// Copyright 2021 Ron Booth. All rights reserved.
// Use of this source code is governed by a license that can be found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show EdgeInsetsGeometry, EdgeInsets;
import 'package:flutter/semantics.dart';

import 'shared.dart';

@immutable
class FloatTag extends SemanticsTag {
  const FloatTag(
    this.index,
    this.placeholderIndex,
    this.float,
    this.clear, {
    this.clearMinSpacing = 0.0,
    this.margin = EdgeInsets.zero,
    this.padding = EdgeInsets.zero,
    this.maxWidthPercentage = 1.0,
  }) : super('FloatTag($index, $placeholderIndex)');

  /// The index of the child.
  final int index;

  /// Index of the placeholder span in the child `WrappableText`, or 0 for child
  /// `Widget`s.
  final int placeholderIndex;

  /// Should the child float to the `left`, `right`, `start`, or `end`? The default is `none`.
  final FCFloat float;

  /// Should the child "clear" (i.e. be placed below) floated siblings?
  /// And if so, should it be placed below floated siblings on just one side
  /// (`left`, `right`, `start`, or `end`) or `both`? The default is `none`.
  final FCClear clear;

  /// Minimum vertical spacing below a cleared sibling. Defaults to 0.0. Only used
  /// if `clear` is set to `left`, `right`, `start`, or `end`, and it is below a
  /// floated sibling.
  final double clearMinSpacing;

  /// Empty space to surround the child. Similar to CSS, the top overlaps
  /// the previous sibling's bottom margin, the bottom overlaps the next
  /// sibling's top margin, and the left and right overlap floated siblings.
  final EdgeInsetsGeometry margin;

  /// Empty space to surround the child that does not overlap siblings.
  final EdgeInsetsGeometry padding;

  /// Maximum width as percentage of the parent FloatColumn's width. Defaults to 100%.
  final double maxWidthPercentage;

  @override
  bool operator ==(Object other) {
    return other is FloatTag &&
        other.index == index &&
        other.placeholderIndex == placeholderIndex &&
        other.float == float &&
        other.clear == clear &&
        other.clearMinSpacing == clearMinSpacing &&
        other.margin == margin &&
        other.padding == padding &&
        other.maxWidthPercentage == maxWidthPercentage;
  }

  @override
  int get hashCode => hashValues(FloatTag, index, placeholderIndex, float, clear, clearMinSpacing,
      margin, padding, maxWidthPercentage);
}
