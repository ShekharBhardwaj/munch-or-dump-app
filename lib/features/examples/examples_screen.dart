import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:munch_or_dump/core/models/catalog.dart';
import 'package:munch_or_dump/core/models/verdict.dart';
import 'package:munch_or_dump/core/providers.dart';
import 'package:munch_or_dump/core/router/routes.dart';
import 'package:munch_or_dump/core/theme/app_colors.dart';
import 'package:munch_or_dump/core/theme/verdict_palette.dart';
import 'package:munch_or_dump/core/utils/country_flag.dart';
import 'package:munch_or_dump/core/widgets/async_states.dart';
import 'package:munch_or_dump/core/widgets/editorial.dart';

/// One live product per verdict, fetched in parallel. Best-effort: a verdict
/// with no product (or a transient error) simply resolves to null so the rest
/// of the legend still renders — the definitions are the point, the examples
/// are the proof.
final verdictExamplesProvider =
    FutureProvider.autoDispose<Map<Verdict, ProductListItem?>>((ref) async {
      final api = ref.watch(munchApiProvider);
      final entries = await Future.wait(
        Verdict.values.map((v) async {
          try {
            final res = await api.searchProducts(verdict: v.apiValue, limit: 1);
            return MapEntry<Verdict, ProductListItem?>(
              v,
              res.items.isEmpty ? null : res.items.first,
            );
          } catch (_) {
            return MapEntry<Verdict, ProductListItem?>(v, null);
          }
        }),
      );
      return Map<Verdict, ProductListItem?>.fromEntries(entries);
    });

const Map<Verdict, String> _verdictTagline = <Verdict, String>{
  Verdict.munch: 'Real food.',
  Verdict.okay: 'Fine to eat.',
  Verdict.treat: 'Now and then.',
  Verdict.engineered: 'Lab-built.',
  Verdict.dump: 'Skip it.',
  Verdict.bullshit: 'Pure deception.',
};

const Map<Verdict, String> _verdictDef = <Verdict, String>{
  Verdict.munch: 'A short, real-food ingredient list with nothing to hide.',
  Verdict.okay: 'A few things worth noting, but nothing alarming.',
  Verdict.treat: 'Enjoyable now and then — just not everyday fuel.',
  Verdict.engineered: 'A formula assembled from additives, not a recipe.',
  Verdict.dump: 'Red-flag ingredients you’re better off without.',
  Verdict.bullshit:
      'The label promises one thing; the ingredients say another.',
};

/// The verdict scale, explained — one card per verdict with its meaning and a
/// real product that earned it. Reachable from Browse; open to everyone.
class ExamplesScreen extends ConsumerWidget {
  const ExamplesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final examples = ref.watch(verdictExamplesProvider);
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: GridBackground(
        child: SafeArea(
          top: false,
          child: examples.when(
            loading: () => const PageLoader(),
            error: (error, _) => ErrorRetry(
              message: errorMessage(error),
              onRetry: () => ref.invalidate(verdictExamplesProvider),
            ),
            data: (map) => ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
              children: <Widget>[
                const Eyebrow('The scale', spacing: 3.6),
                const SizedBox(height: 12),
                const TwoToneHeadline(
                  dark: 'Six ways to',
                  muted: 'read a label.',
                  size: 30,
                  align: TextAlign.left,
                ),
                const SizedBox(height: 14),
                const Text(
                  'Every product lands on one of six verdicts — from real food '
                  'to pure marketing. Here’s what each one means, with a real '
                  'product that earned it.',
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.55,
                    color: AppColors.inkSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                for (final v in Verdict.values) ...<Widget>[
                  _VerdictExampleCard(verdict: v, example: map[v]),
                  const SizedBox(height: 14),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VerdictExampleCard extends StatelessWidget {
  const _VerdictExampleCard({required this.verdict, required this.example});

  final Verdict verdict;
  final ProductListItem? example;

  @override
  Widget build(BuildContext context) {
    final tone = verdictToneFor(verdict);
    final ex = example;
    final country = ex?.countryOfOrigin?.trim() ?? '';
    final flag = countryFlag(country);
    return AccentTopBorderCard(
      accent: tone.bar,
      padding: const EdgeInsets.all(20),
      onTap: ex == null
          ? null
          : () => context.pushNamed(
              Routes.product,
              pathParameters: <String, String>{'slug': ex.slug},
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              WebVerdictBadge(verdict: verdict, size: 11),
              const Spacer(),
              Text(
                _verdictTagline[verdict] ?? '',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: tone.word,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _verdictDef[verdict] ?? '',
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppColors.inkSecondary,
            ),
          ),
          if (ex != null) ...<Widget>[
            const SizedBox(height: 16),
            const Divider(height: 1, color: AppColors.hairlineFaint),
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          if (flag != null) ...<Widget>[
                            Semantics(
                              label: country,
                              child: ExcludeSemantics(
                                child: Text(
                                  flag,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          const Eyebrow('Example', size: 10, spacing: 2),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        ex.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.inkPrimary,
                        ),
                      ),
                      if (_caption(ex).isNotEmpty) ...<Widget>[
                        const SizedBox(height: 3),
                        Text(
                          _caption(ex),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.inkFaint,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: AppColors.inkGhost,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _caption(ProductListItem ex) {
    final parts = <String>[];
    final brand = ex.brandName?.trim();
    if (brand != null && brand.isNotEmpty) parts.add(brand);
    if (ex.score != null) parts.add('Scored ${ex.score}/90');
    return parts.join(' · ');
  }
}
