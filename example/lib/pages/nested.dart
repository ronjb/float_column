import 'package:flutter/material.dart';

import 'package:float_column/float_column.dart';

class Nested extends StatelessWidget {
  const Nested({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // const TextAlign? textAlign = null;
    // const textAlign = TextAlign.center;
    const textAlign = TextAlign.start;
    // const textAlign = TextAlign.end;
    // const textAlign = TextAlign.left;
    // const textAlign = TextAlign.right;
    // const textAlign = TextAlign.justify;

    // const crossAxisAlignment = CrossAxisAlignment.center;
    const crossAxisAlignment = CrossAxisAlignment.start;
    // const crossAxisAlignment = CrossAxisAlignment.end;
    // const crossAxisAlignment = CrossAxisAlignment.stretch;


    return DefaultTextStyle(
      style: const TextStyle(fontSize: 18, color: Colors.black, height: 1.5),
      textAlign: textAlign,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Builder(
          builder: (context) => SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: crossAxisAlignment,
                children: [
                  FloatColumn(
                    crossAxisAlignment: crossAxisAlignment,
                    children: [
                      const Floatable(
                          child: Text('nested',
                              style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold))),
                      const Floatable(
                        float: FCFloat.start,
                        clear: FCClear.both,
                        padding: EdgeInsets.only(right: 8),
                        child: _Box(Text('a1')),
                      ),
                      Floatable(
                        float: FCFloat.start,
                        clear: FCClear.both,
                        maxWidthPercentage: 0.65,
                        clearMinSpacing: 10,
                        padding: const EdgeInsets.only(right: 8),
                        child: _Box(
                          FloatColumn(
                            children: [
                              const Floatable(
                                float: FCFloat.end,
                                clear: FCClear.both,
                                padding: EdgeInsets.only(left: 8),
                                child: _Box(Text('b1')),
                              ),
                              const Floatable(
                                float: FCFloat.start,
                                clear: FCClear.both,
                                clearMinSpacing: 10,
                                padding: EdgeInsets.only(right: 8),
                                child: _Box(Text('b2')),
                              ),
                              Floatable(
                                float: FCFloat.end,
                                clear: FCClear.both,
                                maxWidthPercentage: 0.6,
                                clearMinSpacing: 10,
                                padding: const EdgeInsets.only(right: 8),
                                child: _Box(
                                  FloatColumn(
                                    children: const [
                                      Floatable(
                                        float: FCFloat.start,
                                        clear: FCClear.both,
                                        padding: EdgeInsets.only(right: 8),
                                        child: _Box(Text('c1')),
                                      ),
                                      Floatable(
                                        float: FCFloat.end,
                                        clear: FCClear.both,
                                        clearMinSpacing: 20,
                                        padding: EdgeInsets.only(left: 8),
                                        child: _Box(Text('c2')),
                                      ),
                                      WrappableText(text: _t3, textAlign: textAlign),
                                    ],
                                  ),
                                ),
                              ),
                              const WrappableText(text: _t2, textAlign: textAlign),
                            ],
                          ),
                        ),
                      ),
                      const WrappableText(text: _t1, textAlign: textAlign),
                      const Floatable(
                        float: FCFloat.end,
                        padding: EdgeInsets.only(left: 8),
                        child: _Box(Text('a2')),
                      ),
                      const WrappableText(
                        text: _t2,
                        textAlign: textAlign,
                        margin: EdgeInsets.symmetric(vertical: 8),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Box extends StatelessWidget {
  final Widget child;
  final Color? color;

  const _Box(this.child, {Key? key, this.color}) : super(key: key);

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(border: Border.all()),
        child: Padding(padding: const EdgeInsets.fromLTRB(8, 8, 8, 8), child: child),
      );
}

// cspell: disable

const _t1 = TextSpan(
    text:
        '“You have brains in your head. You have feet in your shoes. You can steer yourself any direction you choose. You’re on your own. And you know what you know. And YOU are the one who’ll decide where to go…” – Dr. Seuss, Oh, the Places You’ll Go!');

const _t2 = TextSpan(
    text:
        '“We are the music-makers, And we are the dreamers of dreams, Wandering by lone sea-breakers, And sitting by desolate streams. World-losers and world-forsakers, Upon whom the pale moon gleams; Yet we are the movers and shakers, Of the world forever, it seems.” – Arthur O’Shaughnessy');

const _t3 = TextSpan(
    text:
        '“Stuff your eyes with wonder, he said, live as if you’d drop dead in ten seconds. See the world. It’s more fantastic than any dream made or paid for in factories.” – Ray Bradbury, Fahrenheit 451');

const _text = TextSpan(
    text:
        '“This is what you shall do; Love the earth and sun and the animals, despise riches, give alms to every one that asks, stand up for the stupid and crazy, devote your income and labor to others, hate tyrants, argue not concerning God, have patience and indulgence toward the people, take off your hat to nothing known or unknown or to any man or number of men, go freely with powerful uneducated persons and with the young and with the mothers of families, read these leaves in the open air every season of every year of your life, re-examine all you have been told at school or church or in any book, dismiss whatever insults your own soul, and your very flesh shall be a great poem and have the richest fluency not only in its words but in the silent lines of its lips and face and between the lashes of your eyes and in every motion and joint of your body.” – Walt Whitman, Song of Myself');
