import 'package:flutter/foundation.dart';

///
/// Iff kDebugMode is true, prints a string representation of the object
/// to the console.
///
void dmPrint(Object object) {
  if (kDebugMode) print(object); // ignore: avoid_print
}
