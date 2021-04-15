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
    const TextAlign? textAlign = null;
    // const textAlign = TextAlign.center;
    // const textAlign = TextAlign.start;
    // const textAlign = TextAlign.end;
    // const textAlign = TextAlign.left;
    // const textAlign = TextAlign.right;

    // const crossAxisAlignment = CrossAxisAlignment.center;
    const crossAxisAlignment = CrossAxisAlignment.start;
    // const crossAxisAlignment = CrossAxisAlignment.end;
    // const crossAxisAlignment = CrossAxisAlignment.stretch;

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
                WrappableText(text: getText1(), textAlign: textAlign),
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
      const TextSpan(text: 'You '),
      WidgetSpan(child: Container(width: 16, height: 16, color: Colors.red)),
      const TextSpan(text: ' have pushed the button this many times:')
    ]);

TextSpan getText2() => TextSpan(children: [
      const TextSpan(text: 'You '),
      WidgetSpan(child: Container(width: 16, height: 16, color: Colors.red)),
      const TextSpan(text: ' have '),
      WidgetSpan(
        alignment: PlaceholderAlignment.baseline,
        baseline: TextBaseline.alphabetic,
        child: Container(width: 12, height: 12, color: Colors.blue),
      ),
      const TextSpan(text: ' pushed:')
    ]);
