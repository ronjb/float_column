import 'package:flutter/material.dart';

import 'package:float_column/float_column.dart';

import '../shared/drop_cap.dart';

class BasicRtl extends StatelessWidget {
  const BasicRtl({Key? key}) : super(key: key);

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
                      const Floatable(
                          float: FCFloat.start, child: DropCap('فقط')),
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
        '"هذا ما يجب أن تفعله ؛ أحبوا الأرض والشمس والحيوانات ، واحتقروا الثروات ، وأعطوا الصدقات لكل من يسأل ، وادافع عن الغباء والمجنون ، وخصص دخلكم وعملك للآخرين ، واكرهوا الطغاة ، ولا تجادلوا بشأن الله ، وتحلى بالصبر والتسامح تجاه أيها الناس ، خلع قبعتك إلى لا شيء معروف أو غير معروف أو لأي رجل أو عدد من الرجال ، اذهب بحرية مع الأشخاص الأقوياء غير المتعلمين ومع الشباب وأمهات العائلات ، اقرأ هذه الأوراق في الهواء الطلق في كل موسم من كل عام حياتك ، أعد فحص كل ما قيل لك في المدرسة أو الكنيسة أو في أي كتاب ، وتجاهل أي إهانة لروحك ، وسوف يكون جسدك قصيدة عظيمة ولديك طلاقة غنية ليس فقط في كلماتها ولكن في الصمت. خطوط شفتيها ووجهها وبين رموش عينيك وفي كل حركة ومفصل لجسمك ". – Walt Whitman, Song of Myself');
