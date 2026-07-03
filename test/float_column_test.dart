// Copyright (c) 2021 Ron Booth. All rights reserved.
// Use of this source code is governed by a license that can be found in the
// LICENSE file.

import 'package:float_column/float_column.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WrappableText maxLines with leading line feeds', () {
    // The default test font renders every glyph as a square with sides equal
    // to the font size, so with `fontSize: 10` and `height: 1.0`, every line
    // is exactly 10 high, making the expected column heights below exact.
    const style = TextStyle(fontSize: 10, height: 1.0);

    Widget wrap(Widget child) => Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(width: 300, child: child),
          ),
        );

    testWidgets('does not crash when leading line feeds use up maxLines',
        (tester) async {
      await tester.pumpWidget(wrap(FloatColumn(
        children: [
          WrappableText(
            text: const TextSpan(style: style, text: '\nHello'),
            maxLines: 1,
          ),
        ],
      )));
      expect(tester.takeException(), isNull);

      // Should render like Text('\nHello', maxLines: 1): a single empty
      // line, with 'Hello' truncated.
      final box = tester.renderObject<RenderBox>(find.byType(FloatColumn));
      expect(box.size.height, 10);
    });

    testWidgets('does not crash with more leading line feeds than maxLines',
        (tester) async {
      await tester.pumpWidget(wrap(FloatColumn(
        children: [
          WrappableText(
            text: const TextSpan(style: style, text: '\n\n\nHello'),
            maxLines: 2,
          ),
        ],
      )));
      expect(tester.takeException(), isNull);

      // Should render like Text('\n\n\nHello', maxLines: 2): two empty
      // lines, with the rest truncated.
      final box = tester.renderObject<RenderBox>(find.byType(FloatColumn));
      expect(box.size.height, 20);
    });

    testWidgets('renders remaining text when maxLines is not used up',
        (tester) async {
      await tester.pumpWidget(wrap(FloatColumn(
        children: [
          WrappableText(
            text: const TextSpan(style: style, text: '\n\nHello'),
            maxLines: 3,
          ),
        ],
      )));
      expect(tester.takeException(), isNull);

      // Two empty lines plus one line with 'Hello'.
      final box = tester.renderObject<RenderBox>(find.byType(FloatColumn));
      expect(box.size.height, 30);
    });

    testWidgets('renders all lines when maxLines is null', (tester) async {
      await tester.pumpWidget(wrap(FloatColumn(
        children: [
          WrappableText(
            text: const TextSpan(style: style, text: '\n\nHello'),
          ),
        ],
      )));
      expect(tester.takeException(), isNull);

      final box = tester.renderObject<RenderBox>(find.byType(FloatColumn));
      expect(box.size.height, 30);
    });
  });

  group('floated inline widgets and maxLines', () {
    const style = TextStyle(fontSize: 10, height: 1.0);

    Widget wrap(Widget child) => Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(width: 300, child: child),
          ),
        );

    testWidgets('a floated inline widget truncated by maxLines does not crash',
        (tester) async {
      const floatKey = Key('float');
      await tester.pumpWidget(wrap(FloatColumn(
        children: [
          WrappableText(
            maxLines: 1,
            text: TextSpan(
              style: style,
              children: [
                // At 10 wide per character in a 300 wide column, 30 'aaa '
                // words wrap to five lines, so with `maxLines: 1` the floated
                // widget at the end is beyond the truncation point and its
                // placeholder is never laid out.
                TextSpan(text: 'aaa ' * 30),
                const WidgetSpan(
                  child: Floatable(
                    float: FCFloat.left,
                    child: SizedBox(key: floatKey, width: 50, height: 50),
                  ),
                ),
              ],
            ),
          ),
        ],
      )));
      expect(tester.takeException(), isNull);

      // The truncated floated widget should be hidden (laid out with zero
      // size), and the column should be one line tall.
      expect(tester.getSize(find.byKey(floatKey)), Size.zero);
      final box = tester.renderObject<RenderBox>(find.byType(FloatColumn));
      expect(box.size.height, 10);
    });

    testWidgets('a visible floated inline widget is laid out normally',
        (tester) async {
      const floatKey = Key('float');
      await tester.pumpWidget(wrap(FloatColumn(
        children: [
          WrappableText(
            text: TextSpan(
              style: style,
              children: [
                const WidgetSpan(
                  child: Floatable(
                    float: FCFloat.left,
                    child: SizedBox(key: floatKey, width: 50, height: 50),
                  ),
                ),
                TextSpan(text: 'aaa ' * 12),
              ],
            ),
          ),
        ],
      )));
      expect(tester.takeException(), isNull);

      // The float should be positioned exactly at the top left corner of its
      // anchor line — the first line of the paragraph.
      expect(tester.getRect(find.byKey(floatKey)),
          const Rect.fromLTRB(0, 0, 50, 50));
    });
  });

  group('floated widget margins', () {
    const style = TextStyle(fontSize: 10, height: 1.0);

    Widget wrap(Widget child) => Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(width: 300, child: child),
          ),
        );

    testWidgets('a floated widget honors vertical margins', (tester) async {
      const floatKey = Key('float');
      await tester.pumpWidget(wrap(FloatColumn(
        children: const [
          Floatable(
            float: FCFloat.left,
            margin: EdgeInsets.all(10),
            child: SizedBox(key: floatKey, width: 50, height: 50),
          ),
        ],
      )));

      // Like CSS, the float's margin box starts at the top left corner, so
      // the child should be inset by its top and left margins.
      expect(tester.getRect(find.byKey(floatKey)),
          const Rect.fromLTRB(10, 10, 60, 60));

      // The column should contain the float's margin box.
      final box = tester.renderObject<RenderBox>(find.byType(FloatColumn));
      expect(box.size.height, 70);
    });

    testWidgets('text wraps around a floated widget\'s margin box',
        (tester) async {
      const floatKey = Key('float');
      await tester.pumpWidget(wrap(FloatColumn(
        children: [
          const Floatable(
            float: FCFloat.left,
            margin: EdgeInsets.all(10),
            child: SizedBox(key: floatKey, width: 50, height: 50),
          ),
          WrappableText(text: const TextSpan(style: style, text: 'aaa')),
        ],
      )));

      // The text should start to the right of the float's margin box:
      // left margin 10 + width 50 + right margin 10 = 70.
      expect(tester.getRect(find.text('aaa', findRichText: true)).left, 70);
    });

    testWidgets('a floated widget honors padding (regression)', (tester) async {
      const floatKey = Key('float');
      await tester.pumpWidget(wrap(FloatColumn(
        children: [
          const Floatable(
            float: FCFloat.left,
            padding: EdgeInsets.all(10),
            child: SizedBox(key: floatKey, width: 50, height: 50),
          ),
          WrappableText(text: const TextSpan(style: style, text: 'aaa')),
        ],
      )));
      expect(tester.getRect(find.byKey(floatKey)),
          const Rect.fromLTRB(10, 10, 60, 60));
      expect(tester.getRect(find.text('aaa', findRichText: true)).left, 70);
      final box = tester.renderObject<RenderBox>(find.byType(FloatColumn));
      expect(box.size.height, 70);
    });

    testWidgets('a non-floated widget honors margins (regression)',
        (tester) async {
      const key = Key('widget');
      await tester.pumpWidget(wrap(FloatColumn(
        children: const [
          Floatable(
            margin: EdgeInsets.all(10),
            child: SizedBox(key: key, width: 50, height: 50),
          ),
        ],
      )));
      expect(
          tester.getRect(find.byKey(key)), const Rect.fromLTRB(10, 10, 60, 60));
      final box = tester.renderObject<RenderBox>(find.byType(FloatColumn));
      expect(box.size.height, 70);
    });
  });

  group('intrinsic sizing', () {
    testWidgets('reports a helpful error instead of silently collapsing',
        (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 300,
              child: FloatColumn(
                children: [
                  WrappableText(text: const TextSpan(text: 'Hello world')),
                ],
              ),
            ),
          ),
        ),
      );

      // Intrinsic dimensions of a FloatColumn cannot be computed efficiently,
      // so instead of silently returning zero (collapsing the column when
      // used in an IntrinsicHeight or IntrinsicWidth, for example), a
      // descriptive FlutterError should be thrown.
      final box = tester.renderObject<RenderBox>(find.byType(FloatColumn));
      expect(() => box.getMinIntrinsicWidth(600), throwsFlutterError);
      expect(() => box.getMaxIntrinsicWidth(600), throwsFlutterError);
      expect(() => box.getMinIntrinsicHeight(300), throwsFlutterError);
      expect(() => box.getMaxIntrinsicHeight(300), throwsFlutterError);
    });
  });

  group('duplicate key detection', () {
    test('detects duplicate keys on widget children', () {
      expect(
        () => FloatColumn(children: [
          Container(key: const ValueKey('dup')),
          Container(key: const ValueKey('dup')),
        ]),
        throwsFlutterError,
      );
    });

    test('detects duplicate keys on WrappableText children', () {
      expect(
        () => FloatColumn(children: [
          WrappableText(
              key: const ValueKey('dup'), text: const TextSpan(text: 'a')),
          WrappableText(
              key: const ValueKey('dup'), text: const TextSpan(text: 'b')),
        ]),
        throwsFlutterError,
      );
    });

    test('detects a duplicate key on a WrappableText and a widget', () {
      expect(
        () => FloatColumn(children: [
          WrappableText(
              key: const ValueKey('dup'), text: const TextSpan(text: 'a')),
          Container(key: const ValueKey('dup')),
        ]),
        throwsFlutterError,
      );
    });

    test('allows unique keys', () {
      expect(
        () => FloatColumn(children: [
          Container(key: const ValueKey('a')),
          Container(key: const ValueKey('b')),
          WrappableText(
              key: const ValueKey('c'), text: const TextSpan(text: 'c')),
        ]),
        returnsNormally,
      );
    });
  });

  group('keyed widget children', () {
    testWidgets('preserve state when reordered', (tester) async {
      Widget build(List<Object> children) => Directionality(
            textDirection: TextDirection.ltr,
            child: FloatColumn(children: children),
          );

      const keyA = ValueKey('a');
      const keyB = ValueKey('b');
      await tester.pumpWidget(build(const [
        _Stateful(key: keyA),
        _Stateful(key: keyB),
      ]));
      final stateA = tester.state<_StatefulState>(find.byKey(keyA));
      final stateB = tester.state<_StatefulState>(find.byKey(keyB));

      // Reorder the children; state should follow the keys.
      await tester.pumpWidget(build(const [
        _Stateful(key: keyB),
        _Stateful(key: keyA),
      ]));
      expect(tester.state<_StatefulState>(find.byKey(keyA)), same(stateA));
      expect(tester.state<_StatefulState>(find.byKey(keyB)), same(stateB));
    });
  });
}

class _Stateful extends StatefulWidget {
  const _Stateful({super.key});

  @override
  State<_Stateful> createState() => _StatefulState();
}

class _StatefulState extends State<_Stateful> {
  @override
  Widget build(BuildContext context) => const SizedBox(width: 10, height: 10);
}
