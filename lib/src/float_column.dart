// Copyright (c) 2021 Ron Booth. All rights reserved.
// Use of this source code is governed by a license that can be found in the
// LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'float_column_semantics_tag.dart';
import 'float_data.dart';
import 'floatable.dart';
import 'render_float_column.dart';
import 'wrappable_text.dart';

/// A vertical column of widgets and text with the ability to "float" child
/// widgets to the left or right, allowing the text to wrap around them —
/// similar to the functionality of the CSS `float` and `clear` properties.
class FloatColumn extends MultiChildRenderObjectWidget {
  /// Creates a [FloatColumn] — a vertical column of widgets and text with the
  /// ability to "float" child widgets to the left or right, allowing the text
  /// to wrap around them — similar to the functionality of the CSS `float`
  /// property.
  ///
  /// The [children] argument can contain [TextSpan], [Text], [RichText],
  /// [WrappableText], and [Widget] children.
  ///
  /// For child widgets that should "float", wrap them in a [Floatable] widget,
  /// indicating, via the `float` parameter, which side they should float on.
  ///
  /// The [textDirection] argument defaults to the ambient [Directionality], if
  /// any. If there is no ambient directionality, [textDirection] must not be
  /// null.
  FloatColumn({
    super.key,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.textDirection,
    this.clipBehavior = Clip.none,
    this.selectionRegistrar,
    this.selectionColor,
    List<Object> children = const <Object>[],
  })  :
        // ignore: unnecessary_null_comparison
        assert(crossAxisAlignment != CrossAxisAlignment.baseline),
        // ignore: unnecessary_null_comparison
        assert(clipBehavior != null),
        // ignore: unnecessary_null_comparison
        assert(children != null),
        super(children: _extractWidgets(children)) {
    _textAndWidgets = children.map((e) {
      if (e is WrappableText) return e;
      if (e is TextSpan) return WrappableText(text: e);
      if (e is Text) return WrappableText.fromText(e);
      if (e is RichText) return WrappableText.fromRichText(e);
      if (e is Widget) return e;
      throw ArgumentError(_errorMsgWithUnsupportedObject(e));
    }).toList();
  }

  /// The list of WrappableText and Widget children.
  late final List<Object> _textAndWidgets;

  static List<Widget> _extractWidgets(List<Object> list) {
    var index = 0;
    final result = <Widget>[];
    for (final child in list) {
      if (child is WrappableText) {
        result._addWidgetSpanChildrenOf(child.text, index);
      } else if (child is TextSpan) {
        result._addWidgetSpanChildrenOf(child, index);
      } else if (child is Text) {
        result._addWidgetSpanChildrenOf(child.textSpan, index);
      } else if (child is RichText) {
        result._addWidgetSpanChildrenOf(child.text, index);
      } else if (child is Widget) {
        result.add(
          MetaData(
            metaData: FloatData(index, 0, child),
            child: Semantics(
              tagForChildren: FloatColumnPlaceholderSpanSemanticsTag(index, 0),
              child: child,
            ),
          ),
        );
      } else {
        throw ArgumentError(_errorMsgWithUnsupportedObject(child));
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
  final TextDirection? textDirection;

  /// {@macro flutter.material.Material.clipBehavior}
  ///
  /// Defaults to [Clip.none].
  final Clip clipBehavior;

  /// The [SelectionRegistrar] this [FloatColumn] is subscribed to.
  ///
  /// If this is `null`, `SelectionContainer.maybeOf(context)` is used to
  /// get the [SelectionRegistrar] from the context.
  final SelectionRegistrar? selectionRegistrar;

  /// The color to use when painting the selection.
  ///
  /// This is ignored if `SelectionContainer.maybeOf(context)` and
  /// [selectionRegistrar] are null.
  final Color? selectionColor;

  @override
  RenderFloatColumn createRenderObject(BuildContext context) {
    assert(textDirection != null || debugCheckHasDirectionality(context));
    final registrar = selectionRegistrar ?? SelectionContainer.maybeOf(context);
    return RenderFloatColumn(
      _textAndWidgets,
      crossAxisAlignment: crossAxisAlignment,
      textDirection: textDirection ?? Directionality.of(context),
      defaultTextStyle: DefaultTextStyle.of(context),
      defaultTextScaleFactor: MediaQuery.textScaleFactorOf(context),
      clipBehavior: clipBehavior,
      registrar: registrar,
      selectionColor: registrar == null
          ? null
          : selectionColor ??
              DefaultSelectionStyle.of(context).selectionColor ??
              DefaultSelectionStyle.defaultColor,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant RenderFloatColumn renderObject) {
    final registrar = selectionRegistrar ?? SelectionContainer.maybeOf(context);
    renderObject
      ..textAndWidgets = _textAndWidgets
      ..crossAxisAlignment = crossAxisAlignment
      ..textDirection = textDirection ?? Directionality.of(context)
      ..defaultTextStyle = DefaultTextStyle.of(context)
      ..defaultTextScaleFactor = MediaQuery.textScaleFactorOf(context)
      ..clipBehavior = clipBehavior
      ..registrar = registrar
      ..selectionColor = registrar == null
          ? null
          : selectionColor ??
              DefaultSelectionStyle.of(context).selectionColor ??
              DefaultSelectionStyle.defaultColor;
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
}

String _errorMsgWithUnsupportedObject(Object object) =>
    'FloatColumn does not support children of type ${object.runtimeType}. '
    'It supports TextSpan, Text, RichText, WrappableText, and Widget children.';

extension on List<Widget> {
  void _addWidgetSpanChildrenOf(InlineSpan? inlineSpan, int index) {
    if (inlineSpan == null) return;

    // Traverses the child's InlineSpan tree and depth-first collects
    // the list of child widgets that are created in WidgetSpans.
    var placeholderIndex = 0;
    inlineSpan.visitChildren((span) {
      if (span is WidgetSpan) {
        add(
          MetaData(
            metaData: FloatData(index, placeholderIndex, span.child),
            child: Semantics(
              tagForChildren: FloatColumnPlaceholderSpanSemanticsTag(
                  index, placeholderIndex),
              child: span.child,
            ),
          ),
        );
        placeholderIndex++;
      }
      return true;
    });
  }
}
