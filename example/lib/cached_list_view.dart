import 'package:cached_listview/cached_listview.dart';
import 'package:flutter/material.dart';

import 'utils.dart';

class CachedListViewDemo extends StatelessWidget {
  final CacheController controller;

  CachedListViewDemo({@required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Random numbers')),
      body: CachedListView<int>(
        controller: controller,
        itemBuilder: (context, item) => ListTile(title: Text('Number $item.')),
        errorBannerBuilder: (context, error) =>
            ErrorBanner(controller: controller),
        errorScreenBuilder: (context, error) => ErrorScreen(),
        emptyStateBuilder: (context) => EmptyState(),
      ),
    );
  }
}
