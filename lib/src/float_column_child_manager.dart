// Copyright (c) 2021 Ron Booth. All rights reserved.
// Use of this source code is governed by a license that can be found in the
// LICENSE file.

import 'package:flutter/widgets.dart';

abstract class FloatColumnChildManager {
  /// The list of WrappableText and Widget children.
  List<Object> get textAndWidgets;

  /// Updates the widget at the given index.
  RenderBox? updateWidgetAt(int index, Widget widget);

  /// Returns the child RenderBox at the given index.
  RenderBox? childAt(int index);
}
