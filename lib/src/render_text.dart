// Copyright (c) 2021 Ron Booth. All rights reserved.
// Use of this source code is governed by a license that can be found in the
// LICENSE file.

import 'dart:ui' as ui show BoxHeightStyle, BoxWidthStyle, PlaceholderAlignment;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'float_data.dart';
import 'inline_span_ext.dart';
import 'render_float_column.dart';
import 'render_text_mixin.dart';
import 'selectable_fragment.dart';
import 'shared.dart';
import 'wrappable_text.dart';

const String _kEllipsis = '\u2026';

///
/// WrappableTextRenderer
///
class WrappableTextRenderer {
  WrappableTextRenderer(
    RenderBox parent,
    WrappableText wt,
    TextDirection defaultTextDirection,
    DefaultTextStyle defaultTextStyle,
    Color? selectionColor,
  ) : renderer = TextRenderer._(
          parent,
          TextPainter(
            text: TextSpan(style: defaultTextStyle.style, children: [wt.text]),
            textAlign:
                wt.textAlign ?? defaultTextStyle.textAlign ?? TextAlign.start,
            textDirection: wt.textDirection ?? defaultTextDirection,
            textScaler: wt.textScaler,
            maxLines: wt.maxLines ?? defaultTextStyle.maxLines,
            ellipsis: (wt.overflow ?? defaultTextStyle.overflow) ==
                    TextOverflow.ellipsis
                ? _kEllipsis
                : null,
            locale: wt.locale,
            strutStyle: wt.strutStyle,
            textHeightBehavior:
                wt.textHeightBehavior ?? defaultTextStyle.textHeightBehavior,
          ),
          0,
          selectionColor,
        );

  bool get alwaysNeedsCompositing =>
      renderers.any((tr) => tr._lastSelectableFragments?.isNotEmpty ?? false);

  void dispose() {
    subsClearAndDispose();
    renderer.dispose();
  }

  final TextRenderer renderer;
  final _subs = <TextRenderer>[];

  TextRenderer operator [](int index) => index == -1 ? renderer : _subs[index];

  int get subsLength => _subs.length;

  void subsClearAndDispose() {
    for (final tr in _subs) {
      tr.dispose();
    }
    _subs.clear();
  }

  TextRenderer? subsRemoveAt(int i, {bool dispose = true}) {
    final removed = _subs.removeAt(i);
    if (dispose) {
      // dmPrint('subsRemoveAt($i, dispose: true) uid: ${removed.uid}');
      removed.dispose();
      return null;
    }
    return removed;
  }

  TextRenderer? subsRemoveLast({bool dispose = true}) =>
      subsRemoveAt(subsLength - 1, dispose: dispose);

  void subsAdd(TextRenderer tr) => _subs.add(tr);

  TextDirection get textDirection => renderer._painter.textDirection!;

  List<TextRenderer> get renderers => _subs.isNotEmpty ? _subs : [renderer];

  TextRenderer rendererWithPlaceholder(int index) {
    if (_subs.isEmpty) {
      return renderer;
    } else {
      var i = index;
      for (final sub in _subs) {
        final count = sub.placeholderSpans.length;
        if (i < count) {
          return sub;
        } else {
          i -= count;
        }
      }
      assert(false);
      return renderer;
    }
  }

  RenderComparison updateWith(
    WrappableText wt,
    RenderBox parent,
    TextDirection defaultTextDirection,
    DefaultTextStyle defaultTextStyle,
    Color? selectionColor,
  ) {
    var needsPaint = false;
    var needsLayout = false;

    final textSpan =
        TextSpan(style: defaultTextStyle.style, children: [wt.text]);
    final comparison =
        renderer._painter.text?.compareTo(textSpan) ?? RenderComparison.layout;
    switch (comparison) {
      case RenderComparison.identical:
      case RenderComparison.metadata:
        break;
      case RenderComparison.paint:
        needsPaint = true;
        break;
      case RenderComparison.layout:
        needsLayout = true;
        break;
    }

    if (needsPaint || needsLayout) {
      renderer
        .._painter.text = textSpan
        .._semanticsInfo = null
        .._cachedCombinedSemanticsInfos = null
        ..clearPlaceholderSpans();

      // `subsClearAndDispose()` is called during layout, so we only need to
      // clear semantics for `_subs` if `needsPaint`.
      if (needsPaint) {
        for (final sub in _subs) {
          sub._semanticsInfo = sub._cachedCombinedSemanticsInfos = null;
        }
      }
    }

    final textAlign =
        wt.textAlign ?? defaultTextStyle.textAlign ?? TextAlign.start;
    if (renderer._painter.textAlign != textAlign) {
      renderer._painter.textAlign = textAlign;
      needsLayout = true;
    }

    final textDirection = wt.textDirection ?? defaultTextDirection;
    if (renderer._painter.textDirection != textDirection) {
      renderer._painter.textDirection = textDirection;
      needsLayout = true;
    }

    final textScaler = wt.textScaler;
    if (renderer._painter.textScaler != textScaler) {
      renderer._painter.textScaler = textScaler;
      needsLayout = true;
    }

    final maxLines = wt.maxLines ?? defaultTextStyle.maxLines;
    if (renderer._painter.maxLines != maxLines) {
      renderer._painter.maxLines = maxLines;
      needsLayout = true;
    }

    final ellipsis =
        (wt.overflow ?? defaultTextStyle.overflow) == TextOverflow.ellipsis
            ? _kEllipsis
            : null;
    if (renderer._painter.ellipsis != ellipsis) {
      renderer._painter.ellipsis = ellipsis;
      needsLayout = true;
    }

    if (renderer._painter.locale != wt.locale) {
      renderer._painter.locale = wt.locale;
      needsLayout = true;
    }

    if (renderer._painter.strutStyle != wt.strutStyle) {
      renderer._painter.strutStyle = wt.strutStyle;
      needsLayout = true;
    }

    final textHeightBehavior =
        wt.textHeightBehavior ?? defaultTextStyle.textHeightBehavior;
    if (renderer._painter.textHeightBehavior != textHeightBehavior) {
      renderer._painter.textHeightBehavior = textHeightBehavior;
      needsLayout = true;
    }

    if (needsLayout) {
      parent.markNeedsLayout();
      // `subsClearAndDispose()` is called during layout, so no need for any
      // other cleanup here.
    } else {
      if (selectionColor != renderer.selectionColor) {
        renderer.selectionColor = selectionColor;
        for (final tr in renderers) {
          tr.selectionColor = selectionColor;
          if (!needsPaint &&
              (tr._lastSelectableFragments?.any((e) => e.value.hasSelection) ??
                  false)) {
            needsPaint = true;
          }
        }
      }

      if (needsPaint) {
        parent.markNeedsPaint();
      }
    }

    return comparison;
  }
}

///
/// TextRenderer
///
class TextRenderer with RenderTextMixin {
  TextRenderer._(
    this._parent,
    this._painter,
    this.startingPlaceholderIndex,
    this.selectionColor,
  ) : assert(_painter.text != null) {
    // uid = ++_instanceCount;
  }

  // static var _instanceCount = 0;

  // late int uid;
  final RenderBox _parent;
  final TextPainter _painter;
  final int startingPlaceholderIndex;
  List<PlaceholderSpan>? _placeholderSpans;

  TextPainter get textPainter => _painter;

  String toPlainText() => text.toPlainText(includeSemanticsLabels: false);

  // ignore: use_late_for_private_fields_and_variables
  Offset? _offset;
  set offset(Offset value) => _offset = value;

  Rect get textRect {
    final size = textSize;
    return Rect.fromLTWH(offset.dx, offset.dy, size.width, size.height);
  }

  int get nextPlaceholderIndex =>
      startingPlaceholderIndex + placeholderSpans.length;

  List<PlaceholderSpan> get placeholderSpans {
    if (_placeholderSpans == null) {
      _placeholderSpans = <PlaceholderSpan>[];
      text.visitChildren((span) {
        if (span is PlaceholderSpan) _placeholderSpans!.add(span);
        return true;
      });
    }
    return _placeholderSpans!;
  }

  void clearPlaceholderSpans() => _placeholderSpans = null;

  /// Computes the visual position of the glyphs for painting the text and the
  /// position of the inline widget children.
  void layout(BoxConstraints constraints) {
    _painter.layout(
        minWidth: constraints.minWidth, maxWidth: constraints.maxWidth);
  }

  TextRenderer copyWith(
    InlineSpan text,
    int startingPlaceholderIndex,
    int? maxLines,
  ) =>
      TextRenderer._(
        _parent,
        TextPainter(
          text: text,
          textAlign: _painter.textAlign,
          textDirection: _painter.textDirection,
          textScaler: _painter.textScaler,
          maxLines: maxLines,
          ellipsis: _painter.ellipsis,
          locale: _painter.locale,
          strutStyle: _painter.strutStyle,
          textWidthBasis: _painter.textWidthBasis,
          textHeightBehavior: _painter.textHeightBehavior,
        ),
        startingPlaceholderIndex,
        selectionColor,
      );

  TextBox placeholderBoxForWidgetIndex(int index) {
    final i = index - startingPlaceholderIndex;
    if ((_painter.inlinePlaceholderBoxes?.length ?? 0) > i) {
      return _painter.inlinePlaceholderBoxes![i];
    } else {
      assert(false);
      return TextBox.fromLTRBD(0, 0, 0, 0, _painter.textDirection!);
    }
  }

  double placeholderScaleForWidgetIndex(int index) {
    return 1.0;
    // final i = index - startingPlaceholderIndex;
    // if ((_painter.inlinePlaceholderScales?.length ?? 0) > i) {
    //   return _painter.inlinePlaceholderScales![i];
    // } else {
    //   assert(false);
    //   return 1.0;
    // }
  }

  /// Returns an estimate of the initial line height based on the initial font
  /// size, initial line height scale, and the text scale factor.
  double initialLineHeight() {
    final fontSize = text.initialFontSize(14.0);
    final lineHeightScale = text.initialLineHeightScale(1.12);
    return _painter.textScaler.scale(fontSize * lineHeightScale);
  }

  double initialScaledFontSize() {
    final fontSize = text.initialFontSize(14.0);
    return _painter.textScaler.scale(fontSize);
  }

  /// Sets the placeholder dimensions for this paragraph's inline widget
  /// children, if any. Returns true iff any of the children are floated.
  bool setPlaceholderDimensions(
    RenderBox? firstChild,
    BoxConstraints constraints,
    TextScaler textScaler,
  ) {
    if (firstChild == null) return false;

    final paragraphIndex = firstChild.floatData.index;

    // The children will be scaled by textScaleFactor during the painting
    // phase, so the constraints are divided by textScaleFactor.
    final childConstraints =
        BoxConstraints(maxWidth: constraints.maxWidth) / textScaleFactor;

    final placeholderDimensions = List<PlaceholderDimensions>.filled(
        placeholderSpans.length, PlaceholderDimensions.empty,
        growable: false);

    var hasFloatedChildren = false;
    RenderBox? child = firstChild;
    while (child != null && child.floatData.index == paragraphIndex) {
      final childParentData = child.parentData! as FloatColumnParentData;

      final i = child.floatData.placeholderIndex - startingPlaceholderIndex;
      if (i >= 0 && i < placeholderSpans.length) {
        if (child.floatData.float != FCFloat.none) {
          hasFloatedChildren = true;
          if (!child.hasSize) {
            _layoutChild(child, i, BoxConstraints.tight(Size.zero));
          }
        } else {
          placeholderDimensions[i] = _layoutChild(child, i, childConstraints);
        }
      }

      child = childParentData.nextSibling;
    }

    _painter.setPlaceholderDimensions(placeholderDimensions);

    return hasFloatedChildren;
  }

  /// Layout the [child] inline widget at the given [childIndex].
  PlaceholderDimensions _layoutChild(
    RenderBox child,
    int childIndex,
    BoxConstraints constraints, {
    bool dry = false,
  }) {
    assert(childIndex >= 0 && childIndex < placeholderSpans.length);

    double? baselineOffset;
    final Size childSize;
    if (!dry) {
      // Layout the child, it may have changed size.
      child.layout(constraints, parentUsesSize: true);

      childSize = child.size;
      switch (placeholderSpans[childIndex].alignment) {
        case ui.PlaceholderAlignment.baseline:
          baselineOffset = child
              .getDistanceToBaseline(placeholderSpans[childIndex].baseline!);
          break;
        default:
          baselineOffset = null;
          break;
      }
    } else {
      assert(placeholderSpans[childIndex].alignment !=
          ui.PlaceholderAlignment.baseline);
      childSize = child.getDryLayout(constraints);
    }

    return PlaceholderDimensions(
      size: childSize,
      alignment: placeholderSpans[childIndex].alignment,
      baseline: placeholderSpans[childIndex].baseline,
      baselineOffset: baselineOffset,
    );
  }

  // ------------------------------------------------------------------------
  // Selection related:
  //

  Color? selectionColor;

  // Should be null if selection is not enabled, i.e. [registrar] is null. The
  // text splits on [PlaceholderSpan.placeholderCodeUnit], and stores each
  // fragment in this list.
  List<SelectableFragment>? _lastSelectableFragments;

  /// The ongoing selections in this text.
  ///
  /// The selection does not include selections in [PlaceholderSpan] if there
  /// are any.
  @visibleForTesting
  List<TextSelection> get selections {
    if (_lastSelectableFragments == null) {
      return const <TextSelection>[];
    }
    final results = <TextSelection>[];
    for (final fragment in _lastSelectableFragments!) {
      if (fragment.textSelectionStart != null &&
          fragment.textSelectionEnd != null) {
        results.add(TextSelection(
            baseOffset: fragment.textSelectionStart!.offset,
            extentOffset: fragment.textSelectionEnd!.offset));
      }
    }
    return results;
  }

  /// The [SelectionRegistrar] this text will be, or is, registered to.
  SelectionRegistrar? get registrar => _registrar;
  SelectionRegistrar? _registrar;
  set registrar(SelectionRegistrar? value) {
    if (value == _registrar) {
      return;
    }
    _removeSelectionRegistrarSubscription();
    _disposeSelectableFragments();
    _registrar = value;
    _updateSelectionRegistrarSubscription();
  }

  void _updateSelectionRegistrarSubscription() {
    if (_registrar == null) {
      return;
    }
    _lastSelectableFragments ??= _getSelectableFragments();
    _lastSelectableFragments!.forEach(_registrar!.add);
    if (_lastSelectableFragments!.isNotEmpty) {
      _parent.markNeedsCompositingBitsUpdate();
    }
  }

  void _removeSelectionRegistrarSubscription() {
    if (registrar == null || _lastSelectableFragments == null) {
      return;
    }
    _lastSelectableFragments!.forEach(registrar!.remove);
  }

  List<SelectableFragment> _getSelectableFragments() {
    final plainText = text.toPlainText(includeSemanticsLabels: false);
    final result = <SelectableFragment>[];
    var start = 0;
    while (start < plainText.length) {
      var end = plainText.indexOf('\uFFFC', start);
      if (start != end) {
        if (end == -1) end = plainText.length;
        result.add(SelectableFragment(
            paragraph: this,
            range: TextRange(start: start, end: end),
            fullText: plainText));
        start = end;
      }
      start += 1;
    }
    return result;
  }

  void _disposeSelectableFragments() {
    if (_lastSelectableFragments == null) {
      return;
    }
    for (final fragment in _lastSelectableFragments!) {
      fragment.dispose();
    }
    _lastSelectableFragments = null;
  }

  void didChangeParagraphLayout() {
    _lastSelectableFragments
        ?.forEach((element) => element.didChangeParagraphLayout());
  }

  void markNeedsPaint() {
    _parent.markNeedsPaint();
  }

  void dispose() {
    _removeSelectionRegistrarSubscription();

    // TODO(ron): Do this instead of `_lastSelectableFragments = null;`?
    // _disposeSelectableFragments();

    // `_lastSelectableFragments` may hold references to this TextRenderer.
    // Release them manually to avoid retain cycles.
    _lastSelectableFragments = null;

    _painter.dispose();
  }

  bool get attached => _parent.attached;

  Matrix4 getTransformTo(RenderObject? ancestor) =>
      _parent.getTransformTo(ancestor);

  Offset globalToLocal(Offset point, {RenderObject? ancestor}) =>
      _parent.globalToLocal(point, ancestor: ancestor);

  // ------------------------------------------------------------------------
  // Semantics related:
  //

  List<InlineSpanSemanticsInformation>? _semanticsInfo;
  List<InlineSpanSemanticsInformation>? _cachedCombinedSemanticsInfos;

  List<InlineSpanSemanticsInformation> getSemanticsInfo({
    bool combined = false,
  }) {
    if (combined) {
      _cachedCombinedSemanticsInfos ??= combineSemanticsInfo(_semanticsInfo!);
      return _cachedCombinedSemanticsInfos!;
    } else {
      _semanticsInfo ??= text.getSemanticsInformation();
      return _semanticsInfo!;
    }
  }

  // ------------------------------------------------------------------------
  // RenderTextMixin overrides:
  //

  @override
  List<TextBox> getBoxesForSelection(
    TextSelection selection, {
    ui.BoxHeightStyle boxHeightStyle = ui.BoxHeightStyle.tight,
    ui.BoxWidthStyle boxWidthStyle = ui.BoxWidthStyle.tight,
  }) =>
      _painter.getBoxesForSelection(selection,
          boxHeightStyle: boxHeightStyle, boxWidthStyle: boxWidthStyle);

  @override
  double? getFullHeightForCaret(TextPosition position) =>
      _painter.getFullHeightForCaret(position, Rect.zero);

  @override
  Offset getOffsetForCaret(TextPosition position, Rect caretPrototype) =>
      _painter.getOffsetForCaret(position, caretPrototype);

  @override
  TextPosition getPositionForOffset(Offset offset) =>
      _painter.getPositionForOffset(offset);

  @override
  TextRange getWordBoundary(TextPosition position) =>
      _painter.getWordBoundary(position);

  @override
  double get height => _painter.height;

  @override
  Locale? get locale => _painter.locale;

  @override
  int? get maxLines => _painter.maxLines;

  @override
  Offset get offset => _offset!;

  @override
  RenderBox get renderBox => _parent;

  @override
  StrutStyle? get strutStyle => _painter.strutStyle;

  @override
  InlineSpan get text => _painter.text ?? const TextSpan(text: '');

  @override
  TextAlign get textAlign => _painter.textAlign;

  @override
  TextDirection get textDirection => _painter.textDirection!;

  @override
  bool get softWrap => true;

  @override
  TextHeightBehavior? get textHeightBehavior => _painter.textHeightBehavior;

  @override
  // ignore: deprecated_member_use
  double get textScaleFactor => _painter.textScaleFactor;

  @override
  TextScaler get textScaler => _painter.textScaler;

  @override
  Size get textSize => _painter.size;

  @override
  TextWidthBasis get textWidthBasis => _painter.textWidthBasis;

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_lastSelectableFragments != null) {
      for (final fragment in _lastSelectableFragments!) {
        fragment.paint(context, offset);
      }
    }

    _painter.paint(context.canvas, this.offset + offset);
  }

  @override
  double get width => _painter.width;
}

extension on RenderBox {
  FloatData get floatData => ((this as RenderMetaData).metaData as FloatData);
}
