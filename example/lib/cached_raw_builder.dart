import 'package:flutter_cached/flutter_cached.dart';
import 'package:flutter/material.dart';

class CachedRawBuilderDemo extends StatelessWidget {
  final CacheController controller;

  CachedRawBuilderDemo({@required this.controller})
      : assert(controller != null);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CachedRawBuilder(
        controller: controller,
        builder: (context, update) {
          if (update.hasData) {
            return ListView(
              children: <Widget>[
                Text('Some data available'),
              ],
            );
          } else {
            return Container(
              color: Colors.blue,
              alignment: Alignment.center,
              child: Text('No data to see here.'),
            );
          }
        },
      ),
    );
  }
}
