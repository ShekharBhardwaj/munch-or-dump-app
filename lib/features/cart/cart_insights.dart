import 'dart:ui' show Color;

import 'package:munch_or_dump/core/theme/palette.dart';

/// Cart-level score interpretation — the web `Receipt.jsx` thresholds, kept as
/// pure functions so the math is unit-testable.

/// The label for a cart score (web `scoreLabel`).
String scoreLabel(int score) {
  if (score >= 80) return 'Clean cart';
  if (score >= 65) return 'Mostly good';
  if (score >= 50) return 'Mixed bag';
  if (score >= 35) return 'Needs work';
  return 'Red zone';
}

/// The display color for a cart score (web `scoreColor`), resolved through the
/// active [Palette] so it reads correctly in light and dark.
Color scoreColorFor(int score, Palette palette) {
  if (score >= 65) return palette.munch;
  if (score >= 50) return palette.treat;
  return palette.dump;
}

/// The sparkline bar color band for a trip score (web `CartTrajectory`).
Color trajectoryBarColorFor(int score, Palette palette) {
  if (score >= 70) return palette.munch;
  if (score >= 50) return palette.okay;
  if (score >= 35) return palette.treat;
  return palette.dump;
}

/// Trend direction across trip scores (oldest → newest): compare the average
/// of the second half against the first; more than ±2 points is a trend.
/// Returns the signed delta and a display label (web `CartTrajectory` trend).
({int delta, String label, bool improving, bool declining}) trajectoryTrend(
  List<int> scores,
) {
  assert(scores.length >= 2, 'trend needs at least two scores');
  final mid = scores.length ~/ 2;
  final first = scores.sublist(0, mid);
  final second = scores.sublist(mid);
  final firstAvg = first.fold<int>(0, (int s, int v) => s + v) / first.length;
  final secondAvg =
      second.fold<int>(0, (int s, int v) => s + v) / second.length;
  final delta = (secondAvg - firstAvg).round();
  final improving = delta > 2;
  final declining = delta < -2;
  final label = improving
      ? '↑ +$delta pts trend'
      : declining
      ? '↓ $delta pts trend'
      : '→ Stable';
  return (
    delta: delta,
    label: label,
    improving: improving,
    declining: declining,
  );
}
