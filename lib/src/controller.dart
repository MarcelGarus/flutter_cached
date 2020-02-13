import 'dart:async';

import 'package:meta/meta.dart';

import 'batcher.dart';
import 'update.dart';

part 'paginated.dart';
part 'simple.dart';

abstract class CacheController<T> {
  final _controller = UpdatesController<T>();

  CacheUpdate<T> get lastUpdate => _controller.lastUpdate;
  bool get isFetching => lastUpdate?.isFetching ?? false;
  T get lastData => lastUpdate?.data;
  dynamic get lastError => lastUpdate?.error;
  StackTrace get lastStackTrace => lastUpdate?.stackTrace;

  /// A stream of [CacheUpdate]s of this controller. A new update appears
  /// everytime something new happens that's also relevant for the listener
  /// (like, new data is available or an error occurred during fetching).
  Stream<CacheUpdate<T>> get updates => _controller.updates;

  /// Fetches data from the cache and the [fetcher] simultaneously and returns
  /// the final [CacheUpdate]. If you want to receive updates about events in
  /// between (like events from the cache), you should rather listen to the
  /// [updates] stream.
  Future<CacheUpdate<T>> fetch();
}
