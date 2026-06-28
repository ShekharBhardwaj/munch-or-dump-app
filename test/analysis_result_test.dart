import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:munch_or_dump/core/models/analysis_result.dart';
import 'package:munch_or_dump/core/models/user_content.dart';
import 'package:munch_or_dump/core/models/verdict.dart';
import 'package:munch_or_dump/features/result/result_actions.dart';
import 'package:munch_or_dump/features/result/result_screen.dart';

Map<String, dynamic> _sampleJson() => <String, dynamic>{
  'verdict': 'OKAY',
  'verdict_score': 60,
  'product_name': 'Test Granola',
  'brand_name': 'Acme',
  'category': 'food',
  'confidence': 'HIGH',
  'short_explanation': 'Decent but sugary.',
  'verdict_reasons': <String>['Whole grains', 'Added sugar'],
  'ingredients_detected': <Map<String, dynamic>>[
    <String, dynamic>{
      'name': 'Oats',
      'safety_rating': 'safe',
      'explanation': 'Whole grain',
      'impact_score': 10,
    },
    <String, dynamic>{
      'name': 'Cane sugar',
      'safety_rating': 'concerning',
      'impact_score': -8,
    },
  ],
  'marketing_claims': <Map<String, dynamic>>[
    <String, dynamic>{
      'claim': 'All natural',
      'reality': 'Still high in sugar',
      'is_misleading': true,
    },
  ],
  'nutrition_summary': <String, dynamic>{
    'sugar_level': 'High (15g)',
    'fat_composition': null,
  },
  'is_vegan': true,
  'contains_nuts': true,
  'cache_hit': true,
  'profile_note': 'High sugar — mind your goal.',
  'barcode': '0123456789012',
};

void main() {
  group('AnalysisResult.fromJson', () {
    test('parses verdict, score, and identity', () {
      final r = AnalysisResult.fromJson(_sampleJson());
      expect(r.verdict, Verdict.okay);
      expect(r.verdictScore, 60);
      expect(r.productName, 'Test Granola');
      expect(r.brandName, 'Acme');
      expect(r.cacheHit, isTrue);
      expect(r.hasProfileNote, isTrue);
    });

    test('parses ingredients with safety ratings', () {
      final r = AnalysisResult.fromJson(_sampleJson());
      expect(r.ingredientsDetected, hasLength(2));
      expect(r.ingredientsDetected[0].rating, SafetyRating.safe);
      expect(r.ingredientsDetected[1].rating, SafetyRating.concerning);
      expect(r.ingredientsDetected[1].impactScore, -8);
    });

    test('parses marketing claims and dietary flags', () {
      final r = AnalysisResult.fromJson(_sampleJson());
      expect(r.marketingClaims.single.isMisleading, isTrue);
      expect(r.isVegan, isTrue);
      expect(r.containsNuts, isTrue);
    });

    test('nutritionFacts drops null/empty values', () {
      final r = AnalysisResult.fromJson(_sampleJson());
      expect(r.nutritionFacts, <String, String>{'sugar_level': 'High (15g)'});
    });

    test('defaults are applied for a minimal payload', () {
      final r = AnalysisResult.fromJson(<String, dynamic>{
        'verdict': 'DUMP',
        'verdict_score': 20,
        'product_name': 'X',
      });
      expect(r.verdict, Verdict.dump);
      expect(r.ingredientsDetected, isEmpty);
      expect(r.verdictReasons, isEmpty);
      expect(r.cacheHit, isFalse);
      expect(r.hasProfileNote, isFalse);
    });

    test('tolerates a null product_name (the API may emit null)', () {
      final r = AnalysisResult.fromJson(<String, dynamic>{
        'verdict': 'DUMP',
        'verdict_score': 20,
        'product_name': null,
      });
      expect(r.productName, '');
    });

    test('brand falls back to off_data when brand_name is absent', () {
      final r = AnalysisResult.fromJson(<String, dynamic>{
        'verdict': 'OKAY',
        'verdict_score': 60,
        'product_name': 'X',
        'off_data': <String, dynamic>{'brand': 'Acme Foods'},
      });
      expect(r.brand, 'Acme Foods');
    });
  });

  testWidgets('Result screen renders the verdict and score', (tester) async {
    final result = AnalysisResult.fromJson(_sampleJson());
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          // Avoid a real /api/votes call from the community widget.
          voteSummaryProvider(
            'Test Granola',
          ).overrideWith((ref) => const VoteSummary()),
        ],
        child: MaterialApp(home: ResultScreen(result: result)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('OKAY'), findsOneWidget);
    expect(find.text('60'), findsOneWidget);
    expect(find.text('Test Granola'), findsOneWidget); // app bar title
    expect(find.textContaining('All natural'), findsOneWidget);
  });
}
