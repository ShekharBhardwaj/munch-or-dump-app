import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:munch_or_dump/core/models/analysis_result.dart';
import 'package:munch_or_dump/core/router/routes.dart';
import 'package:munch_or_dump/core/theme/app_colors.dart';
import 'package:munch_or_dump/core/theme/verdict_palette.dart';
import 'package:munch_or_dump/core/widgets/verdict_badge.dart';
import 'package:munch_or_dump/features/result/result_actions.dart';

/// The verdict result — the app's headline screen. Renders the analysis from
/// `/api/analyze`: verdict + score, reasons, ingredient breakdown, marketing
/// claims, dietary tags, and the personalized "For You" note.
class ResultScreen extends StatelessWidget {
  const ResultScreen({required this.result, super.key});

  final AnalysisResult? result;

  @override
  Widget build(BuildContext context) {
    final data = result;
    if (data == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Result')),
        body: const Center(child: Text('No result to show — scan a product.')),
      );
    }

    final color = context.verdicts.colorFor(data.verdict);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          data.productName.isEmpty ? 'Verdict' : data.productName,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: <Widget>[
            _VerdictHero(result: data, color: color),
            if (data.hasProfileNote) ...<Widget>[
              const SizedBox(height: 12),
              _ForYouCard(note: data.profileNote!),
            ],
            if (data.verdictReasons.isNotEmpty) ...<Widget>[
              const SizedBox(height: 12),
              _ResultCard(
                title: 'Why',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    for (final reason in data.verdictReasons)
                      _Bullet(text: reason, color: color),
                  ],
                ),
              ),
            ],
            if (data.ingredientsDetected.isNotEmpty) ...<Widget>[
              const SizedBox(height: 12),
              _ResultCard(
                title: 'Ingredients',
                child: Column(
                  children: <Widget>[
                    for (final ingredient in data.ingredientsDetected)
                      _IngredientRow(ingredient: ingredient),
                  ],
                ),
              ),
            ],
            if (data.marketingClaims.isNotEmpty) ...<Widget>[
              const SizedBox(height: 12),
              _ResultCard(
                title: 'Marketing claims',
                child: Column(
                  children: <Widget>[
                    for (final claim in data.marketingClaims)
                      _ClaimRow(claim: claim),
                  ],
                ),
              ),
            ],
            _DietaryTags(result: data),
            if ((data.consumptionContext ?? '').isNotEmpty) ...<Widget>[
              const SizedBox(height: 12),
              _ResultCard(
                title: 'Bottom line',
                child: Text(data.consumptionContext!),
              ),
            ],
            if (data.alternatives.isNotEmpty) ...<Widget>[
              const SizedBox(height: 12),
              _ResultCard(
                title: 'Better alternatives',
                child: Column(
                  children: <Widget>[
                    for (final alt in data.alternatives)
                      _AlternativeRow(alt: alt),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            ResultActions(result: data),
          ],
        ),
      ),
    );
  }
}

class _VerdictHero extends StatelessWidget {
  const _VerdictHero({required this.result, required this.color});

  final AnalysisResult result;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lead = result.shortExplanation ?? '';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.hairline),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              _ScoreRing(score: result.verdictScore, color: color),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (result.brand != null && result.brand!.isNotEmpty)
                      Text(
                        result.brand!.toUpperCase(),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: AppColors.inkMuted,
                          letterSpacing: 0.6,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          result.verdict.emoji,
                          style: const TextStyle(fontSize: 30),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              result.verdict.label.toUpperCase(),
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: color,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (result.cacheHit)
                      _Pill(label: 'Instant', icon: Icons.bolt, color: color)
                    else
                      _Pill(
                        label: 'Fresh analysis',
                        icon: Icons.auto_awesome,
                        color: color,
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (lead.isNotEmpty) ...<Widget>[
            const SizedBox(height: 18),
            Text(
              lead,
              style: theme.textTheme.titleMedium?.copyWith(height: 1.4),
            ),
          ],
          if ((result.confidence ?? '').isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              '${result.confidence} confidence',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.inkMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A circular score gauge — verdict-colored arc over a hairline track, with the
/// score centered. More premium than a flat bar.
class _ScoreRing extends StatelessWidget {
  const _ScoreRing({required this.score, required this.color});

  final int score;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 84,
      height: 84,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          SizedBox(
            width: 84,
            height: 84,
            child: CircularProgressIndicator(
              value: (score / 90).clamp(0.0, 1.0),
              strokeWidth: 7,
              strokeCap: StrokeCap.round,
              backgroundColor: AppColors.hairline,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                '$score',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: AppColors.inkPrimary,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              Text(
                '/ 90',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.inkMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ForYouCard extends StatelessWidget {
  const _ForYouCard({required this.note});

  final String note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFE7F4EE),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.person_outline,
                size: 18,
                color: AppColors.brandDeep,
              ),
              const SizedBox(width: 6),
              Text(
                'For you',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppColors.brandDeep,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            note,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.brandDeep,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _IngredientRow extends StatelessWidget {
  const _IngredientRow({required this.ingredient});

  final AnalyzedIngredient ingredient;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _safetyColor(ingredient.rating);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            margin: const EdgeInsets.only(top: 5),
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        ingredient.name,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      ingredient.rating.label,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: color,
                      ),
                    ),
                  ],
                ),
                if ((ingredient.explanation ?? '').isNotEmpty)
                  Text(
                    ingredient.explanation!,
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ClaimRow extends StatelessWidget {
  const _ClaimRow({required this.claim});

  final MarketingClaim claim;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            claim.isMisleading
                ? Icons.warning_amber
                : Icons.check_circle_outline,
            size: 18,
            color: claim.isMisleading
                ? const Color(0xFFF97316)
                : AppColors.brand,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '“${claim.claim}”',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if ((claim.reality ?? '').isNotEmpty)
                  Text(claim.reality!, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DietaryTags extends StatelessWidget {
  const _DietaryTags({required this.result});

  final AnalysisResult result;

  @override
  Widget build(BuildContext context) {
    final tags = <String>[
      if (result.isVegan) 'Vegan',
      if (result.isVegetarian && !result.isVegan) 'Vegetarian',
      if (result.isGlutenFree) 'Gluten-free',
      if (result.isDairyFree) 'Dairy-free',
      if (result.containsNuts) 'Contains nuts',
      if (result.containsSoy) 'Contains soy',
      if (result.containsEggs) 'Contains eggs',
    ];
    if (tags.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: _ResultCard(
        title: 'Dietary',
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[for (final tag in tags) Chip(label: Text(tag))],
        ),
      ),
    );
  }
}

class _AlternativeRow extends StatelessWidget {
  const _AlternativeRow({required this.alt});

  final Alternative alt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final verdict = alt.verdict;
    final delta = alt.scoreDelta;
    final brand = alt.brandName;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        alt.name.trim().isEmpty ? alt.slug : alt.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: brand != null && brand.isNotEmpty
          ? Text(brand, maxLines: 1, overflow: TextOverflow.ellipsis)
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (delta != null && delta > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                '+$delta',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppColors.brand,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          if (verdict != null) VerdictBadge(verdict: verdict, score: alt.score),
        ],
      ),
      onTap: alt.slug.isEmpty
          ? null
          : () => context.pushNamed(
              Routes.product,
              pathParameters: <String, String>{'slug': alt.slug},
            ),
    );
  }
}

/// A white section card on the paper canvas — the calm surface the result is
/// built from.
class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 7, right: 10),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ),
          Expanded(child: Text(text, style: const TextStyle(height: 1.45))),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.icon, required this.color});

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

Color _safetyColor(SafetyRating rating) => switch (rating) {
  SafetyRating.safe => AppColors.brand,
  SafetyRating.moderate => const Color(0xFFE0A317),
  SafetyRating.concerning => const Color(0xFFF97316),
  SafetyRating.harmful => const Color(0xFFEF4444),
};
