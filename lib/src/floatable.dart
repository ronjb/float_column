// Copyright 2021 Ron Booth. All rights reserved.
// Use of this source code is governed by a license that can be found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'shared.dart';

/// A floatable widget.
class Floatable extends StatelessWidget {
  /// Creates and returns a new floatable widget.
  const Floatable({
    Key? key,
    this.float = FCFloat.none,
    this.clear = FCClear.none,
    this.clearMinSpacing = 0.0,
    this.maxWidthPercentage = 1.0,
    required this.child,
  }) : super(key: key);

  /// Should the child widget float to the `left`, `right`, `start`, or `end`?
  /// The default is `none`.
  final FCFloat float;

  /// Should the child widget "clear" (i.e. be placed below) floated siblings?
  /// And if so, should it be placed below floated siblings on just one side
  /// (`left`, `right`, `start`, or `end`) or `both`? The default is `none`.
  final FCClear clear;

  /// Minimum vertical spacing below a cleared sibling. Defaults to 0.0. Only used
  /// if `clear` is set to `left`, `right`, `start`, or `end`, and it is below a
  /// floated sibling.
  final double clearMinSpacing;

  /// Maximum width as percentage of the parent FloatColumn's width. Defaults to 100%.
  final double maxWidthPercentage;

  /// The child widget.
  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}
