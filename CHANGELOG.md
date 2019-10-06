## [1.1.3] - 2019-10-06

* We now depend on the [`pull_to_refresh`](https://pub.dev/packages/pull_to_refresh)
  package so that we can start the refresh indicator programatically.
* Fix missing meta dependency.

## [1.1.2] - 2019-10-05

* `CachedListView` now takes either an `itemBuilder` for building the items
  directly one after another in an index-agnostic deterministic way or it takes
  an `itemSliverBuilder` for transforming all the items into slivers
  simultaneously, allowing for changing the order, grouping etc of items.

## [1.1.1] - 2019-10-04

* Fix type propagation for `CachedCustomScrollView`.

## [1.1.0] - 2019-10-04

* Add abstraction level below `CachedListView`: `CachedCustomScrollView`.
* Rename `CacheManager` to `CacheController`.
* Update readme to reflect changes and display screenshots in table.

## [1.0.0] - 2019-10-04

* Add `CacheManager` and `CachedListView`.
