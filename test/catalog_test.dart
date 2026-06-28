import 'package:flutter_test/flutter_test.dart';
import 'package:munch_or_dump/core/models/analysis_result.dart';
import 'package:munch_or_dump/core/models/catalog.dart';
import 'package:munch_or_dump/core/models/verdict.dart';

void main() {
  group('ProductListItem tolerates both endpoint shapes', () {
    test('search shape (product_name / verdict_score)', () {
      final p = ProductListItem.fromJson(<String, dynamic>{
        'product_name': 'Granola',
        'slug': 'granola',
        'verdict': 'OKAY',
        'verdict_score': 60,
        'brand_name': 'Acme',
      });
      expect(p.name, 'Granola');
      expect(p.verdict, Verdict.okay);
      expect(p.score, 60);
      expect(p.brandName, 'Acme');
    });

    test('category/ingredient shape (name / score)', () {
      final p = ProductListItem.fromJson(<String, dynamic>{
        'name': 'Chips',
        'slug': 'chips',
        'verdict': 'DUMP',
        'score': 20,
      });
      expect(p.name, 'Chips');
      expect(p.verdict, Verdict.dump);
      expect(p.score, 20);
    });
  });

  test('parseProductSearch reads items/total/gated', () {
    final result = parseProductSearch(<String, dynamic>{
      'items': <Map<String, dynamic>>[
        <String, dynamic>{'product_name': 'A', 'slug': 'a', 'verdict': 'MUNCH'},
      ],
      'total': 42,
      'gated': true,
    });
    expect(result.items, hasLength(1));
    expect(result.total, 42);
    expect(result.gated, isTrue);
  });

  test('BrandSummary / CategorySummary parse', () {
    final b = BrandSummary.fromJson(<String, dynamic>{
      'name': 'Acme',
      'slug': 'acme',
      'product_count': 12,
      'avg_score': 55,
      'tier': 'mixed',
    });
    expect(b.name, 'Acme');
    expect(b.productCount, 12);
    expect(b.avgScore, 55);

    final c = CategorySummary.fromJson(<String, dynamic>{
      'slug': 'chips-crisps',
      'label': 'Chips & Crisps',
      'product_count': 30,
    });
    expect(c.label, 'Chips & Crisps');
    expect(c.productCount, 30);
  });

  test('IngredientDetail parses fields + products', () {
    final ing = IngredientDetail.fromJson(<String, dynamic>{
      'name': 'Aspartame',
      'slug': 'aspartame',
      'safety_rating': 'concern',
      'e_number': 'E951',
      'is_additive': true,
      'health_effects': <String>['Debated long-term effects'],
      'products': <Map<String, dynamic>>[
        <String, dynamic>{
          'name': 'Diet Soda',
          'slug': 'diet-soda',
          'verdict': 'DUMP',
        },
      ],
    });
    expect(ing.eNumber, 'E951');
    expect(ing.isAdditive, isTrue);
    expect(ing.healthEffects, isNotEmpty);
    expect(ing.products.single.slug, 'diet-soda');
    // 'concern' maps into the moderate→harmful scale (concerning).
    expect(SafetyRating.fromApi(ing.safetyRating), SafetyRating.concerning);
  });

  test('Alternative parses from better_alternatives item', () {
    final alt = Alternative.fromJson(<String, dynamic>{
      'name': 'Better Bar',
      'slug': 'better-bar',
      'verdict': 'MUNCH',
      'score': 88,
      'score_delta': 40,
      'brand_name': 'Clean Co',
    });
    expect(alt.name, 'Better Bar');
    expect(alt.verdict, Verdict.munch);
    expect(alt.scoreDelta, 40);
  });
}
