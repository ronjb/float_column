// Copyright (c) 2021 Ron Booth. All rights reserved.
// Use of this source code is governed by a license that can be found in the
// LICENSE file.

import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'float_column_semantics_tag.dart';
import 'float_data.dart';
import 'inline_span_ext.dart';
import 'render_object_ext.dart';
import 'render_text.dart';
import 'shared.dart';
import 'util.dart';
import 'wrappable_text.dart';

/// Parent data for use with [RenderFloatColumn].
class FloatColumnParentData extends ContainerBoxParentData<RenderBox> {
  /// The scaling of the text.
  double? scale;

  @override
  String toString() {
    final values = <String>[
      'offset=$offset',
      if (scale != null) 'scale=$scale',
      super.toString(),
    ];
    return values.join('; ');
  }
}

/// A render object that displays a vertical list of widgets and paragraphs of
/// text.
///
/// ## Layout algorithm
///
/// _This section describes how [RenderFloatColumn] positions its children._
/// _See [BoxConstraints] for an introduction to box layout models._
///
/// Layout for a [RenderFloatColumn] proceeds in six steps:
///
/// 1. Layout each child with unbounded main axis constraints and the incoming
///    cross axis constraints. If the [crossAxisAlignment] is
///    [CrossAxisAlignment.stretch], instead use tight cross axis constraints
///    that match the incoming max extent in the cross axis.
///
/// 2. The cross axis extent of the [RenderFloatColumn] is the maximum cross
///    axis extent of the children (which will always satisfy the incoming
///    constraints).
///
/// 3. The main axis extent of the [RenderFloatColumn] is the sum of the main
///    axis extents of the children (subject to the incoming constraints).
class RenderFloatColumn extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, FloatColumnParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, FloatColumnParentData>,
        DebugOverflowIndicatorMixin,
        VisitChildrenOfAnyTypeMixin {
  /// Creates a FloatColumn render object.
  ///
  /// By default, the children are aligned to the start of the cross axis.
  RenderFloatColumn(
    this._textAndWidgets, {
    required CrossAxisAlignment crossAxisAlignment,
    required TextDirection textDirection,
    required DefaultTextStyle defaultTextStyle,
    required double defaultTextScaleFactor,
    Clip clipBehavior = Clip.none,
    List<RenderBox>? widgets,
  })  :
        // ignore: unnecessary_null_comparison
        assert(crossAxisAlignment != null),
        // ignore: unnecessary_null_comparison
        assert(clipBehavior != null),
        _internalTextAndWidgets = _textAndWidgets,
        _crossAxisAlignment = crossAxisAlignment,
        _textDirection = textDirection,
        _defaultTextStyle = defaultTextStyle,
        _defaultTextScaleFactor = defaultTextScaleFactor,
        _clipBehavior = clipBehavior {
    addAll(widgets);
    _updateCache();
  }

  // List<Object> get textAndWidgets => _textAndWidgets;
  List<Object> _textAndWidgets;
  List<Object> _internalTextAndWidgets;
  // ignore: avoid_setters_without_getters
  set textAndWidgets(List<Object> value) {
    assert(value != null); // ignore: unnecessary_null_comparison
    if (_textAndWidgets != value) {
      _internalTextAndWidgets = _textAndWidgets = value;
      _updateCache();
      markNeedsLayout();
    }
  }

  final _cache = <Object, WrappableTextRenderer>{};
  void _updateCache() {
    final keys = <Object>{};
    var needsSemanticsUpdate = false;
    for (var i = 0; i < _internalTextAndWidgets.length; i++) {
      var el = _internalTextAndWidgets[i];
      if (el is WrappableText) {
        // The key MUST be unique, so if it is not, make it so...
        if (keys.contains(el.defaultKey)) {
          var k = -i;
          var newKey = ValueKey(k);
          while (keys.contains(newKey)) {
            newKey = ValueKey(--k);
          }
          el = el.copyWith(key: newKey);

          // Before we make a change to `_internalTextAndWidgets`, make sure it
          // is a copy.
          if (identical(_internalTextAndWidgets, _textAndWidgets)) {
            _internalTextAndWidgets = List<Object>.of(_textAndWidgets);
          }

          _internalTextAndWidgets[i] = el;
        }

        keys.add(el.defaultKey);
        final wtr = _cache[el.defaultKey];
        if (wtr == null) {
          _cache[el.defaultKey] = WrappableTextRenderer(this, el, textDirection,
              defaultTextStyle, defaultTextScaleFactor);
        } else {
          final comparison = wtr.updateWith(el, this, textDirection,
              defaultTextStyle, defaultTextScaleFactor);

          // If any text renderers need to layout or paint, clear some
          // semantic related caches.
          if (comparison == RenderComparison.layout ||
              comparison == RenderComparison.paint) {
            _cachedAttributedLabel = null;
            _cachedCombinedSemanticsInfos = null;
            if (comparison == RenderComparison.paint) {
              needsSemanticsUpdate = true;
            }
          }
        }
      }
    }

    _cache.removeWhere((key, value) => !keys.contains(key));

    if (needsSemanticsUpdate) {
      // Calling `markNeedsSemanticsUpdate` can immediately result in a call to
      // `describeSemanticsConfiguration`, so it needs to be outside of the
      // `for` loop above.
      markNeedsSemanticsUpdate();
    }
  }

  /// How the children should be placed along the cross axis.
  ///
  /// If the [crossAxisAlignment] is either [CrossAxisAlignment.start] or
  /// [CrossAxisAlignment.end], then the [textDirection] must not be null.
  CrossAxisAlignment get crossAxisAlignment => _crossAxisAlignment;
  CrossAxisAlignment _crossAxisAlignment;
  set crossAxisAlignment(CrossAxisAlignment value) {
    assert(value != null); // ignore: unnecessary_null_comparison
    if (_crossAxisAlignment != value) {
      _crossAxisAlignment = value;
      markNeedsLayout();
    }
  }

  /// Controls the meaning of the [crossAxisAlignment] property's
  /// [CrossAxisAlignment.start] and [CrossAxisAlignment.end] values.
  ///
  /// If the [crossAxisAlignment] is either [CrossAxisAlignment.start] or
  /// [CrossAxisAlignment.end], then the [textDirection] must not be null.
  TextDirection get textDirection => _textDirection;
  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (_textDirection != value) {
      _textDirection = value;
      _updateCache();
      markNeedsLayout();
    }
  }

  DefaultTextStyle get defaultTextStyle => _defaultTextStyle;
  DefaultTextStyle _defaultTextStyle;
  set defaultTextStyle(DefaultTextStyle value) {
    if (_defaultTextStyle != value) {
      _defaultTextStyle = value;
      _updateCache();
      markNeedsLayout();
    }
  }

  double get defaultTextScaleFactor => _defaultTextScaleFactor;
  double _defaultTextScaleFactor;
  set defaultTextScaleFactor(double value) {
    if (_defaultTextScaleFactor != value) {
      _defaultTextScaleFactor = value;
      _updateCache();
      markNeedsLayout();
    }
  }

  bool get _debugHasNecessaryDirections {
    assert(crossAxisAlignment != null); // ignore: unnecessary_null_comparison
    if (crossAxisAlignment == CrossAxisAlignment.start ||
        crossAxisAlignment == CrossAxisAlignment.end) {
      assert(
          textDirection != null, // ignore: unnecessary_null_comparison
          '$runtimeType has a null textDirection, so the alignment cannot be '
          'resolved.');
    }
    return true;
  }

  // Set during layout if overflow occurred on the main axis.
  double _overflow = 0.0;

  // Check whether any meaningful overflow is present. Values below an epsilon
  // are treated as not overflowing.
  bool get _hasOverflow => _overflow > precisionErrorTolerance;

  /// {@macro flutter.material.Material.clipBehavior}
  ///
  /// Defaults to [Clip.none], and must not be null.
  Clip get clipBehavior => _clipBehavior;
  Clip _clipBehavior = Clip.none;
  set clipBehavior(Clip value) {
    assert(value != null); // ignore: unnecessary_null_comparison
    if (value != _clipBehavior) {
      _clipBehavior = value;
      markNeedsPaint();
      markNeedsSemanticsUpdate();
    }
  }

  @override
  void markNeedsLayout() {
    super.markNeedsLayout();
    _overflow = 0.0;
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! FloatColumnParentData) {
      child.parentData = FloatColumnParentData();
    }
  }

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    var hitText = false;

    // First, hit test text renderers.
    visitTextRendererChildren((tr) {
      final rect = tr.textRect;
      if (rect.contains(position)) {
        final textPosition = tr.getPositionForOffset(position - tr.offset);
        final span = tr.text.getSpanForPosition(textPosition);
        if (span != null && span is HitTestTarget) {
          result.add(HitTestEntry(span as HitTestTarget));
          hitText = true;
        }
      }

      return true; // !hitText; // Return false to stop the walk if hitText is true;
    });

    // Finally, hit test render object children.
    var child = firstChild;
    while (child != null) {
      final textParentData = child.parentData! as FloatColumnParentData;
      final transform = Matrix4.translationValues(
        textParentData.offset.dx,
        textParentData.offset.dy,
        0.0,
      )..scale(
          textParentData.scale,
          textParentData.scale,
          textParentData.scale,
        );
      final hitChild = result.addWithPaintTransform(
        transform: transform,
        position: position,
        hitTest: (result, transformed) {
          assert(() {
            final manualPosition =
                (position - textParentData.offset) / textParentData.scale!;
            return (transformed.dx - manualPosition.dx).abs() <
                    precisionErrorTolerance &&
                (transformed.dy - manualPosition.dy).abs() <
                    precisionErrorTolerance;
          }());
          return child!.hitTest(result, position: transformed);
        },
      );

      // Stop at the first child hit.
      if (hitChild) return true;

      child = childAfter(child);
    }

    return hitText;
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) {
    return defaultComputeDistanceToFirstActualBaseline(baseline);
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    assert(debugCannotComputeDryLayout(
        reason: 'Dry layout cannot be efficiently computed.'));
    return Size.zero;
  }

  @override
  void performLayout() {
    assert(_debugHasNecessaryDirections);

    _cachedCombinedSemanticsInfos = null;

    final constraints = this.constraints;
    final maxWidth = constraints.maxWidth;

    final BoxConstraints childConstraints;
    if (crossAxisAlignment == CrossAxisAlignment.stretch) {
      childConstraints = BoxConstraints.tightFor(width: maxWidth);
    } else {
      childConstraints = BoxConstraints(maxWidth: maxWidth);
    }

    // These will hold the rectangles of widgets that are floated to the left
    // or right.
    final floatL = <Rect>[];
    final floatR = <Rect>[];

    var child = firstChild;

    // This gets updated to the y position for the next child.
    var yPosNext = 0.0;

    // This gets updated to the previous non-floated child's bottom margin.
    var prevBottomMargin = 0.0;

    var i = 0;
    for (final el in _internalTextAndWidgets) {
      // If it is a Widget...
      if (el is Widget) {
        final floatData = child!.floatData;
        assert(floatData.index == i && floatData.placeholderIndex == 0);

        // If not floated, resolve the margin and update `yPosNext` and
        // `prevBottomMargin`.
        if (floatData.float == FCFloat.none) {
          final margin = floatData.margin.resolve(textDirection);
          final topMargin = math.max(prevBottomMargin, margin.top);
          yPosNext += topMargin;
          prevBottomMargin = margin.bottom;
        }

        final childParentData = child.parentData! as FloatColumnParentData;

        yPosNext = _layoutWidget(child, childParentData, childConstraints,
            yPosNext, maxWidth, floatData, floatL, floatR);

        assert(child.parentData == childParentData);
        child = childParentData.nextSibling;
      }

      // Else, if it is a WrappableText...
      else if (el is WrappableText) {
        final wtr = _cache[el.defaultKey]!;
        assert(wtr.renderer.placeholderSpans.isEmpty ||
            (child != null && child.floatData.index == i));

        // Resolve the margin and update `yPosNext` and `prevBottomMargin`.
        final margin = el.margin.resolve(wtr.textDirection);
        final topMargin = math.max(prevBottomMargin, margin.top);
        yPosNext += topMargin;
        prevBottomMargin = margin.bottom;

        yPosNext = _layoutWrappableText(el, wtr, child, childConstraints,
            yPosNext, maxWidth, floatL, floatR);

        // If this paragraph has inline widget children, set the `offset` and
        // `scale` for each.
        if (child != null && child.floatData.index == i) {
          var widgetIndex = 0;
          while (child != null && child.floatData.index == i) {
            assert(child.floatData.placeholderIndex == widgetIndex);
            final childParentData = child.parentData! as FloatColumnParentData;
            if (child.floatData.float == FCFloat.none) {
              final renderer = wtr.rendererWithPlaceholder(widgetIndex);
              final box = renderer.placeholderBoxForWidgetIndex(widgetIndex);
              childParentData
                ..offset = Offset(
                    box.left + renderer.offset.dx, box.top + renderer.offset.dy)
                ..scale = renderer.placeholderScaleForWidgetIndex(widgetIndex);
            }
            child = childParentData.nextSibling;
            widgetIndex++;
          }
        }
      } else {
        assert(false);
      }

      i++;
    }

    yPosNext += prevBottomMargin;
    final totalHeight =
        math.max(floatL.maxYBelow(yPosNext), floatR.maxYBelow(yPosNext));
    _overflow = totalHeight > constraints.maxHeight
        ? totalHeight - constraints.maxHeight
        : 0.0;
    size = constraints.constrain(Size(maxWidth, totalHeight));
  }

  /// Lays out the given [child] widget, and returns the y position for the
  /// next child.
  double _layoutWidget(
    RenderBox child,
    FloatColumnParentData parentData,
    BoxConstraints childConstraints,
    double yPos,
    double maxWidth,
    FloatData floatData,
    List<Rect> floatL,
    List<Rect> floatR,
  ) {
    final margin = floatData.margin.resolve(textDirection);
    final padding = floatData.padding.resolve(textDirection);

    final maxWidthMinusPadding = math.max(0.0,
        maxWidth - margin.left - margin.right - padding.left - padding.right);
    final childMaxWidth =
        math.min(maxWidthMinusPadding, maxWidth * floatData.maxWidthPercentage);

    var layoutConstraints = childConstraints;
    if (childMaxWidth != childConstraints.maxWidth) {
      layoutConstraints = childConstraints.copyWith(
        maxWidth: childMaxWidth,
        minWidth: math.min(layoutConstraints.minWidth, childMaxWidth),
      );
    }

    child.layout(layoutConstraints, parentUsesSize: true);

    var alignment = crossAxisAlignment;

    // Should this child widget be floated to the left or right?
    List<Rect>? addToFloatRects;
    if (floatData.float != FCFloat.none) {
      final float = resolveFloat(floatData.float, withDir: textDirection);
      assert(float == FCFloat.left || float == FCFloat.right);
      if (float == FCFloat.left) {
        addToFloatRects = floatL;
        alignment = isLTR ? CrossAxisAlignment.start : CrossAxisAlignment.end;
      } else {
        addToFloatRects = floatR;
        alignment = isRTL ? CrossAxisAlignment.start : CrossAxisAlignment.end;
      }
    }

    var yPosNext = yPos;

    // Check for `clear` and adjust `yPosNext` accordingly.
    final clear = resolveClear(floatData.clear, withDir: textDirection);
    final spacing = floatData.clearMinSpacing;
    if (clear == FCClear.left || clear == FCClear.both) {
      yPosNext = floatL.nextY(yPosNext, spacing);
    }
    if (clear == FCClear.right || clear == FCClear.both) {
      yPosNext = floatR.nextY(yPosNext, spacing);
    }

    final totalMinWidth = child.size.width + padding.left + padding.right;
    final minX = margin.left;
    final maxX = math.max(minX + totalMinWidth, maxWidth - margin.right);

    // Find space for this widget...
    var rect = findSpaceFor(
      startY: yPosNext,
      width: math.min(maxWidth, totalMinWidth),
      height: child.size.height + padding.top + padding.bottom,
      minX: minX,
      maxX: maxX,
      floatL: floatL,
      floatR: floatR,
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
    final xPos = xPosForChildWithWidth(
        child.size.width, alignment, rect.left, rect.right);
    parentData
      ..offset = Offset(xPos, rect.top)
      ..scale = 1.0;

    if (addToFloatRects != null) {
      // Include padding for the floated rect.
      addToFloatRects.add(Rect.fromLTRB(
        xPos - padding.left,
        rect.top - padding.top,
        xPos + child.size.width + padding.right,
        rect.top + child.size.height + padding.bottom,
      ));
      // This widget was floated, so set `yPosNext` back to `yPos`.
      yPosNext = yPos;
    } else {
      yPosNext = rect.top + child.size.height + padding.bottom;
    }

    return yPosNext;
  }

  /// Lays out the given WrappableText object, and returns the y position for
  /// the next child.
  double _layoutWrappableText(
    WrappableText wt,
    WrappableTextRenderer wtr,
    RenderBox? child,
    BoxConstraints childConstraints,
    double yPos,
    double maxWidth,
    List<Rect> floatL,
    List<Rect> floatR,
  ) {
    final margin = wt.margin.resolve(wtr.textDirection);
    final padding = wt.padding.resolve(wtr.textDirection);

    var yPosNext = yPos + padding.top;

    // Check for `clear` and adjust `yPosNext` accordingly.
    final clear = resolveClear(wt.clear, withDir: wtr.textDirection);
    if (clear == FCClear.left || clear == FCClear.both) {
      yPosNext = floatL.maxYBelow(yPosNext);
    }
    if (clear == FCClear.right || clear == FCClear.both) {
      yPosNext = floatR.maxYBelow(yPosNext);
    }

    // Clear the sub-paragraph renderers for wrapping text.
    wtr.subs.clear();

    // Keep track of the indices of the floated inline widget children that
    // have already been laid out, because they can only be laid out once.
    final laidOutFloaterIndices = <int>{};

    TextRenderer? rendererBeforeSplit;

    // Loop over this WrappableText's renderers. It starts out with the default
    // text renderer which includes all the text, but if the text needs to be
    // split because the available width and/or x position changes (because of
    // floated widgets), the the text is split into two new renderers that
    // replace the current renderer, and the loop is run again. This continues
    // until all the text is laid out, using as many renderers as necessary to
    // wrap around floated widget positions.

    var subIndex = -1;
    while (subIndex < wtr.subs.length) {
      // Get the estimated line height for the first line. We want to find
      // space for at least the first line of text.
      final estLineHeight = wtr[subIndex].initialLineHeight();

      // If the text starts with a line feed, remove the line feed, add the
      // line height to `yPosNext`, and re-run the loop.
      final initialText = wtr[subIndex].text.initialText();
      if (initialText.isNotEmpty &&
          initialText.codeUnitAt(0) == 0x0a &&
          (wtr[subIndex].maxLines == null || wtr[subIndex].maxLines! > 1)) {
        final textRenderer = wtr[subIndex];
        final split = textRenderer.text
            .splitAtCharacterIndex(1, ignoreFloatedWidgetSpans: true);
        if (split.length == 2) {
          if (subIndex == -1) {
            subIndex = 0;
          } else {
            wtr.subs.removeAt(subIndex);
          }

          final maxLines =
              textRenderer.maxLines == null ? null : textRenderer.maxLines! - 1;

          wtr.subs.add(textRenderer.copyWith(
              split.last,
              subIndex == 0 ? 0 : wtr.subs[subIndex - 1].nextPlaceholderIndex,
              maxLines));

          yPosNext += estLineHeight;

          // Re-run the loop, keeping the index the same.
          continue; //-------------------------------------------->
        }
      }

      final estScaledFontSize = wtr[subIndex].initialScaledFontSize();

      // Adjust the left padding based on indent value.
      final paddingLeft = padding.left + (subIndex <= 0 ? wt.indent : 0.0);

      final lineMinWidth =
          estScaledFontSize * 4.0 + paddingLeft + padding.right;
      final lineMinX = margin.left;
      final lineMaxX =
          math.max(lineMinX + lineMinWidth, maxWidth - margin.right);

      // Find space for a width of at least `estLineHeight * 4.0`. This may
      // need to be tweaked, or it could be an option passed in, or we could
      // layout the text and find the actual width of the first word, and that
      // could be the minimum width?
      var rect = findSpaceFor(
          startY: yPosNext,
          width: lineMinWidth,
          height: estLineHeight,
          minX: lineMinX,
          maxX: lineMaxX,
          floatL: floatL,
          floatR: floatR);

      // Adjust rect for padding.
      rect = Rect.fromLTRB(
        rect.left + paddingLeft,
        rect.top,
        rect.right - padding.right,
        rect.bottom,
      );

      // dmPrint('findSpaceFor $yPosNext, estLineHeight $estLineHeight: $rect');

      final subConstraints = childConstraints.copyWith(
        maxWidth: rect.width,
        minWidth: math.min(childConstraints.minWidth, rect.width),
      );

      var hasFloatedChildren = false;

      // If the sub-renderer has inline widget children, set placeholder
      // dimensions, which MUST be done before `wtr[subIndex].layout` is
      // called.
      if (wtr[subIndex].placeholderSpans.isNotEmpty) {
        assert(child != null);
        hasFloatedChildren = wtr[subIndex].setPlaceholderDimensions(child,
            subConstraints, wt.textScaleFactor ?? defaultTextScaleFactor);
      }

      // Layout the text and inline widget children.
      wtr[subIndex].layout(subConstraints);

      // If this is the default (-1) or last renderer, check to see if it needs
      // to be split.
      if (subIndex == -1 || subIndex == wtr.subs.length - 1) {
        // TODO(ron): It is possible that the estimated line height is less
        // than the actual first line height, which could cause the text in the
        // line to overlap floated widgets below it. This could be fixed by
        // using `painter.computeLineMetrics` to check, and then call
        // `findSpaceFor` again, if necessary, with the actual first line
        // height.

        // If this is the first line of the paragraph, and the indent value is
        // not zero, the second line has a different left padding, so it needs
        // to be laid out separately, so set the `bottom` value accordingly.
        final bottom = math.min(
            rect.bottom,
            subIndex > 0 || wt.indent == 0.0
                ? rect.bottom
                : rect.top + estLineHeight / 2.0);

        // `findSpaceFor` just checked for space for the first line of text.
        // Now that the text has been laid out, we need to see if the available
        // space extends the full height of the text.
        final startY = rect.top + estLineHeight;
        final nextFloatTop = math.min(
          floatL.topOfTopMostRectAtOrBelow(startY),
          floatR.topOfTopMostRectAtOrBelow(startY),
        );
        final nextChangeY = math.min(bottom, nextFloatTop);

        // If the text extends past `nextChangeY`, we need to split the text,
        // and layout each part individually...
        if (rect.top + wtr[subIndex].height > nextChangeY) {
          final span = wtr[subIndex].text;
          if (span is TextSpan) {
            //
            // Calculate the approximate x, y to split the text at, which
            // depends on the text direction.
            //
            // ⦿ Shows the x, y offsets the text should be split at:
            //
            // RTL example:
            //  | This is what you   ┌──────────┐
            //  | shall do; Love the ⦿          │
            //  ├────────┐ earth and ⦿──────────┤
            //  │        │ sun and the animals, |
            //  ├────────┘ despise riches, give ⦿
            //  │ alms to every one that asks...|
            //
            // LTR example:
            //  |   you what is This ┌──────────┐
            //  ⦿ the Love ;do shall │          │
            //  ├────────⦿ and earth └──────────┤
            //  │        │ ,animals the and sun |
            //  ├────────⦿ give ,riches despise |
            //  │...asks that one every to alms |
            //
            final dir = wtr[subIndex].textDirection;
            final x = dir == TextDirection.ltr ? rect.width : 0.0;
            final y =
                math.min(nextChangeY, nextFloatTop - estLineHeight) - rect.top;

            // Get the character index in the text from the point offset.
            var charIndex =
                wtr[subIndex].getPositionForOffset(Offset(x, y)).offset;
            if (charIndex > 0) {
              final text = span.toPlainText(includeSemanticsLabels: false);
              if (charIndex < text.length - 1) {
                // Skip trailing spaces.
                final codeUnits = text.codeUnits;
                while (charIndex < codeUnits.length - 1 &&
                    codeUnits[charIndex] == 0x0020) {
                  charIndex++;
                }

                // final str1 = text.substring(0, charIndex);
                // dmPrint('Splitting at ${Offset(x, y)} after "$str1"');

                // Split the TextSpan at `charIndex`.
                final split = span.splitAtCharacterIndex(charIndex,
                    ignoreFloatedWidgetSpans: true);

                // If it was split into two spans...
                if (split.length == 2) {
                  //
                  // This fixes a bug where, if a span is split right before a
                  // line feed, and we don't remove the line feed, it is
                  // rendered like two line feeds.
                  //
                  // If the second span starts with a '\n' (line feed), remove
                  // the '\n'.
                  if (text.codeUnitAt(charIndex) == 0x0a) {
                    final s2 = split.last.splitAtCharacterIndex(1,
                        ignoreFloatedWidgetSpans: true);
                    if (s2.length == 2) {
                      assert(
                          s2.first.toPlainText(includeSemanticsLabels: false) ==
                              '\n');
                      split[1] = s2.last;
                    }
                  }

                  final textRenderer = wtr[subIndex];
                  rendererBeforeSplit = textRenderer;
                  if (subIndex == -1) {
                    subIndex = 0;
                  } else {
                    wtr.subs.removeLast();
                  }

                  final part1 = textRenderer.copyWith(
                      split.first,
                      subIndex == 0
                          ? 0
                          : wtr.subs[subIndex - 1].nextPlaceholderIndex,
                      null);
                  wtr.subs.add(part1);

                  // If [maxLines] was set, [remainingLines] needs to be set to
                  // [maxLines] minus the number of lines in [part1].
                  int? remainingLines;
                  if (textRenderer.maxLines != null) {
                    // Need to layout [part1] and call `computeLineMetrics` to
                    // know how many lines it has.
                    part1.layout(subConstraints);
                    final lineMetrics = part1.textPainter.computeLineMetrics();
                    remainingLines =
                        textRenderer.maxLines! - lineMetrics.length;
                  }

                  // Only add [part2] if [remainingLines] is null or greater
                  // than zero.
                  if (remainingLines == null || remainingLines > 0) {
                    wtr.subs.add(textRenderer.copyWith(
                        split.last,
                        wtr.subs[subIndex].nextPlaceholderIndex,
                        remainingLines));
                  }

                  // Re-run the loop, keeping the index the same.
                  continue; //------------------------------------>
                }
              }
            }
          }
        }
      }

      // At this point renderer wtr[subIndex] has gone through its final
      // layout, so we can now layout its floated widget children, if any.

      if (hasFloatedChildren) {
        /// Local func that lays out the first floated child that has not
        /// already been laid out, if any, and returns true iff a child was
        /// laid out.
        ///
        /// The floated children need to be laid out one at a time because
        /// each time one is laid out the positions of subsequent floated
        /// children will likely be affected.
        bool layoutFloatedChildren(
            TextRenderer renderer, RenderBox? firstChild) {
          if (firstChild == null) return false;
          RenderBox? child = firstChild;
          final paragraphIndex = firstChild.floatData.index;
          while (child != null && child.floatData.index == paragraphIndex) {
            final childParentData = child.parentData! as FloatColumnParentData;
            final i = child.floatData.placeholderIndex -
                renderer.startingPlaceholderIndex;
            if (i >= 0 && i < renderer.placeholderSpans.length) {
              final ctpIndex = child.floatData.placeholderIndex;
              // If this child is floated...
              if (child.floatData.float != FCFloat.none &&
                  !laidOutFloaterIndices.contains(ctpIndex)) {
                laidOutFloaterIndices.add(ctpIndex);
                final boxTop =
                    renderer.placeholderBoxForWidgetIndex(ctpIndex).top;
                _layoutWidget(
                    child,
                    childParentData,
                    childConstraints,
                    boxTop + rect.top - estLineHeight,
                    maxWidth,
                    child.floatData,
                    floatL,
                    floatR);
                return true;
              }
            }
            child = childParentData.nextSibling;
          }
          return false;
        }

        final rerunLoop = layoutFloatedChildren(wtr[subIndex], child);
        if (rerunLoop) {
          // If the original renderer was split, undo the split because it
          // will likely need to be re-split differently.
          if (rendererBeforeSplit != null) {
            assert(wtr.subs.length == subIndex + 2);
            wtr.subs
              ..removeLast()
              ..removeLast()
              ..add(rendererBeforeSplit);
            rendererBeforeSplit = null;
          }

          // Re-run the loop, keeping the index the same.
          continue; //-------------------------------------------->
        }
      }

      // Clear this before the next loop.
      rendererBeforeSplit = null;

      CrossAxisAlignment alignment() {
        switch (wtr[subIndex].textAlign) {
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

      // Calculate `xPos` based on alignment and available space.
      final xPos = xPosForChildWithWidth(
          wtr[subIndex].width, alignment(), rect.left, rect.right);

      wtr[subIndex].offset = Offset(xPos, rect.top);
      yPosNext = rect.top + wtr[subIndex].height;

      subIndex++;
    } // while (subIndex < wtr.subs.length)

    return yPosNext + padding.bottom;
  }

  /// Given a child's [width] and [alignment], and the [minX] and [maxX],
  /// returns the x position for the child.
  double xPosForChildWithWidth(
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

  void _paintFloatColumn(PaintingContext context, Offset offset) {
    var child = firstChild;
    var i = 0;
    for (final el in _internalTextAndWidgets) {
      //---------------------------------------------------------------------
      // If it is a Widget
      //
      if (el is Widget) {
        final floatData = child!.floatData;
        assert(floatData.index == i && floatData.placeholderIndex == 0);

        final childParentData = child.parentData! as FloatColumnParentData;
        context.paintChild(child, childParentData.offset + offset);
        child = childParentData.nextSibling;
      }

      //---------------------------------------------------------------------
      // Else, if it is a WrappableText
      //
      else if (el is WrappableText) {
        final wtr = _cache[el.defaultKey]!;

        for (final textRenderer in wtr.renderers) {
          textRenderer.paint(context, offset);
        }

        // dmPrint('painted $i, text at ${wtr.offset! + offset}');

        // If this paragraph DOES have inline widget children...
        if (child != null && child.floatData.index == i) {
          var widgetIndex = 0;
          while (child != null && child.floatData.index == i) {
            assert(child.floatData.placeholderIndex == widgetIndex);
            final childParentData = child.parentData! as FloatColumnParentData;

            if (child.floatData.float != FCFloat.none) {
              // Floated inline widget children are rendered like normal
              // children.
              context.paintChild(child, childParentData.offset + offset);
            } else {
              // Non-floated inline widget children are scaled with the text.
              final scale = childParentData.scale!;
              context.pushTransform(
                needsCompositing,
                offset + childParentData.offset,
                Matrix4.diagonal3Values(scale, scale, scale),
                (context, offset) => context.paintChild(child!, offset),
              );
            }

            child = childParentData.nextSibling;
            widgetIndex++;
          }
        }
      } else {
        assert(false);
      }

      i++;
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (!_hasOverflow) {
      _paintFloatColumn(context, offset);
      return;
    }

    // There's no point in drawing the children if we're empty.
    if (size.isEmpty) return;

    // TODO(ron): In PR #102274, April 26th, 2022, the Flex class was updated
    // to just have the `else` part of this if-else statement. Should we make
    // the same change here? Needs to be tested...
    if (clipBehavior == Clip.none) {
      _clipRectLayer.layer = null;
      _paintFloatColumn(context, offset);
    } else {
      // We have overflow and the clipBehavior isn't none. Clip it.
      _clipRectLayer.layer = context.pushClipRect(
        needsCompositing,
        offset,
        Offset.zero & size,
        _paintFloatColumn,
        clipBehavior: clipBehavior,
        oldLayer: _clipRectLayer.layer,
      );
    }

    assert(() {
      final debugOverflowHints = <DiagnosticsNode>[
        ErrorDescription(
          'The edge of the $runtimeType that is overflowing has been marked '
          'in the rendering with a yellow and black striped pattern. This is '
          'usually caused by the contents being too big for the constraints.',
        ),
        ErrorHint(
          'This is considered an error condition because it indicates that '
          'there  is content that cannot be seen. If the content is '
          'legitimately bigger  than the available space, consider clipping '
          'it with a ClipRect widget  before putting it in the FloatColumn.',
        ),
      ];

      // Simulate a child rect that overflows by the right amount. This child
      // rect is never used for drawing, just for determining the overflow
      // location and amount.
      final overflowChildRect =
          Rect.fromLTWH(0.0, 0.0, 0.0, size.height + _overflow);
      paintOverflowIndicator(
          context, offset, Offset.zero & size, overflowChildRect,
          overflowHints: debugOverflowHints);
      return true;
    }());
  }

  final LayerHandle<ClipRectLayer> _clipRectLayer =
      LayerHandle<ClipRectLayer>();

  @override
  void dispose() {
    _clipRectLayer.layer = null;
    super.dispose();
  }

  @override
  Rect? describeApproximatePaintClip(RenderObject child) {
    switch (clipBehavior) {
      case Clip.none:
        return null;
      case Clip.hardEdge:
      case Clip.antiAlias:
      case Clip.antiAliasWithSaveLayer:
        return _hasOverflow ? Offset.zero & size : null;
    }
  }

  @override
  String toStringShort() {
    var header = super.toStringShort();
    if (!kReleaseMode && _hasOverflow) header += ' OVERFLOWING';
    return header;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(EnumProperty<CrossAxisAlignment>(
          'crossAxisAlignment', crossAxisAlignment))
      ..add(EnumProperty<TextDirection>('textDirection', textDirection,
          defaultValue: null));
  }

  //
  // Semantics related:
  //

  /// Collected during [describeSemanticsConfiguration], used by
  /// [assembleSemanticsNode].
  AttributedString? _cachedAttributedLabel;

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);

    final semanticsInfo = getSemanticsInfo();

    if (semanticsInfo.anyItem((info) => info.recognizer != null)) {
      config
        ..explicitChildNodes = true
        ..isSemanticBoundary = true;
    } else {
      if (_cachedAttributedLabel == null) {
        final buffer = StringBuffer();
        var offset = 0;
        final attributes = <StringAttribute>[];
        for (final entry in semanticsInfo.entries) {
          for (final list in entry.value) {
            for (final info in list) {
              final label = info.semanticsLabel ?? info.text;
              for (final infoAttribute in info.stringAttributes) {
                final originalRange = infoAttribute.range;
                attributes.add(
                  infoAttribute.copy(
                      range: TextRange(
                          start: offset + originalRange.start,
                          end: offset + originalRange.end)),
                );
              }
              buffer.write(label);
              offset += label.length;
            }
          }
        }
        _cachedAttributedLabel =
            AttributedString(buffer.toString(), attributes: attributes);
      }
      config
        ..attributedLabel = _cachedAttributedLabel!
        ..textDirection = textDirection;
    }
  }

  // Caches [SemanticsNode]s created during [assembleSemanticsNode] so they
  // can be re-used when [assembleSemanticsNode] is called again. This ensures
  // stable ids for the [SemanticsNode]s of [TextSpan]s across
  // [assembleSemanticsNode] invocations.
  LinkedHashMap<Key, SemanticsNode>? _cachedChildNodes;

  Map<int, List<List<InlineSpanSemanticsInformation>>>?
      _cachedCombinedSemanticsInfos;

  @override
  void assembleSemanticsNode(
    SemanticsNode node,
    SemanticsConfiguration config,
    Iterable<SemanticsNode> children,
  ) {
    final semanticsChildren = children;
    final newSemanticsChildren = <SemanticsNode>[];

    var renderChild = firstChild;

    var currentDirection = textDirection;
    var ordinal = 0.0;
    var semanticsChildIndex = 0;
    // ignore: prefer_collection_literals
    final newChildCache = LinkedHashMap<Key, SemanticsNode>();

    _cachedCombinedSemanticsInfos ??= getSemanticsInfo(combined: true);

    // dmPrint('\n\n************ assembleSemanticsNode *************');

    for (final entry in _cachedCombinedSemanticsInfos!.entries) {
      final floatColumnChildIndex = entry.key;
      var placeholderIndex = 0;

      final el = _internalTextAndWidgets[floatColumnChildIndex];

      final wtr = (el is WrappableText) ? _cache[el.defaultKey]! : null;
      assert(wtr == null ||
          wtr.renderer.placeholderSpans.isEmpty ||
          (renderChild != null &&
              renderChild.floatData.index == floatColumnChildIndex));

      var textRendererIndex = 0;

      for (final list in entry.value) {
        var textRangeStart = 0;
        for (final info in list) {
          if (info.isPlaceholder) {
            // A placeholder span may have 0 to multiple semantics nodes.
            while (semanticsChildren.length > semanticsChildIndex &&
                semanticsChildren.elementAt(semanticsChildIndex).isTagged(
                    FloatColumnPlaceholderSpanSemanticsTag(
                        floatColumnChildIndex, placeholderIndex))) {
              final semanticsChildNode =
                  semanticsChildren.elementAt(semanticsChildIndex);
              final parentData =
                  renderChild!.parentData! as FloatColumnParentData;

              assert(
                  parentData.scale != null || parentData.offset == Offset.zero);
              // parentData.scale may be null if the render object is truncated.
              if (parentData.scale != null) {
                final rect = Rect.fromLTWH(
                  semanticsChildNode.rect.left,
                  semanticsChildNode.rect.top,
                  semanticsChildNode.rect.width * parentData.scale!,
                  semanticsChildNode.rect.height * parentData.scale!,
                );
                semanticsChildNode.rect = rect;
                // dmPrint('Adding semantics node for widget '
                //     '$floatColumnChildIndex with rect $rect');
                newSemanticsChildren.add(semanticsChildNode);
              }

              semanticsChildIndex += 1;
            }
            renderChild = childAfter(renderChild!);
            placeholderIndex += 1;
          } else {
            if (wtr == null || textRendererIndex >= wtr.renderers.length) {
              assert(false);
            } else {
              final textRenderer = wtr.renderers[textRendererIndex];

              final selection = TextSelection(
                baseOffset: textRangeStart,
                extentOffset: textRangeStart + info.text.length,
              );
              textRangeStart += info.text.length;

              // dmPrint('\n\ncalling getBoxes for '
              //     '[${selection.baseOffset}, ${selection.extentOffset}] '
              //     'substring '
              //     '[${info.text}] in [${textRenderer.toPlainText()}]\n');

              final initialDirection = currentDirection;
              final rects = textRenderer.getBoxesForSelection(selection);
              if (rects.isNotEmpty) {
                var rect = rects.first.toRect();
                currentDirection = rects.first.direction;
                for (final textBox in rects.skip(1)) {
                  rect = rect.expandToInclude(textBox.toRect());
                  currentDirection = textBox.direction;
                }

                // Any of the text boxes may have had infinite dimensions.
                // We shouldn't pass infinite dimensions up to the bridges.
                rect = Rect.fromLTWH(
                  math.max(0.0, rect.left),
                  math.max(0.0, rect.top),
                  math.min(rect.width, constraints.maxWidth),
                  math.min(rect.height, constraints.maxHeight),
                );

                // Round the current rectangle to make this API testable and
                // add some padding so that the accessibility rects do not
                // overlap with the text.
                final currentRect = Rect.fromLTRB(
                  rect.left.floorToDouble() - 4.0,
                  rect.top.floorToDouble() - 4.0,
                  rect.right.ceilToDouble() + 4.0,
                  rect.bottom.ceilToDouble() + 4.0,
                );

                final configuration = SemanticsConfiguration()
                  ..sortKey = OrdinalSortKey(ordinal++)
                  ..textDirection = initialDirection
                  ..attributedLabel = AttributedString(
                      info.semanticsLabel ?? info.text,
                      attributes: info.stringAttributes);

                final recognizer = info.recognizer;
                if (recognizer != null) {
                  if (recognizer is TapGestureRecognizer) {
                    if (recognizer.onTap != null) {
                      configuration
                        ..onTap = recognizer.onTap
                        ..isLink = true;
                    }
                  } else if (recognizer is DoubleTapGestureRecognizer) {
                    if (recognizer.onDoubleTap != null) {
                      configuration
                        ..onTap = recognizer.onDoubleTap
                        ..isLink = true;
                    }
                  } else if (recognizer is LongPressGestureRecognizer) {
                    if (recognizer.onLongPress != null) {
                      configuration.onLongPress = recognizer.onLongPress;
                    }
                  } else {
                    assert(
                        false, '${recognizer.runtimeType} is not supported.');
                  }
                }

                // dmPrint('Adding semantics node for span '
                //     '$floatColumnChildIndex:'
                //     '$textRendererIndex with rect $rect '
                //     '${recognizer == null ? '' : 'WITH RECOGNIZER '}'
                //     'for text "${info.text}" ');

                if (node.parentPaintClipRect != null) {
                  final paintRect =
                      node.parentPaintClipRect!.intersect(currentRect);
                  configuration.isHidden =
                      paintRect.isEmpty && !currentRect.isEmpty;
                }
                late final SemanticsNode newChild;
                if (_cachedChildNodes?.isNotEmpty ?? false) {
                  newChild =
                      _cachedChildNodes!.remove(_cachedChildNodes!.keys.first)!;
                } else {
                  final key = UniqueKey();
                  newChild = SemanticsNode(
                    key: key,
                    showOnScreen: _createShowOnScreenFor(key),
                  );
                }
                newChild
                  ..updateWith(config: configuration)
                  ..rect = currentRect;
                newChildCache[newChild.key!] = newChild;
                newSemanticsChildren.add(newChild);
              }
            }
          }
        }
        textRendererIndex++;
      }
    }

    // Make sure we annotated all of the semantics children.
    assert(semanticsChildIndex == semanticsChildren.length);
    assert(renderChild == null);

    _cachedChildNodes = newChildCache;
    node.updateWith(
        config: config, childrenInInversePaintOrder: newSemanticsChildren);
  }

  VoidCallback? _createShowOnScreenFor(Key key) {
    return () {
      final node = _cachedChildNodes![key]!;
      showOnScreen(descendant: this, rect: node.rect);
    };
  }

  @override
  void clearSemantics() {
    super.clearSemantics();
    _cachedChildNodes = null;
  }

  //
  // Utility functions:
  //

  Map<int, List<List<InlineSpanSemanticsInformation>>> getSemanticsInfo({
    bool combined = false,
  }) {
    final semanticsInfo = <int, List<List<InlineSpanSemanticsInformation>>>{};

    var i = 0;
    for (final el in _internalTextAndWidgets) {
      if (el is Widget) {
        // Add a placeholder for each regular child widget.
        semanticsInfo[i] = [
          [InlineSpanSemanticsInformation.placeholder]
        ];
      } else if (el is WrappableText) {
        final wtr = _cache[el.defaultKey]!;
        semanticsInfo[i] = [
          for (final textRenderer in wtr.renderers)
            textRenderer.getSemanticsInfo(combined: combined)
        ];
      } else {
        assert(false);
      }

      i++;
    }

    return semanticsInfo;
  }

  @override
  bool visitChildrenOfAnyType(CancelableObjectVisitor visitor) {
    var child = firstChild;
    var i = 0;

    for (final el in _internalTextAndWidgets) {
      if (el is Widget) {
        final floatData = child!.floatData;
        assert(floatData.index == i && floatData.placeholderIndex == 0);

        // Visit the child widget's render object.
        if (!visitor(child)) return false; //------------------------------->
        child = childAfter(child);
      } else if (el is WrappableText) {
        final wtr = _cache[el.defaultKey]!;
        assert(wtr.renderer.placeholderSpans.isEmpty ||
            (child != null && child.floatData.index == i));

        // Visit all the text renderers.
        for (final textRenderer in wtr.renderers) {
          if (!visitor(textRenderer)) return false; //---------------------->
        }

        // Visit all the child render objects embedded in the text.
        var widgetIndex = 0;
        while (child != null && child.floatData.index == i) {
          assert(child.floatData.placeholderIndex == widgetIndex);
          if (!visitor(child)) return false; //----------------------------->
          child = childAfter(child);
          widgetIndex++;
        }
      } else {
        assert(false);
      }

      i++;
    }
    return true;
  }

  /// Walks [InlineSpan] children and each [InlineSpan]s descendants in
  /// pre-order and calls [visitor] for each span that has content.
  ///
  /// When [visitor] returns true, the walk continues. When [visitor]
  /// returns false, the walk ends.
  bool visitInlineSpanChildren(InlineSpanVisitor visitor) {
    for (final el in _internalTextAndWidgets) {
      if (el is WrappableText) {
        for (final textRenderer in _cache[el.defaultKey]!.renderers) {
          if (!textRenderer.text.visitChildren(visitor)) return false;
        }
      }
    }
    return true;
  }

  /// Walks [TextRenderer] children and calls [visitor] for each.
  ///
  /// When [visitor] returns true, the walk continues. When [visitor]
  /// returns false, the walk ends.
  bool visitTextRendererChildren(
    bool Function(TextRenderer textRenderer) visitor,
  ) {
    for (final el in _internalTextAndWidgets) {
      if (el is WrappableText) {
        for (final textRenderer in _cache[el.defaultKey]!.renderers) {
          if (!visitor(textRenderer)) return false;
        }
      }
    }
    return true;
  }
}

extension on RenderBox {
  FloatData get floatData => ((this as RenderMetaData).metaData as FloatData);
}

extension on RenderFloatColumn {
  bool get isLTR => textDirection == TextDirection.ltr;
  bool get isRTL => textDirection == TextDirection.rtl;
}

extension on WrappableText {
  Key get defaultKey => key ?? ValueKey(this);
}

extension _PrivateExtOnMapOfListOfList<S, T> on Map<S, List<List<T>>> {
  bool anyItem(bool Function(T) test) {
    for (final entry in entries) {
      for (final list in entry.value) {
        if (list.any(test)) return true;
      }
    }
    return false;
  }
}
