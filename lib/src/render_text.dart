// Copyright 2021 Tecarta, Inc. All rights reserved.
// Use of this source code is governed by a license that can be found in the LICENSE file.

import 'dart:ui' as ui show PlaceholderAlignment;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'float_tag.dart';
import 'inline_span_ext.dart';
import 'render_float_column.dart';
import 'wrappable_text.dart';

///
/// WrappableTextRenderer
///
class WrappableTextRenderer {
  WrappableTextRenderer(
    WrappableText ft,
    TextDirection defaultTextDirection,
    DefaultTextStyle defaultTextStyle,
    double defaultTextScaleFactor,
  ) : renderer = TextRenderer(
            TextPainter(
                text: TextSpan(style: defaultTextStyle.style, children: [ft.text]),
                textAlign: ft.textAlign ?? defaultTextStyle.textAlign ?? TextAlign.start,
                textDirection: ft.textDirection ?? defaultTextDirection,
                textScaleFactor: ft.textScaleFactor ?? defaultTextScaleFactor,
                locale: ft.locale,
                strutStyle: ft.strutStyle,
                textHeightBehavior: ft.textHeightBehavior),
            0);

  final TextRenderer renderer;

  final subs = <TextRenderer>[];

  TextRenderer operator [](int index) => index == -1 ? renderer : subs[index];

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

  void updateWith(
    WrappableText ft,
    RenderBox parent,
    TextDirection defaultTextDirection,
    DefaultTextStyle defaultTextStyle,
    double defaultTextScaleFactor,
  ) {
    var needsPaint = false;
    var needsLayout = false;

    final textSpan = TextSpan(style: defaultTextStyle.style, children: [ft.text]);
    switch (renderer.painter.text!.compareTo(textSpan)) {
      case RenderComparison.identical:
      case RenderComparison.metadata:
        break;
      case RenderComparison.paint:
        renderer.painter.text = textSpan;
        renderer.clearPlaceholderSpans();
        needsPaint = true;
        break;
      case RenderComparison.layout:
        renderer.painter.text = textSpan;
        renderer.clearPlaceholderSpans();
        needsLayout = true;
        break;
    }

    final textAlign = ft.textAlign ?? defaultTextStyle.textAlign ?? TextAlign.start;
    if (renderer.painter.textAlign != textAlign) {
      renderer.painter.textAlign = textAlign;
      needsLayout = true;
    }

    final textDirection = ft.textDirection ?? defaultTextDirection;
    if (renderer.painter.textDirection != textDirection) {
      renderer.painter.textDirection = textDirection;
      needsLayout = true;
    }

    final textScaleFactor = ft.textScaleFactor ?? defaultTextScaleFactor;
    if (renderer.painter.textScaleFactor != textScaleFactor) {
      renderer.painter.textScaleFactor = textScaleFactor;
      needsLayout = true;
    }

    if (renderer.painter.locale != ft.locale) {
      renderer.painter.locale = ft.locale;
      needsLayout = true;
    }

    if (renderer.painter.strutStyle != ft.strutStyle) {
      renderer.painter.strutStyle = ft.strutStyle;
      needsLayout = true;
    }

    if (renderer.painter.textHeightBehavior != ft.textHeightBehavior) {
      renderer.painter.textHeightBehavior = ft.textHeightBehavior;
      needsLayout = true;
    }

    if (needsLayout) {
      parent.markNeedsLayout();
    } else if (needsPaint) {
      parent
        ..markNeedsPaint()
        ..markNeedsSemanticsUpdate();
    }
  }
}

///
/// TextRenderer
///
class TextRenderer {
  TextRenderer(this.painter, this.startingPlaceholderIndex) : assert(painter.text != null);

  final TextPainter painter;
  final int startingPlaceholderIndex;
  List<PlaceholderSpan>? _placeholderSpans;
  Offset? offset;

  int get nextPlaceholderIndex => startingPlaceholderIndex + placeholderSpans.length;

  List<PlaceholderSpan> get placeholderSpans {
    if (_placeholderSpans == null) {
      _placeholderSpans = <PlaceholderSpan>[];
      painter.text!.visitChildren((span) {
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
    painter.layout(minWidth: constraints.minWidth, maxWidth: constraints.maxWidth);
  }

  TextRenderer copyWith(
    InlineSpan text,
    int startingPlaceholderIndex,
  ) =>
      TextRenderer(
          TextPainter(
              text: text,
              textAlign: painter.textAlign,
              textDirection: painter.textDirection,
              textScaleFactor: painter.textScaleFactor,
              locale: painter.locale,
              strutStyle: painter.strutStyle,
              textHeightBehavior: painter.textHeightBehavior),
          startingPlaceholderIndex);

  TextBox placeholderBoxForWidgetIndex(int index) {
    final i = index - startingPlaceholderIndex;
    if ((painter.inlinePlaceholderBoxes?.length ?? 0) > i) {
      return painter.inlinePlaceholderBoxes![i];
    } else {
      assert(false);
      return TextBox.fromLTRBD(0, 0, 0, 0, painter.textDirection!);
    }
  }

  double placeholderScaleForWidgetIndex(int index) {
    final i = index - startingPlaceholderIndex;
    if ((painter.inlinePlaceholderScales?.length ?? 0) > i) {
      return painter.inlinePlaceholderScales![i];
    } else {
      assert(false);
      return 1.0;
    }
  }

  /// Returns an estimate of the initial line height based on the initial font size,
  /// initial line height scale, and the text scale factor.
  double initialLineHeight() {
    final fontSize = painter.text!.initialFontSize() ?? 14.0;
    final lineHeightScale = painter.text!.initialLineHeightScale() ?? 1.12;
    return fontSize * lineHeightScale * painter.textScaleFactor;
  }

  double initialScaledFontSize() {
    final fontSize = painter.text!.initialFontSize() ?? 14.0;
    return fontSize * painter.textScaleFactor;
  }

  /// Sets the placeholder dimensions for this paragraph's inline widget children, if any.
  void setPlaceholderDimensions(
    RenderBox? firstChild,
    BoxConstraints constraints,
    double textScaleFactor,
  ) {
    if (firstChild == null) return;

    final paragraphIndex = firstChild.tag.index;

    // The children will be scaled by textScaleFactor during the painting phase,
    // so the constraints are divided by textScaleFactor.
    final childConstraints = BoxConstraints(maxWidth: constraints.maxWidth) / textScaleFactor;

    final placeholderDimensions = List<PlaceholderDimensions>.filled(
        placeholderSpans.length, PlaceholderDimensions.empty,
        growable: false);

    RenderBox? child = firstChild;
    while (child != null && child.tag.index == paragraphIndex) {
      final childParentData = child.parentData! as FloatColumnParentData;

      final i = child.tag.placeholderIndex - startingPlaceholderIndex;
      if (i >= 0 && i < placeholderSpans.length) {
        placeholderDimensions[i] = _layoutChild(child, i, childConstraints);
      }

      child = childParentData.nextSibling;
    }

    painter.setPlaceholderDimensions(placeholderDimensions);
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
      child.layout(
        constraints,
        parentUsesSize: true,
      );
      childSize = child.size;
      switch (placeholderSpans[childIndex].alignment) {
        case ui.PlaceholderAlignment.baseline:
          baselineOffset = child.getDistanceToBaseline(placeholderSpans[childIndex].baseline!);
          break;
        default:
          baselineOffset = null;
          break;
      }
    } else {
      assert(placeholderSpans[childIndex].alignment != ui.PlaceholderAlignment.baseline);
      childSize = child.getDryLayout(constraints);
    }

    return PlaceholderDimensions(
      size: childSize,
      alignment: placeholderSpans[childIndex].alignment,
      baseline: placeholderSpans[childIndex].baseline,
      baselineOffset: baselineOffset,
    );
  }
}

extension on RenderBox {
  FloatTag get tag => ((this as RenderMetaData).metaData as FloatTag);
}
