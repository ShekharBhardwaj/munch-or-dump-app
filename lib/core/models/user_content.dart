import 'package:munch_or_dump/core/models/verdict.dart';

/// One past scan from `GET /api/scans` (the History screen). `verdict` may be
/// absent for a scan that was never analyzed.
class ScanHistoryItem {
  const ScanHistoryItem({
    required this.id,
    required this.productName,
    this.verdict,
    this.verdictScore,
    this.category,
    this.createdDate,
  });

  factory ScanHistoryItem.fromJson(Map<String, dynamic> json) =>
      ScanHistoryItem(
        id: json['id']?.toString() ?? '',
        productName: (json['product_name'] as String?)?.trim() ?? '',
        verdict: Verdict.tryParse(json['verdict'] as String?),
        verdictScore: (json['verdict_score'] as num?)?.toInt(),
        category: json['category'] as String?,
        createdDate: json['created_date'] as String?,
      );

  final String id;
  final String productName;
  final Verdict? verdict;
  final int? verdictScore;
  final String? category;
  final String? createdDate;
}

/// A saved product from `GET /api/lists`.
class SavedItem {
  const SavedItem({
    required this.productSlug,
    required this.productName,
    this.verdict,
    this.brandName,
    this.imageUrl,
  });

  factory SavedItem.fromJson(Map<String, dynamic> json) {
    final slug = json['product_slug']?.toString() ?? '';
    return SavedItem(
      productSlug: slug,
      productName: (json['product_name'] as String?)?.trim().isNotEmpty == true
          ? (json['product_name'] as String).trim()
          : slug,
      verdict: Verdict.tryParse(json['verdict'] as String?),
      brandName: json['brand_name'] as String?,
      imageUrl: json['image_url'] as String?,
    );
  }

  final String productSlug;
  final String productName;
  final Verdict? verdict;
  final String? brandName;
  final String? imageUrl;
}

/// Container for `GET /api/lists` — list name → saved products.
class SavedLists {
  const SavedLists(this.lists);

  factory SavedLists.fromJson(Map<String, dynamic> json) {
    final raw = json['lists'];
    final out = <String, List<SavedItem>>{};
    if (raw is Map) {
      raw.forEach((dynamic key, dynamic value) {
        if (value is List) {
          out[key.toString()] = value
              .whereType<Map<String, dynamic>>()
              .map(SavedItem.fromJson)
              .toList();
        }
      });
    }
    return SavedLists(out);
  }

  final Map<String, List<SavedItem>> lists;

  bool get isEmpty => lists.values.every((List<SavedItem> l) => l.isEmpty);
}

/// A watched product from `GET /api/watches`.
class WatchedProduct {
  const WatchedProduct({
    required this.productSlug,
    required this.productName,
    this.verdict,
    this.category,
  });

  factory WatchedProduct.fromJson(Map<String, dynamic> json) {
    final slug = json['product_slug']?.toString() ?? '';
    return WatchedProduct(
      productSlug: slug,
      productName: (json['product_name'] as String?)?.trim().isNotEmpty == true
          ? (json['product_name'] as String).trim()
          : slug,
      verdict: Verdict.tryParse(json['verdict'] as String?),
      category: json['category'] as String?,
    );
  }

  final String productSlug;
  final String productName;
  final Verdict? verdict;
  final String? category;
}

/// A watched brand from `GET /api/watches`.
class WatchedBrand {
  const WatchedBrand({
    required this.brandSlug,
    required this.brandName,
    this.productCount = 0,
  });

  factory WatchedBrand.fromJson(Map<String, dynamic> json) {
    final slug = json['brand_slug']?.toString() ?? '';
    return WatchedBrand(
      brandSlug: slug,
      brandName: (json['brand_name'] as String?)?.trim().isNotEmpty == true
          ? (json['brand_name'] as String).trim()
          : slug,
      productCount: (json['product_count'] as num?)?.toInt() ?? 0,
    );
  }

  final String brandSlug;
  final String brandName;
  final int productCount;
}

/// Container for `GET /api/watches`.
class Watches {
  const Watches({
    this.products = const <WatchedProduct>[],
    this.brands = const <WatchedBrand>[],
  });

  factory Watches.fromJson(Map<String, dynamic> json) => Watches(
    products:
        (json['products'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(WatchedProduct.fromJson)
            .toList() ??
        const <WatchedProduct>[],
    brands:
        (json['brands'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(WatchedBrand.fromJson)
            .toList() ??
        const <WatchedBrand>[],
  );

  final List<WatchedProduct> products;
  final List<WatchedBrand> brands;

  bool get isEmpty => products.isEmpty && brands.isEmpty;
}

/// A community vote choice.
enum VoteChoice {
  munch('munch'),
  dump('dump');

  const VoteChoice(this.apiValue);
  final String apiValue;
}

/// Community vote split from `GET /api/votes?...&summary=true`.
class VoteSummary {
  const VoteSummary({
    this.totalVotes = 0,
    this.munchVotes = 0,
    this.dumpVotes = 0,
    this.communityMunchPct = 0,
    this.communityVerdict,
  });

  factory VoteSummary.fromJson(Map<String, dynamic> json) => VoteSummary(
    totalVotes: (json['total_votes'] as num?)?.toInt() ?? 0,
    munchVotes: (json['munch_votes'] as num?)?.toInt() ?? 0,
    dumpVotes: (json['dump_votes'] as num?)?.toInt() ?? 0,
    communityMunchPct: (json['community_munch_pct'] as num?)?.toInt() ?? 0,
    communityVerdict: json['community_verdict'] as String?,
  );

  final int totalVotes;
  final int munchVotes;
  final int dumpVotes;
  final int communityMunchPct;
  final String? communityVerdict;
}
