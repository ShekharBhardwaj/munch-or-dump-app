import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:munch_or_dump/core/api/api_exception.dart';
import 'package:munch_or_dump/core/models/analysis_result.dart';
import 'package:munch_or_dump/core/models/user_content.dart';
import 'package:munch_or_dump/core/providers.dart';
import 'package:munch_or_dump/core/theme/app_colors.dart';
import 'package:munch_or_dump/features/auth/auth_controller.dart';
import 'package:munch_or_dump/features/watchlist/watchlist_screen.dart'
    show libraryProvider;

/// Community munch/dump split for a product (anonymous-readable).
final voteSummaryProvider = FutureProvider.autoDispose
    .family<VoteSummary, String>((ref, productName) {
      return ref.watch(munchApiProvider).getVoteSummary(productName);
    });

/// Save / watch / community-vote actions for a product result.
///
/// Save/watch state is derived from the user's library (so it stays consistent
/// with the Watchlist screen and never shows a stale "Save" for an already-saved
/// product); a local override covers the in-flight optimistic toggle. Anonymous
/// taps prompt sign-in.
class ResultActions extends ConsumerStatefulWidget {
  const ResultActions({required this.result, super.key});

  final AnalysisResult result;

  @override
  ConsumerState<ResultActions> createState() => _ResultActionsState();
}

class _ResultActionsState extends ConsumerState<ResultActions> {
  bool? _savedOverride;
  bool? _watchedOverride;
  bool _busy = false;

  String? get _slug => widget.result.productSlug;
  bool get _loggedIn => ref.read(authControllerProvider).valueOrNull != null;

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _setSaved(bool next) async {
    final slug = _slug;
    if (slug == null || slug.isEmpty || _busy) return;
    if (!_loggedIn) return _snack('Sign in to save products.');
    setState(() {
      _busy = true;
      _savedOverride = next;
    });
    try {
      final api = ref.read(munchApiProvider);
      next ? await api.saveProduct(slug) : await api.unsaveProduct(slug);
      ref.invalidate(libraryProvider);
    } on ApiException catch (e) {
      if (mounted) setState(() => _savedOverride = !next);
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setWatched(bool next) async {
    final slug = _slug;
    if (slug == null || slug.isEmpty || _busy) return;
    if (!_loggedIn) return _snack('Sign in to watch products.');
    setState(() {
      _busy = true;
      _watchedOverride = next;
    });
    try {
      final api = ref.read(munchApiProvider);
      next
          ? await api.addWatch(productSlug: slug)
          : await api.removeWatch(productSlug: slug);
      ref.invalidate(libraryProvider);
    } on ApiException catch (e) {
      if (mounted) setState(() => _watchedOverride = !next);
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _vote(VoteChoice choice) async {
    final name = widget.result.productName;
    if (name.isEmpty || _busy) return;
    if (!_loggedIn) return _snack('Sign in to vote.');
    setState(() => _busy = true);
    try {
      await ref.read(munchApiProvider).castVote(name, choice);
      if (!mounted) return;
      ref.invalidate(voteSummaryProvider(name));
      _snack('Voted ${choice.apiValue}!');
    } on ApiException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  bool _isSavedIn(SavedLists saved, String slug) => saved.lists.values.any(
    (List<SavedItem> l) => l.any((SavedItem i) => i.productSlug == slug),
  );

  @override
  Widget build(BuildContext context) {
    final slug = _slug;
    final canSave = slug != null && slug.isNotEmpty;
    final name = widget.result.productName;

    final loggedIn = ref.watch(authControllerProvider).valueOrNull != null;
    final library = loggedIn ? ref.watch(libraryProvider).valueOrNull : null;
    final serverSaved =
        library != null && slug != null && _isSavedIn(library.saved, slug);
    final serverWatched =
        library != null &&
        slug != null &&
        library.watches.products.any(
          (WatchedProduct p) => p.productSlug == slug,
        );
    final saved = _savedOverride ?? serverSaved;
    final watched = _watchedOverride ?? serverWatched;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (canSave) ...<Widget>[
          const SizedBox(height: 24),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : () => _setSaved(!saved),
                  icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border),
                  label: Text(saved ? 'Saved' : 'Save'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : () => _setWatched(!watched),
                  icon: Icon(
                    watched
                        ? Icons.notifications_active
                        : Icons.notifications_none,
                  ),
                  label: Text(watched ? 'Watching' : 'Watch'),
                ),
              ),
            ],
          ),
        ],
        if (name.isNotEmpty)
          _CommunityVote(productName: name, enabled: !_busy, onVote: _vote),
      ],
    );
  }
}

class _CommunityVote extends ConsumerWidget {
  const _CommunityVote({
    required this.productName,
    required this.enabled,
    required this.onVote,
  });

  final String productName;
  final bool enabled;
  final Future<void> Function(VoteChoice) onVote;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final summary = ref.watch(voteSummaryProvider(productName));
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Community',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          summary.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => const SizedBox.shrink(),
            data: (s) => _VoteSplit(summary: s),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: enabled ? () => onVote(VoteChoice.munch) : null,
                  icon: const Text('🥑'),
                  label: const Text('Munch'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: enabled ? () => onVote(VoteChoice.dump) : null,
                  icon: const Text('🚮'),
                  label: const Text('Dump'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VoteSplit extends StatelessWidget {
  const _VoteSplit({required this.summary});

  final VoteSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (summary.totalVotes == 0) {
      return Text(
        'No votes yet — be the first.',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }
    final munchPct = summary.communityMunchPct.clamp(0, 100);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(
              '$munchPct% Munch',
              style: const TextStyle(
                color: AppColors.munch,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Text(
              '${summary.totalVotes} votes',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: munchPct / 100,
            minHeight: 8,
            backgroundColor: AppColors.dump.withValues(alpha: 0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.munch),
          ),
        ),
      ],
    );
  }
}
