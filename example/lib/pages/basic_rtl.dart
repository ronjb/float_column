import 'package:float_column/float_column.dart';
import 'package:flutter/material.dart';

import '../shared/drop_cap.dart';

class BasicRtl extends StatelessWidget {
  const BasicRtl({super.key});

  @override
  Widget build(BuildContext context) {
    const crossAxisAlignment = CrossAxisAlignment.start;
    // const crossAxisAlignment = CrossAxisAlignment.end;
    // const crossAxisAlignment = CrossAxisAlignment.stretch;

    const boxHeight = 40.0;

    return DefaultTextStyle(
      style: const TextStyle(fontSize: 18, color: Colors.black, height: 1.5),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Builder(
          builder: (context) => SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: FloatColumn(
                crossAxisAlignment: crossAxisAlignment,
                children: [
                  const Floatable(float: FCFloat.start, child: DropCap('فقط')),
                  Floatable(
                      float: FCFloat.end,
                      clear: FCClear.both,
                      clearMinSpacing: 20,
                      maxWidthPercentage: 0.333,
                      child:
                          Container(height: boxHeight, color: Colors.orange)),
                  Floatable(
                      float: FCFloat.start,
                      clear: FCClear.both,
                      clearMinSpacing: 40,
                      maxWidthPercentage: 0.333,
                      child: Container(
                          height: 200,
                          color: Colors.blue,
                          margin: const EdgeInsetsDirectional.only(end: 8))),
                  Floatable(
                      float: FCFloat.end,
                      clear: FCClear.end,
                      clearMinSpacing: 100,
                      maxWidthPercentage: 0.333,
                      child: Container(height: boxHeight, color: Colors.green)),
                  WrappableText(text: _text),
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
    text: 'این کاری است که باید انجام دهید؛ زمين و خورشيد و حيوانات را'
        ' دوست بدار، مال را تحقير نما، به هر كه خواست صدقه بده، براي احمق'
        ' و ديوانه قيام كن، درآمد و كارت را وقف ديگران كن، از ظالمان'
        ' متنفر باش، در مورد خدا مجادله نكن، در برابر خدا صبر و اغماض'
        ' داشته باش. مردم، کلاه خود را برای هیچ چیز معلوم یا ناشناخته یا'
        ' برای هر مرد یا تعدادی مرد بردارید، آزادانه با افراد قدرتمند بی'
        ' سواد و با جوانان و با مادران خانواده ها بروید، این برگ ها را در'
        ' هر فصل از هر سال در هوای آزاد بخوانید. زندگی خود را دوباره'
        ' بررسی کنید، تمام آنچه را که در مدرسه یا کلیسا یا در هر کتابی به'
        ' شما گفته شده است بررسی کنید، هر آنچه را که به روح شما توهین می'
        ' کند را رد کنید، و جسم شما یک شعر عالی خواهد بود و نه تنها در'
        ' کلام خود، بلکه در صامت غنی ترین تسلط را خواهد داشت. خطوط لب و'
        ' صورتش و بین مژه های چشمانت و در هر حرکت و مفصل بدنت.');
