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
    assert(!_debugChildrenHaveDuplicateKeys(this, _textAndWidgets));
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

  /// The current list of children of this element.
  ///
  /// This list is filtered to hide elements that have been forgotten (using
  /// [forgetChild]).
  Iterable<Element> get children =>
      _children.where((child) => !_forgottenChildren.contains(child));

  late List<Element> _children;
  // We keep a set of forgotten children to avoid O(n^2) work walking _children
  // repeatedly to remove children.
  final Set<Element> _forgottenChildren = HashSet<Element>();

  @override
  void mount(Element? parent, Object? newSlot) {
    super.mount(parent, newSlot);
    final floatColumnWidget = widget as FloatColumn;
    final children = List<Element>.filled(
        floatColumnWidget._textAndWidgets.length, _NullElement.instance);
    Element? previousChild;
    for (var i = 0; i < children.length; i += 1) {
      final textOrWidget = floatColumnWidget._textAndWidgets[i];
      final widget = textOrWidget is Widget
          ? textOrWidget
          : (textOrWidget as WrappableText).toWidget();
      final newChild =
          inflateWidget(widget, IndexedSlot<Element?>(i, previousChild));
      children[i] = newChild;
      previousChild = newChild;
    }
    _children = children;
  }

  @override
  void update(FloatColumn newWidget) {
    super.update(newWidget);
    final floatColumnWidget = widget as FloatColumn;
    _children = updateChildren(
        _children, floatColumnWidget._textAndWidgets.toWidgets(),
        forgottenChildren: _forgottenChildren);
    _forgottenChildren.clear();
  }

  @override
  void insertRenderObjectChild(RenderObject child, IndexedSlot<Element?> slot) {
    final ContainerRenderObjectMixin<RenderObject,
            ContainerParentDataMixin<RenderObject>> renderObject =
        this.renderObject;
    assert(renderObject.debugValidateChild(child));
    renderObject.insert(child, after: slot.value?.renderObject);
    assert(renderObject == this.renderObject);
  }

  @override
  void moveRenderObjectChild(RenderObject child, IndexedSlot<Element?> oldSlot,
      IndexedSlot<Element?> newSlot) {
    final ContainerRenderObjectMixin<RenderObject,
            ContainerParentDataMixin<RenderObject>> renderObject =
        this.renderObject;
    assert(child.parent == renderObject);
    renderObject.move(child, after: newSlot.value?.renderObject);
    assert(renderObject == this.renderObject);
  }

  @override
  void removeRenderObjectChild(RenderObject child, Object? slot) {
    final ContainerRenderObjectMixin<RenderObject,
            ContainerParentDataMixin<RenderObject>> renderObject =
        this.renderObject;
    assert(child.parent == renderObject);
    renderObject.remove(child);
    assert(renderObject == this.renderObject);
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    for (final child in _children) {
      if (!_forgottenChildren.contains(child)) {
        visitor(child);
      }
    }
  }

  @override
  void forgetChild(Element child) {
    assert(_children.contains(child));
    assert(!_forgottenChildren.contains(child));
    _forgottenChildren.add(child);
    super.forgetChild(child);
  }

  //
  // FloatColumnChildManager
  //

  @override
  List<Object> get textAndWidgets => (widget as FloatColumn)._textAndWidgets;

  @override
  RenderBox? childAt(int index) {
    return _children.maybeElementAt(index)?.renderObject as RenderBox?;
  }

  @override
  RenderBox? updateWidgetAt(int index, Widget widget) {
    // dmPrint('_FloatColumnElement updateWidgetAt');
    RenderBox? child;
    owner!.buildScope(this, () {
      assert(index >= 0 && index < _children.length);
      final newChild = updateChild(_children[index], widget,
          IndexedSlot<Element?>(index, _children.maybeElementAt(index - 1)));
      if (newChild != null) {
        child = newChild.renderObject == null
            ? null
            : newChild.renderObject! as RenderBox;
        _children[index] = newChild;
      } else {
        if (!_forgottenChildren.contains(newChild)) {
          forgetChild(newChild!);
        }
      }
    });
    return child;
  }
}

extension _ExtOnList<T> on List<T> {
  /// Returns `i >= 0 && i < length ? this[i] : null`.
  T? maybeElementAt(int i) => i >= 0 && i < length ? this[i] : null;
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
              alignment: PlaceholderAlignment.top,
              child: MetaData(
                metaData: FloatData(childIndexRef.value++, wrappableTextIndex,
                    placeholderIndexRef.value, child.child),
                child: const SizedBox.shrink(),
                // child: const ColoredBox(
                //     color: Color(0xffff0000),
                //     child: SizedBox(width: 2, height: 2)),
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

bool _debugChildrenHaveDuplicateKeys(Widget parent, Iterable<Object> children) {
  assert(() {
    final nonUniqueKey = _firstNonUniqueKey(children);
    if (nonUniqueKey != null) {
      throw FlutterError(
        "${'Duplicate keys found.\n'
            'If multiple keyed widgets exist as children of another widget, '
            'they must have unique keys.'}"
        '\n$parent has multiple children with key $nonUniqueKey.',
      );
    }
    return true;
  }());
  return false;
}

Key? _firstNonUniqueKey(Iterable<Object> children) {
  final Set<Key> keySet = HashSet<Key>();
  for (final child in children) {
    final key = child is Widget
        ? child.key
        : child is WrappableText
            ? child.key
            : null;
    if (key == null) continue;
    if (!keySet.add(key)) return key;
  }
  return null;
}

extension on List<Object> {
  List<Widget> toWidgets() =>
      map((e) => e is Widget ? e : (e as WrappableText).toWidget()).toList();
}

/// Used as a placeholder in `List<Element>` objects when the actual
/// elements are not yet determined.
class _NullElement extends Element {
  _NullElement() : super(const _NullWidget());

  static _NullElement instance = _NullElement();

  @override
  bool get debugDoingBuild => throw UnimplementedError();
}

class _NullWidget extends Widget {
  const _NullWidget();

  @override
  Element createElement() => throw UnimplementedError();
}
