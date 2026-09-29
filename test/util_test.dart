// Copyright (c) 2021 Ron Booth. All rights reserved.
// Use of this source code is governed by a license that can be found in the
// LICENSE file.

import 'package:float_column/src/util.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('findSpaceFor basic', () {
    expect(
      findSpaceFor(
          startY: 0,
          width: 100,
          height: 100,
          maxX: 200,
          floatL: [],
          floatR: []),
      const Rect.fromLTRB(0, 0, 200, double.infinity),
    );

    {
      const fl = [Rect.fromLTRB(0, 0, 10, 10)];
      const fr = <Rect>[];
      expect(
        findSpaceFor(
            startY: 0,
            width: 100,
            height: 100,
            maxX: 200,
            floatL: fl,
            floatR: fr),
        const Rect.fromLTRB(10, 0, 200, 10),
      );
    }

    {
      const fl = [Rect.fromLTWH(0, 0, 10, 10)];
      const fr = [Rect.fromLTWH(90, 10, 10, 10)];
      expect(
        findSpaceFor(
            startY: 0,
            width: 50,
            height: 50,
            maxX: 100,
            floatL: fl,
            floatR: fr),
        const Rect.fromLTWH(10, 0, 80, 10),
      );
      expect(
        findSpaceFor(
            startY: 0,
            width: 50,
            height: 20,
            maxX: 100,
            floatL: fl,
            floatR: fr),
        const Rect.fromLTWH(10, 0, 80, 10),
      );
      expect(
        findSpaceFor(
            startY: 0,
            width: 50,
            height: 10,
            maxX: 100,
            floatL: fl,
            floatR: fr),
        const Rect.fromLTWH(10, 0, 90, 10),
      );
      expect(
        findSpaceFor(
            startY: 0, width: 1, height: 1, maxX: 100, floatL: fl, floatR: fr),
        const Rect.fromLTWH(10, 0, 90, 10),
      );
      expect(
        findSpaceFor(
            startY: 0,
            width: 90,
            height: 10,
            maxX: 100,
            floatL: fl,
            floatR: fr),
        const Rect.fromLTWH(10, 0, 90, 10),
      );
      expect(
        findSpaceFor(
            startY: 0,
            width: 80,
            height: 11,
            maxX: 100,
            floatL: fl,
            floatR: fr),
        const Rect.fromLTWH(10, 0, 80, 10),
      );
      expect(
        findSpaceFor(
            startY: 0,
            width: 80,
            height: 11,
            maxX: 100,
            floatL: fl,
            floatR: fr),
        const Rect.fromLTWH(10, 0, 80, 10),
      );
    }
  });

  test('findSpaceFor with textDir', () {
    {
      const fl = [Rect.fromLTWH(0, 0, 10, 10), Rect.fromLTWH(0, 20, 10, 10)];
      const fr = [Rect.fromLTWH(90, 10, 10, 10)];
      // Height is larger than the float rects, and the width fits exactly.
      expect(
        findSpaceFor(
            startY: 0,
            width: 80,
            height: 11,
            maxX: 100,
            floatL: fl,
            floatR: fr),
        const Rect.fromLTWH(10, 0, 80, 10),
      );
      // Height is larger than the float rects, and the width doesn't fit.
      expect(
        findSpaceFor(
            startY: 0,
            width: 81,
            height: 11,
            maxX: 100,
            floatL: fl,
            floatR: fr),
        const Rect.fromLTWH(10, 20, 90, 10),
      );
    }
  });

  test('hasSemanticsContent', () {
    final recognizer = TapGestureRecognizer();
    addTearDown(recognizer.dispose);

    expect(const TextSpan(text: 'a').hasSemanticsContent, isTrue);
    expect(const TextSpan(text: ' \n').hasSemanticsContent, isFalse);
    expect(const TextSpan(text: 'a', semanticsLabel: '').hasSemanticsContent,
        isFalse);
    expect(const TextSpan(text: 'a', semanticsLabel: ' ').hasSemanticsContent,
        isFalse);
    expect(const TextSpan(text: ' ', semanticsLabel: 'a').hasSemanticsContent,
        isTrue);
    expect(
        const TextSpan(children: [TextSpan(text: ' '), TextSpan(text: 'a')])
            .hasSemanticsContent,
        isTrue);
    expect(
        const TextSpan(children: [WidgetSpan(child: SizedBox())])
            .hasSemanticsContent,
        isTrue);

    // Hidden text that can be tapped is kept, so the tap stays available.
    expect(
        TextSpan(text: 'a', semanticsLabel: '', recognizer: recognizer)
            .hasSemanticsContent,
        isTrue);

    // But not with a recognizer on a parent that has no text of its own,
    // which, like Flutter, doesn't give its children a tap.
    expect(
        TextSpan(
          recognizer: recognizer,
          children: const [TextSpan(text: 'a', semanticsLabel: '')],
        ).hasSemanticsContent,
        isFalse);
  });
}
