import 'dart:math' as math;
import 'dart:ui' as ui show LineMetrics;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'render_text.dart';

// Based on _SelectableFragment in flutter/lib/src/rendering/paragraph.dart

/// A continuous, selectable piece of paragraph.
///
/// Since the selections in PlaceHolderSpan are handled independently in its
/// subtree, a selection in [TextRenderer] can't continue across a
/// PlaceHolderSpan. The [TextRenderer] splits itself on PlaceHolderSpan
/// to create multiple `SelectableFragment`s so that they can be selected
/// separately.
class SelectableFragment
    with
        Selectable,
        ChangeNotifier // ignore: prefer_mixin
    implements
        TextLayoutMetrics {
  SelectableFragment({
    required this.paragraph,
    required this.fullText,
    required this.range,
  }) : assert(range.isValid && !range.isCollapsed && range.isNormalized) {
    _selectionGeometry = _getSelectionGeometry();
  }

  final TextRange range;
  final TextRenderer paragraph;
  final String fullText;

  TextPosition? textSelectionStart;
  TextPosition? textSelectionEnd;

  LayerLink? _startHandleLayerLink;
  LayerLink? _endHandleLayerLink;

  @override
  SelectionGeometry get value => _selectionGeometry;
  late SelectionGeometry _selectionGeometry;
  void _updateSelectionGeometry() {
    final newValue = _getSelectionGeometry();
    if (_selectionGeometry == newValue) {
      return;
    }
    _selectionGeometry = newValue;
    notifyListeners();
  }

  SelectionGeometry _getSelectionGeometry() {
    if (textSelectionStart == null || textSelectionEnd == null) {
      return const SelectionGeometry(
        status: SelectionStatus.none,
        hasContent: true,
      );
    }

    final selectionStart = textSelectionStart!.offset;
    final selectionEnd = textSelectionEnd!.offset;
    final isReversed = selectionStart > selectionEnd;
    final startOffsetInParagraphCoordinates =
        paragraph._getOffsetForPosition(TextPosition(offset: selectionStart));
    final endOffsetInParagraphCoordinates = selectionStart == selectionEnd
        ? startOffsetInParagraphCoordinates
        : paragraph._getOffsetForPosition(TextPosition(offset: selectionEnd));
    final flipHandles =
        isReversed != (TextDirection.rtl == paragraph.textDirection);
    final paragraphToFragmentTransform = getTransformToParagraph()..invert();
    return SelectionGeometry(
      startSelectionPoint: SelectionPoint(
          localPosition: MatrixUtils.transformPoint(
              paragraphToFragmentTransform, startOffsetInParagraphCoordinates),
          lineHeight: paragraph.textPainter.preferredLineHeight,
          handleType: flipHandles
              ? TextSelectionHandleType.right
              : TextSelectionHandleType.left),
      endSelectionPoint: SelectionPoint(
        localPosition: MatrixUtils.transformPoint(
            paragraphToFragmentTransform, endOffsetInParagraphCoordinates),
        lineHeight: paragraph.textPainter.preferredLineHeight,
        handleType: flipHandles
            ? TextSelectionHandleType.left
            : TextSelectionHandleType.right,
      ),
      status: textSelectionStart!.offset == textSelectionEnd!.offset
          ? SelectionStatus.collapsed
          : SelectionStatus.uncollapsed,
      hasContent: true,
    );
  }

  @override
  SelectionResult dispatchSelectionEvent(SelectionEvent event) {
    late final SelectionResult result;
    final existingSelectionStart = textSelectionStart;
    final existingSelectionEnd = textSelectionEnd;
    switch (event.type) {
      case SelectionEventType.startEdgeUpdate:
      case SelectionEventType.endEdgeUpdate:
        final edgeUpdate = event as SelectionEdgeUpdateEvent;
        result = _updateSelectionEdge(edgeUpdate.globalPosition,
            isEnd: edgeUpdate.type == SelectionEventType.endEdgeUpdate);
        break;
      case SelectionEventType.clear:
        result = _handleClearSelection();
        break;
      case SelectionEventType.selectAll:
        result = _handleSelectAll();
        break;
      case SelectionEventType.selectWord:
        final selectWord = event as SelectWordSelectionEvent;
        result = _handleSelectWord(selectWord.globalPosition);
        break;
      case SelectionEventType.granularlyExtendSelection:
        final granularlyExtendSelection =
            event as GranularlyExtendSelectionEvent;
        result = _handleGranularlyExtendSelection(
          granularlyExtendSelection.forward,
          granularlyExtendSelection.isEnd,
          granularlyExtendSelection.granularity,
        );
        break;
      case SelectionEventType.directionallyExtendSelection:
        final directionallyExtendSelection =
            event as DirectionallyExtendSelectionEvent;
        result = _handleDirectionallyExtendSelection(
          directionallyExtendSelection.dx,
          directionallyExtendSelection.isEnd,
          directionallyExtendSelection.direction,
        );
        break;
    }

    if (existingSelectionStart != textSelectionStart ||
        existingSelectionEnd != textSelectionEnd) {
      _didChangeSelection();
    }
    return result;
  }

  @override
  SelectedContent? getSelectedContent() {
    if (textSelectionStart == null || textSelectionEnd == null) {
      return null;
    }
    final int start =
        math.min(textSelectionStart!.offset, textSelectionEnd!.offset);
    final int end =
        math.max(textSelectionStart!.offset, textSelectionEnd!.offset);
    return SelectedContent(
      plainText: fullText.substring(start, end),
    );
  }

  void _didChangeSelection() {
    paragraph.markNeedsPaint();
    _updateSelectionGeometry();
  }

  SelectionResult _updateSelectionEdge(Offset globalPosition,
      {required bool isEnd}) {
    _setSelectionPosition(null, isEnd: isEnd);
    final transform = paragraph.getTransformTo(null)..invert();
    final localPosition = MatrixUtils.transformPoint(transform, globalPosition);
    if (_rect.isEmpty) {
      return SelectionUtils.getResultBasedOnRect(_rect, localPosition);
    }
    final adjustedOffset = SelectionUtils.adjustDragOffset(
      _rect,
      localPosition,
      direction: paragraph.textDirection,
    );

    final position = _clampTextPosition(
        paragraph.getPositionForOffset(adjustedOffset - paragraph.offset));
    _setSelectionPosition(position, isEnd: isEnd);
    if (position.offset == range.end) {
      return SelectionResult.next;
    }
    if (position.offset == range.start) {
      return SelectionResult.previous;
    }
    // TO-DO: The geometry information should not be used to determine
    // selection result. This is a workaround to TextRenderer, where it does
    // not have a way to get accurate text length if its text is truncated due
    // to layout constraint.
    return SelectionUtils.getResultBasedOnRect(_rect, localPosition);
  }

  TextPosition _clampTextPosition(TextPosition position) {
    // Affinity of range.end is upstream.
    if (position.offset > range.end ||
        (position.offset == range.end &&
            position.affinity == TextAffinity.downstream)) {
      return TextPosition(offset: range.end, affinity: TextAffinity.upstream);
    }
    if (position.offset < range.start) {
      return TextPosition(offset: range.start);
    }
    return position;
  }

  void _setSelectionPosition(TextPosition? position, {required bool isEnd}) {
    if (isEnd) {
      textSelectionEnd = position;
    } else {
      textSelectionStart = position;
    }
  }

  SelectionResult _handleClearSelection() {
    textSelectionStart = null;
    textSelectionEnd = null;
    return SelectionResult.none;
  }

  SelectionResult _handleSelectAll() {
    textSelectionStart = TextPosition(offset: range.start);
    textSelectionEnd =
        TextPosition(offset: range.end, affinity: TextAffinity.upstream);
    return SelectionResult.none;
  }

  SelectionResult _handleSelectWord(Offset globalPosition) {
    final position = paragraph.getPositionForOffset(
        paragraph.globalToLocal(globalPosition) - paragraph.offset);
    if (_positionIsWithinCurrentSelection(position)) {
      return SelectionResult.end;
    }
    final word = paragraph.getWordBoundary(position);
    assert(word.isNormalized);
    // Fragments are separated by placeholder span, the word boundary shouldn't
    // expand across fragments.
    assert(word.start >= range.start && word.end <= range.end);
    late TextPosition start;
    late TextPosition end;
    if (position.offset >= word.end) {
      start = end = TextPosition(offset: position.offset);
    } else {
      start = TextPosition(offset: word.start);
      end = TextPosition(offset: word.end, affinity: TextAffinity.upstream);
    }
    textSelectionStart = start;
    textSelectionEnd = end;
    return SelectionResult.end;
  }

  SelectionResult _handleDirectionallyExtendSelection(double horizontalBaseline,
      bool isExtent, SelectionExtendDirection movement) {
    final transform = paragraph.getTransformTo(null);
    if (transform.invert() == 0.0) {
      switch (movement) {
        case SelectionExtendDirection.previousLine:
        case SelectionExtendDirection.backward:
          return SelectionResult.previous;
        case SelectionExtendDirection.nextLine:
        case SelectionExtendDirection.forward:
          return SelectionResult.next;
      }
    }
    final baselineInParagraphCoordinates =
        MatrixUtils.transformPoint(transform, Offset(horizontalBaseline, 0)).dx;
    assert(!baselineInParagraphCoordinates.isNaN);
    final TextPosition newPosition;
    final SelectionResult result;
    switch (movement) {
      case SelectionExtendDirection.previousLine:
      case SelectionExtendDirection.nextLine:
        assert(textSelectionEnd != null && textSelectionStart != null);
        final targetedEdge = isExtent ? textSelectionEnd! : textSelectionStart!;
        final moveResult = _handleVerticalMovement(
          targetedEdge,
          horizontalBaselineInParagraphCoordinates:
              baselineInParagraphCoordinates,
          below: movement == SelectionExtendDirection.nextLine,
        );
        newPosition = moveResult.key;
        result = moveResult.value;
        break;
      case SelectionExtendDirection.forward:
      case SelectionExtendDirection.backward:
        textSelectionEnd ??= movement == SelectionExtendDirection.forward
            ? TextPosition(offset: range.start)
            : TextPosition(offset: range.end, affinity: TextAffinity.upstream);
        textSelectionStart ??= textSelectionEnd;
        final targetedEdge = isExtent ? textSelectionEnd! : textSelectionStart!;
        final edgeOffsetInParagraphCoordinates =
            paragraph._getOffsetForPosition(targetedEdge);
        final baselineOffsetInParagraphCoordinates = Offset(
          baselineInParagraphCoordinates,
          // Use half of line height to point to the middle of the line.
          edgeOffsetInParagraphCoordinates.dy -
              paragraph.textPainter.preferredLineHeight / 2,
        );
        newPosition = paragraph.getPositionForOffset(
            baselineOffsetInParagraphCoordinates - paragraph.offset);
        result = SelectionResult.end;
        break;
    }
    if (isExtent) {
      textSelectionEnd = newPosition;
    } else {
      textSelectionStart = newPosition;
    }
    return result;
  }

  SelectionResult _handleGranularlyExtendSelection(
      bool forward, bool isExtent, TextGranularity granularity) {
    textSelectionEnd ??= forward
        ? TextPosition(offset: range.start)
        : TextPosition(offset: range.end, affinity: TextAffinity.upstream);
    textSelectionStart ??= textSelectionEnd;
    final targetedEdge = isExtent ? textSelectionEnd! : textSelectionStart!;
    if (forward && (targetedEdge.offset == range.end)) {
      return SelectionResult.next;
    }
    if (!forward && (targetedEdge.offset == range.start)) {
      return SelectionResult.previous;
    }
    final SelectionResult result;
    final TextPosition newPosition;
    switch (granularity) {
      case TextGranularity.character:
        final text = range.textInside(fullText);
        newPosition = _moveBeyondTextBoundaryAtDirection(
            targetedEdge, forward, CharacterBoundary(text));
        result = SelectionResult.end;
        break;
      case TextGranularity.word:
        final textBoundary =
            paragraph.textPainter.wordBoundaries.moveByWordBoundary;
        newPosition = _moveBeyondTextBoundaryAtDirection(
            targetedEdge, forward, textBoundary);
        result = SelectionResult.end;
        break;
      case TextGranularity.line:
        newPosition = _moveToTextBoundaryAtDirection(
            targetedEdge, forward, LineBoundary(this));
        result = SelectionResult.end;
        break;
      case TextGranularity.document:
        final text = range.textInside(fullText);
        newPosition = _moveBeyondTextBoundaryAtDirection(
            targetedEdge, forward, DocumentBoundary(text));
        if (forward && newPosition.offset == range.end) {
          result = SelectionResult.next;
        } else if (!forward && newPosition.offset == range.start) {
          result = SelectionResult.previous;
        } else {
          result = SelectionResult.end;
        }
        break;
    }

    if (isExtent) {
      textSelectionEnd = newPosition;
    } else {
      textSelectionStart = newPosition;
    }
    return result;
  }

  // Move **beyond** the local boundary of the given type (unless range.start or
  // range.end is reached). Used for most TextGranularity types except for
  // TextGranularity.line, to ensure the selection movement doesn't get stuck at
  // a local fixed point.
  TextPosition _moveBeyondTextBoundaryAtDirection(
      TextPosition end, bool forward, TextBoundary textBoundary) {
    final newOffset = forward
        ? textBoundary.getTrailingTextBoundaryAt(end.offset) ?? range.end
        : textBoundary.getLeadingTextBoundaryAt(end.offset - 1) ?? range.start;
    return TextPosition(offset: newOffset);
  }

  // Move **to** the local boundary of the given type. Typically used for line
  // boundaries, such that performing "move to line start" more than once never
  // moves the selection to the previous line.
  TextPosition _moveToTextBoundaryAtDirection(
      TextPosition end, bool forward, TextBoundary textBoundary) {
    assert(end.offset >= 0);
    final int caretOffset;
    switch (end.affinity) {
      case TextAffinity.upstream:
        if (end.offset < 1 && !forward) {
          assert(end.offset == 0);
          return const TextPosition(offset: 0);
        }
        final characterBoundary = CharacterBoundary(fullText);
        caretOffset = math.max(
              0,
              characterBoundary
                      .getLeadingTextBoundaryAt(range.start + end.offset) ??
                  range.start,
            ) -
            1;
        break;
      case TextAffinity.downstream:
        caretOffset = end.offset;
        break;
    }
    final offset = forward
        ? textBoundary.getTrailingTextBoundaryAt(caretOffset) ?? range.end
        : textBoundary.getLeadingTextBoundaryAt(caretOffset) ?? range.start;
    return TextPosition(offset: offset);
  }

  MapEntry<TextPosition, SelectionResult> _handleVerticalMovement(
      TextPosition position,
      {required double horizontalBaselineInParagraphCoordinates,
      required bool below}) {
    final lines = paragraph._computeLineMetrics();
    final offset =
        paragraph.getOffsetForCaret(position, Rect.zero) + paragraph.offset;
    var currentLine = lines.length - 1;
    for (final lineMetrics in lines) {
      if (lineMetrics.baseline + paragraph.offset.dy > offset.dy) {
        currentLine = lineMetrics.lineNumber;
        break;
      }
    }
    final TextPosition newPosition;
    if (below && currentLine == lines.length - 1) {
      newPosition =
          TextPosition(offset: range.end, affinity: TextAffinity.upstream);
    } else if (!below && currentLine == 0) {
      newPosition = TextPosition(offset: range.start);
    } else {
      final newLine = below ? currentLine + 1 : currentLine - 1;
      newPosition = _clampTextPosition(paragraph.getPositionForOffset(Offset(
              horizontalBaselineInParagraphCoordinates,
              lines[newLine].baseline + paragraph.offset.dy) -
          paragraph.offset));
    }
    final SelectionResult result;
    if (newPosition.offset == range.start) {
      result = SelectionResult.previous;
    } else if (newPosition.offset == range.end) {
      result = SelectionResult.next;
    } else {
      result = SelectionResult.end;
    }
    assert(result != SelectionResult.next || below);
    assert(result != SelectionResult.previous || !below);
    return MapEntry<TextPosition, SelectionResult>(newPosition, result);
  }

  /// Whether the given text position is contained in current selection
  /// range.
  ///
  /// The parameter `start` must be smaller than `end`.
  bool _positionIsWithinCurrentSelection(TextPosition position) {
    if (textSelectionStart == null || textSelectionEnd == null) {
      return false;
    }
    // Normalize current selection.
    late TextPosition currentStart;
    late TextPosition currentEnd;
    if (_compareTextPositions(textSelectionStart!, textSelectionEnd!) > 0) {
      currentStart = textSelectionStart!;
      currentEnd = textSelectionEnd!;
    } else {
      currentStart = textSelectionEnd!;
      currentEnd = textSelectionStart!;
    }
    return _compareTextPositions(currentStart, position) >= 0 &&
        _compareTextPositions(currentEnd, position) <= 0;
  }

  /// Compares two text positions.
  ///
  /// Returns 1 if `position` < `otherPosition`,
  /// -1 if `position` > `otherPosition`,
  /// or 0 if they are equal.
  static int _compareTextPositions(
      TextPosition position, TextPosition otherPosition) {
    if (position.offset < otherPosition.offset) {
      return 1;
    } else if (position.offset > otherPosition.offset) {
      return -1;
    } else if (position.affinity == otherPosition.affinity) {
      return 0;
    } else {
      return position.affinity == TextAffinity.upstream ? 1 : -1;
    }
  }

  Matrix4 getTransformToParagraph() {
    return Matrix4.translationValues(_rect.left, _rect.top, 0.0);
  }

  @override
  Matrix4 getTransformTo(RenderObject? ancestor) {
    return getTransformToParagraph()
      ..multiply(paragraph.getTransformTo(ancestor));
  }

  @override
  void pushHandleLayers(LayerLink? startHandle, LayerLink? endHandle) {
    if (!paragraph.attached) {
      assert(startHandle == null && endHandle == null,
          'Only clean up can be called.');
      return;
    }
    if (_startHandleLayerLink != startHandle) {
      _startHandleLayerLink = startHandle;
      paragraph.markNeedsPaint();
    }
    if (_endHandleLayerLink != endHandle) {
      _endHandleLayerLink = endHandle;
      paragraph.markNeedsPaint();
    }
  }

  List<Rect>? _cachedBoundingBoxes;
  @override
  List<Rect> get boundingBoxes {
    if (_cachedBoundingBoxes == null) {
      final boxes = paragraph.getBoxesForSelection(
        TextSelection(baseOffset: range.start, extentOffset: range.end),
      );
      if (boxes.isNotEmpty) {
        _cachedBoundingBoxes = <Rect>[];
        for (final textBox in boxes) {
          _cachedBoundingBoxes!.add(textBox.toRect());
        }
      } else {
        final offset =
            paragraph._getOffsetForPosition(TextPosition(offset: range.start));
        final rect = Rect.fromPoints(offset,
            offset.translate(0, -paragraph.textPainter.preferredLineHeight));
        _cachedBoundingBoxes = <Rect>[rect];
      }
    }
    return _cachedBoundingBoxes!;
  }

  Rect? _cachedRect;
  Rect get _rect {
    if (_cachedRect == null) {
      final boxes = paragraph.getBoxesForSelection(
        TextSelection(baseOffset: range.start, extentOffset: range.end),
      );
      if (boxes.isNotEmpty) {
        var result = boxes.first.toRect();
        for (var index = 1; index < boxes.length; index += 1) {
          result = result.expandToInclude(boxes[index].toRect());
        }
        _cachedRect = result.shift(paragraph.offset);
      } else {
        final offset =
            paragraph._getOffsetForPosition(TextPosition(offset: range.start));
        _cachedRect = Rect.fromPoints(offset,
            offset.translate(0, -paragraph.textPainter.preferredLineHeight));
      }
    }
    return _cachedRect!;
  }

  void didChangeParagraphLayout() {
    _cachedRect = null;
  }

  @override
  Size get size {
    return _rect.size;
  }

  void paint(PaintingContext context, Offset offset) {
    if (textSelectionStart == null || textSelectionEnd == null) {
      return;
    }
    if (paragraph.selectionColor != null) {
      final selection = TextSelection(
        baseOffset: textSelectionStart!.offset,
        extentOffset: textSelectionEnd!.offset,
      );
      final selectionPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = paragraph.selectionColor!;
      for (final textBox in paragraph.getBoxesForSelection(selection)) {
        context.canvas.drawRect(
            textBox.toRect().shift(paragraph.offset).shift(offset),
            selectionPaint);
      }
    }
    final transform = getTransformToParagraph();
    if (_startHandleLayerLink != null && value.startSelectionPoint != null) {
      context.pushLayer(
        LeaderLayer(
          link: _startHandleLayerLink!,
          offset: offset +
              MatrixUtils.transformPoint(
                  transform, value.startSelectionPoint!.localPosition),
        ),
        (context, offset) {},
        Offset.zero,
      );
    }
    if (_endHandleLayerLink != null && value.endSelectionPoint != null) {
      context.pushLayer(
        LeaderLayer(
          link: _endHandleLayerLink!,
          offset: offset +
              MatrixUtils.transformPoint(
                  transform, value.endSelectionPoint!.localPosition),
        ),
        (context, offset) {},
        Offset.zero,
      );
    }
  }

  @override
  TextSelection getLineAtOffset(TextPosition position) {
    final line = paragraph._getLineAtOffset(position);
    final start =
        line.start.clamp(range.start, range.end); // ignore_clamp_double_lint
    final end =
        line.end.clamp(range.start, range.end); // ignore_clamp_double_lint
    return TextSelection(baseOffset: start, extentOffset: end);
  }

  @override
  TextPosition getTextPositionAbove(TextPosition position) {
    return _clampTextPosition(paragraph._getTextPositionAbove(position));
  }

  @override
  TextPosition getTextPositionBelow(TextPosition position) {
    return _clampTextPosition(paragraph._getTextPositionBelow(position));
  }

  @override
  TextRange getWordBoundary(TextPosition position) =>
      paragraph.getWordBoundary(position);
}

extension on TextRenderer {
  Offset _getOffsetForPosition(TextPosition position) {
    return getOffsetForCaret(position, Rect.zero) +
        offset +
        Offset(0, getFullHeightForCaret(position) ?? 0.0);
  }

  TextRange _getLineAtOffset(TextPosition position) =>
      textPainter.getLineBoundary(position);

  TextPosition _getTextPositionAbove(TextPosition position) {
    // -0.5 of preferredLineHeight points to the middle of the line above.
    final preferredLineHeight = textPainter.preferredLineHeight;
    final verticalOffset = -0.5 * preferredLineHeight;
    return _getTextPositionVertical(position, verticalOffset);
  }

  TextPosition _getTextPositionBelow(TextPosition position) {
    // 1.5 of preferredLineHeight points to the middle of the line below.
    final preferredLineHeight = textPainter.preferredLineHeight;
    final verticalOffset = 1.5 * preferredLineHeight;
    return _getTextPositionVertical(position, verticalOffset);
  }

  TextPosition _getTextPositionVertical(
      TextPosition position, double verticalOffset) {
    final caretOffset = getOffsetForCaret(position, Rect.zero) + offset;
    final caretOffsetTranslated = caretOffset.translate(0.0, verticalOffset);
    return getPositionForOffset(caretOffsetTranslated - offset);
  }

  List<ui.LineMetrics> _computeLineMetrics() {
    return textPainter.computeLineMetrics();
  }
}
