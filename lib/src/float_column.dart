// Copyright 2021 Ron Booth. All rights reserved.
// Use of this source code is governed by a license that can be found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'float_tag.dart';
import 'float_text.dart';
import 'floatable.dart';
import 'render_float_column.dart';
import 'shared.dart';

/// A vertical list of widgets and text.
class FloatColumn extends MultiChildRenderObjectWidget {
  /// Creates a flex-text layout.
  ///
  /// The [textDirection] argument defaults to the ambient [Directionality], if
  /// any. If there is no ambient directionality, and a text direction is going
  /// to be necessary to disambiguate `start` or `end` values for the cross axis
  /// directions, the [textDirection] must not be null.
  FloatColumn({
    Key? key,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.textDirection,
    this.clipBehavior = Clip.none,
    List<Object> children = const <Object>[],
  })  : assert(crossAxisAlignment != null), // ignore: unnecessary_null_comparison
        assert(crossAxisAlignment != CrossAxisAlignment.baseline),
        assert(clipBehavior != null), // ignore: unnecessary_null_comparison
        assert(children != null), // ignore: unnecessary_null_comparison
        _textAndWidgets = children,
        super(key: key, children: _extractWidgets(children));

  /// The list of FloatText and Widget children.
  final List<Object> _textAndWidgets;

  static List<Widget> _extractWidgets(List<Object> list) {
    var index = 0;
    final result = <Widget>[];
    for (final child in list) {
      if (child is Widget) {
        final float = child is Floatable ? child.float : FTFloat.none;
        final clear = child is Floatable ? child.clear : FTClear.none;
        result.add(MetaData(metaData: FloatTag(index, 0, float, clear), child: child));
      } else if (child is FloatText) {
        // Traverses the paragraph's InlineSpan tree and depth-first collects the list of
        // child widgets that are created in WidgetSpans.
        var placeholderIndex = 0;
        child.text.visitChildren((span) {
          if (span is WidgetSpan) {
            final child = span.child;
            final float = child is Floatable ? child.float : FTFloat.none;
            final clear = child is Floatable ? child.clear : FTClear.none;
            final tag = FloatTag(index, placeholderIndex++, float, clear);
            result.add(Semantics(
              tagForChildren: tag,
              child: MetaData(metaData: tag, child: child),
            ));
          }
          return true;
        });
      } else {
        assert(false, 'FloatColumn only supports Widget and FloatText');
      }
      index++;
    }

    return result;
  }

  /// How the children should be placed along the cross axis.
  ///
  /// For example, [CrossAxisAlignment.start], the default, places the children
  /// at the starting horizontal edge (the left edge if [textDirection] is
  /// [TextDirection.ltr], or the right edge if it is [TextDirection.rtl]).
  final CrossAxisAlignment crossAxisAlignment;

  /// Determines the order to lay children out horizontally and how to interpret
  /// `start` and `end` in the horizontal direction.
  ///
  /// Defaults to the ambient [Directionality].
  ///
  /// If [textDirection] is [TextDirection.rtl], then the direction in which
  /// text flows starts from right to left. Otherwise, if [textDirection] is
  /// [TextDirection.ltr], then the direction in which text flows starts from
  /// left to right.
  ///
  /// Controls the meaning of the [crossAxisAlignment] property's
  /// [CrossAxisAlignment.start] and [CrossAxisAlignment.end] values.
  ///
  /// If the [crossAxisAlignment] is either [CrossAxisAlignment.start] or
  /// [CrossAxisAlignment.end], then the [textDirection] (or the ambient
  /// [Directionality]) must not be null.
  ///
  final TextDirection? textDirection;

  /// {@macro flutter.material.Material.clipBehavior}
  ///
  /// Defaults to [Clip.none].
  final Clip clipBehavior;

  bool get _needTextDirection {
    assert(crossAxisAlignment != null); // ignore: unnecessary_null_comparison
    return crossAxisAlignment == CrossAxisAlignment.start ||
        crossAxisAlignment == CrossAxisAlignment.end;
  }

  /// The value to pass to [RenderFloatColumn.textDirection].
  ///
  /// This value is derived from the [textDirection] property and the ambient
  /// [Directionality]. The value is null if there is no need to specify the
  /// text direction. In practice there's always a need to specify the direction
  /// except when the [crossAxisAlignment] is not dependent on the text direction
  /// (not `start` or `end`).
  ///
  /// This method exists so that subclasses of [FloatColumn] that create their own
  /// render objects that are derived from [RenderFloatColumn] can do so and still use
  /// the logic for providing a text direction only when it is necessary.
  @protected
  TextDirection? getEffectiveTextDirection(BuildContext context) {
    return textDirection ?? (_needTextDirection ? Directionality.maybeOf(context) : null);
  }

  @override
  RenderFloatColumn createRenderObject(BuildContext context) {
    return RenderFloatColumn(
      _textAndWidgets,
      crossAxisAlignment: crossAxisAlignment,
      textDirection: getEffectiveTextDirection(context),
      clipBehavior: clipBehavior,
    );
  }

  @override
  void updateRenderObject(BuildContext context, covariant RenderFloatColumn renderObject) {
    renderObject
      ..crossAxisAlignment = crossAxisAlignment
      ..textDirection = getEffectiveTextDirection(context)
      ..clipBehavior = clipBehavior;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(EnumProperty<CrossAxisAlignment>('crossAxisAlignment', crossAxisAlignment))
      ..add(EnumProperty<TextDirection>('textDirection', textDirection, defaultValue: null));
  }
}
