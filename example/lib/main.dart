import 'package:flutter/material.dart';

import 'pages/basic_ltr.dart';
import 'pages/basic_rtl.dart';
import 'pages/indents.dart';
import 'pages/inline_floats.dart';
import 'pages/margins_and_padding.dart';
import 'pages/nested.dart';

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

class MyHomePage extends StatelessWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const tabs = <String, Widget>{
      'Basic LTR': BasicLtr(),
      'Basic RTL': BasicRtl(),
      'Inline': InlineFloats(),
      'Nested': Nested(),
      'Indents': Indents(),
      'Margins & Padding': MarginsAndPadding(),
    };

    final tabsTitles = tabs.entries.map((e) => Tab(text: e.key)).toList();
    final tabViews = tabs.entries.map((e) => e.value).toList();

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(title: TabBar(tabs: tabsTitles, isScrollable: true)),
        body: TabBarView(children: tabViews),
      ),
    );
  }
}
