// Copyright (c) 2021 Ron Booth. All rights reserved.
// Use of this source code is governed by a license that can be found in the
// LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/semantics.dart';

/// Used by the `RenderFloatColumn` to map its rendering children to their
/// corresponding semantics nodes.
///
/// `FloatColumn` uses this to tag the relation between its placeholder
/// spans and their semantics nodes.
@immutable
class FloatColumnPlaceholderSpanSemanticsTag extends SemanticsTag {
  const FloatColumnPlaceholderSpanSemanticsTag(
    this.index,
    this.placeholderIndex,
  ) : super('FloatColumnSemanticsTag($index, $placeholderIndex)');

  /// The index of the child.
  final int index;

  /// Index of the placeholder span in the child `WrappableText`, or 0 for
  /// child `Widget`s.
  final int placeholderIndex;

  @override
  bool operator ==(Object other) {
    return other is FloatColumnPlaceholderSpanSemanticsTag &&
        other.index == index &&
        other.placeholderIndex == placeholderIndex;
  }

  @override
  int get hashCode => Object.hash(
      FloatColumnPlaceholderSpanSemanticsTag, index, placeholderIndex);
}
