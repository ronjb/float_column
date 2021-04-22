// Copyright 2021 Ron Booth. All rights reserved.
// Use of this source code is governed by a license that can be found in the LICENSE file.

// import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import 'splittable_mixin.dart';

extension FCInlineSpanExt on InlineSpan {
  ///
  /// Splits this span at the given character [index] and returns a list of one or two spans.
  /// If [index] is zero, or if [index] is greater than the number of characters in this span,
  /// a list containing just this span is returned. If this span was split, a list of two spans
  /// is returned, containing the two new spans.
  ///
  List<InlineSpan> splitAtCharacterIndex(int index) => this is Splittable<InlineSpan>
      ? (this as Splittable<InlineSpan>).splitAt(index)
      : _splitAtIndex(SplitAtIndex(index));

  List<InlineSpan> _splitAtIndex(SplitAtIndex index) {
    if (index.value == 0) return [this];

    final span = this;
    if (span is TextSpan) {
      final text = span.text;
      if (text != null && text.isNotEmpty) {
        if (index.value >= text.length) {
          index.value -= text.length;
        } else {
          final result = [
            span.copyWith(text: text.substring(0, index.value), noChildren: true),
            span.copyWith(text: text.substring(index.value)),
          ];
          index.value = 0;
          return result;
        }
      }

      final children = span.children;
      if (children != null && children.isNotEmpty) {
        // If the text.length was equal to index.value, split the text and children.
        if (index.value == 0) {
          return [
            span.copyWith(text: text, noChildren: true),
            span.copyWith(noText: true),
          ];
        }

        final result = children.splitAtCharacterIndex(index);

        if (index.value == 0) {
          if (result.length == 2) {
            return [
              span.copyWith(text: text, children: result.first),
              span.copyWith(noText: true, children: result.last),
            ];
          } else if (result.length == 1) {
            // Only true if the number of characters in all the children was equal to index.value.
            assert(listEquals<InlineSpan>(result.first, children));
          } else {
            assert(false);
          }
        }
      }
    } else if (span is WidgetSpan) {
      index.value -= 1;
    } else {
      assert(false);
    }

    return [this];
  }
}

extension FCListOfInlineSpanExt on List<InlineSpan> {
  ///
  /// Splits this span at the given character [index] and returns a list of one or two lists.
  /// If [index] is zero, or if [index] is greater than the number of characters in these spans,
  /// a list containing just this list is returned. If this list was split, an array of two lists
  /// is returned, containing the two new lists.
  ///
  List<List<InlineSpan>> splitAtCharacterIndex(SplitAtIndex index) {
    if (index.value == 0) return [this];

    var i = 0;
    for (final span in this) {
      final result = span is Splittable<InlineSpan>
          ? (span as Splittable<InlineSpan>).splitAtIndex(index)
          : span._splitAtIndex(index);

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
    String? semanticsLabel,
    bool noText = false,
    bool noChildren = false,
  }) =>
      TextSpan(
        text: noText ? null : (text ?? this.text),
        children: noChildren ? null : (children ?? this.children),
        style: style ?? this.style,
        recognizer: recognizer ?? this.recognizer,
        semanticsLabel: semanticsLabel ?? this.semanticsLabel,
      );
}
