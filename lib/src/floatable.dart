import 'package:flutter/widgets.dart';

import 'shared.dart';

/// A floatable widget.
class Floatable extends StatelessWidget {
  /// Creates and returns a new floatable widget.
  const Floatable({
    Key? key,
    this.float = FTFloat.none,
    this.clear = FTClear.none,
    required this.child,
  }) : super(key: key);

  /// Should the child widget float to the `left`, `right`, `start`, or `end`?
  /// The default is `none`.
  final FTFloat float;

  /// Should the child widget "clear" (i.e. be placed below) floating siblings?
  /// And if so, should it be placed below floating siblings on just one side
  /// (`left`, `right`, `start`, or `end`) or `both`? The default is `none`.
  final FTClear clear;

  /// The child widget.
  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}
