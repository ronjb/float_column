import 'package:flutter/material.dart';

import 'pages/basic_ltr.dart';
import 'pages/basic_rtl.dart';
import 'pages/indents.dart';
import 'pages/margins_and_padding.dart';
import 'pages/multiple_paragraphs.dart';

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
    const tabViews = <Widget>[
      BasicLtr(),
      BasicRtl(),
      MultipleParagraphs(),
      MarginsAndPadding(),
      Indents(),
    ];

    final tabs = tabViews.map((e) => Tab(text: e.runtimeType.toString())).toList();

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(title: TabBar(tabs: tabs, isScrollable: true)),
        body: const TabBarView(children: tabViews),
      ),
    );
  }
}
