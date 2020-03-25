import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';

part 'cached_fetch_stream.dart';

typedef Fetcher<T> = FutureOr<T> Function();

/// A broadcast [Stream] that takes a [Function] as an argument that gets
/// executed when it's [listen]ed to the first time and whenever [fetch] gets
/// called.
abstract class FetchStream<T> extends Stream<T> {
  FetchStream._();

  factory FetchStream(Fetcher<T> fetcher) = _FetchStreamImpl<T>;

  Future<void> fetch();
  void dispose();
}

class _FetchStreamImpl<T> extends FetchStream<T> {
  _FetchStreamImpl(this._fetcher) : super._();

  final _controller = BehaviorSubject();
  final Fetcher<T> _fetcher;
  bool _isFetching = false;

  void dispose() => _controller.close();

  Future<void> fetch() async {
    if (_isFetching) return;

    _isFetching = true;

    final result = await _fetcher();
    _controller.add(result);

    _isFetching = false;
  }

  @override
  StreamSubscription<T> listen(
    void Function(T event) onData, {
    Function onError,
    void Function() onDone,
    bool cancelOnError,
  }) {
    if (_controller.value == null) {
      fetch();
    }
    return _controller.stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  bool get isBroadcast => true;

  _CachedFetchStream<T> cached({
    @required SaveToCache save,
    @required LoadFromCache load,
  }) {
    return _CachedFetchStream.withSaverAndLoader(this, save, load);
  }

  @override
  Stream<E> asyncExpand<E>(Stream<E> Function(T event) convert) =>
      super.asyncExpand(convert)._asFetched(fetch, dispose);

  @override
  Stream<E> asyncMap<E>(FutureOr<E> Function(T event) convert) =>
      super.asyncMap(convert)._asFetched(fetch, dispose);

  @override
  Stream<R> cast<R>() => super.cast<R>()._asFetched(fetch, dispose);

  @override
  Stream<T> distinct([bool Function(T previous, T next) equals]) =>
      super.distinct(equals)._asFetched(fetch, dispose);

  @override
  Stream<S> expand<S>(Iterable<S> Function(T element) convert) =>
      super.expand(convert)._asFetched(fetch, dispose);

  @override
  Stream<T> handleError(Function onError,
          {bool Function(dynamic error) test}) =>
      super.handleError(onError, test: test)._asFetched(fetch, dispose);

  @override
  Stream<S> map<S>(S Function(T event) convert) =>
      super.map(convert)._asFetched(fetch, dispose);

  @override
  Stream<T> skip(int count) => super.skip(count)._asFetched(fetch, dispose);

  @override
  Stream<T> skipWhile(bool Function(T element) test) =>
      super.skipWhile(test)._asFetched(fetch, dispose);

  @override
  Stream<T> take(int count) => super.take(count)._asFetched(fetch, dispose);

  @override
  Stream<T> takeWhile(bool Function(T element) test) =>
      super.takeWhile(test)._asFetched(fetch, dispose);

  @override
  Stream<T> timeout(Duration timeLimit,
          {void Function(EventSink<T> sink) onTimeout}) =>
      super.timeout(timeLimit)._asFetched(fetch, dispose);

  @override
  Stream<S> transform<S>(StreamTransformer<T, S> streamTransformer) =>
      super.transform(streamTransformer)._asFetched(fetch, dispose);

  @override
  Stream<T> where(bool Function(T event) test) =>
      super.where(test)._asFetched(fetch, dispose);
}

extension AsFetched<T> on Stream<T> {
  _ConvertedFetchStream<T> _asFetched(
          Future<void> Function() rawFetcher, VoidCallback disposer) =>
      _ConvertedFetchStream(this, rawFetcher, disposer);
}

class _ConvertedFetchStream<T> implements FetchStream<T> {
  _ConvertedFetchStream(this._parent, this._rawFetcher, this._disposer);

  Stream<T> _parent;
  Future<void> Function() _rawFetcher;
  VoidCallback _disposer;

  @override
  Future<void> fetch() => _rawFetcher();

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
      _parent.asBroadcastStream()._asFetched(_rawFetcher, _disposer);

  @override
  Stream<E> asyncExpand<E>(Stream<E> Function(T event) convert) =>
      _parent.asyncExpand(convert)._asFetched(_rawFetcher, _disposer);

  @override
  Stream<E> asyncMap<E>(FutureOr<E> Function(T event) convert) =>
      _parent.asyncMap(convert)._asFetched(_rawFetcher, _disposer);

  @override
  Stream<R> cast<R>() => _parent.cast<R>()._asFetched(_rawFetcher, _disposer);

  @override
  Future<bool> contains(Object needle) => _parent.contains(needle);

  @override
  Stream<T> distinct([bool Function(T previous, T next) equals]) =>
      _parent.distinct(equals)._asFetched(_rawFetcher, _disposer);

  @override
  Future<E> drain<E>([E futureValue]) => _parent.drain<E>(futureValue);

  @override
  Future<T> elementAt(int index) => _parent.elementAt(index);

  @override
  Future<bool> every(bool Function(T element) test) => _parent.every(test);

  @override
  Stream<S> expand<S>(Iterable<S> Function(T element) convert) =>
      _parent.expand(convert)._asFetched(_rawFetcher, _disposer);

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
          ._asFetched(_rawFetcher, _disposer);

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
      _parent.map(convert)._asFetched(_rawFetcher, _disposer);

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
      _parent.skip(count)._asFetched(_rawFetcher, _disposer);

  @override
  Stream<T> skipWhile(bool Function(T element) test) =>
      _parent.skipWhile(test)._asFetched(_rawFetcher, _disposer);

  @override
  Stream<T> take(int count) =>
      _parent.take(count)._asFetched(_rawFetcher, _disposer);

  @override
  Stream<T> takeWhile(bool Function(T element) test) =>
      _parent.takeWhile(test)._asFetched(_rawFetcher, _disposer);

  @override
  Stream<T> timeout(Duration timeLimit,
          {void Function(EventSink<T> sink) onTimeout}) =>
      _parent.timeout(timeLimit)._asFetched(_rawFetcher, _disposer);

  @override
  Future<List<T>> toList() => _parent.toList();

  @override
  Future<Set<T>> toSet() => _parent.toSet();

  @override
  Stream<S> transform<S>(StreamTransformer<T, S> streamTransformer) =>
      _parent.transform(streamTransformer)._asFetched(_rawFetcher, _disposer);

  @override
  Stream<T> where(bool Function(T event) test) =>
      _parent.where(test)._asFetched(_rawFetcher, _disposer);
}
