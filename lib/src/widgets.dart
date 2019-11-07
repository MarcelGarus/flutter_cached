import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import 'controller.dart';

const _defaultFadeDuration = Duration(milliseconds: 200);

Widget _defaultLoadingScreenBuilder(BuildContext _) =>
    Center(child: CircularProgressIndicator());

typedef ErrorBuilder = Widget Function(
    BuildContext context, dynamic error, StackTrace stackTrace);

/// Takes a [CacheController] and a [builder] and asks the builder to rebuild
/// every time a new [CacheUpdate] is emitted from the [CacheController].
/// Calls [CacheController.fetch] when building for the first time.
class CachedRawBuilder<T> extends StatefulWidget {
  final CacheController<T> Function() controllerBuilder;

  /// A function that receives raw [CacheUpdate]s and returns a widget to
  /// build. [update] is guaranteed to be non-null.
  final Widget Function(BuildContext context, CacheUpdate<T> update) builder;

  factory CachedRawBuilder({
    Key key,
    CacheController<T> controller,
    CacheController<T> Function() controllerBuilder,
    Widget Function(BuildContext context, CacheUpdate<T> update) builder,
  }) {
    assert(builder != null);
    assert(
        controller != null || controllerBuilder != null,
        'You should provide a controller or a controller builder to the '
        'CachedRawBuilder.');
    assert(
        controller == null || controllerBuilder == null,
        "You can't provide both a controller and a controller builder to the "
        "CachedRawBuilder.");
    final actualControllerBuilder = controllerBuilder ?? () => controller;
    return CachedRawBuilder._(
      key: key,
      controllerBuilder: actualControllerBuilder,
      builder: builder,
    );
  }

  CachedRawBuilder._({
    Key key,
    @required this.controllerBuilder,
    @required this.builder,
  }) : super(key: key);

  @override
  _CachedRawBuilderState<T> createState() => _CachedRawBuilderState<T>();
}

class _CachedRawBuilderState<T> extends State<CachedRawBuilder<T>> {
  CacheController<T> _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controllerBuilder()..fetch();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<CacheUpdate<T>>(
      stream: _controller.updates,
      initialData: CacheUpdate(isFetching: false),
      builder: (BuildContext context, AsyncSnapshot<CacheUpdate<T>> snapshot) {
        assert(snapshot.hasData);
        final update = snapshot.data;
        final content = widget.builder(context, update);
        assert(content != null, 'The builder should never return null.');

        return content;
      },
    );
  }
}

/// Displays content with pull-to-refresh feature. Fires the
/// [CacheController]'s
/// fetch function when building for the first time and when the user pulls to
/// refresh. Displays [headerSliversBuilder]'s slivers above the refresh
/// indicator and [bodySliversBuilder] below it. Calls to these builders are
/// guaranteed provide updates with data or an error or both. Otherwise, the
/// [loadingScreenBuilder] is called instead.
class CachedBuilder<T> extends StatefulWidget {
  /// The [CacheController] to be used as a data provider.
  final CacheController<T> controller;

  /// A builder for building the [CacheController] to be used as a data
  /// provider.
  final CacheController<T> Function() controllerBuilder;

  /// A builder for the loading screen.
  final WidgetBuilder loadingScreenBuilder;

  /// A builder for an error banner to be shown at the top of the list.
  final ErrorBuilder errorBannerBuilder;

  /// A builder for a full screen error message instead of the list.
  final ErrorBuilder errorScreenBuilder;

  /// A builder for the widget to be displayed.
  final Widget Function(BuildContext context, T data) builder;
  final bool hasScrollBody;

  /// The duration used to fade between the [loadingScreenBuilder] and the
  /// [builder].
  final Duration duration;

  const CachedBuilder({
    Key key,
    this.controller,
    this.controllerBuilder,
    @required this.errorBannerBuilder,
    @required this.errorScreenBuilder,
    @required this.builder,
    this.loadingScreenBuilder = _defaultLoadingScreenBuilder,
    this.hasScrollBody = true,
    this.duration = _defaultFadeDuration,
  })  : assert(controller != null),
        assert(errorBannerBuilder != null),
        assert(errorScreenBuilder != null),
        assert(builder != null),
        assert(loadingScreenBuilder != null),
        assert(hasScrollBody != null),
        assert(duration != null),
        super(key: key);

  @override
  _CachedBuilderState<T> createState() => _CachedBuilderState<T>();
}

class _CachedBuilderState<T> extends State<CachedBuilder<T>> {
  final _refreshController = RefreshController();

  @override
  Widget build(BuildContext context) {
    return CachedRawBuilder(
      controller: widget.controller,
      controllerBuilder: widget.controllerBuilder,
      builder: (context, update) {
        final showLoadingScreen = !update.hasData && !update.hasError;

        return AnimatedCrossFade(
          duration: widget.duration,
          crossFadeState: showLoadingScreen
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          firstChild: _buildLoadingScreen(context, update),
          secondChild:
              showLoadingScreen ? Container() : _buildContent(context, update),
          layoutBuilder:
              (Widget top, Key topKey, Widget bottom, Key bottomKey) {
            return Stack(
              overflow: Overflow.visible,
              children: <Widget>[
                Positioned.fill(key: bottomKey, child: bottom),
                Positioned.fill(key: topKey, child: top),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildLoadingScreen(BuildContext context, CacheUpdate<T> update) {
    return CustomScrollView(
      slivers: <Widget>[
        SliverFillRemaining(child: widget.loadingScreenBuilder(context)),
      ],
    );
  }

  Widget _buildContent(BuildContext context, CacheUpdate<T> update) {
    // It's possible to trigger a refresh without the [RefreshIndicator], for
    // example by calling [controller.fetch] on a button press. Because the
    // refresh indicator should also spin in that case, we need to trigger it
    // manually.
    if (update.isFetching && !_refreshController.isRefresh) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _refreshController.requestRefresh(),
      );
    }

    return Column(
      children: <Widget>[
        if (update.hasData && update.hasError)
          widget.errorBannerBuilder(context, update.error, update.stackTrace),
        Expanded(
          child: SmartRefresher(
            controller: _refreshController,
            onRefresh: () async {
              await widget.controller.fetch();
              _refreshController.refreshCompleted();
            },
            child: () {
              if (!update.hasData) {
                return CustomScrollView(slivers: <Widget>[
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: widget.errorScreenBuilder(
                        context, update.error, update.stackTrace),
                  ),
                ]);
              }

              if (widget.hasScrollBody) {
                return widget.builder(context, update.data);
              } else {
                return CustomScrollView(slivers: <Widget>[
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: widget.builder(context, update.data),
                  ),
                ]);
              }
            }(),
          ),
        ),
      ],
    );
  }
}
