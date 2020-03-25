part of 'fetch_stream.dart';

typedef SaveToCache<T> = void Function(T);
typedef LoadFromCache<T> = Stream<T> Function();

/// A broadcast [Stream] that wraps a [FetchStream] by saving and loading the
/// data to/from a cache using a [SaveToCache] and a [LoadToCache] function.
/// Only actually calls [fetch] on the original [FetchStream] if necessary.
abstract class _CachedFetchStream<T> extends FetchStream<T> {
  _CachedFetchStream._() : super._();

  factory _CachedFetchStream.withSaverAndLoader(
    FetchStream<T> parent,
    SaveToCache<T> saveToCache,
    LoadFromCache<T> loadFromCache,
  ) = _CachedFetchStreamImpl<T>;

  Future<void> fetch({bool force = false});
  void dispose();
}

class _CachedFetchStreamImpl<T> extends _CachedFetchStream<T> {
  _CachedFetchStreamImpl(this._parent, this._saveToCache, this._loadFromCache)
      : super._() {
    _parent.listen((value) {
      _controller.add(value);
      _saveToCache(value);
      _loadingFromCache?.cancel();
      _loadingFromCache = _loadFromCache().listen(_controller.add);
    }, onError: (error, stackTrace) {
      _controller.addError(error, stackTrace);
    }, onDone: _controller.close);
  }

  final _controller = BehaviorSubject();
  final FetchStream<T> _parent;
  final SaveToCache<T> _saveToCache;
  final LoadFromCache<T> _loadFromCache;
  StreamSubscription<T> _loadingFromCache;

  void dispose() {
    _parent.dispose();
    _loadingFromCache.cancel();
    _controller.close();
  }

  Future<void> fetch({bool force = false}) async {
    if (force || !_controller.hasValue) {
      await _parent.fetch();
    }
  }

  @override
  StreamSubscription<T> listen(
    void Function(T event) onData, {
    Function onError,
    void Function() onDone,
    bool cancelOnError,
  }) {
    scheduleMicrotask(fetch);
    return _controller.stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  bool get isBroadcast => true;

  @override
  Stream<E> asyncExpand<E>(Stream<E> Function(T event) convert) =>
      super.asyncExpand(convert)._asCachedFetched(fetch, dispose);

  @override
  Stream<E> asyncMap<E>(FutureOr<E> Function(T event) convert) =>
      super.asyncMap(convert)._asCachedFetched(fetch, dispose);

  @override
  Stream<R> cast<R>() => super.cast<R>()._asCachedFetched(fetch, dispose);

  @override
  Stream<T> distinct([bool Function(T previous, T next) equals]) =>
      super.distinct(equals)._asCachedFetched(fetch, dispose);

  @override
  Stream<S> expand<S>(Iterable<S> Function(T element) convert) =>
      super.expand(convert)._asCachedFetched(fetch, dispose);

  @override
  Stream<T> handleError(Function onError,
          {bool Function(dynamic error) test}) =>
      super.handleError(onError, test: test)._asCachedFetched(fetch, dispose);

  @override
  Stream<S> map<S>(S Function(T event) convert) =>
      super.map(convert)._asCachedFetched(fetch, dispose);

  @override
  Stream<T> skip(int count) =>
      super.skip(count)._asCachedFetched(fetch, dispose);

  @override
  Stream<T> skipWhile(bool Function(T element) test) =>
      super.skipWhile(test)._asCachedFetched(fetch, dispose);

  @override
  Stream<T> take(int count) =>
      super.take(count)._asCachedFetched(fetch, dispose);

  @override
  Stream<T> takeWhile(bool Function(T element) test) =>
      super.takeWhile(test)._asCachedFetched(fetch, dispose);

  @override
  Stream<T> timeout(Duration timeLimit,
          {void Function(EventSink<T> sink) onTimeout}) =>
      super.timeout(timeLimit)._asCachedFetched(fetch, dispose);

  @override
  Stream<S> transform<S>(StreamTransformer<T, S> streamTransformer) =>
      super.transform(streamTransformer)._asCachedFetched(fetch, dispose);

  @override
  Stream<T> where(bool Function(T event) test) =>
      super.where(test)._asCachedFetched(fetch, dispose);
}

extension AsCachedFetched<T> on Stream<T> {
  _ConvertedFetchStream<T> _asCachedFetched(
          Future<void> Function({bool force}) rawFetcher,
          VoidCallback disposer) =>
      _ConvertedFetchStream(this, rawFetcher, disposer);
}

class _ConvertedCachedFetchStream<T> implements _CachedFetchStream<T> {
  _ConvertedCachedFetchStream(this._parent, this._rawFetcher, this._disposer);

  Stream<T> _parent;
  Future<void> Function({bool force}) _rawFetcher;
  VoidCallback _disposer;

  @override
  Future<void> fetch({bool force = false}) => _rawFetcher(force: force);

  @override
  void dispose() => _disposer();

  @override
  StreamSubscription<T> listen(void Function(T event) onData,
          {Function onError, void Function() onDone, bool cancelOnError}) =>
      _parent.listen(onData,
          onError: onError, onDone: onDone, cancelOnError: cancelOnError);

  @override
  Future<bool> any(bool Function(T element) test) => _parent.any(test);

  @override
  Stream<T> asBroadcastStream(
          {void Function(StreamSubscription<T> subscription) onListen,
          void Function(StreamSubscription<T> subscription) onCancel}) =>
      _parent.asBroadcastStream()._asCachedFetched(_rawFetcher, _disposer);

  @override
  Stream<E> asyncExpand<E>(Stream<E> Function(T event) convert) =>
      _parent.asyncExpand(convert)._asCachedFetched(_rawFetcher, _disposer);

  @override
  Stream<E> asyncMap<E>(FutureOr<E> Function(T event) convert) =>
      _parent.asyncMap(convert)._asCachedFetched(_rawFetcher, _disposer);

  @override
  Stream<R> cast<R>() =>
      _parent.cast<R>()._asCachedFetched(_rawFetcher, _disposer);

  @override
  Future<bool> contains(Object needle) => _parent.contains(needle);

  @override
  Stream<T> distinct([bool Function(T previous, T next) equals]) =>
      _parent.distinct(equals)._asCachedFetched(_rawFetcher, _disposer);

  @override
  Future<E> drain<E>([E futureValue]) => _parent.drain<E>(futureValue);

  @override
  Future<T> elementAt(int index) => _parent.elementAt(index);

  @override
  Future<bool> every(bool Function(T element) test) => _parent.every(test);

  @override
  Stream<S> expand<S>(Iterable<S> Function(T element) convert) =>
      _parent.expand(convert)._asCachedFetched(_rawFetcher, _disposer);

  @override
  Future<T> get first => _parent.first;

  @override
  Future<T> firstWhere(bool Function(T element) test, {T Function() orElse}) =>
      _parent.firstWhere(test, orElse: orElse);

  @override
  Future<S> fold<S>(
          S initialValue, S Function(S previous, T element) combine) =>
      _parent.fold(initialValue, combine);

  @override
  Future forEach(void Function(T element) action) => _parent.forEach(action);

  @override
  Stream<T> handleError(Function onError,
          {bool Function(dynamic error) test}) =>
      _parent
          .handleError(onError, test: test)
          ._asCachedFetched(_rawFetcher, _disposer);

  @override
  bool get isBroadcast => _parent.isBroadcast;

  @override
  Future<bool> get isEmpty => _parent.isEmpty;

  @override
  Future<String> join([String separator = ""]) => _parent.join(separator);

  @override
  Future<T> get last => _parent.last;

  @override
  Future<T> lastWhere(bool Function(T element) test, {T Function() orElse}) =>
      _parent.lastWhere(test, orElse: orElse);

  @override
  Future<int> get length => _parent.length;

  @override
  Stream<S> map<S>(S Function(T event) convert) =>
      _parent.map(convert)._asCachedFetched(_rawFetcher, _disposer);

  @override
  Future pipe(StreamConsumer<T> streamConsumer) => _parent.pipe(streamConsumer);

  @override
  Future<T> reduce(T Function(T previous, T element) combine) =>
      _parent.reduce(combine);

  @override
  Future<T> get single => _parent.single;

  @override
  Future<T> singleWhere(bool Function(T element) test, {T Function() orElse}) =>
      _parent.singleWhere(test, orElse: orElse);

  @override
  Stream<T> skip(int count) =>
      _parent.skip(count)._asCachedFetched(_rawFetcher, _disposer);

  @override
  Stream<T> skipWhile(bool Function(T element) test) =>
      _parent.skipWhile(test)._asCachedFetched(_rawFetcher, _disposer);

  @override
  Stream<T> take(int count) =>
      _parent.take(count)._asCachedFetched(_rawFetcher, _disposer);

  @override
  Stream<T> takeWhile(bool Function(T element) test) =>
      _parent.takeWhile(test)._asCachedFetched(_rawFetcher, _disposer);

  @override
  Stream<T> timeout(Duration timeLimit,
          {void Function(EventSink<T> sink) onTimeout}) =>
      _parent.timeout(timeLimit)._asCachedFetched(_rawFetcher, _disposer);

  @override
  Future<List<T>> toList() => _parent.toList();

  @override
  Future<Set<T>> toSet() => _parent.toSet();

  @override
  Stream<S> transform<S>(StreamTransformer<T, S> streamTransformer) => _parent
      .transform(streamTransformer)
      ._asCachedFetched(_rawFetcher, _disposer);

  @override
  Stream<T> where(bool Function(T event) test) =>
      _parent.where(test)._asCachedFetched(_rawFetcher, _disposer);
}
