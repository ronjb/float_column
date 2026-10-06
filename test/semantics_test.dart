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

    testWidgets(
        'a heading is announced as one, also when it wraps around a float '
        '($textAlign)', (tester) async {
      final handle = tester.ensureSemantics();

      // Long enough to wrap around the float and continue below it, so it is
      // split into more than one part.
      final heading = List.filled(40, 'heading').join(' ');

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
                WrappableText(
                  text: TextSpan(
                    text: heading,
                    style: const TextStyle(fontSize: 10, height: 1.0),
                  ),
                  textAlign: textAlign,
                  headingLevel: 2,
                ),
                WrappableText(
                  text: const TextSpan(text: 'hidden', semanticsLabel: ''),
                  headingLevel: 3,
                ),
                const Text('paragraph'),
              ],
            ),
          ),
        ),
      ));

      final nodes = <SemanticsNode>[];
      void visit(SemanticsNode node) {
        if (node.label.isNotEmpty || node.headingLevel != 0) nodes.add(node);
        node.visitChildren((child) {
          visit(child);
          return true;
        });
      }

      tester.getSemantics(find.byType(FloatColumn)).visitChildren((child) {
        visit(child);
        return true;
      });

      final headings = nodes.where((node) => node.label.startsWith('heading'));
      expect(headings.length, greaterThan(1),
          reason: 'The heading should be split into more than one part.');
      expect(headings.map((node) => node.headingLevel), everyElement(2));
      expect(
        nodes.where((node) => node.headingLevel == 3),
        isEmpty,
        reason: 'A heading hidden from assistive technologies should be '
            'excluded from the semantics tree.',
      );
      expect(
          nodes.singleWhere((node) => node.label == 'paragraph').headingLevel,
          0);

      handle.dispose();
    });
  }
}
