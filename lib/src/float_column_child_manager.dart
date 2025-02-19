import 'dart:collection';

import 'package:flutter/widgets.dart';

abstract class FloatColumnChildManager {
  List<Object> get textAndWidgets;

  HashMap<int, Widget?> get childWidgets;

  bool childExistsAt(int index);

  RenderBox? addOrUpdateChild(int index, {required RenderBox? after});

  void removeChild(RenderBox child);
}
