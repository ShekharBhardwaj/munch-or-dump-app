import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Riverpod's standard TTL pattern for `.autoDispose` providers: keep the
/// state alive for a fixed window so re-visiting a screen within that window
/// serves the cached value instead of refetching.
///
/// Note: `keepAlive()` moved from `AutoDisposeRef` onto [Ref] in Riverpod 2.6
/// (it throws at runtime if the provider is not `.autoDispose`), hence the
/// extension target.
extension CacheForExtension on Ref {
  /// Prevents this provider's state from being disposed for [duration] after
  /// it was built, even once all listeners are gone.
  ///
  /// After the window elapses the provider disposes as usual, so the next
  /// listen refetches. `ref.invalidate` / `ref.refresh` still force an
  /// immediate refetch at any time (the rebuild restarts the window).
  void cacheFor(Duration duration) {
    final link = keepAlive();
    final timer = Timer(duration, link.close);
    onDispose(timer.cancel);
  }
}
