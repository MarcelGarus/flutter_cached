import 'dart:math';

import 'package:flutter/material.dart';
import 'package:cached_listview/cached_listview.dart';

import 'cached_raw_builder.dart';
import 'cached_raw_custom_scroll_view.dart';
import 'cached_custom_scroll_view.dart';
import 'cached_list_view.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MaterialApp(home: MainMenu());
}

class MainMenu extends StatefulWidget {
  @override
  _MainMenuState createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  List<int> inMemoryCache;
  CacheController<int> controller;

  @override
  void initState() {
    super.initState();

    var random = Random();
    controller = CacheController<int>(
      // The fetcher just waits and then either crashes or returns a list of
      // random numbers.
      fetcher: () async {
        await Future.delayed(Duration(seconds: 2));
        if (random.nextBool()) {
          return List.generate(random.nextInt(100), (i) => random.nextInt(10));
        }
        if (random.nextBool()) {
          return [];
        }
        throw UnsupportedError('Oh no! Something terrible happened.');
      },
      loadFromCache: () async {
        if (inMemoryCache == null) {
          throw StateError('Nothing saved in cache.');
        }
        return inMemoryCache;
      },
      saveToCache: (data) async => inMemoryCache = data,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Cached ListView examples')),
      body: ListView(
        children: <Widget>[
          ListTile(
            title: Text('CachedListView demo'),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => CachedListViewDemo(controller: controller),
            )),
          ),
          ListTile(
            title: Text('CachedCustomScrollView demo'),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) =>
                  CachedCustomScrollViewDemo(controller: controller),
            )),
          ),
          ListTile(
            title: Text('CachedRawCustomScrollView demo'),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => CachedRawCustomScrollViewDemo(
                controller: controller,
              ),
            )),
          ),
          ListTile(
            title: Text('CachedRawBuilder demo'),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => CachedRawBuilderDemo(
                controller: controller,
              ),
            )),
          ),
        ],
      ),
    );
  }
}

class ExampleDemo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: <Widget>[
        SliverAppBar(
          title: Text('Title'),
          expandedHeight: 200,
        ),
        SliverList(
          delegate: SliverChildListDelegate([
            Container(color: Colors.red, height: 200),
          ]),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Container(color: Colors.white),
        ),
      ],
    );
  }
}
