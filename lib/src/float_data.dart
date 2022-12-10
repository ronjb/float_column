// Copyright (c) 2021 Ron Booth. All rights reserved.
// Use of this source code is governed by a license that can be found in the
// LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show EdgeInsetsGeometry, EdgeInsets;

import 'floatable.dart';
import 'shared.dart';

@immutable
class FloatData {
  FloatData(this.index, this.placeholderIndex, Object child)
      : float = child is Floatable ? child.float : FCFloat.none,
        clear = child is Floatable ? child.clear : FCClear.none,
        clearMinSpacing = child is Floatable ? child.clearMinSpacing : 0.0,
        margin = child is Floatable ? child.margin : EdgeInsets.zero,
        padding = child is Floatable ? child.padding : EdgeInsets.zero,
        maxWidthPercentage =
            child is Floatable ? child.maxWidthPercentage : 1.0;

  /// The index of the child.
  final int index;

  /// Index of the placeholder span in the child `WrappableText`, or 0 for
  /// child `Widget`s.
  final int placeholderIndex;

  /// Should the child float to the `left`, `right`, `start`, or `end`? The
  /// default is `none`.
  final FCFloat float;

  /// Should the child "clear" (i.e. be placed below) floated siblings?
  /// And if so, should it be placed below floated siblings on just one side
  /// (`left`, `right`, `start`, or `end`) or `both`? The default is `none`.
  final FCClear clear;

  /// Minimum vertical spacing below a cleared sibling. Defaults to 0.0. Only
  /// used if `clear` is set to `left`, `right`, `start`, or `end`, and it is
  /// below a floated sibling.
  final double clearMinSpacing;

  /// Empty space to surround the child. Similar to CSS, the top overlaps
  /// the previous sibling's bottom margin, the bottom overlaps the next
  /// sibling's top margin, and the left and right overlap floated siblings.
  final EdgeInsetsGeometry margin;

  /// Empty space to surround the child that does not overlap siblings.
  final EdgeInsetsGeometry padding;

  /// Maximum width as percentage of the parent FloatColumn's width. Defaults
  /// to 100%.
  final double maxWidthPercentage;

  @override
  bool operator ==(Object other) {
    return other is FloatData &&
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
  int get hashCode => Object.hash(FloatData, index, placeholderIndex, float,
      clear, clearMinSpacing, margin, padding, maxWidthPercentage);
}
