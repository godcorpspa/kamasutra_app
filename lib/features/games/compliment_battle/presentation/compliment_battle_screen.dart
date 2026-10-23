import 'dart:async';
import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme.dart';
import '../../../../shared/utils/display_text.dart';
import '../../shared/game_kit.dart';
import '../domain/compliment_scoring.dart';

/// Compliment Battle: each round draws a category; both partners in turn
/// pay the other a compliment on it before the clock runs out, and the
/// receiver judges it. Quicker and better compliments score more, streaks
/// multiply, and a golden category now and then doubles the points.
class ComplimentBattleScreen extends StatefulWidget {
  const ComplimentBattleScreen({super.key});

  @override
  State<ComplimentBattleScreen> createState() => _ComplimentBattleScreenState();
}

enum _Phase { setup, ready, speaking, judging, result, finished }

class _Category {
  final String key;
  final IconData icon;

  const _Category(this.key, this.icon);
}

const _categories = [
  _Category('physical', Icons.visibility_outlined),
  _Category('personality', Icons.psychology_alt_outlined),
  _Category('talents', Icons.star_outline_rounded),
  _Category('moments', Icons.photo_outlined),
  _Category('feelings', Icons.favorite_border_rounded),
  _Category('unique', Icons.fingerprint_rounded),
  _Category('intelligence', Icons.lightbulb_outline_rounded),
  _Category('kindness', Icons.volunteer_activism_outlined),
  _Category('passion', Icons.local_fire_department_outlined),
  _Category('creativity', Icons.palette_outlined),
];

/// Seconds to answer per difficulty — the same numbers the setup shows.
const _times = {'easy': 20, 'normal': 15, 'hard': 10};

class _ComplimentBattleScreenState extends State<ComplimentBattleScreen> {
  final _session = GameSession();
  final _random = Random();
  late final GameCountdown _countdown = GameCountdown(
    onTick: () {
      if (!mounted) return;
      final left = _countdown.remaining;
      if (left <= 3 && left > 0) HapticFeedback.selectionClick();
      setState(() {});
    },
    onDone: () => _finishTurn(points: 0, outcome: _Outcome.timeout),
  );
  Timer? _readyTimer;

  _Phase _phase = _Phase.setup;
  String _difficulty = 'normal';
  int _totalRounds = 5;
  int _round = 1;
  int _player = 1;
  final _scores = [0, 0];
  final _streaks = [0, 0];
  final _extraTimeUsed = [false, false];
  final _skipUsed = [false, false];
  int _longestStreak = 0;
  int _complimentsLanded = 0;
  late ShuffleBag<_Category> _deck;
  _Category _category = _categories.first;
  bool _bonus = false;
  int _lastPoints = 0;
  _Outcome _lastOutcome = _Outcome.timeout;

  int get _judge => 3 - _player;

  @override
  void dispose() {
    _readyTimer?.cancel();
    _countdown.cancel();
    _session.finish();
    super.dispose();
  }

  List<String> get _rules => [
        'games.compliment_battle.rule1'.tr(),
        'games.compliment_battle.rule2'.tr(),
        'games.compliment_battle.rule3'.tr(),
        'games.compliment_battle.rule4'.tr(),
        'games.compliment_battle.rule5'.tr(),
      ];

  // ── Flow ───────────────────────────────────────────────────────────────

  void _start() {
    _session.start();
    _deck = ShuffleBag(_categories);
    setState(() {
      _round = 1;
      _player = 1;
      _scores.fillRange(0, 2, 0);
      _streaks.fillRange(0, 2, 0);
      _extraTimeUsed.fillRange(0, 2, false);
      _skipUsed.fillRange(0, 2, false);
      _longestStreak = 0;
      _complimentsLanded = 0;
    });
    _drawCategory(allowBonus: false);
    _beginTurn();
  }

  void _drawCategory({required bool allowBonus}) {
    _category = _deck.next();
    // One round in five (never the first) is a golden category.
    _bonus = allowBonus && _random.nextInt(5) == 0;
  }

  /// Two seconds to read the category, then the clock starts.
  void _beginTurn() {
    _readyTimer?.cancel();
    _countdown.cancel();
    setState(() => _phase = _Phase.ready);
    _readyTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted || _phase != _Phase.ready) return;
      HapticFeedback.mediumImpact();
      setState(() => _phase = _Phase.speaking);
      _countdown.start(_times[_difficulty]!);
    });
  }

  void _extraTime() {
    HapticFeedback.mediumImpact();
    setState(() {
      _extraTimeUsed[_player - 1] = true;
      _countdown.remaining += 5;
      _countdown.total += 5;
    });
  }

  void _skipCategory() {
    HapticFeedback.mediumImpact();
    setState(() {
      _skipUsed[_player - 1] = true;
      _category = _deck.next();
    });
  }

  void _complimentGiven() {
    _countdown.pause();
    HapticFeedback.mediumImpact();
    setState(() => _phase = _Phase.judging);
  }

  void _pass() {
    _readyTimer?.cancel();
    _finishTurn(points: 0, outcome: _Outcome.passed);
  }

  void _judgeCompliment(int judgment) {
    final result = ComplimentScoring.judge(
      judgment: judgment,
      timeRemaining: _countdown.remaining,
      currentStreak: _streaks[_player - 1],
      bonusRound: _bonus,
    );
    _streaks[_player - 1] = result.newStreak;
    _longestStreak = max(_longestStreak, result.newStreak);
    if (result.complimentRegistered) _complimentsLanded++;
    _finishTurn(
      points: result.points,
      outcome: result.points > 0 ? _Outcome.scored : _Outcome.weak,
    );
  }

  void _finishTurn({required int points, required _Outcome outcome}) {
    if (_phase == _Phase.result || _phase == _Phase.finished) return;
    _countdown.cancel();
    HapticFeedback.heavyImpact();
    setState(() {
      if (points == 0) _streaks[_player - 1] = 0;
      _scores[_player - 1] += points;
      _lastPoints = points;
      _lastOutcome = outcome;
      _phase = _Phase.result;
    });
  }

  void _next() {
    if (_player == 1) {
      // Same category for the other partner.
      setState(() => _player = 2);
      _beginTurn();
      return;
    }
    if (_round >= _totalRounds) {
      _session.finish();
      setState(() => _phase = _Phase.finished);
      return;
    }
    setState(() {
      _round++;
      _player = 1;
    });
    _drawCategory(allowBonus: true);
    _beginTurn();
  }

  // ── UI ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final inGame = _phase != _Phase.setup && _phase != _Phase.finished;
    return GameScaffold(
      title: 'games.compliment_battle.title'.tr(),
      guardExit: inGame,
      onHelp: () => showGameRules(
        context,
        title: 'games.compliment_battle.how_to_play'.tr(),
        rules: _rules,
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        child: KeyedSubtree(
          key: ValueKey(_phase == _Phase.speaking || _phase == _Phase.ready
              ? 'turn$_round$_player'
              : '$_phase$_round$_player'),
          child: switch (_phase) {
            _Phase.setup => _buildSetup(),
            _Phase.ready || _Phase.speaking => _buildTurn(),
            _Phase.judging => _buildJudging(),
            _Phase.result => _buildResult(),
            _Phase.finished => _buildFinale(),
          },
        ),
      ),
    );
  }

  Widget _buildSetup() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        GameHero(
          icon: Icons.workspace_premium_outlined,
          title: 'games.compliment_battle.title'.tr(),
          subtitle: 'games.compliment_battle.subtitle'.tr(),
        ),
        const SizedBox(height: 32),
        const GamePlayersCard(),
        const SizedBox(height: 28),
        GameSectionLabel('games.compliment_battle.difficulty_label'.tr()),
        GameSegmented<String>(
          values: const ['easy', 'normal', 'hard'],
          selected: _difficulty,
          label: (d) => 'games.compliment_battle.diff_$d'.tr(),
          caption: (d) => 'games.compliment_battle.diff_${d}_time'.tr(),
          onChanged: (d) => setState(() => _difficulty = d),
        ),
        const SizedBox(height: 28),
        GameSectionLabel('games.compliment_battle.rounds_label'.tr()),
        GameSegmented<int>(
          values: const [3, 5, 7],
          selected: _totalRounds,
          numeric: true,
          label: (v) => '$v',
          onChanged: (v) => setState(() => _totalRounds = v),
        ),
        const SizedBox(height: 28),
        GameRulesCard(
          title: 'games.compliment_battle.how_to_play'.tr(),
          rules: [
            'games.compliment_battle.quick_rules_desc'.tr(),
            'games.compliment_battle.feature_judge'.tr(),
            'games.compliment_battle.feature_streak'.tr(),
            'games.compliment_battle.feature_bonus'.tr(),
          ],
        ),
        const SizedBox(height: 28),
        GamePrimaryButton(
          label: 'games.compliment_battle.start_battle'.tr(),
          icon: Icons.play_arrow_rounded,
          onPressed: _start,
        ),
      ],
    );
  }

  String get _roundLabel => 'game_ui.round_of'
      .tr(namedArgs: {'current': '$_round', 'total': '$_totalRounds'});

  Widget _buildCategoryCard() {
    final text = Theme.of(context).textTheme;
    return GameSurface(
      highlighted: true,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
      child: Column(
        children: [
          if (_bonus) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.round),
                border: Border.all(color: AppColors.champagne),
              ),
              child: Text(
                'games.compliment_battle.bonus_x2'.tr(),
                style: AppTypography.eyebrow.copyWith(
                  fontSize: 10,
                  color: AppColors.champagne,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Text(
            plainLabel('games.compliment_battle.compliment_on'.tr())
                .replaceAll(RegExp(r'\s*:$'), '')
                .toUpperCase(),
            textAlign: TextAlign.center,
            style: AppTypography.eyebrow.copyWith(
              color: GameTone.accentSoft,
              letterSpacing: 2.5,
            ),
          ),
          const SizedBox(height: 14),
          Icon(_category.icon, color: GameTone.accentSoft, size: 26),
          const SizedBox(height: 10),
          Text(
            'games.compliment_battle.cat_${_category.key}'.tr(),
            textAlign: TextAlign.center,
            style: text.headlineMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'games.compliment_battle.hint_${_category.key}'.tr(),
            textAlign: TextAlign.center,
            style: text.bodyMedium?.copyWith(color: AppColors.mist),
          ),
        ],
      ),
    );
  }

  Widget _buildTurn() {
    final ready = _phase == _Phase.ready;
    final left = _countdown.remaining;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Column(
        children: [
          GameTurnBanner(player: _player, trailing: _roundLabel),
          const SizedBox(height: 16),
          _buildCategoryCard(),
          Expanded(
            child: Center(
              child: GameTimerRing(
                size: 150,
                progress: ready ? 1 : _countdown.progress,
                label: ready ? '' : formatSeconds(left),
                caption: ready
                    ? plainLabel('games.compliment_battle.get_ready'.tr())
                    : 'game_ui.seconds'.tr(),
                urgent: !ready && left <= 5,
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: ready || _extraTimeUsed[_player - 1]
                      ? null
                      : _extraTime,
                  icon: const Icon(Icons.more_time_rounded, size: 18),
                  label: Text(_extraTimeUsed[_player - 1]
                      ? 'games.compliment_battle.power_used'.tr()
                      : 'games.compliment_battle.power_extra_time'.tr()),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _skipUsed[_player - 1] ? null : _skipCategory,
                  icon: const Icon(Icons.shuffle_rounded, size: 18),
                  label: Text(_skipUsed[_player - 1]
                      ? 'games.compliment_battle.power_used'.tr()
                      : 'games.compliment_battle.power_skip'.tr()),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GamePrimaryButton(
            label: 'games.compliment_battle.compliment_done'.tr(),
            icon: Icons.favorite_border_rounded,
            onPressed: ready ? null : _complimentGiven,
          ),
          GameQuietButton(
            label: 'games.compliment_battle.pass'.tr(),
            icon: Icons.skip_next_rounded,
            onPressed: _pass,
          ),
        ],
      ),
    );
  }

  Widget _buildJudging() {
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        GameTurnBanner(
          player: _judge,
          caption: 'games.compliment_battle.judging'.tr(),
          trailing: _roundLabel,
        ),
        const SizedBox(height: 28),
        Text(
          'games.compliment_battle.judge_prompt'.tr(),
          textAlign: TextAlign.center,
          style: text.headlineSmall,
        ),
        const SizedBox(height: 6),
        Text(
          plainLabel('games.compliment_battle.judge_hint'.tr()),
          textAlign: TextAlign.center,
          style: text.bodyMedium?.copyWith(color: AppColors.mist),
        ),
        const SizedBox(height: 24),
        for (final (judgment, key, icon) in const [
          (2, 'great', Icons.favorite_rounded),
          (1, 'ok', Icons.thumb_up_alt_outlined),
          (0, 'weak', Icons.refresh_rounded),
        ]) ...[
          GameOptionTile(
            title: 'games.compliment_battle.judge_$key'.tr(),
            subtitle: 'games.compliment_battle.judge_${key}_desc'.tr(),
            icon: icon,
            selected: false,
            onTap: () => _judgeCompliment(judgment),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _buildResult() {
    final text = Theme.of(context).textTheme;
    final scored = _lastOutcome == _Outcome.scored;
    final streak = _streaks[_player - 1];
    final last = _player == 2 && _round >= _totalRounds;
    final title = switch (_lastOutcome) {
      _Outcome.scored => 'games.compliment_battle.nice_compliment'.tr(),
      _Outcome.timeout => 'games.compliment_battle.time_up'.tr(),
      _ => 'games.compliment_battle.no_points'.tr(),
    };
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      children: [
        Center(
          child: GameEmblem(
            icon: switch (_lastOutcome) {
              _Outcome.scored => Icons.favorite_border_rounded,
              _Outcome.timeout => Icons.timer_off_outlined,
              _ => Icons.more_horiz_rounded,
            },
          ),
        ),
        const SizedBox(height: 20),
        Text(plainLabel(title),
            textAlign: TextAlign.center, style: text.headlineMedium),
        const SizedBox(height: 8),
        Text(
          scored
              ? '${GamePlayers.name(_player)}  ${'game_ui.points'.tr(namedArgs: {'count': '$_lastPoints'})}'
              : plainLabel('game_ui.no_points_round'.tr()),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: scored ? GamePlayers.color(_player) : AppColors.smoke,
          ),
        ),
        if (scored && streak >= 2) ...[
          const SizedBox(height: 4),
          Text(
            'games.compliment_battle.streak'
                .tr(namedArgs: {'count': '$streak'}),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.champagne),
          ),
        ],
        const SizedBox(height: 28),
        GameScoreboard(score1: _scores[0], score2: _scores[1]),
        const SizedBox(height: 32),
        GamePrimaryButton(
          label: last
              ? 'game_ui.see_results'.tr()
              : 'games.compliment_battle.continue'.tr(),
          icon: last ? Icons.emoji_events_outlined : Icons.arrow_forward_rounded,
          onPressed: _next,
        ),
      ],
    );
  }

  Widget _buildFinale() {
    final draw = _scores[0] == _scores[1];
    return GameFinale(
      title: winnerTitle(_scores[0], _scores[1]),
      subtitle: draw
          ? 'games.compliment_battle.both_champions'.tr()
          : 'games.compliment_battle.winner_reward'.tr(),
      onPlayAgain: () => setState(() => _phase = _Phase.setup),
      onExit: () => Navigator.of(context).pop(),
      child: Column(
        children: [
          GameScoreboard(score1: _scores[0], score2: _scores[1]),
          const SizedBox(height: 12),
          GameSurface(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: _Stat(
                      value: '$_longestStreak',
                      label: 'games.compliment_battle.longest_streak'.tr(),
                    ),
                  ),
                  const VerticalDivider(width: 1, color: AppColors.hairline),
                  Expanded(
                    child: _Stat(
                      value: '$_complimentsLanded',
                      label: 'games.compliment_battle.total_compliments'.tr(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _Outcome { scored, weak, passed, timeout }

class _Stat extends StatelessWidget {
  final String value;
  final String label;

  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontFamily: AppTypography.displayFont,
            fontFeatures: AppTypography.lining,
            fontSize: 24,
            color: AppColors.ivory,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: AppColors.mist),
        ),
      ],
    );
  }
}
