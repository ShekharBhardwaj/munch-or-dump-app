import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:munch_or_dump/core/models/user.dart';
import 'package:munch_or_dump/core/router/routes.dart';
import 'package:munch_or_dump/core/widgets/editorial.dart';
import 'package:munch_or_dump/features/auth/auth_controller.dart';

/// Signed-in account screen: identity, plan/tier, profile summary, edit + sign
/// out. Reached only when authenticated (router redirect guards it).
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    if (user == null) {
      return const Scaffold(body: PageLoader());
    }
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: <Widget>[
            CircleAvatar(
              radius: 32,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                user.email.isNotEmpty ? user.email[0].toUpperCase() : '?',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                user.email,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Wrap(
                spacing: 8,
                children: <Widget>[
                  Chip(label: Text(user.isPremium ? 'Premium' : 'Free')),
                  if (user.tier != null)
                    Chip(label: Text(_prettyTier(user.tier!))),
                  if (user.isAdmin) const Chip(label: Text('Admin')),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _ProfileSummary(user: user),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.history),
              title: const Text('Scan history'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.pushNamed(Routes.history),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.bookmark_outline),
              title: const Text('Saved & watching'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.pushNamed(Routes.watchlist),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.gavel_outlined),
              title: const Text('Disclaimers & terms'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.pushNamed(Routes.legal),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.lock_outline),
              title: const Text('Privacy policy'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.pushNamed(Routes.privacy),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => context.pushNamed(Routes.onboarding),
              icon: const Icon(Icons.tune),
              label: const Text('Edit personalization'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              // No explicit navigation: signing out flips the session state,
              // and the router redirect moves the now-gated /account to home.
              onPressed: () =>
                  ref.read(authControllerProvider.notifier).signOut(),
              icon: const Icon(Icons.logout),
              label: const Text('Sign out'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _prettyTier(String tier) => tier
      .replaceAll('_', ' ')
      .replaceFirstMapped(RegExp('^.'), (m) => m.group(0)!.toUpperCase());
}

class _ProfileSummary extends StatelessWidget {
  const _ProfileSummary({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final profile = user.profile;
    final theme = Theme.of(context);
    final dietary = profile?.dietaryList ?? const <String>[];
    final goals = profile?.goalsList ?? const <String>[];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Your profile',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            _row(context, 'Persona', profile?.persona ?? '—'),
            _row(context, 'Goals', goals.isEmpty ? '—' : goals.join(', ')),
            _row(
              context,
              'Dietary',
              dietary.isEmpty ? '—' : dietary.join(', '),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
