import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:munch_or_dump/core/router/routes.dart';
import 'package:munch_or_dump/core/theme/app_colors.dart';
import 'package:munch_or_dump/core/widgets/editorial.dart';
import 'package:munch_or_dump/features/about/about_screens.dart';
import 'package:munch_or_dump/features/account/account_screen.dart';
import 'package:munch_or_dump/features/auth/auth_controller.dart';

/// The "You" tab: the full account when signed in, a sign-in invitation when
/// not. (Anonymous users still reach the legal docs from here.)
class YouScreen extends ConsumerWidget {
  const YouScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loggedIn = ref.watch(authControllerProvider).valueOrNull != null;
    return loggedIn ? const AccountScreen() : const _SignedOutYou();
  }
}

class _SignedOutYou extends StatelessWidget {
  const _SignedOutYou();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
          children: <Widget>[
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.hairline),
                ),
                child: const Icon(
                  Icons.person_outline,
                  size: 30,
                  color: AppColors.inkSecondary,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Sign in to Munch or Dump',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: AppColors.inkPrimary,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Scan products, save your verdicts, follow the ones you care '
              'about, and get a read tailored to you.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: AppColors.inkSecondary,
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: BlackCtaButton(
                label: 'Sign in',
                trailingIcon: null,
                onTap: () => context.pushNamed(Routes.login),
              ),
            ),
            const SizedBox(height: 40),
            const Eyebrow('About', spacing: 4),
            const SizedBox(height: 12),
            _LinkTile(
              icon: Icons.info_outline,
              label: 'About Munch or Dump',
              onTap: () => context.pushNamed(Routes.about),
            ),
            const Divider(height: 1, color: AppColors.hairlineFaint),
            _LinkTile(
              icon: Icons.science_outlined,
              label: 'How it works',
              onTap: () => context.pushNamed(Routes.howItWorks),
            ),
            const Divider(height: 1, color: AppColors.hairlineFaint),
            _LinkTile(
              icon: Icons.auto_stories_outlined,
              label: 'Our story',
              onTap: () => context.pushNamed(Routes.ourStory),
            ),
            const Divider(height: 1, color: AppColors.hairlineFaint),
            _LinkTile(
              icon: Icons.gavel_outlined,
              label: 'Disclaimers & terms',
              onTap: () => context.pushNamed(Routes.legal),
            ),
            const Divider(height: 1, color: AppColors.hairlineFaint),
            _LinkTile(
              icon: Icons.lock_outline,
              label: 'Privacy policy',
              onTap: () => context.pushNamed(Routes.privacy),
            ),
            const SizedBox(height: 28),
            const SatireFooter(),
          ],
        ),
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 20, color: AppColors.inkSecondary),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.inkPrimary,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: AppColors.inkGhost,
            ),
          ],
        ),
      ),
    );
  }
}
