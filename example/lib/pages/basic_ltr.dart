import 'package:float_column/float_column.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../shared/drop_cap.dart';

class BasicLtr extends StatelessWidget {
  const BasicLtr({super.key});

  @override
  Widget build(BuildContext context) {
    final scale =
        (((MediaQuery.of(context).size.width / 600.0) - 1.0) * 0.3) + 1.0;

    return DefaultTextStyle(
      style: const TextStyle(fontSize: 18, color: Colors.black, height: 1.5),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FloatColumn(
            children: [
              Text.rich(_text(context, scale),
                  textScaler: TextScaler.linear(scale)),
            ],
          ),
        ),
      ),
    );
  }
}

String _name(String name) => kIsWeb && kDebugMode ? name : 'assets/$name';

class Img extends StatelessWidget {
  const Img({super.key, required this.assetName, this.title});

  final String assetName;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.black,
          padding: const EdgeInsets.all(4),
          child: Image(image: AssetImage(assetName), semanticLabel: title),
        ),
        if (title?.isNotEmpty ?? false)
          Text(
            title!,
            style: const TextStyle(fontSize: 9),
            textAlign: TextAlign.center,
          ),
      ],
    );
  }
}

// cspell: disable

TextSpan _text(BuildContext context, double textScaleFactor) => TextSpan(
      children: [
        WidgetSpan(
          child: Floatable(
            float: FCFloat.start,
            child: DropCap(
              '“T',
              size: 3,
              textScaleFactor: textScaleFactor,
            ),
          ),
        ),
        WidgetSpan(
          child: Floatable(
            float: FCFloat.end,
            clear: FCClear.both,
            clearMinSpacing: -50 * textScaleFactor,
            maxWidthPercentage: 0.33 / textScaleFactor,
            padding: const EdgeInsetsDirectional.only(start: 8),
            child: Img(
                assetName: _name('walt_whitman.jpg'), title: 'Walt Whitman'),
          ),
        ),
        WidgetSpan(
          child: Floatable(
            float: FCFloat.start,
            clear: FCClear.start,
            clearMinSpacing: 65 * textScaleFactor,
            maxWidthPercentage: 0.25 / textScaleFactor,
            padding: const EdgeInsetsDirectional.only(end: 12),
            child: Img(
              assetName: _name('jeremy-bishop-EwKXn5CapA4-unsplash.jpg'),
              title: 'Photo by Jeremy Bishop on Unsplash',
            ),
          ),
        ),
        const TextSpan(
          text: 'his is what you shall do; ',
        ),
        TextSpan(
          text: 'Love',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
            decoration: TextDecoration.underline,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              ScaffoldMessenger.of(context)
                ..removeCurrentSnackBar()
                ..showSnackBar(
                    const SnackBar(content: Text('Tapped on "Love"')));
            },
        ),
        const TextSpan(
          text: ' the earth and sun and the animals, despise riches, give alms '
              'to every one that asks, ',
        ),
        TextSpan(
          text: 'stand up for the stupid and crazy',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
            decoration: TextDecoration.underline,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              ScaffoldMessenger.of(context)
                ..removeCurrentSnackBar()
                ..showSnackBar(const SnackBar(
                    content:
                        Text('Tapped on "stand up for the stupid and crazy"')));
            },
        ),
        const TextSpan(
          text: ', devote your income and labor to others, hate tyrants, argue '
              'not concerning God, have patience and indulgence toward the '
              'people, ',
        ),
        const TextSpan(
          text:
              'take off your hat to nothing known or unknown or to any man or '
              'number of men',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
        ),
        const TextSpan(
          text: ', go freely with powerful uneducated persons and with the '
              'young and with the mothers of families, read these leaves in '
              'the open air every season of every year of your life, ',
        ),
        const TextSpan(
          text: 're-examine all you have been told',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
        ),
        const TextSpan(
          text: ' at school or church or in any book, ',
        ),
        const TextSpan(
          text: 'dismiss whatever insults your own soul',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
        ),
        const TextSpan(
          text: ', and your very flesh shall be a great poem and have the '
              'richest fluency not only in its words but in the silent lines '
              'of its lips and face and between the lashes of your eyes and '
              'in every motion and joint of your body.” – ',
        ),
        const TextSpan(
          text: 'Walt Whitman, ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
        ),
        TextSpan(
          text: 'Song of Myself',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
            color: Colors.deepPurple,
            decoration: TextDecoration.underline,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              ScaffoldMessenger.of(context)
                ..removeCurrentSnackBar()
                ..showSnackBar(const SnackBar(
                    content: Text('Tapped on "Song of Myself"')));
            },
        ),
      ],
    );
