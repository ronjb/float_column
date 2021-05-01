import 'package:flutter/material.dart';

import 'package:float_column/float_column.dart';

class MarginsAndPadding2 extends StatelessWidget {
  const MarginsAndPadding2({Key? key}) : super(key: key);

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

    const boxHeight = 40.0;

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
                      Floatable(
                        float: FCFloat.end,
                        clear: FCClear.both,
                        maxWidthPercentage: 0.333,
                        child: Container(height: boxHeight, color: Colors.orange),
                        margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                        padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                      ),
                      const WrappableText(
                        text: _text,
                        textAlign: textAlign,
                        indent: 0,
                        margin: EdgeInsets.fromLTRB(0, 0, 0, 0),
                        padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                      ),
                      Floatable(
                        float: FCFloat.start,
                        clear: FCClear.both,
                        maxWidthPercentage: 0.333,
                        margin: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 0),
                        padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 8, 0),
                        child: Container(height: 200, color: Colors.blue),
                      ),
                      Floatable(
                        // float: FCFloat.start,
                        maxWidthPercentage: 0.333,
                        margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                        padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                        child: Container(height: boxHeight, color: Colors.red),
                      ),
                      const WrappableText(
                        text: _text,
                        textAlign: textAlign,
                        indent: 0,
                        margin: EdgeInsets.fromLTRB(0, 0, 0, 0),
                        padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                      ),
                      Floatable(
                        float: FCFloat.end,
                        clear: FCClear.end,
                        maxWidthPercentage: 0.333,
                        margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                        padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                        child: Container(height: boxHeight, color: Colors.green),
                      ),
                      const WrappableText(
                        text: _text,
                        textAlign: textAlign,
                        indent: 0,
                        margin: EdgeInsets.fromLTRB(0, 0, 0, 0),
                        padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
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

// cspell: disable
const _text = TextSpan(
    text:
        '“We are the music-makers, And we are the dreamers of dreams, Wandering by lone sea-breakers, And sitting by desolate streams. World-losers and world-forsakers, Upon whom the pale moon gleams; Yet we are the movers and shakers, Of the world forever, it seems.” – Arthur O’Shaughnessy');
