// Copyright (c) 2021 Ron Booth. All rights reserved.
// Use of this source code is governed by a license that can be found in the
// LICENSE file.

/// @docImport 'float_column.dart';
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'float_column_child_manager.dart';
import 'float_data.dart';
import 'inline_span_ext.dart';
import 'render_object_ext.dart';
import 'shared.dart';
import 'util.dart';
import 'wrappable_text.dart';

export 'float_column_child_manager.dart';

part 'render_float_column_ext.dart';

/// Parent data for use with [RenderFloatColumn].
class FloatColumnParentData extends ContainerBoxParentData<RenderBox> {
  /// Index of this child in its parent's child list.
  ///
  /// This must be maintained by the [FloatColumnChildManager].
  int? index;

  @override
  String toString() => '${super.toString()}; index=$index';
}

/// Displays its children in a vertical column.
///
/// ### Layout algorithm
///
/// _This section describes how the framework causes [RenderFloatColumn] to
/// position its children._
///
/// Layout for a [RenderFloatColumn] proceeds as follows:
///
/// 1. Layout each child with unbounded main axis constraints and the incoming
///    cross axis constraints.
/// 2. The cross axis extent of the [RenderFloatColumn] is the maximum cross
///    axis extent of the children (which will always satisfy the incoming
///    constraints).
/// 3. The main axis extent of the [RenderFloatColumn] is the sum of the main
///    axis extents of the children (subject to the incoming constraints).
/// 4. Determine the position for each child.
///
/// See also [FloatColumn], the widget equivalent.
class RenderFloatColumn extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, FloatColumnParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, FloatColumnParentData>,
        DebugOverflowIndicatorMixin,
        VisitChildrenOfAnyTypeMixin {
  /// Creates a [FloatColumn] render object.
  RenderFloatColumn({
    required this.childManager,
    required CrossAxisAlignment crossAxisAlignment,
    required TextDirection textDirection,
    required DefaultTextStyle defaultTextStyle,
    required TextScaler defaultTextScaler,
    Clip clipBehavior = Clip.none,
    List<RenderBox>? children,
  })  : _crossAxisAlignment = crossAxisAlignment,
        _textDirection = textDirection,
        _defaultTextStyle = defaultTextStyle,
        _defaultTextScaler = defaultTextScaler,
        _clipBehavior = clipBehavior {
    addAll(children);
  }

  /// The delegate that manages the children of this object.
  ///
  /// This delegate must maintain the [FloatColumnParentData.index] value.
  final FloatColumnChildManager childManager;

  /// How the children should be placed along the cross axis.
  ///
  /// If the [crossAxisAlignment] is either [CrossAxisAlignment.start] or
  /// [CrossAxisAlignment.end], then the [textDirection] must not be null.
  CrossAxisAlignment get crossAxisAlignment => _crossAxisAlignment;
  CrossAxisAlignment _crossAxisAlignment;
  set crossAxisAlignment(CrossAxisAlignment value) {
    if (_crossAxisAlignment != value) {
      _crossAxisAlignment = value;
      markNeedsLayout();
    }
  }

  /// Determines the order to lay children out horizontally and how to
  /// interpret `start` and `end` in the horizontal direction.
  ///
  /// The [textDirection] must not be null.
  TextDirection get textDirection => _textDirection;
  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (_textDirection != value) {
      _textDirection = value;
      markNeedsLayout();
    }
  }

  DefaultTextStyle get defaultTextStyle => _defaultTextStyle;
  DefaultTextStyle _defaultTextStyle;
  set defaultTextStyle(DefaultTextStyle value) {
    if (_defaultTextStyle != value) {
      _defaultTextStyle = value;
      markNeedsLayout();
    }
  }

  TextScaler get defaultTextScaler => _defaultTextScaler;
  TextScaler _defaultTextScaler;
  set defaultTextScaler(TextScaler value) {
    if (_defaultTextScaler != value) {
      _defaultTextScaler = value;
      markNeedsLayout();
    }
  }

  // Set during layout if overflow occurred on the main axis.
  double _overflow = 0;

  // Check whether any meaningful overflow is present. Values below an epsilon
  // are treated as not overflowing.
  bool get _hasOverflow => _overflow > precisionErrorTolerance;

  /// {@macro flutter.material.Material.clipBehavior}
  ///
  /// Defaults to [Clip.none].
  Clip get clipBehavior => _clipBehavior;
  Clip _clipBehavior = Clip.none;
  set clipBehavior(Clip value) {
    if (value != _clipBehavior) {
      _clipBehavior = value;
      markNeedsPaint();
      markNeedsSemanticsUpdate();
    }
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! FloatColumnParentData) {
      child.parentData = FloatColumnParentData();
    }
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) {
    return defaultComputeDistanceToFirstActualBaseline(baseline);
  }

  @override
  double? computeDryBaseline(
      BoxConstraints constraints, TextBaseline baseline) {
    return null;
  }

  @override
  @protected
  Size computeDryLayout(covariant BoxConstraints constraints) {
    assert(debugCannotComputeDryLayout(
        reason: 'Dry layout cannot be efficiently computed.'));
    return Size.zero;
  }

  /// Gets the index of a child by looking at its [parentData].
  ///
  /// This relies on the [childManager] maintaining
  /// [FloatColumnParentData.index].
  int indexOf(RenderBox child) {
    final childParentData = child.parentData! as FloatColumnParentData;
    assert(childParentData.index != null);
    return childParentData.index!;
  }

  RenderBox? _addOrUpdateChild(int index, {RenderBox? after}) {
    RenderBox? child;
    invokeLayoutCallback<BoxConstraints>((constraints) {
      assert(constraints == this.constraints);
      child = childManager.addOrUpdateChild(index, after: after);
    });
    return child;
  }

  void _removeChild(RenderBox child) {
    invokeLayoutCallback<BoxConstraints>((constraints) {
      assert(constraints == this.constraints);
      childManager.removeChild(child);
    });
  }

  @override
  void performLayout() {
    // dmPrint('RenderFloatColumn.performLayout()');
    size = dmTime(_performLayout, title: 'RenderFloatColumn.performLayout()');

    /* 
    final constraints = this.constraints;
    final childConstraints = BoxConstraints(maxWidth: constraints.maxWidth);
    var accumulatedSize = _AxisSize.empty;

    RenderBox? previousChild;
    var child = firstChild;

    for (var i = 0; i < childManager.textAndWidgets.length; i++) {
      // First, update the associated widget.
      final textOrWidget = childManager.textAndWidgets[i];
      var updatedWidget = false;
      if (childManager.childWidgets[i] == null) {
        childManager.childWidgets[i] = textOrWidget is Widget
            ? textOrWidget
            : Text.rich((textOrWidget as WrappableText).text);
        updatedWidget = true;
      }

      // Then create or update the render object.
      if (child == null || updatedWidget) {
        child = _addOrUpdateChild(i, after: previousChild);
      }

      if (child != null) {
        var childSize = _AxisSize.fromSize(
            size: ChildLayoutHelper.layoutChild(child, childConstraints),
            direction: Axis.vertical);

        if (i == 0) {
          childManager.childWidgets[i] = Text.rich('ABC'.textSpanReplacing(
              'B', const [Icon(Icons.people_outlined, size: 20)]));
          // ignore: unnecessary_null_checks
          child = _addOrUpdateChild(i, after: previousChild)!;
          childSize = _AxisSize.fromSize(
              size: ChildLayoutHelper.layoutChild(child, childConstraints),
              direction: Axis.vertical);
        }

        accumulatedSize += childSize;

        final childParentData = child.parentData! as FloatColumnParentData;
        previousChild = child;
        child = childParentData.nextSibling;
      }
    }

    // Remove any remaining children.
    while (child != null) {
      final childParentData = child.parentData! as FloatColumnParentData;
      final nextChild = childParentData.nextSibling;
      _removeChild(child);
      child = nextChild;
    }

    final idealMainSize = accumulatedSize.mainAxisExtent;

    final constrainedSize = _AxisSize(
            mainAxisExtent: idealMainSize,
            crossAxisExtent: accumulatedSize.crossAxisExtent)
        .applyConstraints(constraints, Axis.vertical);
    final sizes = _LayoutSizes(
      axisSize: constrainedSize,
      mainAxisFreeSpace:
          constrainedSize.mainAxisExtent - accumulatedSize.mainAxisExtent,
    );

    final crossAxisExtent = sizes.axisSize.crossAxisExtent;
    size = sizes.axisSize.toSize(Axis.vertical);
    _overflow = math.max(0.0, -sizes.mainAxisFreeSpace);

    final flipCrossAxis = firstChild != null &&
        switch (textDirection) {
          TextDirection.ltr => false,
          TextDirection.rtl => true,
        };

    // Position all children in visual order: starting from the top-left child and
    // work towards the child that's farthest away from the origin.
    var childMainPosition = 0.0;
    for (var child = firstChild; child != null; child = childAfter(child)) {
      final childCrossPosition =
          flipCrossAxis ? crossAxisExtent - child.size.width : 0.0;
      (child.parentData! as FloatColumnParentData).offset =
          Offset(childCrossPosition, childMainPosition);
      childMainPosition += child.size.height;
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
    if (size.isEmpty) {
      return;
    }

    _clipRectLayer.layer = context.pushClipRect(
      needsCompositing,
      offset,
      Offset.zero & size,
      defaultPaint,
      clipBehavior: clipBehavior,
      oldLayer: _clipRectLayer.layer,
    );

    assert(() {
      final debugOverflowHints = <DiagnosticsNode>[
        ErrorDescription(
          'The overflowing $runtimeType has an orientation of Axis.vertical.',
        ),
        ErrorDescription(
          'The edge of the $runtimeType that is overflowing has been marked '
          'in the rendering with a yellow and black striped pattern. This is '
          'usually caused by the contents being too big for the $runtimeType.',
        ),
        ErrorHint(
          'Consider applying a flex factor (e.g. using an Expanded widget) to '
          'force the children of the $runtimeType to fit within the available '
          'space instead of being sized to their natural size.',
        ),
        ErrorHint(
          'This is considered an error condition because it indicates that '
          'there is content that cannot be seen. If the content is '
          'legitimately bigger than the available space, consider clipping it '
          'with a ClipRect widget before putting it in the FloatColumn.',
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
    if (!kReleaseMode) {
      if (_hasOverflow) {
        header += ' OVERFLOWING';
      }
    }
    return header;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<TextDirection>('textDirection', textDirection,
        defaultValue: null));
  }

  //
  // VisitChildrenOfAnyTypeMixin
  //

  @override
  bool visitChildrenOfAnyType(CancelableObjectVisitor visitor) {
    var child = firstChild;
    while (child != null) {
      if (!visitor(child)) return false; //--------------------------------->
      child = childAfter(child);
    }

    return true;
  }
}

/*
// A 2D vector that uses a [RenderFloatColumn]'s main axis and cross axis as
// its first and second coordinate axes. It represents the same vector as
// (double mainAxisExtent, double crossAxisExtent).
extension type const _AxisSize._(Size _size) {
  _AxisSize({required double mainAxisExtent, required double crossAxisExtent})
      : this._(Size(mainAxisExtent, crossAxisExtent));
  _AxisSize.fromSize({required Size size, required Axis direction})
      : this._(_convert(size, direction));

  static const _AxisSize empty = _AxisSize._(Size.zero);

  static Size _convert(Size size, Axis direction) {
    return switch (direction) {
      Axis.horizontal => size,
      Axis.vertical => size.flipped,
    };
  }

  double get mainAxisExtent => _size.width;
  double get crossAxisExtent => _size.height;

  Size toSize(Axis direction) => _convert(_size, direction);

  _AxisSize applyConstraints(BoxConstraints constraints, Axis direction) {
    final effectiveConstraints = switch (direction) {
      Axis.horizontal => constraints,
      Axis.vertical => constraints.flipped,
    };
    return _AxisSize._(effectiveConstraints.constrain(_size));
  }

  _AxisSize operator +(_AxisSize other) => _AxisSize._(Size(
      _size.width + other._size.width,
      math.max(_size.height, other._size.height)));
}

class _LayoutSizes {
  _LayoutSizes({
    required this.axisSize,
    required this.mainAxisFreeSpace,
  });

  // The final constrained _AxisSize of the RenderFloatColumn.
  final _AxisSize axisSize;

  // The free space along the main axis. If the value is positive, the free space
  // will be distributed according to the [MainAxisAlignment] specified. A
  // negative value indicates the RenderFloatColumn overflows along the main axis.
  final double mainAxisFreeSpace;
}

extension CommonUtilityExtOnTextSpan on String {
  /// Returns a [TextSpan] with each occurrence of [pattern] replaced with a
  /// [WidgetSpan] wrapping the next widget from [widgets].
  TextSpan textSpanReplacing(
    Pattern pattern,
    List<Widget> widgets, {
    PlaceholderAlignment? alignment,
  }) {
    final parts = split(pattern);
    final spans = <InlineSpan>[];
    for (var i = 0; i < parts.length; i++) {
      if (i > 0 && i - 1 < widgets.length) {
        spans.add(WidgetSpan(
            child: MediaQuery.withNoTextScaling(child: widgets[i - 1]),
            alignment: alignment ?? PlaceholderAlignment.middle));
      }
      spans.add(TextSpan(text: parts[i]));
    }
    return TextSpan(children: spans);
  }
}
*/
