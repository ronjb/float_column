import 'package:flutter/widgets.dart';

class ChapterNumber extends StatelessWidget {
  final int number;

  const ChapterNumber(this.number, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      // color: Colors.yellow,
      padding: Directionality.of(context) == TextDirection.ltr
          ? const EdgeInsets.only(right: 10)
          : const EdgeInsets.only(left: 10),
      child: SizedOverflowBox(
        size: const Size(90, 40),
        alignment: Alignment.topLeft,
        child: Text(
          number.toString(),
          style: const TextStyle(fontSize: 54, height: 1),
          // strutStyle: StrutStyle(height: 1.5, forceStrutHeight: false),
        ),
      ),
    );
  }
}

