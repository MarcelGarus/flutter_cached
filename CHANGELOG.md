## [4.2.1] - 2020-02-23

* Add `map` method to `CacheController`.

## [4.1.1] - 2020-02-13

* Make `CacheUpdate`'s (default) constructor public under the name `.raw(…)`.

## [4.1.0] - 2020-02-13

* There are now several utility controllers: You can create a controller from a stream of controllers, a list of controllers as well as a list of `CacheUpdate`s.

## [4.0.0] - 2020-01-24

* Refactored `CacheController`: There are now two concrete `CacheController` implementations: The `SimpleCacheController` and the `PaginatedCacheController`.
* The `CacheUpdate` got several fancy constructors (`initial`, `loading`, `cached`, `success`, `error`) and getters (`isNotFetching`, `hasNoData`, `hasNoError`).
* The readme got revised quite a bit.

## [3.2.0] - 2020-01-24

* Create `CacheController` interface and rename former `CacheController` to `CacheControllerImpl`.
* Create `PaginatedListView`.

## [3.1.0] - 2020-01-24

* Add `PaginatedCacheController`.

## [3.0.1] - 2019-11-09

* Fix `CacheController`, where the data would be saved to the cache but not
  being sent directly to the updates streams.

## [3.0.0] - 2019-11-02

* When calling `loadFromCache`, the `CacheController` only catches
  `NotInCacheException`s, not all possible errors. That makes it simpler to
  debug, because you need to explicitly throw this error if the cache is empty.
  Other errors will still bubble up to the debugger.
* The `CacheUpdate` now also contains a `stackTrace` if it contains an `error`.
  That makes debugging even easier.

## [2.1.1] - 2019-11-02

* You don't need to call `dispose` anymore. If you want to listen to multiple
  update streams of the same controller, just request `updates` multiple times.

## [2.1.0] - 2019-11-02

* Optionally provide a `controllerBuilder` instead of a `controller` to the
  `CachedRawBuilder` or the `CachedBuilder`. `dispose` is called automatically.

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
