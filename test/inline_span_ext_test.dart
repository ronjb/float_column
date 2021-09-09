// Copyright 2021 Ron Booth. All rights reserved.
// Use of this source code is governed by a license that can be found in the LICENSE file.

import 'package:float_column/src/inline_span_ext.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('InlineSpan.splitAtCharacterIndex', () {
    // Empty text.
    const a = TextSpan(text: '');
    expect(a.splitAtCharacterIndex(0), [a]);
    expect(a.splitAtCharacterIndex(1), [a]);

    // Just 1 character text.
    const b = TextSpan(text: '1');
    expect(b.splitAtCharacterIndex(0), [b]);
    expect(b.splitAtCharacterIndex(1), [b]);
    expect(b.splitAtCharacterIndex(2), [b]);

    // Split in text.
    const c = TextSpan(text: '12');
    expect(c.splitAtCharacterIndex(0), [c]);
    expect(c.splitAtCharacterIndex(1),
        [const TextSpan(text: '1'), const TextSpan(text: '2')]);
    expect(c.splitAtCharacterIndex(2), [c]);
    expect(c.splitAtCharacterIndex(3), [c]);

    // Split in text and with empty children list.
    const d = TextSpan(text: '12', children: []);
    expect(d.splitAtCharacterIndex(0), [d]);
    expect(d.splitAtCharacterIndex(1),
        [const TextSpan(text: '1'), const TextSpan(text: '2', children: [])]);
    expect(d.splitAtCharacterIndex(2), [d]);
    expect(d.splitAtCharacterIndex(3), [d]);

    // Split between text and children.
    const ec = [TextSpan(text: '3')];
    const e = TextSpan(text: '12', children: ec);
    expect(e.splitAtCharacterIndex(0), [e]);
    expect(e.splitAtCharacterIndex(1),
        [const TextSpan(text: '1'), const TextSpan(text: '2', children: ec)]);
    expect(e.splitAtCharacterIndex(2),
        [const TextSpan(text: '12'), const TextSpan(children: ec)]);
    expect(e.splitAtCharacterIndex(3), [e]);

    // Split between text, between text in children, and between children.
    const fc = [TextSpan(text: '34'), TextSpan(text: '56')];
    const f = TextSpan(text: '12', children: fc);
    expect(f.splitAtCharacterIndex(0), [f]);
    expect(f.splitAtCharacterIndex(1),
        [const TextSpan(text: '1'), const TextSpan(text: '2', children: fc)]);
    expect(f.splitAtCharacterIndex(2),
        [const TextSpan(text: '12'), const TextSpan(children: fc)]);
    expect(f.splitAtCharacterIndex(3), [
      const TextSpan(text: '12', children: [TextSpan(text: '3')]),
      const TextSpan(children: [TextSpan(text: '4'), TextSpan(text: '56')]),
    ]);
    expect(f.splitAtCharacterIndex(4), [
      const TextSpan(text: '12', children: [TextSpan(text: '34')]),
      const TextSpan(children: [TextSpan(text: '56')]),
    ]);
    expect(f.splitAtCharacterIndex(5), [
      const TextSpan(
          text: '12', children: [TextSpan(text: '34'), TextSpan(text: '5')]),
      const TextSpan(children: [TextSpan(text: '6')]),
    ]);
    expect(f.splitAtCharacterIndex(6), [f]);
    expect(f.splitAtCharacterIndex(7), [f]);

    // Split between text in children and between children.
    const gc = [TextSpan(text: '12'), TextSpan(text: '34')];
    const g = TextSpan(children: gc);
    expect(g.splitAtCharacterIndex(0), [g]);
    expect(g.splitAtCharacterIndex(1), [
      const TextSpan(children: [TextSpan(text: '1')]),
      const TextSpan(children: [TextSpan(text: '2'), TextSpan(text: '34')]),
    ]);
    expect(g.splitAtCharacterIndex(2), [
      const TextSpan(children: [TextSpan(text: '12')]),
      const TextSpan(children: [TextSpan(text: '34')]),
    ]);
    expect(g.splitAtCharacterIndex(3), [
      const TextSpan(children: [TextSpan(text: '12'), TextSpan(text: '3')]),
      const TextSpan(children: [TextSpan(text: '4')]),
    ]);
    expect(g.splitAtCharacterIndex(4), [g]);
    expect(g.splitAtCharacterIndex(5), [g]);

    // A deep split, and make sure other span data is copied (e.g. `style`).
    final h = TextSpan(
      style: style(1),
      children: [
        TextSpan(
          style: style(2),
          children: [
            TextSpan(
              style: style(3),
              children: const [TextSpan(text: '12')],
            )
          ],
        )
      ],
    );
    expect(h.splitAtCharacterIndex(0), [h]);
    expect(h.splitAtCharacterIndex(1), [
      TextSpan(
        style: style(1),
        children: [
          TextSpan(
            style: style(2),
            children: [
              TextSpan(
                style: style(3),
                children: const [TextSpan(text: '1')],
              )
            ],
          )
        ],
      ),
      TextSpan(
        style: style(1),
        children: [
          TextSpan(
            style: style(2),
            children: [
              TextSpan(
                style: style(3),
                children: const [TextSpan(text: '2')],
              )
            ],
          )
        ],
      )
    ]);
    expect(h.splitAtCharacterIndex(2), [h]);
  });
}

TextStyle style(double fontSize) => TextStyle(fontSize: fontSize);
