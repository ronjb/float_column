import 'package:flutter/material.dart';
import 'package:intrinsic_size_overflow_box/intrinsic_size_overflow_box.dart';

class DropCap extends StatelessWidget {
  const DropCap(this.text, {super.key, this.size = 2.0, this.textScaleFactor});

  final String text;
  final double size;
  final double? textScaleFactor;

  @override
  Widget build(BuildContext context) {
    final style = DefaultTextStyle.of(context).style;
    final scaler = textScaleFactor == null
        ? MediaQuery.textScalerOf(context)
        : TextScaler.linear(textScaleFactor!);
    final fontSize =
        (style.fontSize ?? 16.0) * (style.height ?? 1.0) * size * 1.1;
    final scaledSize = scaler.scale(fontSize);

    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 10),
      child: SizedBox(
        // color: Colors.orange,
        height: scaledSize * 0.75,
        child: IntrinsicSizeOverflowBox(
          maxHeight: scaledSize * 1.5,
          child: Text(
            text,
            textScaler: scaler,
            style: style.copyWith(fontSize: fontSize, height: 1),
          ),
        ),
      ),
    );
  }
}
