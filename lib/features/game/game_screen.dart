import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:munch_or_dump/core/api/api_exception.dart';
import 'package:munch_or_dump/core/models/game.dart';
import 'package:munch_or_dump/core/providers.dart';
import 'package:munch_or_dump/core/widgets/async_states.dart';
import 'package:munch_or_dump/core/widgets/verdict_badge.dart';

enum _Phase { loading, playing, revealed, gameOver, error }

/// Guess which ingredient list belongs to the shown product. Correct → keep
/// going; wrong → game over, score recorded to the leaderboard.
class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  _Phase _phase = _Phase.loading;
  GameRound? _round;
  String? _selectedId;
  int _score = 0;
  int _streak = 0;
  String? _message;
  ScoreResult? _result;
  bool _wasCorrect = false;
  // Product ids already shown this game (the correct option's id is the target's
  // product id) — excluded from the next lineup so rounds don't repeat.
  final Set<String> _seen = <String>{};
  List<LeaderboardEntry> _leaderboard = const <LeaderboardEntry>[];

  @override
  void initState() {
    super.initState();
    _loadRound(reset: true);
  }

  Future<void> _loadRound({bool reset = false}) async {
    setState(() {
      _phase = _Phase.loading;
      if (reset) {
        _score = 0;
        _streak = 0;
        _seen.clear();
      }
    });
    try {
      final round = await ref
          .read(munchApiProvider)
          .getGameLineup(exclude: _seen.toList());
      if (!mounted) return;
      for (final option in round.options) {
        if (option.isCorrect) _seen.add(option.optionId);
      }
      setState(() {
        _round = round;
        _selectedId = null;
        _wasCorrect = false;
        _phase = _Phase.playing;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _phase = _Phase.error;
          _message = e is ApiException ? e.message : 'Couldn’t start the game.';
        });
      }
    }
  }

  void _guess(GameOption option) {
    if (_phase != _Phase.playing) return;
    setState(() {
      _selectedId = option.optionId;
      _wasCorrect = option.isCorrect;
      _phase = _Phase.revealed;
      if (option.isCorrect) {
        _score += 100;
        _streak += 1;
      }
    });
    if (!option.isCorrect) {
      unawaited(_endGame());
    }
  }

  Future<void> _endGame() async {
    List<LeaderboardEntry> board = const <LeaderboardEntry>[];
    ScoreResult? result;
    try {
      final api = ref.read(munchApiProvider);
      if (_score > 0) {
        result = await api.submitScore(score: _score, streak: _streak);
      }
      board = await api.getLeaderboard();
    } catch (_) {
      // Submitting/leaderboard is best-effort — a failure here must never trap
      // the player on the revealed round (it still falls through to gameOver).
    }
    if (!mounted) return;
    setState(() {
      _result = result;
      _leaderboard = board;
      _phase = _Phase.gameOver;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guess the ingredients'),
        actions: <Widget>[
          if (_phase == _Phase.playing || _phase == _Phase.revealed)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  'Score $_score',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
        ],
      ),
      body: switch (_phase) {
        _Phase.loading => const Center(child: CircularProgressIndicator()),
        _Phase.error => ErrorRetry(
          message: _message ?? 'Couldn’t start the game.',
          onRetry: () => _loadRound(reset: true),
        ),
        _Phase.gameOver => _GameOver(
          score: _score,
          result: _result,
          leaderboard: _leaderboard,
          onReplay: () => _loadRound(reset: true),
        ),
        _ => _RoundView(
          round: _round!,
          revealed: _phase == _Phase.revealed,
          canAdvance: _wasCorrect,
          selectedId: _selectedId,
          onGuess: _guess,
          onNext: _loadRound,
        ),
      },
    );
  }
}

class _RoundView extends StatelessWidget {
  const _RoundView({
    required this.round,
    required this.revealed,
    required this.canAdvance,
    required this.selectedId,
    required this.onGuess,
    required this.onNext,
  });

  final GameRound round;
  final bool revealed;
  final bool canAdvance;
  final String? selectedId;
  final void Function(GameOption) onGuess;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final target = round.target;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: <Widget>[
        Text(
          target.name,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        if (target.brandName != null && target.brandName!.isNotEmpty)
          Text(
            target.brandName!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        const SizedBox(height: 8),
        if (target.verdict != null)
          VerdictBadge(verdict: target.verdict!, score: target.verdictScore),
        const SizedBox(height: 20),
        Text(
          'Which ingredient list is this?',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        for (final option in round.options)
          _OptionCard(
            option: option,
            revealed: revealed,
            selected: option.optionId == selectedId,
            onTap: revealed ? null : () => onGuess(option),
          ),
        // Only a correct guess advances; a wrong guess ends the game (the
        // game-over transition is in flight), so no Next button is shown.
        if (revealed && canAdvance) ...<Widget>[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onNext,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Next'),
            ),
          ),
        ],
      ],
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.option,
    required this.revealed,
    required this.selected,
    required this.onTap,
  });

  final GameOption option;
  final bool revealed;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color? border;
    if (revealed) {
      if (option.isCorrect) {
        border = const Color(0xFF10B981);
      } else if (selected) {
        border = const Color(0xFFEF4444);
      }
    }
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: border != null
            ? BorderSide(color: border, width: 2)
            : BorderSide(color: theme.dividerColor),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Text(
            option.ingredients.take(6).join(', ') +
                (option.ingredients.length > 6 ? '…' : ''),
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ),
    );
  }
}

class _GameOver extends StatelessWidget {
  const _GameOver({
    required this.score,
    required this.result,
    required this.leaderboard,
    required this.onReplay,
  });

  final int score;
  final ScoreResult? result;
  final List<LeaderboardEntry> leaderboard;
  final VoidCallback onReplay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        const SizedBox(height: 12),
        Center(
          child: Text(
            'Game over',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'You scored $score'
            '${result?.rank != null ? '  ·  rank #${result!.rank}' : ''}',
            style: theme.textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: onReplay,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('Play again'),
          ),
        ),
        if (leaderboard.isNotEmpty) ...<Widget>[
          const SizedBox(height: 28),
          Text(
            'Top scores',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < leaderboard.length; i++)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Text('${i + 1}'),
              title: Text(leaderboard[i].name),
              trailing: Text('${leaderboard[i].score}'),
            ),
        ],
      ],
    );
  }
}
