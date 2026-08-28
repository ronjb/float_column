// Copyright (c) 2021 Ron Booth. All rights reserved.
// Use of this source code is governed by a license that can be found in the
// LICENSE file.

import 'package:float_column/float_column.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TextAlign.justify selection', () {
    // The default test font renders every glyph as a square with sides equal
    // to the font size, so with `fontSize: 10` and `height: 1.0`, every glyph
    // is exactly 10 wide and every line is exactly 10 high, making the
    // layout below exact.
    const style = TextStyle(fontSize: 10, height: 1.0);

    // Forty distinct three-character words ('w00' through 'w39'), so that if
    // the hidden word appended to a chunk (to justify its last line) leaks
    // into selected content, it shows up as a duplicated word.
    final words =
        List.generate(40, (i) => 'w${i.toString().padLeft(2, '0')}').join(' ');

    // A FloatColumn with a floated box and a justified paragraph that wraps
    // around it, splitting the paragraph into a 200 wide chunk with three
    // lines of five words each (beside the float), and a 300 wide chunk with
    // the rest of the words below it.
    Widget floatColumn() => Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 300,
            child: FloatColumn(
              children: [
                const Floatable(
                  float: FCFloat.left,
                  child: SizedBox(width: 100, height: 25),
                ),
                WrappableText(
                  text: TextSpan(style: style, text: words),
                  textAlign: TextAlign.justify,
                ),
              ],
            ),
          ),
        );

    testWidgets('select all does not include the hidden appended word',
        (tester) async {
      SelectedContent? selectedContent;
      await tester.pumpWidget(MaterialApp(
        home: SelectionArea(
          onSelectionChanged: (content) => selectedContent = content,
          child: floatColumn(),
        ),
      ));

      tester
          .state<SelectableRegionState>(find.byType(SelectableRegion))
          .selectAll(SelectionChangedCause.toolbar);
      await tester.pump();

      expect(selectedContent?.plainText, words);
    });

    testWidgets(
        'drag selection across a chunk boundary does not include the '
        'hidden appended word', (tester) async {
      SelectedContent? selectedContent;
      await tester.pumpWidget(MaterialApp(
        home: SelectionArea(
          onSelectionChanged: (content) => selectedContent = content,
          child: floatColumn(),
        ),
      ));

      // Drag from the first line of the first chunk (which starts at x 100,
      // to the right of the float) to the middle of the first line of the
      // second chunk.
      final topLeft = tester.getTopLeft(find.byType(FloatColumn));
      final gesture = await tester.startGesture(
        topLeft + const Offset(105, 5),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump();
      await gesture.moveTo(topLeft + const Offset(150, 35));
      await tester.pump();
      await gesture.up();
      await tester.pump();
      await gesture.removePointer();

      // The selection spans the chunk boundary, so if the hidden word leaked
      // in, the content would not be a contiguous substring of the text.
      expect(selectedContent, isNotNull);
      expect(selectedContent!.plainText, isNotEmpty);
      expect(words.contains(selectedContent!.plainText), isTrue);
    });

    testWidgets('drag selection within one chunk has no artifacts',
        (tester) async {
      SelectedContent? selectedContent;
      await tester.pumpWidget(MaterialApp(
        home: SelectionArea(
          onSelectionChanged: (content) => selectedContent = content,
          child: floatColumn(),
        ),
      ));

      // Drag from the first line to the second line of the first chunk.
      final topLeft = tester.getTopLeft(find.byType(FloatColumn));
      final gesture = await tester.startGesture(
        topLeft + const Offset(105, 5),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump();
      await gesture.moveTo(topLeft + const Offset(150, 15));
      await tester.pump();
      await gesture.up();
      await tester.pump();
      await gesture.removePointer();

      expect(selectedContent, isNotNull);
      expect(selectedContent!.plainText, isNotEmpty);
      expect(words.contains(selectedContent!.plainText), isTrue);
      expect(selectedContent!.plainText.contains('￼'), isFalse);
    });

    testWidgets(
        'select all works with a floated inline widget in the paragraph',
        (tester) async {
      SelectedContent? selectedContent;
      await tester.pumpWidget(MaterialApp(
        home: SelectionArea(
          onSelectionChanged: (content) => selectedContent = content,
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 300,
              child: FloatColumn(
                children: [
                  WrappableText(
                    text: TextSpan(
                      style: style,
                      children: [
                        const WidgetSpan(
                          child: Floatable(
                            float: FCFloat.left,
                            child: SizedBox(width: 100, height: 25),
                          ),
                        ),
                        TextSpan(text: words),
                      ],
                    ),
                    textAlign: TextAlign.justify,
                  ),
                ],
              ),
            ),
          ),
        ),
      ));

      tester
          .state<SelectableRegionState>(find.byType(SelectableRegion))
          .selectAll(SelectionChangedCause.toolbar);
      await tester.pump();

      expect(selectedContent?.plainText, words);
    });

    testWidgets('renders without a SelectionArea', (tester) async {
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: floatColumn(),
      ));
      expect(tester.takeException(), isNull);
      expect(find.byType(FloatColumn), findsOneWidget);
    });
  });
}
