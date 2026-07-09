import 'package:flutter/material.dart';
import 'package:munch_or_dump/core/theme/palette.dart';
import 'package:munch_or_dump/core/widgets/editorial.dart';

/// A nutrition metric tablet, keyed to the analysis `nutrition_summary` map.
class _Metric {
  const _Metric(this.key, this.label, {this.invert = false});

  final String key;
  final String label;

  /// Inverted semantics: for protein/fiber, high is good (green), low is bad.
  final bool invert;
}

/// The six metrics the web renders, in order.
const List<_Metric> _metrics = <_Metric>[
  _Metric('sugar_level', 'Sugar'),
  _Metric('fat_composition', 'Fat'),
  _Metric('calorie_density', 'Calories'),
  _Metric('protein_content', 'Protein', invert: true),
  _Metric('fiber_content', 'Fiber', invert: true),
  _Metric('salt_level', 'Salt / Sodium'),
];

enum _Level { veryHigh, high, moderate, low, none, unknown }

/// Parses a free-text level ("high", "very high in sugar", "negligible") into
/// a [_Level] — the web's `getLevel`.
_Level _parseLevel(String value) {
  final v = value.toLowerCase();
  if (v.contains('very high') || v.contains('extreme')) return _Level.veryHigh;
  if (v.contains('high')) return _Level.high;
  if (v.contains('moderate') || v.contains('medium')) return _Level.moderate;
  if (v.contains('low')) return _Level.low;
  if (v.contains('zero') ||
      v.contains('none') ||
      v.contains('negligible') ||
      v.contains('absent')) {
    return _Level.none;
  }
  return _Level.unknown;
}

String _levelLabel(_Level level) => switch (level) {
  _Level.veryHigh => 'Very High',
  _Level.high => 'High',
  _Level.moderate => 'Moderate',
  _Level.low => 'Low',
  _Level.none => 'None',
  _Level.unknown => '—',
};

/// How the chip reads: good (green), moderate (orange), bad (red), unknown.
enum _Tone { good, moderate, bad, unknown }

/// For sugar/fat/calories/salt high = bad; for protein/fiber high = good.
_Tone _toneFor(_Level level, {required bool invert}) => switch (level) {
  _Level.veryHigh || _Level.high => invert ? _Tone.good : _Tone.bad,
  _Level.moderate => _Tone.moderate,
  _Level.low || _Level.none => invert ? _Tone.bad : _Tone.good,
  _Level.unknown => _Tone.unknown,
};

({Color fg, Color bg, Color border}) _chipColors(Palette palette, _Tone tone) =>
    switch (tone) {
      _Tone.bad => (
        fg: palette.concernHigh,
        bg: palette.concernHighTint,
        border: palette.concernHigh.withValues(alpha: 0.3),
      ),
      _Tone.moderate => (
        fg: palette.concernMid,
        bg: palette.concernMidTint,
        border: palette.concernMid.withValues(alpha: 0.3),
      ),
      _Tone.good => (
        fg: palette.impactPositive,
        bg: palette.impactPositive.withValues(alpha: 0.12),
        border: palette.impactPositive.withValues(alpha: 0.3),
      ),
      _Tone.unknown => (
        fg: palette.inkFaint,
        bg: palette.surfaceAlt,
        border: palette.hairline,
      ),
    };

/// The web's nutrition tablets: a two-column grid of metric cards — Sugar,
/// Fat, Calories, Protein, Fiber, Salt — each with a level chip colored by
/// concern. Protein and fiber are inverted (high = good). Renders nothing
/// when [nutrition] is null or carries no known metric.
class NutritionInsight extends StatelessWidget {
  const NutritionInsight({super.key, required this.nutrition});

  /// The raw `nutrition_summary` map from the analysis, e.g.
  /// `{'sugar_level': 'high', 'protein_content': 'moderate'}`.
  final Map<String, dynamic>? nutrition;

  /// True when [nutrition] carries at least one known metric — lets callers
  /// hide a section header when the grid would render nothing.
  static bool hasData(Map<String, dynamic>? nutrition) =>
      nutrition != null && _available(nutrition).isNotEmpty;

  static List<_Metric> _available(Map<String, dynamic> nutrition) => _metrics
      .where((m) => (nutrition[m.key]?.toString().trim() ?? '').isNotEmpty)
      .toList();

  @override
  Widget build(BuildContext context) {
    final summary = nutrition;
    if (summary == null) return const SizedBox.shrink();
    final available = _available(summary);
    if (available.isEmpty) return const SizedBox.shrink();

    Widget tablet(_Metric metric) => _NutritionTablet(
      metric: metric,
      value: summary[metric.key].toString().trim(),
    );

    return Column(
      children: <Widget>[
        for (var i = 0; i < available.length; i += 2) ...<Widget>[
          if (i > 0) const SizedBox(height: 10),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(child: tablet(available[i])),
                const SizedBox(width: 10),
                Expanded(
                  child: i + 1 < available.length
                      ? tablet(available[i + 1])
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _NutritionTablet extends StatelessWidget {
  const _NutritionTablet({required this.metric, required this.value});

  final _Metric metric;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final level = _parseLevel(value);
    final chip = _chipColors(palette, _toneFor(level, invert: metric.invert));
    final levelLabel = _levelLabel(level);
    return Semantics(
      label:
          '${metric.label}: '
          '${level == _Level.unknown ? value : levelLabel}',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: palette.hairline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Eyebrow(metric.label, size: 10, spacing: 1.4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: chip.bg,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: chip.border),
                    ),
                    child: Text(
                      levelLabel.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: chip.fg,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: palette.inkSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
