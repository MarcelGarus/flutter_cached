import 'package:cached_listview/cached_listview.dart';
import 'package:flutter/material.dart';

class ErrorBanner extends StatelessWidget {
  final CacheController controller;

  const ErrorBanner({Key key, @required this.controller})
      : assert(controller != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialBanner(
      leading: Icon(Icons.error_outline),
      padding: const EdgeInsets.all(8),
      content: Text(
        "An error occurred while fetching the latest numbers. "
        "You're currently seeing a cached version.",
      ),
      actions: <Widget>[
        FlatButton(child: Text('Try again'), onPressed: controller.fetch),
      ],
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
