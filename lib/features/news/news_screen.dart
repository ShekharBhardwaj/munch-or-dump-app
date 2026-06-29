import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:munch_or_dump/core/models/news.dart';
import 'package:munch_or_dump/core/providers.dart';
import 'package:munch_or_dump/core/router/routes.dart';
import 'package:munch_or_dump/core/widgets/async_states.dart';

final newsProvider = FutureProvider.autoDispose<NewsList>((ref) {
  return ref.watch(munchApiProvider).getNews();
});

final newsPostProvider = FutureProvider.autoDispose.family<NewsPost, String>((
  ref,
  slug,
) {
  return ref.watch(munchApiProvider).getNewsPost(slug);
});

class NewsScreen extends ConsumerWidget {
  const NewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final news = ref.watch(newsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('What’s new')),
      body: news.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorRetry(
          message: errorMessage(error),
          onRetry: () => ref.invalidate(newsProvider),
        ),
        data: (data) {
          if (data.items.isEmpty) {
            return const EmptyState(
              icon: Icons.article_outlined,
              message: 'No posts yet.',
            );
          }
          return ListView.separated(
            itemCount: data.items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final post = data.items[i];
              final date = formatNewsDate(post.publishedAt);
              return ListTile(
                title: Text(
                  post.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: date.isEmpty ? null : Text(date),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.pushNamed(
                  Routes.newsPost,
                  pathParameters: <String, String>{'slug': post.slug},
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class NewsPostScreen extends ConsumerWidget {
  const NewsPostScreen({required this.slug, super.key});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final post = ref.watch(newsPostProvider(slug));
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('News')),
      body: post.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorRetry(
          message: errorMessage(error),
          onRetry: () => ref.invalidate(newsPostProvider(slug)),
        ),
        data: (data) => ListView(
          padding: const EdgeInsets.all(20),
          children: <Widget>[
            Text(
              data.title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              formatNewsDate(data.publishedAt),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            SelectableText(data.body, style: theme.textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}

String formatNewsDate(String? iso) {
  if (iso == null || iso.isEmpty) return '';
  final dt = DateTime.tryParse(iso)?.toLocal();
  if (dt == null) return '';
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
}
