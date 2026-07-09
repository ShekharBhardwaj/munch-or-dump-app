import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:munch_or_dump/core/models/analysis_result.dart';
import 'package:munch_or_dump/core/providers.dart';
import 'package:munch_or_dump/core/utils/cache_for.dart';
import 'package:munch_or_dump/core/widgets/async_states.dart';
import 'package:munch_or_dump/core/widgets/editorial.dart';
import 'package:munch_or_dump/features/result/result_screen.dart';

/// Canonical product detail by slug. The response shares the analyze verdict
/// fields, so it renders through the same [ResultScreen].
///
/// The product endpoint emits its slug as `slug`, not the analyze response's
/// `product_slug`, so [AnalysisResult.productSlug] comes back null — which
/// hides Save/Follow in `ResultActions` and drops the share link. Patch the
/// route's slug in so the product page gets the full action row.
final productProvider = FutureProvider.autoDispose
    .family<AnalysisResult, String>((ref, slug) async {
      ref.cacheFor(const Duration(minutes: 5));
      final result = await ref.watch(munchApiProvider).getProduct(slug);
      if (result.productSlug?.trim().isNotEmpty ?? false) return result;
      return AnalysisResult.fromJson(<String, dynamic>{
        ...result.toJson(),
        'product_slug': slug,
      });
    });

class ProductScreen extends ConsumerWidget {
  const ProductScreen({required this.slug, super.key});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final product = ref.watch(productProvider(slug));
    return product.when(
      data: (result) => ResultScreen(result: result),
      loading: () => const Scaffold(body: PageLoader()),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: ErrorRetry(
          message: errorMessage(error),
          onRetry: () => ref.invalidate(productProvider(slug)),
        ),
      ),
    );
  }
}
