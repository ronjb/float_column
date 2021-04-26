import 'package:float_column/float_column.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FloatColumn Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('FloatColumn Demo'),
      ),
      body: DefaultTextStyle(
        style: const TextStyle(fontSize: 18, color: Colors.black, height: 1.5),
        textAlign: TextAlign.justify,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(
            builder: (context) => SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: crossAxisAlignment,
                  children: [
                    // Text.rich(getText1(), textAlign: textAlign),
                    // Text.rich(getText2(), textAlign: textAlign),
                    // Text('$_counter', style: Theme.of(context).textTheme.headline4),
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
                            maxWidthPercentage: 0.5,
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
                        WrappableText(text: getText1(context), textAlign: textAlign),
                        const SizedBox(width: 0, height: 10),
                        WrappableText(text: getText2(), textAlign: textAlign),
                        Text('$_counter', style: Theme.of(context).textTheme.headline4),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}

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

TextSpan getText1(BuildContext context) => Directionality.of(context) == TextDirection.ltr
    ? const TextSpan(
        text:
            '“This is what you shall do; Love the earth and sun and the animals, despise riches, give alms to every one that asks, stand up for the stupid and crazy, devote your income and labor to others, hate tyrants, argue not concerning God, have patience and indulgence toward the people, take off your hat to nothing known or unknown or to any man or number of men, go freely with powerful uneducated persons and with the young and with the mothers of families, read these leaves in the open air every season of every year of your life, re-examine all you have been told at school or church or in any book, dismiss whatever insults your own soul, and your very flesh shall be a great poem and have the richest fluency not only in its words but in the silent lines of its lips and face and between the lashes of your eyes and in every motion and joint of your body.” – Walt Whitman, Song of Myself')
    : const TextSpan(
        text:
            '"این همان کاری است که شما باید انجام دهید. زمین و خورشید و حیوانات را دوست داشته باشید ، ثروت را تحقیر کنید ، به هر کسی که درخواست می کند صدقه دهید ، برای احمقان و دیوانه ها ایستادگی کنید ، درآمد و زحمت خود را به دیگران اختصاص دهید ، از جباران متنفر شوید ، در مورد خدا بحث نکنید ، صبر و شادی کنید مردم ، کلاه خود را از چیزی که شناخته شده یا ناشناخته است یا برای هر مرد یا تعداد زیادی مرد بردارید ، آزادانه با افراد تحصیل کرده قدرتمند و با جوانان و مادران خانواده بروید ، این برگها را در هر فصل از هر سال در هوای آزاد بخوانید زندگی خود را بررسی کنید ، تمام آنچه را که در مدرسه یا کلیسا یا هر کتاب به شما گفته شده است ، بررسی کنید ، هر آنچه را که به روح خود توهین می کند کنار بگذارید ، و گوشت شما یک شعر عالی خواهد بود و نه تنها در کلمات بلکه در سکوت غنی ترین تسلط را دارد خطوط لب و صورت و بین مژه های چشم و در هر حرکت و مفصل بدن شما. " - والت ویتمن ، آهنگ خودم');

TextSpan getText2() => TextSpan(children: [
      const TextSpan(text: 'You have pushed the button this '),
      WidgetSpan(child: Container(width: 16, height: 16, color: Colors.red)),
      const TextSpan(text: ' many '),
      WidgetSpan(
        alignment: PlaceholderAlignment.baseline,
        baseline: TextBaseline.alphabetic,
        child: Container(width: 12, height: 12, color: Colors.blue),
      ),
      const TextSpan(text: ' times:')
    ]);
