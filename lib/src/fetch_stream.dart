import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_cached/src/stream_and_data.dart';
import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';

part 'cached_fetch_stream.dart';

typedef Fetcher<T> = FutureOr<T> Function();

/// A broadcast [Stream] that takes a [Function] as an argument that gets
/// executed when whenever [fetch] gets called. The result is broadcasted to
/// the listeners.
/// The [fetch] function is never executed multiple times simultaneously.
extension FetchStream<T> on StreamAndData<T, FetchStreamData<dynamic>> {
  static StreamAndData<T, FetchStreamData<dynamic>> create<T>(
      Fetcher<T> fetcher) {
    final data = FetchStreamData<T>(fetcher);
    return StreamAndData(data._controller.stream, data);
  }

  Future<void> fetch() => data.fetch();
  void dispose() => data.dispose();

  StreamAndData<T, CachedFetchStreamData<dynamic>> cached({
    @required SaveToCache<T> save,
    @required LoadFromCache<T> load,
  }) =>
      CachedFetchStream._create(this, save, load);
}

class FetchStreamData<T> {
  FetchStreamData(this._fetcher);

  final _controller = BehaviorSubject<T>();
  final Fetcher<T> _fetcher;
  bool _isFetching = false;

  void dispose() => _controller.close();

  Future<void> fetch() async {
    if (_isFetching) return;

    _isFetching = true;

    T result;
    try {
      result = await _fetcher();

      if (!_controller.isClosed) {
        _controller.add(result);
      }
    } catch (e, st) {
      if (!_controller.isClosed) {
        _controller.addError(e, st);
      }
    }

    _isFetching = false;
  }
}
