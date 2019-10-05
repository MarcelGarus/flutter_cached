import 'package:flutter/material.dart';

import 'controller.dart';

Widget _defaultLoadingScreenBuilder(BuildContext _) {
  return Center(child: CircularProgressIndicator());
}

const _defaultFadeDuration = Duration(milliseconds: 200);

List<Widget> _defaultHeaderSliversBuilder(
    BuildContext _, bool __, CacheUpdate ___) {
  return [];
}

List<Widget> _defaultHeaderSliversBuilderWithOnlyContext(BuildContext _) => [];

/// Takes a [CacheController] and a [builder] and asks the builder to rebuild
/// every time a new [CacheUpdate] is emitted from the [CacheController].
class CachedRawBuilder<Item> extends StatelessWidget {
  /// The [CacheController] to be used as a data provider.
  final CacheController<Item> controller;

  /// A function that receives raw [CacheUpdate]s and returns a widget to
  /// build. [update] is guaranteed to be non-null.
  final Widget Function(BuildContext context, CacheUpdate<Item> update) builder;

  CachedRawBuilder({
    Key key,
    @required this.controller,
    @required this.builder,
  })  : assert(controller != null),
        assert(builder != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<CacheUpdate<Item>>(
      stream: controller.updates,
      initialData: CacheUpdate(isFetching: false),
      builder: (context, snapshot) {
        assert(snapshot.hasData);
        final update = snapshot.data;

        final widget = builder(context, update);
        assert(widget != null, 'The builder should never return null.');

        return widget;
      },
    );
  }
}

/// Displays a list with pull-to-refresh feature. Fires the [CacheController]'s
/// fetch function when building for the first time and when the user pulls to
/// refresh. Displays [headerSliversBuilder]'s slivers above the refresh
/// indicator and [bodySliversBuilder] below it. Calls to these builders are
/// guaranteed provide updates with data or an error or both. Otherwise, the
/// [loadingScreenBuilder] is called instead.
class CachedRawCustomScrollView<Item> extends StatefulWidget {
  /// The [CacheController] to be used as a data provider.
  final CacheController<Item> controller;

  /// A builder for the loading screen.
  final WidgetBuilder loadingScreenBuilder;

  /// A builder for slivers to be displayed below the [RefreshIndicator].
  /// [update] is guaranteed to have data or an error or both.
  final List<Widget> Function(BuildContext context, CacheUpdate<Item> update)
      bodySliversBuilder;

  /// A builder for slivers to be displayed above the [RefreshIndicator].
  /// /// [update] is guaranteed to have data or an error or both.
  final List<Widget> Function(
          BuildContext context, bool innerBoxScrolled, CacheUpdate<Item> update)
      headerSliversBuilder;

  /// The duration used to fade between the [loadingScreenBuilder] and the
  /// [builder].
  final Duration duration;

  const CachedRawCustomScrollView({
    Key key,
    @required this.controller,
    @required this.bodySliversBuilder,
    this.headerSliversBuilder = _defaultHeaderSliversBuilder,
    this.loadingScreenBuilder = _defaultLoadingScreenBuilder,
    this.duration = _defaultFadeDuration,
  })  : assert(controller != null),
        assert(loadingScreenBuilder != null),
        assert(headerSliversBuilder != null),
        assert(bodySliversBuilder != null),
        assert(duration != null),
        super(key: key);

  @override
  _CachedRawCustomScrollViewState<Item> createState() =>
      _CachedRawCustomScrollViewState<Item>();
}

class _CachedRawCustomScrollViewState<Item>
    extends State<CachedRawCustomScrollView<Item>> {
  final _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  CacheController<Item> _controller;

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
    return CachedRawBuilder(
      controller: widget.controller,
      builder: (context, update) {
        final showLoadingScreen = !update.hasData && !update.hasError;

        return AnimatedCrossFade(
          duration: widget.duration,
          crossFadeState: showLoadingScreen
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          firstChild: Center(child: CircularProgressIndicator()),
          secondChild:
              showLoadingScreen ? Container() : _buildContent(context, update),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, CacheUpdate update) {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxScrolled) {
        var slivers =
            widget.headerSliversBuilder(context, innerBoxScrolled, update);
        assert(
            slivers != null,
            "The headerSliversBuilder should never return null. If you don't "
            "want to display anything above the refresh indicator, consider "
            "returning an empty list instead.");
        return slivers;
      },
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _controller.fetch,
        child: CustomScrollView(
          slivers: () {
            var slivers = widget.bodySliversBuilder(context, update);
            assert(
                slivers != null,
                "The bodySliversBuilder should never return null. If you don't "
                "want to display anything below the refresh indicator, "
                "consider returning an empty list instead.");
            return slivers;
          }(),
        ),
      ),
    );
  }
}

/// Abstracts from [CacheUpdate]s by taking builders for various special cases
/// like displaying a loading screen, error banner, error screen and empty
/// state, so that the actual [itemSliversBuilder] can be simplified to just
/// take a list of items.
class CachedCustomScrollView<Item> extends StatelessWidget {
  /// The corresponding [CacheController] that's used as a data provider.
  final CacheController<Item> controller;

  /// A builder for an error banner to be shown at the top of the list.
  final Widget Function(BuildContext context, dynamic error) errorBannerBuilder;

  /// A builder for a full screen error message instead of the list.
  final Widget Function(BuildContext context, dynamic error) errorScreenBuilder;

  /// A builder for what to display when there are no items.
  final WidgetBuilder emptyStateBuilder;

  /// A builder for item slivers to be displayed in the list.
  final List<Widget> Function(BuildContext context, List<Item> items)
      itemSliversBuilder;

  /// A builder for slivers to be displayed at the top above the refresh
  /// indicator.
  final List<Widget> Function(BuildContext context) headerSliversBuilder;

  /// A builder for the loading screen.
  final WidgetBuilder loadingScreenBuilder;

  /// Whether to show the error banner above the refresh indicator or below.
  final bool showErrorBannerAboveRefreshIndicator;

  /// The duration used to fade between the [loadingScreenBuilder] and the
  /// actual content.
  final Duration duration;

  const CachedCustomScrollView({
    Key key,
    @required this.controller,
    @required this.errorBannerBuilder,
    @required this.errorScreenBuilder,
    @required this.emptyStateBuilder,
    @required this.itemSliversBuilder,
    this.headerSliversBuilder = _defaultHeaderSliversBuilderWithOnlyContext,
    this.loadingScreenBuilder = _defaultLoadingScreenBuilder,
    this.showErrorBannerAboveRefreshIndicator = true,
    this.duration = _defaultFadeDuration,
  })  : assert(controller != null),
        assert(errorBannerBuilder != null),
        assert(errorScreenBuilder != null),
        assert(emptyStateBuilder != null),
        assert(itemSliversBuilder != null),
        assert(headerSliversBuilder != null),
        assert(loadingScreenBuilder != null),
        assert(showErrorBannerAboveRefreshIndicator != null),
        assert(duration != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return CachedRawCustomScrollView(
      controller: controller,
      loadingScreenBuilder: loadingScreenBuilder,
      headerSliversBuilder: (context, innerBoxScrolled, update) => [
        if (headerSliversBuilder != null) ...headerSliversBuilder(context),
        if (update.hasData &&
            update.hasError &&
            showErrorBannerAboveRefreshIndicator)
          SliverList(
            delegate: SliverChildListDelegate([
              errorBannerBuilder(context, update.error),
            ]),
          ),
      ],
      bodySliversBuilder: (context, update) {
        assert(update.hasData || update.hasError);

        // If there's no error, we are guaranteed to have data - either we are
        // finished or we're still fetching but can display cached data.
        if (!update.hasError) {
          assert(update.hasData);
          return _buildItemSlivers(context, update.data);
        }

        assert(update.hasError);

        // If we have cached data, display the error as a banner above
        // the actual items. Otherwise, display a fullscreen error.
        if (update.hasData) {
          return [
            if (!showErrorBannerAboveRefreshIndicator)
              SliverList(
                delegate: SliverChildListDelegate([
                  errorBannerBuilder(context, update.error),
                ]),
              ),
            ..._buildItemSlivers(context, update.data),
          ];
        } else {
          return [
            SliverFillViewport(
              delegate: SliverChildListDelegate([
                errorScreenBuilder(context, update.error),
              ]),
            ),
          ];
        }
      },
    );
  }

  List<Widget> _buildItemSlivers(BuildContext context, List<Item> items) {
    if (items.isEmpty && emptyStateBuilder != null) {
      return [SliverFillRemaining(child: emptyStateBuilder(context))];
    } else {
      return itemSliversBuilder(context, items);
    }
  }
}

/// Abstracts from slivers by taking an [itemBuilder] for deterministically
/// building a single item independent of other items or the index.
class CachedListView<Item> extends StatelessWidget {
  /// The corresponding [CacheController] that's used as a data provider.
  final CacheController<Item> controller;

  /// A builder for an error banner to be shown at the top of the list.
  final Widget Function(BuildContext context, dynamic error) errorBannerBuilder;

  /// A builder for a full screen error message instead of the list.
  final Widget Function(BuildContext context, dynamic error) errorScreenBuilder;

  /// A builder for what to display when there are no items.
  final WidgetBuilder emptyStateBuilder;

  /// A builder for an item to be displayed in the list.
  final Widget Function(BuildContext context, Item) itemBuilder;

  /// A builder for the loading screen.
  final WidgetBuilder loadingScreenBuilder;

  /// Whether to show the error banner above the refresh indicator or below.
  final bool showErrorBannerAboveRefreshIndicator;

  /// The duration used to fade between the [loadingScreenBuilder] and the
  /// actual content.
  final Duration duration;

  const CachedListView({
    Key key,
    @required this.controller,
    @required this.errorBannerBuilder,
    @required this.errorScreenBuilder,
    @required this.emptyStateBuilder,
    @required this.itemBuilder,
    this.loadingScreenBuilder = _defaultLoadingScreenBuilder,
    this.showErrorBannerAboveRefreshIndicator = true,
    this.duration = _defaultFadeDuration,
  })  : assert(controller != null),
        assert(errorBannerBuilder != null),
        assert(errorScreenBuilder != null),
        assert(emptyStateBuilder != null),
        assert(itemBuilder != null),
        assert(loadingScreenBuilder != null),
        assert(showErrorBannerAboveRefreshIndicator != null),
        assert(duration != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return CachedCustomScrollView(
      controller: controller,
      errorBannerBuilder: errorBannerBuilder,
      errorScreenBuilder: errorScreenBuilder,
      emptyStateBuilder: emptyStateBuilder,
      loadingScreenBuilder: loadingScreenBuilder,
      showErrorBannerAboveRefreshIndicator:
          showErrorBannerAboveRefreshIndicator,
      duration: duration,
      itemSliversBuilder: (context, items) => [
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, i) => itemBuilder(context, items[i]),
            childCount: items.length,
          ),
        ),
      ],
    );
  }
}
