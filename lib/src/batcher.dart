import 'dart:async';

/// A class that has a [run] method offering to run a callback. If another
/// callback is already running, its result is returned instead.
class Batcher<T> {
  FutureOr<T> _currentFetcher;

  Future<T> run(FutureOr<T> Function() callback) async {
    _currentFetcher ??= callback();
    final result = await _currentFetcher;
    _currentFetcher = null;
    return result;
  }
}
