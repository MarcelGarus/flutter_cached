import 'package:flutter_cached/flutter_cached.dart';
import 'package:flutter/material.dart';

class CachedBuilderDemo extends StatelessWidget {
  final CacheController controller;

  CachedBuilderDemo({@required this.controller}) : assert(controller != null);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Numbers')),
      body: CachedBuilder<List<int>>(
        controller: controller,
        errorBannerBuilder: (context, error) {
          return Material(
            elevation: 2,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Text('$error'),
            ),
          );
        },
        errorScreenBuilder: (context, error) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Icon(Icons.cancel, size: 52, color: Colors.red),
              SizedBox(height: 16),
              SizedBox(
                width: 200,
                child: Text('$error', textAlign: TextAlign.center),
              ),
            ],
          );
        },
        builder: (context, items) {
          if (items.isNotEmpty) {
            return ListView(
              children: <Widget>[
                for (var item in items) ListTile(title: Text('$item')),
                ListTile(title: Text('${items.length} items')),
              ],
            );
          } else {
            return Container(
              color: Colors.blue,
              alignment: Alignment.center,
              child: Text(
                'No data to see here.',
                style: TextStyle(color: Colors.white),
              ),
            );
          }
        },
      ),
    );
  }
}
