import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DropCap extends StatelessWidget {
  const DropCap(this.text, {super.key, this.size = 2.0, this.textScaleFactor});

  final String text;
  final double size;
  final double? textScaleFactor;

  @override
  Widget build(BuildContext context) {
    final style = DefaultTextStyle.of(context).style;

    return Padding(
      padding: Directionality.of(context) == TextDirection.ltr
          ? const EdgeInsets.only(right: 10)
          : const EdgeInsets.only(left: 10),
      // ignore: avoid_unnecessary_containers
      child: Container(
        // color: Colors.yellow,
        child: Text(
          text,
          textScaleFactor:
              textScaleFactor ?? MediaQuery.of(context).textScaleFactor,
          style: GoogleFonts.getFont(_fonts[1],
              fontSize: (style.fontSize ?? 16.0) *
                  (style.height ?? 1.0) *
                  size *
                  0.99,
              height: 1),
        ),
      ),
    );
  }
}

// cspell: disable
const _fonts = [
  'Great Vibes',
  'Sevillana',
  'Oleo Script',
  'Oleo Script Swash Caps',
  'Seaweed Script',
  'Lobster',
  'Alfa Slab One',
  'Playball',
  'Monoton',
  'Londrina Shadow',
  'Rye',
  'UnifrakturMaguntia',
  'Frijole',
  'Creepster',
  'Sail',
  'Faster One',
  'Shojumaru',
  'UnifrakturCook',
  'Nosifer',
  'Akronim',
  'Ewert',
];
