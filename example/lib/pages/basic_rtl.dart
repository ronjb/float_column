import 'package:flutter/material.dart';

import 'package:float_column/float_column.dart';

import '../shared/chapter_number.dart';

class BasicRtl extends StatelessWidget {
  const BasicRtl({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // const TextAlign? textAlign = null;
    // const textAlign = TextAlign.center;
    const textAlign = TextAlign.start;
    // const textAlign = TextAlign.end;
    // const textAlign = TextAlign.left;
    // const textAlign = TextAlign.right;

    // const crossAxisAlignment = CrossAxisAlignment.center;
    const crossAxisAlignment = CrossAxisAlignment.start;
    // const crossAxisAlignment = CrossAxisAlignment.end;
    // const crossAxisAlignment = CrossAxisAlignment.stretch;

    const boxHeight = 40.0;

    return DefaultTextStyle(
      style: const TextStyle(fontSize: 18, color: Colors.black, height: 1.5),
      textAlign: TextAlign.justify,
      child: Directionality(
        textDirection: TextDirection.rtl,
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
                      const Floatable(float: FCFloat.start, child: ChapterNumber(123)),
                      Floatable(
                          float: FCFloat.end,
                          clear: FCClear.both,
                          clearMinSpacing: 20,
                          maxWidthPercentage: 0.333,
                          child: Container(height: boxHeight, color: Colors.orange)),
                      Floatable(
                          float: FCFloat.start,
                          clear: FCClear.both,
                          clearMinSpacing: 40,
                          maxWidthPercentage: 0.333,
                          child: Container(
                            height: 200,
                            color: Colors.blue,
                            margin: Directionality.of(context) == TextDirection.ltr
                                ? const EdgeInsets.only(right: 8)
                                : const EdgeInsets.only(left: 8),
                          )),
                      Floatable(
                          float: FCFloat.end,
                          clear: FCClear.end,
                          clearMinSpacing: 100,
                          maxWidthPercentage: 0.333,
                          child: Container(height: boxHeight, color: Colors.green)),
                      const WrappableText(text: _text, textAlign: textAlign),
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
        '"این همان کاری است که شما باید انجام دهید. زمین و خورشید و حیوانات را دوست داشته باشید ، ثروت را تحقیر کنید ، به هر کسی که درخواست می کند صدقه دهید ، برای احمقان و دیوانه ها ایستادگی کنید ، درآمد و زحمت خود را به دیگران اختصاص دهید ، از جباران متنفر شوید ، در مورد خدا بحث نکنید ، صبر و شادی کنید مردم ، کلاه خود را از چیزی که شناخته شده یا ناشناخته است یا برای هر مرد یا تعداد زیادی مرد بردارید ، آزادانه با افراد تحصیل کرده قدرتمند و با جوانان و مادران خانواده بروید ، این برگها را در هر فصل از هر سال در هوای آزاد بخوانید زندگی خود را بررسی کنید ، تمام آنچه را که در مدرسه یا کلیسا یا هر کتاب به شما گفته شده است ، بررسی کنید ، هر آنچه را که به روح خود توهین می کند کنار بگذارید ، و گوشت شما یک شعر عالی خواهد بود و نه تنها در کلمات بلکه در سکوت غنی ترین تسلط را دارد خطوط لب و صورت و بین مژه های چشم و در هر حرکت و مفصل بدن شما. " - والت ویتمن ، آهنگ خودم');
