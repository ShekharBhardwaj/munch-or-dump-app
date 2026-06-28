import 'package:flutter_test/flutter_test.dart';
import 'package:munch_or_dump/core/models/analysis_result.dart';
import 'package:munch_or_dump/core/models/user_content.dart';
import 'package:munch_or_dump/core/models/verdict.dart';

void main() {
  group('Verdict.tryParse', () {
    test('returns the verdict for a known token', () {
      expect(Verdict.tryParse('MUNCH'), Verdict.munch);
      expect(Verdict.tryParse('engineered'), Verdict.engineered);
    });

    test('returns null for empty / null / unknown', () {
      expect(Verdict.tryParse(''), isNull);
      expect(Verdict.tryParse(null), isNull);
      expect(Verdict.tryParse('???'), isNull);
    });
  });

  group('SafetyRating.fromApi handles both API vocabularies', () {
    test('analyze words (safe/moderate/concerning/harmful)', () {
      expect(SafetyRating.fromApi('safe'), SafetyRating.safe);
      expect(SafetyRating.fromApi('concerning'), SafetyRating.concerning);
      expect(SafetyRating.fromApi('harmful'), SafetyRating.harmful);
    });

    test('scans/products words (LOW/MEDIUM/HIGH/CRITICAL)', () {
      expect(SafetyRating.fromApi('LOW'), SafetyRating.safe);
      expect(SafetyRating.fromApi('MEDIUM'), SafetyRating.moderate);
      expect(SafetyRating.fromApi('HIGH'), SafetyRating.concerning);
      expect(SafetyRating.fromApi('CRITICAL'), SafetyRating.harmful);
    });
  });

  group('ScanHistoryItem', () {
    test('parses verdict + score', () {
      final item = ScanHistoryItem.fromJson(<String, dynamic>{
        'id': 's1',
        'product_name': 'Soda',
        'verdict': 'DUMP',
        'verdict_score': 20,
        'created_date': '2026-06-28T12:00:00Z',
      });
      expect(item.productName, 'Soda');
      expect(item.verdict, Verdict.dump);
      expect(item.verdictScore, 20);
    });

    test('verdict is null for an un-analyzed scan (empty string)', () {
      final item = ScanHistoryItem.fromJson(<String, dynamic>{
        'id': 's2',
        'product_name': 'X',
        'verdict': '',
      });
      expect(item.verdict, isNull);
    });
  });

  test('SavedLists parses nested list groups', () {
    final lists = SavedLists.fromJson(<String, dynamic>{
      'lists': <String, dynamic>{
        'saved': <Map<String, dynamic>>[
          <String, dynamic>{
            'product_slug': 'nutella',
            'product_name': 'Nutella',
            'verdict': 'ENGINEERED',
          },
        ],
      },
    });
    expect(lists.isEmpty, isFalse);
    expect(lists.lists['saved'], hasLength(1));
    expect(lists.lists['saved']!.first.verdict, Verdict.engineered);
  });

  test('Watches parses products and brands', () {
    final w = Watches.fromJson(<String, dynamic>{
      'products': <Map<String, dynamic>>[
        <String, dynamic>{
          'product_slug': 'p',
          'product_name': 'P',
          'verdict': 'MUNCH',
        },
      ],
      'brands': <Map<String, dynamic>>[
        <String, dynamic>{
          'brand_slug': 'b',
          'brand_name': 'B',
          'product_count': 3,
        },
      ],
    });
    expect(w.products.single.verdict, Verdict.munch);
    expect(w.brands.single.productCount, 3);
    expect(w.isEmpty, isFalse);
  });

  test('VoteSummary parses the community split', () {
    final v = VoteSummary.fromJson(<String, dynamic>{
      'total_votes': 10,
      'munch_votes': 7,
      'dump_votes': 3,
      'community_munch_pct': 70,
      'community_verdict': 'munch',
    });
    expect(v.totalVotes, 10);
    expect(v.communityMunchPct, 70);
    expect(v.communityVerdict, 'munch');
  });
}
