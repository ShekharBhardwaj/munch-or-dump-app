import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:munch_or_dump/core/api/api_exception.dart';
import 'package:munch_or_dump/core/models/analysis_result.dart';
import 'package:munch_or_dump/core/models/user_content.dart';
import 'package:munch_or_dump/core/models/verdict.dart';
import 'package:munch_or_dump/core/providers.dart';
import 'package:munch_or_dump/core/theme/app_colors.dart';
import 'package:munch_or_dump/core/theme/verdict_palette.dart';
import 'package:munch_or_dump/core/widgets/editorial.dart';
import 'package:munch_or_dump/features/auth/auth_controller.dart';
import 'package:munch_or_dump/features/auth/sign_in_prompts.dart';
import 'package:munch_or_dump/features/watchlist/watchlist_screen.dart'
    show libraryProvider;
import 'package:share_plus/share_plus.dart';

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
    if (!_loggedIn) return _snack('Sign in to follow products.');
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

  void _share() {
    final AnalysisResult r = widget.result;
    final Verdict v = r.verdict;
    final StringBuffer msg = StringBuffer(
      'Munch or Dump says ${r.productName} is a '
      '${v.label.toUpperCase()} ${v.emoji} — ${r.verdictScore}/90.',
    );
    final String? slug = _slug;
    if (slug != null && slug.isNotEmpty) {
      msg.write('\nhttps://munchordump.com/p/$slug');
    }
    SharePlus.instance.share(ShareParams(text: msg.toString()));
  }

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
                  icon: Icon(watched ? Icons.bookmark : Icons.bookmark_border),
                  label: Text(watched ? 'Following' : 'Follow'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ] else
          const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: _share,
          icon: const Icon(Icons.ios_share),
          label: const Text('Share this verdict'),
        ),
        if (name.isNotEmpty)
          _CommunityVote(
            productName: name,
            enabled: !_busy,
            loggedIn: loggedIn,
            onVote: _vote,
          ),
      ],
    );
  }
}

/// The community munch/dump section, in the website's editorial language: a
/// bordered card with the vote split bar, then either the two tinted vote
/// pills (signed in) or an inline sign-in prompt (anonymous).
class _CommunityVote extends ConsumerWidget {
  const _CommunityVote({
    required this.productName,
    required this.enabled,
    required this.loggedIn,
    required this.onVote,
  });

  final String productName;
  final bool enabled;
  final bool loggedIn;
  final Future<void> Function(VoteChoice) onVote;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(voteSummaryProvider(productName));
    return Container(
      margin: const EdgeInsets.only(top: 24),
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
          const Eyebrow('Community verdict', spacing: 4.2),
          const SizedBox(height: 14),
          summary.when(
            loading: () => const Text(
              'Tallying the community…',
              style: TextStyle(fontSize: 13, color: AppColors.inkFaint),
            ),
            error: (_, _) => const SizedBox.shrink(),
            data: (s) => _VoteSplit(summary: s),
          ),
          const SizedBox(height: 18),
          if (loggedIn)
            Row(
              children: <Widget>[
                _VoteButton(
                  toneVerdict: Verdict.munch,
                  emoji: '🥑',
                  label: 'Munch',
                  onTap: enabled ? () => onVote(VoteChoice.munch) : null,
                ),
                const SizedBox(width: 12),
                _VoteButton(
                  toneVerdict: Verdict.dump,
                  emoji: '🚮',
                  label: 'Dump',
                  onTap: enabled ? () => onVote(VoteChoice.dump) : null,
                ),
              ],
            )
          else
            const Align(
              alignment: Alignment.centerLeft,
              child: SignInInline(
                action: 'Sign in',
                rest: ' to add your vote',
                align: TextAlign.left,
              ),
            ),
        ],
      ),
    );
  }
}

/// One tinted, tappable vote pill keyed to a verdict's tones.
class _VoteButton extends StatelessWidget {
  const _VoteButton({
    required this.toneVerdict,
    required this.emoji,
    required this.label,
    required this.onTap,
  });

  final Verdict toneVerdict;
  final String emoji;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tone = verdictToneFor(toneVerdict);
    return Expanded(
      child: Opacity(
        opacity: onTap == null ? 0.55 : 1,
        child: Material(
          color: tone.tint,
          borderRadius: BorderRadius.circular(999),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: tone.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  ExcludeSemantics(
                    child: Text(emoji, style: const TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                      color: tone.word,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VoteSplit extends StatelessWidget {
  const _VoteSplit({required this.summary});

  final VoteSummary summary;

  @override
  Widget build(BuildContext context) {
    if (summary.totalVotes == 0) {
      return const Text(
        'No votes yet — be the first.',
        style: TextStyle(fontSize: 13.5, color: AppColors.inkFaint),
      );
    }
    final munchPct = summary.communityMunchPct.clamp(0, 100);
    final dumpPct = 100 - munchPct;
    final munchTone = verdictToneFor(Verdict.munch);
    final dumpTone = verdictToneFor(Verdict.dump);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(
              '$munchPct% Munch',
              style: TextStyle(
                color: munchTone.word,
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
              ),
            ),
            const Spacer(),
            Text(
              '$dumpPct% Dump',
              style: TextStyle(
                color: dumpTone.word,
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 8,
            child: ColoredBox(
              color: dumpTone.bar,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: munchPct / 100,
                child: ColoredBox(color: munchTone.bar),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${summary.totalVotes} ${summary.totalVotes == 1 ? "vote" : "votes"}',
          style: const TextStyle(fontSize: 12, color: AppColors.inkFaint),
        ),
      ],
    );
  }
}
