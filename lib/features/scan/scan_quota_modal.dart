import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:munch_or_dump/core/router/routes.dart';
import 'package:munch_or_dump/core/theme/palette.dart';
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
              'Sign in to scan',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: palette.inkPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a free account to scan products and get an instant, '
              'honest verdict.',
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: palette.inkSecondary,
              ),
            ),
            const SizedBox(height: 20),
            for (final perk in _perks)
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
