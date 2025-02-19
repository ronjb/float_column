import 'package:flutter/material.dart';

import 'pages/basic_ltr.dart';
import 'pages/basic_rtl.dart';
import 'pages/indents.dart';
import 'pages/inline_floats.dart';
import 'pages/margins_and_padding.dart';
import 'pages/nested.dart';
import 'pages/sliver_list.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FloatColumn Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    const tabs = <String, Widget>{
      'Indents': Indents(),
      'Margins & Padding': MarginsAndPadding(),
      'Basic LTR': BasicLtr(),
      'Basic RTL': BasicRtl(),
      'Nested': Nested(),
      'Inline': InlineFloats(),
      'SliverList': SliverListPage(),
    };

    final tabsTitles = tabs.entries.map((e) => Tab(text: e.key)).toList();
    final tabViews = tabs.entries.map((e) => e.value).toList();

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(title: TabBar(tabs: tabsTitles, isScrollable: true)),
        body: SelectionArea(child: TabBarView(children: tabViews)),
      ),
    );
  }
}

/*
// This tests whether FloatColumn properly handles widget size changes
// for widgets embedded in TextSpans via WidgetSpan.
class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FloatColumn Demo')),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(width: double.infinity),

            // Column
            Text('Column:', style: Theme.of(context).textTheme.headlineMedium),
            Container(
              color: Colors.grey[300],
              constraints: const BoxConstraints(minWidth: double.infinity),
              child: Column(
                // crossAxisAlignment: CrossAxisAlignment.start,
                children: [richTextImage()],
              ),
            ),
            const SizedBox(height: 16),

            // FloatColumn
            Text('FloatColumn:',
                style: Theme.of(context).textTheme.headlineMedium),
            Container(
              color: Colors.grey[300],
              constraints: const BoxConstraints(minWidth: double.infinity),
              child: FloatColumn(
                children: [
                  richTextImage(),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

Widget richTextImage() => Text.rich(
      textAlign: TextAlign.center,
      TextSpan(children: [
        WidgetSpan(
            child: Container(width: 100, height: 100, color: Colors.red)
                .animate() //onPlay: (c) => c.repeat(reverse: true))
                .custom(
                  duration: 300.ms,
                  builder: (c, v, ch) =>
                      SizedBox(width: v * 100, height: v * 100, child: ch),
                ),
            ),
        // WidgetSpan(child: image()),
      ]),
    );
*/
