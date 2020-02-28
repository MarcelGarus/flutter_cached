part of 'controller.dart';

class NotInCacheException implements Exception {
  String toString() => 'The item is not in the cache.';
}

typedef Fetcher<T> = FutureOr<T> Function();
typedef ToCacheSaver<T> = FutureOr<void> Function(T data);
typedef FromCacheLoader<T> = FutureOr<T> Function();

/// A class that manages fetching data using the provided [fetcher] and saves
/// and loads cached data using [saveToCache] and [loadFromCache]. By calling
/// [fetch] on this class, you can start the process of fetching data
/// simultaneously from the cache and the original source. To get updates about
/// this process, you can listen to the [updates] stream.
class SimpleCacheController<T> extends CacheController<T> {
  SimpleCacheController({
    @required this.fetcher,
    @required this.saveToCache,
    @required this.loadFromCache,
  })  : assert(fetcher != null),
        assert(saveToCache != null),
        assert(loadFromCache != null);

  final Fetcher<T> fetcher;
  final ToCacheSaver<T> saveToCache;
  final FromCacheLoader<T> loadFromCache;

  final _fetcher = Batcher<CacheUpdate<T>>();

  /// Fetches data from the cache and the [fetcher] simultaneously and returns
  /// the final [CacheUpdate]. If you want to receive updates about events in
  /// between (like events from the cache), you should rather listen to the
  /// [updates] stream.
  Future<CacheUpdate<T>> fetch() => _fetcher.run(_actuallyFetchData);

  Future<CacheUpdate<T>> _actuallyFetchData() async {
    if (lastData == null) {
      _controller.add(CacheUpdate<T>.loading());
    } else {
      _controller.add(CacheUpdate<T>.cached(lastData));
    }

    // Simultaneously get data from the (probably faster) cache and the
    // original source.
    await Future.wait([
      // Get data from the cache only if we don't already have it in memory.
      if (lastData == null)
        Future.microtask(() async {
          try {
            final data = await loadFromCache();
            // If the original source was faster than the cache, we don't need
            // to do anything. Otherwise, we push an update with the cached
            // data so that it can be already displayed.
            if (isFetching) {
              _controller.add(CacheUpdate<T>.cached(data));
            }
          } on NotInCacheException {
            // We just fail silently as the original data will be returned
            // soon – hopefully.
          }
        }),
      // Get data from the original source.
      Future.microtask(() async {
        try {
          final data = await fetcher();
          _controller.add(CacheUpdate<T>.success(data));
          saveToCache(data);
        } catch (error, stackTrace) {
          _controller.add(CacheUpdate<T>.error(
            error,
            stackTrace,
            cachedData: lastData,
          ));
        }
      }),
    ]);

    return lastUpdate;
  }
}
