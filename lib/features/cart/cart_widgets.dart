import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:munch_or_dump/core/models/analysis_result.dart';
import 'package:munch_or_dump/core/models/cart.dart';
import 'package:munch_or_dump/core/models/verdict.dart';
import 'package:munch_or_dump/core/router/routes.dart';
import 'package:munch_or_dump/core/theme/palette.dart';
import 'package:munch_or_dump/core/theme/verdict_palette.dart';
import 'package:munch_or_dump/core/widgets/editorial.dart';
import 'package:munch_or_dump/features/cart/cart_controller.dart';
import 'package:munch_or_dump/features/cart/cart_insights.dart';
import 'package:munch_or_dump/features/cart/upgrade_sheet.dart';
import 'package:munch_or_dump/features/product/product_screen.dart'
    show productProvider;

/// Shared building blocks for the Cart Intelligence surfaces: the summary
/// header, verdict distribution, item rows (with healthier-swap chips), the
/// trajectory sparkline, saved-trip cards, and the premium upgrade gate.

const List<String> _monthNames = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// `MMM d` without an intl dependency.
String shortDate(DateTime date) => '${_monthNames[date.month - 1]} ${date.day}';

/// A rounded surface card that groups cart rows, divided by faint hairlines.
class CartGroupCard extends StatelessWidget {
  const CartGroupCard({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.hairline),
      ),
      child: Column(
        children: <Widget>[
          for (var i = 0; i < children.length; i++) ...<Widget>[
            if (i > 0) Divider(height: 1, color: palette.hairlineFaint),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// The cart-level intelligence header: the big averaged score, its label, the
/// item/analyzed counts, and a worst-offender callout.
class CartSummaryHeader extends StatelessWidget {
  const CartSummaryHeader({required this.cart, super.key});

  final CartState cart;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final score = cart.cartScore;
    final analyzed = cart.analyzed;
    final bad = cart.bad;
    final accent = score == null
        ? palette.inkGhost
        : scoreColorFor(score, palette);
    return AccentTopBorderCard(
      accent: accent,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Eyebrow('Cart Intelligence', size: 10, spacing: 3.6),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              if (score != null) ...<Widget>[
                Text(
                  '$score',
                  style: TextStyle(
                    fontSize: 48,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.5,
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                    color: accent,
                  ),
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      score != null ? scoreLabel(score) : 'Your cart',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        color: palette.inkPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${cart.count} item${cart.count == 1 ? '' : 's'}'
                      '${analyzed.length != cart.count ? ' · ${analyzed.length} analyzed' : ''}',
                      style: TextStyle(fontSize: 13, color: palette.inkFaint),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (bad.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              '${bad.length} to address — worst: ${bad.first.name.isEmpty ? bad.first.inputName : bad.first.name}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: palette.dump,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The thin stacked verdict-distribution bar + `N× LABEL` chips, over the
/// analyzed items only. Uses the web-exact verdict tones.
class VerdictDistribution extends StatelessWidget {
  const VerdictDistribution({required this.analyzed, super.key});

  final List<CartItem> analyzed;

  @override
  Widget build(BuildContext context) {
    if (analyzed.isEmpty) return const SizedBox.shrink();
    final counts = <Verdict, int>{
      for (final v in Verdict.values)
        v: analyzed.where((CartItem i) => i.verdict == v).length,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 6,
            child: Row(
              children: <Widget>[
                for (final v in Verdict.values)
                  if (counts[v]! > 0)
                    Expanded(
                      flex: counts[v]!,
                      child: ColoredBox(color: verdictToneFor(v).dot),
                    ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: <Widget>[
            for (final v in Verdict.values)
              if (counts[v]! > 0)
                Text(
                  '${counts[v]}× ${v.apiValue}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: verdictToneFor(v).word,
                  ),
                ),
          ],
        ),
      ],
    );
  }
}

/// The healthier swap for a bad carted item: the first `better_alternatives`
/// entry of its product page, fetched lazily (and cached ~5 min) through
/// [productProvider]. Null when there is none.
final cartSwapProvider = FutureProvider.autoDispose
    .family<Alternative?, String>((ref, slug) async {
      final product = await ref.watch(productProvider(slug).future);
      for (final alt in product.alternatives) {
        if (alt.slug.trim().isNotEmpty) return alt;
      }
      return null;
    });

/// One cart row — three visual modes (locked / unknown / analyzed), expandable
/// for analyzed items, with a remove ✕ and (for bad items with a slug) an
/// inline healthier-swap chip.
class CartItemRow extends ConsumerStatefulWidget {
  const CartItemRow({
    required this.item,
    this.defaultOpen = false,
    this.showSwap = false,
    super.key,
  });

  final CartItem item;
  final bool defaultOpen;

  /// Fetch + render the healthier-swap chip (bad items only).
  final bool showSwap;

  @override
  ConsumerState<CartItemRow> createState() => _CartItemRowState();
}

class _CartItemRowState extends ConsumerState<CartItemRow> {
  late bool _open = widget.defaultOpen;

  void _remove() {
    unawaited(HapticFeedback.selectionClick());
    ref.read(cartControllerProvider.notifier).removeByKey(widget.item.key);
  }

  Widget _removeButton(Palette palette) => IconButton(
    onPressed: _remove,
    visualDensity: VisualDensity.compact,
    icon: Icon(Icons.close, size: 15, color: palette.inkGhost),
    tooltip: 'Remove from cart',
  );

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final item = widget.item;
    final displayName = item.inputName.isNotEmpty ? item.inputName : item.name;

    if (item.locked) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: <Widget>[
            Icon(Icons.lock_outline, size: 14, color: palette.inkGhost),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14, color: palette.inkFaint),
              ),
            ),
            Text(
              'Premium',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: palette.inkFaint,
              ),
            ),
            _removeButton(palette),
          ],
        ),
      );
    }

    final verdict = item.verdict;
    if (verdict == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 14,
              child: Text(
                '?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: palette.inkGhost,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14, color: palette.inkFaint),
              ),
            ),
            InkWell(
              onTap: () => context.pushNamed(Routes.scan),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Text(
                  'Scan →',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: palette.inkFaint,
                  ),
                ),
              ),
            ),
            _removeButton(palette),
          ],
        ),
      );
    }

    final tone = verdictToneFor(verdict);
    final resolvedDiffers =
        item.name.isNotEmpty &&
        item.inputName.isNotEmpty &&
        item.name.toLowerCase() != item.inputName.toLowerCase();
    final slug = item.productSlug?.trim() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        InkWell(
          onTap: () => setState(() => _open = !_open),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: <Widget>[
                ConcernDot(color: tone.dot, size: 7),
                const SizedBox(width: 12),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: <TextSpan>[
                        TextSpan(
                          text: displayName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: palette.inkPrimary,
                          ),
                        ),
                        if (resolvedDiffers)
                          TextSpan(
                            text: '  → ${item.name}',
                            style: TextStyle(
                              fontSize: 12,
                              color: palette.inkFaint,
                            ),
                          ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                WebVerdictBadge(verdict: verdict, size: 10),
                if (item.score != null) ...<Widget>[
                  const SizedBox(width: 8),
                  Text(
                    '${item.score}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const <FontFeature>[
                        FontFeature.tabularFigures(),
                      ],
                      color: palette.inkFaint,
                    ),
                  ),
                ],
                AnimatedRotation(
                  turns: _open ? 0.5 : 0,
                  duration: const Duration(milliseconds: 150),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    size: 16,
                    color: palette.inkGhost,
                  ),
                ),
                _removeButton(palette),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 150),
          alignment: Alignment.topCenter,
          child: !_open
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(left: 19, bottom: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      if ((item.shortExplanation ?? '').isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            item.shortExplanation!,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.5,
                              color: palette.inkSecondary,
                            ),
                          ),
                        ),
                      for (final reason in item.verdictReasons.take(2))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '· $reason',
                            style: TextStyle(
                              fontSize: 12,
                              color: palette.inkFaint,
                            ),
                          ),
                        ),
                      if (slug.isNotEmpty)
                        InkWell(
                          onTap: () => context.pushNamed(
                            Routes.product,
                            pathParameters: <String, String>{'slug': slug},
                          ),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              'Full verdict →',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: palette.inkSecondary,
                              ),
                            ),
                          ),
                        ),
                      if (widget.showSwap && slug.isNotEmpty)
                        _SwapChip(slug: slug),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

/// "Swap for {name} ({verdict})" — one healthier alternative for a bad item.
/// Tapping opens the alternative's product page; "+" adds it to the cart.
/// Renders nothing while loading, on error, or when there's no alternative.
class _SwapChip extends ConsumerWidget {
  const _SwapChip({required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final swap = ref.watch(cartSwapProvider(slug)).valueOrNull;
    if (swap == null) return const SizedBox.shrink();
    final tone = verdictToneFor(swap.verdict ?? Verdict.munch);
    final swapKey = CartItem.fromAlternative(swap).key;
    final inCart = ref.watch(
      cartControllerProvider.select((CartState s) => s.contains(swapKey)),
    );
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        decoration: BoxDecoration(
          color: tone.tint,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: tone.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Flexible(
              child: InkWell(
                onTap: () => context.pushNamed(
                  Routes.product,
                  pathParameters: <String, String>{'slug': swap.slug},
                ),
                borderRadius: BorderRadius.circular(999),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 7, 4, 7),
                  child: Text(
                    'Swap for ${swap.name}'
                    '${swap.verdict != null ? ' (${swap.verdict!.apiValue})' : ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: tone.word,
                    ),
                  ),
                ),
              ),
            ),
            InkWell(
              onTap: inCart
                  ? null
                  : () {
                      unawaited(HapticFeedback.selectionClick());
                      ref
                          .read(cartControllerProvider.notifier)
                          .addItem(CartItem.fromAlternative(swap));
                    },
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 7, 10, 7),
                child: Icon(
                  inCart ? Icons.check : Icons.add,
                  size: 15,
                  color: tone.word,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "{N} items need Premium" — the upgrade gate under locked receipt rows. The
/// server enforces the free cap; this only renders the pitch (IAP seam).
class UpgradeGate extends StatelessWidget {
  const UpgradeGate({required this.lockedCount, super.key});

  final int lockedCount;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
      decoration: BoxDecoration(
        color: palette.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.hairline),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '$lockedCount item${lockedCount == 1 ? '' : 's'} need Premium',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: palette.inkPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Unlimited cart analysis, web ingredient research',
                  style: TextStyle(fontSize: 12, color: palette.inkFaint),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: () => showUpgradeSheet(
              context,
              reason:
                  '$lockedCount item${lockedCount == 1 ? '' : 's'} in your '
                  'cart ${lockedCount == 1 ? 'is' : 'are'} beyond the free '
                  'receipt limit.',
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'Upgrade',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: palette.inkPrimary,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward, size: 13, color: palette.inkPrimary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The score-trajectory sparkline over the last 8 scored trips (oldest left),
/// with a trend label. Renders nothing below 2 scored trips. Plain containers —
/// no chart dependency.
class CartTrajectory extends StatelessWidget {
  const CartTrajectory({required this.trips, super.key});

  final List<SavedTrip> trips;

  static const double _barAreaHeight = 40;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    // History is stored newest-first; read oldest→left like the web.
    final scored = trips
        .where((SavedTrip t) => t.score != null)
        .toList()
        .reversed
        .toList();
    final visible = scored.length > 8
        ? scored.sublist(scored.length - 8)
        : scored;
    if (visible.length < 2) return const SizedBox.shrink();

    final scores = visible.map((SavedTrip t) => t.score!).toList();
    final min = scores.reduce((int a, int b) => a < b ? a : b);
    final max = scores.reduce((int a, int b) => a > b ? a : b);
    final range = (max - min) == 0 ? 1 : max - min;
    final trend = trajectoryTrend(scores);
    final trendColor = trend.improving
        ? palette.munch
        : trend.declining
        ? palette.dump
        : palette.inkFaint;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Expanded(child: Eyebrow('Score trajectory', size: 10)),
              Text(
                trend.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: trendColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: _barAreaHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                for (var i = 0; i < visible.length; i++) ...<Widget>[
                  if (i > 0) const SizedBox(width: 6),
                  Expanded(
                    child: Opacity(
                      opacity: i == visible.length - 1 ? 1 : 0.6,
                      child: Container(
                        height:
                            ((visible[i].score! - min) / range * _barAreaHeight)
                                .clamp(4, _barAreaHeight)
                                .toDouble(),
                        decoration: BoxDecoration(
                          color: trajectoryBarColorFor(
                            visible[i].score!,
                            palette,
                          ),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                '${scores.first}',
                style: TextStyle(fontSize: 10, color: palette.inkFaint),
              ),
              Text(
                '${scores.last}',
                style: TextStyle(fontSize: 10, color: palette.inkFaint),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One saved trip: score + label + date/count line, expandable to a read-only
/// verdict breakdown and item list, with a delete action.
class SavedTripCard extends ConsumerStatefulWidget {
  const SavedTripCard({required this.trip, super.key});

  final SavedTrip trip;

  @override
  ConsumerState<SavedTripCard> createState() => _SavedTripCardState();
}

class _SavedTripCardState extends ConsumerState<SavedTripCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final trip = widget.trip;
    final flagged = trip.items
        .where((CartItem i) => i.verdict?.isBad ?? false)
        .length;
    final unknownCount = trip.items
        .where((CartItem i) => i.verdict == null && !i.locked)
        .length;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          InkWell(
            onTap: () => setState(() => _open = !_open),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: <Widget>[
                  if (trip.score != null) ...<Widget>[
                    Text(
                      '${trip.score}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        fontFeatures: const <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                        color: scoreColorFor(trip.score!, palette),
                      ),
                    ),
                    const SizedBox(width: 14),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          trip.score != null ? scoreLabel(trip.score!) : 'Trip',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: palette.inkPrimary,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          '${shortDate(trip.savedAt)} · ${trip.itemCount} '
                          'item${trip.itemCount == 1 ? '' : 's'}'
                          '${flagged > 0 ? ' · $flagged flagged' : ''}',
                          style: TextStyle(
                            fontSize: 12,
                            color: palette.inkFaint,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 150),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      size: 16,
                      color: palette.inkGhost,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 150),
            alignment: Alignment.topCenter,
            child: !_open
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Divider(height: 1, color: palette.hairlineFaint),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 4,
                          children: <Widget>[
                            for (final v in Verdict.values)
                              if (trip.items.any(
                                (CartItem i) => i.verdict == v,
                              ))
                                Text(
                                  '${trip.items.where((CartItem i) => i.verdict == v).length}× ${v.apiValue}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: verdictToneFor(v).word,
                                  ),
                                ),
                            if (unknownCount > 0)
                              Text(
                                '$unknownCount× unknown',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: palette.inkFaint,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        for (final item in trip.items)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Row(
                              children: <Widget>[
                                ConcernDot(
                                  color: item.verdict != null
                                      ? verdictToneFor(item.verdict!).dot
                                      : palette.inkGhost,
                                  size: 6,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    item.inputName.isNotEmpty
                                        ? item.inputName
                                        : item.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: palette.inkSecondary,
                                    ),
                                  ),
                                ),
                                if (item.verdict != null)
                                  WebVerdictBadge(
                                    verdict: item.verdict!,
                                    size: 9,
                                  ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: () {
                            unawaited(HapticFeedback.selectionClick());
                            ref
                                .read(cartControllerProvider.notifier)
                                .deleteTrip(trip.id);
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Icon(
                                  Icons.delete_outline,
                                  size: 13,
                                  color: palette.inkFaint,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'Delete this trip',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: palette.inkFaint,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
