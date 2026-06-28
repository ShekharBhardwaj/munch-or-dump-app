import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:munch_or_dump/core/models/analysis_result.dart';
import 'package:munch_or_dump/core/models/catalog.dart';
import 'package:munch_or_dump/core/providers.dart';
import 'package:munch_or_dump/core/widgets/async_states.dart';
import 'package:munch_or_dump/core/widgets/product_row.dart';

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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorRetry(
          message: '$error',
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

class _IngredientBody extends StatelessWidget {
  const _IngredientBody({required this.ingredient});

  final IngredientDetail ingredient;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rating = SafetyRating.fromApi(ingredient.safetyRating);
    final color = _safetyColor(rating);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: <Widget>[
        Row(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                rating.label,
                style: TextStyle(color: color, fontWeight: FontWeight.w700),
              ),
            ),
            if (ingredient.eNumber != null) ...<Widget>[
              const SizedBox(width: 8),
              Chip(label: Text(ingredient.eNumber!)),
            ],
            if (ingredient.isAdditive) ...<Widget>[
              const SizedBox(width: 8),
              const Chip(label: Text('Additive')),
            ],
          ],
        ),
        if ((ingredient.description ?? '').isNotEmpty) ...<Widget>[
          const SizedBox(height: 16),
          Text(ingredient.description!, style: theme.textTheme.bodyLarge),
        ],
        if (ingredient.healthEffects.isNotEmpty)
          _Section(
            title: 'Health effects',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                for (final effect in ingredient.healthEffects)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Text('• $effect'),
                  ),
              ],
            ),
          ),
        if (ingredient.avoidIf.isNotEmpty)
          _Section(
            title: 'Avoid if',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final a in ingredient.avoidIf) Chip(label: Text(a)),
              ],
            ),
          ),
        if (ingredient.products.isNotEmpty) ...<Widget>[
          const SizedBox(height: 24),
          Text(
            'Found in',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          for (final p in ingredient.products) ProductRow(item: p),
        ],
      ],
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

Color _safetyColor(SafetyRating rating) => switch (rating) {
  SafetyRating.safe => const Color(0xFF10B981),
  SafetyRating.moderate => const Color(0xFFF59E0B),
  SafetyRating.concerning => const Color(0xFFF97316),
  SafetyRating.harmful => const Color(0xFFEF4444),
};
