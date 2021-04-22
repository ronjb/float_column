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
    const textAlign = TextAlign.center;
    // const textAlign = TextAlign.start;
    // const textAlign = TextAlign.end;
    // const textAlign = TextAlign.left;
    // const textAlign = TextAlign.right;

    const crossAxisAlignment = CrossAxisAlignment.center;
    // const crossAxisAlignment = CrossAxisAlignment.start;
    // const crossAxisAlignment = CrossAxisAlignment.end;
    // const crossAxisAlignment = CrossAxisAlignment.stretch;

    const boxHeight = 70.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('FloatColumn Demo Home Page'),
      ),
      body: Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: crossAxisAlignment,
          children: [
            Text.rich(getText1(), textAlign: textAlign),
            Text.rich(getText2(), textAlign: textAlign),
            Text('$_counter', style: Theme.of(context).textTheme.headline4),
            FloatColumn(
              // textDirection: TextDirection.rtl,
              crossAxisAlignment: crossAxisAlignment,
              children: [
                Floatable(
                    float: FCFloat.start,
                    child: Container(width: 105, height: boxHeight, color: Colors.orange)),
                Floatable(
                    float: FCFloat.start,
                    child: Container(width: 50, height: boxHeight, color: Colors.blue)),
                Floatable(
                    float: FCFloat.end,
                    clear: FCClear.end,
                    child: Container(width: 100, height: boxHeight, color: Colors.green)),
                WrappableText(text: getText1(), textAlign: textAlign, clear: FCClear.none),
                WrappableText(text: getText2(), textAlign: textAlign),
                Text('$_counter', style: Theme.of(context).textTheme.headline4),
              ],
            ),
          ],
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

TextSpan getText1() => TextSpan(children: [
      const TextSpan(text: 'این یک متن فارسی است که در سمت راست قرار می‌گیرد'),
      // const TextSpan(
      //     text: ' Neque porro quisquam est, qui dolorem '
      //         'ipsum quia dolor sit amet. '),
      const TextSpan(text: 'You '),
      WidgetSpan(child: Container(width: 16, height: 16, color: Colors.red)),
      const TextSpan(text: ' have pushed the button')
    ]);

TextSpan getText2() => TextSpan(children: [
      const TextSpan(text: 'this '),
      WidgetSpan(child: Container(width: 16, height: 16, color: Colors.red)),
      const TextSpan(text: ' many '),
      WidgetSpan(
        alignment: PlaceholderAlignment.baseline,
        baseline: TextBaseline.alphabetic,
        child: Container(width: 12, height: 12, color: Colors.blue),
      ),
      const TextSpan(text: ' times:')
    ]);
