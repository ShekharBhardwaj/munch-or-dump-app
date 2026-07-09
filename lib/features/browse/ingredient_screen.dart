import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:munch_or_dump/core/models/analysis_result.dart';
import 'package:munch_or_dump/core/models/catalog.dart';
import 'package:munch_or_dump/core/providers.dart';
import 'package:munch_or_dump/core/theme/app_colors.dart';
import 'package:munch_or_dump/core/widgets/async_states.dart';
import 'package:munch_or_dump/core/widgets/editorial.dart';
import 'package:munch_or_dump/core/widgets/product_row.dart';
import 'package:munch_or_dump/features/auth/sign_in_prompts.dart';

final ingredientProvider = FutureProvider.autoDispose
    .family<IngredientDetail?, String>((ref, slug) {
      return ref.watch(munchApiProvider).getIngredient(slug);
    });

class IngredientScreen extends ConsumerWidget {
  const IngredientScreen({required this.slug, super.key});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ingredient = ref.watch(ingredientProvider(slug));
    return Scaffold(
      appBar: AppBar(title: Text(ingredient.valueOrNull?.name ?? 'Ingredient')),
      body: ingredient.when(
        loading: () => const _IngredientSkeleton(),
        error: (error, _) => ErrorRetry(
          message: errorMessage(error),
          onRetry: () => ref.invalidate(ingredientProvider(slug)),
        ),
        data: (data) {
          if (data == null) {
            return const EmptyState(
              icon: Icons.science_outlined,
              message: 'We don’t have details on this ingredient yet.',
            );
          }
          return _IngredientBody(ingredient: data);
        },
      ),
    );
  }
}

/// Shimmering placeholder shaped like [_IngredientBody]: the safety-tier
/// header card, a few description lines, then "found in" product rows.
class _IngredientSkeleton extends StatelessWidget {
  const _IngredientSkeleton();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading',
      child: ExcludeSemantics(
        child: Shimmer(
          child: ListView(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: const <Widget>[
              ShimmerBox(height: 148, radius: 16),
              SizedBox(height: 24),
              ShimmerBox(height: 14, radius: 7),
              SizedBox(height: 10),
              ShimmerBox(height: 14, radius: 7),
              SizedBox(height: 10),
              FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: 0.62,
                child: ShimmerBox(height: 14, radius: 7),
              ),
              SizedBox(height: 32),
              FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: 0.34,
                child: ShimmerBox(height: 11, radius: 6),
              ),
              SizedBox(height: 16),
              ShimmerBox(height: 12, radius: 6),
              SizedBox(height: 14),
              ShimmerBox(height: 12, radius: 6),
              SizedBox(height: 14),
              FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: 0.72,
                child: ShimmerBox(height: 12, radius: 6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IngredientBody extends StatelessWidget {
  const _IngredientBody({required this.ingredient});

  final IngredientDetail ingredient;

  @override
  Widget build(BuildContext context) {
    final rating = SafetyRating.fromApi(ingredient.safetyRating);
    final color = _safetyColor(rating);
    final desc = ingredient.description ?? '';
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: <Widget>[
        // Safety-tier header: the rating is the headline, not a footnote.
        AccentTopBorderCard(
          accent: color,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  ConcernDot(
                    color: color,
                    size: 11,
                    semanticLabel: '${rating.label} safety rating',
                  ),
                  const SizedBox(width: 10),
                  Text(
                    rating.label,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: AppColors.inkPrimary,
                    ),
                  ),
                  const Spacer(),
                  if (ingredient.eNumber != null)
                    MetaPill(
                      text: ingredient.eNumber!,
                      fg: AppColors.inkSecondary,
                      bg: AppColors.surfaceAlt,
                      border: AppColors.hairline,
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                _safetyBlurb(rating),
                style: const TextStyle(
                  fontSize: 13.5,
                  height: 1.45,
                  color: AppColors.inkSecondary,
                ),
              ),
              if (ingredient.isAdditive) ...<Widget>[
                const SizedBox(height: 12),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: MetaPill(
                    text: 'Additive',
                    fg: AppColors.inkSecondary,
                    bg: AppColors.surfaceAlt,
                    border: AppColors.hairline,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (desc.isNotEmpty) ...<Widget>[
          const SizedBox(height: 20),
          Text(
            desc,
            style: const TextStyle(
              fontSize: 16,
              height: 1.55,
              color: AppColors.inkPrimary,
            ),
          ),
        ],
        if (ingredient.healthEffects.isNotEmpty) ...<Widget>[
          const SizedBox(height: 28),
          const Eyebrow('Health effects', spacing: 4.2),
          const SizedBox(height: 12),
          for (final effect in ingredient.healthEffects)
            _EffectBullet(text: effect, color: color),
        ],
        if (ingredient.avoidIf.isNotEmpty) ...<Widget>[
          const SizedBox(height: 28),
          const Eyebrow('Avoid if', spacing: 4.2),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final a in ingredient.avoidIf)
                MetaPill(
                  text: a,
                  fg: AppColors.concernHigh,
                  bg: AppColors.concernHighTint,
                  border: AppColors.concernHighTint,
                ),
            ],
          ),
        ],
        if (ingredient.products.isNotEmpty) ...<Widget>[
          const SizedBox(height: 28),
          const Eyebrow('Found in', spacing: 4.2),
          const SizedBox(height: 8),
          for (final p in ingredient.products) ProductRow(item: p),
          if (ingredient.gated)
            SignInGate(
              shown: ingredient.products.length,
              unit: 'products',
              fullLabel: 'every product with this ingredient',
            ),
        ],
      ],
    );
  }
}

class _EffectBullet extends StatelessWidget {
  const _EffectBullet({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 7, right: 12),
            child: ConcernDot(color: color, size: 6),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14.5,
                height: 1.5,
                color: AppColors.inkPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _safetyBlurb(SafetyRating rating) => switch (rating) {
  SafetyRating.safe => 'Generally recognized as safe.',
  SafetyRating.moderate => 'Fine in moderation — worth knowing about.',
  SafetyRating.concerning => 'Some evidence raises concerns.',
  SafetyRating.harmful => 'Best avoided where you can.',
};

Color _safetyColor(SafetyRating rating) => switch (rating) {
  SafetyRating.safe => const Color(0xFF10B981),
  SafetyRating.moderate => const Color(0xFFF59E0B),
  SafetyRating.concerning => const Color(0xFFF97316),
  SafetyRating.harmful => const Color(0xFFEF4444),
};
