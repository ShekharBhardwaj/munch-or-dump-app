import 'package:munch_or_dump/core/models/verdict.dart';

/// A product as it appears in a list (search results, brand/category products,
/// ingredient products). Tolerates the field-name differences across endpoints:
/// search uses `product_name`/`verdict_score`; category/ingredient use
/// `name`/`score`.
class ProductListItem {
  const ProductListItem({
    required this.name,
    required this.slug,
    this.verdict,
    this.score,
    this.brandName,
    this.imageUrl,
    this.category,
    this.countryOfOrigin,
  });

  factory ProductListItem.fromJson(Map<String, dynamic> json) {
    final rawScore = json['verdict_score'] ?? json['score'];
    return ProductListItem(
      name: (json['product_name'] ?? json['name'])?.toString().trim() ?? '',
      slug: json['slug']?.toString() ?? '',
      verdict: Verdict.tryParse(json['verdict'] as String?),
      score: rawScore is num ? rawScore.toInt() : null,
      brandName: json['brand_name'] as String?,
      imageUrl: json['image_url'] as String?,
      category: json['category'] as String?,
      countryOfOrigin: json['country_of_origin'] as String?,
    );
  }

  final String name;
  final String slug;
  final Verdict? verdict;
  final int? score;
  final String? brandName;
  final String? imageUrl;
  final String? category;
  final String? countryOfOrigin;
}

/// `GET /api/products` search/list envelope.
typedef ProductSearchResult = ({
  List<ProductListItem> items,
  int total,
  bool gated,
});

ProductSearchResult parseProductSearch(Map<String, dynamic> json) => (
  items:
      (json['items'] as List?)
          ?.whereType<Map<String, dynamic>>()
          .map(ProductListItem.fromJson)
          .toList() ??
      const <ProductListItem>[],
  total: (json['total'] as num?)?.toInt() ?? 0,
  gated: json['gated'] == true,
);

/// A brand in the `GET /api/brands` list.
class BrandSummary {
  const BrandSummary({
    required this.name,
    required this.slug,
    this.productCount = 0,
    this.avgScore,
    this.tier,
  });

  factory BrandSummary.fromJson(Map<String, dynamic> json) => BrandSummary(
    name: json['name']?.toString().trim() ?? json['slug']?.toString() ?? '',
    slug: json['slug']?.toString() ?? '',
    productCount: (json['product_count'] as num?)?.toInt() ?? 0,
    avgScore: (json['avg_score'] as num?)?.toInt(),
    tier: json['tier'] as String?,
  );

  final String name;
  final String slug;
  final int productCount;
  final int? avgScore;
  final String? tier;
}

/// `GET /api/brands/:slug` detail.
class BrandDetail {
  const BrandDetail({
    required this.name,
    required this.slug,
    this.website,
    this.products = const <ProductListItem>[],
    this.gated = false,
  });

  factory BrandDetail.fromJson(Map<String, dynamic> json) => BrandDetail(
    name: json['name']?.toString().trim() ?? json['slug']?.toString() ?? '',
    slug: json['slug']?.toString() ?? '',
    website: json['website'] as String?,
    products:
        (json['products'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(ProductListItem.fromJson)
            .toList() ??
        const <ProductListItem>[],
    gated: json['gated'] == true,
  );

  final String name;
  final String slug;
  final String? website;
  final List<ProductListItem> products;
  final bool gated;
}

/// A category in the `GET /api/categories` list.
class CategorySummary {
  const CategorySummary({
    required this.slug,
    required this.label,
    this.productCount = 0,
    this.avgScore,
    this.tier,
  });

  factory CategorySummary.fromJson(Map<String, dynamic> json) {
    final slug = json['slug']?.toString() ?? '';
    return CategorySummary(
      slug: slug,
      label: json['label']?.toString().trim().isNotEmpty == true
          ? (json['label'] as String).trim()
          : slug,
      productCount: (json['product_count'] as num?)?.toInt() ?? 0,
      avgScore: (json['avg_score'] as num?)?.toInt(),
      tier: json['tier'] as String?,
    );
  }

  final String slug;
  final String label;
  final int productCount;
  final int? avgScore;
  final String? tier;
}

/// `GET /api/categories/:slug` detail.
class CategoryDetail {
  const CategoryDetail({
    required this.slug,
    required this.label,
    this.avgScore,
    this.products = const <ProductListItem>[],
    this.gated = false,
  });

  factory CategoryDetail.fromJson(Map<String, dynamic> json) {
    final slug = json['slug']?.toString() ?? '';
    return CategoryDetail(
      slug: slug,
      label: json['label']?.toString().trim().isNotEmpty == true
          ? (json['label'] as String).trim()
          : slug,
      avgScore: (json['avg_score'] as num?)?.toInt(),
      products:
          (json['products'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(ProductListItem.fromJson)
              .toList() ??
          const <ProductListItem>[],
      gated: json['gated'] == true,
    );
  }

  final String slug;
  final String label;
  final int? avgScore;
  final List<ProductListItem> products;
  final bool gated;
}

/// `GET /api/ingredients/:slug` detail (the endpoint returns a single-item array).
class IngredientDetail {
  const IngredientDetail({
    required this.name,
    required this.slug,
    this.safetyRating,
    this.description,
    this.eNumber,
    this.isAdditive = false,
    this.healthEffects = const <String>[],
    this.avoidIf = const <String>[],
    this.products = const <ProductListItem>[],
    this.gated = false,
  });

  factory IngredientDetail.fromJson(Map<String, dynamic> json) =>
      IngredientDetail(
        name: json['name']?.toString().trim() ?? json['slug']?.toString() ?? '',
        slug: json['slug']?.toString() ?? '',
        safetyRating: json['safety_rating'] as String?,
        description: json['description'] as String?,
        eNumber: json['e_number'] as String?,
        isAdditive: json['is_additive'] == true,
        healthEffects:
            (json['health_effects'] as List?)
                ?.map((dynamic e) => e.toString())
                .toList() ??
            const <String>[],
        avoidIf:
            (json['avoid_if'] as List?)
                ?.map((dynamic e) => e.toString())
                .toList() ??
            const <String>[],
        products:
            (json['products'] as List?)
                ?.whereType<Map<String, dynamic>>()
                .map(ProductListItem.fromJson)
                .toList() ??
            const <ProductListItem>[],
        gated: json['gated'] == true,
      );

  final String name;
  final String slug;
  final String? safetyRating;
  final String? description;
  final String? eNumber;
  final bool isAdditive;
  final List<String> healthEffects;
  final List<String> avoidIf;
  final List<ProductListItem> products;
  final bool gated;
}
