import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:munch_or_dump/core/api/api_exception.dart';
import 'package:munch_or_dump/core/models/user_content.dart';
import 'package:munch_or_dump/core/providers.dart';
import 'package:munch_or_dump/core/router/routes.dart';
import 'package:munch_or_dump/core/widgets/async_states.dart';
import 'package:munch_or_dump/core/widgets/verdict_badge.dart';

typedef _LibraryData = ({SavedLists saved, Watches watches});

/// Saved lists + watches in one load.
final libraryProvider = FutureProvider.autoDispose<_LibraryData>((ref) async {
  final api = ref.watch(munchApiProvider);
  return (saved: await api.getSavedLists(), watches: await api.getWatches());
});

class WatchlistScreen extends ConsumerWidget {
  const WatchlistScreen({super.key});

  Future<void> _remove(
    WidgetRef ref,
    BuildContext context,
    Future<void> Function() op,
  ) async {
    try {
      await op();
      ref.invalidate(libraryProvider);
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  void _openProduct(BuildContext context, String slug) {
    if (slug.isEmpty) return;
    context.pushNamed(
      Routes.product,
      pathParameters: <String, String>{'slug': slug},
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final library = ref.watch(libraryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Saved & watching')),
      body: library.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorRetry(
          message: '$error',
          onRetry: () => ref.invalidate(libraryProvider),
        ),
        data: (data) {
          final api = ref.read(munchApiProvider);
          final savedItems = data.saved.lists.values
              .expand((List<SavedItem> l) => l)
              .toList();
          if (data.saved.isEmpty && data.watches.isEmpty) {
            return const EmptyState(
              icon: Icons.bookmark_border,
              message:
                  'Nothing saved yet. Save or watch a product from its '
                  'verdict to see it here.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              try {
                // Awaited for the side effect; refresh (not invalidate) keeps
                // the list visible during the reload.
                // ignore: unused_result
                await ref.refresh(libraryProvider.future);
              } on ApiException catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(e.message)));
                }
              }
            },
            child: ListView(
              children: <Widget>[
                if (savedItems.isNotEmpty) ...<Widget>[
                  const _SectionHeader('Saved'),
                  for (final item in savedItems)
                    ListTile(
                      title: Text(
                        item.productName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: item.brandName != null
                          ? Text(item.brandName!)
                          : null,
                      leading: item.verdict != null
                          ? VerdictBadge(verdict: item.verdict!)
                          : null,
                      trailing: IconButton(
                        icon: const Icon(Icons.bookmark_remove_outlined),
                        tooltip: 'Remove',
                        onPressed: () => _remove(
                          ref,
                          context,
                          () => api.unsaveProduct(item.productSlug),
                        ),
                      ),
                      onTap: () => _openProduct(context, item.productSlug),
                    ),
                ],
                if (data.watches.products.isNotEmpty) ...<Widget>[
                  const _SectionHeader('Watching products'),
                  for (final p in data.watches.products)
                    ListTile(
                      title: Text(
                        p.productName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      leading: p.verdict != null
                          ? VerdictBadge(verdict: p.verdict!)
                          : null,
                      trailing: IconButton(
                        icon: const Icon(Icons.notifications_off_outlined),
                        tooltip: 'Stop watching',
                        onPressed: () => _remove(
                          ref,
                          context,
                          () => api.removeWatch(productSlug: p.productSlug),
                        ),
                      ),
                      onTap: () => _openProduct(context, p.productSlug),
                    ),
                ],
                if (data.watches.brands.isNotEmpty) ...<Widget>[
                  const _SectionHeader('Watching brands'),
                  for (final b in data.watches.brands)
                    ListTile(
                      title: Text(
                        b.brandName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text('${b.productCount} products'),
                      trailing: IconButton(
                        icon: const Icon(Icons.notifications_off_outlined),
                        tooltip: 'Stop watching',
                        onPressed: () => _remove(
                          ref,
                          context,
                          () => api.removeWatch(brandSlug: b.brandSlug),
                        ),
                      ),
                    ),
                ],
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }
}
