part of 'controller.dart';

abstract class PaginationState {
  PaginationState._();

  bool get isDone;
}

typedef PaginatedFetcher<T, State extends PaginationState>
    = Future<PaginationResponse<T, State>> Function(State state);

@immutable
class PaginationResponse<T, State> {
  const PaginationResponse({
    @required this.items,
    @required this.state,
  })  : assert(items != null),
        assert(state != null);

  final List<T> items;
  final State state;
}

class PaginatedCacheController<T, State extends PaginationState>
    extends CacheController<List<T>> {
  PaginatedCacheController({
    @required this.fetcher,
    @required this.saveToCache,
    @required this.loadFromCache,
    this.initialState,
    @required this.isAllFetched,
  });

  final PaginatedFetcher<T, State> fetcher;
  final ToCacheSaver<List<T>> saveToCache;
  final FromCacheLoader<List<T>> loadFromCache;
  final State initialState;
  final bool Function(State state) isAllFetched;

  Batcher<CacheUpdate<List<T>>> _fetcher;
  State _state;
  State get state => _state;

  /// Fetches data from the cache and the [fetcher] simultaneously and returns
  /// the final [CacheUpdate]. If you want to receive updates about events in
  /// between (like events from the cache), you should rather listen to the
  /// [updates] stream.
  Future<CacheUpdate<List<T>>> fetch() => _fetcher.run(_actuallyFetchData);

  Future<CacheUpdate<List<T>>> _actuallyFetchData() async {
    if (lastData == null) {
      _controller.add(CacheUpdate<List<T>>.loading());
    } else {
      _controller.add(CacheUpdate<List<T>>.cached(lastData));
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
              _controller.add(CacheUpdate<List<T>>.cached(data));
            }
          } on NotInCacheException {
            // We just fail silently as the original data will be returned
            // soon – hopefully.
          }
        }),
      // Get data from the original source.
      () async {
        _state = initialState;
        _actuallyFetchMoreData();
      }(),
    ]);

    return lastUpdate;
  }

  /// Fetches more data from the original source.
  Future<CacheUpdate<List<T>>> fetchMore() {
    assert(!_state.isDone,
        'You tried to fetch more items, although everything was fetched already.');

    return _fetcher.run(_actuallyFetchMoreData);
  }

  Future<CacheUpdate<List<T>>> _actuallyFetchMoreData() async {
    _controller.add(CacheUpdate<List<T>>.cached(lastData));

    // Get data from the original source.
    Future.microtask(() async {
      try {
        final response = await fetcher(_state);
        final items = lastData + response.items;
        _state = response.state;

        _controller.add(CacheUpdate<List<T>>.success(items));
        saveToCache(items);
      } catch (error, stackTrace) {
        _controller.add(CacheUpdate<List<T>>.error(
          error,
          stackTrace,
          cachedData: lastData,
        ));
      }
    });

    return lastUpdate;
  }
}
