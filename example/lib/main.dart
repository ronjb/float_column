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
    return Scaffold(
      appBar: AppBar(
        title: const Text('FloatColumn Demo Home Page'),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          // crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text.rich(getText()), //textAlign: TextAlign.center),
            Text.rich(getText()), //textAlign: TextAlign.center),
            Text('$_counter', style: Theme.of(context).textTheme.headline4),
            FloatColumn(
              // textDirection: TextDirection.rtl,
              // crossAxisAlignment: CrossAxisAlignment.end,
              // crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                WrappableText(text: getText(), textAlign: TextAlign.center),
                WrappableText(text: getText(), textAlign: TextAlign.center),
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

TextSpan getText() => TextSpan(children: [
      const TextSpan(text: 'You '),
      WidgetSpan(child: Container(width: 16, height: 16, color: Colors.red)),
      const TextSpan(text: ' have pushed the button this many times:')
    ]);
