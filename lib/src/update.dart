import 'dart:async';

import 'package:meta/meta.dart';

/// The [CacheController] creates [CacheUpdate]s to inform other classes about
/// its state of fetching data.
@immutable
class CacheUpdate<T> {
  CacheUpdate.raw({
    @required this.isFetching,
    this.data,
    this.error,
    this.stackTrace,
  }) : assert(isFetching != null);

  CacheUpdate.inital() : this.raw(isFetching: false);

  CacheUpdate.loading() : this.raw(isFetching: true);

  CacheUpdate.cached(T cachedData)
      : this.raw(isFetching: true, data: cachedData);

  CacheUpdate.success(T data) : this.raw(isFetching: false, data: data);

  CacheUpdate.error(dynamic error, StackTrace stackTrace, {T cachedData})
      : this.raw(
          isFetching: false,
          data: cachedData,
          error: error,
          stackTrace: stackTrace,
        );

  /// Whether the fetching of the original data source is still in progress.
  final bool isFetching;
  bool get isNotFetching => !isFetching;

  /// The value that the source returned.
  final T data;
  bool get hasData => data != null;
  bool get hasNoData => !hasData;

  /// An error that the source threw and its stack trace.
  final dynamic error;
  final StackTrace stackTrace;
  bool get hasError => error != null;
  bool get hasNoError => !hasError;
}

/// Similar to a [StreamController], but it provides you with the last update
/// immediately after listening to it, you can listen to it multiple times and
/// you don't need to dispose it.
class UpdatesController<T> {
  final Set<StreamController<CacheUpdate<T>>> _controllers = {};
  CacheUpdate<T> _lastUpdate;
  CacheUpdate<T> get lastUpdate => _lastUpdate;

  /// A stream of [CacheUpdate]s of this controller.
  Stream<CacheUpdate<T>> get updates {
    StreamController<CacheUpdate<T>> controller;
    controller = StreamController<CacheUpdate<T>>(
      onCancel: () {
        controller.close();
        _controllers.remove(controller);
      },
    )..add(lastUpdate);
    _controllers.add(controller);

    return controller.stream;
  }

  /// Notifies everyone listening to this controller's [updates] that a new
  /// update is available.
  void add(CacheUpdate<T> update) {
    _lastUpdate = update;
    for (final controller in _controllers) {
      controller.add(update);
    }
  }
}
