import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:munch_or_dump/core/models/verdict.dart';
import 'package:munch_or_dump/core/router/routes.dart';
import 'package:munch_or_dump/core/theme/verdict_palette.dart';
import 'package:munch_or_dump/features/auth/auth_controller.dart';

/// Landing screen — exercises the theme, router, verdict palette, and (Phase 1)
/// surfaces the account / sign-in entry point.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final loggedIn = ref.watch(authControllerProvider).valueOrNull != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Munch or Dump',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Search',
            icon: const Icon(Icons.search),
            onPressed: () => context.pushNamed(Routes.search),
          ),
          IconButton(
            tooltip: loggedIn ? 'Account' : 'Sign in',
            icon: Icon(
              loggedIn ? Icons.account_circle : Icons.account_circle_outlined,
            ),
            onPressed: () => loggedIn
                ? context.goNamed(Routes.account)
                : context.pushNamed(Routes.login),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Scan a product.\nGet a verdict.',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Six verdicts, one honest read on what you’re about to eat.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  for (final verdict in Verdict.values)
                    _VerdictChip(verdict: verdict),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Browse',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.pushNamed(Routes.categories),
                      icon: const Icon(Icons.category_outlined),
                      label: const Text('Categories'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.pushNamed(Routes.brands),
                      icon: const Icon(Icons.storefront_outlined),
                      label: const Text('Brands'),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => context.pushNamed(Routes.scan),
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Scan a product'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'v0.1.0',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VerdictChip extends StatelessWidget {
  const _VerdictChip({required this.verdict});

  final Verdict verdict;

  @override
  Widget build(BuildContext context) {
    final color = context.verdicts.colorFor(verdict);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        '${verdict.emoji}  ${verdict.label}',
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}
