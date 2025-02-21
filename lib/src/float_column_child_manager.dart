import 'dart:collection';

import 'package:flutter/widgets.dart';

abstract class FloatColumnChildManager {
  /// The list of WrappableText and Widget children.
  List<Object> get textAndWidgets;

  /// The resulting child widgets, built from `textAndWidgets`.
  HashMap<int, Widget?> get childWidgets;

  /// Returns the child RenderBox at the given index.
  RenderBox? childAt(int index);

  /// Adds or updates the child element at the given index.
  RenderBox? addOrUpdateChild(int index, {required RenderBox? after});

  /// Removes the child element at the given index.
  void removeChild(RenderBox child);
}
