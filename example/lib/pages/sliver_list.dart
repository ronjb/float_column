import 'dart:math';

import 'package:float_column/float_column.dart';
import 'package:flutter/material.dart';

class SliverListPage extends StatelessWidget {
  const SliverListPage({super.key});

  @override
  Widget build(BuildContext context) {
    const TextAlign? textAlign = null;
    const boxHeight = 89.0;

    return DefaultTextStyle(
      style: const TextStyle(fontSize: 20, color: Colors.black, height: 1.5),
      textAlign: textAlign,
      child: CustomScrollView(
        slivers: <Widget>[
          SliverList(
            // itemExtent: 50.0,
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.lightBlue[100 * (index % 9)],
                  child: FloatColumn(
                    children: [
                      Floatable(
                          float: FCFloat.end,
                          clear: FCClear.both,
                          maxWidthPercentage: 0.333,
                          child: Container(
                              height: boxHeight, color: Colors.orange)),
                      WrappableText(
                        text: TextSpan(
                            text:
                                _text.substring(0, _random.nextInt(_textLen))),
                        indent: 40,
                        textAlign: textAlign,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

final Random _random = Random();

// cspell: disable
const _text = '“We are the music-makers, And we are the dreamers of dreams, '
    'Wandering by lone sea-breakers, And sitting by desolate streams. '
    'World-losers and world-forsakers, Upon whom the pale moon gleams; '
    'Yet we are the movers and shakers, Of the world forever, it seems.” '
    '– Arthur O’Shaughnessy';
const _textLen = _text.length;
