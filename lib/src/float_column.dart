// Copyright 2021 Ron Booth. All rights reserved.
// Use of this source code is governed by a license that can be found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'float_tag.dart';
import 'floatable.dart';
import 'render_float_column.dart';
import 'shared.dart';
import 'wrappable_text.dart';

/// A vertical column of widgets and text with the ability to "float" child widgets
/// to the left or right, allowing the text to wrap around them -- copying, as
/// closely as possible, the functionality of the CSS `float` and `clear` properties.
class FloatColumn extends MultiChildRenderObjectWidget {
  /// Creates and returns a new FloatColumn.
  ///
  /// The [children] argument must only contain [Widget] and [WrappableText] children.
  ///
  /// For child widgets that should "float", wrap them in a [Floatable] widget,
  /// indicating, via the `float` parameter, which side they should float on.
  ///
  /// The [textDirection] argument defaults to the ambient [Directionality], if
  /// any. If there is no ambient directionality, [textDirection] must not be null.
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

  /// The list of WrappableText and Widget children.
  final List<Object> _textAndWidgets;

  static List<Widget> _extractWidgets(List<Object> list) {
    var index = 0;
    final result = <Widget>[];
    for (final child in list) {
      if (child is Widget) {
        final float = child is Floatable ? child.float : FCFloat.none;
        final clear = child is Floatable ? child.clear : FCClear.none;
        final clearMinSpacing = child is Floatable ? child.clearMinSpacing : 0.0;
        final maxWidthPercentage = child is Floatable ? child.maxWidthPercentage : 1.0;
        result.add(MetaData(
            metaData: FloatTag(index, 0, float, clear,
                clearMinSpacing: clearMinSpacing, maxWidthPercentage: maxWidthPercentage),
            child: child));
      } else if (child is WrappableText) {
        // Traverses the paragraph's InlineSpan tree and depth-first collects the list of
        // child widgets that are created in WidgetSpans.
        var placeholderIndex = 0;
        child.text.visitChildren((span) {
          if (span is WidgetSpan) {
            final child = span.child;
            final float = child is Floatable ? child.float : FCFloat.none;
            final clear = child is Floatable ? child.clear : FCClear.none;
            final clearMinSpacing = child is Floatable ? child.clearMinSpacing : 0.0;
            final maxWidthPercentage = child is Floatable ? child.maxWidthPercentage : 1.0;
            final tag = FloatTag(index, placeholderIndex++, float, clear,
                clearMinSpacing: clearMinSpacing, maxWidthPercentage: maxWidthPercentage);
            result.add(MetaData(
              metaData: tag,
              child: Semantics(tagForChildren: tag, child: child),
            ));
          }
          return true;
        });
      } else {
        assert(false, 'FloatColumn only supports Widget and WrappableText children.');
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
  /// The [textDirection] (or the ambient [Directionality]) must not be null.
  ///
  final TextDirection? textDirection;

  /// {@macro flutter.material.Material.clipBehavior}
  ///
  /// Defaults to [Clip.none].
  final Clip clipBehavior;

  @override
  RenderFloatColumn createRenderObject(BuildContext context) {
    assert(textDirection != null || debugCheckHasDirectionality(context));
    return RenderFloatColumn(
      _textAndWidgets,
      crossAxisAlignment: crossAxisAlignment,
      textDirection: textDirection ?? Directionality.of(context),
      defaultTextStyle: DefaultTextStyle.of(context),
      defaultTextScaleFactor: MediaQuery.textScaleFactorOf(context),
      clipBehavior: clipBehavior,
    );
  }

  @override
  void updateRenderObject(BuildContext context, covariant RenderFloatColumn renderObject) {
    renderObject
      ..textAndWidgets = _textAndWidgets
      ..crossAxisAlignment = crossAxisAlignment
      ..textDirection = textDirection ?? Directionality.of(context)
      ..defaultTextStyle = DefaultTextStyle.of(context)
      ..defaultTextScaleFactor = MediaQuery.textScaleFactorOf(context)
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
