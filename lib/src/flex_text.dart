// Copyright 2021 Ron Booth. All rights reserved.
// Use of this source code is governed by a license that can be found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'flex_text_span.dart';
import 'render_flex_text.dart';

/// A vertical list of widgets and text.
class FlexText extends MultiChildRenderObjectWidget {
  /// Creates a flex-text layout.
  ///
  /// The [textDirection] argument defaults to the ambient [Directionality], if
  /// any. If there is no ambient directionality, and a text direction is going
  /// to be necessary to disambiguate `start` or `end` values for the cross axis
  /// directions, the [textDirection] must not be null.
  FlexText({
    Key? key,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.textDirection,
    this.clipBehavior = Clip.none,
    List<Object> children = const <Object>[],
  })  : assert(crossAxisAlignment != null), // ignore: unnecessary_null_comparison
        assert(crossAxisAlignment != CrossAxisAlignment.baseline),
        assert(clipBehavior != null), // ignore: unnecessary_null_comparison
        super(key: key, children: _extractWidgets(children));

  static List<Widget> _extractWidgets(List<Object> children) {
    var index = 0;
    final result = <Widget>[];

    for (final child in children) {
      if (child is Widget) {
        result.add(child);
      } else if (child is FlexTextSpan) {
        // Traverses the FlexTextSpan tree and depth-first collects the list of
        // child widgets that are created in WidgetSpans.
        var placeholderIndex = 0;
        child.text.visitChildren((span) {
          if (span is WidgetSpan) {
            result.add(Semantics(
              tagForChildren: FlexTextSemanticsTag(index, placeholderIndex++),
              child: span.child,
            ));
          }
          return true;
        });
      } else {
        assert(false, 'FlexText only supports Widget and FlexTextSpan children');
      }
      index++;
    }

    return result;
  }

  /// How the children should be placed along the cross axis.
  ///
  /// For example, [CrossAxisAlignment.center], the default, centers the
  /// children in the cross axis (e.g., horizontally for a [Column]).
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

  /// The value to pass to [RenderFlexText.textDirection].
  ///
  /// This value is derived from the [textDirection] property and the ambient
  /// [Directionality]. The value is null if there is no need to specify the
  /// text direction. In practice there's always a need to specify the direction
  /// except when the [crossAxisAlignment] is not dependent on the text direction
  /// (not `start` or `end`).
  ///
  /// This method exists so that subclasses of [FlexText] that create their own
  /// render objects that are derived from [RenderFlexText] can do so and still use
  /// the logic for providing a text direction only when it is necessary.
  @protected
  TextDirection? getEffectiveTextDirection(BuildContext context) {
    return textDirection ?? (_needTextDirection ? Directionality.maybeOf(context) : null);
  }

  @override
  RenderFlexText createRenderObject(BuildContext context) {
    return RenderFlexText(
      crossAxisAlignment: crossAxisAlignment,
      textDirection: getEffectiveTextDirection(context),
      clipBehavior: clipBehavior,
    );
  }

  @override
  void updateRenderObject(BuildContext context, covariant RenderFlexText renderObject) {
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

/// Used by the [RenderFlexText] to map its rendering children to their corresponding
/// semantics nodes.
///
/// The [FlexText] uses this to tag the relation between its [Widget] children and
/// placeholder spans in its [FlexTextSpan] children and their semantics nodes.
@immutable
class FlexTextSemanticsTag extends SemanticsTag {
  /// Creates a semantics tag with the input `index`.
  ///
  /// Different [FlexTextSemanticsTag]s with the same `index` are
  /// consider the same.
  const FlexTextSemanticsTag(this.index, [this.placeholderIndex = 0])
      : super('FlexTextSemanticsTag($index, $placeholderIndex)');

  /// The index of the child.
  final int index;

  /// Index of the placeholder span in the child [FlexTextSpan], or 0 for child
  /// [Widget]s.
  final int placeholderIndex;

  @override
  bool operator ==(Object other) {
    return other is FlexTextSemanticsTag &&
        other.index == index &&
        other.placeholderIndex == placeholderIndex;
  }

  @override
  int get hashCode => hashValues(FlexTextSemanticsTag, index, placeholderIndex);
}
