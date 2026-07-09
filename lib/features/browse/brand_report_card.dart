import 'package:flutter/material.dart';
import 'package:munch_or_dump/core/models/catalog.dart';
import 'package:munch_or_dump/core/models/verdict.dart';
import 'package:munch_or_dump/core/theme/palette.dart';
import 'package:munch_or_dump/core/theme/verdict_palette.dart';
import 'package:munch_or_dump/core/widgets/editorial.dart';

/// The web's "Brand Report Card" hero (BrandPage.jsx) as an editorial card:
/// a letter grade from the weighted verdict mix, the average product score
/// out of 90, the product count, and a stacked verdict-mix bar with a legend.
///
/// Like the web, everything is computed client-side from the brand's products
/// (`GET /api/brands/:slug` returns no aggregates).

/// Web `VERDICT_WEIGHT` (BrandPage.jsx) — the weighted average of these picks
/// the overall grade tier. Missing/unknown verdicts weigh 2, as on the web.
double _verdictWeight(Verdict? verdict) => switch (verdict) {
  Verdict.munch => 5,
  Verdict.okay => 3,
  Verdict.treat => 2,
  Verdict.engineered => 1.5,
  Verdict.dump => 1,
  Verdict.bullshit => 0,
  null => 2,
};

/// Web `getOverallVerdict` (BrandPage.jsx), thresholds copied exactly.
Verdict overallBrandVerdict(List<ProductListItem> products) {
  if (products.isEmpty) return Verdict.okay;
  final avg =
      products.fold<double>(0, (sum, p) => sum + _verdictWeight(p.verdict)) /
      products.length;
  if (avg >= 4.0) return Verdict.munch;
  if (avg >= 2.5) return Verdict.okay;
  if (avg >= 1.75) return Verdict.treat;
  if (avg >= 1.25) return Verdict.engineered;
  if (avg >= 0.5) return Verdict.dump;
  return Verdict.bullshit;
}

/// Report-card letter for the web's six grade tiers, best → worst.
String brandGradeLetter(Verdict verdict) => switch (verdict) {
  Verdict.munch => 'A',
  Verdict.okay => 'B',
  Verdict.treat => 'C',
  Verdict.engineered => 'D',
  Verdict.dump => 'E',
  Verdict.bullshit => 'F',
};

/// Mean of the products' 0–90 scores, rounded; null when no product carries
/// a score.
int? averageBrandScore(List<ProductListItem> products) {
  final scores = <int>[
    for (final p in products)
      if (p.score != null) p.score!,
  ];
  if (scores.isEmpty) return null;
  return (scores.reduce((a, b) => a + b) / scores.length).round();
}

/// The report-card header shown above a brand's product list.
class BrandReportCard extends StatelessWidget {
  const BrandReportCard({required this.brand, super.key});

  final BrandDetail brand;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final products = brand.products;
    final overall = overallBrandVerdict(products);
    final gradeColor = context.verdicts.colorFor(overall);
    final letter = brandGradeLetter(overall);
    final avgScore = averageBrandScore(products);

    // Verdict mix, in best → worst order (Verdict.values is already ordered).
    final counts = <Verdict, int>{};
    for (final p in products) {
      final v = p.verdict;
      if (v != null) counts[v] = (counts[v] ?? 0) + 1;
    }

    return AccentTopBorderCard(
      accent: gradeColor,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Eyebrow('Brand report card', size: 11, spacing: 4.2),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Semantics(
                label: 'Grade $letter, ${overall.label}',
                child: ExcludeSemantics(
                  child: Container(
                    width: 62,
                    height: 62,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: gradeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: gradeColor.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      letter,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        height: 1,
                        color: gradeColor,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      brand.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        height: 1.15,
                        color: palette.inkPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    WebVerdictBadge(verdict: overall, size: 10),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              _Stat(
                value: avgScore == null ? '—' : '$avgScore',
                suffix: avgScore == null ? null : ' /90',
                label: 'Avg score',
              ),
              Container(
                width: 1,
                height: 34,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                color: palette.hairline,
              ),
              _Stat(
                value: '${products.length}',
                label: products.length == 1 ? 'Product' : 'Products',
              ),
            ],
          ),
          // Only rated products make the mix; a brand with a single verdict
          // renders one solid bar (never empty segments).
          if (counts.isNotEmpty) ...<Widget>[
            const SizedBox(height: 18),
            _VerdictMixBar(counts: counts),
            const SizedBox(height: 10),
            _VerdictMixLegend(counts: counts),
          ],
        ],
      ),
    );
  }
}

/// One big stat: value (+ faint suffix) over an eyebrow label.
class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, this.suffix});

  final String value;
  final String label;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text.rich(
          TextSpan(
            children: <TextSpan>[
              TextSpan(
                text: value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                  color: palette.inkPrimary,
                ),
              ),
              if (suffix != null)
                TextSpan(
                  text: suffix,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: palette.inkFaint,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 3),
        Eyebrow(label, size: 10, spacing: 2.5),
      ],
    );
  }
}

/// Slim stacked bar of the brand's verdict mix — flex-weighted segments in
/// the theme-aware verdict tones, hairline gaps, pill-clipped. Decorative:
/// the legend below carries the counts for assistive tech.
class _VerdictMixBar extends StatelessWidget {
  const _VerdictMixBar({required this.counts});

  final Map<Verdict, int> counts;

  @override
  Widget build(BuildContext context) {
    final verdicts = context.verdicts;
    final active = <Verdict>[
      for (final v in Verdict.values)
        if ((counts[v] ?? 0) > 0) v,
    ];
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          height: 6,
          child: Row(
            children: <Widget>[
              for (var i = 0; i < active.length; i++) ...<Widget>[
                if (i > 0) const SizedBox(width: 2),
                Expanded(
                  flex: counts[active[i]]!,
                  child: ColoredBox(color: verdicts.colorFor(active[i])),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// `[dot] VERDICT n` chips for each verdict present in the mix.
class _VerdictMixLegend extends StatelessWidget {
  const _VerdictMixLegend({required this.counts});

  final Map<Verdict, int> counts;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final verdicts = context.verdicts;
    return Wrap(
      spacing: 14,
      runSpacing: 8,
      children: <Widget>[
        for (final v in Verdict.values)
          if ((counts[v] ?? 0) > 0)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ConcernDot(color: verdicts.colorFor(v), size: 7),
                const SizedBox(width: 6),
                Text.rich(
                  TextSpan(
                    children: <TextSpan>[
                      TextSpan(
                        text: v.apiValue,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: palette.inkSecondary,
                        ),
                      ),
                      TextSpan(
                        text: ' ${counts[v]}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          fontFeatures: const <FontFeature>[
                            FontFeature.tabularFigures(),
                          ],
                          color: palette.inkFaint,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
      ],
    );
  }
}
