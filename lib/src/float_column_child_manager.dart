import 'package:flutter/widgets.dart';

abstract class FloatColumnChildManager {
  /// The list of WrappableText and Widget children.
  List<Object> get textAndWidgets;

  /// Updates the widget at the given index.
  RenderBox? updateWidgetAt(int index, Widget widget);

  /// Returns the child RenderBox at the given index.
  RenderBox? childAt(int index);
}
