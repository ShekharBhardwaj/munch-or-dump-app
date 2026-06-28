import 'package:json_annotation/json_annotation.dart';
import 'package:munch_or_dump/core/models/verdict.dart';

part 'analysis_result.g.dart';

/// Maps the API's `verdict` string ↔ the [Verdict] enum for json_serializable.
class VerdictJson implements JsonConverter<Verdict, String> {
  const VerdictJson();

  @override
  Verdict fromJson(String json) => Verdict.fromApi(json);

  @override
  String toJson(Verdict object) => object.apiValue;
}

/// How risky a single ingredient is, per the analysis.
enum SafetyRating {
  safe('safe', 'Safe'),
  moderate('moderate', 'Moderate'),
  concerning('concerning', 'Concerning'),
  harmful('harmful', 'Harmful');

  const SafetyRating(this.apiValue, this.label);

  final String apiValue;
  final String label;

  /// Accepts both API vocabularies: `/api/analyze` uses
  /// safe|moderate|concerning|harmful; `/api/scans` and `/api/products` use
  /// LOW|MEDIUM|HIGH|CRITICAL (higher = worse).
  static SafetyRating fromApi(String? value) {
    return switch ((value ?? '').trim().toLowerCase()) {
      'safe' || 'low' => SafetyRating.safe,
      'moderate' || 'medium' => SafetyRating.moderate,
      'concerning' || 'high' => SafetyRating.concerning,
      'harmful' || 'critical' => SafetyRating.harmful,
      _ => SafetyRating.moderate,
    };
  }
}

/// A full product analysis from `POST /api/analyze` (the success case). Only the
/// fields the app renders are modeled; json_serializable ignores the rest.
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class AnalysisResult {
  const AnalysisResult({
    required this.verdict,
    required this.verdictScore,
    required this.productName,
    this.brandName,
    this.category,
    this.productSlug,
    this.confidence,
    this.shortExplanation,
    this.detailedAnalysis,
    this.verdictReasons = const <String>[],
    this.ingredientsDetected = const <AnalyzedIngredient>[],
    this.marketingClaims = const <MarketingClaim>[],
    this.nutritionSummary,
    this.avoidIf = const <String>[],
    this.bestFor,
    this.consumptionContext,
    this.profileNote,
    this.cacheHit = false,
    this.barcode,
    this.novaGroup,
    this.offData,
    this.isVegan = false,
    this.isVegetarian = false,
    this.isGlutenFree = false,
    this.isDairyFree = false,
    this.containsNuts = false,
    this.containsSoy = false,
    this.containsEggs = false,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) =>
      _$AnalysisResultFromJson(json);

  @VerdictJson()
  final Verdict verdict;
  final int verdictScore;

  // The API may emit `product_name: null` (the LLM runs in JSON mode, not strict
  // schema); default to '' so a valid analysis never crashes deserialization.
  @JsonKey(defaultValue: '')
  final String productName;
  final String? brandName;
  final String? category;
  final String? productSlug;
  final String? confidence;
  final String? shortExplanation;
  final String? detailedAnalysis;
  final List<String> verdictReasons;
  final List<AnalyzedIngredient> ingredientsDetected;
  final List<MarketingClaim> marketingClaims;
  final Map<String, dynamic>? nutritionSummary;
  final List<String> avoidIf;
  final String? bestFor;
  final String? consumptionContext;
  final String? profileNote;
  final bool cacheHit;
  final String? barcode;
  final int? novaGroup;
  final Map<String, dynamic>? offData;
  final bool isVegan;
  final bool isVegetarian;
  final bool isGlutenFree;
  final bool isDairyFree;
  final bool containsNuts;
  final bool containsSoy;
  final bool containsEggs;

  Map<String, dynamic> toJson() => _$AnalysisResultToJson(this);

  /// Nutrition facts as display strings, dropping null/empty entries.
  Map<String, String> get nutritionFacts {
    final summary = nutritionSummary;
    if (summary == null) return const <String, String>{};
    final out = <String, String>{};
    summary.forEach((key, value) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) out[key] = text;
    });
    return out;
  }

  bool get hasProfileNote =>
      profileNote != null && profileNote!.trim().isNotEmpty;

  /// The brand to display. The analyze response doesn't emit `brand_name`, so
  /// fall back to the Open Food Facts brand carried in `off_data`.
  String? get brand {
    final named = brandName?.trim() ?? '';
    if (named.isNotEmpty) return named;
    final off = offData?['brand']?.toString().trim() ?? '';
    return off.isEmpty ? null : off;
  }
}

@JsonSerializable(fieldRename: FieldRename.snake)
class AnalyzedIngredient {
  const AnalyzedIngredient({
    required this.name,
    this.safetyRating = 'moderate',
    this.explanation,
    this.impactScore,
  });

  factory AnalyzedIngredient.fromJson(Map<String, dynamic> json) =>
      _$AnalyzedIngredientFromJson(json);

  final String name;
  final String safetyRating;
  final String? explanation;
  final int? impactScore;

  Map<String, dynamic> toJson() => _$AnalyzedIngredientToJson(this);

  SafetyRating get rating => SafetyRating.fromApi(safetyRating);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class MarketingClaim {
  const MarketingClaim({
    required this.claim,
    this.reality,
    this.isMisleading = false,
  });

  factory MarketingClaim.fromJson(Map<String, dynamic> json) =>
      _$MarketingClaimFromJson(json);

  final String claim;
  final String? reality;
  final bool isMisleading;

  Map<String, dynamic> toJson() => _$MarketingClaimToJson(this);
}

/// Outcome of an analyze call. The verdict result, "not found" (barcode missing
/// from Open Food Facts), or "unsupported" (not a food/beverage). Transport and
/// auth failures surface as [ApiException] instead.
sealed class AnalyzeOutcome {
  const AnalyzeOutcome();
}

class AnalyzeSuccess extends AnalyzeOutcome {
  const AnalyzeSuccess(this.result);
  final AnalysisResult result;
}

class AnalyzeNotFound extends AnalyzeOutcome {
  const AnalyzeNotFound(this.barcode);
  final String? barcode;
}

class AnalyzeUnsupported extends AnalyzeOutcome {
  const AnalyzeUnsupported(this.message);
  final String message;
}
