import 'dart:math';

import 'package:flutter/material.dart';
import 'package:cached_listview/cached_listview.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Random numbers')),
        body: MyContent(),
      ),
    );
  }
}

class MyContent extends StatefulWidget {
  @override
  _MyContentState createState() => _MyContentState();
}

class _MyContentState extends State<MyContent> {
  List<int> inMemoryCache;
  CacheManager<int> manager;

  @override
  void initState() {
    super.initState();

    var random = Random();
    manager = CacheManager<int>(
      // The fetcher just waits and then either crashes or returns a list of
      // random numbers.
      fetcher: () async {
        await Future.delayed(Duration(seconds: 2));
        if (random.nextBool()) {
          throw UnsupportedError('Oh no! Something terrible happened.');
        }
        return List.generate(random.nextInt(3), (i) => random.nextInt(10));
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
    return CachedListView<int>(
      manager: manager,
      itemBuilder: (context, number) {
        return ListTile(title: Text('Number $number.'));
      },
      errorBannerBuilder: (context, error) {
        return Material(
          color: Colors.red,
          elevation: 4,
          child: Text(
            'An error occurred while fetching the latest numbers: $error',
            style: TextStyle(color: Colors.white),
          ),
        );
      },
      errorScreenBuilder: (context, error) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline),
              Text('Oh no!\n$error'),
            ],
          ),
        );
      },
      emptyStateBuilder: (context) {
        return Center(
          child: Text('No numbers here.'),
        );
      },
    );
  }
}
