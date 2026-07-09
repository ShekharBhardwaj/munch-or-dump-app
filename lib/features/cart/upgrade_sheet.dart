import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:munch_or_dump/core/theme/palette.dart';
import 'package:munch_or_dump/core/widgets/editorial.dart';

/// The premium purchase seam. There is no purchase flow yet — the real path is
/// Apple StoreKit / in-app purchase, specced separately (Stripe is web-only
/// and rejected on iOS). This interface is where it plugs in.
// TODO(iap): wire Apple StoreKit / in_app_purchase here — Stripe is web-only
// and rejected on iOS.
abstract interface class PurchaseGateway {
  /// Purchase the premium plan. Resolves true on a completed purchase.
  Future<bool> purchasePremium();
}

class _NotYetWiredPurchaseGateway implements PurchaseGateway {
  const _NotYetWiredPurchaseGateway();

  @override
  Future<bool> purchasePremium() => throw UnimplementedError('IAP not wired');
}

/// The (unwired) purchase gateway. Swap the implementation when StoreKit
/// lands; callers must treat [UnimplementedError] as "coming soon".
final notYetWiredPurchaseGatewayProvider = Provider<PurchaseGateway>(
  (ref) => const _NotYetWiredPurchaseGateway(),
);

const List<String> _premiumPerks = <String>[
  'Every receipt item analyzed',
  'Unlimited cart analysis',
  'Web ingredient research for unknowns',
  'No brand deals. Ever.',
];

/// Bottom sheet pitching Premium — the centralized upgrade gate. [reason]
/// explains what triggered it (e.g. locked receipt items). The purchase button
/// is a stub: it never attempts a payment, it snackbars "coming soon".
Future<void> showUpgradeSheet(BuildContext context, {required String reason}) {
  final palette = context.palette;
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: palette.surface,
    showDragHandle: true,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Upgrade to Premium',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: palette.inkPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              reason,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: palette.inkSecondary,
              ),
            ),
            const SizedBox(height: 20),
            for (final perk in _premiumPerks)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: <Widget>[
                    Icon(Icons.check, size: 18, color: palette.brand),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        perk,
                        style: TextStyle(
                          fontSize: 14,
                          color: palette.inkPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Center(
              child: BlackCtaButton(
                label: 'Upgrade — coming soon',
                trailingIcon: null,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Premium purchases are coming soon.'),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(sheetContext).pop(),
                child: const Text('Maybe later'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
