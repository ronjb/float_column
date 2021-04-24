// Copyright 2021 Ron Booth. All rights reserved.
// Use of this source code is governed by a license that can be found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui' show Rect, TextDirection;

import 'package:flutter/foundation.dart';

import 'shared.dart';

///
/// Iff kDebugMode is true, prints a string representation of the object
/// to the console.
///
void dmPrint(Object object) {
  if (kDebugMode) print(object); // ignore: avoid_print
}

/// If float is `start` or `end`, returns `left` or `right` depending on the text direction.
FCFloat resolveFloat(FCFloat float, {required TextDirection withDir}) {
  if (float == FCFloat.start) return _isLTR(withDir) ? FCFloat.left : FCFloat.right;
  if (float == FCFloat.end) return _isLTR(withDir) ? FCFloat.right : FCFloat.left;
  return float;
}

/// If clear is `start` or `end`, returns `left` or `right` depending on the text direction.
FCClear resolveClear(FCClear clear, {required TextDirection withDir}) {
  if (clear == FCClear.start) return _isLTR(withDir) ? FCClear.left : FCClear.right;
  if (clear == FCClear.end) return _isLTR(withDir) ? FCClear.right : FCClear.left;
  return clear;
}

bool _isLTR(TextDirection direction) => direction == TextDirection.ltr;

extension FloatColumnExtOnList<T> on List<T> {
  ///
  /// Evaluates every item in this list using the provided [eval] function, and returns
  /// the first item that has the minimum non-null evaluation result. If this list is
  /// empty, or the [eval] function returns `null` for every item in the list, `null`
  /// is returned.
  ///
  T? min(double? Function(T) eval) {
    T? minObject;
    double? minValue;
    for (final rect in this) {
      final value = eval(rect);
      if (value != null && (minValue == null || value < minValue)) {
        minValue = value;
        minObject = rect;
      }
    }
    return minObject;
  }

  ///
  /// Evaluates every item in this list using the provided [eval] function, and returns
  /// the first item that has the maximum non-null evaluation result. If this list is
  /// empty, or the [eval] function returns `null` for every item in the list, `null`
  /// is returned.
  ///
  T? max(double? Function(T) eval) => min((rect) {
        final value = eval(rect);
        return value != null ? -value : value;
      });
}

/// List<Rect> extensions
extension FloatColumnExtOnListOfRect on List<Rect> {
  /// Returns the `bottom` of the bottom rectangle in this list (i.e. the max `bottom`).
  double maxY(double startY) => fold<double>(startY, (p, r) => math.max(p, r.bottom));
}

///
/// Given a starting Y position ([startY]), an optional [minX] value (defaults to 0.0),
/// [maxX] value, and the floating rectangle lists ([floatL] and [floatR]), returns the
/// first vertical space that a rectangle with the given [width] and [height] will fit.
///
Rect findSpaceFor({
  required double startY,
  required double width,
  required double height,
  double minX = 0.0,
  required double maxX,
  required List<Rect> floatL,
  required List<Rect> floatR,
  // TextDirection? textDir,
}) {
  assert(startY < double.infinity);
  assert(width > 0.0 && width < double.infinity);
  assert(height >= 0.0 && height < double.infinity);
  assert(minX < double.infinity);
  assert(maxX < double.infinity && maxX - minX >= width);

  // If the float lists are empty, just return what was given.
  if (floatL.isEmpty && floatR.isEmpty) {
    return Rect.fromLTRB(minX, startY, maxX, double.infinity);
  }

  Rect? lRect;
  Rect? rRect;
  var nextY = startY;

  const minStep = 1.0;
  var top = startY - minStep;
  var left = minX;
  var right = startY;

  do {
    if (nextY.isInfinite) {
      assert(false);
      break;
    }

    // Make sure the `top` value is increasing.
    top = nextY > top ? nextY : top + minStep;

    final bottom = top + height;

    lRect = floatL.max((r) => r.top < bottom && r.bottom > top && r.right > minX ? r.right : null);
    rRect = floatR.min((r) => r.top < bottom && r.bottom > top && r.left < maxX ? r.left : null);

    left = lRect?.right ?? minX;
    right = rRect?.left ?? maxX;

    nextY = math.min(lRect?.bottom ?? double.infinity, rRect?.bottom ?? double.infinity);
  } while (width > right - left);

  // If a textDir was provided...
  // if (textDir != null) {
  //   // Find the next floating rects on the left and right, if any.
  //   final bottom = top + height;
  //   lRect = floatL.min((r) => r.top > bottom && r.top < nextY && r.right > left ? r.top : null);
  //   rRect = floatR.min((r) => r.top > bottom && r.top < nextY && r.left < right ? r.top : null);

  //   // Update `nextY` based on the top rect, if any.
  //   if (lRect != null && (rRect == null || lRect.top < rRect.top)) {
  //     nextY = lRect.top - (textDir == TextDirection.ltr ? height : 0.0);
  //   } else if (rRect != null) {
  //     nextY = rRect.top - (textDir == TextDirection.rtl ? height : 0.0);
  //   }
  // }

  return Rect.fromLTRB(left, top, right, nextY);
}
