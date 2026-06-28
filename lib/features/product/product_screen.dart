import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:munch_or_dump/core/models/analysis_result.dart';
import 'package:munch_or_dump/core/providers.dart';
import 'package:munch_or_dump/core/widgets/async_states.dart';
import 'package:munch_or_dump/features/result/result_screen.dart';

/// Canonical product detail by slug. The response shares the analyze verdict
/// fields, so it renders through the same [ResultScreen].
final productProvider = FutureProvider.autoDispose
    .family<AnalysisResult, String>((ref, slug) {
      return ref.watch(munchApiProvider).getProduct(slug);
    });

class ProductScreen extends ConsumerWidget {
  const ProductScreen({required this.slug, super.key});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final product = ref.watch(productProvider(slug));
    return product.when(
      data: (result) => ResultScreen(result: result),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: ErrorRetry(
          message: '$error',
          onRetry: () => ref.invalidate(productProvider(slug)),
        ),
      ),
    );
  }
}
