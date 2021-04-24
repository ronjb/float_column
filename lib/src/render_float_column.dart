// Copyright 2021 Ron Booth. All rights reserved.
// Use of this source code is governed by a license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'float_tag.dart';
import 'inline_span_ext.dart';
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

/// A render object that displays a vertical list of widgets and paragraphs of text.
///
/// ## Layout algorithm
///
/// _This section describes how the framework causes [RenderFloatColumn] to position
/// its children._
/// _See [BoxConstraints] for an introduction to box layout models._
///
/// Layout for a [RenderFloatColumn] proceeds in six steps:
///
/// 1. Layout each child with unbounded main axis constraints and the incoming
///    cross axis constraints. If the [crossAxisAlignment] is
///    [CrossAxisAlignment.stretch], instead use tight cross axis constraints
///    that match the incoming max extent in the cross axis.
///
/// 2. The cross axis extent of the [RenderFloatColumn] is the maximum cross axis
///    extent of the children (which will always satisfy the incoming
///    constraints).
///
/// 3. The main axis extent of the [RenderFloatColumn] is the sum of the main axis
///    extents of the children (subject to the incoming constraints).
///
class RenderFloatColumn extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, FloatColumnParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, FloatColumnParentData>,
        DebugOverflowIndicatorMixin {
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
  })  : assert(crossAxisAlignment != null), // ignore: unnecessary_null_comparison
        assert(clipBehavior != null), // ignore: unnecessary_null_comparison
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
    for (var i = 0; i < _internalTextAndWidgets.length; i++) {
      var el = _internalTextAndWidgets[i];
      if (el is WrappableText) {
        // The key MUST be unique, so if it is not, make it so...
        if (keys.contains(el.key)) {
          var k = -i;
          var newKey = ValueKey(k);
          while (keys.contains(newKey)) {
            newKey = ValueKey(--k);
          }
          el = el.copyWith(key: newKey);

          // Before we make a change to `_internalTextAndWidgets`, make sure it is a copy.
          if (identical(_internalTextAndWidgets, _textAndWidgets)) {
            _internalTextAndWidgets = List<Object>.of(_textAndWidgets);
          }

          _internalTextAndWidgets[i] = el;
        }

        keys.add(el.key);
        final prh = _cache[el.key];
        if (prh == null) {
          _cache[el.key] =
              WrappableTextRenderer(el, textDirection, defaultTextStyle, defaultTextScaleFactor);
        } else {
          prh.updateWith(el, this, textDirection, defaultTextStyle, defaultTextScaleFactor);
        }
      }
    }

    _cache.removeWhere((key, value) => !keys.contains(key));
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
          '$runtimeType has a null textDirection, so the alignment cannot be resolved.');
    }
    return true;
  }

  // Set during layout if overflow occurred on the main axis.
  double _overflow = 0;
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
    _overflow = 0;
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! FloatColumnParentData) child.parentData = FloatColumnParentData();
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }

  /*
  double _getIntrinsicSize({
    required Axis sizingDirection,
    required double extent, // the extent in the direction that isn't the sizing direction
    required _ChildSizingFunction childSize, // a method to find the size in the sizing direction
  }) {
    if (sizingDirection == Axis.vertical) {
      // INTRINSIC MAIN SIZE
      // Intrinsic main size is the smallest size the container can take
      // while maintaining the min/max-content contributions of its items.

      var totalSize = 0.0;
      var child = firstChild;
      while (child != null) {
        totalSize += childSize(child, extent);
        final childParentData = child.parentData! as FloatColumnParentData;
        child = childParentData.nextSibling;
      }
      return totalSize;
    } else {
      // INTRINSIC CROSS SIZE
      // Intrinsic cross size is the max of the intrinsic cross sizes of the
      // children, after the children are fit into the available space,
      // with the children sized using their max intrinsic dimensions.

      var maxCrossSize = 0.0;
      var child = firstChild;
      while (child != null) {
        late final double mainSize;
        late final double crossSize;
        mainSize = child.getMaxIntrinsicHeight(double.infinity);
        crossSize = childSize(child, mainSize);
        maxCrossSize = math.max(maxCrossSize, crossSize);
        final childParentData = child.parentData! as FloatColumnParentData;
        child = childParentData.nextSibling;
      }
      return maxCrossSize;
    }
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    return _getIntrinsicSize(
      sizingDirection: Axis.horizontal,
      extent: height,
      childSize: (child, extent) => child.getMinIntrinsicWidth(extent),
    );
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    return _getIntrinsicSize(
      sizingDirection: Axis.horizontal,
      extent: height,
      childSize: (child, extent) => child.getMaxIntrinsicWidth(extent),
    );
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    return _getIntrinsicSize(
      sizingDirection: Axis.vertical,
      extent: width,
      childSize: (child, extent) => child.getMinIntrinsicHeight(extent),
    );
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    return _getIntrinsicSize(
      sizingDirection: Axis.vertical,
      extent: width,
      childSize: (child, extent) => child.getMaxIntrinsicHeight(extent),
    );
  }
  */

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) {
    return defaultComputeDistanceToFirstActualBaseline(baseline);
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    assert(debugCannotComputeDryLayout(reason: 'Dry layout cannot be efficiently computed.'));
    return Size.zero;

    /*
    final sizes = _computeSizes(
      layoutChild: ChildLayoutHelper.dryLayoutChild,
      constraints: constraints,
    );

    return constraints.constrain(Size(sizes.crossSize, sizes.mainSize));
    */
  }

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

  @override
  void performLayout() {
    assert(_debugHasNecessaryDirections);

    final constraints = this.constraints;
    final maxWidth = constraints.maxWidth;

    final BoxConstraints childConstraints;
    if (crossAxisAlignment == CrossAxisAlignment.stretch) {
      childConstraints = BoxConstraints.tightFor(width: maxWidth);
    } else {
      childConstraints = BoxConstraints(maxWidth: maxWidth);
    }

    var yPosNext = 0.0;
    var child = firstChild;

    final floatL = <Rect>[];
    final floatR = <Rect>[];

    // final lineHeight = (defaultTextStyle.style.fontSize ?? 14.0) *
    //     (defaultTextStyle.style.height ?? 1.15) *
    //     defaultTextScaleFactor;
    // dmPrint('RenderFloatColumn performLayout, lineHeight = $lineHeight');

    var i = 0;
    for (final el in _internalTextAndWidgets) {
      //---------------------------------------------------------------------
      // If it is a Widget
      //
      if (el is Widget) {
        final tag = child!.tag;
        assert(tag.index == i && tag.placeholderIndex == 0);

        final childParentData = child.parentData! as FloatColumnParentData;
        child.layout(childConstraints, parentUsesSize: true);
        final childSize = child.size;

        var alignment = crossAxisAlignment;

        // Should this child widget be floated to the left or right?
        List<Rect>? addToFloatRects;
        if (tag.float != FCFloat.none) {
          final float = resolveFloat(tag.float, withDir: textDirection);
          assert(float == FCFloat.left || float == FCFloat.right);
          if (float == FCFloat.left) {
            addToFloatRects = floatL;
            alignment = isLTR ? CrossAxisAlignment.start : CrossAxisAlignment.end;
          } else {
            addToFloatRects = floatR;
            alignment = isRTL ? CrossAxisAlignment.start : CrossAxisAlignment.end;
          }
        }

        var yPos = yPosNext;

        // Check for `clear` and adjust `yPos` accordingly.
        final clear = resolveClear(tag.clear, withDir: textDirection);
        if (clear == FCClear.left || clear == FCClear.both) yPos = floatL.maxY(yPos);
        if (clear == FCClear.right || clear == FCClear.both) yPos = floatR.maxY(yPos);

        // Find space for this widget...
        final rect = findSpaceFor(
          startY: yPos,
          width: childSize.width,
          height: childSize.height,
          maxX: maxWidth,
          floatL: floatL,
          floatR: floatR,
        );
        yPos = rect.top;

        // Calculate `xPos` based on alignment and available space.
        final xPos = xPosForChildWithWidth(child.size.width, alignment, rect.left, rect.right);
        childParentData.offset = Offset(xPos, yPos);

        if (addToFloatRects != null) {
          addToFloatRects.add(Rect.fromLTWH(xPos, yPos, childSize.width, childSize.height));
        } else {
          final childBottom = yPos + childSize.height;
          if (childBottom > yPosNext) yPosNext = childBottom;
        }

        assert(child.parentData == childParentData);
        child = childParentData.nextSibling;
      }

      //---------------------------------------------------------------------
      // Else, if it is a WrappableText
      //
      else if (el is WrappableText) {
        final wtr = _cache[el.key]!;

        // Check for `clear` and adjust `yPosNext` accordingly.
        final clear = resolveClear(el.clear, withDir: textDirection);
        if (clear == FCClear.left || clear == FCClear.both) yPosNext = floatL.maxY(yPosNext);
        if (clear == FCClear.right || clear == FCClear.both) yPosNext = floatR.maxY(yPosNext);

        // Clear the subs (sub-paragraph renderers for wrapping text).
        wtr.subs.clear();

        //
        // Loop over this WrappableText's renderers. It starts out with the default text
        // renderer which includes all the text, but if the text needs to be split because
        // the available width and/or x position changes (because of float widgets), the
        // the text is split into two new renderers that replace the current renderer,
        // and the loop is run again. This continues until all the text is layed-out,
        // using as many renderers as necessary to wrap around float widget positions.
        //
        var subIndex = -1;
        while (subIndex < wtr.subs.length) {
          var yPos = yPosNext;

          final lineHeight = wtr[subIndex].initialLineHeight();
          dmPrint('Finding space for text at $yPos with lineHeight = $lineHeight');

          // Find space for a width of at least `lineHeight * 4.0`. This may need to be
          // tweaked, or it could be an option passed in, or we could layout the text and
          // find the actual width of the first word, and that could be the minimum width?
          final rect = findSpaceFor(
              startY: yPos,
              width: math.min(maxWidth, lineHeight * 4.0),
              height: lineHeight,
              maxX: maxWidth,
              floatL: floatL,
              floatR: floatR);
          dmPrint('Space for text: $rect');
          yPos = rect.top;

          final subConstraints = childConstraints.copyWith(maxWidth: rect.width);

          // If sub-renderer has inline widget children, set placeholder dimensions.
          if (wtr[subIndex].placeholderSpans.isNotEmpty) {
            assert(child != null && child.tag.index == i);
            wtr[subIndex].setPlaceholderDimensions(
                child, subConstraints, el.textScaleFactor ?? defaultTextScaleFactor);
          }

          // Layout the text and inline widget children.
          wtr[subIndex].layout(subConstraints);

          // If this is the default (-1) or last renderer, check to see if it needs to be
          // split.
          if (subIndex == -1 || subIndex == wtr.subs.length - 1) {
            // `findSpaceFor` just checked for space for the first line of text. Now that
            // the text has been layed-out, we need to see if the available space extends
            // the full height of the layed-out text.
            // TODO(ron): ... wtr[subIndex].painter.height

            // The `rect.bottom` is where the layout of available space for the text changes,
            // so if the text extends past `rect.bottom`, we need to split the text, and layout
            // each part individually...
            if (yPos + wtr[subIndex].painter.height > rect.bottom) {
              final span = wtr[subIndex].painter.text;
              if (span is TextSpan) {
                final textPos =
                    wtr[subIndex].painter.getPositionForOffset(Offset(rect.width, rect.height));
                if (textPos.offset > 0) {
                  // TODO(ron): ...

                  if (kDebugMode) {
                    final text =
                        span.toPlainText(includeSemanticsLabels: false, includePlaceholders: true);
                    final sub = text.substring(0, textPos.offset);
                    dmPrint('split text after "$sub"');
                  }

                  final split = span.splitAtCharacterIndex(textPos.offset);
                  if (split.length == 2) {
                    final textRenderer = wtr[subIndex];
                    if (subIndex == -1) {
                      subIndex = 0;
                    } else {
                      wtr.subs.removeLast();
                    }
                    wtr.subs
                      ..add(textRenderer.copyWith(split.first,
                          subIndex == 0 ? 0 : wtr.subs[subIndex - 1].nextPlaceholderIndex))
                      ..add(textRenderer.copyWith(
                          split.last, wtr.subs[subIndex].nextPlaceholderIndex));

                    // Re-run the loop, keeping the index the same.
                    continue;
                  }
                }
              }

              // final selection = TextSelection(baseOffset: 0, extentOffset: text.length);
              // final boxes = wtr.painter.getBoxesForSelection(selection);
              // for (final box in boxes) {
              //   dmPrint(box);
              // }
            }
          }

          // Calculate `xPos` based on alignment and available space.
          final xPos = xPosForChildWithWidth(
              wtr[subIndex].painter.width, crossAxisAlignment, rect.left, rect.right);

          wtr[subIndex].offset = Offset(xPos, yPos);
          yPosNext = yPos + wtr[subIndex].painter.height;

          subIndex++;
        }

        // If this paragraph has inline widget children, set the `offset` and `scale` for each.
        if (child != null && child.tag.index == i) {
          var widgetIndex = 0;
          while (child != null && child.tag.index == i) {
            assert(child.tag.placeholderIndex == widgetIndex);

            final renderer = wtr.rendererWithPlaceholder(widgetIndex);
            final box = renderer.placeholderBoxForWidgetIndex(widgetIndex);
            final childParentData = child.parentData! as FloatColumnParentData
              ..offset = Offset(box.left + renderer.offset!.dx, box.top + renderer.offset!.dy)
              ..scale = renderer.placeholderScaleForWidgetIndex(widgetIndex);

            child = childParentData.nextSibling;
            widgetIndex++;
          }
        }
      } else {
        assert(false);
      }

      i++;
    }

    final totalHeight = math.max(floatL.maxY(yPosNext), floatR.maxY(yPosNext));
    size = constraints.constrain(Size(maxWidth, totalHeight));
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    var child = firstChild;
    var i = 0;
    for (final el in _internalTextAndWidgets) {
      //---------------------------------------------------------------------
      // If it is a Widget
      //
      if (el is Widget) {
        final tag = child!.tag;
        assert(tag.index == i && tag.placeholderIndex == 0);

        final childParentData = child.parentData! as FloatColumnParentData;
        context.paintChild(child, childParentData.offset + offset);
        child = childParentData.nextSibling;

        // dmPrint('painted $i, a widget at ${childParentData.offset + offset}');
      }

      //---------------------------------------------------------------------
      // Else, if it is a WrappableText
      //
      else if (el is WrappableText) {
        final wtr = _cache[el.key]!;

        for (final textRenderer in wtr.renderers) {
          textRenderer.painter.paint(context.canvas, textRenderer.offset! + offset);
        }

        // dmPrint('painted $i, text at ${wtr.offset! + offset}');

        // If this paragraph DOES have inline widget children...
        if (child != null && child.tag.index == i) {
          var widgetIndex = 0;
          while (child != null && child.tag.index == i) {
            assert(child.tag.placeholderIndex == widgetIndex);
            final childParentData = child.parentData! as FloatColumnParentData;

            final scale = childParentData.scale!;
            context.pushTransform(
              needsCompositing,
              offset + childParentData.offset,
              Matrix4.diagonal3Values(scale, scale, scale),
              (context, offset) {
                context.paintChild(child!, offset);
                // dmPrint('painted $i:$widgetIndex, a widget in text at $offset');
              },
            );

            child = childParentData.nextSibling;
            widgetIndex++;
          }
        }
      } else {
        assert(false);
      }

      i++;
    }

    /*
    if (!_hasOverflow) {
      defaultPaint(context, offset);
      return;
    }

    // There's no point in drawing the children if we're empty.
    if (size.isEmpty) return;

    if (clipBehavior == Clip.none) {
      _clipRectLayer = null;
      defaultPaint(context, offset);
    } else {
      // We have overflow and the clipBehavior isn't none. Clip it.
      _clipRectLayer = context.pushClipRect(
          needsCompositing, offset, Offset.zero & size, defaultPaint,
          clipBehavior: clipBehavior, oldLayer: _clipRectLayer);
    }

    assert(() {
      // Only set this if it's null to save work.
      final debugOverflowHints = <DiagnosticsNode>[
        ErrorDescription('The edge of the $runtimeType that is overflowing has been '
            'marked in the rendering with a yellow and black striped pattern. This is '
            'usually caused by the contents being too big for the constraints.'),
        ErrorHint('This is considered an error condition because it indicates that there '
            'is content that cannot be seen. If the content is legitimately bigger than '
            'the available space, consider placing the $runtimeType in a scrollable '
            'container, like a ListView.'),
      ];

      // Simulate a child rect that overflows by the right amount. This child
      // rect is never used for drawing, just for determining the overflow
      // location and amount.
      final Rect overflowChildRect;
      overflowChildRect = Rect.fromLTWH(0.0, 0.0, 0.0, size.height + _overflow);
      paintOverflowIndicator(context, offset, Offset.zero & size, overflowChildRect,
          overflowHints: debugOverflowHints);
      return true;
    }());
    */
  }

  // ClipRectLayer? _clipRectLayer;

  @override
  Rect? describeApproximatePaintClip(RenderObject child) =>
      _hasOverflow ? Offset.zero & size : null;

  @override
  String toStringShort() {
    var header = super.toStringShort();
    if (_hasOverflow) header += ' OVERFLOWING';
    return header;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(EnumProperty<CrossAxisAlignment>('crossAxisAlignment', crossAxisAlignment))
      ..add(EnumProperty<TextDirection>('textDirection', textDirection, defaultValue: null));
  }
}

extension on RenderBox {
  FloatTag get tag => ((this as RenderMetaData).metaData as FloatTag);
}

extension on RenderFloatColumn {
  bool get isLTR => textDirection == TextDirection.ltr;
  bool get isRTL => textDirection == TextDirection.rtl;
}

/* Old code from `performLayout`:

    ...

    final sizes = _computeSizes(
      layoutChild: ChildLayoutHelper.layoutChild,
      constraints: constraints,
    );

    final allocatedSize = sizes.allocatedSize;
    var actualSize = sizes.mainSize;
    var crossSize = sizes.crossSize;

    // Align items along the main axis.
    size = constraints.constrain(Size(crossSize, actualSize));
    actualSize = size.height;
    crossSize = size.width;
    final actualSizeDelta = actualSize - allocatedSize;
    _overflow = math.max(0.0, -actualSizeDelta);

    // Position elements
    var childMainPosition = 0.0;
    var child = firstChild;
    while (child != null) {
      final childParentData = child.parentData! as FloatColumnParentData;
      final double childCrossPosition;
      switch (crossAxisAlignment) {
        case CrossAxisAlignment.start:
        case CrossAxisAlignment.end:
          childCrossPosition =
              crossAxisAlignment == CrossAxisAlignment.start ? 0.0 : crossSize - child.size.width;
          break;
        case CrossAxisAlignment.center:
          childCrossPosition = crossSize / 2.0 - child.size.width / 2.0;
          break;
        case CrossAxisAlignment.stretch:
          childCrossPosition = 0.0;
          break;
        case CrossAxisAlignment.baseline:
          childCrossPosition = 0.0;
          break;
      }
      childParentData.offset = Offset(childCrossPosition, childMainPosition);
      childMainPosition += child.size.height;
      child = childParentData.nextSibling;
    }
  }

  _LayoutSizes _computeSizes({
    required BoxConstraints constraints,
    required ChildLayouter layoutChild,
  }) {
    assert(_debugHasNecessaryDirections);
    assert(constraints != null); // ignore: unnecessary_null_comparison

    var crossSize = 0.0;
    var allocatedSize = 0.0; // Sum of the sizes of the children.
    var child = firstChild;
    while (child != null) {
      final childParentData = child.parentData! as FloatColumnParentData;
      final BoxConstraints innerConstraints;
      if (crossAxisAlignment == CrossAxisAlignment.stretch) {
        innerConstraints = BoxConstraints.tightFor(width: constraints.maxWidth);
      } else {
        innerConstraints = BoxConstraints(maxWidth: constraints.maxWidth);
      }
      final childSize = layoutChild(child, innerConstraints);
      allocatedSize += childSize.height;
      crossSize = math.max(crossSize, childSize.width);
      assert(child.parentData == childParentData);
      child = childParentData.nextSibling;
    }

    final idealSize = allocatedSize;
    return _LayoutSizes(
      mainSize: idealSize,
      crossSize: crossSize,
      allocatedSize: allocatedSize,
    );
  }

// ignore: avoid_private_typedef_functions
typedef _ChildSizingFunction = double Function(RenderBox child, double extent);

class _LayoutSizes {
  const _LayoutSizes({
    required this.mainSize,
    required this.crossSize,
    required this.allocatedSize,
  });

  final double mainSize;
  final double crossSize;
  final double allocatedSize;
}

*/
