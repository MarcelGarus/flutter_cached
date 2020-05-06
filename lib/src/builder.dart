import 'package:flutter/widgets.dart';
import 'package:rxdart/rxdart.dart';

import 'fetch_stream.dart';
import 'stream_and_data.dart';

typedef FetchCallback = Future<void> Function({bool force});

typedef RawBuilder<T> = Widget Function(
  BuildContext,
  StreamAndData<T, CachedFetchStreamData<dynamic>>,
);
typedef FetchableBuilder<T> = Widget Function(
  BuildContext,
  T,
  FetchCallback fetch,
);

class ScopedBuilder<T> extends StatefulWidget {
  const ScopedBuilder({
    Key key,
    @required this.create,
    @required this.destroy,
    @required this.builder,
  })  : assert(create != null),
        assert(destroy != null),
        assert(builder != null),
        super(key: key);

  final T Function() create;
  final void Function(T) destroy;
  final Widget Function(BuildContext, T) builder;

  @override
  State<StatefulWidget> createState() => _ScopedBuilderState<T>();
}

class _ScopedBuilderState<T> extends State<ScopedBuilder<T>> {
  T object;

  @override
  void initState() {
    super.initState();
    object = widget.create();
  }

  @override
  void dispose() {
    widget.destroy(object);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, object);
}

class CacheSnapshot<T> {
  CacheSnapshot({this.data, this.hasData, this.error, this.stackTrace})
      : assert(stackTrace == null || error != null);

  final T data;
  final bool hasData;
  bool get hasNoData => !hasData;

  final dynamic error;
  final StackTrace stackTrace;
  bool get hasError => error != null;
  bool get hasNoError => !hasError;
}

/// Wrapper around a value of type [T] which may be null.
class Existing<T> {
  Existing(this.value);
  final T value;
}

class CachedBuilder<T> extends StatelessWidget {
  const CachedBuilder({
    Key key,
    @required this.stream,
    @required this.builder,
  }) : super(key: key);

  final StreamAndData<T, CachedFetchStreamData<dynamic>> stream;
  final FetchableBuilder<CacheSnapshot<T>> builder;

  @override
  Widget build(BuildContext context) {
    Existing<T> latestValue;

    return StreamBuilder<Existing<T>>(
      // What you're looking at here is lots of frustration with Flutter's
      // `StreamBuilder`: It doesn't support `StackTrace`s although Dart's
      // `Stream`s do. And it makes no distinction between no data and `null`
      // as data, although Dart's `Stream`s can contain null. I opened issues
      // for both of these, so we can do nothing but wait.
      // - https://github.com/flutter/flutter/issues/53384
      // - https://github.com/flutter/flutter/issues/53682
      stream: stream.handleError((error, stackTrace) {
        throw ErrorAndStacktrace(error, stackTrace);
      }).map((data) {
        latestValue = Existing(data);
        return latestValue;
      }),
      builder: (context, snapshot) {
        final errorAndStackTrace = snapshot.error as ErrorAndStacktrace;

        return builder(
          context,
          CacheSnapshot(
            data: latestValue?.value,
            hasData: latestValue != null,
            error: errorAndStackTrace?.error,
            stackTrace: errorAndStackTrace?.stackTrace,
          ),
          stream.fetch,
        );
      },
    );
  }
}
