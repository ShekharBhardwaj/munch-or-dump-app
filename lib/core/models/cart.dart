import 'package:munch_or_dump/core/models/analysis_result.dart';
import 'package:munch_or_dump/core/models/catalog.dart';
import 'package:munch_or_dump/core/models/receipt.dart';
import 'package:munch_or_dump/core/models/verdict.dart';

/// The cart data model — a device-local, anonymous shopping cart mirroring the
/// web's `CartContext` (`munch-or-dump-ui/src/lib/CartContext.jsx`). Items and
/// saved trips round-trip through the same snake_case JSON shape the web writes
/// to `localStorage`, persisted here via `shared_preferences`.

/// One product in the cart. Every add source (receipt OCR, typed list, scan
/// result, search, product page) normalizes into this shape — the exact port
/// of the web's `addToCart` normalization.
class CartItem {
  const CartItem({
    required this.inputName,
    required this.name,
    required this.addedAt,
    this.productSlug,
    this.brandName,
    this.verdict,
    this.score,
    this.shortExplanation,
    this.verdictReasons = const <String>[],
    this.locked = false,
    this.source = 'scan',
  });

  /// Tolerant decode of a persisted item. Callers wrap the list decode in a
  /// try/catch (matching the web's corrupt-localStorage guard), so this only
  /// needs to survive missing/typed-wrong fields, not arbitrary garbage.
  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    inputName: json['input_name']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    productSlug: json['product_slug'] as String?,
    brandName: json['brand_name'] as String?,
    verdict: Verdict.tryParse(json['verdict'] as String?),
    score: (json['score'] as num?)?.toInt(),
    shortExplanation: json['short_explanation'] as String?,
    verdictReasons:
        (json['verdict_reasons'] as List?)
            ?.map((dynamic e) => e.toString())
            .toList() ??
        const <String>[],
    locked: json['locked'] == true,
    source: json['source']?.toString() ?? 'scan',
    addedAt:
        DateTime.tryParse(json['added_at']?.toString() ?? '') ?? DateTime.now(),
  );

  /// Adapter from a receipt-job line item (`ReceiptItem`). Image jobs pass
  /// `source: 'receipt'` (the default); typed pre-shop lists pass `'typed'`.
  factory CartItem.fromReceiptItem(
    ReceiptItem item, {
    String source = 'receipt',
  }) => CartItem(
    inputName: item.inputName ?? item.name,
    name: item.name.isEmpty ? (item.inputName ?? '') : item.name,
    productSlug: item.productSlug,
    brandName: item.brand,
    verdict: item.verdict,
    score: item.score,
    shortExplanation: item.shortExplanation,
    locked: item.locked,
    source: source,
    addedAt: DateTime.now(),
  );

  /// Adapter from a search / category / brand list row.
  factory CartItem.fromProductListItem(
    ProductListItem item, {
    required String source,
  }) => CartItem(
    inputName: item.name,
    name: item.name,
    productSlug: item.slug.isEmpty ? null : item.slug,
    brandName: item.brandName,
    verdict: item.verdict,
    score: item.score,
    source: source,
    addedAt: DateTime.now(),
  );

  /// Adapter from a full scan/product analysis.
  factory CartItem.fromAnalysis(AnalysisResult result) => CartItem(
    inputName: result.productName,
    name: result.productName,
    productSlug: (result.productSlug?.trim().isEmpty ?? true)
        ? null
        : result.productSlug!.trim(),
    brandName: result.brand,
    verdict: result.verdict,
    score: result.verdictScore,
    shortExplanation: result.shortExplanation,
    verdictReasons: result.verdictReasons,
    source: 'scan',
    addedAt: DateTime.now(),
  );

  /// Adapter from a healthier-swap suggestion (`better_alternatives`).
  factory CartItem.fromAlternative(Alternative alt) => CartItem(
    inputName: alt.name,
    name: alt.name,
    productSlug: alt.slug.isEmpty ? null : alt.slug,
    brandName: alt.brandName,
    verdict: alt.verdict,
    score: alt.score,
    shortExplanation: alt.shortExplanation,
    source: 'product',
    addedAt: DateTime.now(),
  );

  /// OCR/typed raw name — what was scanned.
  final String inputName;

  /// Resolved product name.
  final String name;

  /// Catalog slug; null until resolved to a catalog product.
  final String? productSlug;
  final String? brandName;

  /// Null = unknown / not yet analyzed.
  final Verdict? verdict;
  final int? score;
  final String? shortExplanation;
  final List<String> verdictReasons;

  /// Premium-gated item from the receipt processor (free-tier overflow).
  final bool locked;

  /// `receipt` | `typed` | `scan` | `search` | `category-browse` | `product`.
  final String source;
  final DateTime addedAt;

  /// Dedup identity — the exact port of the web `itemKey`: the slug when one
  /// exists, else the lowercased trimmed name. An empty key (`name:`) is
  /// rejected by the controller.
  String get key {
    final slug = productSlug?.trim() ?? '';
    if (slug.isNotEmpty) return 'slug:$slug';
    final label = name.isEmpty ? inputName : name;
    return 'name:${label.toLowerCase().trim()}';
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'input_name': inputName,
    'name': name,
    'product_slug': productSlug,
    'brand_name': brandName,
    'verdict': verdict?.apiValue,
    'score': score,
    'short_explanation': shortExplanation,
    'verdict_reasons': verdictReasons,
    'locked': locked,
    'source': source,
    'added_at': addedAt.toIso8601String(),
  };
}

/// A completed shopping trip — a snapshot of the cart at "Save trip" time.
class SavedTrip {
  const SavedTrip({
    required this.id,
    required this.savedAt,
    required this.itemCount,
    required this.items,
    this.score,
  });

  factory SavedTrip.fromJson(Map<String, dynamic> json) => SavedTrip(
    id: json['id']?.toString() ?? '',
    savedAt:
        DateTime.tryParse(json['saved_at']?.toString() ?? '') ?? DateTime.now(),
    score: (json['score'] as num?)?.toInt(),
    itemCount: (json['item_count'] as num?)?.toInt() ?? 0,
    items:
        (json['items'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(CartItem.fromJson)
            .toList() ??
        const <CartItem>[],
  );

  final String id;
  final DateTime savedAt;

  /// Cart score computed at save time; null when nothing was analyzed.
  final int? score;
  final int itemCount;
  final List<CartItem> items;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'saved_at': savedAt.toIso8601String(),
    'score': score,
    'item_count': itemCount,
    'items': items.map((CartItem i) => i.toJson()).toList(),
  };
}

/// Average `score` over unlocked, scored items, rounded — the exact port of
/// the web `computeScore`. Null when nothing qualifies.
int? computeCartScore(List<CartItem> items) {
  final scored = items
      .where((CartItem i) => i.score != null && !i.locked)
      .toList();
  if (scored.isEmpty) return null;
  final sum = scored.fold<int>(0, (int s, CartItem i) => s + i.score!);
  return (sum / scored.length).round();
}

/// The cart controller's immutable state: live items + saved trip history.
class CartState {
  const CartState({
    this.items = const <CartItem>[],
    this.savedTrips = const <SavedTrip>[],
  });

  final List<CartItem> items;
  final List<SavedTrip> savedTrips;

  int get count => items.length;

  /// Cart-level score (see [computeCartScore]).
  int? get cartScore => computeCartScore(items);

  /// Items with a verdict, excluding premium-locked rows.
  List<CartItem> get analyzed => items
      .where((CartItem i) => i.verdict != null && !i.locked)
      .toList(growable: false);

  /// Bad-verdict items, worst (lowest score) first.
  List<CartItem> get bad =>
      analyzed.where((CartItem i) => i.verdict!.isBad).toList()
        ..sort((CartItem a, CartItem b) => (a.score ?? 0) - (b.score ?? 0));

  /// Good-verdict items (munch/okay/treat), best first.
  List<CartItem> get good =>
      analyzed.where((CartItem i) => !i.verdict!.isBad).toList()
        ..sort((CartItem a, CartItem b) => (b.score ?? 0) - (a.score ?? 0));

  /// Premium-locked rows (free-tier receipt overflow).
  List<CartItem> get lockedItems =>
      items.where((CartItem i) => i.locked).toList(growable: false);

  /// Unresolved items — no verdict yet and not locked.
  List<CartItem> get unknown => items
      .where((CartItem i) => i.verdict == null && !i.locked)
      .toList(growable: false);

  bool contains(String key) => items.any((CartItem i) => i.key == key);

  CartState copyWith({List<CartItem>? items, List<SavedTrip>? savedTrips}) =>
      CartState(
        items: items ?? this.items,
        savedTrips: savedTrips ?? this.savedTrips,
      );
}
