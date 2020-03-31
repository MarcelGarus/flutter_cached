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
  CacheSnapshot({this.data, this.error, this.stackTrace})
      : assert(stackTrace == null || error != null);

  final T data;
  final dynamic error;
  final StackTrace stackTrace;
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
    return StreamBuilder<T>(
      stream: stream.handleError(
        (error, stackTrace) => throw ErrorAndStacktrace(error, stackTrace),
      ),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return builder(
            context,
            CacheSnapshot(data: snapshot.data),
            stream.fetch,
          );
        } else if (snapshot.hasError) {
          final errorAndStackTrace = snapshot.error as ErrorAndStacktrace;
          return builder(
            context,
            CacheSnapshot(
              data: stream.latestValue,
              error: errorAndStackTrace.error,
              stackTrace: errorAndStackTrace.stackTrace,
            ),
            stream.fetch,
          );
        } else {
          return builder(
            context,
            CacheSnapshot(data: stream.latestValue),
            stream.fetch,
          );
        }
      },
    );
  }
}
