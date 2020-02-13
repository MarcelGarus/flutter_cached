When building an app that caches data, there are many special cases to think about.

For example, according to the [Material Design guidelines](https://material.io), you need to worry about displaying [offline data](https://material.io/design/communication/offline-states.html), handling [swipe to refresh](https://material.io/design/platform-guidance/android-swipe-to-refresh.html), showing [error banners](https://material.io/design/communication/confirmation-acknowledgement.html) and displaying [empty states](https://material.io/design/communication/empty-states.html).

This package aims to make implementing cached Flutter apps as easy as possible.

Usually, the frontend asks the backend to fetch data and the backend then offers a continuous `Stream` of data to your frontend.
When listening to bare-bone streams in Dart, you usually have to work with `AsyncSnapshot`s quite often.

This package offers a new, augmented type of communication path between backend and frontend designed around the providing of cached data.

```
+----------+                             +----+
| business +-----------------+  updates  | UI |
| logic    | CacheController |==========>|    |
|          |                 |<==========|    |
|          +-----------------+  fetch()  |    |
|          |                             |    |
|          +-----------------+  updates  |    |
|          | CacheController |==========>|    |
|          |                 |<==========|    |
|          +-----------------+  fetch()  |    |
+----------+                             +----+
```

## The communication: `CacheUpdate`

This type provides not only data or an error (like a normal `AsyncSnapshot`), but also contains information about whether data is still being fetched. Also, every error is accompanied by a stack trace.

For comparison, here are the possible states of the `AsyncSnapshot`:

|               | **no data** | **has data** |
| ------------- | ----------- | ------------ |
| **no error**  | nothing     | with data    |
| **has error** | with error  | -            |

Here are the possible states of a `CacheUpdate`:

|                  |               | **no data** | **has data**    |
| ---------------- | ------------- | ----------- | --------------- |
| **fetching**     | **no error**  | loading     | cached          |
| **fetching**     | **has error** | -           | -               |
| **not fetching** | **no error**  | initial     | success         |
| **not fetching** | **has error** | error       | error but cache |

Now that looks like an upgraded version of `AsyncSnapshot`!

## The data layer

`CacheController`s glue together the logic for fetching data with the UI.
You can call `fetch` on these controllers to fetch data. And you can call `updates` to get a stream of `CacheUpdate`s.

There are currently two types of `CacheController`s:

- The `SimpleCacheController` accepts three functions: `fetcher`, `saveToCache`and `loadFromCache`.
  When `fetch` is called, it simultaneously calls the `fetcher` and the `loadFromCache` function. If `loadFromCache` returns first, it sends out a `CacheUpdate` containing the cached data. When finally the `fetcher` returns, it sends out another `CacheUpdate` containing the actual data. It also passes the data to `saveToCache`.
- The `PaginatedCacheController` is a `CacheController` specific to `List`s of items. It works just like the `SimpleCacheController` except that the `fetcher` returns both a list of items as well as a `PaginationState` (this can be any class that implements `isDone`).  
  Next to the `fetch` method, the `PaginatedCacheController` also has a `fetchMore` method, which calls the `fetcher` again, passing in the last state it returned.  
  By saving the offset or a pagination token or something similar in the `PaginationState`, it's quite easy for clients to implement pagination.

Here's an example of how each of these controllers work:

```dart
// A simple controller asking the International Chuck Norris Database for
// jokes. The second fetch call causes a joke to be immediately printed.
// (Although this is not that great of an example, because the jokes are
// non-deterministic.)
final controller = SimpleCacheController<String>(
  fetcher: () async {
    final response = http.get('http://api.icndb.com/jokes/random/');
    return json.decode(response)['value']['joke'];
  },
  saveToCache: (joke) async {
    await File('cache.txt').writeAsString(joke);
  },
  loadFromCache: () async {
    return await File('cache.txt').readAsString();
  },
);

controller.updates.forEach(print);

await controller.fetch();
await controller.fetch();
```

```dart
class MyPaginationState implements PaginationState {
  MyPaginationState({this.offset, this.isDone});
  
  final int offset;
  final bool isDone;
}

// A paginated controller that requests an API with an increasing offset.
final controller = PaginatedCacheController<String, int>(
  fetcher: (state) async {
    final response = json.decode(http.get('…?offset=${state.offset}')).
    final items = response['items'].cast<String>().toList();

    return PaginationResponse(
      items: items,
      state: MyPaginationState(
        offset: state.offset + items.length,
        isDone: items.isEmpty,
      ),
    );
  },
  saveToCache: (data) => …;
  loadFromCache: () => …,
);

controller.updates.forEach(print);

// Fetches data and some more data.
await controller.fetch();
await controller.fetchMore();
await controller.fetchMore();

// Re-fetches data. Displays the cached data as long as the Future is still
// loading.
await controller.fetch();
await controller.fetchMore();
```

## The UI layer

### `CachedRawBuilder`

Because parsing `Stream<CacheUpdate<T>>` is tedious, there's an equivalent to Flutter's built-in `StreamBuilder` that makes reacting to `CacheUpdate`s easy:

```dart
CachedRawBuilder(
  controller: controller,
  builder: (context, update) {
    return Container(color: update.hasData ? Colors.green : Colors.red);
  },
),
```

### `CachedBuilder`

Often, `CacheUpdate`s are handled similarly.
The `CachedBuilder` provides several builder for special cases:

```dart
// The CachedBuilder supports pull-to-refresh out of the box.
CachedBuilder(
  controller: controller,
  loadingScreenBuilder: (context) => …,
  // When an error occurs during fetching but there is cached data, the data is
  // still shown but an error banner is displayed at the top.
  errorBannerBuilder: (context, error, stackTrace) => …,
  // When there's no cached data and an errors occurs, it's shown in
  // full-screen.
  errorScreenBuilder: (context, error, stackTrace) => …,
  // There is data to show (either cached data or live data).
  builder: (context, data) {
      return Center(child: Text(data));
  },
),
```

> **Note**: By default, the `CachedBuilder` assumes that the `builder` returns a scrollable widget, like a `ListView` or `GridView`. If that's not the case, you need to set `hasScrollBody` to `false` in order for the swipe to refresh to work.

### `PaginatedListView`

Quite often, the cached data is a paginated list.
This view takes care of loading more items.

And that's it!
More description coming soon!
