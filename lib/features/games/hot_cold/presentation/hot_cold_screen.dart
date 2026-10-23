import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme.dart';
import '../../../../shared/utils/display_text.dart';
import '../../shared/game_kit.dart';

/// Hot & Cold: one partner (the guide) secretly sees a body zone, the
/// other (the seeker) explores and the guide answers only with
/// temperatures. Finding the zone quickly scores more. Roles swap every
/// round, so both seek the same number of times.
class HotColdScreen extends StatefulWidget {
  const HotColdScreen({super.key});

  @override
  State<HotColdScreen> createState() => _HotColdScreenState();
}

enum _Phase { setup, handoff, reveal, search, roundEnd, finished }

class _Zone {
  final String name;
  final String hint;

  const _Zone(this.name, this.hint);
}

/// The five readings the guide can give, from freezing to boiling.
const _levels = [0.06, 0.28, 0.5, 0.72, 0.94];

const _roundDuration = 60;

class _HotColdScreenState extends State<HotColdScreen> {
  final _session = GameSession();
  late final GameCountdown _countdown = GameCountdown(
    onTick: () {
      if (!mounted) return;
      final left = _countdown.remaining;
      if (left == 10 || (left <= 5 && left > 0)) HapticFeedback.selectionClick();
      setState(() {});
    },
    onDone: () => _endRound(found: false),
  );

  _Phase _phase = _Phase.setup;
  String _intensity = 'spicy';
  int _totalRounds = 4;
  int _round = 1;
  final _scores = [0, 0];
  double _temperature = 0.5;
  int _lastPoints = 0;
  bool _lastFound = false;
  ShuffleBag<_Zone>? _zones;
  _Zone? _zone;

  /// Player 1 seeks in odd rounds, player 2 in even ones.
  int get _seeker => _round.isOdd ? 1 : 2;
  int get _guide => 3 - _seeker;

  @override
  void dispose() {
    _countdown.cancel();
    _session.finish();
    super.dispose();
  }

  List<_Zone> _loadZones() => [
        for (var i = 0; i < 10; i++)
          _Zone('games.hot_cold.zones.$i.name'.tr(),
              'games.hot_cold.zones.$i.hint'.tr()),
        if (_intensity == 'spicy')
          for (var i = 0; i < 4; i++)
            _Zone('games.hot_cold.spicy_zones.$i.name'.tr(),
                'games.hot_cold.spicy_zones.$i.hint'.tr()),
      ];

  List<String> get _rules => [
        'games.hot_cold.rule_1'.tr(),
        'games.hot_cold.rule_2'.tr(),
        'games.hot_cold.rule_3'.tr(),
        'games.hot_cold.rule_4'.tr(),
      ];

  /// "Gelato! 🥶" → "Gelato", "¡Helado!" → "Helado".
  String _bare(String s) =>
      plainLabel(s).replaceAll(RegExp(r'^¡|\s*!$'), '');

  String _levelLabel(int i) => _bare(switch (i) {
        0 => 'games.hot_cold.freezing'.tr(),
        1 => 'games.hot_cold.cold'.tr(),
        2 => 'games.hot_cold.warm'.tr(),
        3 => 'games.hot_cold.hot'.tr(),
        _ => 'games.hot_cold.boiling'.tr(),
      });

  int _levelOf(double t) {
    var best = 0;
    for (var i = 1; i < _levels.length; i++) {
      if ((_levels[i] - t).abs() < (_levels[best] - t).abs()) best = i;
    }
    return best;
  }

  void _start() {
    _session.start();
    setState(() {
      _zones = ShuffleBag(_loadZones());
      _scores
        ..[0] = 0
        ..[1] = 0;
      _round = 1;
    });
    _prepareRound();
  }

  void _prepareRound() {
    setState(() {
      _zone = _zones!.next();
      _temperature = 0.5;
      _phase = _Phase.handoff;
    });
  }

  void _beginSearch() {
    setState(() => _phase = _Phase.search);
    _countdown.start(_roundDuration);
  }

  void _setTemperature(double t) {
    HapticFeedback.mediumImpact();
    setState(() => _temperature = t);
  }

  void _endRound({required bool found}) {
    if (_phase != _Phase.search) return;
    _countdown.cancel();
    HapticFeedback.heavyImpact();
    final int points = found ? (_countdown.remaining / 10).ceil() + 5 : 0;
    setState(() {
      _lastFound = found;
      _lastPoints = points;
      _scores[_seeker - 1] += points;
      _phase = _Phase.roundEnd;
    });
  }

  void _next() {
    if (_round >= _totalRounds) {
      _session.finish();
      setState(() => _phase = _Phase.finished);
      return;
    }
    setState(() => _round++);
    _prepareRound();
  }

  @override
  Widget build(BuildContext context) {
    final inGame = _phase != _Phase.setup && _phase != _Phase.finished;
    return GameScaffold(
      title: 'games.hot_cold.title'.tr(),
      guardExit: inGame,
      onHelp: () => showGameRules(
        context,
        title: 'games.hot_cold.how_to_play'.tr(),
        rules: _rules,
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: KeyedSubtree(
          key: ValueKey('$_phase$_round'),
          child: switch (_phase) {
            _Phase.setup => _buildSetup(),
            _Phase.handoff => GameHandoff(
                player: _seeker,
                title: 'games.hot_cold.look_away'
                    .tr(namedArgs: {'name': GamePlayers.name(_seeker)}),
                message: 'games.hot_cold.look_away_body'
                    .tr(namedArgs: {'guide': GamePlayers.name(_guide)}),
                action: 'games.hot_cold.reveal_zone'.tr(),
                onContinue: () => setState(() => _phase = _Phase.reveal),
              ),
            _Phase.reveal => _buildReveal(),
            _Phase.search => _buildSearch(),
            _Phase.roundEnd => _buildRoundEnd(),
            _Phase.finished => GameFinale(
                title: winnerTitle(_scores[0], _scores[1]),
                subtitle: _scores[0] == _scores[1]
                    ? 'game_ui.celebrate_together'.tr()
                    : 'game_ui.winner_prize'.tr(),
                onPlayAgain: () => setState(() => _phase = _Phase.setup),
                onExit: () => Navigator.of(context).pop(),
                child: GameScoreboard(score1: _scores[0], score2: _scores[1]),
              ),
          },
        ),
      ),
    );
  }

  // ── Setup ──────────────────────────────────────────────────────────────

  Widget _buildSetup() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        GameHero(
          icon: Icons.thermostat_rounded,
          title: 'games.hot_cold.title'.tr(),
          subtitle: 'game_ui.find_secret_zone'.tr(),
        ),
        const SizedBox(height: 32),
        const GamePlayersCard(),
        const SizedBox(height: 28),
        GameSectionLabel('game_ui.intensity'.tr()),
        GameOptionTile(
          title: 'game_ui.soft_label'.tr(),
          subtitle: 'game_ui.soft_zones'.tr(),
          dot: AppColors.soft,
          selected: _intensity == 'soft',
          onTap: () => setState(() => _intensity = 'soft'),
        ),
        const SizedBox(height: 10),
        GameOptionTile(
          title: 'game_ui.spicy_label'.tr(),
          subtitle: 'game_ui.spicy_zones'.tr(),
          dot: AppColors.spicy,
          selected: _intensity == 'spicy',
          onTap: () => setState(() => _intensity = 'spicy'),
        ),
        const SizedBox(height: 28),
        GameSectionLabel('game_ui.number_of_rounds'.tr()),
        GameSegmented<int>(
          values: const [2, 4, 6],
          selected: _totalRounds,
          numeric: true,
          label: (v) => '$v',
          onChanged: (v) => setState(() => _totalRounds = v),
        ),
        const SizedBox(height: 28),
        GameRulesCard(title: 'games.hot_cold.how_to_play'.tr(), rules: _rules),
        const SizedBox(height: 28),
        GamePrimaryButton(
          label: 'game_ui.start_playing'.tr(),
          icon: Icons.play_arrow_rounded,
          onPressed: _start,
        ),
      ],
    );
  }

  // ── Round ──────────────────────────────────────────────────────────────

  String get _roundLabel => 'game_ui.round_of'
      .tr(namedArgs: {'current': '$_round', 'total': '$_totalRounds'});

  Widget _buildReveal() {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        children: [
          GameTurnBanner(
            player: _guide,
            caption: 'games.hot_cold.guides'.tr(),
            trailing: _roundLabel,
          ),
          const Spacer(),
          GameSurface(
            highlighted: true,
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 30),
            child: Column(
              children: [
                Text(
                  'games.hot_cold.secret_zone'.tr().toUpperCase(),
                  style: AppTypography.eyebrow.copyWith(
                    color: GameTone.accentSoft,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 14),
                Text(_zone!.name,
                    textAlign: TextAlign.center, style: text.displaySmall),
                const SizedBox(height: 14),
                Text(
                  '${plainLabel('games.hot_cold.hint_label'.tr())}: ${_zone!.hint}',
                  textAlign: TextAlign.center,
                  style: text.bodyMedium?.copyWith(color: AppColors.mist),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            plainLabel('game_ui.guide_instructions'.tr()),
            textAlign: TextAlign.center,
            style: text.bodyMedium?.copyWith(color: AppColors.mist),
          ),
          const Spacer(),
          GamePrimaryButton(
            label: 'games.hot_cold.start_search'.tr(),
            icon: Icons.play_arrow_rounded,
            onPressed: _beginSearch,
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    final urgent = _countdown.remaining <= 10;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        children: [
          GameTurnBanner(
            player: _seeker,
            caption: 'games.hot_cold.searching'.tr(),
            trailing: _roundLabel,
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.timer_outlined,
                  size: 16, color: urgent ? AppColors.rose : AppColors.mist),
              const SizedBox(width: 6),
              Text(
                formatSeconds(_countdown.remaining),
                style: TextStyle(
                  fontFeatures: AppTypography.lining,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: urgent ? AppColors.rose : AppColors.ivory,
                ),
              ),
            ],
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, box) {
                final w = min(box.maxWidth, (box.maxHeight - 90) * 2)
                    .clamp(200.0, 360.0);
                return Center(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: _temperature),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    builder: (context, t, _) => _Gauge(
                      width: w,
                      value: t,
                      label: _levelLabel(_levelOf(_temperature)),
                    ),
                  ),
                );
              },
            ),
          ),
          Text(
            'games.hot_cold.guide_hint'
                .tr(namedArgs: {'name': GamePlayers.name(_guide)}),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12.5, color: AppColors.smoke),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var i = 0; i < _levels.length; i++)
                Expanded(
                  child: _LevelButton(
                    label: _levelLabel(i),
                    color: _Gauge.colorAt(_levels[i]),
                    selected: _levelOf(_temperature) == i,
                    onTap: () => _setTemperature(_levels[i]),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          GamePrimaryButton(
            label: 'game_ui.found'.tr(),
            icon: Icons.check_rounded,
            onPressed: () => _endRound(found: true),
          ),
        ],
      ),
    );
  }

  Widget _buildRoundEnd() {
    final text = Theme.of(context).textTheme;
    final last = _round >= _totalRounds;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      children: [
        Center(
          child: GameEmblem(
            icon: _lastFound ? Icons.check_rounded : Icons.timer_off_outlined,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          plainLabel(_lastFound
              ? 'games.hot_cold.found_title'.tr()
              : 'game_ui.time_expired'.tr()),
          textAlign: TextAlign.center,
          style: text.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'game_ui.zone_was'.tr(namedArgs: {'zone': _zone!.name}),
          textAlign: TextAlign.center,
          style: text.bodyMedium?.copyWith(color: AppColors.mist),
        ),
        const SizedBox(height: 6),
        Text(
          _lastFound
              ? '${GamePlayers.name(_seeker)}  ${'game_ui.points'.tr(namedArgs: {'count': '$_lastPoints'})}'
              : plainLabel('game_ui.no_points_round'.tr()),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _lastFound ? GamePlayers.color(_seeker) : AppColors.smoke,
          ),
        ),
        const SizedBox(height: 28),
        GameScoreboard(score1: _scores[0], score2: _scores[1]),
        const SizedBox(height: 32),
        GamePrimaryButton(
          label: last ? 'game_ui.see_results'.tr() : 'game_ui.next_round'.tr(),
          icon: last ? Icons.emoji_events_outlined : Icons.arrow_forward_rounded,
          onPressed: _next,
        ),
      ],
    );
  }
}

/// Half-ring thermometer: a hairline track, a cool→warm arc up to the
/// current value, a slim needle and the reading underneath.
class _Gauge extends StatelessWidget {
  final double width;
  final double value;
  final String label;

  const _Gauge({required this.width, required this.value, required this.label});

  static const _stops = [
    AppColors.jewelDusk,
    AppColors.jewelLilac,
    GameTone.accent,
    AppColors.jewelEmber,
    AppColors.jewelGarnet,
  ];

  static Color colorAt(double t) {
    final x = t.clamp(0.0, 1.0) * (_stops.length - 1);
    final i = x.floor().clamp(0, _stops.length - 2);
    return Color.lerp(_stops[i], _stops[i + 1], x - i)!;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: width,
          height: width / 2 + 10,
          child: CustomPaint(painter: _GaugePainter(value: value)),
        ),
        const SizedBox(height: 14),
        Text(
          label,
          style: TextStyle(
            fontFamily: AppTypography.displayFont,
            fontSize: (width * 0.1).clamp(22.0, 34.0),
            fontWeight: FontWeight.w500,
            color: colorAt(value),
          ),
        ),
        Text(
          '${(value * 100).round()}°',
          style: const TextStyle(
            fontSize: 12,
            fontFeatures: AppTypography.lining,
            color: AppColors.smoke,
          ),
        ),
      ],
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double value;

  _GaugePainter({required this.value});

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2 - 8;
    final c = Offset(size.width / 2, size.height - 6);
    final rect = Rect.fromCircle(center: c, radius: r);

    canvas.drawArc(
      rect,
      pi,
      pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..color = AppColors.hairline,
    );
    canvas.drawArc(
      rect,
      pi,
      pi * value.clamp(0.0, 1.0),
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..shader = const SweepGradient(
          startAngle: pi,
          endAngle: 2 * pi,
          colors: _Gauge._stops,
        ).createShader(rect),
    );
    // Ticks for the five readings.
    for (final l in _levels) {
      final a = pi + pi * l;
      canvas.drawLine(
        c + Offset.fromDirection(a, r - 14),
        c + Offset.fromDirection(a, r - 20),
        Paint()
          ..strokeWidth = 1
          ..color = AppColors.outline,
      );
    }
    // Needle.
    final a = pi + pi * value.clamp(0.0, 1.0);
    final tip = c + Offset.fromDirection(a, r - 26);
    canvas.drawLine(
      c,
      tip,
      Paint()
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round
        ..color = AppColors.champagne,
    );
    canvas.drawCircle(c, 5, Paint()..color = AppColors.champagne);
    canvas.drawCircle(c, 2, Paint()..color = AppColors.ink);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) => old.value != value;
}

class _LevelButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _LevelButton({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? color.withOpacity(0.2) : Colors.transparent,
                  border: Border.all(
                    color: selected ? color : color.withOpacity(0.45),
                    width: selected ? 1.6 : 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: selected ? AppColors.ivory : AppColors.mist,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
