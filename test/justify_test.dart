// Copyright (c) 2021 Ron Booth. All rights reserved.
// Use of this source code is governed by a license that can be found in the
// LICENSE file.

import 'dart:math' as math;

import 'package:float_column/float_column.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TextAlign.justify with floated siblings', () {
    // The default test font renders every glyph as a square with sides equal
    // to the font size, so with `fontSize: 10` and `height: 1.0`, every glyph
    // is exactly 10 wide and every line is exactly 10 high, making the
    // expected values below exact.
    const style = TextStyle(fontSize: 10, height: 1.0);

    // Forty three-character words. In a 200 wide chunk (20 characters per
    // line), each full line fits five words ('abc abc abc abc abc' plus a
    // trailing ghost space), so an unjustified line's last glyph ends at 190,
    // and a justified line's last glyph ends at exactly 200. In a 300 wide
    // chunk, each full line fits seven words, ending at 270 unjustified.
    final words = List.filled(40, 'abc').join(' ');

    Widget wrap(Widget child) => Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(width: 300, child: child),
          ),
        );

    testWidgets('justifies the last line of each chunk except the final one',
        (tester) async {
      await tester.pumpWidget(wrap(FloatColumn(
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
      )));
      expect(tester.takeException(), isNull);

      final chunk1 = _paragraphWithWidth(tester, 200);
      final chunk2 = _paragraphWithWidth(tester, 300);

      // The first chunk has three visible lines beside the float, and every
      // one of them should be justified, including its last line, which is
      // mid-paragraph.
      final lines1 = _visibleGlyphLines(chunk1);
      expect(lines1, hasLength(3));
      for (final line in lines1) {
        expect(line.right, moreOrLessEquals(200, epsilon: 0.5));
      }

      // The second chunk has four visible lines. All but the last should be
      // justified, and the last, which ends the paragraph, should be ragged.
      final lines2 = _visibleGlyphLines(chunk2);
      expect(lines2, hasLength(4));
      for (final line in lines2.take(3)) {
        expect(line.right, moreOrLessEquals(300, epsilon: 0.5));
      }
      // The last line has four words ('abc abc abc abc'), so 150 wide.
      expect(lines2.last.right, moreOrLessEquals(150, epsilon: 0.5));
    });

    testWidgets('does not change layout size or text when justified',
        (tester) async {
      Widget floatColumn(TextAlign textAlign) => wrap(FloatColumn(
            children: [
              const Floatable(
                float: FCFloat.left,
                child: SizedBox(width: 100, height: 25),
              ),
              WrappableText(
                text: TextSpan(style: style, text: words),
                textAlign: textAlign,
              ),
            ],
          ));

      await tester.pumpWidget(floatColumn(TextAlign.left));
      final leftAlignedSize = tester.getSize(find.byType(FloatColumn));

      // With left alignment, the text of the chunks, joined back together,
      // should exactly equal the original text.
      final joined = [
        _paragraphWithWidth(tester, 200),
        _paragraphWithWidth(tester, 300)
      ].map((p) => p.text.toPlainText()).join();
      expect(joined, words);

      await tester.pumpWidget(floatColumn(TextAlign.justify));

      // Justification must not change the size of the FloatColumn, because
      // the hidden text appended to justify chunk boundaries is excluded
      // from each chunk's height.
      expect(tester.getSize(find.byType(FloatColumn)), leftAlignedSize);
    });

    testWidgets('justifies the indented first line of a paragraph',
        (tester) async {
      await tester.pumpWidget(wrap(FloatColumn(
        children: [
          WrappableText(
            text: TextSpan(style: style, text: words),
            textAlign: TextAlign.justify,
            indent: 35,
          ),
        ],
      )));
      expect(tester.takeException(), isNull);

      // The first line is its own chunk, 265 wide (300 minus the 35 indent),
      // which fits six words, ending at 230 unjustified. It is mid-paragraph,
      // so it should be justified to 265.
      final chunk1 = _paragraphWithWidth(tester, 265);
      final lines1 = _visibleGlyphLines(chunk1);
      expect(lines1, hasLength(1));
      expect(lines1.first.right, moreOrLessEquals(265, epsilon: 0.5));
    });

    testWidgets('does not justify a chunk that ends at a hard line break',
        (tester) async {
      // With a first line indent, the first line becomes its own chunk. The
      // first line ends at a hard line break, so even though it is not the
      // last line of the paragraph, it should not be justified.
      await tester.pumpWidget(wrap(FloatColumn(
        children: [
          WrappableText(
            text: TextSpan(style: style, text: 'ab cd\n$words'),
            textAlign: TextAlign.justify,
            indent: 35,
          ),
        ],
      )));
      expect(tester.takeException(), isNull);

      final chunk1 = _paragraphWithWidth(tester, 265);
      final lines1 = _visibleGlyphLines(chunk1);
      expect(lines1, hasLength(1));
      // 'ab cd' is 5 glyphs, so its last glyph should end at 50, unjustified.
      expect(lines1.first.right, moreOrLessEquals(50, epsilon: 0.5));
    });

    testWidgets('justifies chunk boundaries in right-to-left text',
        (tester) async {
      final rtlWords = List.filled(40, 'אבג').join(' ');
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.rtl,
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 300,
            child: FloatColumn(
              children: [
                const Floatable(
                  float: FCFloat.start,
                  child: SizedBox(width: 100, height: 25),
                ),
                WrappableText(
                  text: TextSpan(style: style, text: rtlWords),
                  textAlign: TextAlign.justify,
                ),
              ],
            ),
          ),
        ),
      ));
      expect(tester.takeException(), isNull);

      // The first chunk is beside the float, and all three of its visible
      // lines should be justified, spanning its full 200 width.
      final chunk1 = _paragraphWithWidth(tester, 200);
      final lines1 = _visibleGlyphLines(chunk1);
      expect(lines1, hasLength(3));
      for (final line in lines1) {
        expect(line.left, moreOrLessEquals(0, epsilon: 0.5));
        expect(line.right, moreOrLessEquals(200, epsilon: 0.5));
      }

      // The final chunk's last line is ragged, and in right-to-left text it
      // should be aligned to the right edge.
      final chunk2 = _paragraphWithWidth(tester, 300);
      final lines2 = _visibleGlyphLines(chunk2);
      expect(lines2, hasLength(4));
      expect(lines2.last.left, moreOrLessEquals(150, epsilon: 0.5));
      expect(lines2.last.right, moreOrLessEquals(300, epsilon: 0.5));
    });

    testWidgets('works with maxLines', (tester) async {
      await tester.pumpWidget(wrap(FloatColumn(
        children: [
          const Floatable(
            float: FCFloat.left,
            child: SizedBox(width: 100, height: 25),
          ),
          WrappableText(
            text: TextSpan(style: style, text: words),
            textAlign: TextAlign.justify,
            maxLines: 5,
          ),
        ],
      )));
      expect(tester.takeException(), isNull);

      // Three lines beside the float, plus two below it.
      final box = tester.renderObject<RenderBox>(find.byType(FloatColumn));
      expect(box.size.height, 50);

      final chunk1 = _paragraphWithWidth(tester, 200);
      final lines1 = _visibleGlyphLines(chunk1);
      expect(lines1, hasLength(3));
      for (final line in lines1) {
        expect(line.right, moreOrLessEquals(200, epsilon: 0.5));
      }
    });

    testWidgets('excludes the hidden appended text from semantics',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(wrap(FloatColumn(
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
      )));

      // The hidden word appended to the first chunk (to justify its last
      // line) has an empty semantics label, so the total number of words in
      // the semantics tree should equal the number of words in the text.
      var wordCount = 0;
      bool countWords(SemanticsNode node) {
        wordCount += 'abc'.allMatches(node.label).length;
        node.visitChildren(countWords);
        return true;
      }

      countWords(tester.getSemantics(find.byType(FloatColumn)));
      expect(wordCount, 40);

      handle.dispose();
    });
  });
}

/// Returns the single [RenderParagraph] with the given width whose text
/// starts with a word character.
RenderParagraph _paragraphWithWidth(WidgetTester tester, double width) => tester
    .allRenderObjects
    .whereType<RenderParagraph>()
    .where(
        (p) => p.size.width == width && p.text.toPlainText().trim().isNotEmpty)
    .toSet()
    .single;

/// Returns the bounds of the non-whitespace glyphs of each line of the given
/// paragraph, excluding lines at or below the paragraph's height (i.e. lines
/// that are hidden because they were clipped). Whitespace is excluded so
/// that trailing ghost space boxes don't inflate a line's right edge.
List<({double top, double left, double right})> _visibleGlyphLines(
    RenderParagraph paragraph) {
  final text = paragraph.text.toPlainText();
  final lines = <double, ({double left, double right})>{};
  for (var i = 0; i < text.length; i++) {
    if (text[i].trim().isEmpty) continue;
    final boxes = paragraph.getBoxesForSelection(
        TextSelection(baseOffset: i, extentOffset: i + 1));
    for (final box in boxes) {
      if (box.top >= paragraph.size.height - 0.5) continue;
      final key = (box.top * 10).roundToDouble() / 10;
      final bounds = lines[key];
      lines[key] = (
        left: bounds == null ? box.left : math.min(bounds.left, box.left),
        right: bounds == null ? box.right : math.max(bounds.right, box.right),
      );
    }
  }
  final tops = lines.keys.toList()..sort();
  return [
    for (final top in tops)
      (top: top, left: lines[top]!.left, right: lines[top]!.right)
  ];
}
