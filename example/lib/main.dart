import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_cached/flutter_cached.dart';

import 'cached_raw_builder.dart';
import 'cached_builder.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<int> inMemoryCache;
  CacheController<List<int>> controller;

  @override
  void initState() {
    super.initState();

    var random = Random();
    controller = SimpleCacheController<List<int>>(
      // The fetcher just waits and then either crashes or returns a list of
      // random numbers.
      fetcher: () async {
        await Future.delayed(Duration(seconds: 2));
        if (random.nextDouble() < 0.8) {
          return List.generate(random.nextInt(100), (i) => random.nextInt(10));
        }
        if (random.nextDouble() < 0.1) {
          return [];
        }
        throw UnsupportedError('Oh no! Something terrible happened.');
      },
      loadFromCache: () async => throw NotInCacheException(),
      saveToCache: (_) async {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Cached ListView examples')),
        body: Builder(
          builder: (context) {
            return ListView(
              children: <Widget>[
                ListTile(
                  title: Text('CachedBuilder demo'),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => CachedBuilderDemo(
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
            );
          },
        ),
      ),
    );
  }
}
