// Copyright (c) 2021 Ron Booth. All rights reserved.
// Use of this source code is governed by a license that can be found in the
// LICENSE file.

import 'dart:ui' as ui show Locale;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'floatable.dart';
import 'shared.dart';
import 'splittable_mixin.dart';

extension FCInlineSpanExt on InlineSpan {
  /// Returns the font size of the first non-empty text in the span, or
  /// [defaultValue] if none.
  double initialFontSize(double defaultValue) {
    return valueOfFirstDescendantOf(
          this,
          where: (s) => s is TextSpan && (s.text?.isNotEmpty ?? false),
          defaultValue: defaultValue,
          getValue: (s) => s is TextSpan ? s.style?.fontSize : null,
          childrenOf: (s) => s is TextSpan ? s.children : null,
        ) ??
        defaultValue;
  }

  /// Returns the line height of the first non-empty text in the span, or
  /// [defaultValue] if none.
  double initialLineHeightScale(double defaultValue) {
    return valueOfFirstDescendantOf(
          this,
          where: (s) => s is TextSpan && (s.text?.isNotEmpty ?? false),
          defaultValue: defaultValue,
          getValue: (s) => s is TextSpan ? s.style?.height : null,
          childrenOf: (s) => s is TextSpan ? s.children : null,
        ) ??
        defaultValue;
  }

  /// Returns the first non-empty text in the span, or the empty string if
  /// none.
  ///
  /// Note, a WidgetSpan is represented as '\uFFFC', the standard object
  /// replacement character.
  String initialText() {
    return valueOfFirstDescendantOf(
          this,
          where: (s) =>
              s is WidgetSpan ||
              (s is TextSpan && (s.text?.isNotEmpty ?? false)),
          defaultValue: '',
          getValue: (s) => s is WidgetSpan
              ? '\uFFFC'
              : s is TextSpan && (s.text?.isNotEmpty ?? false)
                  ? s.text
                  : '',
          childrenOf: (s) => s is TextSpan ? s.children : null,
          isValueInherited: false,
        ) ??
        '';
  }

  /// Splits this span at the given character [index] and returns a list of one
  /// or two spans. If [index] is zero, or if [index] is greater than the
  /// number of characters in this span, a list containing just this span is
  /// returned. If this span was split, a list of two spans is returned,
  /// containing the two new spans.
  List<InlineSpan> splitAtCharacterIndex(
    int index, {
    bool ignoreFloatedWidgetSpans = false,
  }) =>
      this is SplittableMixin<InlineSpan>
          ? (this as SplittableMixin<InlineSpan>).splitAt(index,
              ignoreFloatedWidgetSpans: ignoreFloatedWidgetSpans)
          : defaultSplitSpanAtIndex(SplitAtIndex(index),
              ignoreFloatedWidgetSpans: ignoreFloatedWidgetSpans);

  List<InlineSpan> defaultSplitSpanAtIndex(
    SplitAtIndex index, {
    required bool ignoreFloatedWidgetSpans,
  }) {
    if (index.value == 0) return [this];

    final span = this;
    if (span is TextSpan) {
      final text = span.text;
      if (text != null && text.isNotEmpty) {
        if (index.value >= text.length) {
          index.value -= text.length;
        } else {
          final result = [
            span.copyWith(
                text: text.substring(0, index.value), noChildren: true),
            span.copyWith(text: text.substring(index.value)),
          ];
          index.value = 0;
          return result;
        }
      }

      final children = span.children;
      if (children != null && children.isNotEmpty) {
        // If the text.length was equal to index.value, split the text and
        // children.
        if (index.value == 0) {
          return [
            span.copyWith(text: text, noChildren: true),
            span.copyWith(noText: true),
          ];
        }

        final result = children.splitAtCharacterIndex(index,
            ignoreFloatedWidgetSpans: ignoreFloatedWidgetSpans);

        if (index.value == 0) {
          if (result.length == 2) {
            return [
              span.copyWith(text: text, children: result.first),
              span.copyWith(noText: true, children: result.last),
            ];
          } else if (result.length == 1) {
            // Only true if the number of characters in all the children was
            // equal to index.value.
            assert(listEquals<InlineSpan>(result.first, children));
          } else {
            assert(false);
          }
        }
      }
    } else if (span is WidgetSpan) {
      if (!ignoreFloatedWidgetSpans &&
          span.child is Floatable &&
          (span.child as Floatable).float != FCFloat.none) {
        index.value += 1;
      } else {
        index.value -= 1;
      }
    } else {
      assert(false);
    }

    return [this];
  }
}

extension FCListOfInlineSpanExt on List<InlineSpan> {
  /// Splits this list of spans at the given character [index] and returns one
  /// or two lists. If [index] is zero, or if [index] is greater than the
  /// number of characters in these spans, a list containing just this list is
  /// returned. If this list was split, an array of two lists is returned,
  /// containing the two new lists.
  List<List<InlineSpan>> splitAtCharacterIndex(
    SplitAtIndex index, {
    bool ignoreFloatedWidgetSpans = false,
  }) {
    if (index.value == 0) return [this];

    var i = 0;
    for (final span in this) {
      final result = span is SplittableMixin<InlineSpan>
          ? (span as SplittableMixin<InlineSpan>).splitAtIndex(index,
              ignoreFloatedWidgetSpans: ignoreFloatedWidgetSpans)
          : span.defaultSplitSpanAtIndex(index,
              ignoreFloatedWidgetSpans: ignoreFloatedWidgetSpans);

      if (index.value == 0) {
        if (result.length == 2) {
          return [
            [...take(i), result.first],
            [result.last, ...skip(i + 1)],
          ];
        } else if (result.length == 1) {
          return [
            [...take(i), result.first],
            if (i + 1 < length) [...skip(i + 1)],
          ];
        } else {
          assert(false);
          break;
        }
      }

      i++;
    }

    return [this];
  }
}

extension FCTextSpanExt on TextSpan {
  TextSpan copyWith({
    String? text,
    List<InlineSpan>? children,
    TextStyle? style,
    GestureRecognizer? recognizer,
    MouseCursor? mouseCursor,
    PointerEnterEventListener? onEnter,
    PointerExitEventListener? onExit,
    String? semanticsLabel,
    ui.Locale? locale,
    bool? spellOut,
    bool noText = false,
    bool noChildren = false,
  }) =>
      TextSpan(
        text: noText ? null : (text ?? this.text),
        children: noChildren ? null : (children ?? this.children),
        style: style ?? this.style,
        recognizer: recognizer ?? this.recognizer,
        mouseCursor: mouseCursor ?? this.mouseCursor,
        onEnter: onEnter ?? this.onEnter,
        onExit: onExit ?? this.onExit,
        semanticsLabel: semanticsLabel ?? this.semanticsLabel,
        locale: locale ?? this.locale,
        spellOut: spellOut ?? this.spellOut,
      );
}

/// Walks the given [node] and its descendants in pre-order and returns the
/// value (using [getValue]) of the first node (including the initial node)
/// where the [where] function returns `true`. If no matching node is found,
/// `null` is returned.
///
/// If the value of the matching node is `null`, and [isValueInherited] is
/// `true`, the default, the value of the matching node's parent is returned,
/// or its parent, if it is also `null`, and so on, all the way up the tree.
/// If all the values are `null`, the [defaultValue] is returned.
///
/// If the value of the matching node is `null` and [isValueInherited] is
/// set to `false`, the [defaultValue] is returned.
V? valueOfFirstDescendantOf<T, V>(
  T node, {
  required bool Function(T) where,
  required V defaultValue,
  required V? Function(T) getValue,
  required Iterable<T>? Function(T) childrenOf,
  bool isValueInherited = true,
}) {
  if (where(node)) {
    return getValue(node) ?? defaultValue;
  } else {
    // Walk its descendants in pre-order, looking for the first match.
    final children = childrenOf(node);
    if (children != null) {
      final value = (isValueInherited ? getValue(node) : null) ?? defaultValue;
      for (final child in children) {
        final childValue = valueOfFirstDescendantOf(child,
            where: where,
            defaultValue: value,
            getValue: getValue,
            childrenOf: childrenOf,
            isValueInherited: isValueInherited);
        if (childValue != null) return childValue;
      }
    }
  }

  return null; // ignore: avoid_returning_null
}
