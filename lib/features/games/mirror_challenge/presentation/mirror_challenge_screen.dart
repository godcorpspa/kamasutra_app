import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme.dart';
import '../../../../shared/utils/display_text.dart';
import '../../shared/game_kit.dart';

/// Mirror Challenge: one partner leads a slow movement, the other mirrors
/// it; roles swap every round. After each round the couple rates their
/// sync; perfect rounds in a row and the occasional golden round multiply
/// the shared score.
class MirrorChallengeScreen extends StatefulWidget {
  const MirrorChallengeScreen({super.key});

  @override
  State<MirrorChallengeScreen> createState() => _MirrorChallengeScreenState();
}

enum _Phase { setup, preview, active, rating, finished }

class _Challenge {
  final String key;
  final IconData icon;
  final bool breathing;

  const _Challenge(this.key, this.icon, {this.breathing = false});

  String get title => 'games.mirror_challenge.${key}_title'.tr();
  String get desc => 'games.mirror_challenge.${key}_desc'.tr();
  String get tip => 'games.mirror_challenge.${key}_tip'.tr();
}

const _challenges = [
  _Challenge('ch1', Icons.back_hand_outlined),
  _Challenge('ch2', Icons.face_outlined),
  _Challenge('ch3', Icons.accessibility_new_rounded),
  _Challenge('ch4', Icons.air_rounded, breathing: true),
  _Challenge('ch5', Icons.visibility_off_outlined),
  _Challenge('ch6', Icons.slow_motion_video_rounded),
  _Challenge('ch7', Icons.pan_tool_alt_outlined),
  _Challenge('ch8', Icons.people_outline_rounded, breathing: true),
];

/// Seconds per round and score multiplier for each difficulty.
const _difficulties = {
  'easy': (30, 1),
  'medium': (60, 2),
  'hard': (90, 3),
};

class _MirrorChallengeScreenState extends State<MirrorChallengeScreen>
    with SingleTickerProviderStateMixin {
  final _session = GameSession();
  final _random = Random();
  late final AnimationController _breath;
  late final GameCountdown _countdown = GameCountdown(
    onTick: () {
      if (!mounted) return;
      final left = _countdown.remaining;
      if (_countdown.total >= 30 && left == _countdown.total ~/ 2) {
        HapticFeedback.mediumImpact();
        _halfwayUntil = DateTime.now().add(const Duration(seconds: 4));
      }
      if (left <= 3 && left > 0) HapticFeedback.selectionClick();
      setState(() {});
    },
    onDone: () {
      HapticFeedback.heavyImpact();
      _endRound();
    },
  );

  _Phase _phase = _Phase.setup;
  String _difficulty = 'medium';
  int _totalRounds = 5;
  List<_Challenge> _rounds = [];
  int _round = 0;
  int _leader = 1;
  bool _bonus = false;
  DateTime? _halfwayUntil;
  int _score = 0;
  int _streak = 0;
  int _bestStreak = 0;
  int _completed = 0;

  _Challenge get _current => _rounds[_round];
  int get _mirror => 3 - _leader;
  int get _multiplier => _difficulties[_difficulty]!.$2;

  @override
  void initState() {
    super.initState();
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
  }

  @override
  void dispose() {
    _countdown.cancel();
    _breath.dispose();
    _session.finish();
    super.dispose();
  }

  List<String> get _rules => [
        'games.mirror_challenge.instruction_1'.tr(),
        'games.mirror_challenge.instruction_2'.tr(),
        'games.mirror_challenge.instruction_3'.tr(),
        'games.mirror_challenge.instruction_4'.tr(),
      ];

  // ── Flow ───────────────────────────────────────────────────────────────

  void _start() {
    _session.start();
    setState(() {
      _rounds =
          (List.of(_challenges)..shuffle(_random)).take(_totalRounds).toList();
      _round = 0;
      _leader = _random.nextInt(2) + 1;
      _score = 0;
      _streak = 0;
      _bestStreak = 0;
      _completed = 0;
      _bonus = false;
      _phase = _Phase.preview;
    });
  }

  void _swap() {
    HapticFeedback.mediumImpact();
    final unused =
        _challenges.where((c) => !_rounds.contains(c)).toList();
    if (unused.isEmpty) return;
    setState(
        () => _rounds[_round] = unused[_random.nextInt(unused.length)]);
  }

  void _begin() {
    setState(() {
      // One round in five (never the first) is a golden round.
      _bonus = _round > 0 && _random.nextInt(5) == 0;
      _halfwayUntil = null;
      _phase = _Phase.active;
    });
    if (_current.breathing) _breath.repeat();
    _countdown.start(_difficulties[_difficulty]!.$1);
  }

  void _endRound() {
    _countdown.cancel();
    _breath.stop();
    setState(() => _phase = _Phase.rating);
  }

  void _rate(int rating) {
    HapticFeedback.mediumImpact();
    var points = (rating == 3 ? 20 : rating == 2 ? 10 : 5) * _multiplier;
    if (rating == 3) {
      _streak++;
      if (_streak >= 3) points = (points * 1.5).round();
    } else {
      _streak = 0;
    }
    if (_bonus) points *= 2;
    _score += points;
    _bestStreak = max(_bestStreak, _streak);
    _completed++;
    _advance();
  }

  void _advance() {
    if (_round < _rounds.length - 1) {
      setState(() {
        _round++;
        _leader = _mirror;
        _bonus = false;
        _phase = _Phase.preview;
      });
    } else {
      _session.finish();
      setState(() => _phase = _Phase.finished);
    }
  }

  // ── UI ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final inGame = _phase != _Phase.setup && _phase != _Phase.finished;
    return GameScaffold(
      title: 'games.mirror_challenge.app_bar_title'.tr(),
      guardExit: inGame,
      onHelp: () => showGameRules(
        context,
        title: 'games.mirror_challenge.how_to_play'.tr(),
        rules: _rules,
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: KeyedSubtree(
          key: ValueKey(
              '$_phase$_round${_rounds.isEmpty ? '' : _current.key}'),
          child: switch (_phase) {
            _Phase.setup => _buildSetup(),
            _Phase.preview => _buildPreview(),
            _Phase.active => _buildActive(),
            _Phase.rating => _buildRating(),
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
          icon: Icons.flip_rounded,
          title: 'games.mirror_challenge.app_bar_title'.tr(),
          subtitle: 'games.mirror_challenge.subtitle_desc'.tr(),
        ),
        const SizedBox(height: 32),
        const GamePlayersCard(),
        const SizedBox(height: 28),
        GameSectionLabel('games.mirror_challenge.difficulty'.tr()),
        GameSegmented<String>(
          values: _difficulties.keys.toList(),
          selected: _difficulty,
          label: (d) => 'games.mirror_challenge.$d'.tr(),
          caption: (d) =>
              '${_difficulties[d]!.$1} s · ×${_difficulties[d]!.$2}',
          onChanged: (d) => setState(() => _difficulty = d),
        ),
        const SizedBox(height: 28),
        GameSectionLabel('games.mirror_challenge.number_of_rounds'.tr()),
        GameSegmented<int>(
          values: const [3, 5, 7],
          selected: _totalRounds,
          numeric: true,
          label: (v) => '$v',
          onChanged: (v) => setState(() => _totalRounds = v),
        ),
        const SizedBox(height: 28),
        GameRulesCard(
          title: 'games.mirror_challenge.how_to_play'.tr(),
          rules: _rules,
        ),
        const SizedBox(height: 28),
        GamePrimaryButton(
          label: 'games.mirror_challenge.start_challenge'.tr(),
          icon: Icons.play_arrow_rounded,
          onPressed: _start,
        ),
      ],
    );
  }

  String get _roundLabel => 'games.mirror_challenge.round_of'.tr(
      namedArgs: {'current': '${_round + 1}', 'total': '${_rounds.length}'});

  Widget _roles() {
    return Column(
      children: [
        GameTurnBanner(
          player: _leader,
          caption: 'games.mirror_challenge.leader'.tr(),
          trailing: _roundLabel,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.flip_rounded, size: 14, color: AppColors.smoke),
            const SizedBox(width: 6),
            Text(
              '${'games.mirror_challenge.mirror'.tr()}: ',
              style: const TextStyle(fontSize: 13, color: AppColors.smoke),
            ),
            PlayerDot(player: _mirror, size: 6),
            const SizedBox(width: 5),
            Text(
              GamePlayers.name(_mirror),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: GamePlayers.color(_mirror),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPreview() {
    final text = Theme.of(context).textTheme;
    final c = _current;
    final canSwap = _challenges.any((x) => !_rounds.contains(x));
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Column(
        children: [
          _roles(),
          const SizedBox(height: 12),
          GameProgressBar(value: _round / _rounds.length),
          Expanded(
            child: Center(
              child: GameSurface(
                highlighted: true,
                padding: const EdgeInsets.fromLTRB(24, 26, 24, 26),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(c.icon, color: GameTone.accentSoft, size: 26),
                    const SizedBox(height: 12),
                    Text(c.title,
                        textAlign: TextAlign.center,
                        style: text.headlineMedium),
                    const SizedBox(height: 10),
                    Text(
                      c.desc,
                      textAlign: TextAlign.center,
                      style: text.bodyLarge
                          ?.copyWith(color: AppColors.mist, height: 1.5),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 1),
                          child: Icon(Icons.lightbulb_outline_rounded,
                              size: 15, color: AppColors.champagne),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            c.tip,
                            style: const TextStyle(
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                              color: AppColors.champagne,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          GamePrimaryButton(
            label: 'games.mirror_challenge.start_challenge'.tr(),
            icon: Icons.play_arrow_rounded,
            onPressed: _begin,
          ),
          const SizedBox(height: 10),
          GameSecondaryButton(
            label: 'games.mirror_challenge.surprise'.tr(),
            icon: Icons.shuffle_rounded,
            onPressed: canSwap ? _swap : null,
          ),
        ],
      ),
    );
  }

  Widget _buildActive() {
    final left = _countdown.remaining;
    final halfway =
        _halfwayUntil != null && DateTime.now().isBefore(_halfwayUntil!);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Column(
        children: [
          _roles(),
          const SizedBox(height: 18),
          if (_bonus) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.round),
                border: Border.all(color: AppColors.champagne),
              ),
              child: Text(
                '${plainLabel('games.mirror_challenge.feature_bonus'.tr())} ×2'
                    .toUpperCase(),
                style: AppTypography.eyebrow.copyWith(
                  fontSize: 10,
                  color: AppColors.champagne,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          Text(
            _current.title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          Text(
            _current.desc,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: AppColors.mist),
          ),
          Expanded(
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (_current.breathing)
                    GameBreathingHalo(animation: _breath),
                  GameTimerRing(
                    size: 200,
                    progress: _countdown.progress,
                    label: formatSeconds(left),
                    caption: _current.breathing
                        ? (_breath.value < 0.5
                            ? 'games.mirror_challenge.inhale'.tr()
                            : 'games.mirror_challenge.exhale'.tr())
                        : 'games.mirror_challenge.seconds'.tr(),
                    urgent: left <= 5,
                  ),
                ],
              ),
            ),
          ),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 400),
            opacity: halfway ? 1 : 0,
            child: Text(
              'games.mirror_challenge.halfway_msg'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.champagne),
            ),
          ),
          const SizedBox(height: 14),
          GamePrimaryButton(
            label: 'games.mirror_challenge.end_early'.tr(),
            icon: Icons.check_rounded,
            onPressed: _endRound,
          ),
        ],
      ),
    );
  }

  Widget _buildRating() {
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        _roles(),
        const SizedBox(height: 28),
        Text(
          plainLabel('games.mirror_challenge.round_complete_title'.tr()),
          textAlign: TextAlign.center,
          style: text.headlineSmall,
        ),
        const SizedBox(height: 6),
        Text(
          'games.mirror_challenge.connection_how'.tr(),
          textAlign: TextAlign.center,
          style: text.bodyMedium?.copyWith(color: AppColors.mist),
        ),
        const SizedBox(height: 24),
        for (final (rating, key, desc, icon) in const [
          (1, 'feedback_hard', 'rate_low_desc', Icons.waves_rounded),
          (2, 'feedback_good', 'rate_mid_desc', Icons.favorite_border_rounded),
          (3, 'feedback_perfect', 'rate_high_desc', Icons.auto_awesome_outlined),
        ]) ...[
          GameOptionTile(
            title: 'games.mirror_challenge.$key'.tr(),
            subtitle: 'games.mirror_challenge.$desc'.tr(),
            icon: icon,
            selected: false,
            onTap: () => _rate(rating),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _buildFinale() {
    // A perfect run without golden rounds, streak bonus included.
    final ideal = 20 * _multiplier * 1.5 * _rounds.length;
    final ratio = ideal == 0 ? 0.0 : (_score / ideal).clamp(0.0, 1.0);
    final message = ratio > 0.7
        ? 'games.mirror_challenge.connection_msg_high'
        : ratio > 0.4
            ? 'games.mirror_challenge.connection_msg_mid'
            : 'games.mirror_challenge.connection_msg_low';
    return GameFinale(
      icon: Icons.flip_rounded,
      title: 'games.mirror_challenge.session_complete_title'.tr(),
      subtitle: message.tr(),
      onPlayAgain: () => setState(() => _phase = _Phase.setup),
      onExit: () => Navigator.of(context).pop(),
      child: GameSurface(
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'games.mirror_challenge.connection_score'.tr(),
                    style: const TextStyle(fontSize: 13, color: AppColors.mist),
                  ),
                ),
                Text(
                  '$_score',
                  style: const TextStyle(
                    fontFamily: AppTypography.displayFont,
                    fontFeatures: AppTypography.lining,
                    fontSize: 22,
                    color: AppColors.ivory,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            GameProgressBar(value: ratio),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _Stat('$_bestStreak',
                      'games.mirror_challenge.best_streak'.tr()),
                ),
                Expanded(
                  child: _Stat('$_completed/${_rounds.length}',
                      'games.mirror_challenge.rounds_done'.tr()),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              plainLabel('games.mirror_challenge.closing'.tr()),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: AppTypography.displayFont,
                fontStyle: FontStyle.italic,
                fontSize: 14,
                color: AppColors.mist,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;

  const _Stat(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontFamily: AppTypography.displayFont,
            fontFeatures: AppTypography.lining,
            fontSize: 22,
            color: AppColors.ivory,
          ),
        ),
        Text(
          plainLabel(label),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: AppColors.mist),
        ),
      ],
    );
  }
}
