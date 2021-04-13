// Copyright 2021 Ron Booth. All rights reserved.
// Use of this source code is governed by a license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'float_tag.dart';
import 'float_text.dart';
import 'shared.dart';

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

// ignore: avoid_private_typedef_functions
typedef _ChildSizingFunction = double Function(RenderBox child, double extent);

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
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    TextDirection? textDirection,
    Clip clipBehavior = Clip.none,
    List<RenderBox>? widgets,
  })  : assert(crossAxisAlignment != null), // ignore: unnecessary_null_comparison
        assert(clipBehavior != null), // ignore: unnecessary_null_comparison
        _crossAxisAlignment = crossAxisAlignment,
        _textDirection = textDirection,
        _clipBehavior = clipBehavior {
    addAll(widgets);
  }

  List<Object> get textAndWidgets => _textAndWidgets;
  List<Object> _textAndWidgets;
  set textAndWidgets(List<Object> value) {
    assert(value != null); // ignore: unnecessary_null_comparison
    if (_textAndWidgets != value) {
      _textAndWidgets = value;
      _textPainters.clear();
      markNeedsLayout();
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
  TextDirection? get textDirection => _textDirection;
  TextDirection? _textDirection;
  set textDirection(TextDirection? value) {
    if (_textDirection != value) {
      _textDirection = value;
      markNeedsLayout();
    }
  }

  bool get _debugHasNecessaryDirections {
    assert(crossAxisAlignment != null); // ignore: unnecessary_null_comparison
    if (crossAxisAlignment == CrossAxisAlignment.start ||
        crossAxisAlignment == CrossAxisAlignment.end) {
      assert(textDirection != null,
          'Vertical $runtimeType with $crossAxisAlignment has a null textDirection, so the alignment cannot be resolved.');
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
  void setupParentData(RenderBox child) {
    if (child.parentData is! FloatColumnParentData) child.parentData = FloatColumnParentData();
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

  /*
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
  */

  final _textPainters = <TextPainter>[];

  @override
  void performLayout() {
    assert(_debugHasNecessaryDirections);

    final constraints = this.constraints;

    var maxWidth = 0.0;
    var totalHeight = 0.0;

    var child = firstChild;

    final leftRects = <Rect>[];
    final rightRects = <Rect>[];

    var i = 0;
    for (final el in textAndWidgets) {
      // If it is a Widget:
      if (el is Widget) {
        final tag = child!.tag;
        assert(tag.index == i && tag.placeholderIndex == 0);

        final childParentData = child.parentData! as FloatColumnParentData;
        final BoxConstraints innerConstraints;
        if (crossAxisAlignment == CrossAxisAlignment.stretch) {
          innerConstraints = BoxConstraints.tightFor(width: constraints.maxWidth);
        } else {
          innerConstraints = BoxConstraints(maxWidth: constraints.maxWidth);
        }
        child.layout(innerConstraints, parentUsesSize: true);
        final childSize = child.size;

        // Does it float?
        if (tag.float != FCFloat.none) {
          // TODO(ron): ...
        }


        totalHeight += childSize.height;
        maxWidth = math.max(maxWidth, childSize.width);




        assert(child.parentData == childParentData);
        child = childParentData.nextSibling;
      }

      // Else, if it is a FloatText
      else if (el is FloatText) {
        while (child != null && child.tag.index == i) {
          // TODO(ron): ...
          child = childAfter(child);
        }

        // TODO(ron): ...
      } else {
        assert(false);
      }

      i++;
    }

    // for (final paragraph in textAndWidgets.whereType<FloatText>()) {
    // }

    /*
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
      switch (_crossAxisAlignment) {
        case CrossAxisAlignment.start:
        case CrossAxisAlignment.end:
          childCrossPosition =
              _crossAxisAlignment == CrossAxisAlignment.start ? 0.0 : crossSize - child.size.width;
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
    */
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
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
        ErrorDescription('The edge of the $runtimeType that is overflowing has been marked '
            'in the rendering with a yellow and black striped pattern. This is '
            'usually caused by the contents being too big for the $runtimeType.'),
        ErrorHint('This is considered an error condition because it indicates that there '
            'is content that cannot be seen. If the content is legitimately bigger '
            'than the available space, consider placing it in a scrollable container, '
            'like a ListView.'),
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
  }

  ClipRectLayer? _clipRectLayer;

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

extension on RenderBox {
  FloatTag get tag => ((this as RenderMetaData).metaData as FloatTag);
}
