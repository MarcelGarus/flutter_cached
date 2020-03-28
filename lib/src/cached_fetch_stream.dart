part of 'fetch_stream.dart';

typedef SaveToCache<T> = void Function(T);
typedef LoadFromCache<T> = Stream<T> Function();

/// A broadcast [Stream] that wraps a [FetchStream] by saving and loading the
/// data to/from a cache using a [SaveToCache] and a [LoadToCache] function.
/// Only actually calls [fetch] on the original [FetchStream] if necessary.
extension CachedFetchStream<T>
    on StreamAndData<T, CachedFetchStreamData<dynamic>> {
  static StreamAndData<T, CachedFetchStreamData<dynamic>> _create<T>(
    StreamAndData<T, FetchStreamData<dynamic>> parent,
    SaveToCache<T> save,
    LoadFromCache<T> load,
  ) {
    final data = CachedFetchStreamData(parent, save, load);
    return StreamAndData(data._controller.stream, data);
  }

  Future<void> fetch({bool force = false}) => data.fetch(force);
  void dispose() => data.dispose();

  StreamAndData<T, CachedFetchStreamData<dynamic>> cached() => this;
}

class CachedFetchStreamData<T> {
  CachedFetchStreamData(this._parent, this._saveToCache, this._loadFromCache) {
    // Whenever a new value got fetched, it gets saved to the cache.
    _parent.listen((value) {
      _controller.add(value);
      _saveToCache(value);
      _loadingFromCache?.cancel();
      _loadingFromCache = _loadFromCache().listen(_controller.add);
    }, onError: (error, stackTrace) {
      _controller.addError(error, stackTrace);
    }, onDone: _controller.close);
  }

  final _controller = BehaviorSubject<T>();
  final StreamAndData<T, FetchStreamData<dynamic>> _parent;
  final SaveToCache<T> _saveToCache;
  final LoadFromCache<T> _loadFromCache;
  StreamSubscription<T> _loadingFromCache;

  void dispose() {
    _parent.dispose();
    _loadingFromCache.cancel();
    _controller.close();
  }

  Future<void> fetch(bool force) async {
    if (force || !loadFromCache() && !_controller.hasValue) {
      await _parent.fetch();
    }
  }

  /// Loads the value from the cache. Returns whether the [_loadFromCache]
  /// returned a synchronous stream and immediately yielded data.
  bool loadFromCache() {
    var immediatelyReturnedData = false;

    _loadingFromCache?.cancel();
    _loadingFromCache = _loadFromCache().listen((data) {
      _controller.add(data);
      immediatelyReturnedData = true;
    });

    return immediatelyReturnedData;
  }
}
