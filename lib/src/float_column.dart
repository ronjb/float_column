// Copyright (c) 2021 Ron Booth. All rights reserved.
// Use of this source code is governed by a license that can be found in the
// LICENSE file.

import 'dart:collection';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'float_data.dart';
import 'floatable.dart';
import 'inline_span_ext.dart';
import 'render_float_column.dart';
import 'wrappable_text.dart';

/// A vertical column of widgets and text with the ability to "float" child
/// widgets to the left or right, allowing the text to wrap around them —
/// similar to the functionality of the CSS `float` and `clear` properties.
class FloatColumn extends RenderObjectWidget {
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
    List<Object> children = const <Object>[],
  }) : assert(crossAxisAlignment != CrossAxisAlignment.baseline) {
    final indexRef = _Ref(0);
    _textAndWidgets = children
        .map((e) {
          if (e is WrappableText) return e;
          if (e is TextSpan) return WrappableText(text: e);
          if (e is Text) return WrappableText.fromText(e);
          if (e is RichText) return WrappableText.fromRichText(e);
          if (e is Widget) return e;
          throw ArgumentError(_errorMsgWithUnsupportedObject(e));
        })
        .expand((e) => _expandToIncludeFloatedWidgetSpanChildren(e, indexRef))
        .toList();
    assert(_textAndWidgets.length == indexRef.value);
  }

  /// The list of WrappableText and Widget children.
  late final List<Object> _textAndWidgets;

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

  /// The value to pass to [RenderFloatColumn.textDirection].
  ///
  /// This value is derived from the [textDirection] property and the ambient
  /// [Directionality].
  @protected
  TextDirection getEffectiveTextDirection(BuildContext context) {
    return textDirection ?? Directionality.of(context);
  }

  @override
  RenderFloatColumn createRenderObject(BuildContext context) {
    assert(textDirection != null || debugCheckHasDirectionality(context));
    final childManager = context as _FloatColumnElement;
    return RenderFloatColumn(
      childManager: childManager,
      crossAxisAlignment: crossAxisAlignment,
      textDirection: getEffectiveTextDirection(context),
      defaultTextStyle: DefaultTextStyle.of(context),
      defaultTextScaler: MediaQuery.textScalerOf(context),
      clipBehavior: clipBehavior,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant RenderFloatColumn renderObject) {
    renderObject
      ..crossAxisAlignment = crossAxisAlignment
      ..textDirection = getEffectiveTextDirection(context)
      ..defaultTextStyle = DefaultTextStyle.of(context)
      ..defaultTextScaler = MediaQuery.textScalerOf(context)
      ..clipBehavior = clipBehavior;
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

  @override
  // _FloatColumnElement should be private.
  // ignore: library_private_types_in_public_api
  _FloatColumnElement createElement() => _FloatColumnElement(this);
}

String _errorMsgWithUnsupportedObject(Object object) =>
    'FloatColumn does not support children of type ${object.runtimeType}. '
    'It supports TextSpan, Text, RichText, WrappableText, and Widget children.';

///
/// _FloatColumnElement
///
class _FloatColumnElement extends RenderObjectElement
    implements FloatColumnChildManager {
  _FloatColumnElement(FloatColumn super.widget);

  @override
  RenderFloatColumn get renderObject => super.renderObject as RenderFloatColumn;

  // We call `updateChild` at two different times:
  //  1. When we ourselves are told to rebuild (see performRebuild).
  //  2. When our render object needs a new child (see createChild).
  // In both cases, we cache the results of calling into our delegate to get
  // the child widget, so that if we do case 2 later, we don't call the builder
  // again. Any time we do case 1, though, we reset the cache.

  /// A cache of widgets so that we don't have to rebuild every time.
  @override
  final HashMap<int, Widget?> childWidgets = HashMap<int, Widget?>();

  /// The map containing all active child elements. SplayTreeMap is used so that
  /// we have all elements ordered and iterable by their keys.
  final SplayTreeMap<int, Element> _childElements =
      SplayTreeMap<int, Element>();

  @override
  void update(FloatColumn newWidget) {
    // dmPrint('_FloatColumnElement update');
    final oldWidget = widget as FloatColumn;
    super.update(newWidget);
    if (newWidget._textAndWidgets != oldWidget._textAndWidgets) {
      performRebuild();
      renderObject.markNeedsLayout();
    }
  }

  @override
  void performRebuild() {
    // dmPrint('_FloatColumnElement performRebuild');
    childWidgets.clear();
    super.performRebuild();
  }

  @override
  Element? updateChild(Element? child, Widget? newWidget, Object? newSlot) {
    // dmPrint('_FloatColumnElement updateChild');
    final oldParentData =
        child?.renderObject?.parentData as FloatColumnParentData?;
    final newChild = super.updateChild(child, newWidget, newSlot);
    final newParentData =
        newChild?.renderObject?.parentData as FloatColumnParentData?;
    if (newParentData != null) {
      newParentData.index = newSlot! as int;
      if (oldParentData != null) {
        newParentData.offset = oldParentData.offset;
      }
    }

    return newChild;
  }

  @override
  void insertRenderObjectChild(RenderObject child, int slot) {
    // dmPrint('_FloatColumnElement insertRenderObjectChild');
    final renderObject = this.renderObject;
    assert(renderObject.debugValidateChild(child));
    renderObject.insert(child as RenderBox,
        after: _childElements[slot - 1]?.renderObject as RenderBox?);
    assert(renderObject == this.renderObject);
  }

  @override
  void moveRenderObjectChild(RenderObject child, int oldSlot, int newSlot) {
    // dmPrint('_FloatColumnElement moveRenderObjectChild');
    const moveChildRenderObjectErrorMessage =
        'Currently we maintain the list in contiguous increasing order, so '
        'moving children around is not allowed.';
    assert(false, moveChildRenderObjectErrorMessage);
  }

  @override
  void removeRenderObjectChild(RenderObject child, int slot) {
    // dmPrint('_FloatColumnElement removeRenderObjectChild');
    assert(child.parent == renderObject);
    renderObject.remove(child as RenderBox);
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    // dmPrint('_FloatColumnElement visitChildren');
    _childElements.forEach((key, child) {
      visitor(child);
    });
  }

  @override
  void forgetChild(Element child) {
    // dmPrint('_FloatColumnElement forgetChild');
    _childElements.remove(child.slot);
    super.forgetChild(child);
  }

  //
  // FloatColumnChildManager
  //

  @override
  List<Object> get textAndWidgets => (widget as FloatColumn)._textAndWidgets;

  @override
  RenderBox? childAt(int index) {
    // dmPrint('_FloatColumnElement childAt');
    return _childElements[index]?.renderObject as RenderBox?;
  }

  @override
  RenderBox? addOrUpdateChild(int index, {required RenderBox? after}) {
    // dmPrint('_FloatColumnElement createChild');
    RenderBox? child;
    owner!.buildScope(this, () {
      final insertFirst = after == null;
      assert(insertFirst || _childElements[index - 1] != null);
      final newChild =
          updateChild(_childElements[index], childWidgets[index], index);
      if (newChild != null) {
        child = newChild.renderObject == null
            ? null
            : newChild.renderObject! as RenderBox;
        _childElements[index] = newChild;
      } else {
        _childElements.remove(index);
      }
    });
    return child;
  }

  @override
  void removeChild(RenderBox child) {
    // dmPrint('_FloatColumnElement removeChild');
    final index = renderObject.indexOf(child);
    owner!.buildScope(this, () {
      assert(_childElements.containsKey(index));
      final result = updateChild(_childElements[index], null, index);
      assert(result == null);
      _childElements.remove(index);
      assert(!_childElements.containsKey(index));
    });
  }

  @override
  void removeAllChildren() {
    // dmPrint('_FloatColumnElement removeAllChildren');
    owner!.buildScope(this, () {
      _childElements
        ..forEach((index, child) {
          final result = updateChild(child, null, index);
          assert(result == null);
        })
        ..clear();
      // assert(_childElements.containsKey(index));
      // final result = updateChild(_childElements[index], null, index);
      // assert(result == null);
      // _childElements.remove(index);
      // assert(!_childElements.containsKey(index));
    });
  }
}

Iterable<Object> _expandToIncludeFloatedWidgetSpanChildren(
    Object e, _Ref<int> indexRef) {
  if (e is Widget) {
    return [
      MetaData(metaData: FloatData(indexRef.value++, null, 0, e), child: e)
    ];
  } else if (e is WrappableText) {
    // Increment the index for the WrappableText.
    indexRef.value++;

    // First check if the WrappableText has any floated WidgetSpan children,
    // so we don't do unnecessary work.
    if (!e.text.hasFloatedWidgetSpanChildren()) {
      return [e];
    } else {
      final wrappableTextIndex = indexRef.value - 1;
      final floatedWidgets = <_WidgetAndPlaceholderIndex>[];
      final newText = e.text.copyCollectingExtractedFloatedWidgets(
          wrappableTextIndex,
          floatedWidgets,
          _Ref<int>(indexRef.value),
          _Ref<int>(0));

      return [
        // First, the WrappableText.
        e.copyWith(text: newText),

        // Then the floated widgets.
        ...floatedWidgets.map((c) => MetaData(
            metaData: FloatData(indexRef.value++, wrappableTextIndex,
                c.placeholderIndex, c.widget),
            child: c.widget)),
      ];
    }
  }
  return [];
}

typedef _WidgetAndPlaceholderIndex = ({Widget widget, int placeholderIndex});

class _Ref<T> {
  _Ref(this.value);
  T value;
}

extension on TextSpan {
  /// Returns a copy of this TextSpan with all floated widgets replaced with
  /// `SizedBox.shrink()` and the original floated widgets collected in
  /// [floatedWidgets].
  TextSpan copyCollectingExtractedFloatedWidgets(
    int wrappableTextIndex,
    List<_WidgetAndPlaceholderIndex> floatedWidgets,
    _Ref<int> childIndexRef,
    _Ref<int> placeholderIndexRef,
  ) {
    var changed = false;
    final newChildren = children?.map((child) {
      if (child is WidgetSpan) {
        var newChild = child;
        if (child.isFloatedWidgetSpan) {
          floatedWidgets.add((
            widget: child.child,
            placeholderIndex: placeholderIndexRef.value
          ));
          changed = true;
          newChild = WidgetSpan(
              child: MetaData(
            metaData: FloatData(childIndexRef.value++, wrappableTextIndex,
                placeholderIndexRef.value, child.child),
            child: const SizedBox.shrink(),
          ));
        }
        placeholderIndexRef.value++;
        return newChild;
      } else if (child is TextSpan) {
        final newChild = child.copyCollectingExtractedFloatedWidgets(
            wrappableTextIndex,
            floatedWidgets,
            childIndexRef,
            placeholderIndexRef);
        changed = changed || newChild != child;
        return newChild;
      } else {
        return child;
      }
    }).toList();

    // If no changes were made, return the original TextSpan.
    return changed ? copyWith(children: newChildren) : this;
  }
}
