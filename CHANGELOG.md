## [2.0.2] - 2019-10-14

* Provide `lastData` and `lastError` getters on `CacheController`.

## [2.0.1] - 2019-10-12

* Update examples.
* Complete transition to `flutter_cached`.
* Remove `list_diff` dependency.

## [2.0.0] - 2019-10-12

* Complete overhaul of the API.
* Package moved to `flutter_cached`.

## [1.1.5] - 2019-10-11

* Add more examples to the demo. Now all abstraction levels are covered.
* Fix unbound vertical height issue caused by `AnimatedCrossFade`.

## [1.1.4] - 2019-10-11

* Fix type propagation on `CacheController`'s `updates`.

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
