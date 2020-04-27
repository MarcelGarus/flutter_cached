Often, apps just display data fetched from some server.
This package introduces the concept of fetchable streams. They are just like normal `Stream`s, but can be fetched.

Let's say you want to load `Fruit`s from a server:

```dart
final stream = FetchStream.create<Fruit>(() {
  // Do some network request and parse it to obtain a Fruit.
});
stream.listen(print);

// By default, the stream never emits and events. Only after calling fetch(), it
// calls the provided function and emits the result.
stream.fetch();

// Calling fetch again executes the function again and provides the result to
// all listeners. If the function is already running, it's not called again.
stream.fetch();

// After your're done using the stream, dispose it.
await Future.delayed(Duration(seconds: 10));
stream.dispose();
```

The real magic happens by calling `stream.cached()`.
This creates a cached version of this stream using the provided methods.

```dart
final cachedStream = stream.cached(
  save: (fruit) {
    // Save the fruit to storage.
  },
  load: (fruit) async* {
    // Load the fruit from storage and yield it. If there are updates to the
    // fruit, you can also optionally yied them too.
  },
);
```

And that's about it!
