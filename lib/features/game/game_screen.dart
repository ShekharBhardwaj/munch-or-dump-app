import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:munch_or_dump/core/api/api_exception.dart';
import 'package:munch_or_dump/core/models/game.dart';
import 'package:munch_or_dump/core/providers.dart';
import 'package:munch_or_dump/core/router/routes.dart';
import 'package:munch_or_dump/core/theme/app_colors.dart';
import 'package:munch_or_dump/core/widgets/async_states.dart';
import 'package:munch_or_dump/core/widgets/editorial.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

const int kRoundTime = 15; // seconds per round
const int kMaxLives = 3;
const int kBasePts = 100;
const int kSpeedBonus = 50;
const String kBestScoreKey = 'munchordump_game_best';

const List<String> _correctQuips = <String>[
  'You can read a label.',
  'Ingredient-literate. Rare.',
  'Nothing gets past you.',
  'You’ve done this before.',
  'You’re not easily fooled.',
];
const List<String> _wrongQuips = <String>[
  'The marketing team wins again.',
  'They got you.',
  'Trickier than it looks.',
  'Don’t feel bad. Most people miss this.',
];
const List<String> _timeoutQuips = <String>[
  'Too slow. The food aisle waits for no one.',
  'Time’s up.',
  'Hesitation costs you.',
];

const Color _emerald = Color(0xFF10B981);
const Color _red = Color(0xFFEF4444);
const Color _amber = Color(0xFFF59E0B);
const Color _flame = Color(0xFFF97316);

enum _Phase { start, loading, playing, revealed, gameOver, error }

/// "Can You Tell?" — read the label better than the AI. A lives-and-clock
/// survival game: 3 lives, 15s per round, weighted scoring (base + speed +
/// streak). Matches the web game.
class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  final Random _rng = Random();

  _Phase _phase = _Phase.start;
  GameRound? _round;
  String? _selectedId;

  int _score = 0;
  int _streak = 0;
  int _bestStreak = 0;
  int _lives = kMaxLives;
  int _roundNum = 0;
  int _timeLeft = kRoundTime;
  int _earned = 0;
  bool _wasCorrect = false;
  bool _timedOut = false;
  String _quip = '';

  int _bestScore = 0;
  bool _isNewBest = false;
  ScoreResult? _result;
  List<LeaderboardEntry> _leaderboard = const <LeaderboardEntry>[];
  bool _notEnough = false;
  String? _message;

  final Set<String> _seen = <String>{};
  Timer? _roundTimer;
  Timer? _advanceTimer;

  @override
  void initState() {
    super.initState();
    _loadStartData();
  }

  @override
  void dispose() {
    _roundTimer?.cancel();
    _advanceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadStartData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _bestScore = prefs.getInt(kBestScoreKey) ?? 0;
    } catch (_) {
      /* best score is non-critical */
    }
    try {
      final board = await ref.read(munchApiProvider).getLeaderboard();
      if (mounted) setState(() => _leaderboard = board);
    } catch (_) {
      /* start-screen leaderboard is best-effort */
    }
  }

  Future<void> _loadRound({bool reset = false}) async {
    _roundTimer?.cancel();
    _advanceTimer?.cancel();
    setState(() {
      _phase = _Phase.loading;
      _notEnough = false;
      if (reset) {
        _score = 0;
        _streak = 0;
        _bestStreak = 0;
        _lives = kMaxLives;
        _roundNum = 0;
        _isNewBest = false;
        _result = null;
        _seen.clear();
      }
    });
    try {
      final round = await ref
          .read(munchApiProvider)
          .getGameLineup(exclude: _seen.toList());
      if (!mounted) return;
      if (round.options.length < 2 || round.target.name.isEmpty) {
        setState(() {
          _phase = _Phase.error;
          _notEnough = true;
        });
        return;
      }
      for (final option in round.options) {
        if (option.isCorrect) _seen.add(option.optionId);
      }
      setState(() {
        _round = round;
        _selectedId = null;
        _wasCorrect = false;
        _timedOut = false;
        _earned = 0;
        _timeLeft = kRoundTime;
        _roundNum += 1;
        _phase = _Phase.playing;
      });
      _startTimer();
    } catch (e) {
      if (mounted) {
        setState(() {
          _phase = _Phase.error;
          _message = e is ApiException ? e.message : 'Couldn’t start the game.';
        });
      }
    }
  }

  void _startTimer() {
    _roundTimer?.cancel();
    _roundTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _phase != _Phase.playing) return;
      if (_timeLeft <= 1) {
        _onTimeout();
      } else {
        setState(() => _timeLeft -= 1);
      }
    });
  }

  void _guess(GameOption option) {
    if (_phase != _Phase.playing) return;
    _roundTimer?.cancel();
    setState(() {
      _selectedId = option.optionId;
      _phase = _Phase.revealed;
      if (option.isCorrect) {
        final speedPts = ((_timeLeft / kRoundTime) * kSpeedBonus).round();
        final streakPts = _streak.clamp(0, 4) * 20; // uses streak BEFORE bump
        _earned = kBasePts + speedPts + streakPts;
        _score += _earned;
        _streak += 1;
        _bestStreak = max(_bestStreak, _streak);
        _wasCorrect = true;
        _quip = _correctQuips[_rng.nextInt(_correctQuips.length)];
      } else {
        _earned = 0;
        _streak = 0;
        _lives -= 1;
        _wasCorrect = false;
        _quip = _wrongQuips[_rng.nextInt(_wrongQuips.length)];
      }
    });
    _scheduleAdvance();
  }

  void _onTimeout() {
    if (_phase != _Phase.playing) return;
    _roundTimer?.cancel();
    setState(() {
      _selectedId = null;
      _phase = _Phase.revealed;
      _earned = 0;
      _streak = 0;
      _lives -= 1;
      _wasCorrect = false;
      _timedOut = true;
      _quip = _timeoutQuips[_rng.nextInt(_timeoutQuips.length)];
    });
    _scheduleAdvance();
  }

  void _scheduleAdvance() {
    final over = _lives <= 0;
    final ms = over ? (_timedOut ? 2200 : 2400) : 2600;
    _advanceTimer = Timer(Duration(milliseconds: ms), () {
      if (!mounted) return;
      over ? _endGame() : _loadRound();
    });
  }

  Future<void> _endGame() async {
    _roundTimer?.cancel();
    final api = ref.read(munchApiProvider);
    ScoreResult? result;
    var board = _leaderboard;
    try {
      if (_score > 0) {
        result = await api.submitScore(score: _score, streak: _bestStreak);
      }
      board = await api.getLeaderboard();
    } catch (_) {
      /* submit + leaderboard are best-effort */
    }
    var isNewBest = false;
    if (_score > _bestScore) {
      isNewBest = true;
      final previous = _bestScore;
      _bestScore = _score;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(kBestScoreKey, _score);
      } catch (_) {
        _bestScore = previous; // persist failed — keep the old best
      }
    }
    if (!mounted) return;
    setState(() {
      _result = result;
      _leaderboard = board;
      _isNewBest = isNewBest;
      _phase = _Phase.gameOver;
    });
  }

  Future<void> _share() async {
    await SharePlus.instance.share(
      ShareParams(
        text:
            'I scored $_score on Munch or Dump’s “Can You Tell?” 🍩 Think you '
            'can read a label better than me?\nhttps://munchordump.com/Game',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SafeArea(
        top: false,
        child: switch (_phase) {
          _Phase.start => _StartView(
            leaderboard: _leaderboard,
            onPlay: () => _loadRound(reset: true),
          ),
          _Phase.loading => const PageLoader(),
          _Phase.error =>
            _notEnough
                ? _NotEnoughView(onScan: () => context.pushNamed(Routes.scan))
                : ErrorRetry(
                    message: _message ?? 'Couldn’t start the game.',
                    onRetry: () => _loadRound(reset: true),
                  ),
          _Phase.gameOver => _GameOver(
            score: _score,
            bestScore: _bestScore,
            isNewBest: _isNewBest,
            bestStreak: _bestStreak,
            rounds: _roundNum,
            result: _result,
            leaderboard: _leaderboard,
            onReplay: () => _loadRound(reset: true),
            onShare: _share,
          ),
          _ => _RoundView(
            round: _round!,
            roundNum: _roundNum,
            lives: _lives,
            score: _score,
            streak: _streak,
            timeLeft: _timeLeft,
            revealed: _phase == _Phase.revealed,
            wasCorrect: _wasCorrect,
            timedOut: _timedOut,
            earned: _earned,
            quip: _quip,
            selectedId: _selectedId,
            onGuess: _guess,
          ),
        },
      ),
    );
  }
}

class _RoundView extends StatelessWidget {
  const _RoundView({
    required this.round,
    required this.roundNum,
    required this.lives,
    required this.score,
    required this.streak,
    required this.timeLeft,
    required this.revealed,
    required this.wasCorrect,
    required this.timedOut,
    required this.earned,
    required this.quip,
    required this.selectedId,
    required this.onGuess,
  });

  final GameRound round;
  final int roundNum;
  final int lives;
  final int score;
  final int streak;
  final int timeLeft;
  final bool revealed;
  final bool wasCorrect;
  final bool timedOut;
  final int earned;
  final String quip;
  final String? selectedId;
  final void Function(GameOption) onGuess;

  @override
  Widget build(BuildContext context) {
    final target = round.target;
    final sub = <String>[
      if ((target.brandName ?? '').trim().isNotEmpty) target.brandName!.trim(),
      if ((target.category ?? '').trim().isNotEmpty) target.category!.trim(),
    ].join(' · ');
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      children: <Widget>[
        _Hud(lives: lives, score: score, streak: streak),
        const SizedBox(height: 12),
        _TimerBar(fraction: timeLeft / kRoundTime),
        const SizedBox(height: 24),
        Eyebrow(
          'Round $roundNum · Which list belongs to',
          size: 11,
          spacing: 2,
        ),
        const SizedBox(height: 8),
        Text(
          target.name,
          style: const TextStyle(
            fontSize: 26,
            height: 1.1,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
            color: AppColors.inkPrimary,
          ),
        ),
        if (sub.isNotEmpty) ...<Widget>[
          const SizedBox(height: 4),
          Text(
            sub,
            style: const TextStyle(fontSize: 13, color: AppColors.inkFaint),
          ),
        ],
        const SizedBox(height: 20),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.92,
          children: <Widget>[
            for (final option in round.options)
              _OptionCard(
                option: option,
                revealed: revealed,
                selected: option.optionId == selectedId,
                onTap: revealed ? null : () => onGuess(option),
              ),
          ],
        ),
        if (revealed) ...<Widget>[
          const SizedBox(height: 20),
          _RevealPanel(
            target: target,
            wasCorrect: wasCorrect,
            timedOut: timedOut,
            earned: earned,
            quip: quip,
          ),
        ],
      ],
    );
  }
}

class _Hud extends StatelessWidget {
  const _Hud({required this.lives, required this.score, required this.streak});

  final int lives;
  final int score;
  final int streak;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: Semantics(
            label: '$lives of $kMaxLives lives',
            child: ExcludeSemantics(
              child: Row(
                children: <Widget>[
                  for (var i = 0; i < kMaxLives; i++)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(
                        i < lives ? Icons.favorite : Icons.favorite_border,
                        size: 18,
                        color: i < lives ? _red : AppColors.inkGhost,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        Column(
          children: <Widget>[
            const Eyebrow('Score', size: 10, spacing: 2),
            Text(
              '$score',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.inkPrimary,
                fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              if (streak > 0) ...<Widget>[
                const Icon(
                  Icons.local_fire_department,
                  size: 18,
                  color: _flame,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                '$streak',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: streak > 0 ? _flame : AppColors.inkGhost,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TimerBar extends StatelessWidget {
  const _TimerBar({required this.fraction});

  final double fraction;

  @override
  Widget build(BuildContext context) {
    final f = fraction.clamp(0.0, 1.0);
    final color = f > 0.55 ? _emerald : (f > 0.28 ? _amber : _red);
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Stack(
        children: <Widget>[
          Container(height: 8, color: AppColors.hairline),
          AnimatedFractionallySizedBox(
            duration: const Duration(milliseconds: 400),
            widthFactor: f,
            child: Container(height: 8, color: color),
          ),
        ],
      ),
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
    Color border = AppColors.hairline;
    double opacity = 1;
    Widget? badge;
    if (revealed) {
      if (option.isCorrect) {
        border = _emerald;
        badge = const _CornerBadge(color: _emerald, icon: Icons.check);
      } else if (selected) {
        border = _red;
        badge = const _CornerBadge(color: _red, icon: Icons.close);
      } else {
        opacity = 0.25;
      }
    }
    final shown = option.ingredients.take(5).toList();
    final extra = option.ingredients.length - shown.length;
    return Opacity(
      opacity: opacity,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: border,
                width: border == AppColors.hairline ? 1 : 2,
              ),
            ),
            child: Stack(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      for (var i = 0; i < shown.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Text(
                            shown[i],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              height: 1.25,
                              fontWeight: i == 0
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: i == 0
                                  ? AppColors.inkPrimary
                                  : AppColors.inkSecondary,
                            ),
                          ),
                        ),
                      if (extra > 0)
                        Text(
                          '+$extra more',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.inkFaint,
                          ),
                        ),
                    ],
                  ),
                ),
                if (badge != null) Positioned(top: 8, right: 8, child: badge),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CornerBadge extends StatelessWidget {
  const _CornerBadge({required this.color, required this.icon});

  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Icon(icon, size: 13, color: Colors.white),
    );
  }
}

class _RevealPanel extends StatelessWidget {
  const _RevealPanel({
    required this.target,
    required this.wasCorrect,
    required this.timedOut,
    required this.earned,
    required this.quip,
  });

  final GameTarget target;
  final bool wasCorrect;
  final bool timedOut;
  final int earned;
  final String quip;

  @override
  Widget build(BuildContext context) {
    final quipColor = wasCorrect
        ? _emerald
        : (timedOut ? AppColors.inkSecondary : _red);
    final explanation = target.shortExplanation?.trim() ?? '';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
              if (target.verdict != null)
                WebVerdictBadge(verdict: target.verdict!, size: 11),
              const Spacer(),
              if (wasCorrect && earned > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '+$earned pts',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF047857),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            quip,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: quipColor,
            ),
          ),
          if (explanation.isNotEmpty) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              explanation,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppColors.inkSecondary,
              ),
            ),
          ],
          if ((target.slug ?? '').isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            InkWell(
              onTap: () => context.pushNamed(
                Routes.product,
                pathParameters: <String, String>{'slug': target.slug!},
              ),
              child: const Text(
                'Full analysis →',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.brand,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StartView extends StatelessWidget {
  const _StartView({required this.leaderboard, required this.onPlay});

  final List<LeaderboardEntry> leaderboard;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      children: <Widget>[
        const SizedBox(height: 12),
        const Center(child: _TrophyCircle()),
        const SizedBox(height: 20),
        const Eyebrow('Can you tell?', spacing: 4, align: TextAlign.center),
        const SizedBox(height: 10),
        const Text(
          'Read the label\nbetter than the AI.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 30,
            height: 1.1,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
            color: AppColors.inkPrimary,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Guess the verdict from the ingredients, beat the clock, and climb '
          'the board.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            height: 1.5,
            color: AppColors.inkSecondary,
          ),
        ),
        const SizedBox(height: 28),
        Center(
          child: BlackCtaButton(label: 'Play', onTap: onPlay),
        ),
        if (leaderboard.isNotEmpty) ...<Widget>[
          const SizedBox(height: 32),
          const SectionLabel('High scores'),
          const SizedBox(height: 12),
          _LeaderboardCard(entries: leaderboard),
        ],
      ],
    );
  }
}

class _GameOver extends StatelessWidget {
  const _GameOver({
    required this.score,
    required this.bestScore,
    required this.isNewBest,
    required this.bestStreak,
    required this.rounds,
    required this.result,
    required this.leaderboard,
    required this.onReplay,
    required this.onShare,
  });

  final int score;
  final int bestScore;
  final bool isNewBest;
  final int bestStreak;
  final int rounds;
  final ScoreResult? result;
  final List<LeaderboardEntry> leaderboard;
  final VoidCallback onReplay;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      children: <Widget>[
        const SizedBox(height: 12),
        const Center(child: _TrophyCircle()),
        const SizedBox(height: 16),
        const Eyebrow('Game over', spacing: 4, align: TextAlign.center),
        const SizedBox(height: 12),
        Center(
          child: Text(
            '$score',
            style: const TextStyle(
              fontSize: 56,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: -2,
              color: AppColors.inkPrimary,
              fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
        ),
        const Center(
          child: Text(
            'points',
            style: TextStyle(fontSize: 13, color: AppColors.inkFaint),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            isNewBest ? '🏆 New best score!' : 'Best: $bestScore',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isNewBest ? const Color(0xFF047857) : AppColors.inkFaint,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _Stat(label: 'Best streak', value: '$bestStreak'),
            Container(
              width: 1,
              height: 32,
              margin: const EdgeInsets.symmetric(horizontal: 24),
              color: AppColors.hairline,
            ),
            _Stat(label: 'Rounds', value: '$rounds'),
          ],
        ),
        if (result != null && result!.name.isNotEmpty) ...<Widget>[
          const SizedBox(height: 16),
          Center(
            child: Text(
              'You’re ${result!.name}'
              '${result!.rank != null ? ' — ranked #${result!.rank}' : ''}',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.inkSecondary,
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        Center(
          child: BlackCtaButton(
            label: 'Play again',
            leadingIcon: Icons.refresh,
            trailingIcon: null,
            onTap: onReplay,
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: onShare,
            child: const Text('Share your score'),
          ),
        ),
        if (leaderboard.isNotEmpty) ...<Widget>[
          const SizedBox(height: 24),
          const SectionLabel('Leaderboard'),
          const SizedBox(height: 12),
          _LeaderboardCard(entries: leaderboard, highlightName: result?.name),
        ],
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.inkPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.inkFaint),
        ),
      ],
    );
  }
}

class _LeaderboardCard extends StatelessWidget {
  const _LeaderboardCard({required this.entries, this.highlightName});

  final List<LeaderboardEntry> entries;
  final String? highlightName;

  @override
  Widget build(BuildContext context) {
    final top = entries.take(6).toList();
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        children: <Widget>[
          for (var i = 0; i < top.length; i++)
            Container(
              decoration: BoxDecoration(
                color: (highlightName != null && top[i].name == highlightName)
                    ? const Color(0xFFFFFBEB)
                    : null,
                border: i == 0
                    ? null
                    : const Border(
                        top: BorderSide(color: AppColors.hairlineFaint),
                      ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: 28,
                    child: Text(
                      '#${top[i].rank ?? i + 1}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.inkFaint,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      top[i].name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.inkPrimary,
                      ),
                    ),
                  ),
                  Text(
                    '${top[i].score}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.inkSecondary,
                      fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TrophyCircle extends StatelessWidget {
  const _TrophyCircle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: const BoxDecoration(
        color: AppColors.inkPrimary,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.emoji_events, size: 30, color: _amber),
    );
  }
}

class _NotEnoughView extends StatelessWidget {
  const _NotEnoughView({required this.onScan});

  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text(
              'Not enough products to play yet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.inkPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Scan a few products first, then come back.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.inkSecondary),
            ),
            const SizedBox(height: 20),
            BlackCtaButton(label: 'Scan a product', onTap: onScan),
          ],
        ),
      ),
    );
  }
}
