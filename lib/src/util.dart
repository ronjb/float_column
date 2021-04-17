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

bool _isLTR(TextDirection direction) => direction == TextDirection.ltr;

FCFloat resolveFloat(FCFloat float, {required TextDirection withDir}) {
  if (float == FCFloat.start) return _isLTR(withDir) ? FCFloat.left : FCFloat.right;
  if (float == FCFloat.end) return _isLTR(withDir) ? FCFloat.right : FCFloat.left;
  return float;
}

FCClear resolveClear(FCClear clear, {required TextDirection withDir}) {
  if (clear == FCClear.start) return _isLTR(withDir) ? FCClear.left : FCClear.right;
  if (clear == FCClear.end) return _isLTR(withDir) ? FCClear.right : FCClear.left;
  return clear;
}

///
/// List<Rect> extensions
///
extension FloatColumnExtOnListOfRect on List<Rect> {
  ///
  /// Returns the right edge value of the first rectangle in this list whose right edge value
  /// is greater than [greaterThan] (which defaults to 0.0), and whose vertical position
  /// overlaps the range [top] through [bottom], and is the rectangle furthest to the right.
  ///
  /// If no rectangle in this list meets those requirements, the [greaterThan] value is returned.
  ///
  /// If the optional [rectBottom] is non-null, its `value` is set to the `bottom` edge value
  /// of the matching rectangle, or `double.infinity` if no matching rectangle was found.
  ///
  double maxXInRange(
    double top,
    double bottom, {
    double greaterThan = 0.0,
    _Double? rectBottom,
  }) {
    var maxX = greaterThan;
    rectBottom?.value = double.infinity;
    for (final rect in this) {
      if (rect.right > maxX && rect.top < bottom && rect.bottom > top) {
        maxX = rect.right;
        rectBottom?.value = rect.bottom;
      }
    }
    return maxX;
  }

  ///
  /// Returns the left edge value of the first rectangle in this list whose left edge value
  /// is less than [lessThan], and whose vertical position overlaps the range [top] through
  /// [bottom], and is the rectangle furthest to the left.
  ///
  /// If no rectangle in this list meets those requirements, the [lessThan] value is returned.
  ///
  /// If the optional [rectBottom] is non-null, its `value` is set to the `bottom` edge value
  /// of the matching rectangle, or `double.infinity` if no matching rectangle was found.
  ///
  double minXInRange(
    double top,
    double bottom, {
    required double lessThan,
    _Double? rectBottom,
  }) {
    var minX = lessThan;
    rectBottom?.value = double.infinity;
    for (final rect in this) {
      if (rect.left < minX && rect.top < bottom && rect.bottom > top) {
        minX = rect.left;
        rectBottom?.value = rect.bottom;
      }
    }
    return minX;
  }

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
}) {
  assert(startY < double.infinity);
  assert(width > 0.0 && width < double.infinity);
  assert(height >= 0.0 && height < double.infinity);
  assert(minX < double.infinity);
  assert(maxX < double.infinity && maxX - minX >= width);

  // If the float lists are empty, just return what was given.
  if (floatL.isEmpty && floatR.isEmpty) {
    return Rect.fromLTRB(minX, startY, maxX, startY + height);
  }

  final lNext = _Double(startY);
  final rNext = _Double(startY);

  const minStep = 1.0;
  var top = startY - minStep;
  var left = minX;
  var right = startY;
  do {
    final nextY = math.min(lNext.value, rNext.value);
    if (nextY == double.infinity) {
      assert(false);
      break;
    }

    // Make sure the `top` value is increasing.
    top = nextY > top ? nextY : top + minStep;

    final bottom = top + height;
    left = floatL.maxXInRange(top, bottom, greaterThan: minX, rectBottom: lNext);
    right = floatR.minXInRange(top, bottom, lessThan: maxX, rectBottom: rNext);
  } while (width > right - left);

  return Rect.fromLTRB(left, top, right, top + height);
}

///
/// Given a starting Y position ([startY]), an optional [minX] value (defaults to 0.0),
/// [maxX] value, and the floating rectangle lists ([floatL] and [floatR]), returns the
/// maximum available space at [startY] with the given [height].
///
Rect spaceAt({
  required double startY,
  required double height,
  double minX = 0.0,
  required double maxX,
  required List<Rect> floatL,
  required List<Rect> floatR,
}) {
  assert(startY < double.infinity);
  assert(height >= 0.0 && height < double.infinity);
  assert(minX < double.infinity);
  assert(maxX < double.infinity);

  // If the float lists are empty, just return what was given.
  if (floatL.isEmpty && floatR.isEmpty) {
    return Rect.fromLTRB(minX, startY, maxX, startY + height);
  }

  final left = floatL.maxXInRange(startY, startY + height, greaterThan: minX);
  final right = floatR.minXInRange(startY, startY + height, lessThan: maxX);

  return Rect.fromLTRB(left, startY, right, startY + height);
}

/// Mutable wrapper of a double that can be passed by reference.
class _Double {
  _Double(this.value);
  double value;
}
