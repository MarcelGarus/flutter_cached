import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import 'controller.dart';

const _defaultFadeDuration = Duration(milliseconds: 200);

Widget _defaultLoadingScreenBuilder(BuildContext _) =>
    Center(child: CircularProgressIndicator());

/// Takes a [CacheController] and a [builder] and asks the builder to rebuild
/// every time a new [CacheUpdate] is emitted from the [CacheController].
/// Calls [CacheController.fetch] when building for the first time.
class CachedRawBuilder<T> extends StatefulWidget {
  /// The [CacheController] to be used as a data provider.
  final CacheController<T> controller;

  /// A function that receives raw [CacheUpdate]s and returns a widget to
  /// build. [update] is guaranteed to be non-null.
  final Widget Function(BuildContext context, CacheUpdate<T> update) builder;

  CachedRawBuilder({
    Key key,
    @required this.controller,
    @required this.builder,
  })  : assert(controller != null),
        assert(builder != null),
        super(key: key);

  @override
  _CachedRawBuilderState<T> createState() => _CachedRawBuilderState<T>();
}

class _CachedRawBuilderState<T> extends State<CachedRawBuilder<T>> {
  CacheController<T> _controller;

  @override
  void didChangeDependencies() {
    // When this widget is shown for the first time or the manager changed,
    // trigger the [widget.controller]'s fetch function so we get some data.
    if (widget.controller != _controller) {
      _controller = widget.controller..fetch();
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<CacheUpdate<T>>(
      stream: widget.controller.updates,
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

  /// A builder for the loading screen.
  final WidgetBuilder loadingScreenBuilder;

  /// A builder for an error banner to be shown at the top of the list.
  final Widget Function(BuildContext context, dynamic error) errorBannerBuilder;

  /// A builder for a full screen error message instead of the list.
  final Widget Function(BuildContext context, dynamic error) errorScreenBuilder;

  /// A builder for the widget to be displayed.
  final Widget Function(BuildContext context, T data) builder;
  final bool hasScrollBody;

  /// The duration used to fade between the [loadingScreenBuilder] and the
  /// [builder].
  final Duration duration;

  const CachedBuilder({
    Key key,
    @required this.controller,
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
          widget.errorBannerBuilder(context, update.error),
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
                    child: widget.errorScreenBuilder(context, update.error),
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

              /*assert(
                      content != null,
                      "The builder should never return null. If you don't want "
                      "to display anything, consider returning a Container() "
                      "instead.");*/
            }(),
          ),
        ),
      ],
    );
  }
}
