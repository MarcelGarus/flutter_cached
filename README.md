When building a screen that displays a cached list of items, there are many special cases to think about.

For example, on [material.io](https://material.io), there are guidelines on [how to handle displaying offline data](https://material.io/design/communication/offline-states.html) and when to use [error banners](https://material.io/design/communication/confirmation-acknowledgement.html) or [empty states](https://material.io/design/communication/empty-states.html).

This package tries to make implementing cached ListViews as easy as possible.

| loading with no data in cache | loading with data in cache              | loading successful          |
| ----------------------------- | --------------------------------------- | --------------------------- |
| ![](screenshot_loading.png)   | ![](screenshot_loading_with_cached.png) | ![](screenshot_success.png) |

| error with no data in cache      | error with data in cache             | no data available               |
| -------------------------------- | ------------------------------------ | ------------------------------- |
| ![](screenshot_banner_error.png) | ![](screenshot_fullscreen_error.png) | ![](screenshot_empty_state.png) |

## Usage

First, create a `CacheController`. This will be the class that orchestrates the fetching of data.

```dart
var cacheController = CacheController<Item>(
  // Does the actual work and returns a Future<List<Item>>.
  fetcher: _downloadData,
  // Asynchronously saves a List<Item> to the cache.
  saveToCache: _saveToCache,
  // Asynchronously loads a List<Item> from the cache.
  loadFromCache: _loadFromCache,
);
```

Then you can create a `CachedListView` in your widget tree:

```dart
CachedListView(
  controller: cacheController,
  itemBuilder: (context, item) => ...,
  errorBannerBuilder: (context, error) => ...,
  errorScreenBuilder: (context, error) => ...,
  emptyStateBuilder: (context) => ...,
),
```
