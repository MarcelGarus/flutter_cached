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
          throw UnsupportedError('Oh no! Something terrible happened.');
        }
        return List.generate(random.nextInt(7), (i) => random.nextInt(10));
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
      controller: controller,
      itemBuilder: (context, number) {
        return ListTile(title: Text('Number $number.'));
      },
      errorBannerBuilder: (context, error) {
        return Material(
          color: Colors.red,
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              "An error occurred while fetching the latest numbers.\n"
              "You're currently seeing a cached version.",
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
      },
      errorScreenBuilder: (context, error) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline),
              SizedBox(height: 8),
              Text(
                'Oh no!\nSomething terrible happened!',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
      emptyStateBuilder: (context) => Center(child: Text('No numbers here.')),
    );
  }
}
