// import 'package:flutter/material.dart';
// import 'package:pull_to_refresh/pull_to_refresh.dart';

// import 'fetch_stream.dart';
// import 'update.dart';

// const _defaultFadeDuration = Duration(milliseconds: 200);

// Widget _defaultLoadingScreenBuilder(BuildContext _) =>
//     Center(child: CircularProgressIndicator());

// typedef ErrorBuilder = Widget Function(
//     BuildContext context, dynamic error, StackTrace stackTrace);

/// Displays content with pull-to-refresh feature. Fires the
/// [CacheController]'s fetch function when building for the first time and
/// when the user pulls to refresh. Displays [headerSliversBuilder]'s slivers
/// above the refresh indicator and [bodySliversBuilder] below it. Calls to
/// these builders are guaranteed to provide updates with data or an error or
/// both. Otherwise, the [loadingScreenBuilder] is called instead.
/*class CachedBuilder<T> extends StatefulWidget {
  /// The [CacheController] to be used as a data provider.
  final CacheController<T> controller;

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

/// A widget that when shown, calls [controller.fetchMore].
class LoadMoreWidget extends StatefulWidget {
  const LoadMoreWidget({
    Key key,
    @required this.controller,
    @required this.child,
  })  : assert(controller != null),
        super(key: key);

  final PaginatedCacheController controller;
  final Widget child;

  @override
  _LoadMoreWidgetState createState() => _LoadMoreWidgetState();
}

class _LoadMoreWidgetState extends State<LoadMoreWidget> {
  @override
  void initState() {
    super.initState();
    widget.controller.fetchMore();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

Widget _buildDefaultLoadMoreContent(BuildContext context) {
  return Center(child: CircularProgressIndicator());
}

class PaginatedListView<T, State extends PaginationState>
    extends StatelessWidget {
  const PaginatedListView({
    Key key,
    @required this.controller,
    @required this.errorBannerBuilder,
    @required this.errorScreenBuilder,
    @required this.loadingScreenBuilder,
    @required this.itemBuilder,
    this.loadMoreBuilder = _buildDefaultLoadMoreContent,
  }) : super(key: key);

  final PaginatedCacheController<T, State> controller;
  final ErrorBuilder errorBannerBuilder;
  final ErrorBuilder errorScreenBuilder;
  final WidgetBuilder loadingScreenBuilder;
  final Widget Function(BuildContext context, T data) itemBuilder;
  final WidgetBuilder loadMoreBuilder;

  @override
  Widget build(BuildContext context) {
    return CachedBuilder<List<T>>(
      controller: controller,
      errorBannerBuilder: errorBannerBuilder,
      errorScreenBuilder: errorScreenBuilder,
      loadingScreenBuilder: loadingScreenBuilder,
      builder: (context, items) {
        return ListView.builder(
          itemBuilder: (context, i) {
            if (i < items.length) {
              return itemBuilder(context, items[i]);
            } else if (i == items.length) {
              return LoadMoreWidget(
                controller: controller,
                child: loadMoreBuilder(context),
              );
            } else {
              return null;
            }
          },
        );
      },
    );
  }
}*/
