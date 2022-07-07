// Copyright (c) 2021 Ron Booth. All rights reserved.
// Use of this source code is governed by a license that can be found in the
// LICENSE file.

import 'dart:ui' as ui show PlaceholderAlignment;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'float_data.dart';
import 'inline_span_ext.dart';
import 'render_float_column.dart';
import 'render_text_mixin.dart';
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
    double defaultTextScaleFactor,
  ) : renderer = TextRenderer(
          parent,
          TextPainter(
            text: TextSpan(style: defaultTextStyle.style, children: [wt.text]),
            textAlign:
                wt.textAlign ?? defaultTextStyle.textAlign ?? TextAlign.start,
            textDirection: wt.textDirection ?? defaultTextDirection,
            textScaleFactor: wt.textScaleFactor ?? defaultTextScaleFactor,
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
        );

  final TextRenderer renderer;

  final subs = <TextRenderer>[];

  TextRenderer operator [](int index) => index == -1 ? renderer : subs[index];

  TextDirection get textDirection => renderer._painter.textDirection!;

  List<TextRenderer> get renderers => subs.isNotEmpty ? subs : [renderer];

  TextRenderer rendererWithPlaceholder(int index) {
    if (subs.isEmpty) {
      return renderer;
    } else {
      var i = index;
      for (final sub in subs) {
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
    double defaultTextScaleFactor,
  ) {
    var needsPaint = false;
    var needsLayout = false;

    final textSpan =
        TextSpan(style: defaultTextStyle.style, children: [wt.text]);
    final comparison = renderer._painter.text!.compareTo(textSpan);
    switch (comparison) {
      case RenderComparison.identical:
      case RenderComparison.metadata:
        break;
      case RenderComparison.paint:
        renderer._painter.text = textSpan;
        renderer._semanticsInfo = null;
        renderer._cachedCombinedSemanticsInfos = null;
        renderer.clearPlaceholderSpans();
        needsPaint = true;
        break;
      case RenderComparison.layout:
        renderer._painter.text = textSpan;
        renderer._semanticsInfo = null;
        renderer._cachedCombinedSemanticsInfos = null;
        renderer.clearPlaceholderSpans();
        needsLayout = true;
        break;
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

    final textScaleFactor = wt.textScaleFactor ?? defaultTextScaleFactor;
    if (renderer._painter.textScaleFactor != textScaleFactor) {
      renderer._painter.textScaleFactor = textScaleFactor;
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
    } else if (needsPaint) {
      for (final sub in subs) {
        sub._semanticsInfo = sub._cachedCombinedSemanticsInfos = null;
      }
      parent.markNeedsPaint();
    }

    return comparison;
  }
}

///
/// TextRenderer
///
class TextRenderer with RenderTextMixin {
  TextRenderer(this._parent, this._painter, this.startingPlaceholderIndex)
      : assert(_painter.text != null);

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
    return Rect.fromLTWH(_offset!.dx, _offset!.dy, size.width, size.height);
  }

  int get nextPlaceholderIndex =>
      startingPlaceholderIndex + placeholderSpans.length;

  List<PlaceholderSpan> get placeholderSpans {
    if (_placeholderSpans == null) {
      _placeholderSpans = <PlaceholderSpan>[];
      _painter.text!.visitChildren((span) {
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
      TextRenderer(
          _parent,
          TextPainter(
              text: text,
              textAlign: _painter.textAlign,
              textDirection: _painter.textDirection,
              textScaleFactor: _painter.textScaleFactor,
              maxLines: maxLines ?? _painter.maxLines,
              ellipsis: _painter.ellipsis,
              locale: _painter.locale,
              strutStyle: _painter.strutStyle,
              textWidthBasis: _painter.textWidthBasis,
              textHeightBehavior: _painter.textHeightBehavior),
          startingPlaceholderIndex);

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
    final i = index - startingPlaceholderIndex;
    if ((_painter.inlinePlaceholderScales?.length ?? 0) > i) {
      return _painter.inlinePlaceholderScales![i];
    } else {
      assert(false);
      return 1.0;
    }
  }

  /// Returns an estimate of the initial line height based on the initial font
  /// size, initial line height scale, and the text scale factor.
  double initialLineHeight() {
    final fontSize = _painter.text!.initialFontSize(14.0);
    final lineHeightScale = _painter.text!.initialLineHeightScale(1.12);
    return fontSize * lineHeightScale * _painter.textScaleFactor;
  }

  double initialScaledFontSize() {
    final fontSize = _painter.text!.initialFontSize(14.0);
    return fontSize * _painter.textScaleFactor;
  }

  /// Sets the placeholder dimensions for this paragraph's inline widget
  /// children, if any. Returns true iff any of the children are floated.
  bool setPlaceholderDimensions(
    RenderBox? firstChild,
    BoxConstraints constraints,
    double textScaleFactor,
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
      if (!child.hasSize) {
        // TODO(ron): Maybe need to call this every time in case constraints
        // change?
        child.layout(
          constraints,
          parentUsesSize: true,
        );
      }
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

  //
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

  //
  // RenderTextAdapter overrides:
  //

  @override
  List<TextBox> getBoxesForSelection(TextSelection selection) =>
      _painter.getBoxesForSelection(selection);

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
  InlineSpan get text => _painter.text!;

  @override
  TextAlign get textAlign => _painter.textAlign;

  @override
  TextDirection get textDirection => _painter.textDirection!;

  @override
  TextHeightBehavior? get textHeightBehavior => _painter.textHeightBehavior;

  @override
  double get textScaleFactor => _painter.textScaleFactor;

  @override
  Size get textSize => _painter.size;

  @override
  TextWidthBasis get textWidthBasis => _painter.textWidthBasis;

  @override
  void paint(PaintingContext context, Offset offset) {
    _painter.paint(context.canvas, this.offset + offset);
  }

  @override
  double get width => _painter.width;
}

extension on RenderBox {
  FloatData get floatData => ((this as RenderMetaData).metaData as FloatData);
}
