import 'package:flutter/material.dart';

import 'package:float_column/float_column.dart';

class InlineFloats extends StatelessWidget {
  const InlineFloats({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const TextAlign? textAlign = null;
    // const textAlign = TextAlign.start;
    // const textAlign = TextAlign.end;
    // const textAlign = TextAlign.left;
    // const textAlign = TextAlign.right;
    // const textAlign = TextAlign.center;
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
                      _floatable('f1     \n', FCFloat.start, FCClear.none),
                      _floatable('f2     \n', FCFloat.end, FCClear.both),
                      _floatable('f3     \n', FCFloat.start, FCClear.both),
                      _floatable('f4     \n', FCFloat.end, FCClear.both),
                      _floatable('f5     \n', FCFloat.start, FCClear.both),
                      _floatable('f6     \n', FCFloat.end, FCClear.both),
                      const WrappableText(
                        text: _t0,
                        // margin: EdgeInsetsDirectional.only(start: 45),
                        textAlign: textAlign,
                      ),
                      // const WrappableText(text: _t1, textAlign: textAlign),
                      // const WrappableText(text: _t2, textAlign: textAlign),
                      // const WrappableText(text: _t3, textAlign: textAlign),
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

// cspell: disable

const _t0 = TextSpan(
  children: [
    WidgetSpan(
      baseline: TextBaseline.alphabetic,
      alignment: PlaceholderAlignment.baseline,
      child: Floatable(
        float: FCFloat.start,
        clear: FCClear.none,
        padding: EdgeInsetsDirectional.only(end: 8),
        child: _Box(Text('i1')),
      ),
    ),
    _t1,
    WidgetSpan(
      baseline: TextBaseline.alphabetic,
      alignment: PlaceholderAlignment.baseline,
      child: Floatable(
        float: FCFloat.start,
        clear: FCClear.none,
        padding: EdgeInsetsDirectional.only(end: 8),
        child: _Box(Text('i2')),
      ),
    ),
    _t2,
    _t3,
  ],
);

const _t1 = TextSpan(
    style: TextStyle(backgroundColor: Color(0xffddddff)),
    text:
        '“You have brains in your head. You have feet in your shoes. You can steer yourself any direction you choose. You’re on your own. And you know what you know. And YOU are the one who’ll decide where to go…” – Dr. Seuss, Oh, the Places You’ll Go!\n\n');

const _t2 = TextSpan(
    style: TextStyle(backgroundColor: Color(0xffccffcc)),
    text:
        '“We are the music-makers, And we are the dreamers of dreams, Wandering by lone sea-breakers, And sitting by desolate streams. \n\nWorld-losers and world-forsakers, Upon whom the pale moon gleams; Yet we are the movers and shakers, Of the world forever, it seems.” – Arthur O’Shaughnessy\n\n');

const _t3 = TextSpan(
    style: TextStyle(backgroundColor: Color(0xffffcccc)),
    text:
        '“Stuff your eyes with wonder, he said, live as if you’d drop dead in ten seconds. See the world. It’s more fantastic than any dream made or paid for in factories.” – Ray Bradbury, Fahrenheit 451');

Floatable _floatable(String text, [FCFloat float = FCFloat.start, FCClear clear = FCClear.none]) =>
    Floatable(
      float: float,
      clear: clear,
      clearMinSpacing: 36,
      padding: float == FCFloat.start
          ? const EdgeInsetsDirectional.only(end: 8)
          : const EdgeInsetsDirectional.only(start: 8),
      child: _Box(Text(text, style: const TextStyle(fontSize: 16))),
    );

class _Box extends StatelessWidget {
  final Widget child;
  final Color? color;

  const _Box(this.child, {Key? key, this.color = const Color(0xffe0e0e0)}) : super(key: key);

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(border: Border.all(), color: color),
        child: Padding(padding: const EdgeInsets.fromLTRB(8, 0, 8, 0), child: child),
      );
}
