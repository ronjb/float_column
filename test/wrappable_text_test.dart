// Copyright (c) 2021 Ron Booth. All rights reserved.
// Use of this source code is governed by a license that can be found in the
// LICENSE file.

import 'package:float_column/float_column.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WrappableText.copyWith', () {
    test('preserves a null textScaler', () {
      final wt = WrappableText(text: const TextSpan(text: 'hello'));
      expect(wt.textScaler, isNull);
      final copy = wt.copyWith(text: const TextSpan(text: 'goodbye'));
      expect(copy.textScaler, isNull);
    });

    test('preserves a non-null textScaler', () {
      const scaler = TextScaler.linear(1.5);
      final wt = WrappableText(
          text: const TextSpan(text: 'hello'), textScaler: scaler);
      final copy = wt.copyWith(text: const TextSpan(text: 'goodbye'));
      expect(copy.textScaler, scaler);
    });

    test('accepts a new textScaler', () {
      const scaler = TextScaler.linear(2.0);
      final wt = WrappableText(text: const TextSpan(text: 'hello'));
      final copy = wt.copyWith(textScaler: scaler);
      expect(copy.textScaler, scaler);
    });
  });

  testWidgets(
      'text split around a float honors the ambient MediaQuery textScaler',
      (tester) async {
    const scaler = TextScaler.linear(2.0);

    // The default test font renders every glyph as a square with sides equal
    // to the font size, so with `fontSize: 10` scaled 2x, each character is
    // 20x20. In a 300 wide FloatColumn with a 100x100 left float, 'aaa ' words
    // (80 wide) fit two per line beside the float, so 20 words extend well
    // past the bottom of the float, forcing the text to be split into chunks.
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: scaler),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 300,
              child: FloatColumn(
                children: [
                  const Floatable(
                    float: FCFloat.left,
                    child: SizedBox(width: 100, height: 100),
                  ),
                  WrappableText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 10),
                      text: 'aaa ' * 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    // Every rendered text chunk should use the ambient MediaQuery textScaler.
    final richTexts =
        tester.widgetList<RichText>(find.byType(RichText)).toList();
    expect(richTexts, isNotEmpty);
    for (final richText in richTexts) {
      expect(
        richText.textScaler,
        scaler,
        reason: 'A text chunk was rendered with ${richText.textScaler} '
            'instead of the ambient MediaQuery textScaler.',
      );
    }
  });
}
