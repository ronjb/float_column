// Copyright (c) 2021 Ron Booth. All rights reserved.
// Use of this source code is governed by a license that can be found in the
// LICENSE file.

import 'package:float_column/float_column.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
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
        'select all does not include the hidden appended word when a chunk '
        'ends at a hyphen', (tester) async {
      // Seven-character hyphenated words. In the 200 wide chunk beside the
      // float (20 characters per line), lines break alternately after a
      // hyphen and after a space, and the chunk ends after 'a07-', so its
      // last visible line ends with a hyphen rather than whitespace, and its
      // hidden appended word is 'b07'.
      final hyphenated = List.generate(
          20,
          (i) => 'a${i.toString().padLeft(2, '0')}-'
              'b${i.toString().padLeft(2, '0')}').join(' ');
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
                  const Floatable(
                    float: FCFloat.left,
                    child: SizedBox(width: 100, height: 25),
                  ),
                  WrappableText(
                    text: TextSpan(style: style, text: hyphenated),
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

      expect(selectedContent?.plainText, hyphenated);
    });

    testWidgets(
        'drag selection beside the hidden line does not select the hidden '
        'appended word', (tester) async {
      SelectedContent? selectedContent;
      await tester.pumpWidget(MaterialApp(
        home: SelectionArea(
          onSelectionChanged: (content) => selectedContent = content,
          child: floatColumn(),
        ),
      ));

      // Drag along the first line of the second chunk, which is where the
      // first chunk's hidden line (y 30 to 40) lies, beneath the float's
      // right side (x 100 to 200).
      final topLeft = tester.getTopLeft(find.byType(FloatColumn));
      final gesture = await tester.startGesture(
        topLeft + const Offset(105, 35),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump();
      await gesture.moveTo(topLeft + const Offset(195, 35));
      await tester.pump();
      await gesture.up();
      await tester.pump();
      await gesture.removePointer();

      expect(selectedContent, isNotNull);
      expect(selectedContent!.plainText, isNotEmpty);
      expect(words.contains(selectedContent!.plainText), isTrue);
    });

    testWidgets(
        'extending a selection with the keyboard past the end of a chunk '
        'does not include the hidden appended word', (tester) async {
      SelectedContent? selectedContent;
      await tester.pumpWidget(MaterialApp(
        home: SelectionArea(
          onSelectionChanged: (content) => selectedContent = content,
          child: floatColumn(),
        ),
      ));

      // Select from the start of the first chunk's last visible line to its
      // end, then extend the end a character at a time, past the end of the
      // chunk's visible text.
      final topLeft = tester.getTopLeft(find.byType(FloatColumn));
      final gesture = await tester.startGesture(
        topLeft + const Offset(101, 25),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump();
      await gesture.moveTo(topLeft + const Offset(199, 25));
      await tester.pump();
      await gesture.up();
      await tester.pump();
      await gesture.removePointer();

      for (var i = 0; i < 3; i++) {
        await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
        await tester.pump();

        expect(selectedContent, isNotNull);
        expect(words.contains(selectedContent!.plainText), isTrue,
            reason: 'after ${i + 1} extension(s): '
                '"${selectedContent!.plainText}"');
      }
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
