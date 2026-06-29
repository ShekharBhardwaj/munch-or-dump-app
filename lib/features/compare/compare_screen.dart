import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:munch_or_dump/core/models/analysis_result.dart';
import 'package:munch_or_dump/core/models/catalog.dart';
import 'package:munch_or_dump/core/widgets/verdict_badge.dart';
import 'package:munch_or_dump/features/browse/search_screen.dart';
import 'package:munch_or_dump/features/product/product_screen.dart';

/// Pick two products and compare their verdicts side by side. Each side fetches
/// the product detail (which carries the verdict fields).
class CompareScreen extends ConsumerStatefulWidget {
  const CompareScreen({this.initialSlug, super.key});

  final String? initialSlug;

  @override
  ConsumerState<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends ConsumerState<CompareScreen> {
  String? _a;
  String? _b;

  @override
  void initState() {
    super.initState();
    final slug = widget.initialSlug;
    _a = (slug != null && slug.isNotEmpty) ? slug : null;
  }

  Future<void> _pick({required bool isA}) async {
    final item = await Navigator.of(context).push<ProductListItem>(
      MaterialPageRoute<ProductListItem>(
        builder: (context) =>
            SearchScreen(onPick: (item) => Navigator.of(context).pop(item)),
      ),
    );
    if (item == null || item.slug.isEmpty || !mounted) return;
    // Force a refetch so re-picking a product that previously errored retries.
    ref.invalidate(productProvider(item.slug));
    setState(() => isA ? _a = item.slug : _b = item.slug);
  }

  @override
  Widget build(BuildContext context) {
    final aAsync = _a != null ? ref.watch(productProvider(_a!)) : null;
    final bAsync = _b != null ? ref.watch(productProvider(_b!)) : null;
    final aScore = aAsync?.valueOrNull?.verdictScore;
    final bScore = bAsync?.valueOrNull?.verdictScore;
    final aWins = aScore != null && bScore != null && aScore > bScore;
    final bWins = aScore != null && bScore != null && bScore > aScore;

    return Scaffold(
      appBar: AppBar(title: const Text('Compare')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: _Slot(
                async: aAsync,
                isWinner: aWins,
                onPick: () => _pick(isA: true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Slot(
                async: bAsync,
                isWinner: bWins,
                onPick: () => _pick(isA: false),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slot extends StatelessWidget {
  const _Slot({
    required this.async,
    required this.isWinner,
    required this.onPick,
  });

  final AsyncValue<AnalysisResult>? async;
  final bool isWinner;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = async;
    if (value == null) {
      return OutlinedButton.icon(
        onPressed: onPick,
        icon: const Icon(Icons.add),
        label: const Text('Pick a product'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 28),
        ),
      );
    }
    return value.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 28),
        child: SizedBox(
          height: 36,
          width: 36,
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, _) => OutlinedButton.icon(
        onPressed: onPick,
        icon: const Icon(Icons.refresh),
        label: const Text('Pick another'),
      ),
      data: (result) => Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isWinner
              ? const BorderSide(color: Color(0xFF10B981), width: 2)
              : BorderSide(color: theme.dividerColor),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (isWinner)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Better pick',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: const Color(0xFF10B981),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              Text(
                result.productName,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (result.brand != null)
                Text(
                  result.brand!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              const SizedBox(height: 12),
              VerdictBadge(verdict: result.verdict, score: result.verdictScore),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: <Widget>[
                  if (result.isVegan) const _Tag('Vegan'),
                  if (result.isGlutenFree) const _Tag('GF'),
                  if (result.isDairyFree) const _Tag('DF'),
                  if (result.containsNuts) const _Tag('Nuts'),
                ],
              ),
              const SizedBox(height: 8),
              TextButton(onPressed: onPick, child: const Text('Change')),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
