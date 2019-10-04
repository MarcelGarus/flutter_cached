import 'dart:math';

import 'package:flutter/material.dart';
import 'package:cached_listview/cached_listview.dart';

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
            title: Text('CachedListView with custom slivers demo'),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) =>
                  CachedCustomScrollViewDemo(controller: controller),
            )),
          ),
        ],
      ),
    );
  }
}

class CachedListViewDemo extends StatelessWidget {
  final CacheController controller;

  CachedListViewDemo({@required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Random numbers')),
      body: CachedListView<int>(
        controller: controller,
        itemBuilder: (context, number) =>
            ListTile(title: Text('Number $number.')),
        errorBannerBuilder: (context, error) => ErrorBanner(),
        errorScreenBuilder: (context, error) => ErrorScreen(),
        emptyStateBuilder: (context) => EmptyState(),
      ),
    );
  }
}

class CachedCustomScrollViewDemo extends StatelessWidget {
  final CacheController controller;

  CachedCustomScrollViewDemo({@required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxScrolled) => [
          SliverAppBar(
            title: Text('Random numbers'),
            floating: true,
            pinned: false,
            expandedHeight: 200,
          ),
        ],
        body: CachedListView<int>(
          controller: controller,
          errorScreenBuilder: (context, error) => ErrorScreen(),
          errorBannerBuilder: (context, error) => ErrorBanner(),
          emptyStateBuilder: (context) => EmptyState(),
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

class ErrorBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
  }
}

class ErrorScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
  }
}

class EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(child: Text('No numbers here.'));
}
