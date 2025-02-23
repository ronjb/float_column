// Copyright (c) 2021 Ron Booth. All rights reserved.
// Use of this source code is governed by a license that can be found in the
// LICENSE file.

/// Mix this in with a class that can be split at an integer index.
mixin SplittableMixin<T> {
  /// Splits this object at the given [index] and returns a list of one or two
  /// objects. If [index] is zero, or if [index] is greater than the number of
  /// items in this object, a list containing just this object is returned. If
  /// this object was split, a list of two objects is returned, containing the
  /// two new split objects.
  ///
  /// Classes that adopt this mixin should NOT implement this method, but they
  /// must implement `splitAtIndex`.
  List<T> splitAt(
    int index, {
    bool ignoreFloatedWidgetSpans = false,
  }) =>
      splitAtIndex(
        SplitAtIndex(index),
        ignoreFloatedWidgetSpans: ignoreFloatedWidgetSpans,
      );

  /// Splits this object at the given [index] and returns a list of one or two
  /// objects. If [index] is zero, or if [index] is greater than the number of
  /// items in this object, a list containing just this object is returned. If
  /// this object was split, a list of two objects is returned, containing the
  /// two new split objects.
  ///
  /// IMPORTANT: When implementing this method, `index.value` must be either:
  ///   1. Reduced by the total number of items in this object, if
  ///      `index.value` is greater than or equal to the total number of items
  ///      in this object.
  ///   2. Or, set to zero if `index.value` is less than the total number of
  ///      items in this object -- in which case this object should be split at
  ///      `index.value`, and the two new split objects should be returned.
  ///
  /// Classes that adopt this mixin MUST implement this method.
  List<T> splitAtIndex(
    SplitAtIndex index, {
    bool ignoreFloatedWidgetSpans = false,
  });
}

/// Mutable wrapper of an integer index that can be passed by reference.
class SplitAtIndex {
  SplitAtIndex(this.value);
  int value = 0;
}

/// An example of a class that adopts the SplittableMixin -- a splittable
/// string.
class SplittableString with SplittableMixin<SplittableString> {
  SplittableString(this.value);

  final String value;

  @override
  List<SplittableString> splitAtIndex(
    SplitAtIndex index, {
    bool ignoreFloatedWidgetSpans = false,
  }) {
    // If `index.value` is zero, just return `[this]`.
    if (index.value == 0) return [this];

    // If `index.value` is greater than or equal to the length of the string,
    // decrement `index.value` by the length of the string and return `[this]`.
    if (index.value >= value.length) {
      index.value -= value.length;
      return [this];
    }

    // Otherwise, split the string at `index.value`, update `index.value` to
    // zero, and return the two split strings.
    final result = [
      SplittableString(value.substring(0, index.value)),
      SplittableString(value.substring(index.value))
    ];
    index.value = 0;
    return result;
  }
}
