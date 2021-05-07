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

/// List<Rect> extensions
extension FloatColumnExtOnListOfRect on List<Rect> {
  ///
  /// Returns the `bottom` of the bottom-most rectangle in this list that is greater than
  /// [startY], or [startY] if there is none.
  ///
  double maxYBelow(double startY) => fold<double>(startY, (max, r) => math.max(max, r.bottom));

  double nextY(double startY, double clearMinSpacing) =>
      maxYBelow(startY - clearMinSpacing) + clearMinSpacing;

  ///
  /// Returns the `top` of the top-most rectangle in this list that is greater than
  /// [startY], or `double.infinity` if there is none.
  ///
  double minYBelow(double startY) =>
      fold<double?>(
          null, (min, r) => r.top > startY && (min == null || r.top < min) ? r.top : min) ??
      double.infinity;
}

///
/// Given a starting Y position, [startY], an optional [minX] value (defaults to 0.0),
/// a [maxX] value, and the floated rectangle lists [floatL] and [floatR], returns the
/// first vertical space that a rectangle with the given [width] and [height] will fit.
///
/// The `bottom` value in the returned rectangle contains the minimum `bottom` value of
/// the right or left floated rect that constrains the returned rectangle's width, or
/// `double.infinity` if no floated rect constrains it.
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
  assert(width < double.infinity);
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

    // Find the rightmost rect in the float-left rects that overlaps the range `top` - `bottom`.
    lRect = floatL.fold<Rect?>(
        null,
        (max, r) => r.top < bottom &&
                r.bottom > top &&
                r.right > minX &&
                (max == null || r.right > max.right)
            ? r
            : max);

    // Find the leftmost rect in the float-right rects that overlaps the range `top` - `bottom`.
    rRect = floatR.fold<Rect?>(
        null,
        (min, r) =>
            r.top < bottom && r.bottom > top && r.left < maxX && (min == null || r.left < min.left)
                ? r
                : min);

    left = lRect?.right ?? minX;
    right = rRect?.left ?? maxX;

    nextY = math.min(lRect?.bottom ?? double.infinity, rRect?.bottom ?? double.infinity);
  } while (width > right - left);

  return Rect.fromLTRB(left, top, right, nextY);
}
