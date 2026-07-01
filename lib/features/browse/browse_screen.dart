import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:munch_or_dump/core/router/routes.dart';
import 'package:munch_or_dump/core/theme/app_colors.dart';
import 'package:munch_or_dump/core/widgets/editorial.dart';

/// The Browse tab: a search entry + a grouped list of the catalog surfaces.
/// Replaces the old home "Browse" chip row.
class BrowseScreen extends StatelessWidget {
  const BrowseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: <Widget>[
            Text('Browse', style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: 16),
            _SearchField(onTap: () => context.pushNamed(Routes.search)),
            const SizedBox(height: 28),
            const Eyebrow('Explore the catalog', spacing: 4),
            const SizedBox(height: 12),
            _GroupCard(
              tiles: <_BrowseTile>[
                _BrowseTile(
                  icon: Icons.category_outlined,
                  label: 'Categories',
                  sub: 'Every food category, ranked',
                  onTap: () => context.pushNamed(Routes.categories),
                ),
                _BrowseTile(
                  icon: Icons.workspace_premium_outlined,
                  label: 'The verdicts',
                  sub: 'What each rating means',
                  onTap: () => context.pushNamed(Routes.examples),
                ),
                _BrowseTile(
                  icon: Icons.storefront_outlined,
                  label: 'Brands',
                  sub: 'The brand leaderboard',
                  onTap: () => context.pushNamed(Routes.brands),
                ),
                _BrowseTile(
                  icon: Icons.compare_arrows,
                  label: 'Compare',
                  sub: 'Two products, side by side',
                  onTap: () => context.pushNamed(Routes.compare),
                ),
                _BrowseTile(
                  icon: Icons.article_outlined,
                  label: 'News',
                  sub: 'What we’re reading',
                  onTap: () => context.pushNamed(Routes.news),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.hairline),
        ),
        child: const Row(
          children: <Widget>[
            Icon(Icons.search, color: AppColors.inkFaint, size: 20),
            SizedBox(width: 12),
            Text(
              'Search a product or brand…',
              style: TextStyle(fontSize: 14, color: AppColors.inkFaint),
            ),
          ],
        ),
      ),
    );
  }
}

/// A white grouped card holding a list of [_BrowseTile]s divided by hairlines.
class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.tiles});

  final List<_BrowseTile> tiles;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        children: <Widget>[
          for (var i = 0; i < tiles.length; i++) ...<Widget>[
            if (i > 0)
              const Padding(
                padding: EdgeInsets.only(left: 64),
                child: Divider(height: 1, color: AppColors.hairlineFaint),
              ),
            tiles[i],
          ],
        ],
      ),
    );
  }
}

class _BrowseTile extends StatelessWidget {
  const _BrowseTile({
    required this.icon,
    required this.label,
    required this.sub,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String sub;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: <Widget>[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, size: 20, color: AppColors.inkPrimary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.inkPrimary,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    sub,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.inkFaint,
                    ),
                  ),
                ],
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
