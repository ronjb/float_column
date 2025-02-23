import 'package:float_column/float_column.dart';
import 'package:flutter/material.dart';

import '../shared/drop_cap.dart';

class MarginsAndPadding extends StatelessWidget {
  const MarginsAndPadding({super.key});

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

    const boxHeight = 40.0;

    return DefaultTextStyle(
      style: const TextStyle(fontSize: 18, color: Colors.black, height: 1.5),
      textAlign: textAlign,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Builder(
          builder: (context) => SingleChildScrollView(
            child: SafeArea(
              minimum: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: crossAxisAlignment,
                children: [
                  FloatColumn(
                    crossAxisAlignment: crossAxisAlignment,
                    children: [
                      Floatable(
                          float: FCFloat.start, child: DropCap(123.toString())),
                      Floatable(
                          float: FCFloat.end,
                          clear: FCClear.both,
                          clearMinSpacing: 20,
                          maxWidthPercentage: 0.333,
                          child: Container(
                              height: boxHeight, color: Colors.orange)),
                      Floatable(
                          float: FCFloat.start,
                          clear: FCClear.both,
                          clearMinSpacing: 40,
                          maxWidthPercentage: 0.333,
                          child: Container(
                              height: 200,
                              color: Colors.blue,
                              margin:
                                  const EdgeInsetsDirectional.only(end: 8))),
                      Floatable(
                          float: FCFloat.end,
                          clear: FCClear.end,
                          clearMinSpacing: 100,
                          maxWidthPercentage: 0.333,
                          child: Container(
                              height: boxHeight, color: Colors.green)),
                      WrappableText(
                        text: _text,
                        textAlign: textAlign,
                        margin: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                        padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
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
    text: '“This is what you shall do; Love the earth and sun and the animals, '
        'despise riches, give alms to every one that asks, stand up for the '
        'stupid and crazy, devote your income and labor to others, hate '
        'tyrants, argue not concerning God, have patience and indulgence '
        'toward the people, take off your hat to nothing known or unknown '
        'or to any man or number of men, go freely with powerful uneducated '
        'persons and with the young and with the mothers of families, read '
        'these leaves in the open air every season of every year of your '
        'life, re-examine all you have been told at school or church or in '
        'any book, dismiss whatever insults your own soul, and your very '
        'flesh shall be a great poem and have the richest fluency not only '
        'in its words but in the silent lines of its lips and face and '
        'between the lashes of your eyes and in every motion and joint of '
        'your body.” – Walt Whitman, Song of Myself');
