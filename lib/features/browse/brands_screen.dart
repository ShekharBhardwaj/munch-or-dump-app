import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:munch_or_dump/core/models/catalog.dart';
import 'package:munch_or_dump/core/providers.dart';
import 'package:munch_or_dump/core/router/routes.dart';
import 'package:munch_or_dump/core/widgets/async_states.dart';
import 'package:munch_or_dump/core/widgets/editorial.dart';
import 'package:munch_or_dump/core/widgets/product_row.dart';

final brandsProvider =
    FutureProvider.autoDispose<({List<BrandSummary> items, bool gated})>((ref) {
      return ref.watch(munchApiProvider).getBrands();
    });

final brandProvider = FutureProvider.autoDispose.family<BrandDetail, String>((
  ref,
  slug,
) {
  return ref.watch(munchApiProvider).getBrand(slug);
});

class BrandsScreen extends ConsumerWidget {
  const BrandsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brands = ref.watch(brandsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Brands')),
      body: brands.when(
        loading: () => const PageLoader(),
        error: (error, _) => ErrorRetry(
          message: errorMessage(error),
          onRetry: () => ref.invalidate(brandsProvider),
        ),
        data: (data) {
          if (data.items.isEmpty) {
            return const EmptyState(
              icon: Icons.storefront_outlined,
              message: 'No brands yet.',
            );
          }
          return ListView.separated(
            itemCount: data.items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final b = data.items[i];
              return ListTile(
                title: Text(
                  b.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text('${b.productCount} products'),
                trailing: b.avgScore != null
                    ? Text(
                        'avg ${b.avgScore}',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                      )
                    : null,
                onTap: () => context.pushNamed(
                  Routes.brand,
                  pathParameters: <String, String>{'slug': b.slug},
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class BrandScreen extends ConsumerWidget {
  const BrandScreen({required this.slug, super.key});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brand = ref.watch(brandProvider(slug));
    return Scaffold(
      appBar: AppBar(title: Text(brand.valueOrNull?.name ?? 'Brand')),
      body: brand.when(
        loading: () => const PageLoader(),
        error: (error, _) => ErrorRetry(
          message: errorMessage(error),
          onRetry: () => ref.invalidate(brandProvider(slug)),
        ),
        data: (data) {
          if (data.products.isEmpty) {
            return const EmptyState(
              icon: Icons.inventory_2_outlined,
              message: 'No products for this brand yet.',
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
