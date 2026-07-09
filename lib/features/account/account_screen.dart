import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:munch_or_dump/core/models/user.dart';
import 'package:munch_or_dump/core/router/routes.dart';
import 'package:munch_or_dump/core/theme/app_colors.dart';
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
            const Divider(height: 1, color: AppColors.hairlineFaint),
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
            const Divider(height: 1, color: AppColors.hairlineFaint),
            NavRow(
              icon: Icons.science_outlined,
              label: 'How it works',
              onTap: () => context.pushNamed(Routes.howItWorks),
            ),
            const Divider(height: 1, color: AppColors.hairlineFaint),
            NavRow(
              icon: Icons.auto_stories_outlined,
              label: 'Our story',
              onTap: () => context.pushNamed(Routes.ourStory),
            ),
            const Divider(height: 1, color: AppColors.hairlineFaint),
            NavRow(
              icon: Icons.gavel_outlined,
              label: 'Disclaimers & terms',
              onTap: () => context.pushNamed(Routes.legal),
            ),
            const Divider(height: 1, color: AppColors.hairlineFaint),
            NavRow(
              icon: Icons.lock_outline,
              label: 'Privacy policy',
              onTap: () => context.pushNamed(Routes.privacy),
            ),
            const SizedBox(height: 28),
            _SignOutButton(
              onTap: () => ref.read(authControllerProvider.notifier).signOut(),
            ),
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
            border: Border.all(color: AppColors.brand),
          ),
          child: Text(
            initial,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.brandDeep,
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
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.inkPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: <Widget>[
                  if (user.isPremium)
                    const MetaPill(
                      text: 'Premium',
                      fg: AppColors.brandDeep,
                      bg: Color(0xFFECFDF5),
                      border: AppColors.brand,
                      upper: true,
                    )
                  else
                    const MetaPill(
                      text: 'Free',
                      fg: AppColors.inkSecondary,
                      bg: AppColors.surfaceAlt,
                      border: AppColors.hairline,
                      upper: true,
                    ),
                  if (user.tier != null)
                    MetaPill(
                      text: _prettyTier(user.tier!),
                      fg: AppColors.inkSecondary,
                      bg: AppColors.surfaceAlt,
                      border: AppColors.hairline,
                    ),
                  if (user.isAdmin)
                    const MetaPill(
                      text: 'Admin',
                      fg: AppColors.inkSecondary,
                      bg: AppColors.surfaceAlt,
                      border: AppColors.hairline,
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.hairline),
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
                child: const Text(
                  'Edit',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.brand,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _row('Shopping for', personaLabel),
          _row('Goals', goals.isEmpty ? '—' : goals.join(', ')),
          _row('Dietary', dietary.isEmpty ? '—' : dietary.join(', ')),
          _row('Conditions', conditions.isEmpty ? '—' : conditions.join(', ')),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12.5, color: AppColors.inkFaint),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
                color: AppColors.inkPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A full-width, muted outlined pill for the non-destructive sign-out action.
class _SignOutButton extends StatelessWidget {
  const _SignOutButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.logout, size: 18),
      label: const Text('Sign out'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        foregroundColor: AppColors.inkSecondary,
        backgroundColor: AppColors.surface,
        shape: const StadiumBorder(side: BorderSide(color: AppColors.hairline)),
      ),
    );
  }
}
