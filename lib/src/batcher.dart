import 'dart:async';

class Batcher<T> {
  FutureOr<T> _currentFetcher;

  Future<T> run(FutureOr<T> Function() callback) async {
    _currentFetcher ??= callback();
    return await _currentFetcher;
  }
}
