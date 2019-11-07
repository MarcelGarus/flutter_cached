import 'dart:async';

import 'package:meta/meta.dart';

class NotInCacheException implements Exception {
  String toString() => 'The item is not in the cache.';
}

/// The [CacheController] creates [CacheUpdate]s to inform other classes about
/// its state of fetching data.
@immutable
class CacheUpdate<T> {
  CacheUpdate({
    @required this.isFetching,
    this.data,
    this.error,
    this.stackTrace,
  }) : assert(isFetching != null);

  /// Whether the fetching of the original data source is still in progress.
  final bool isFetching;

  /// The value that the source returned.
  final T data;
  bool get hasData => data != null;

  /// An error that the source threw and its stack trace.
  final dynamic error;
  final StackTrace stackTrace;
  bool get hasError => error != null;
}

/// A class that manages fetching data using the provided [fetcher] and saves
/// and loads cached data using [saveToCache] and [loadFromCache]. By calling
/// [fetch] on this class, you can start the process of fetching data
/// simultaneously from the cache and the original source. To get updates about
/// this process, you can listen to the [updates] stream.
class CacheController<T> {
  CacheController({
    @required this.fetcher,
    @required this.saveToCache,
    @required this.loadFromCache,
  })  : assert(fetcher != null),
        assert(saveToCache != null),
        assert(loadFromCache != null);

  final Future<T> Function() fetcher;
  Future<void> _currentFetcher;
  bool get isFetching => _currentFetcher != null;

  final Future<void> Function(T data) saveToCache;
  final Future<T> Function() loadFromCache;

  T _lastData;
  T get lastData => _lastData;

  dynamic _lastError;
  StackTrace _lastStackTrace;
  dynamic get lastError => _lastError;
  StackTrace get lastStackTrace => _lastStackTrace;

  void _addUpdate() {
    for (final controller in _controllers) {
      controller.add(CacheUpdate(
        isFetching: isFetching,
        data: lastData,
        error: lastError,
        stackTrace: lastStackTrace,
      ));
    }
  }

  final Set<StreamController<CacheUpdate<T>>> _controllers = {};
  Stream<CacheUpdate<T>> get updates {
    StreamController<CacheUpdate<T>> controller;
    controller = StreamController<CacheUpdate<T>>(
      onCancel: () {
        controller.close();
        _controllers.remove(controller);
      },
    );
    _controllers.add(controller);

    controller.add(CacheUpdate(
      isFetching: isFetching,
      data: lastData,
      error: lastError,
      stackTrace: lastStackTrace,
    ));

    return controller.stream;
  }

  @Deprecated(
      "You don't need to call dispose anymore. The CacheController takes care "
      "of that by itself now.")
  void dispose() {}

  /// Fetches data from the cache and the [fetcher] simultaneously.
  Future<void> fetch() {
    _currentFetcher ??= _actuallyFetchData();
    return _currentFetcher;
  }

  Future<void> _actuallyFetchData() async {
    // Simultaneously get data from the (probably faster) cache and the
    // original source.
    await Future.wait([
      // Get data from the cache.
      if (_lastData == null)
        Future.microtask(() async {
          try {
            _lastData = await loadFromCache();
            // If the original source was faster than the cache, we don't need
            // to do anything. Otherwise, we push a [CacheUpdate] with the
            // [cachedData] so that it can be displayed to the user while the
            // original source is still loading.
            if (isFetching) _addUpdate();
          } on NotInCacheException {
            // We just fail silently as the original data will be returned
            // soon.
          }
        }),
      // Get data from the original source.
      Future.microtask(() async {
        try {
          T data = await fetcher();
          _lastError = null;
          _lastStackTrace = null;
          saveToCache(data);
        } catch (error, stackTrace) {
          _lastError = error;
          _lastStackTrace = stackTrace;
        } finally {
          _currentFetcher = null;
          _addUpdate();
        }
      }),
    ]);
  }
}
