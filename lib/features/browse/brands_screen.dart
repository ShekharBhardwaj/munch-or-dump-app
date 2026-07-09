import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:munch_or_dump/core/models/catalog.dart';
import 'package:munch_or_dump/core/providers.dart';
import 'package:munch_or_dump/core/router/routes.dart';
import 'package:munch_or_dump/core/widgets/async_states.dart';
import 'package:munch_or_dump/core/widgets/product_row.dart';
import 'package:munch_or_dump/features/auth/sign_in_prompts.dart';

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
        loading: () => const SkeletonList(rows: 10, showLeading: false),
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
            itemCount: data.items.length + (data.gated ? 1 : 0),
            separatorBuilder: (_, i) => data.gated && i == data.items.length - 1
                ? const SizedBox.shrink()
                : const Divider(height: 1),
            itemBuilder: (context, i) {
              if (data.gated && i == data.items.length) {
                return SignInGate(
                  shown: data.items.length,
                  unit: 'brands',
                  fullLabel: 'the full brand leaderboard',
                );
              }
              final b = data.items[i];
              return BrowseHubRow(
                label: b.name,
                sub: '${b.productCount} products',
                avgScore: b.avgScore,
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
        loading: () => const SkeletonList(showLeading: false),
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
            itemCount: data.products.length + (data.gated ? 1 : 0),
            separatorBuilder: (_, i) =>
                data.gated && i == data.products.length - 1
                ? const SizedBox.shrink()
                : const Divider(height: 1),
            itemBuilder: (context, i) {
              if (data.gated && i == data.products.length) {
                return SignInGate(
                  shown: data.products.length,
                  unit: 'products',
                  fullLabel: 'every product from this brand',
                );
              }
              return ProductRow(item: data.products[i]);
            },
          );
        },
      ),
    );
  }
}
