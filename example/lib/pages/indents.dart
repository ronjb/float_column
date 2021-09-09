import 'package:float_column/float_column.dart';
import 'package:flutter/material.dart';

class Indents extends StatelessWidget {
  const Indents({Key? key}) : super(key: key);

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

    const boxHeight = 89.0;

    return DefaultTextStyle(
      style: const TextStyle(fontSize: 20, color: Colors.black, height: 1.5),
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
                      const Heading(title: 'Indent'),
                      Floatable(
                          float: FCFloat.end,
                          clear: FCClear.both,
                          maxWidthPercentage: 0.333,
                          child: Container(
                              height: boxHeight, color: Colors.orange)),
                      const WrappableText(
                        text: _text,
                        indent: 40,
                        textAlign: textAlign,
                      ),
                      const SizedBox(height: 8),
                      const Heading(title: 'Hanging Indent'),
                      Floatable(
                          float: FCFloat.start,
                          clear: FCClear.both,
                          maxWidthPercentage: 0.333,
                          child: Container(
                              height: 200,
                              color: Colors.blue,
                              margin:
                                  const EdgeInsetsDirectional.only(end: 8))),
                      const WrappableText(
                        text: _text,
                        indent: -40,
                        textAlign: textAlign,
                        padding: EdgeInsets.only(left: 40),
                      ),
                      const SizedBox(height: 8),
                      const Heading(title: 'No Indent'),
                      Floatable(
                          float: FCFloat.end,
                          clear: FCClear.end,
                          // clearMinSpacing: 100,
                          maxWidthPercentage: 0.333,
                          child: Container(
                              height: boxHeight, color: Colors.green)),
                      const WrappableText(
                        text: _text,
                        textAlign: textAlign,
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

class Heading extends StatelessWidget {
  final String title;

  const Heading({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        width: double.infinity,
        color: Colors.grey,
        child: Text(
          title,
          textAlign: TextAlign.center,
          style:
              const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }
}

// cspell: disable
const _text = TextSpan(
    text:
        '“We are the music-makers, And we are the dreamers of dreams, Wandering by lone sea-breakers, And sitting by desolate streams. World-losers and world-forsakers, Upon whom the pale moon gleams; Yet we are the movers and shakers, Of the world forever, it seems.” – Arthur O’Shaughnessy');
