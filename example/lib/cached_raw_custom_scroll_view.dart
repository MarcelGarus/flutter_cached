import 'package:cached_listview/cached_listview.dart';
import 'package:flutter/material.dart';

class CachedRawCustomScrollViewDemo extends StatelessWidget {
  final CacheController controller;

  CachedRawCustomScrollViewDemo({@required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CachedRawCustomScrollView<int>(
        controller: controller,
        bodySliversBuilder: (context, update) {
          return [
            SliverAppBar(
              title: Text('Random numbers'),
              floating: true,
              pinned: false,
              expandedHeight: 200,
            ),
            if (update.hasData)
              SliverList(
                delegate: SliverChildListDelegate(
                  update.data.map((i) => ListTile(title: Text('$i'))).toList(),
                ),
              ),
            if (update.hasError)
              SliverToBoxAdapter(
                child: ListTile(title: Text(update.error.toString())),
              )
          ];
        },
      ),
    );
  }
}
