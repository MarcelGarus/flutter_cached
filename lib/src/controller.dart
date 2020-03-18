import 'dart:async';

import 'package:meta/meta.dart';

import 'batcher.dart';
import 'update.dart';

part 'paginated.dart';
part 'simple.dart';
part 'streamed.dart';

abstract class CacheController<T> {
  CacheController();

  final _controller = UpdatesController<T>();

  CacheUpdate<T> get lastUpdate => _controller.lastUpdate;
  bool get isFetching => lastUpdate?.isFetching ?? false;
  T get lastData => lastUpdate?.data;
  dynamic get lastError => lastUpdate?.error;
  StackTrace get lastStackTrace => lastUpdate?.stackTrace;

  /// A stream of [CacheUpdate]s of this controller. A new update appears
  /// everytime something new happens that's also relevant for the listener
  /// (like, new data is available or an error occurred during fetching).
  Stream<CacheUpdate<T>> get updates {
    if (lastUpdate == null) {
      fetch();
    }
    return _controller.updates;
  }

  /// Fetches data from the cache and the [fetcher] simultaneously. If you want
  /// to receive updates about events in between (like events from the cache),
  /// you should listen to the [updates] stream.
  Future<void> fetch();

  // Specializations for certain kinds of [CacheControllers].

  factory CacheController.fromStreamOfControllers(
      Stream<CacheController<T>> stream) {
    return CacheControllerFromStreamOfControllers(controllerStream: stream);
  }

  factory CacheController.fromStreamOfUpdates({
    @required Future<void> Function() fetch,
    @required Stream<CacheUpdate<T>> stream,
  }) {
    return CacheControllerFromStream(fetcher: fetch, stream: stream);
  }

  static CacheController<List<T>> combiningControllers<T>(
      List<CacheController<T>> controllers) {
    return CombiningCacheController(controllers: controllers);
  }

  MappedCacheController<T, S> map<S>(S Function(T value) convert) {
    return MappedCacheController<T, S>(controller: this, convert: convert);
  }
}

/// Create a [CacheController] based on a [Stream] of [CacheController]s.
class CacheControllerFromStreamOfControllers<T> extends CacheController<T> {
  CacheControllerFromStreamOfControllers({@required this.controllerStream})
      : assert(controllerStream != null) {
    controllerStream.listen((controller) {
      controller.updates.listen((update) {
        if (_currentController == controller) {
          _controller.add(update);
        }
      });
    });
  }

  final Stream<CacheController<T>> controllerStream;
  CacheController<T> _currentController;

  @override
  Future<void> fetch() async => await _currentController?.fetch();
}

/// Create a [CacheController] based on a [Stream] of [CacheUpdate]s.
class CacheControllerFromStream<T> extends CacheController<T> {
  CacheControllerFromStream({@required this.stream, @required this.fetcher}) {
    stream.listen(_controller.add);
  }

  final Stream<CacheUpdate<T>> stream;
  final Future<void> Function() fetcher;

  @override
  Future<void> fetch() => fetcher();
}

/// A [CacheController] based on a [List] of [CacheController]s.
class CombiningCacheController<T> extends CacheController<List<T>> {
  CombiningCacheController({@required this.controllers})
      : assert(controllers != null) {
    _updates = <CacheUpdate<T>>[
      for (final _ in controllers) CacheUpdate.inital(),
    ];

    controllers.asMap().forEach((index, controller) {
      controller.updates.listen((update) {
        _updates[index] = update;
        _controller.add(_createUpdate());
      });
    });
  }

  CacheUpdate<List<T>> _createUpdate() {
    final erroneousUpdate = _updates.firstWhere(
      (update) => update.hasError,
      orElse: () => null,
    );
    if (erroneousUpdate != null) {
      return CacheUpdate.error(
        erroneousUpdate.error,
        erroneousUpdate.stackTrace,
      );
    }

    assert(_updates.every((update) => update.hasNoError));

    final someAreStillFetching = _updates.any((update) => update.isFetching);
    final someHaveData = _updates.any((update) => update.hasData);
    if (someAreStillFetching && someHaveData) {
      return CacheUpdate.loading();
    }

    return CacheUpdate.cached(_updates.map((update) => update.data).toList());
  }

  final List<CacheController<T>> controllers;
  List<CacheUpdate<T>> _updates;

  @override
  Future<void> fetch() async {
    await Future.wait([
      for (final controller in controllers) controller.fetch(),
    ]);
  }
}

/// A [CacheController] that maps [A] to [B].
class MappedCacheController<A, B> extends CacheController<B> {
  MappedCacheController({@required this.controller, @required this.convert})
      : assert(controller != null),
        assert(convert != null);

  final CacheController<A> controller;
  final B Function(A value) convert;

  Stream<CacheUpdate<B>> get updates => controller.updates.map((update) {
        return CacheUpdate.raw(
          data: update.data == null ? null : convert(update.data),
          error: update.error,
          stackTrace: update.stackTrace,
          isFetching: update.isFetching,
        );
      });

  Future<void> fetch() => controller.fetch();
}
