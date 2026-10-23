import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme.dart';
import '../../../../shared/utils/display_text.dart';
import '../../shared/game_kit.dart';

/// Two Minutes: a short series of timed intimate challenges. Some are done
/// together, others are led by one partner (the lead alternates); breathing
/// challenges get a guided 4-4 rhythm. After each one the couple rates how
/// connected they felt.
class TwoMinutesScreen extends StatefulWidget {
  const TwoMinutesScreen({super.key});

  @override
  State<TwoMinutesScreen> createState() => _TwoMinutesScreenState();
}

enum _Phase { setup, preview, active, rating, finished }

class _Challenge {
  final String id;
  final IconData icon;

  /// Done by both at once (no lead).
  final bool together;
  final bool breathing;

  const _Challenge(
    this.id,
    this.icon, {
    this.together = false,
    this.breathing = false,
  });
}

const _pools = {
  'soft': [
    _Challenge('deep_gaze', Icons.visibility_outlined, together: true),
    _Challenge('hand_massage', Icons.back_hand_outlined),
    _Challenge('whispers', Icons.hearing_outlined),
    _Challenge('sync_breathing', Icons.air_rounded,
        together: true, breathing: true),
    _Challenge('light_caresses', Icons.face_outlined),
    _Challenge('forehead_rest', Icons.spa_outlined,
        together: true, breathing: true),
    _Challenge('gratitude', Icons.favorite_border_rounded, together: true),
  ],
  'spicy': [
    _Challenge('exploring_kisses', Icons.favorite_border_rounded),
    _Challenge('neck_massage', Icons.spa_outlined),
    _Challenge('total_hug', Icons.people_outline_rounded,
        together: true, breathing: true),
    _Challenge('slow_dance', Icons.music_note_outlined, together: true),
    _Challenge('blind_touch', Icons.touch_app_outlined),
    _Challenge('hair_caress', Icons.back_hand_outlined),
    _Challenge('lip_tracing', Icons.gesture_rounded),
  ],
  'extra_spicy': [
    _Challenge('sensitive_spots', Icons.local_fire_department_outlined),
    _Challenge('back_massage', Icons.self_improvement_rounded),
    _Challenge('kisses_everywhere', Icons.favorite_border_rounded),
    _Challenge('tactile_exploration', Icons.explore_outlined),
    _Challenge('total_connection', Icons.all_inclusive_rounded,
        together: true, breathing: true),
    _Challenge('slow_undress', Icons.checkroom_outlined, together: true),
    _Challenge('warm_breath', Icons.air_rounded),
  ],
};

const _intensities = ['soft', 'spicy', 'extra_spicy'];

class _TwoMinutesScreenState extends State<TwoMinutesScreen>
    with SingleTickerProviderStateMixin {
  final _session = GameSession();
  final _random = Random();
  late final AnimationController _breath;
  late final GameCountdown _countdown = GameCountdown(
    onTick: () {
      if (!mounted) return;
      final left = _countdown.remaining;
      if (_countdown.total >= 60 && left == _countdown.total ~/ 2) {
        HapticFeedback.mediumImpact();
        _halfwayUntil = DateTime.now().add(const Duration(seconds: 4));
      }
      if (left <= 3 && left > 0) HapticFeedback.selectionClick();
      setState(() {});
    },
    onDone: () {
      HapticFeedback.heavyImpact();
      _finishChallenge();
    },
  );

  _Phase _phase = _Phase.setup;
  String _intensity = 'spicy';
  int _duration = 120;
  int _count = 5;

  List<_Challenge> _challenges = [];
  int _index = 0;
  int _nextLead = 1;
  int? _lead;
  bool _paused = false;
  DateTime? _halfwayUntil;
  int _completed = 0;
  int _points = 0;
  int _secondsTogether = 0;

  _Challenge get _current => _challenges[_index];

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
        'games.two_minutes.rule_1'.tr(),
        'games.two_minutes.rule_2'.tr(),
        'games.two_minutes.rule_3'.tr(),
        'games.two_minutes.rule_4'.tr(),
        'games.two_minutes.rule_5'.tr(),
      ];

  String _title(_Challenge c) =>
      'games.two_minutes.$_intensity.${c.id}_title'.tr();
  String _desc(_Challenge c) =>
      'games.two_minutes.$_intensity.${c.id}_desc'.tr();

  // ── Flow ───────────────────────────────────────────────────────────────

  void _start() {
    _session.start();
    final pool = List.of(_pools[_intensity]!)..shuffle(_random);
    setState(() {
      _challenges = pool.take(_count).toList();
      _index = 0;
      _nextLead = _random.nextInt(2) + 1;
      _completed = 0;
      _points = 0;
      _secondsTogether = 0;
    });
    _preview();
  }

  void _preview() {
    setState(() {
      _lead = _current.together ? null : _nextLead;
      _phase = _Phase.preview;
    });
  }

  /// Swaps the upcoming challenge for one not already in this session.
  void _swap() {
    HapticFeedback.mediumImpact();
    final unused = _pools[_intensity]!
        .where((c) => !_challenges.contains(c))
        .toList();
    if (unused.isEmpty) return;
    setState(() => _challenges[_index] = unused[_random.nextInt(unused.length)]);
    _preview();
  }

  void _begin() {
    if (_lead != null) _nextLead = 3 - _lead!;
    setState(() {
      _phase = _Phase.active;
      _paused = false;
      _halfwayUntil = null;
    });
    if (_current.breathing) _breath.repeat();
    _countdown.start(_duration);
  }

  void _togglePause() {
    HapticFeedback.lightImpact();
    setState(() => _paused = !_paused);
    if (_paused) {
      _countdown.pause();
      _breath.stop();
    } else {
      _countdown.resume();
      if (_current.breathing) _breath.repeat();
    }
  }

  void _finishChallenge() {
    _countdown.cancel();
    _breath.stop();
    _secondsTogether += _countdown.total - _countdown.remaining;
    setState(() => _phase = _Phase.rating);
  }

  void _rate(int rating) {
    HapticFeedback.mediumImpact();
    _completed++;
    _points += rating * 10;
    _advance();
  }

  void _skip() {
    _countdown.cancel();
    _breath.stop();
    _advance();
  }

  void _advance() {
    if (_index < _challenges.length - 1) {
      _index++;
      _preview();
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
      title: 'games.two_minutes.title'.tr(),
      guardExit: inGame,
      onHelp: () => showGameRules(
        context,
        title: 'games.two_minutes.how_to_play'.tr(),
        rules: _rules,
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: KeyedSubtree(
          key: ValueKey('$_phase$_index$_currentId'),
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

  String get _currentId => _challenges.isEmpty ? '' : _current.id;

  Widget _buildSetup() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        GameHero(
          icon: Icons.hourglass_empty_rounded,
          title: 'games.two_minutes.title'.tr(),
          subtitle: 'games.two_minutes.subtitle'.tr(),
        ),
        const SizedBox(height: 32),
        const GamePlayersCard(),
        const SizedBox(height: 28),
        GameSectionLabel('games.two_minutes.intensity'.tr()),
        for (final i in _intensities) ...[
          GameOptionTile(
            title: 'games.two_minutes.intensity_$i'.tr(),
            subtitle: 'games.two_minutes.intensity_${i}_desc'.tr(),
            dot: switch (i) {
              'soft' => AppColors.soft,
              'spicy' => AppColors.spicy,
              _ => AppColors.extraSpicy,
            },
            selected: _intensity == i,
            onTap: () => setState(() => _intensity = i),
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 18),
        GameSectionLabel('games.two_minutes.challenge_duration'.tr()),
        GameSegmented<int>(
          values: const [60, 120, 180, 300],
          selected: _duration,
          label: (s) => 'games.two_minutes.dur_${s ~/ 60}min'.tr(),
          onChanged: (s) => setState(() => _duration = s),
        ),
        const SizedBox(height: 28),
        GameSectionLabel('games.two_minutes.challenges_count'.tr()),
        GameSegmented<int>(
          values: const [3, 5, 7],
          selected: _count,
          numeric: true,
          label: (v) => '$v',
          onChanged: (v) => setState(() => _count = v),
        ),
        const SizedBox(height: 28),
        GameRulesCard(
            title: 'games.two_minutes.how_to_play'.tr(), rules: _rules),
        const SizedBox(height: 28),
        GamePrimaryButton(
          label: 'games.two_minutes.start_session'.tr(),
          icon: Icons.play_arrow_rounded,
          onPressed: _start,
        ),
      ],
    );
  }

  String get _progressLabel => 'games.two_minutes.challenge_short'
      .tr(namedArgs: {'current': '${_index + 1}', 'total': '${_challenges.length}'});

  Widget _whoBanner() {
    final lead = _lead;
    if (lead != null) {
      return GameTurnBanner(
        player: lead,
        caption: 'games.two_minutes.leads'.tr(),
        trailing: _progressLabel,
      );
    }
    return GameSurface(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          const PlayerDot(player: 1, size: 9),
          const SizedBox(width: 4),
          const PlayerDot(player: 2, size: 9),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'game_kit.together'.tr().toUpperCase(),
                  style: AppTypography.eyebrow.copyWith(fontSize: 10),
                ),
                const SizedBox(height: 2),
                Text(
                  '${GamePlayers.name(1)} & ${GamePlayers.name(2)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppTypography.displayFont,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ivory,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _progressLabel,
            style: const TextStyle(fontSize: 13, color: AppColors.mist),
          ),
        ],
      ),
    );
  }

  Widget _challengeCard() {
    final text = Theme.of(context).textTheme;
    return GameSurface(
      highlighted: true,
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_current.icon, color: GameTone.accentSoft, size: 26),
          const SizedBox(height: 12),
          Text(_title(_current),
              textAlign: TextAlign.center, style: text.headlineMedium),
          const SizedBox(height: 10),
          Text(
            _desc(_current),
            textAlign: TextAlign.center,
            style: text.bodyLarge?.copyWith(color: AppColors.mist, height: 1.5),
          ),
          if (_current.breathing) ...[
            const SizedBox(height: 14),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.air_rounded,
                    size: 15, color: AppColors.champagne),
                const SizedBox(width: 6),
                Text(
                  'games.two_minutes.breathing_mode'.tr(),
                  style: const TextStyle(
                      fontSize: 12.5, color: AppColors.champagne),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPreview() {
    final canSwap = _pools[_intensity]!.any((c) => !_challenges.contains(c));
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Column(
        children: [
          _whoBanner(),
          const SizedBox(height: 12),
          GameProgressBar(value: _index / _challenges.length),
          Expanded(child: Center(child: _challengeCard())),
          GamePrimaryButton(
            label: 'games.two_minutes.start_timer'.tr(),
            icon: Icons.play_arrow_rounded,
            onPressed: _begin,
          ),
          const SizedBox(height: 10),
          GameSecondaryButton(
            label: 'games.two_minutes.surprise'.tr(),
            icon: Icons.shuffle_rounded,
            onPressed: canSwap ? _swap : null,
          ),
          GameQuietButton(
            label: 'games.two_minutes.skip'.tr(),
            icon: Icons.skip_next_rounded,
            onPressed: _skip,
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
          _whoBanner(),
          const SizedBox(height: 18),
          Text(
            _title(_current),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          Text(
            _desc(_current),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: AppColors.mist),
          ),
          Expanded(
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (_current.breathing) _BreathingHalo(animation: _breath),
                  GameTimerRing(
                    size: 200,
                    progress: _countdown.progress,
                    label: formatSeconds(left),
                    caption: _paused
                        ? 'games.two_minutes.paused'.tr()
                        : _current.breathing
                            ? (_breath.value < 0.5
                                ? 'games.two_minutes.breathe_in'.tr()
                                : 'games.two_minutes.breathe_out'.tr())
                            : 'games.two_minutes.remaining'.tr(),
                    urgent: left <= 10,
                  ),
                ],
              ),
            ),
          ),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 400),
            opacity: halfway ? 1 : 0,
            child: Text(
              'games.two_minutes.halfway_message'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.champagne),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: GameSecondaryButton(
                  label: _paused ? 'games.resume'.tr() : 'games.pause'.tr(),
                  icon: _paused
                      ? Icons.play_arrow_rounded
                      : Icons.pause_rounded,
                  onPressed: _togglePause,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GamePrimaryButton(
                  label: 'common.done'.tr(),
                  icon: Icons.check_rounded,
                  onPressed: _finishChallenge,
                ),
              ),
            ],
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
        _whoBanner(),
        const SizedBox(height: 28),
        Text(
          'games.two_minutes.rate_connection'.tr(),
          textAlign: TextAlign.center,
          style: text.headlineSmall,
        ),
        const SizedBox(height: 6),
        Text(
          'games.two_minutes.rate_hint'.tr(),
          textAlign: TextAlign.center,
          style: text.bodyMedium?.copyWith(color: AppColors.mist),
        ),
        const SizedBox(height: 24),
        for (final (rating, key, icon) in const [
          (1, 'low', Icons.favorite_border_rounded),
          (2, 'mid', Icons.favorite_rounded),
          (3, 'high', Icons.auto_awesome_outlined),
        ]) ...[
          GameOptionTile(
            title: 'games.two_minutes.rate_$key'.tr(),
            subtitle: 'games.two_minutes.rate_${key}_desc'.tr(),
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
    final max = 30 * _challenges.length;
    final ratio = max == 0 ? 0.0 : (_points / max).clamp(0.0, 1.0);
    final message = ratio > 0.7
        ? 'games.two_minutes.connection_msg_high'
        : ratio > 0.4
            ? 'games.two_minutes.connection_msg_mid'
            : 'games.two_minutes.connection_msg_low';
    return GameFinale(
      icon: Icons.hourglass_bottom_rounded,
      title: 'games.two_minutes.session_complete'.tr(),
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
                    'games.two_minutes.connection_score'.tr(),
                    style: const TextStyle(fontSize: 13, color: AppColors.mist),
                  ),
                ),
                Text(
                  '${(ratio * 100).round()}%',
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
                  child: _Stat(
                    '$_completed/${_challenges.length}',
                    'games.two_minutes.challenges_completed'.tr(),
                  ),
                ),
                Expanded(
                  child: _Stat(
                    '${_secondsTogether ~/ 60}:'
                        '${(_secondsTogether % 60).toString().padLeft(2, '0')}',
                    'games.two_minutes.session_label'.tr(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Soft disc that swells for 4 s (breathe in) and shrinks for 4 s.
class _BreathingHalo extends StatelessWidget {
  final Animation<double> animation;

  const _BreathingHalo({required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = animation.value;
        final phase = t < 0.5 ? t * 2 : (1 - t) * 2;
        final eased = Curves.easeInOut.transform(phase);
        final size = 200 + 60 * eased;
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              GameTone.accent.withOpacity(0.0),
              GameTone.accent.withOpacity(0.10 + 0.08 * eased),
              GameTone.accent.withOpacity(0.0),
            ], stops: const [0.6, 0.85, 1.0]),
          ),
        );
      },
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
