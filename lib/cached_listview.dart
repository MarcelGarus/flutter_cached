library cached_listview;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// The [CacheController] creates [CacheUpdate]s to inform other classes about its
/// state of fetching data.
@immutable
class CacheUpdate<Item> {
  /// Whether the fetching of the original data source is still in progress.
  final bool isFetching;

  /// A list of items that the source returned.
  final List<Item> data;
  bool get hasData => data != null;

  /// An error that the source threw.
  final dynamic error;
  bool get hasError => error != null;

  CacheUpdate({this.isFetching, this.data, this.error})
      : assert(isFetching != null),
        assert(!isFetching || error == null);
}

/// A class that manages fetching data using the provided [fetcher] and saves
/// and loads cached data using [saveToCache] and [loadFromCache]. By calling
/// [fetch] on this class, you can start the process of fetching data
/// simultaneously from the cache and the original source. To get updates about
/// this process, you can listen to the [updates] stream.
/// Call [dispose] after you're done using the [CacheController].
class CacheController<Item> {
  final Future<List<Item>> Function() fetcher;
  final Future<void> Function(List<Item> items) saveToCache;
  final Future<List<Item>> Function() loadFromCache;

  final _updates = StreamController<CacheUpdate<Item>>();
  Stream<CacheUpdate> get updates => _updates.stream;
  List<Item> cachedData;

  CacheController({
    @required this.fetcher,
    @required this.saveToCache,
    @required this.loadFromCache,
  })  : assert(fetcher != null),
        assert(saveToCache != null),
        assert(loadFromCache != null);

  /// Disposes the internally used stream controller.
  void dispose() => _updates.close();

  /// Fetches data from the cache and the [fetcher] simultaneously.
  Future<void> fetch() async {
    bool fetchingCompleted = false;

    _updates.add(CacheUpdate(isFetching: true, data: cachedData));

    // Simultaneously get data from the (probably faster) cache and the
    // original source.
    await Future.wait([
      // Get data from the cache.
      Future.microtask(() async {
        try {
          cachedData = await loadFromCache();
          // If the original source was faster than the cache, we don't need
          // to do anything. Otherwise, we push a [CacheUpdate] with the
          // [cachedData] so that it can be displayed to the user while the
          // original source is still loading.
          if (!fetchingCompleted) {
            _updates.add(CacheUpdate(
              isFetching: true,
              data: cachedData,
            ));
          }
        } catch (error) {
          // The [loadFromCache] function throwing means that the cache
          // doesn't contain any cached data yet. In that case, we just fail
          // silently as the original data will be returned soon.
        }
      }),
      // Get data from the original source.
      Future.microtask(() async {
        try {
          List<Item> data = await fetcher();
          _updates.add(CacheUpdate(isFetching: false, data: data));
          //unawaited(saveToCache(data));
          saveToCache(data);
        } catch (error) {
          _updates.add(CacheUpdate(
            isFetching: false,
            error: error,
            data: cachedData,
          ));
        }
      }),
    ]);
  }
}

class CachedCustomScrollView<Item> extends StatefulWidget {
  /// The corresponding [CacheController] that's used as a data provider.
  final CacheController<Item> controller;

  /// A function that receives raw [CacheUpdate]s and returns the slivers to
  /// build.
  final List<Widget> Function(BuildContext context, CacheUpdate<Item> update)
      sliverBuilder;

  CachedCustomScrollView({
    @required this.controller,
    @required this.sliverBuilder,
  })  : assert(controller != null),
        assert(sliverBuilder != null);

  @override
  _CachedCustomScrollView<Item> createState() =>
      _CachedCustomScrollView<Item>();
}

class _CachedCustomScrollView<Item>
    extends State<CachedCustomScrollView<Item>> {
  final _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  CacheController<Item> _controller;

  @override
  void didChangeDependencies() {
    // When this widget is shown for the first time or the manager changed,
    // trigger the [CacheManager]'s [fetch] function so we get some data.
    if (widget.controller != _controller) {
      _controller = widget.controller;
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => _refreshIndicatorKey.currentState.show());
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      key: _refreshIndicatorKey,
      onRefresh: _controller.fetch,
      child: StreamBuilder(
        stream: _controller.updates,
        builder: (context, snapshot) {
          var update = snapshot.data;
          var displayFullScreenLoader =
              update == null || !update.hasData && !update.hasError;

          return AnimatedCrossFade(
            duration: Duration(milliseconds: 200),
            crossFadeState: displayFullScreenLoader
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Center(child: CircularProgressIndicator()),
            secondChild: displayFullScreenLoader
                ? Container()
                : CustomScrollView(
                    slivers: widget.sliverBuilder(context, update),
                  ),
          );
        },
      ),
    );
  }
}

class CachedListView<Item> extends StatelessWidget {
  /// The corresponding [CacheController] that's used as a data provider.
  final CacheController<Item> controller;

  /// A builder for an [Item] to be displayed in the list.
  final Widget Function(BuildContext context, Item item) itemBuilder;

  /// A builder for an [error] banner to be shown at the top of the list.
  final Widget Function(BuildContext context, dynamic error) errorBannerBuilder;

  /// A builder for a full screen error message instead of the list.
  final Widget Function(BuildContext context, dynamic error) errorScreenBuilder;

  /// A builder for what to display when there are no items.
  final WidgetBuilder emptyStateBuilder;

  const CachedListView({
    Key key,
    @required this.controller,
    @required this.itemBuilder,
    @required this.errorBannerBuilder,
    @required this.errorScreenBuilder,
    @required this.emptyStateBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CachedCustomScrollView(
      controller: controller,
      sliverBuilder: (context, update) {
        assert(update.hasData || update.hasError);

        // If we're still loading, there can't be an error yet, so we are
        // guaranteed to have cached data to be displayed.
        if (update.isFetching) {
          assert(update.hasData);
          return [_buildItemsSliver(context, update.data)];
        }

        assert(!update.isFetching);

        // If everything went successful, display the newly fetched data.
        if (!update.hasError) {
          assert(update.hasData);
          return [_buildItemsSliver(context, update.data)];
        }

        assert(update.hasError);

        // If we have cached data, display the error as a banner above
        // the actual items. Otherwise, display a fullscreen error.
        if (update.hasData) {
          return [
            SliverList(
              delegate: SliverChildListDelegate([
                errorBannerBuilder(context, update.error),
              ]),
            ),
            _buildItemsSliver(context, update.data),
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

  Widget _buildItemsSliver(BuildContext context, List<Item> items) {
    if (items.isEmpty) {
      return SliverFillRemaining(child: emptyStateBuilder(context));
    } else {
      return SliverList(
        delegate: SliverChildBuilderDelegate((context, i) {
          return (i >= items.length) ? null : itemBuilder(context, items[i]);
        }),
      );
    }
  }
}
