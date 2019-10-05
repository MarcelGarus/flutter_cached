import 'dart:async';

import 'package:meta/meta.dart';

/// The [CacheController] creates [CacheUpdate]s to inform other classes about
/// its state of fetching data.
@immutable
class CacheUpdate<Item> {
  /// Whether the fetching of the original data source is still in progress.
  final bool isFetching;

  /// A list of items that the source returned.
  final List<Item> data;
  bool get hasData => data != null;

  /// An error that the source threw.
  final dynamic error;
  bool get hasError => error != null;

  CacheUpdate({@required this.isFetching, this.data, this.error})
      : assert(isFetching != null),
        assert(!isFetching || error == null);
}

/// A class that manages fetching data using the provided [fetcher] and saves
/// and loads cached data using [saveToCache] and [loadFromCache]. By calling
/// [fetch] on this class, you can start the process of fetching data
/// simultaneously from the cache and the original source. To get updates about
/// this process, you can listen to the [updates] stream.
/// Call [dispose] after you're done using the [CacheController].
class CacheController<Item> {
  final Future<List<Item>> Function() fetcher;
  final Future<void> Function(List<Item> items) saveToCache;
  final Future<List<Item>> Function() loadFromCache;

  final _updates = StreamController<CacheUpdate<Item>>.broadcast();
  Stream<CacheUpdate> get updates => _updates.stream;
  List<Item> cachedData;

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
  Future<void> fetch() async {
    bool fetchingCompleted = false;

    _updates.add(CacheUpdate(isFetching: true, data: cachedData));

    // Simultaneously get data from the (probably faster) cache and the
    // original source.
    await Future.wait([
      // Get data from the cache.
      Future.microtask(() async {
        try {
          cachedData = await loadFromCache();
          // If the original source was faster than the cache, we don't need
          // to do anything. Otherwise, we push a [CacheUpdate] with the
          // [cachedData] so that it can be displayed to the user while the
          // original source is still loading.
          if (!fetchingCompleted) {
            _updates.add(CacheUpdate(
              isFetching: true,
              data: cachedData,
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
          List<Item> data = await fetcher();
          _updates.add(CacheUpdate(isFetching: false, data: data));
          //unawaited(saveToCache(data));
          saveToCache(data);
        } catch (error) {
          _updates.add(CacheUpdate(
            isFetching: false,
            error: error,
            data: cachedData,
          ));
        }
      }),
    ]);
  }
}
