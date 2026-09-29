// Copyright (c) 2021 Ron Booth. All rights reserved.
// Use of this source code is governed by a license that can be found in the
// LICENSE file.

import 'package:float_column/float_column.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final textAlign in [TextAlign.start, TextAlign.justify]) {
    testWidgets(
        'text hidden from assistive technologies stays hidden, and leaves no '
        'empty semantics nodes, when it wraps around a float ($textAlign)',
        (tester) async {
      final handle = tester.ensureSemantics();

      // Long enough to wrap around the float and continue below it, so it is
      // split into more than one part.
      final hidden = List.filled(40, 'hidden').join(' ');

      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 300,
            child: FloatColumn(
              children: [
                const Floatable(
                  float: FCFloat.start,
                  child: SizedBox(width: 100, height: 30),
                ),
                Text.rich(
                  TextSpan(
                    text: hidden,
                    semanticsLabel: '',
                    style: const TextStyle(fontSize: 10, height: 1.0),
                  ),
                  textAlign: textAlign,
                ),
                const Text('shown'),
              ],
            ),
          ),
        ),
      ));

      final labels = <String>[];
      void visit(SemanticsNode node) {
        labels.add(node.label);
        node.visitChildren((child) {
          visit(child);
          return true;
        });
      }

      tester.getSemantics(find.byType(FloatColumn)).visitChildren((child) {
        visit(child);
        return true;
      });

      expect(labels, contains('shown'));
      expect(labels.where((label) => label.contains('hidden')), isEmpty);
      expect(
        labels.where((label) => label.trim().isEmpty),
        isEmpty,
        reason: 'Hidden text should be excluded from the semantics tree '
            'rather than leave empty nodes in it.',
      );

      handle.dispose();
    });
  }
}
