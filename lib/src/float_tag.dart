import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/semantics.dart';

import 'shared.dart';

@immutable
class FloatTag extends SemanticsTag {
  /// Creates a semantics tag with the input `index`.
  ///
  /// Different [FloatTag]s with the same `index` are
  /// consider the same.
  const FloatTag(this.index, this.placeholderIndex, this.float, this.clear)
      : super('FloatTag($index, $placeholderIndex)');

  /// The index of the child.
  final int index;

  /// Index of the placeholder span in the child `FloatText`, or 0 for child
  /// `Widget`s.
  final int placeholderIndex;

  /// Should the child float to the `left`, `right`, `start`, or `end`? The default is `none`.
  final FCFloat float;

  /// Should the child "clear" (i.e. be placed below) floating siblings?
  /// And if so, should it be placed below floating siblings on just one side
  /// (`left`, `right`, `start`, or `end`) or `both`? The default is `none`.
  final FCClear clear;

  @override
  bool operator ==(Object other) {
    return other is FloatTag &&
        other.index == index &&
        other.placeholderIndex == placeholderIndex &&
        other.float == float &&
        other.clear == clear;
  }

  @override
  int get hashCode => hashValues(FloatTag, index, placeholderIndex, float, clear);
}
