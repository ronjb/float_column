import 'package:flutter/widgets.dart';

abstract class FloatColumnChildManager {
  /// The list of WrappableText and Widget children.
  List<Object> get textAndWidgets;

  /// Adds or updates the child widget at the given index.
  void addOrUpdateWidgetAt(int index, Widget widget);

  /// Returns the child RenderBox at the given index.
  RenderBox? childAt(int index);

  /// Adds or updates the child element at the given index.
  RenderBox? addOrUpdateChild(int index, {required RenderBox? after});

  /// Removes the child element at the given index.
  void removeChild(RenderBox child);

  /// Removes all children.
  void removeAllChildren();
}
