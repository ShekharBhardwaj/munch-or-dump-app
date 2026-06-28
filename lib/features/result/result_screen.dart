import 'package:flutter/material.dart';
import 'package:munch_or_dump/core/models/analysis_result.dart';
import 'package:munch_or_dump/core/theme/verdict_palette.dart';

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

    final theme = Theme.of(context);
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
          children: <Widget>[
            _VerdictHero(result: data, color: color),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if ((data.shortExplanation ?? '').isNotEmpty) ...<Widget>[
                    const SizedBox(height: 16),
                    Text(
                      data.shortExplanation!,
                      style: theme.textTheme.titleMedium,
                    ),
                  ],
                  if (data.hasProfileNote) _ForYouCard(note: data.profileNote!),
                  if (data.verdictReasons.isNotEmpty)
                    _Section(
                      title: 'Why',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          for (final reason in data.verdictReasons)
                            _Bullet(text: reason, color: color),
                        ],
                      ),
                    ),
                  if (data.ingredientsDetected.isNotEmpty)
                    _Section(
                      title: 'Ingredients',
                      child: Column(
                        children: <Widget>[
                          for (final ingredient in data.ingredientsDetected)
                            _IngredientRow(ingredient: ingredient),
                        ],
                      ),
                    ),
                  if (data.marketingClaims.isNotEmpty)
                    _Section(
                      title: 'Marketing claims',
                      child: Column(
                        children: <Widget>[
                          for (final claim in data.marketingClaims)
                            _ClaimRow(claim: claim),
                        ],
                      ),
                    ),
                  _DietaryTags(result: data),
                  if ((data.consumptionContext ?? '').isNotEmpty)
                    _Section(
                      title: 'Bottom line',
                      child: Text(data.consumptionContext!),
                    ),
                ],
              ),
            ),
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
    return Container(
      width: double.infinity,
      color: color.withValues(alpha: 0.10),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (result.brand != null)
            Text(
              result.brand!,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text(result.verdict.emoji, style: const TextStyle(fontSize: 44)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  result.verdict.label.toUpperCase(),
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: color,
                    letterSpacing: -1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Text(
                '${result.verdictScore}',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              Text(
                ' / 90',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
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
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (result.verdictScore / 90).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          if ((result.confidence ?? '').isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              '${result.confidence} confidence',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
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
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.person,
                size: 18,
                color: theme.colorScheme.onSecondaryContainer,
              ),
              const SizedBox(width: 6),
              Text(
                'For you',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            note,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSecondaryContainer,
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
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
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
                : const Color(0xFF10B981),
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
                  Text(
                    claim.reality!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
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
    return _Section(
      title: 'Dietary',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: <Widget>[for (final tag in tags) Chip(label: Text(tag))],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
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
            padding: const EdgeInsets.only(top: 6, right: 10),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ),
          Expanded(child: Text(text)),
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
        color: color.withValues(alpha: 0.15),
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
  SafetyRating.safe => const Color(0xFF10B981),
  SafetyRating.moderate => const Color(0xFFF59E0B),
  SafetyRating.concerning => const Color(0xFFF97316),
  SafetyRating.harmful => const Color(0xFFEF4444),
};
