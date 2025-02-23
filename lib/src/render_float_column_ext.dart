part of 'render_float_column.dart';

extension on RenderFloatColumn {
  bool get isLTR => textDirection == TextDirection.ltr;
  bool get isRTL => textDirection == TextDirection.rtl;

  Size _performLayout() {
    final BoxConstraints childConstraints;
    if (crossAxisAlignment == CrossAxisAlignment.stretch) {
      childConstraints = BoxConstraints.tightFor(width: constraints.maxWidth);
    } else {
      childConstraints = BoxConstraints(maxWidth: constraints.maxWidth);
    }

    if (firstChild != null) {
      _removeAllChildren();
    }

    final rc = _RenderCursor(this, childConstraints, firstChild);

    // This gets updated to the previous non-floated child's bottom margin.
    var prevBottomMargin = 0.0;

    for (var i = 0; i < childManager.textAndWidgets.length; i++) {
      assert(rc.index == i);
      rc.index = i;
      final el = childManager.textAndWidgets[i];

      // If this a floated child widget of a WrappableText, it has already
      // been laid out, so skip it.
      if (el is MetaData &&
          el.metaData is FloatData &&
          (el.metaData as FloatData).wrappableTextIndex != null &&
          rc.maybeChild != null &&
          rc.child.hasSize) {
        // Nothing to do here...
      } else {
        // Update the current child's widget and associated element.
        rc.updateCurrentChildWidget(
            el is Widget ? el : (el as WrappableText).toWidget());
        if (rc.maybeChild == null) {
          assert(false);
          continue;
        }

        // If it is a Widget...
        if (el is Widget) {
          // All widgets are wrapped in a MetaData widget with FloatData.
          final floatData =
              ((rc.child as RenderMetaData).metaData as FloatData);

          // If not floated, resolve the margin and update `rc.y` and
          // `prevBottomMargin`.
          if (floatData.float == FCFloat.none) {
            final margin = floatData.margin.resolve(textDirection);
            final topMargin = math.max(prevBottomMargin, margin.top);
            rc.y += topMargin;
            prevBottomMargin = margin.bottom;
          }

          _layoutWidget(rc, childConstraints, floatData);
        }

        // Else, if it is a WrappableText...
        else if (el is WrappableText) {
          // Resolve the margin and update `rc.y` and `prevBottomMargin`.
          final textDirection = el.textDirection ?? this.textDirection;
          final margin = el.margin.resolve(textDirection);
          final topMargin = math.max(prevBottomMargin, margin.top);
          rc.y += topMargin;
          prevBottomMargin = margin.bottom;

          _layoutWrappableText(el, rc, childConstraints, textDirection);
        } else {
          assert(false);
        }
      }

      rc.moveNext();
    }

    // Remove any extra children.
    while (rc.maybeChild != null) {
      final childParentData = rc.child.parentData! as FloatColumnParentData;
      final nextChild = childParentData.nextSibling;
      _removeChild(rc.child);
      rc.maybeChild = nextChild;
    }

    rc.y += prevBottomMargin;
    final totalHeight =
        math.max(rc.floatL.maxYBelow(rc.y), rc.floatR.maxYBelow(rc.y));
    return Size(constraints.maxWidth, totalHeight);
  }

  /// Lays out child widget.
  void _layoutWidget(
    _RenderCursor rc,
    BoxConstraints childConstraints,
    FloatData floatData,
  ) {
    final margin = floatData.margin.resolve(textDirection);
    final padding = floatData.padding.resolve(textDirection);
    final maxWidth = childConstraints.maxWidth;

    final maxWidthMinusPadding = math.max(0.0,
        maxWidth - margin.left - margin.right - padding.left - padding.right);
    final childMaxWidth =
        math.min(maxWidthMinusPadding, maxWidth * floatData.maxWidthPercentage);

    var widgetConstraints = childConstraints;
    if (childMaxWidth != childConstraints.maxWidth) {
      widgetConstraints = childConstraints.copyWith(
        maxWidth: childMaxWidth,
        minWidth: math.min(widgetConstraints.minWidth, childMaxWidth),
      );
    }

    rc.child.layout(widgetConstraints, parentUsesSize: true);

    var alignment = crossAxisAlignment;

    // Should this child widget be floated to the left or right?
    List<Rect>? addToFloatRects;
    if (floatData.float != FCFloat.none) {
      final float = resolveFloat(floatData.float, withDir: textDirection);
      assert(float == FCFloat.left || float == FCFloat.right);
      if (float == FCFloat.left) {
        addToFloatRects = rc.floatL;
        alignment = isLTR ? CrossAxisAlignment.start : CrossAxisAlignment.end;
      } else {
        addToFloatRects = rc.floatR;
        alignment = isRTL ? CrossAxisAlignment.start : CrossAxisAlignment.end;
      }
    }

    var yPosNext = rc.y;

    // Check for `clear` and adjust `yPosNext` accordingly.
    final clear = resolveClear(floatData.clear, withDir: textDirection);
    final spacing = floatData.clearMinSpacing;
    if (clear == FCClear.left || clear == FCClear.both) {
      yPosNext = rc.floatL.nextY(yPosNext, spacing);
    }
    if (clear == FCClear.right || clear == FCClear.both) {
      yPosNext = rc.floatR.nextY(yPosNext, spacing);
    }

    final totalMinWidth = rc.child.size.width + padding.left + padding.right;
    final minX = margin.left;
    final maxX = math.max(minX + totalMinWidth, maxWidth - margin.right);

    // Find space for this widget...
    var rect = findSpaceFor(
      startY: yPosNext,
      width: math.min(maxWidth, totalMinWidth),
      height: rc.child.size.height + padding.top + padding.bottom,
      minX: minX,
      maxX: maxX,
      floatL: rc.floatL,
      floatR: rc.floatR,
    );

    // Adjust rect for padding.
    if (padding != EdgeInsets.zero) {
      rect = Rect.fromLTRB(
        rect.left + padding.left,
        rect.top + padding.top,
        rect.right - padding.right,
        rect.bottom - padding.bottom,
      );
    }

    // Calculate `xPos` based on alignment and available space.
    final xPos = _xPosForChildWithWidth(
        rc.child.size.width, alignment, rect.left, rect.right);
    (rc.child.parentData! as FloatColumnParentData).offset =
        Offset(xPos, rect.top);

    if (addToFloatRects != null) {
      // Include padding for the floated rect.
      addToFloatRects.add(Rect.fromLTRB(
        xPos - padding.left,
        rect.top - padding.top,
        xPos + rc.child.size.width + padding.right,
        rect.top + rc.child.size.height + padding.bottom,
      ));
      // This widget was floated, so set `yPosNext` back to `rc.y`.
      yPosNext = rc.y;
    } else {
      yPosNext = rect.top + rc.child.size.height + padding.bottom;
    }

    rc.y = yPosNext;
  }

  /// Lays out the given WrappableText object, and returns the y position for
  /// the next child.
  void _layoutWrappableText(
    WrappableText wt,
    _RenderCursor rc,
    BoxConstraints childConstraints,
    TextDirection textDirection,
  ) {
    final margin = wt.margin.resolve(textDirection);
    final padding = wt.padding.resolve(textDirection);

    var yPosNext = rc.y + padding.top;

    // Check for `clear` and adjust `yPosNext` accordingly.
    final clear = resolveClear(wt.clear, withDir: textDirection);
    if (clear == FCClear.left || clear == FCClear.both) {
      yPosNext = rc.floatL.maxYBelow(yPosNext);
    }
    if (clear == FCClear.right || clear == FCClear.both) {
      yPosNext = rc.floatR.maxYBelow(yPosNext);
    }

    // Does this WrappableText have any floated inline widget children?
    final wrappableTextIndex = rc.index;
    // final hasFloatedChildren = wt.text._hasFloatedChildren(wrappableTextIndex);

    // Keep track of the indices of the floated widget children that have
    // already been laid out, because should only be laid out once.
    final laidOutFloaterIndices = <int>{};

    final textChunks = <_TextChunk>[];
    WrappableText? remaining = wt.copyWith(
        text: TextSpan(style: defaultTextStyle.style, children: [wt.text]));
    while (remaining != null) {
      // Get the estimated line height for the first line. We want to find
      // space for at least the first line of text.
      final estLineHeight =
          remaining.text.initialLineHeight(wt.textScaler ?? defaultTextScaler);

      // While the text starts with a line feed, remove the line feed, add the
      // line height to `yPosNext`, then re-run the loop.
      if (remaining.text.initialText().startsWith('\n')) {
        do {
          remaining = remaining!.copyWith(
              text: remaining.text.skipChars(1),
              maxLines:
                  remaining.maxLines == null ? null : remaining.maxLines! - 1);
          yPosNext += estLineHeight;
        } while (remaining.text.initialText().startsWith('\n'));

        // Update the widget, and re-run the loop...
        rc.updateCurrentChildWidget(remaining.toWidget());
        continue; //-------------------------------------------->
      }

      final indent = textChunks.isEmpty ? wt.indent : 0.0;
      final estScaledFontSize = remaining.text
          .initialScaledFontSize(wt.textScaler ?? defaultTextScaler);
      final lineMinWidth =
          estScaledFontSize * 4.0 + padding.left + indent + padding.right;

      // Find space for a width of at least `estLineHeight * 4.0`. This may
      // need to be tweaked, or it could be an option passed in, or we could
      // layout the text and find the actual width of the first word, and that
      // could be the minimum width?
      var rect = findSpaceFor(
          startY: yPosNext,
          width: lineMinWidth,
          height: estLineHeight,
          minX: margin.left,
          maxX: math.max(margin.left + lineMinWidth,
              childConstraints.maxWidth - margin.right),
          floatL: rc.floatL,
          floatR: rc.floatR);

      // Adjust rect for padding.
      rect = Rect.fromLTRB(
        rect.left + padding.left + indent,
        rect.top,
        rect.right - padding.right,
        rect.bottom,
      );

      final subConstraints = childConstraints.copyWith(
        maxWidth: rect.width,
        minWidth: math.min(childConstraints.minWidth, rect.width),
      );

      // Layout the text and inline widget children.
      rc.child.layout(subConstraints, parentUsesSize: true);

      // If this is the first line of the paragraph, and the indent value is
      // not zero, the second line has a different width and needs to be
      // laid out separately, so set the `bottom` value accordingly.
      final bottom = math.min(rect.bottom,
          indent == 0.0 ? rect.bottom : rect.top + estLineHeight / 2.0);

      // `findSpaceFor` just checked for space for the first line of text.
      // Now that the text has been laid out, we need to see if the available
      // space extends to the full height of the text.
      final startY = rect.top + estLineHeight;
      final nextFloatTop = math.min(
        rc.floatL.topOfTopMostRectAtOrBelow(startY),
        rc.floatR.topOfTopMostRectAtOrBelow(startY),
      );
      final yChange = math.min(bottom, nextFloatTop);

      // If the text extends past `yChange`, we need to split the text
      // and layout each part individually...
      if (rect.top + rc.child.size.height > yChange) {
        final renderParagraph = rc.childRenderParagraph();
        if (renderParagraph == null) {
          assert(false);
        } else {
          // Calculate the approximate x, y to split the text at, which
          // depends on the text direction.
          //
          // ⦿ Shows the x, y offsets the text should be split at:
          //
          // LTR example:
          //  | This is what you   ┌──────────┐
          //  | shall do; Love the ⦿          │
          //  ├────────┐ earth and ⦿──────────┤
          //  │        │ sun and the animals, |
          //  ├────────┘ despise riches, give ⦿
          //  │ alms to every one that asks...|
          //
          // RTL example:
          //  |   you what is This ┌──────────┐
          //  ⦿ the Love ;do shall │          │
          //  ├────────⦿ and earth └──────────┤
          //  │        │ ,animals the and sun |
          //  ├────────⦿ give ,riches despise |
          //  │...asks that one every to alms |
          //

          final x = textDirection == TextDirection.ltr ? rect.width : 0.0;
          final y = math.min(yChange, nextFloatTop - estLineHeight) - rect.top;
          final parts = remaining.text.splitAt(
              renderParagraph.getPositionForOffset(Offset(x, y)).offset);

          // If it was split into two spans...
          if (parts.length == 2) {
            final part1 = remaining.copyWith(
                text: parts.first, clearKey: textChunks.isNotEmpty);

            // Update the current child's widget and re-layout it.
            rc.updateCurrentChildWidget(part1.toWidget());
            rc.child.layout(subConstraints, parentUsesSize: true);

            // Does [part1] have any floated child widgets that needed to be
            // laid out?
            if (part1.text._hasFloatedChildren(wrappableTextIndex) &&
                rc.layoutFloatedChildren(
                    laidOutFloaterIndices, wrappableTextIndex, rect.top)) {
              // If so, we need to re-run the loop...
              continue;
            }

            // If [maxLines] was set, [remainingLines] needs to be set to
            // [maxLines] minus the number of lines in [part1].
            int? remainingLines;
            if (remaining.maxLines != null) {
              // Estimate the number of lines in [part1].
              final lines = (rc.child.size.height / estLineHeight).round();
              remainingLines = remaining.maxLines! - lines;
            }

            // Only add [part2] if [remainingLines] is null or greater
            // than zero.
            if (remainingLines == null || remainingLines > 0) {
              // Calculate `xPos` based on alignment and available space.
              final xPos = _xPosForChildWithWidth(rc.child.size.width,
                  _alignment(wt.textAlign), rect.left, rect.right);
              yPosNext = rect.top + rc.child.size.height;
              final textChunk = _TextChunk(
                  Rect.fromLTWH(xPos, rect.top, rc.child.size.width,
                      rc.child.size.height),
                  part1);

              textChunks.add(textChunk);

              remaining = remaining.copyWith(
                  text: parts.last,
                  maxLines: remainingLines,
                  clearKey: textChunks.isNotEmpty);

              rc.updateCurrentChildWidget(remaining.toWidget());

              // Re-run the loop...
              continue; //------------------------------------>
            }
          }
        }
      }

      // Are there any floated child widgets that needed to be laid out?
      if (rc.layoutFloatedChildren(
          laidOutFloaterIndices, wrappableTextIndex, rect.top)) {
        // If so, we need to re-run the loop...
        continue;
      }

      final double xPos;
      if (textChunks.isNotEmpty) {
        // Calculate `xPos` based on alignment and available space.
        final x = _xPosForChildWithWidth(rc.child.size.width,
            _alignment(wt.textAlign), rect.left, rect.right);
        textChunks.add(_TextChunk(
          Rect.fromLTWH(x, rect.top, rc.child.size.width, rc.child.size.height),
          remaining,
        ));

        rc.updateCurrentChildWidget(
            textChunks.toWidget(childConstraints.maxWidth));
        rc.child.layout(childConstraints, parentUsesSize: true);

        final top = textChunks.first.rect.top;
        rect = Rect.fromLTWH(
            0, top, childConstraints.maxWidth, top + rc.child.size.height);
        xPos = 0.0;
      } else {
        // Calculate `xPos` based on alignment and available space.
        xPos = _xPosForChildWithWidth(rc.child.size.width,
            _alignment(wt.textAlign), rect.left, rect.right);
      }

      (rc.child.parentData! as FloatColumnParentData).offset =
          Offset(xPos, rect.top);

      yPosNext = rect.top + rc.child.size.height;
      remaining = null;
      break;
    }

    rc.y = yPosNext + padding.bottom;
  }

  /// Given a child's [width] and [alignment], and the [minX] and [maxX],
  /// returns the x position for the child.
  double _xPosForChildWithWidth(
      double width, CrossAxisAlignment alignment, double minX, double maxX) {
    final double childCrossPosition;
    switch (alignment) {
      case CrossAxisAlignment.start:
        childCrossPosition = isLTR ? minX : maxX - width;
        break;
      case CrossAxisAlignment.end:
        childCrossPosition = isRTL ? minX : maxX - width;
        break;
      case CrossAxisAlignment.center:
        childCrossPosition = (minX + maxX) / 2.0 - width / 2.0;
        break;
      case CrossAxisAlignment.stretch:
      case CrossAxisAlignment.baseline:
        childCrossPosition = minX;
        break;
    }
    return childCrossPosition;
  }

  CrossAxisAlignment _alignment(TextAlign? textAlign) {
    switch (textAlign ?? defaultTextStyle.textAlign ?? TextAlign.start) {
      case TextAlign.left:
        return isLTR ? CrossAxisAlignment.start : CrossAxisAlignment.end;
      case TextAlign.right:
        return isRTL ? CrossAxisAlignment.start : CrossAxisAlignment.end;
      case TextAlign.center:
        return CrossAxisAlignment.center;
      case TextAlign.justify:
        return CrossAxisAlignment.stretch;
      case TextAlign.start:
        return CrossAxisAlignment.start;
      case TextAlign.end:
        return CrossAxisAlignment.end;
    }
  }
}

class _RenderCursor {
  _RenderCursor(this.rfc, this.childConstraints, this.maybeChild);

  RenderFloatColumn rfc;
  final BoxConstraints childConstraints;

  int index = 0;
  RenderBox? previousChild;
  RenderBox? maybeChild;
  double y = 0.0;

  // The rectangles of widgets that are floated to the left or right.
  final floatL = <Rect>[];
  final floatR = <Rect>[];

  RenderBox get child => maybeChild!;

  /// The current child as a RenderParagraph, or the first descendant of the
  /// current child that is a RenderParagraph.
  RenderParagraph? childRenderParagraph() => child is RenderParagraph
      ? child as RenderParagraph
      : child.firstDescendantOfType<RenderParagraph>();

  /// Moves to the next child.
  void moveNext() {
    previousChild = child;
    maybeChild = (child.parentData! as FloatColumnParentData).nextSibling;
    index++;
  }

  /// Moves to the previous child.
  void movePrevious() {
    maybeChild = previousChild;
    previousChild =
        (previousChild!.parentData! as FloatColumnParentData).previousSibling;
    index--;
  }

  /// Attempts to jump to the child at the given [index], returning `true` if
  /// successful. Fails if `childManager.childAt(index)` and
  /// `childManager.childAt(index - 1)` are `null`.
  bool jumpToIndex(int newIndex) {
    final newChild = rfc.childManager.childAt(newIndex);
    if (newChild != null) {
      maybeChild = newChild;
      previousChild =
          (newChild.parentData! as FloatColumnParentData).previousSibling;
      index = newIndex;
      return true;
    } else {
      final newPreviousChild = rfc.childManager.childAt(newIndex - 1);
      if (newPreviousChild != null) {
        previousChild = newPreviousChild;
        maybeChild =
            (newPreviousChild.parentData! as FloatColumnParentData).nextSibling;
        index = newIndex;
        return true;
      }
    }
    return false;
  }

  /// Updates the current child's widget and associated element.
  void updateCurrentChildWidget(Widget widget) {
    rfc.childManager.childWidgets[index] = widget;
    maybeChild = rfc._addOrUpdateChild(index, after: previousChild);
  }

  /// Lays out the first floated child widget of the current WrappableText
  /// that has not already been laid out, if any. Returns `true` if a floated
  /// child widget was laid out.
  bool layoutFloatedChildren(
    Set<int> laidOutFloaterIndices,
    int wrappableTextIndex,
    double top,
  ) {
    final renderParagraph = childRenderParagraph();
    assert(renderParagraph != null);
    if (renderParagraph != null) {
      var rpChild = renderParagraph.firstChild;
      while (rpChild != null) {
        final renderMetaData = rpChild is RenderMetaData
            ? rpChild
            : rpChild.firstDescendantOfType<RenderMetaData>();
        if (renderMetaData != null && renderMetaData.metaData is FloatData) {
          final fd = renderMetaData.metaData as FloatData;
          if (fd.wrappableTextIndex == wrappableTextIndex &&
              !laidOutFloaterIndices.contains(fd.placeholderIndex)) {
            final savedIndex = index;
            assert(savedIndex == wrappableTextIndex);

            // Jump to the index of the floated child widget.
            if (jumpToIndex(fd.index)) {
              final widget = rfc.childManager.textAndWidgets[index];
              assert(widget is Widget);
              var laidOutFloatingWidget = false;
              if (widget is Widget) {
                updateCurrentChildWidget(widget);
                final savedY = y;
                final offset = (rpChild.parentData! as TextParentData).offset!;
                // dmPrint('wrappableTextIndex ${fd.wrappableTextIndex}, '
                //     'index: $index, placeholderIndex: '
                //     '${fd.placeholderIndex} offset: $offset');
                y = top + offset.dy - 5;
                rfc._layoutWidget(this, childConstraints, fd);
                y = savedY;
                laidOutFloaterIndices.add(fd.placeholderIndex);
                laidOutFloatingWidget = true;
              }

              jumpToIndex(savedIndex);
              if (laidOutFloatingWidget) return true; //-------------------->
            }
          }
        }

        rpChild = renderParagraph.childAfter(rpChild);
      }
    }

    return false;
  }
}

@immutable
class _TextChunk {
  const _TextChunk(this.rect, this.text);
  final Rect rect;
  final WrappableText text;
}

extension on List<_TextChunk> {
  Widget toWidget(double width) {
    // dmPrint('widgets:');
    // for (final t in this) {
    //   dmPrint('object: ${t.x}, ${t.width}, ${t.text.toWidget()}');
    // }
    // dmPrint('------------------------------------');
    final top = isEmpty ? 0.0 : first.rect.top;
    final height = isEmpty ? 0.0 : last.rect.bottom - top;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        SizedBox(width: width, height: height),
        for (final t in this)
          Positioned(
            left: t.rect.left,
            top: t.rect.top - top,
            child: SizedBox(
              width: t.rect.width,
              child: t.text.toWidget(),
            ),
          ),
      ],
    );
  }
}

extension on TextSpan {
  List<TextSpan> splitAt(int index) {
    var i = index;

    if (i > 0) {
      final text = toPlainText(includeSemanticsLabels: false);
      if (i < text.length - 1) {
        // Skip trailing spaces.
        final codeUnits = text.codeUnits;
        while (i < codeUnits.length - 1 && codeUnits[i] == 0x0020) {
          i++;
        }

        // Split the TextSpan at `i`.
        final split = splitAtCharacterIndex(i, ignoreFloatedWidgetSpans: true);

        // If it was split into two spans...
        if (split.length == 2) {
          //
          // This fixes a bug where, if a span is split right before a
          // line feed, and we don't remove the line feed, it is
          // rendered like two line feeds.
          //
          // If the second span starts with a '\n' (line feed), remove
          // the '\n'.
          if (text.codeUnitAt(i) == 0x0a) {
            final s2 = split.last
                .splitAtCharacterIndex(1, ignoreFloatedWidgetSpans: true);
            if (s2.length == 2) {
              assert(
                  s2.first.toPlainText(includeSemanticsLabels: false) == '\n');
              split[1] = s2.last;
            }
          }

          return [split.first as TextSpan, split.last as TextSpan];
        }
      }
    }

    return [this];
  }
}

extension on TextSpan {
  /// Returns `true` if this TextSpan has any floated WidgetSpan children.
  bool _hasFloatedChildren(int index) =>
      !visitChildren((span) => !(span is WidgetSpan &&
          span.child is MetaData &&
          (span.child as MetaData).metaData is FloatData &&
          ((span.child as MetaData).metaData as FloatData).wrappableTextIndex ==
              index));
}
