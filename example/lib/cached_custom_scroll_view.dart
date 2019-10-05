import 'package:cached_listview/cached_listview.dart';
import 'package:flutter/material.dart';

import 'utils.dart';

class CachedCustomScrollViewDemo extends StatelessWidget {
  final CacheController controller;

  CachedCustomScrollViewDemo({@required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /*body: CachedRawCustomScrollView<int>(
        controller: controller,
        headerSliversBuilder: (_, __, ___) => [
          SliverAppBar(
            title: Text('Random numbers'),
            floating: true,
            pinned: false,
            expandedHeight: 200,
          ),
        ],
        bodySliversBuilder: (_, __) => [
          for (var i = 0; i < 8; i++) ...[
            SliverGrid.count(
              crossAxisCount: 2,
              children: <Widget>[
                _buildItem(1, Colors.yellow),
                _buildItem(2, Colors.orange),
              ],
            ),
            SliverList(
              delegate: SliverChildListDelegate([
                _buildItem(3, Colors.lightBlueAccent),
              ]),
            ),
          ],
        ],
      ),*/
      body: CachedCustomScrollView<int>(
        controller: controller,
        errorScreenBuilder: (context, error) => ErrorScreen(),
        errorBannerBuilder: (context, error) =>
            ErrorBanner(controller: controller),
        emptyStateBuilder: (context) => EmptyState(),
        headerSliversBuilder: (context) {
          return [
            SliverAppBar(
              title: Text('Random numbers'),
              floating: true,
              pinned: false,
              expandedHeight: 200,
            ),
          ];
        },
        itemSliversBuilder: (context, items) {
          return [
            for (var i = 0; i < items.length; i++)
              if (i < items.length - 4) ...[
                SliverGrid.count(
                  crossAxisCount: 2,
                  children: <Widget>[
                    _buildItem(items[i], Colors.yellow),
                    _buildItem(items[i++], Colors.orange),
                  ],
                ),
                SliverList(
                  delegate: SliverChildListDelegate([
                    _buildItem(items[i], Colors.lightBlueAccent),
                  ]),
                ),
              ],
          ];
        },
      ),
    );
  }

  Widget _buildItem(int number, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: color,
      child: Text('$number'),
    );
  }
}
