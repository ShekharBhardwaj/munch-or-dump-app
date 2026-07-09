import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:munch_or_dump/core/models/cart.dart';
import 'package:munch_or_dump/core/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The persistent cart — the app-side port of the web `CartProvider`
/// (`munch-or-dump-ui/src/lib/CartContext.jsx`). Device-local and anonymous:
/// the cart is NOT synced to the server, is not user-scoped, and survives
/// sign-out (matching the web's `localStorage` behavior).
///
/// A synchronous [Notifier]: `build()` hydrates from the [SharedPreferences]
/// instance preloaded in `main()`, so the cart is available on first frame.
class CartController extends Notifier<CartState> {
  /// Same key names as the web's `localStorage`, so the convention is
  /// recognizable across clients.
  static const String itemsKey = 'munch_cart_v1';
  static const String historyKey = 'munch_cart_history_v1';

  /// Saved-trip history cap (web `MAX_SAVED`) — oldest trips drop off.
  static const int maxSavedTrips = 10;

  @override
  CartState build() {
    final prefs = ref.watch(sharedPrefsProvider);
    return CartState(
      items: _decodeList(_read(prefs, itemsKey), CartItem.fromJson),
      savedTrips: _decodeList(_read(prefs, historyKey), SavedTrip.fromJson),
    );
  }

  /// [SharedPreferences.getString] throws a [TypeError] when the stored value
  /// isn't a string (another writer, platform corruption). Treat that exactly
  /// like corrupt JSON: hydrate empty instead of crashing `build()`.
  String? _read(SharedPreferences prefs, String key) {
    try {
      return prefs.getString(key);
    } on Object catch (_) {
      return null;
    }
  }

  /// Corrupt/legacy JSON must never crash `build()` — parse failures start
  /// with an empty list, matching the web's try/catch around `JSON.parse`.
  List<T> _decodeList<T>(
    String? raw,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded.whereType<Map<String, dynamic>>().map(fromJson).toList();
    } on Object catch (_) {
      return const [];
    }
  }

  void _persist() {
    final prefs = ref.read(sharedPrefsProvider);
    unawaited(
      prefs.setString(
        itemsKey,
        jsonEncode(state.items.map((CartItem i) => i.toJson()).toList()),
      ),
    );
    unawaited(
      prefs.setString(
        historyKey,
        jsonEncode(state.savedTrips.map((SavedTrip t) => t.toJson()).toList()),
      ),
    );
  }

  /// Add [item], deduped by [CartItem.key]. A no-op for an already-carted key
  /// or an empty identity (`name:`) — the web `addToCart` guard. Returns true
  /// when the item was actually added.
  bool addItem(CartItem item) {
    final key = item.key;
    if (key == 'name:' || key.isEmpty) return false;
    if (state.contains(key)) return false;
    state = state.copyWith(items: <CartItem>[...state.items, item]);
    _persist();
    return true;
  }

  /// Add every item (deduped). Returns how many were actually added.
  int addAll(Iterable<CartItem> items) {
    var added = 0;
    for (final item in items) {
      if (addItem(item)) added++;
    }
    return added;
  }

  void removeByKey(String key) {
    state = state.copyWith(
      items: state.items.where((CartItem i) => i.key != key).toList(),
    );
    _persist();
  }

  void clear() {
    state = state.copyWith(items: const <CartItem>[]);
    _persist();
  }

  bool contains(String key) => state.contains(key);

  /// Snapshot the cart as a completed trip (score computed now), prepend it to
  /// history (capped at [maxSavedTrips]), and start fresh — the web `saveCart`.
  void saveTrip() {
    if (state.items.isEmpty) return;
    final trip = SavedTrip(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      savedAt: DateTime.now(),
      score: state.cartScore,
      itemCount: state.items.length,
      items: List<CartItem>.of(state.items),
    );
    state = CartState(
      items: const <CartItem>[],
      savedTrips: <SavedTrip>[
        trip,
        ...state.savedTrips,
      ].take(maxSavedTrips).toList(),
    );
    _persist();
  }

  void deleteTrip(String id) {
    state = state.copyWith(
      savedTrips: state.savedTrips.where((SavedTrip t) => t.id != id).toList(),
    );
    _persist();
  }
}

final cartControllerProvider = NotifierProvider<CartController, CartState>(
  CartController.new,
);
