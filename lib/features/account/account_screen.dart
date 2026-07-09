import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:munch_or_dump/core/api/api_exception.dart';
import 'package:munch_or_dump/core/models/user.dart';
import 'package:munch_or_dump/core/providers.dart';
import 'package:munch_or_dump/core/router/routes.dart';
import 'package:munch_or_dump/core/theme/palette.dart';
import 'package:munch_or_dump/core/widgets/editorial.dart';
import 'package:munch_or_dump/core/widgets/forms.dart';
import 'package:munch_or_dump/features/about/about_screens.dart';
import 'package:munch_or_dump/features/auth/auth_controller.dart';
import 'package:munch_or_dump/features/onboarding/personalization_options.dart';

/// Signed-in account screen: identity, plan/tier, profile summary, library +
/// about links, edit-personalization, and sign-out. Reached only when
/// authenticated (router redirect guards it).
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    if (user == null) {
      return const Scaffold(body: PageLoader());
    }

    final palette = context.palette;
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
          children: <Widget>[
            const Eyebrow('Account', spacing: 3.6),
            const SizedBox(height: 16),
            _Identity(user: user),
            const SizedBox(height: 24),
            _ProfileCard(user: user),
            const SizedBox(height: 28),
            const SectionLabel('Library'),
            const SizedBox(height: 4),
            NavRow(
              icon: Icons.history,
              label: 'Scan history',
              onTap: () => context.pushNamed(Routes.history),
            ),
            Divider(height: 1, color: palette.hairlineFaint),
            NavRow(
              icon: Icons.bookmark_outline,
              label: 'Saved & following',
              onTap: () => context.pushNamed(Routes.watchlist),
            ),
            const SizedBox(height: 28),
            const SectionLabel('About'),
            const SizedBox(height: 4),
            NavRow(
              icon: Icons.info_outline,
              label: 'About Munch or Dump',
              onTap: () => context.pushNamed(Routes.about),
            ),
            Divider(height: 1, color: palette.hairlineFaint),
            NavRow(
              icon: Icons.science_outlined,
              label: 'How it works',
              onTap: () => context.pushNamed(Routes.howItWorks),
            ),
            Divider(height: 1, color: palette.hairlineFaint),
            NavRow(
              icon: Icons.auto_stories_outlined,
              label: 'Our story',
              onTap: () => context.pushNamed(Routes.ourStory),
            ),
            Divider(height: 1, color: palette.hairlineFaint),
            NavRow(
              icon: Icons.gavel_outlined,
              label: 'Disclaimers & terms',
              onTap: () => context.pushNamed(Routes.legal),
            ),
            Divider(height: 1, color: palette.hairlineFaint),
            NavRow(
              icon: Icons.lock_outline,
              label: 'Privacy policy',
              onTap: () => context.pushNamed(Routes.privacy),
            ),
            const SizedBox(height: 28),
            _SignOutButton(
              onTap: () => ref.read(authControllerProvider.notifier).signOut(),
            ),
            const SizedBox(height: 36),
            const _DangerZone(),
            const SizedBox(height: 28),
            const SatireFooter(),
          ],
        ),
      ),
    );
  }
}

class _Identity extends StatelessWidget {
  const _Identity({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final initial = user.email.isNotEmpty ? user.email[0].toUpperCase() : '?';
    return Row(
      children: <Widget>[
        Container(
          width: 60,
          height: 60,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFECFDF5),
            shape: BoxShape.circle,
            border: Border.all(color: palette.brand),
          ),
          child: Text(
            initial,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: palette.brandDeep,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                user.email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: palette.inkPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: <Widget>[
                  if (user.isPremium)
                    MetaPill(
                      text: 'Premium',
                      fg: palette.brandDeep,
                      bg: const Color(0xFFECFDF5),
                      border: palette.brand,
                      upper: true,
                    )
                  else
                    MetaPill(
                      text: 'Free',
                      fg: palette.inkSecondary,
                      bg: palette.surfaceAlt,
                      border: palette.hairline,
                      upper: true,
                    ),
                  if (user.tier != null)
                    MetaPill(
                      text: _prettyTier(user.tier!),
                      fg: palette.inkSecondary,
                      bg: palette.surfaceAlt,
                      border: palette.hairline,
                    ),
                  if (user.isAdmin)
                    MetaPill(
                      text: 'Admin',
                      fg: palette.inkSecondary,
                      bg: palette.surfaceAlt,
                      border: palette.hairline,
                      upper: true,
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _prettyTier(String tier) => tier
      .replaceAll('_', ' ')
      .replaceFirstMapped(RegExp('^.'), (m) => m.group(0)!.toUpperCase());
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final profile = user.profile;
    final persona = profile?.persona;
    final personaLabel = (persona == null || persona.isEmpty)
        ? '—'
        : labelForValue(persona, personaOptions);
    final goals = labelsForValues(
      profile?.goalsList ?? const <String>[],
      goalOptions,
    );
    final dietary = labelsForValues(
      profile?.dietaryList ?? const <String>[],
      dietaryOptions,
    );
    final conditions = labelsForValues(
      profile?.conditionsList ?? const <String>[],
      conditionOptions,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
              const Eyebrow('Your profile', spacing: 4.2),
              const Spacer(),
              GestureDetector(
                onTap: () => context.pushNamed(Routes.onboarding),
                behavior: HitTestBehavior.opaque,
                child: Text(
                  'Edit',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: palette.brand,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _row(palette, 'Shopping for', personaLabel),
          _row(palette, 'Goals', goals.isEmpty ? '—' : goals.join(', ')),
          _row(palette, 'Dietary', dietary.isEmpty ? '—' : dietary.join(', ')),
          _row(
            palette,
            'Conditions',
            conditions.isEmpty ? '—' : conditions.join(', '),
          ),
        ],
      ),
    );
  }

  Widget _row(Palette palette, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: TextStyle(fontSize: 12.5, color: palette.inkFaint),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: palette.inkPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Restrained destructive area at the very bottom of the account screen.
/// Apple 5.1.1(v) requires account deletion to be reachable in-app: one quiet
/// concern-toned row that opens an explicit confirmation before anything
/// irreversible happens.
class _DangerZone extends ConsumerStatefulWidget {
  const _DangerZone();

  @override
  ConsumerState<_DangerZone> createState() => _DangerZoneState();
}

class _DangerZoneState extends ConsumerState<_DangerZone> {
  bool _deleting = false;

  Future<void> _confirmAndDelete() async {
    if (_deleting) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: _buildConfirmDialog,
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    // Resolve before the async gap — on success the sign-out flips the session
    // to null and the router redirect disposes this screen, but the app-level
    // messenger and router outlive it.
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    try {
      await ref.read(munchApiProvider).deleteAccount();
    } on ApiException catch (e) {
      // Deletion failed — the account still exists, so keep the session.
      if (mounted) setState(() => _deleting = false);
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
      return;
    }
    // Server side is gone; run the existing full sign-out path (best-effort
    // logout + token clear + Google session + auth state).
    await ref.read(authControllerProvider.notifier).signOut();
    router.goNamed(Routes.home);
    messenger.showSnackBar(
      const SnackBar(content: Text('Your account has been deleted.')),
    );
  }

  Widget _buildConfirmDialog(BuildContext dialogContext) {
    final palette = dialogContext.palette;
    return AlertDialog(
      backgroundColor: palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: palette.hairline),
      ),
      title: Text(
        'Delete your account?',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: palette.inkPrimary,
        ),
      ),
      content: Text(
        'This permanently deletes your account, scan history, votes, '
        'watchlist, and saved lists. There is no undo.',
        style: TextStyle(
          fontSize: 14.5,
          height: 1.5,
          color: palette.inkSecondary,
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          style: TextButton.styleFrom(foregroundColor: palette.inkSecondary),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: TextButton.styleFrom(foregroundColor: palette.concernHigh),
          child: const Text(
            'Delete account',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SectionLabel('Danger zone'),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _deleting ? null : _confirmAndDelete,
          icon: _deleting
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: palette.concernHigh,
                  ),
                )
              : const Icon(Icons.delete_outline, size: 18),
          label: Text(_deleting ? 'Deleting…' : 'Delete account'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            foregroundColor: palette.concernHigh,
            backgroundColor: palette.surface,
            shape: StadiumBorder(
              side: BorderSide(
                color: palette.concernHigh.withValues(alpha: 0.4),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Permanently removes your account, scan history, votes, watchlist, '
          'and saved lists.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12.5,
            height: 1.5,
            color: palette.inkFaint,
          ),
        ),
      ],
    );
  }
}

/// A full-width, muted outlined pill for the non-destructive sign-out action.
class _SignOutButton extends StatelessWidget {
  const _SignOutButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.logout, size: 18),
      label: const Text('Sign out'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        foregroundColor: palette.inkSecondary,
        backgroundColor: palette.surface,
        shape: StadiumBorder(side: BorderSide(color: palette.hairline)),
      ),
    );
  }
}
