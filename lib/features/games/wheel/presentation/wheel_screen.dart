import 'dart:math';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme.dart';
import '../../../../shared/utils/display_text.dart';
import '../../shared/game_kit.dart';
import '../data/wheel_actions.dart';

/// Wheel of fortune: the players take turns spinning; the slice it stops on
/// picks a category and the game draws an action of the chosen intensity.
class WheelScreen extends StatefulWidget {
  const WheelScreen({super.key});

  @override
  State<WheelScreen> createState() => _WheelScreenState();
}

class _WheelSegment {
  final String key;
  final IconData icon;

  const _WheelSegment(this.key, this.icon);

  String get name => 'games.wheel.segments.$key'.tr().replaceAll('\n', ' ');
  String get label => 'games.wheel.segments.$key'.tr();
}

class _Spin {
  final int player;
  final _WheelSegment segment;

  const _Spin(this.player, this.segment);
}

const _segments = [
  _WheelSegment('forbidden_kiss', Icons.favorite_border_rounded),
  _WheelSegment('erotic_massage', Icons.spa_outlined),
  _WheelSegment('strip_tease', Icons.checkroom_outlined),
  _WheelSegment('hot_position', Icons.local_fire_department_outlined),
  _WheelSegment('oral_pleasure', Icons.water_drop_outlined),
  _WheelSegment('role_play', Icons.theater_comedy_outlined),
  _WheelSegment('mutual_pleasure', Icons.all_inclusive_rounded),
  _WheelSegment('secret_desire', Icons.auto_awesome_outlined),
  _WheelSegment('sensual_touch', Icons.back_hand_outlined),
  _WheelSegment('forbidden_temptation', Icons.nights_stay_outlined),
  _WheelSegment('wild_card', Icons.style_outlined),
];

const _intensities = ['soft', 'spicy', 'extra_spicy'];

class _WheelScreenState extends State<WheelScreen>
    with SingleTickerProviderStateMixin {
  final _deck = WheelDeck();
  final _session = GameSession();
  final _random = Random();
  final List<_Spin> _history = [];

  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 5200),
  )..addListener(_tick);

  bool _playing = false;
  String _intensity = 'spicy';
  int _player = 1;
  double _from = 0;
  double _to = 0;
  int? _winner;
  int _lastTickSegment = -1;

  static const _segmentAngle = 2 * pi / 11;

  double get _rotation =>
      _from + (_to - _from) * Curves.easeOutQuart.transform(_spin.value);

  bool get _spinning => _spin.isAnimating;

  @override
  void dispose() {
    _session.finish();
    _spin.dispose();
    super.dispose();
  }

  /// Soft click each time a divider passes under the pointer.
  void _tick() {
    final passed = (_rotation / _segmentAngle).floor();
    if (passed != _lastTickSegment) {
      _lastTickSegment = passed;
      HapticFeedback.selectionClick();
    }
  }

  String _intensityLabel(String i) => switch (i) {
        'soft' => 'games.wheel.intensity_soft'.tr(),
        'spicy' => 'games.wheel.intensity_spicy'.tr(),
        _ => 'games.wheel.intensity_extra_hot'.tr(),
      };

  List<String> get _rules => [
        'games.wheel.rule_1'.tr(),
        'games.wheel.rule_2'.tr(),
        'games.wheel.rule_3'.tr(),
        'games.wheel.rule_4'.tr(),
      ];

  Future<void> _spinWheel() async {
    if (_spinning) return;
    HapticFeedback.mediumImpact();
    _session.start();

    // The pointer sits at the top; slice i spans [i·s − π/2, (i+1)·s − π/2]
    // on the wheel, so landing on its centre needs a rotation of
    // −(i·s + s/2) modulo a full turn.
    final target = _random.nextInt(_segments.length);
    final current = _rotation;
    final desired =
        (2 * pi - target * _segmentAngle - _segmentAngle / 2) % (2 * pi);
    var delta = desired - current % (2 * pi);
    if (delta < 0) delta += 2 * pi;
    // A little jitter inside the slice so it doesn't always stop dead centre.
    final jitter = (_random.nextDouble() - 0.5) * _segmentAngle * 0.6;

    setState(() {
      _winner = null;
      _from = current;
      _to = current + (6 + _random.nextInt(3)) * 2 * pi + delta + jitter;
    });
    await _spin.forward(from: 0);
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    setState(() {
      _winner = target;
      _history.insert(0, _Spin(_player, _segments[target]));
    });
    await _showResult(_segments[target]);
  }

  Future<void> _showResult(_WheelSegment segment) async {
    final action = _deck.draw(segment.key, _intensity);
    final again = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ResultDialog(
        segment: segment,
        action: action,
        player: _player,
        intensity: _intensityLabel(_intensity),
      ),
    );
    if (!mounted) return;
    if (again == true) {
      _spinWheel();
    } else {
      setState(() => _player = _player == 1 ? 2 : 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      title: 'games.wheel.title'.tr(),
      onHelp: () => showGameRules(
        context,
        title: 'games.wheel.how_to_play'.tr(),
        rules: [..._rules, 'games.wheel.consent_reminder'.tr()],
      ),
      actions: [
        if (_playing && _history.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.history_rounded, color: AppColors.mist),
            tooltip: 'games.wheel.history'.tr(),
            onPressed: _showHistory,
          ),
      ],
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _playing ? _buildGame() : _buildSetup(),
      ),
    );
  }

  // ── Setup ──────────────────────────────────────────────────────────────

  Widget _buildSetup() {
    return ListView(
      key: const ValueKey('setup'),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        GameHero(
          icon: Icons.donut_large_rounded,
          title: 'games.wheel.title'.tr(),
          subtitle: 'games.wheel.subtitle'.tr(),
        ),
        const SizedBox(height: 32),
        const GamePlayersCard(),
        const SizedBox(height: 28),
        GameSectionLabel('game_ui.intensity'.tr()),
        _intensityPicker(),
        const SizedBox(height: 28),
        GameRulesCard(title: 'games.wheel.how_to_play'.tr(), rules: _rules),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            'games.wheel.consent_reminder'.tr().replaceAll('\n', ' '),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12.5,
              fontStyle: FontStyle.italic,
              color: AppColors.smoke,
            ),
          ),
        ),
        const SizedBox(height: 28),
        GamePrimaryButton(
          label: 'game_ui.start_playing'.tr(),
          icon: Icons.play_arrow_rounded,
          onPressed: () => setState(() => _playing = true),
        ),
      ],
    );
  }

  Widget _intensityPicker() => GameSegmented<String>(
        values: _intensities,
        selected: _intensity,
        label: _intensityLabel,
        onChanged: (i) => setState(() => _intensity = i),
      );

  // ── Game ───────────────────────────────────────────────────────────────

  Widget _buildGame() {
    return Padding(
      key: const ValueKey('game'),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        children: [
          GameTurnBanner(
            player: _player,
            trailing: _history.isEmpty
                ? null
                : 'games.wheel.spin_number'
                    .tr(namedArgs: {'count': '${_history.length}'}),
          ),
          const SizedBox(height: 12),
          IgnorePointer(ignoring: _spinning, child: _intensityPicker()),
          Expanded(
            child: LayoutBuilder(
              builder: (context, box) {
                final size = min(box.maxWidth, box.maxHeight - 24)
                    .clamp(200.0, 420.0);
                return Center(child: _buildWheel(size));
              },
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Text(
              plainLabel(_spinning
                  ? 'games.wheel.spinning'.tr()
                  : 'games.wheel.tap_to_spin'.tr()),
              key: ValueKey(_spinning),
              style: const TextStyle(fontSize: 13.5, color: AppColors.mist),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWheel(double size) {
    final names = [for (final s in _segments) s.label];
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _spin,
            builder: (context, _) => Transform.rotate(
              angle: _rotation,
              child: CustomPaint(
                size: Size.square(size - 28),
                painter: _WheelPainter(names: names, highlight: _winner),
              ),
            ),
          ),
          CustomPaint(
            size: Size.square(size),
            painter: _RimPainter(),
          ),
          // Hub: tap to spin.
          Semantics(
            button: true,
            label: 'games.wheel.spin_button'.tr(),
            child: GestureDetector(
              onTap: _spinning ? null : _spinWheel,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: size * 0.26,
                height: size * 0.26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.ink,
                  gradient: _spinning
                      ? null
                      : RadialGradient(colors: [
                          GameTone.accent.withOpacity(0.35),
                          AppColors.ink,
                        ]),
                  border: Border.all(
                    color: _spinning ? AppColors.outline : GameTone.accent,
                    width: 1.2,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  plainLabel('games.wheel.spin_button'.tr()),
                  style: AppTypography.eyebrow.copyWith(
                    fontSize: 12,
                    letterSpacing: 3,
                    color: _spinning ? AppColors.smoke : AppColors.ivory,
                  ),
                ),
              ),
            ),
          ),
          // Pointer.
          Positioned(
            top: 0,
            child: CustomPaint(size: const Size(22, 30), painter: _PointerPainter()),
          ),
        ],
      ),
    );
  }

  void _showHistory() {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: AppColors.inkHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          children: [
            Text(
              'games.wheel.history_title'
                  .tr(namedArgs: {'count': '${_history.length}'}),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < _history.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(
                  children: [
                    SizedBox(
                      width: 30,
                      child: Text(
                        '${_history.length - i}',
                        style: const TextStyle(
                          fontFeatures: AppTypography.lining,
                          color: AppColors.smoke,
                        ),
                      ),
                    ),
                    Icon(_history[i].segment.icon,
                        size: 18, color: GameTone.accentSoft),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _history[i].segment.name,
                        style: const TextStyle(color: AppColors.ivory),
                      ),
                    ),
                    PlayerDot(player: _history[i].player, size: 7),
                    const SizedBox(width: 6),
                    Text(
                      GamePlayers.name(_history[i].player),
                      style:
                          const TextStyle(fontSize: 13, color: AppColors.mist),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ResultDialog extends StatelessWidget {
  final _WheelSegment segment;
  final String action;
  final int player;
  final String intensity;

  const _ResultDialog({
    required this.segment,
    required this.action,
    required this.player,
    required this.intensity,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: GameTone.selectedBorder),
                gradient: RadialGradient(colors: [
                  GameTone.accent.withOpacity(0.22),
                  Colors.transparent,
                ]),
              ),
              child: Icon(segment.icon, color: GameTone.accentSoft, size: 24),
            ),
            const SizedBox(height: 14),
            Text(
              segment.name.toUpperCase(),
              textAlign: TextAlign.center,
              style: AppTypography.eyebrow.copyWith(
                color: GameTone.accentSoft,
                letterSpacing: 2.5,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                PlayerDot(player: player, size: 7),
                const SizedBox(width: 6),
                Text(
                  '${GamePlayers.name(player)} · ${plainLabel(intensity)}',
                  style: const TextStyle(fontSize: 12.5, color: AppColors.mist),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              action,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: AppTypography.displayFont,
                fontFeatures: AppTypography.lining,
                fontSize: 21,
                height: 1.35,
                fontWeight: FontWeight.w500,
                color: AppColors.ivory,
              ),
            ),
            const SizedBox(height: 26),
            GamePrimaryButton(
              label: 'games.wheel.done'.tr(),
              icon: Icons.check_rounded,
              onPressed: () => Navigator.of(context).pop(false),
            ),
            const SizedBox(height: 10),
            GameSecondaryButton(
              label: 'games.wheel.spin_again'.tr(),
              icon: Icons.refresh_rounded,
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      ),
    );
  }
}

/// The slices: three alternating plum tones, champagne hairline dividers
/// and names written along the radius.
class _WheelPainter extends CustomPainter {
  final List<String> names;
  final int? highlight;

  _WheelPainter({required this.names, required this.highlight});

  static const _tones = [
    Color(0xFF231225),
    Color(0xFF2D1630),
    Color(0xFF381B3B),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final rect = Rect.fromCircle(center: c, radius: r);
    final n = names.length;
    final s = 2 * pi / n;

    for (var i = 0; i < n; i++) {
      final start = i * s - pi / 2;
      canvas.drawArc(rect, start, s, true, Paint()..color = _tones[i % 3]);
      if (i == highlight) {
        canvas.drawArc(rect, start, s, true,
            Paint()..color = GameTone.accent.withOpacity(0.32));
      }
    }
    // Soft light towards the rim.
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(colors: [
          Colors.transparent,
          GameTone.accent.withOpacity(0.08),
        ], stops: const [0.55, 1]).createShader(rect),
    );

    final divider = Paint()
      ..color = AppColors.champagne.withOpacity(0.28)
      ..strokeWidth = 1;
    for (var i = 0; i < n; i++) {
      canvas.drawLine(
        c + Offset.fromDirection(i * s - pi / 2, r * 0.22),
        c + Offset.fromDirection(i * s - pi / 2, r),
        divider,
      );
    }

    final fontSize = (r * 0.068).clamp(9.0, 12.5);
    for (var i = 0; i < n; i++) {
      final mid = i * s + s / 2 - pi / 2;
      final tp = TextPainter(
        text: TextSpan(
          text: names[i],
          style: TextStyle(
            fontFamily: AppTypography.bodyFont,
            fontSize: fontSize,
            height: 1.15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
            color: i == highlight
                ? AppColors.ivory
                : AppColors.ivory.withOpacity(0.78),
          ),
        ),
        textAlign: TextAlign.right,
        textDirection: ui.TextDirection.ltr,
      )..layout(maxWidth: r * 0.66);
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(mid);
      // Text runs outward along the radius and ends near the rim.
      tp.paint(canvas, Offset(r * 0.9 - tp.width, -tp.height / 2));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _WheelPainter old) =>
      old.highlight != highlight || old.names.join() != names.join();
}

/// Fixed rim around the wheel: a hairline and a ring of champagne beads.
class _RimPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    canvas.drawCircle(
      c,
      r - 14,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = AppColors.champagne.withOpacity(0.45),
    );
    canvas.drawCircle(
      c,
      r - 1,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = AppColors.hairline,
    );
    const beads = 44;
    for (var i = 0; i < beads; i++) {
      final a = i * 2 * pi / beads - pi / 2;
      final major = i % 4 == 0;
      canvas.drawCircle(
        c + Offset.fromDirection(a, r - 7.5),
        major ? 1.8 : 1.1,
        Paint()
          ..color = AppColors.champagne.withOpacity(major ? 0.75 : 0.35),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RimPainter oldDelegate) => false;
}

/// Slim champagne pointer with a fuchsia bead.
class _PointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.18, 0)
      ..lineTo(w * 0.82, 0)
      ..lineTo(w / 2, h)
      ..close();
    canvas.drawShadow(path, Colors.black, 3, false);
    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.champagne, AppColors.rose],
        ).createShader(Offset.zero & size),
    );
    canvas.drawCircle(Offset(w / 2, h * 0.28), 2.6,
        Paint()..color = GameTone.accent);
  }

  @override
  bool shouldRepaint(covariant _PointerPainter oldDelegate) => false;
}
