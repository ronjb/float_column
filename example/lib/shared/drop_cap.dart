import 'package:flutter/material.dart';

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
          textScaler: textScaleFactor == null
              ? MediaQuery.textScalerOf(context)
              : TextScaler.linear(textScaleFactor!),
          style: style.copyWith(
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

/*
TextStyle textStyleWithGoogleFont([String? fontFamily]) {
  try {
    return GoogleFonts.getFont(fontFamily ?? _fonts[1]);
  } catch (_) {
    return const TextStyle();
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
*/
