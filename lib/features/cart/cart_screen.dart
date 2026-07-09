import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:munch_or_dump/core/models/cart.dart';
import 'package:munch_or_dump/core/models/catalog.dart';
import 'package:munch_or_dump/core/router/routes.dart';
import 'package:munch_or_dump/core/theme/palette.dart';
import 'package:munch_or_dump/core/widgets/editorial.dart';
import 'package:munch_or_dump/features/browse/search_screen.dart';
import 'package:munch_or_dump/features/cart/cart_controller.dart';
import 'package:munch_or_dump/features/cart/cart_widgets.dart';

/// Cart Intelligence — the persistent, device-local cart with a cart-level
/// verdict summary: averaged score, verdict distribution, worst offenders with
/// healthier swaps, saved-trip history and trajectory. Anonymous-friendly (the
/// cart itself never talks to the server); only receipt/scan analysis gates.
class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  bool _showGood = false;
  // Tap-twice-to-confirm clear (web `confirmClear`): first tap arms for 3s.
  bool _confirmClear = false;
  Timer? _confirmTimer;

  @override
  void dispose() {
    _confirmTimer?.cancel();
    super.dispose();
  }

  Future<void> _addByName() async {
    final item = await Navigator.of(context).push<ProductListItem>(
      MaterialPageRoute<ProductListItem>(
        builder: (context) =>
            SearchScreen(onPick: (item) => Navigator.of(context).pop(item)),
      ),
    );
    if (item == null || !mounted) return;
    unawaited(HapticFeedback.selectionClick());
    final added = ref
        .read(cartControllerProvider.notifier)
        .addItem(CartItem.fromProductListItem(item, source: 'search'));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(added ? 'Added to cart.' : 'Already in your cart.'),
      ),
    );
  }

  void _saveTrip() {
    unawaited(HapticFeedback.mediumImpact());
    ref.read(cartControllerProvider.notifier).saveTrip();
    setState(() {
      _showGood = false;
      _confirmClear = false;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Trip saved.')));
  }

  void _clearCart() {
    if (_confirmClear) {
      _confirmTimer?.cancel();
      unawaited(HapticFeedback.mediumImpact());
      ref.read(cartControllerProvider.notifier).clear();
      setState(() => _confirmClear = false);
    } else {
      unawaited(HapticFeedback.selectionClick());
      setState(() => _confirmClear = true);
      _confirmTimer?.cancel();
      _confirmTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) setState(() => _confirmClear = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartControllerProvider);
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: GridBackground(
        child: SafeArea(
          top: false,
          child: cart.items.isEmpty
              ? _EmptyCart(savedTrips: cart.savedTrips, onAddByName: _addByName)
              : _buildPopulated(cart),
        ),
      ),
    );
  }

  Widget _buildPopulated(CartState cart) {
    final palette = context.palette;
    final bad = cart.bad;
    final good = cart.good;
    final locked = cart.lockedItems;
    final unknown = cart.unknown;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
      children: <Widget>[
        CartSummaryHeader(cart: cart),
        if (cart.analyzed.isNotEmpty) ...<Widget>[
          const SizedBox(height: 20),
          VerdictDistribution(analyzed: cart.analyzed),
        ],
        if (bad.isNotEmpty) ...<Widget>[
          const SizedBox(height: 28),
          Row(
            children: <Widget>[
              Icon(Icons.warning_amber_rounded, size: 14, color: palette.dump),
              const SizedBox(width: 8),
              Eyebrow(
                '${bad.length} item${bad.length == 1 ? '' : 's'} to address',
                size: 10,
                spacing: 3.6,
              ),
            ],
          ),
          const SizedBox(height: 10),
          CartGroupCard(
            children: <Widget>[
              for (final item in bad)
                CartItemRow(
                  key: ValueKey<String>(item.key),
                  item: item,
                  defaultOpen: bad.length <= 3,
                  showSwap: true,
                ),
            ],
          ),
        ],
        if (good.isNotEmpty) ...<Widget>[
          const SizedBox(height: 28),
          InkWell(
            onTap: () => setState(() => _showGood = !_showGood),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: <Widget>[
                  Eyebrow(
                    '${good.length} item${good.length == 1 ? '' : 's'} looking good',
                    size: 10,
                    spacing: 3.6,
                  ),
                  const SizedBox(width: 6),
                  AnimatedRotation(
                    turns: _showGood ? 0.5 : 0,
                    duration: const Duration(milliseconds: 150),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      size: 15,
                      color: palette.inkGhost,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_showGood) ...<Widget>[
            const SizedBox(height: 10),
            CartGroupCard(
              children: <Widget>[
                for (final item in good)
                  CartItemRow(key: ValueKey<String>(item.key), item: item),
              ],
            ),
          ],
        ],
        if (locked.isNotEmpty) ...<Widget>[
          const SizedBox(height: 28),
          CartGroupCard(
            children: <Widget>[
              for (final item in locked)
                CartItemRow(key: ValueKey<String>(item.key), item: item),
            ],
          ),
          const SizedBox(height: 10),
          UpgradeGate(lockedCount: locked.length),
        ],
        if (unknown.isNotEmpty) ...<Widget>[
          const SizedBox(height: 28),
          Eyebrow(
            '${unknown.length} not found — scan barcode for full analysis',
            size: 10,
            spacing: 3.6,
          ),
          const SizedBox(height: 10),
          CartGroupCard(
            children: <Widget>[
              for (final item in unknown)
                CartItemRow(key: ValueKey<String>(item.key), item: item),
            ],
          ),
        ],
        const SizedBox(height: 24),
        Divider(color: palette.hairlineFaint),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _addByName,
          icon: const Icon(Icons.search, size: 18),
          label: const Text('Add more products by name'),
        ),
        const SizedBox(height: 20),
        BlackCtaButton(
          label: 'Save trip & start fresh',
          expand: true,
          trailingIcon: null,
          onTap: _saveTrip,
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            InkWell(
              onTap: () => context.pushNamed(Routes.scan),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Row(
                  children: <Widget>[
                    Icon(
                      Icons.qr_code_scanner,
                      size: 13,
                      color: palette.inkFaint,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Scan another product',
                      style: TextStyle(fontSize: 12, color: palette.inkFaint),
                    ),
                  ],
                ),
              ),
            ),
            InkWell(
              onTap: _clearCart,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Row(
                  children: <Widget>[
                    Icon(
                      Icons.delete_outline,
                      size: 13,
                      color: _confirmClear ? palette.dump : palette.inkGhost,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _confirmClear ? 'Tap again to clear' : 'Clear cart',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: _confirmClear
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: _confirmClear ? palette.dump : palette.inkGhost,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (cart.savedTrips.isNotEmpty) ...<Widget>[
          const SizedBox(height: 32),
          _PastTripsSection(savedTrips: cart.savedTrips),
        ],
      ],
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart({required this.savedTrips, required this.onAddByName});

  final List<SavedTrip> savedTrips;
  final VoidCallback onAddByName;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 40),
      children: <Widget>[
        const Eyebrow('Cart Intelligence', spacing: 3.6),
        const SizedBox(height: 12),
        const TwoToneHeadline(
          dark: 'Your cart is',
          muted: 'empty.',
          size: 30,
          align: TextAlign.left,
        ),
        const SizedBox(height: 12),
        Text(
          'Add products after scanning them, or scan a receipt to analyze a '
          'whole trip.',
          style: TextStyle(
            fontSize: 15,
            height: 1.55,
            color: palette.inkSecondary,
          ),
        ),
        const SizedBox(height: 24),
        BlackCtaButton(
          label: 'Scan a product',
          leadingIcon: Icons.file_upload_outlined,
          expand: true,
          onTap: () => context.pushNamed(Routes.scan),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => context.pushNamed(Routes.receipt),
          icon: const Icon(Icons.receipt_long_outlined, size: 18),
          label: const Text('Scan a receipt'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onAddByName,
          icon: const Icon(Icons.search, size: 18),
          label: const Text('Add by name'),
        ),
        if (savedTrips.isNotEmpty) ...<Widget>[
          const SizedBox(height: 36),
          _PastTripsSection(savedTrips: savedTrips),
        ],
      ],
    );
  }
}

/// Trajectory + a short "Past trips" preview with a "See all" tap-through.
class _PastTripsSection extends StatelessWidget {
  const _PastTripsSection({required this.savedTrips});

  final List<SavedTrip> savedTrips;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        CartTrajectory(trips: savedTrips),
        const SizedBox(height: 20),
        Row(
          children: <Widget>[
            Icon(Icons.history, size: 13, color: palette.inkFaint),
            const SizedBox(width: 8),
            const Expanded(child: Eyebrow('Past trips', size: 10)),
            if (savedTrips.length > 2)
              InkWell(
                onTap: () => context.pushNamed(Routes.cartHistory),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                  child: Text(
                    'See all →',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: palette.inkSecondary,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        for (final trip in savedTrips.take(2))
          SavedTripCard(key: ValueKey<String>(trip.id), trip: trip),
      ],
    );
  }
}
