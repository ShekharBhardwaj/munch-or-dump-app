import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:munch_or_dump/core/models/catalog.dart';
import 'package:munch_or_dump/core/providers.dart';
import 'package:munch_or_dump/core/router/routes.dart';
import 'package:munch_or_dump/core/widgets/async_states.dart';
import 'package:munch_or_dump/core/widgets/product_row.dart';

final categoriesProvider =
    FutureProvider.autoDispose<({List<CategorySummary> items, bool gated})>((
      ref,
    ) {
      return ref.watch(munchApiProvider).getCategories();
    });

final categoryProvider = FutureProvider.autoDispose
    .family<CategoryDetail, String>((ref, slug) {
      return ref.watch(munchApiProvider).getCategory(slug);
    });

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: categories.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorRetry(
          message: errorMessage(error),
          onRetry: () => ref.invalidate(categoriesProvider),
        ),
        data: (data) {
          if (data.items.isEmpty) {
            return const EmptyState(
              icon: Icons.category_outlined,
              message: 'No categories yet.',
            );
          }
          return ListView.separated(
            itemCount: data.items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final c = data.items[i];
              return ListTile(
                title: Text(
                  c.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text('${c.productCount} products'),
                trailing: c.avgScore != null
                    ? _ScorePill(score: c.avgScore!)
                    : null,
                onTap: () => context.pushNamed(
                  Routes.category,
                  pathParameters: <String, String>{'slug': c.slug},
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class CategoryScreen extends ConsumerWidget {
  const CategoryScreen({required this.slug, super.key});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = ref.watch(categoryProvider(slug));
    return Scaffold(
      appBar: AppBar(title: Text(category.valueOrNull?.label ?? 'Category')),
      body: category.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorRetry(
          message: errorMessage(error),
          onRetry: () => ref.invalidate(categoryProvider(slug)),
        ),
        data: (data) {
          if (data.products.isEmpty) {
            return const EmptyState(
              icon: Icons.inventory_2_outlined,
              message: 'No products in this category yet.',
            );
          }
          return ListView.separated(
            itemCount: data.products.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) => ProductRow(item: data.products[i]),
          );
        },
      ),
    );
  }
}

class _ScorePill extends StatelessWidget {
  const _ScorePill({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      'avg $score',
      style: theme.textTheme.labelMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
