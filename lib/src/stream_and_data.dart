import 'dart:async';

abstract class Data<D> {
  D get data;
}

class StreamAndData<T, D> implements Stream<T>, Data<D> {
  StreamAndData(this.stream, this.data);

  final Stream<T> stream;
  final D data;

  @override
  Future<bool> any(bool Function(T element) test) => stream.any(test);

  @override
  StreamAndData<T, D> asBroadcastStream({
    void Function(StreamSubscription<T> subscription) onListen,
    void Function(StreamSubscription<T> subscription) onCancel,
  }) =>
      StreamAndData(stream.asBroadcastStream(), data);

  @override
  StreamAndData<E, D> asyncExpand<E>(Stream<E> Function(T event) convert) =>
      StreamAndData(stream.asyncExpand(convert), data);

  @override
  StreamAndData<E, D> asyncMap<E>(FutureOr<E> Function(T event) convert) =>
      StreamAndData(stream.asyncMap(convert), data);

  @override
  StreamAndData<R, D> cast<R>() => StreamAndData(stream.cast<R>(), data);

  @override
  Future<bool> contains(Object needle) => stream.contains(needle);

  @override
  StreamAndData<T, D> distinct([bool Function(T previous, T next) equals]) =>
      StreamAndData(stream.distinct(equals), data);

  @override
  Future<E> drain<E>([E futureValue]) => stream.drain(futureValue);

  @override
  Future<T> elementAt(int index) => stream.elementAt(index);

  @override
  Future<bool> every(bool Function(T element) test) => stream.every(test);

  @override
  StreamAndData<S, D> expand<S>(Iterable<S> Function(T element) convert) =>
      StreamAndData(stream.expand(convert), data);

  @override
  Future<T> get first => stream.first;

  @override
  Future<T> firstWhere(bool Function(T element) test, {T Function() orElse}) =>
      stream.firstWhere(test, orElse: orElse);

  @override
  Future<S> fold<S>(
          S initialValue, S Function(S previous, T element) combine) =>
      stream.fold(initialValue, combine);

  @override
  Future forEach(void Function(T element) action) => stream.forEach(action);

  @override
  StreamAndData<T, D> handleError(Function onError,
          {bool Function(dynamic error) test}) =>
      StreamAndData(stream.handleError(onError, test: test), data);

  @override
  bool get isBroadcast => stream.isBroadcast;

  @override
  Future<bool> get isEmpty => stream.isEmpty;

  @override
  Future<String> join([String separator = ""]) => stream.join(separator);

  @override
  Future<T> get last => stream.last;

  @override
  Future<T> lastWhere(bool Function(T element) test, {T Function() orElse}) =>
      stream.lastWhere(test, orElse: orElse);

  @override
  Future<int> get length => stream.length;

  @override
  StreamSubscription<T> listen(
    void Function(T event) onData, {
    Function onError,
    void Function() onDone,
    bool cancelOnError,
  }) =>
      stream.listen(
        onData,
        onError: onError,
        onDone: onDone,
        cancelOnError: cancelOnError,
      );

  @override
  StreamAndData<S, D> map<S>(S Function(T event) convert) =>
      StreamAndData(stream.map(convert), data);

  @override
  Future pipe(StreamConsumer<T> streamConsumer) => stream.pipe(streamConsumer);

  @override
  Future<T> reduce(T Function(T previous, T element) combine) =>
      stream.reduce(combine);

  @override
  Future<T> get single => stream.single;

  @override
  Future<T> singleWhere(bool Function(T element) test, {T Function() orElse}) =>
      stream.singleWhere(test, orElse: orElse);

  @override
  StreamAndData<T, D> skip(int count) =>
      StreamAndData(stream.skip(count), data);

  @override
  StreamAndData<T, D> skipWhile(bool Function(T element) test) =>
      StreamAndData(stream.skipWhile(test), data);

  @override
  StreamAndData<T, D> take(int count) =>
      StreamAndData(stream.take(count), data);

  @override
  StreamAndData<T, D> takeWhile(bool Function(T element) test) =>
      StreamAndData(stream.takeWhile(test), data);

  @override
  StreamAndData<T, D> timeout(
    Duration timeLimit, {
    void Function(EventSink<T> sink) onTimeout,
  }) =>
      StreamAndData(stream.timeout(timeLimit, onTimeout: onTimeout), data);

  @override
  Future<List<T>> toList() => stream.toList();

  @override
  Future<Set<T>> toSet() => stream.toSet();

  @override
  StreamAndData<S, D> transform<S>(StreamTransformer<T, S> streamTransformer) =>
      StreamAndData(stream.transform(streamTransformer), data);

  @override
  StreamAndData<T, D> where(bool Function(T event) test) =>
      StreamAndData(stream.where(test), data);
}
