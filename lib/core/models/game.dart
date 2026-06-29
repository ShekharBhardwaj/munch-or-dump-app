import 'package:munch_or_dump/core/models/verdict.dart';

/// The product the player must match to its ingredient list.
class GameTarget {
  const GameTarget({
    required this.name,
    this.brandName,
    this.category,
    this.verdict,
    this.verdictScore,
    this.shortExplanation,
    this.slug,
  });

  factory GameTarget.fromJson(Map<String, dynamic> json) => GameTarget(
    name: (json['name'] as String?)?.trim() ?? '',
    brandName: json['brand_name'] as String?,
    category: json['category'] as String?,
    verdict: Verdict.tryParse(json['verdict'] as String?),
    verdictScore: (json['verdict_score'] as num?)?.toInt(),
    shortExplanation: json['short_explanation'] as String?,
    slug: json['slug'] as String?,
  );

  final String name;
  final String? brandName;
  final String? category;
  final Verdict? verdict;
  final int? verdictScore;
  final String? shortExplanation;
  final String? slug;
}

/// One ingredient-list choice in a round.
class GameOption {
  const GameOption({
    required this.optionId,
    this.ingredients = const <String>[],
    this.isCorrect = false,
  });

  factory GameOption.fromJson(Map<String, dynamic> json) => GameOption(
    optionId: json['option_id']?.toString() ?? '',
    ingredients:
        (json['ingredients'] as List?)
            ?.map((dynamic e) => e.toString())
            .toList() ??
        const <String>[],
    isCorrect: json['is_correct'] == true,
  );

  final String optionId;
  final List<String> ingredients;
  final bool isCorrect;
}

/// `GET /api/game/lineup` — a target product + 4 ingredient-list options.
class GameRound {
  const GameRound({required this.target, this.options = const <GameOption>[]});

  factory GameRound.fromJson(Map<String, dynamic> json) => GameRound(
    target: GameTarget.fromJson(
      (json['target'] as Map<String, dynamic>?) ?? const <String, dynamic>{},
    ),
    options:
        (json['options'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(GameOption.fromJson)
            .toList() ??
        const <GameOption>[],
  );

  final GameTarget target;
  final List<GameOption> options;
}

/// A leaderboard row (`GET /api/game/leaderboard`).
class LeaderboardEntry {
  const LeaderboardEntry({required this.name, this.score = 0, this.streak = 0});

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) =>
      LeaderboardEntry(
        name: json['name']?.toString() ?? '',
        score: (json['score'] as num?)?.toInt() ?? 0,
        streak: (json['streak'] as num?)?.toInt() ?? 0,
      );

  final String name;
  final int score;
  final int streak;
}

/// `POST /api/game/score` result.
class ScoreResult {
  const ScoreResult({required this.name, this.score = 0, this.rank});

  factory ScoreResult.fromJson(Map<String, dynamic> json) => ScoreResult(
    name: json['name']?.toString() ?? '',
    score: (json['score'] as num?)?.toInt() ?? 0,
    rank: (json['rank'] as num?)?.toInt(),
  );

  final String name;
  final int score;
  final int? rank;
}
