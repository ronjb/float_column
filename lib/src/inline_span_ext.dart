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
  /// Returns `true` if this InlineSpan is a WidgetSpan with a Floated
  /// child where `child.float != FCFloat.none`.
  bool get isFloatedWidgetSpan {
    return this is WidgetSpan &&
        (this as WidgetSpan).child is Floatable &&
        ((this as WidgetSpan).child as Floatable).float != FCFloat.none;
  }

  /// Returns the scaled line height of the first non-empty text in the span.
  double initialLineHeight(
    TextScaler textScaler, {
    double defaultFontSize = 14.0,
  }) {
    final fontSize = initialFontSize(defaultFontSize);
    final lineHeightScale = initialLineHeightScale(1.12);
    return textScaler.scale(fontSize * lineHeightScale);
  }

  /// Returns the scaled font size of the first non-empty text in the span.
  double initialScaledFontSize(
    TextScaler textScaler, {
    double defaultFontSize = 14.0,
  }) {
    final fontSize = initialFontSize(defaultFontSize);
    return textScaler.scale(fontSize);
  }

  /// Returns the font size of the first non-empty text in the span, or
  /// [defaultValue] if none.
  double initialFontSize(double defaultValue) =>
      valueOfFirstDescendantWhere(
        (s) => s is TextSpan && (s.text?.isNotEmpty ?? false),
        defaultValue: defaultValue,
        getValue: (s) => s is TextSpan ? s.style?.fontSize : null,
      ) ??
      defaultValue;

  /// Returns the line height of the first non-empty text in the span, or
  /// [defaultValue] if none.
  double initialLineHeightScale(double defaultValue) =>
      valueOfFirstDescendantWhere(
        (s) => s is TextSpan && (s.text?.isNotEmpty ?? false),
        defaultValue: defaultValue,
        getValue: (s) => s is TextSpan ? s.style?.height : null,
      ) ??
      defaultValue;

  /// Returns the first non-empty text in the span, or the empty string if
  /// none.
  ///
  /// Note, a WidgetSpan is represented as '\uFFFC', the standard object
  /// replacement character.
  String initialText() =>
      valueOfFirstDescendantWhere(
        (s) =>
            s is WidgetSpan || (s is TextSpan && (s.text?.isNotEmpty ?? false)),
        defaultValue: '',
        getValue: (s) => s is WidgetSpan
            ? '\uFFFC'
            : s is TextSpan && (s.text?.isNotEmpty ?? false)
                ? s.text
                : '',
        isValueInherited: false,
      ) ??
      '';

  /// Walks this span and its descendants in pre-order and returns the value
  /// (using [getValue]) of the first span (including this span) where the
  /// [where] function returns `true`. If no matching span is found,
  /// `null` is returned.
  ///
  /// If the value of the matching span is `null`, and [isValueInherited] is
  /// `true` (the default), the value of the matching node's parent is returned,
  /// or its parent, if it is also `null`, and so on, all the way up the tree.
  /// If all the values are `null`, the [defaultValue] is returned.
  ///
  /// If the value of the matching span is `null` and [isValueInherited] is
  /// set to `false`, the [defaultValue] is returned.
  V? valueOfFirstDescendantWhere<V>(
    bool Function(InlineSpan) where, {
    required V defaultValue,
    required V? Function(InlineSpan) getValue,
    bool isValueInherited = true,
  }) =>
      valueOfFirstDescendantOf(this,
          where: where,
          defaultValue: defaultValue,
          getValue: getValue,
          childrenOf: (s) => s is TextSpan ? s.children : null);

  /// Splits this span at the given character [index] and returns a list of one
  /// or two spans. If [index] is zero, or if [index] is greater than the
  /// number of characters in this span, a list containing just this span is
  /// returned. If this span was split, a list of two [TextSpan]s is returned.
  List<InlineSpan> splitAtCharacterIndex(
    int index, {
    bool ignoreFloatedWidgetSpans = false,
  }) =>
      this is SplittableMixin<InlineSpan>
          ? (this as SplittableMixin<InlineSpan>).splitAt(index,
              ignoreFloatedWidgetSpans: ignoreFloatedWidgetSpans)
          : defaultSplitSpanAtIndex(SplitAtIndex(index),
              ignoreFloatedWidgetSpans: ignoreFloatedWidgetSpans,
              copyWithTextSpan: (span, text, children) => span.copyWith(
                  text: text,
                  children: children,
                  noText: text == null,
                  noChildren: children == null));

  /// Splits this span at the given character [index] and returns a list of one
  /// or two spans. If [index] is zero, or if [index] is greater than the
  /// number of characters in this span, a list containing just this span is
  /// returned. If this span was split, a list of two [TextSpan]s is returned.
  ///
  /// This is the default implementation of [splitAtCharacterIndex] for
  /// [InlineSpan]s. In general, `splitAtCharacterIndex` should be used instead
  /// of this method, unless it is used in a class that extends TextSpan with
  /// `SplittableMixin<InlineSpan>`, in which case calling
  /// `splitAtCharacterIndex` would result in a recursive infinite loop.
  List<InlineSpan> defaultSplitSpanAtIndex(
    SplitAtIndex index, {
    required bool ignoreFloatedWidgetSpans,
    required TextSpan Function(
            TextSpan span, String? text, List<InlineSpan>? children)
        copyWithTextSpan,
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
            copyWithTextSpan(span, text.substring(0, index.value), null),
            copyWithTextSpan(span, text.substring(index.value), span.children),
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
            copyWithTextSpan(span, text, null),
            copyWithTextSpan(span, null, span.children),
          ];
        }

        final result = children.splitAtCharacterIndex(index,
            ignoreFloatedWidgetSpans: ignoreFloatedWidgetSpans);

        if (index.value == 0) {
          if (result.length == 2) {
            return [
              copyWithTextSpan(span, text, result.first),
              copyWithTextSpan(span, null, result.last),
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
        // Leave the index unchanged.
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
              ignoreFloatedWidgetSpans: ignoreFloatedWidgetSpans,
              copyWithTextSpan: (span, text, children) => span.copyWith(
                  text: text,
                  children: children,
                  noText: text == null,
                  noChildren: children == null));

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
  /// Returns `true` if this TextSpan has any floated WidgetSpan children.
  bool hasFloatedWidgetSpanChildren() =>
      !visitChildren((span) => !span.isFloatedWidgetSpan);

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
        text: text ?? (noText ? null : this.text),
        children: children ?? (noChildren ? null : this.children),
        style: style ?? this.style,
        recognizer: recognizer ?? this.recognizer,
        mouseCursor: mouseCursor ?? this.mouseCursor,
        onEnter: onEnter ?? this.onEnter,
        onExit: onExit ?? this.onExit,
        semanticsLabel: semanticsLabel ?? this.semanticsLabel,
        locale: locale ?? this.locale,
        spellOut: spellOut ?? this.spellOut,
      );

  /// Returns a TextSpan that skips the first [count] characters of this span.
  /// If [count] is zero, this span is returned. If [count] is greater than the
  /// number of characters in this span, a TextSpan with an empty string is
  /// returned.
  TextSpan skipChars(int count, {bool ignoreFloatedWidgetSpans = true}) {
    if (count == 0) return this;
    final split = splitAtCharacterIndex(count,
        ignoreFloatedWidgetSpans: ignoreFloatedWidgetSpans);
    if (split.length == 2) {
      assert(split.first is TextSpan && split.last is TextSpan);
      return split.last as TextSpan;
    }
    return const TextSpan(text: '');
  }
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

  return null;
}
