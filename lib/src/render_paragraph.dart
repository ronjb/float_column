// Copyright 2021 Ron Booth. All rights reserved.
// Use of this source code is governed by a license that can be found in the LICENSE file.

import 'dart:ui' as ui show PlaceholderAlignment;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'float_tag.dart';
import 'render_float_column.dart';
import 'wrappable_text.dart';

class RenderParagraphHelper {
  RenderParagraphHelper(WrappableText ft)
      : painter = TextPainter(
            text: ft.text,
            textAlign: ft.textAlign,
            textDirection: ft.textDirection,
            textScaleFactor: ft.textScaleFactor,
            locale: ft.locale,
            strutStyle: ft.strutStyle,
            textHeightBehavior: ft.textHeightBehavior) {
    _extractPlaceholderSpans(ft.text);
  }

  final TextPainter painter;

  late List<PlaceholderSpan> placeholderSpans;
  void _extractPlaceholderSpans(InlineSpan span) {
    placeholderSpans = <PlaceholderSpan>[];
    span.visitChildren((span) {
      if (span is PlaceholderSpan) placeholderSpans.add(span);
      return true;
    });
  }

  void updateWith(WrappableText ft, RenderBox parent) {
    var needsPaint = false;
    var needsLayout = false;

    switch (painter.text!.compareTo(ft.text)) {
      case RenderComparison.identical:
      case RenderComparison.metadata:
        break;
      case RenderComparison.paint:
        painter.text = ft.text;
        _extractPlaceholderSpans(ft.text);
        needsPaint = true;
        break;
      case RenderComparison.layout:
        painter.text = ft.text;
        _extractPlaceholderSpans(ft.text);
        needsLayout = true;
        break;
    }

    if (painter.textAlign != ft.textAlign) {
      painter.textAlign = ft.textAlign;
      needsLayout = true;
    }

    if (painter.textDirection != ft.textDirection) {
      painter.textDirection = ft.textDirection;
      needsLayout = true;
    }

    if (painter.textScaleFactor != ft.textScaleFactor) {
      painter.textScaleFactor = ft.textScaleFactor;
      needsLayout = true;
    }

    if (painter.locale != ft.locale) {
      painter.locale = ft.locale;
      needsLayout = true;
    }

    if (painter.strutStyle != ft.strutStyle) {
      painter.strutStyle = ft.strutStyle;
      needsLayout = true;
    }

    if (painter.textHeightBehavior != ft.textHeightBehavior) {
      painter.textHeightBehavior = ft.textHeightBehavior;
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

  /// Computes the visual position of the glyphs for painting the text and the
  /// position of the inline widget children.
  void layout(BoxConstraints constraints) {
    painter.layout(minWidth: constraints.minWidth, maxWidth: constraints.maxWidth);
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
      placeholderDimensions[child.tag.placeholderIndex] =
          _layoutChild(child, child.tag.placeholderIndex, childConstraints);
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
