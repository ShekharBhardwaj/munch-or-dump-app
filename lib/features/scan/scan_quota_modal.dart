import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:munch_or_dump/core/router/routes.dart';
import 'package:munch_or_dump/core/theme/app_colors.dart';
import 'package:munch_or_dump/core/widgets/editorial.dart';

const List<String> _perks = <String>[
  'Scan any product for a verdict',
  'Your scan history, saved',
  'A watchlist for products you track',
  'No brand deals. Ever.',
];

/// Bottom sheet shown when a logged-out user tries to scan. Scanning requires an
/// account (the API returns 401 for anonymous analyze), so this is the gate.
Future<void> showSignInToScanSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
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
            const Text(
              'Sign in to scan',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: AppColors.inkPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create a free account to scan products and get an instant, '
              'honest verdict.',
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: AppColors.inkSecondary,
              ),
            ),
            const SizedBox(height: 20),
            for (final perk in _perks)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.check, size: 18, color: AppColors.brand),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        perk,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.inkPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Center(
              child: BlackCtaButton(
                label: 'Create free account',
                trailingIcon: null,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  context.pushNamed(Routes.login);
                },
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  context.pushNamed(Routes.login);
                },
                child: const Text('Already have an account? Sign in'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
