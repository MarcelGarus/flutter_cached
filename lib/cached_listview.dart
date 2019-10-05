library cached_listview;

export 'src/controller.dart';
export 'src/widgets.dart';

/*import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'src/controller.dart';

class CachedCustomScrollView<Item> extends StatefulWidget {
  /// The corresponding [CacheController] that's used as a data provider.
  final CacheController<Item> controller;

  /// A function that receives raw [CacheUpdate]s and returns the slivers to
  /// build. Does not get called in cases where the (optionally provided)
  /// specific builders below can be used.
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

  /// A builder for an [error] banner to be shown at the top of the list.
  final Widget Function(BuildContext context, dynamic error) errorBannerBuilder;

  /// A builder for a full screen error message instead of the list.
  final Widget Function(BuildContext context, dynamic error) errorScreenBuilder;

  /// A builder for what to display when there are no items.
  final WidgetBuilder emptyStateBuilder;

  /// A builder for an [Item] to be displayed in the list.
  final Widget Function(BuildContext context, Item item) itemBuilder;

  /// A builder for item slivers to be displayed in the list.
  final List<Widget> Function(BuildContext context, List<Item> items)
      itemSliversBuilder;

  const CachedListView({
    Key key,
    @required this.controller,
    @required this.errorBannerBuilder,
    @required this.errorScreenBuilder,
    this.emptyStateBuilder,
    this.itemBuilder,
    this.itemSliversBuilder,
  })  : assert(controller != null),
        assert(errorBannerBuilder != null),
        assert(errorScreenBuilder != null),
        assert(
            itemBuilder != null || itemSliversBuilder != null,
            'You need to provide an itemBuilder or an itemSliversBuilder for '
            'building the items.'),
        assert(
            itemBuilder == null || itemSliversBuilder == null,
            "You can't provide both an itemBuilder and an itemSliversBuilder "
            "for building the items.\n\nUse an itemBuilder if all items "
            "should be displayed below each other and be built in a "
            "deterministic manner that doesn't depend on their index. "
            "Otherwise, use the itemSliversBuilder to receive the list of all "
            "items and return a list of all the slivers that should be "
            "created."),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return CachedCustomScrollView(
      controller: controller,
      sliverBuilder: (context, update) {
        assert(update.hasData || update.hasError);

        // If there's no error, we are guaranteed to have data - either we are
        // still fetching and can display cached data or we are finished.
        if (!update.hasError) {
          assert(update.hasData);
          return _buildItemSlivers(context, update.data);
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
    } else if (itemBuilder != null) {
      return [
        SliverList(
          delegate: SliverChildBuilderDelegate((context, i) {
            return (i >= items.length) ? null : itemBuilder(context, items[i]);
          }),
        )
      ];
    } else {
      return itemSliversBuilder(context, items);
    }
  }
}*/
