import 'package:float_column/float_column.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../shared/drop_cap.dart';

class BasicLtr extends StatelessWidget {
  const BasicLtr({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = (((constraints.maxWidth / 600.0) - 1.0) * 0.75) + 1.0;
        return DefaultTextStyle(
          style: const TextStyle(fontSize: 18, color: Colors.black, height: 1.5),
          child: Scrollbar(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FloatColumn(
                  children: [
                    Floatable(
                      float: FCFloat.end,
                      maxWidthPercentage: 0.25,
                      padding: EdgeInsetsDirectional.only(start: 8),
                      child: Img(assetName: _name('walt_whitman.jpg'), title: 'Walt Whitman'),
                    ),
                    Floatable(
                      float: FCFloat.start,
                      clear: FCClear.end,
                      // clearMinSpacing: -120,
                      maxWidthPercentage: 0.25,
                      padding: EdgeInsetsDirectional.only(end: 12),
                      child: Img(
                        assetName: _name('jeremy-bishop-EwKXn5CapA4-unsplash.jpg'),
                        title: 'Photo by Jeremy Bishop on Unsplash',
                      ),
                    ),
                    WrappableText(text: _text(scale), textScaleFactor: scale),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

String _name(String name) => kIsWeb && kDebugMode ? name : 'assets/$name';

class Img extends StatelessWidget {
  final String assetName;
  final String? title;

  const Img({Key? key, required this.assetName, this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.black,
          padding: const EdgeInsets.all(4),
          child: Image(image: AssetImage(assetName)),
        ),
        if (title?.isNotEmpty ?? false)
          Text(
            title!,
            style: const TextStyle(fontSize: 9),
          ),
      ],
    );
  }
}

// ignore_for_file: prefer_const_constructors, cspell: disable

TextSpan _text(double textScaleFactor) => TextSpan(
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
        TextSpan(
          text: 'his is what you shall do; ',
        ),
        TextSpan(
          text: 'Love',
          style: GoogleFonts.getFont('Sevillana',
              fontWeight: FontWeight.bold, color: Colors.deepPurple),
        ),
        TextSpan(
          text:
              ' the earth and sun and the animals, despise riches, give alms to every one that asks, ',
        ),
        TextSpan(
          text: 'stand up for the stupid and crazy',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple),
        ),
        TextSpan(
          text:
              ', devote your income and labor to others, hate tyrants, argue not concerning God, have patience and indulgence toward the people, ',
        ),
        TextSpan(
          text: 'take off your hat to nothing known or unknown or to any man or number of men',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple),
        ),
        TextSpan(
          text:
              ', go freely with powerful uneducated persons and with the young and with the mothers of families, read these leaves in the open air every season of every year of your life, ',
        ),
        TextSpan(
          text: 're-examine all you have been told',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple),
        ),
        TextSpan(
          text: ' at school or church or in any book, ',
        ),
        TextSpan(
          text: 'dismiss whatever insults your own soul',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple),
        ),
        TextSpan(
          text:
              ', and your very flesh shall be a great poem and have the richest fluency not only in its words but in the silent lines of its lips and face and between the lashes of your eyes and in every motion and joint of your body.” – ',
        ),
        TextSpan(
          text: 'Walt Whitman, ',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple),
        ),
        TextSpan(
          text: 'Song of Myself',
          style: TextStyle(
              fontWeight: FontWeight.bold, fontStyle: FontStyle.italic, color: Colors.deepPurple),
        ),
      ],
    );
