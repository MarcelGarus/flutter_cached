import 'dart:math';

import 'package:flutter/material.dart';
import 'package:cached_listview/cached_listview.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: Scaffold(body: MyContent()));
  }
}

class MyContent extends StatefulWidget {
  @override
  _MyContentState createState() => _MyContentState();
}

class _MyContentState extends State<MyContent> {
  final manager = CacheManager<int>(
    fetcher: () async {
      await Future.delayed(Duration(seconds: 2));
      if (Random().nextBool()) {
        throw UnsupportedError('Oh no! Something terrible happened.');
      }
      return [1, 2, 3, 4, 5];
    },
    loadFromCache: () async => [1, 2, 3],
    saveToCache: (data) async {},
  );

  @override
  Widget build(BuildContext context) {
    return CachedListView<int>(
      manager: manager,
      itemBuilder: (context, number) {
        return ListTile(title: Text('$number'));
      },
      errorBannerBuilder: (context, error) {
        return ListTile(
          leading: Text('!'),
          title: Text('$error'),
        );
      },
      errorScreenBuilder: (context, error) {
        return Center(child: Text('Oh no!\n$error'));
      },
    );
  }
}
