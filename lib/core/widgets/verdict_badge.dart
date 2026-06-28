import 'package:flutter/material.dart';
import 'package:munch_or_dump/core/models/verdict.dart';
import 'package:munch_or_dump/core/theme/verdict_palette.dart';

/// A small pill showing a verdict (emoji + label, optional score), colored from
/// the verdict palette. Used in history/watchlist/list rows.
class VerdictBadge extends StatelessWidget {
  const VerdictBadge({required this.verdict, this.score, super.key});

  final Verdict verdict;
  final int? score;

  @override
  Widget build(BuildContext context) {
    final color = context.verdicts.colorFor(verdict);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        score != null
            ? '${verdict.emoji} ${verdict.label} · $score'
            : '${verdict.emoji} ${verdict.label}',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
