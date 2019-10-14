import 'dart:async';

import 'package:meta/meta.dart';

/// The [CacheController] creates [CacheUpdate]s to inform other classes about
/// its state of fetching data.
@immutable
class CacheUpdate<T> {
  /// Whether the fetching of the original data source is still in progress.
  final bool isFetching;

  /// The value that the source returned.
  final T data;
  bool get hasData => data != null;

  /// An error that the source threw.
  final dynamic error;
  bool get hasError => error != null;

  CacheUpdate({@required this.isFetching, this.data, this.error})
      : assert(isFetching != null);
}

/// A class that manages fetching data using the provided [fetcher] and saves
/// and loads cached data using [saveToCache] and [loadFromCache]. By calling
/// [fetch] on this class, you can start the process of fetching data
/// simultaneously from the cache and the original source. To get updates about
/// this process, you can listen to the [updates] stream.
/// Call [dispose] after you're done using the [CacheController].
class CacheController<T> {
  final Future<T> Function() fetcher;
  Future<void> _currentFetcher;

  final Future<void> Function(T data) saveToCache;
  final Future<T> Function() loadFromCache;

  final _updates = StreamController<CacheUpdate<T>>.broadcast();
  Stream<CacheUpdate<T>> get updates => _updates.stream;

  T _lastData;
  T get lastData => _lastData;

  dynamic _lastError;
  dynamic get lastError => _lastError;

  CacheController({
    @required this.fetcher,
    @required this.saveToCache,
    @required this.loadFromCache,
  })  : assert(fetcher != null),
        assert(saveToCache != null),
        assert(loadFromCache != null);

  /// Disposes the internally used stream controller.
  void dispose() => _updates.close();

  /// Fetches data from the cache and the [fetcher] simultaneously.
  Future<void> fetch() {
    _currentFetcher ??= _actuallyFetchData();
    return _currentFetcher;
  }

  Future<void> _actuallyFetchData() async {
    bool fetchingCompleted = false;

    _updates.add(CacheUpdate(
      isFetching: true,
      data: _lastData,
      error: _lastError,
    ));

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
            if (!fetchingCompleted) {
              _updates.add(CacheUpdate(
                isFetching: true,
                data: _lastData,
                error: _lastError,
              ));
            }
          } catch (error) {
            // The [loadFromCache] function throwing means that the cache
            // doesn't contain any cached data yet. In that case, we just fail
            // silently as the original data will be returned soon.
          }
        }),
      // Get data from the original source.
      Future.microtask(() async {
        try {
          T data = await fetcher();
          _lastError = null;
          _updates.add(CacheUpdate(isFetching: false, data: data));
          saveToCache(data);
        } catch (error) {
          _lastError = error;
          _updates.add(CacheUpdate(
            isFetching: false,
            data: _lastData,
            error: error,
          ));
        }
      }),
    ]);

    _currentFetcher = null;
  }
}
