import 'package:flutter/material.dart';

/// Brand + verdict colors.
///
/// Verdict hexes mirror the web app's `ShareCard.jsx` VERDICT_CONFIG so web and
/// mobile stay visually identical. Each verdict has a primary tone (for light
/// surfaces) and a lighter accent tone (for dark surfaces).
abstract final class AppColors {
  // ── Brand ──────────────────────────────────────────────────────────────────
  static const Color brandSeed = Color(
    0xFF10B981,
  ); // emerald — the "Munch" hero
  static const Color ink = Color(0xFF1C1917); // stone-900 text
  static const Color mutedInk = Color(0xFF78716C); // stone-500

  // ── Verdict — primary tone ──────────────────────────────────────────────────
  static const Color munch = Color(0xFF10B981);
  static const Color okay = Color(0xFF0EA5E9);
  static const Color treat = Color(0xFFF59E0B);
  static const Color engineered = Color(0xFF8B5CF6);
  static const Color dump = Color(0xFFEF4444);
  static const Color bullshit = Color(0xFFA855F7);

  // ── Verdict — lighter accent tone (dark surfaces) ───────────────────────────
  static const Color munchAccent = Color(0xFF34D399);
  static const Color okayAccent = Color(0xFF38BDF8);
  static const Color treatAccent = Color(0xFFFBBF24);
  static const Color engineeredAccent = Color(0xFFA78BFA);
  static const Color dumpAccent = Color(0xFFF87171);
  static const Color bullshitAccent = Color(0xFFC084FC);
}
