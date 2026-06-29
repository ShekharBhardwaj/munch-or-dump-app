import 'package:flutter_test/flutter_test.dart';
import 'package:munch_or_dump/core/models/game.dart';
import 'package:munch_or_dump/core/models/receipt.dart';
import 'package:munch_or_dump/core/models/verdict.dart';

void main() {
  group('Receipt', () {
    test('ReceiptStart parses', () {
      final s = ReceiptStart.fromJson(<String, dynamic>{
        'job_id': 'job-1',
        'is_premium': false,
        'free_limit': 3,
      });
      expect(s.jobId, 'job-1');
      expect(s.isPremium, isFalse);
      expect(s.freeLimit, 3);
    });

    test('ReceiptJob parses status + items', () {
      final job = ReceiptJob.fromJson(<String, dynamic>{
        'status': 'done',
        'total': 2,
        'items': <Map<String, dynamic>>[
          <String, dynamic>{
            'name': 'Oat Milk',
            'brand': 'Oatly',
            'verdict': 'MUNCH',
            'score': 80,
            'product_slug': 'oatly-oat-milk',
            'locked': false,
          },
          <String, dynamic>{'input_name': 'mystery item', 'locked': true},
        ],
      });
      expect(job.isDone, isTrue);
      expect(job.items, hasLength(2));
      expect(job.items[0].verdict, Verdict.munch);
      expect(job.items[0].score, 80);
      expect(job.items[1].name, 'mystery item'); // falls back to input_name
      expect(job.items[1].locked, isTrue);
    });

    test('ReceiptJob defaults to processing', () {
      final job = ReceiptJob.fromJson(<String, dynamic>{});
      expect(job.isProcessing, isTrue);
      expect(job.items, isEmpty);
    });
  });

  group('Game', () {
    test('GameRound parses target + options', () {
      final round = GameRound.fromJson(<String, dynamic>{
        'target': <String, dynamic>{
          'name': 'Sparkling Water',
          'verdict': 'MUNCH',
          'verdict_score': 90,
          'slug': 'sparkling-water',
        },
        'options': <Map<String, dynamic>>[
          <String, dynamic>{
            'option_id': 'o1',
            'ingredients': <String>['Carbonated water'],
            'is_correct': true,
          },
          <String, dynamic>{
            'option_id': 'o2',
            'ingredients': <String>['Sugar', 'Color'],
            'is_correct': false,
          },
        ],
      });
      expect(round.target.name, 'Sparkling Water');
      expect(round.target.verdict, Verdict.munch);
      expect(round.options, hasLength(2));
      expect(round.options[0].isCorrect, isTrue);
      expect(round.options[0].ingredients.single, 'Carbonated water');
    });

    test('LeaderboardEntry + ScoreResult parse', () {
      final e = LeaderboardEntry.fromJson(<String, dynamic>{
        'name': 'Funny Crouton',
        'score': 4200,
        'streak': 12,
      });
      expect(e.name, 'Funny Crouton');
      expect(e.score, 4200);

      final r = ScoreResult.fromJson(<String, dynamic>{
        'name': 'Funny Crouton',
        'score': 4200,
        'rank': 3,
      });
      expect(r.rank, 3);
    });
  });
}
