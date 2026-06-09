import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class HotColdScreen extends StatefulWidget {
  const HotColdScreen({super.key});

  @override
  State<HotColdScreen> createState() => _HotColdScreenState();
}

class _HotColdScreenState extends State<HotColdScreen>
    with TickerProviderStateMixin {
  // ---------------------------------------------------------------------------
  // Game state
  // ---------------------------------------------------------------------------
  bool _gameStarted = false;
  bool _isSeeker = true; // Player 1 starts as seeker
  String _intensity = 'spicy';
  String? _currentZone;
  int _roundNumber = 1;
  int _totalRounds = 5;
  int _player1Score = 0;
  int _player2Score = 0;
  Timer? _timer;
  int _timeRemaining = 60;
  static const int _roundDuration = 60;

  // 0 = freezing, 1 = burning. Animated separately for fluid mercury.
  double _temperatureTarget = 0.5;

  // ---------------------------------------------------------------------------
  // Animations
  // ---------------------------------------------------------------------------
  late final AnimationController _bgParticles;
  late final AnimationController _haloPulse;
  late final AnimationController _shimmer;
  late final AnimationController _mercuryAnim;
  late final AnimationController _bulbPulse;
  late final AnimationController _celebrate;
  late final AnimationController _intro;

  late Animation<double> _mercuryAnimation;
  late Animation<double> _haloAnimation;
  late Animation<double> _introAnimation;

  final List<_FloatParticle> _particles = List.generate(
    36,
    (i) => _FloatParticle(Random(i * 13 + 7)),
  );
  final List<_CelebrationParticle> _confetti = List.generate(
    60,
    (i) => _CelebrationParticle(Random(i * 31 + 5)),
  );

  // ---------------------------------------------------------------------------
  // Zones
  // ---------------------------------------------------------------------------
  List<Map<String, dynamic>> get _zones => List.generate(10, (i) => {
        'name': 'games.hot_cold.zones.$i.name'.tr(),
        'emoji': 'games.hot_cold.zones.$i.emoji'.tr(),
        'hint': 'games.hot_cold.zones.$i.hint'.tr(),
      });

  List<Map<String, dynamic>> get _spicyZones => List.generate(4, (i) => {
        'name': 'games.hot_cold.spicy_zones.$i.name'.tr(),
        'emoji': 'games.hot_cold.spicy_zones.$i.emoji'.tr(),
        'hint': 'games.hot_cold.spicy_zones.$i.hint'.tr(),
      });

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------
  @override
  void initState() {
    super.initState();

    _bgParticles = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();

    _haloPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _haloAnimation = CurvedAnimation(
      parent: _haloPulse,
      curve: Curves.easeInOut,
    );

    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _bulbPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _mercuryAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _mercuryAnimation = const AlwaysStoppedAnimation<double>(0.5);

    _celebrate = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _introAnimation = CurvedAnimation(
      parent: _intro,
      curve: Curves.easeOutCubic,
    );
    _intro.forward();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _bgParticles.dispose();
    _haloPulse.dispose();
    _shimmer.dispose();
    _mercuryAnim.dispose();
    _bulbPulse.dispose();
    _celebrate.dispose();
    _intro.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Game logic
  // ---------------------------------------------------------------------------
  void _startGame() {
    HapticFeedback.heavyImpact();
    final allZones = _intensity == 'soft'
        ? _zones
        : [..._zones, ..._spicyZones];
    allZones.shuffle();

    setState(() {
      _gameStarted = true;
      _currentZone = allZones.first['name'];
      _temperatureTarget = 0.5;
      _timeRemaining = _roundDuration;
      _player1Score = 0;
      _player2Score = 0;
      _roundNumber = 1;
      _isSeeker = true;
    });

    _setMercury(0.5, animate: false);
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showZoneToGuider();
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _timeRemaining--);

      if (_timeRemaining == 10) {
        HapticFeedback.lightImpact();
      }
      if (_timeRemaining <= 5 && _timeRemaining > 0) {
        HapticFeedback.selectionClick();
      }

      if (_timeRemaining <= 0) {
        _timer?.cancel();
        HapticFeedback.heavyImpact();
        _handleTimeout();
      }
    });
  }

  void _setMercury(double target, {bool animate = true}) {
    _temperatureTarget = target.clamp(0.0, 1.0);
    if (!animate) {
      _mercuryAnimation = AlwaysStoppedAnimation<double>(_temperatureTarget);
      setState(() {});
      return;
    }
    final from = _mercuryAnimation.value;
    _mercuryAnimation = Tween<double>(begin: from, end: _temperatureTarget)
        .animate(CurvedAnimation(parent: _mercuryAnim, curve: Curves.easeOutCubic));
    _mercuryAnim
      ..reset()
      ..forward();
  }

  void _updateTemperature(double delta) {
    HapticFeedback.mediumImpact();
    _setMercury(_temperatureTarget + delta);
  }

  void _showZoneToGuider() {
    final zone = _getZoneData(_currentZone!);
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (context) => _ZoneRevealDialog(
        emoji: zone['emoji'],
        name: zone['name'],
        hint: zone['hint'],
        guiderLabel: 'game_ui.player_guides'.tr(args: [
          _isSeeker ? 'game_ui.player_2'.tr() : 'game_ui.player_1'.tr(),
        ]),
        instructions: 'game_ui.guide_instructions'.tr(),
        hintLabel: 'games.hot_cold.hint_label'.tr(),
        actionLabel: 'game_ui.understood'.tr(),
        onConfirm: () => Navigator.pop(context),
      ),
    );
  }

  Map<String, dynamic> _getZoneData(String zoneName) {
    final allZones = [..._zones, ..._spicyZones];
    return allZones.firstWhere(
      (z) => z['name'] == zoneName,
      orElse: () => {'name': zoneName, 'emoji': '❓', 'hint': ''},
    );
  }

  void _handleFound() {
    HapticFeedback.heavyImpact();
    _timer?.cancel();
    final score = (_timeRemaining / 10).ceil() + 5;

    setState(() {
      if (_isSeeker) {
        _player1Score += score;
      } else {
        _player2Score += score;
      }
    });

    _celebrate
      ..reset()
      ..forward();

    _showRoundResult(true, score);
  }

  void _handleTimeout() {
    _showRoundResult(false, 0);
  }

  void _showRoundResult(bool found, int score) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (context) => _RoundResultDialog(
        found: found,
        score: score,
        zone: _currentZone!,
        player1Score: _player1Score,
        player2Score: _player2Score,
        isLastRound: _roundNumber >= _totalRounds,
        onNext: () {
          Navigator.pop(context);
          if (_roundNumber < _totalRounds) {
            _nextRound();
          } else {
            _showFinalResults();
          }
        },
      ),
    );
  }

  void _nextRound() {
    final allZones = _intensity == 'soft'
        ? _zones
        : [..._zones, ..._spicyZones];
    allZones.shuffle();

    setState(() {
      _roundNumber++;
      _isSeeker = !_isSeeker;
      _currentZone = allZones.first['name'];
      _temperatureTarget = 0.5;
      _timeRemaining = _roundDuration;
    });

    _setMercury(0.5, animate: true);
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showZoneToGuider();
    });
  }

  void _showFinalResults() {
    final winner = _player1Score > _player2Score
        ? 'game_ui.player_1'.tr()
        : _player1Score < _player2Score
            ? 'game_ui.player_2'.tr()
            : 'game_ui.draw'.tr();
    final isDraw = _player1Score == _player2Score;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (context) => _FinalResultsDialog(
        winnerLabel: isDraw
            ? '${'game_ui.draw'.tr()}!'
            : 'game_ui.wins'.tr(namedArgs: {'player': winner}),
        player1Score: _player1Score,
        player2Score: _player2Score,
        prizeText: isDraw
            ? 'game_ui.celebrate_together'.tr()
            : 'game_ui.winner_prize'.tr(),
        newGameLabel: 'game_ui.new_game'.tr(),
        endLabel: 'game_ui.end'.tr(),
        onNewGame: () {
          Navigator.pop(context);
          setState(() {
            _gameStarted = false;
            _roundNumber = 1;
            _player1Score = 0;
            _player2Score = 0;
            _isSeeker = true;
          });
          _intro.forward(from: 0);
        },
        onEnd: () {
          Navigator.pop(context);
          if (mounted) context.pop();
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Color & label helpers
  // ---------------------------------------------------------------------------
  Color _temperatureColorFor(double t) {
    if (t < 0.2) return const Color(0xFF1E90FF);
    if (t < 0.4) return const Color(0xFF4DB8FF);
    if (t < 0.6) return const Color(0xFFFFD166);
    if (t < 0.8) return const Color(0xFFFF8C42);
    return const Color(0xFFE53935);
  }

  Color _temperatureAccentFor(double t) {
    if (t < 0.2) return const Color(0xFF7DD3FC);
    if (t < 0.4) return const Color(0xFFA5E0FF);
    if (t < 0.6) return const Color(0xFFFFE7A0);
    if (t < 0.8) return const Color(0xFFFFB880);
    return const Color(0xFFFF6B6B);
  }

  String _temperatureText(double t) {
    if (t < 0.2) return 'games.hot_cold.freezing'.tr();
    if (t < 0.4) return 'games.hot_cold.cold'.tr();
    if (t < 0.6) return 'games.hot_cold.warm'.tr();
    if (t < 0.8) return 'games.hot_cold.hot'.tr();
    return 'games.hot_cold.boiling'.tr();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        // Material 3 paints an opaque surfaceTint band over a
        // transparent AppBar on scroll; disable it so the bar blends
        // with the game background as designed.
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white70),
          onPressed: () => context.pop(),
        ),
        title: _gameStarted
            ? null
            : Text(
                'games.hot_cold.title'.tr(),
                style: const TextStyle(
                  fontFamily: 'PlayfairDisplay',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  decoration: TextDecoration.none,
                ),
              ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white70),
            onPressed: _showRules,
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _mercuryAnim,
        builder: (context, _) {
          final mercury =
              _gameStarted ? _mercuryAnimation.value : _temperatureTarget;
          final temperatureColor = _temperatureColorFor(mercury);
          final accentColor = _temperatureAccentFor(mercury);

          return Stack(
            children: [
              // Animated background gradient that subtly shifts with temperature
              AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF0A0F2C),
                      Color.lerp(const Color(0xFF101638),
                          temperatureColor.withOpacity(0.55), 0.35)!,
                      const Color(0xFF06081C),
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
              ),
              // Floating particles (snow / sparks)
              AnimatedBuilder(
                animation: _bgParticles,
                builder: (context, _) {
                  return CustomPaint(
                    size: Size.infinite,
                    painter: _BackgroundParticlesPainter(
                      particles: _particles,
                      progress: _bgParticles.value,
                      coldness: 1 - mercury,
                      heat: mercury,
                    ),
                  );
                },
              ),
              SafeArea(
                child: _gameStarted
                    ? _buildGameView(temperatureColor, accentColor, mercury)
                    : _buildSetupView(),
              ),
              // Celebration overlay (when zone is found)
              IgnorePointer(
                child: AnimatedBuilder(
                  animation: _celebrate,
                  builder: (context, _) {
                    if (_celebrate.value == 0) return const SizedBox.shrink();
                    return CustomPaint(
                      size: Size.infinite,
                      painter: _CelebrationPainter(
                        particles: _confetti,
                        progress: _celebrate.value,
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Setup view
  // ---------------------------------------------------------------------------
  Widget _buildSetupView() {
    return AnimatedBuilder(
      animation: _introAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _introAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - _introAnimation.value)),
            child: child,
          ),
        );
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(
          children: [
            const SizedBox(height: 8),
            // Header — animated thermometer icon with halo
            AnimatedBuilder(
              animation: _haloAnimation,
              builder: (context, _) {
                return SizedBox(
                  height: 160,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFFFF6B6B)
                                  .withOpacity(0.35 + 0.15 * _haloAnimation.value),
                              const Color(0xFF1E90FF).withOpacity(0.18),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      // Static mini thermometer
                      SizedBox(
                        width: 70,
                        height: 130,
                        child: CustomPaint(
                          painter: _ThermometerPainter(
                            temperature: 0.65,
                            mercuryColor: const Color(0xFFFF6B6B),
                            glowPulse: _haloAnimation.value,
                            showTicks: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            Text(
              'games.hot_cold.title'.tr(),
              style: const TextStyle(
                fontFamily: 'PlayfairDisplay',
                fontSize: 30,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 1.2,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'game_ui.find_secret_zone'.tr(),
              style: TextStyle(
                fontFamily: 'DMSans',
                fontSize: 14,
                color: Colors.white.withOpacity(0.6),
                fontStyle: FontStyle.italic,
                decoration: TextDecoration.none,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Intensity
            _buildSectionLabel(
              icon: Icons.local_fire_department,
              color: const Color(0xFFFF6B35),
              label: 'game_ui.intensity'.tr(),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _buildIntensityCard(
                  value: 'soft',
                  emoji: '🌸',
                  label: 'game_ui.soft_label'.tr(),
                  description: 'game_ui.soft_zones'.tr(),
                  color: const Color(0xFFFF8FB1),
                ),
                const SizedBox(width: 12),
                _buildIntensityCard(
                  value: 'spicy',
                  emoji: '🌶️',
                  label: 'game_ui.spicy_label'.tr(),
                  description: 'game_ui.spicy_zones'.tr(),
                  color: const Color(0xFFFF6B35),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // Rounds
            _buildSectionLabel(
              icon: Icons.refresh,
              color: const Color(0xFFFFD166),
              label: 'game_ui.number_of_rounds'.tr(),
            ),
            const SizedBox(height: 14),
            Row(
              children: [3, 5, 7].map((rounds) {
                final isSelected = _totalRounds == rounds;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _totalRounds = rounds);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isSelected
                              ? const [
                                  Color(0xFFFFD166),
                                  Color(0xFFFFB347),
                                ]
                              : [
                                  Colors.white.withOpacity(0.06),
                                  Colors.white.withOpacity(0.02),
                                ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFFFD166)
                              : Colors.white.withOpacity(0.1),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFFFFD166)
                                      .withOpacity(0.45),
                                  blurRadius: 18,
                                  spreadRadius: 1,
                                )
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          '$rounds',
                          style: TextStyle(
                            fontFamily: 'PlayfairDisplay',
                            color:
                                isSelected ? const Color(0xFF2D1700) : Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 22,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 28),

            // Rules card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.info_outline,
                          color: Colors.white54, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'games.hot_cold.how_to_play'.tr(),
                        style: TextStyle(
                          fontFamily: 'DMSans',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.75),
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildRule('1', 'games.hot_cold.rule_1'.tr()),
                  const SizedBox(height: 8),
                  _buildRule('2', 'games.hot_cold.rule_2'.tr()),
                  const SizedBox(height: 8),
                  _buildRule('3', 'games.hot_cold.rule_3'.tr()),
                  const SizedBox(height: 8),
                  _buildRule('4', 'games.hot_cold.rule_4'.tr()),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Start button — gold gradient with shimmer
            AnimatedBuilder(
              animation: _shimmer,
              builder: (context, _) {
                return GestureDetector(
                  onTap: _startGame,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(-1 + 2 * _shimmer.value, 0),
                        end: Alignment(1 + 2 * _shimmer.value, 0),
                        colors: const [
                          Color(0xFFE53935),
                          Color(0xFFFF8C42),
                          Color(0xFFFFD166),
                          Color(0xFFFF8C42),
                          Color(0xFFE53935),
                        ],
                        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF6B35).withOpacity(0.45),
                          blurRadius: 22,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.play_arrow_rounded,
                            color: Colors.white, size: 28),
                        const SizedBox(width: 8),
                        Text(
                          'game_ui.start_playing'.tr(),
                          style: const TextStyle(
                            fontFamily: 'DMSans',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 1.2,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel({
    required IconData icon,
    required Color color,
    required String label,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'PlayfairDisplay',
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            decoration: TextDecoration.none,
          ),
        ),
      ],
    );
  }

  Widget _buildIntensityCard({
    required String value,
    required String emoji,
    required String label,
    required String description,
    required Color color,
  }) {
    final isSelected = _intensity == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _intensity = value);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isSelected
                  ? [color.withOpacity(0.32), color.withOpacity(0.12)]
                  : [
                      Colors.white.withOpacity(0.05),
                      Colors.white.withOpacity(0.02),
                    ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? color : Colors.white.withOpacity(0.1),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.45),
                      blurRadius: 22,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 36)),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'PlayfairDisplay',
                  color: isSelected ? color : Colors.white.withOpacity(0.85),
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  decoration: TextDecoration.none,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'DMSans',
                  color: Colors.white.withOpacity(0.55),
                  fontSize: 11,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRule(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFFFF6B35), Color(0xFFE53935)],
            ),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                fontFamily: 'DMSans',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'DMSans',
              fontSize: 13,
              height: 1.4,
              color: Colors.white.withOpacity(0.7),
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Game view
  // ---------------------------------------------------------------------------
  Widget _buildGameView(Color temperatureColor, Color accent, double mercury) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        children: [
          // Top: round + circular timer
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.casino,
                          color: Color(0xFFFFD166), size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'game_ui.round_of'.tr(namedArgs: {
                          'current': '$_roundNumber',
                          'total': '$_totalRounds',
                        }),
                        style: const TextStyle(
                          fontFamily: 'DMSans',
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 64,
                height: 64,
                child: CustomPaint(
                  painter: _CircularTimerPainter(
                    progress: _timeRemaining / _roundDuration,
                    color: _timeRemaining <= 10
                        ? const Color(0xFFE53935)
                        : const Color(0xFFFFD166),
                  ),
                  child: Center(
                    child: Text(
                      '$_timeRemaining',
                      style: TextStyle(
                        fontFamily: 'PlayfairDisplay',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _timeRemaining <= 10
                            ? const Color(0xFFFF8A80)
                            : Colors.white,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Seeker indicator with shimmer
          AnimatedBuilder(
            animation: _shimmer,
            builder: (context, _) {
              final color = _isSeeker
                  ? const Color(0xFFE879F9)
                  : const Color(0xFFFFD166);
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withOpacity(0.18),
                      color.withOpacity(0.06),
                      color.withOpacity(0.18),
                    ],
                    stops: [0.0, _shimmer.value, 1.0],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [
                          color,
                          color.withOpacity(0.4),
                        ]),
                        boxShadow: [
                          BoxShadow(
                              color: color.withOpacity(0.5), blurRadius: 12),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.search,
                            color: Colors.white, size: 16),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'game_ui.player_searches'.tr(
                          namedArgs: {'player': _isSeeker ? '1' : '2'}),
                      style: TextStyle(
                        fontFamily: 'PlayfairDisplay',
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 8),

          // Thermometer + halo (big, centered)
          Expanded(
            child: AnimatedBuilder(
              animation: Listenable.merge([_haloAnimation, _bulbPulse]),
              builder: (context, _) {
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final maxH = constraints.maxHeight;
                    // Reserve room for label below
                    final thermoH = (maxH - 80).clamp(220.0, 380.0);
                    final thermoW = thermoH * 0.42;

                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // Pulsing halo
                        Container(
                          width: thermoH * 0.95,
                          height: thermoH * 0.95,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                temperatureColor.withOpacity(
                                    0.32 + 0.18 * _haloAnimation.value),
                                temperatureColor.withOpacity(0.1),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.55, 1.0],
                            ),
                          ),
                        ),
                        // Soft outer ring
                        Container(
                          width: thermoH * 1.05,
                          height: thermoH * 1.05,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color:
                                  accent.withOpacity(0.18 * _haloAnimation.value),
                              width: 1.5,
                            ),
                          ),
                        ),
                        // Thermometer custom paint
                        SizedBox(
                          width: thermoW,
                          height: thermoH,
                          child: CustomPaint(
                            painter: _ThermometerPainter(
                              temperature: mercury,
                              mercuryColor: temperatureColor,
                              glowPulse:
                                  0.5 + 0.5 * _bulbPulse.value,
                              showTicks: true,
                            ),
                          ),
                        ),
                        // Floating temperature label below thermometer
                        Positioned(
                          bottom: 0,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _temperatureText(mercury),
                                style: TextStyle(
                                  fontFamily: 'PlayfairDisplay',
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                  color: accent,
                                  letterSpacing: 1.4,
                                  decoration: TextDecoration.none,
                                  shadows: [
                                    Shadow(
                                      color: temperatureColor.withOpacity(0.7),
                                      blurRadius: 14,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${(mercury * 100).round()}°',
                                style: TextStyle(
                                  fontFamily: 'DMSans',
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.45),
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // Guider buttons label
          Text(
            'game_ui.guider_buttons'.tr(),
            style: TextStyle(
              fontFamily: 'DMSans',
              fontSize: 12,
              color: Colors.white.withOpacity(0.5),
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 10),

          // Temperature buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTempButton(
                '🥶',
                -0.3,
                const Color(0xFF1E90FF),
                'games.hot_cold.freezing'.tr(),
              ),
              _buildTempButton(
                '❄️',
                -0.15,
                const Color(0xFF4DB8FF),
                'games.hot_cold.cold'.tr(),
              ),
              _buildTempButton(
                '🔥',
                0.15,
                const Color(0xFFFF8C42),
                'games.hot_cold.hot'.tr(),
              ),
              _buildTempButton(
                '🌋',
                0.3,
                const Color(0xFFE53935),
                'games.hot_cold.boiling'.tr(),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Found button — gold shimmer
          AnimatedBuilder(
            animation: _shimmer,
            builder: (context, _) {
              return GestureDetector(
                onTap: _handleFound,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(-1 + 2 * _shimmer.value, 0),
                      end: Alignment(1 + 2 * _shimmer.value, 0),
                      colors: const [
                        Color(0xFFB8860B),
                        Color(0xFFFFD166),
                        Color(0xFFFFF1B0),
                        Color(0xFFFFD166),
                        Color(0xFFB8860B),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD166).withOpacity(0.5),
                        blurRadius: 22,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.emoji_events,
                          color: Color(0xFF3A2200), size: 24),
                      const SizedBox(width: 10),
                      Text(
                        'game_ui.found'.tr(),
                        style: const TextStyle(
                          fontFamily: 'PlayfairDisplay',
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF3A2200),
                          letterSpacing: 1.4,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTempButton(
      String emoji, double delta, Color color, String label) {
    return GestureDetector(
      onTap: () => _updateTemperature(delta),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  color.withOpacity(0.5),
                  color.withOpacity(0.15),
                ],
              ),
              border: Border.all(color: color.withOpacity(0.85), width: 2),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.45),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 28)),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'DMSans',
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Rules sheet
  // ---------------------------------------------------------------------------
  void _showRules() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A0F3D),
              Color(0xFF0A0F2C),
            ],
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'games.hot_cold.how_to_play'.tr(),
              style: const TextStyle(
                fontFamily: 'PlayfairDisplay',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 16),
            _buildRule('1', 'games.hot_cold.rule_1'.tr()),
            const SizedBox(height: 10),
            _buildRule('2', 'games.hot_cold.rule_2'.tr()),
            const SizedBox(height: 10),
            _buildRule('3', 'games.hot_cold.rule_3'.tr()),
            const SizedBox(height: 10),
            _buildRule('4', 'games.hot_cold.rule_4'.tr()),
            const SizedBox(height: 18),
            Text(
              'game_ui.explore_with_fun'.tr(),
              style: TextStyle(
                fontFamily: 'DMSans',
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: Colors.white.withOpacity(0.55),
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Dialogs
// =============================================================================

class _ZoneRevealDialog extends StatelessWidget {
  final String emoji;
  final String name;
  final String hint;
  final String guiderLabel;
  final String instructions;
  final String hintLabel;
  final String actionLabel;
  final VoidCallback onConfirm;

  const _ZoneRevealDialog({
    required this.emoji,
    required this.name,
    required this.hint,
    required this.guiderLabel,
    required this.instructions,
    required this.hintLabel,
    required this.actionLabel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2D1B5C),
              Color(0xFF120822),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFFFFD166).withOpacity(0.25),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD166).withOpacity(0.18),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD166).withOpacity(0.14),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                guiderLabel,
                style: const TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFFD166),
                  letterSpacing: 1,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFE53935),
                    Color(0xFFFF8C42),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE53935).withOpacity(0.5),
                    blurRadius: 25,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 56)),
                  const SizedBox(height: 8),
                  Text(
                    name,
                    style: const TextStyle(
                      fontFamily: 'PlayfairDisplay',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      decoration: TextDecoration.none,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              instructions,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'DMSans',
                fontSize: 14,
                color: Colors.white.withOpacity(0.75),
                decoration: TextDecoration.none,
              ),
            ),
            if (hint.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '💡 $hintLabel: $hint',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: Colors.white.withOpacity(0.7),
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 22),
            GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                onConfirm();
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD166), Color(0xFFFFB347)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD166).withOpacity(0.4),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    actionLabel,
                    style: const TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF3A2200),
                      letterSpacing: 1,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundResultDialog extends StatelessWidget {
  final bool found;
  final int score;
  final String zone;
  final int player1Score;
  final int player2Score;
  final bool isLastRound;
  final VoidCallback onNext;

  const _RoundResultDialog({
    required this.found,
    required this.score,
    required this.zone,
    required this.player1Score,
    required this.player2Score,
    required this.isLastRound,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final color = found ? const Color(0xFFFFD166) : const Color(0xFFE53935);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A0F3D), Color(0xFF0A0F2C)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.4), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              found ? '🎯' : '⏰',
              style: const TextStyle(fontSize: 56),
            ),
            const SizedBox(height: 8),
            Text(
              found
                  ? 'games.hot_cold.found_title'.tr()
                  : 'game_ui.time_expired'.tr(),
              style: TextStyle(
                fontFamily: 'PlayfairDisplay',
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: color,
                decoration: TextDecoration.none,
              ),
              textAlign: TextAlign.center,
            ),
            if (found) ...[
              const SizedBox(height: 8),
              Text(
                'game_ui.points'.tr(args: [score.toString()]),
                style: const TextStyle(
                  fontFamily: 'PlayfairDisplay',
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFFFD166),
                  decoration: TextDecoration.none,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'game_ui.zone_was'.tr(namedArgs: {'zone': zone}),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.7),
                  decoration: TextDecoration.none,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.25),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _scoreColumn('game_ui.player_1'.tr(), player1Score,
                      const Color(0xFFE879F9)),
                  Text(
                    'game_ui.vs'.tr(),
                    style: const TextStyle(
                      fontFamily: 'PlayfairDisplay',
                      fontSize: 18,
                      color: Color(0xFFFFD166),
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  _scoreColumn('game_ui.player_2'.tr(), player2Score,
                      const Color(0xFFFFD166)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: onNext,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isLastRound
                        ? const [Color(0xFFFFD166), Color(0xFFFFB347)]
                        : const [Color(0xFFE53935), Color(0xFFFF6B35)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: (isLastRound
                              ? const Color(0xFFFFD166)
                              : const Color(0xFFE53935))
                          .withOpacity(0.45),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    isLastRound
                        ? 'game_ui.see_results'.tr()
                        : 'game_ui.next_round'.tr(),
                    style: TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isLastRound
                          ? const Color(0xFF3A2200)
                          : Colors.white,
                      letterSpacing: 1,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scoreColumn(String label, int score, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'DMSans',
            fontSize: 11,
            color: Colors.white.withOpacity(0.55),
            decoration: TextDecoration.none,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$score',
          style: TextStyle(
            fontFamily: 'PlayfairDisplay',
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: color,
            decoration: TextDecoration.none,
          ),
        ),
      ],
    );
  }
}

class _FinalResultsDialog extends StatelessWidget {
  final String winnerLabel;
  final int player1Score;
  final int player2Score;
  final String prizeText;
  final String newGameLabel;
  final String endLabel;
  final VoidCallback onNewGame;
  final VoidCallback onEnd;

  const _FinalResultsDialog({
    required this.winnerLabel,
    required this.player1Score,
    required this.player2Score,
    required this.prizeText,
    required this.newGameLabel,
    required this.endLabel,
    required this.onNewGame,
    required this.onEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2D1B5C),
              Color(0xFF1A0F3D),
              Color(0xFF0A0F2C),
            ],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: const Color(0xFFFFD166).withOpacity(0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD166).withOpacity(0.4),
              blurRadius: 35,
              spreadRadius: 3,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🏆', style: TextStyle(fontSize: 72)),
            const SizedBox(height: 8),
            Text(
              'game_ui.game_over'.tr(),
              style: const TextStyle(
                fontFamily: 'PlayfairDisplay',
                fontSize: 22,
                color: Color(0xFFFFD166),
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              winnerLabel,
              style: const TextStyle(
                fontFamily: 'PlayfairDisplay',
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                decoration: TextDecoration.none,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _bigScoreColumn('game_ui.player_1'.tr(), player1Score,
                      const Color(0xFFE879F9)),
                  Container(
                    width: 1,
                    height: 60,
                    color: Colors.white.withOpacity(0.15),
                  ),
                  _bigScoreColumn('game_ui.player_2'.tr(), player2Score,
                      const Color(0xFFFFD166)),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              prizeText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'DMSans',
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Color(0xFFFFD166),
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: onEnd,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.18)),
                      ),
                      child: Center(
                        child: Text(
                          endLabel,
                          style: TextStyle(
                            fontFamily: 'DMSans',
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.7),
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: onNewGame,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD166), Color(0xFFFFB347)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFD166).withOpacity(0.45),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          newGameLabel,
                          style: const TextStyle(
                            fontFamily: 'DMSans',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF3A2200),
                            letterSpacing: 1,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _bigScoreColumn(String label, int score, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'DMSans',
            fontSize: 12,
            color: Colors.white.withOpacity(0.55),
            decoration: TextDecoration.none,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$score',
          style: TextStyle(
            fontFamily: 'PlayfairDisplay',
            fontSize: 36,
            fontWeight: FontWeight.w700,
            color: color,
            decoration: TextDecoration.none,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Painters
// =============================================================================

/// Custom-painted vertical thermometer with mercury, ticks and bulb glow.
class _ThermometerPainter extends CustomPainter {
  final double temperature; // 0..1
  final Color mercuryColor;
  final double glowPulse; // 0..1
  final bool showTicks;

  _ThermometerPainter({
    required this.temperature,
    required this.mercuryColor,
    this.glowPulse = 0.5,
    this.showTicks = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final tubeWidth = w * 0.42;
    final bulbRadius = w * 0.46;
    final centerX = w / 2;

    // ----- Bulb glow -----
    final bulbCenter = Offset(centerX, h - bulbRadius);
    final glowPaint = Paint()
      ..shader = ui.Gradient.radial(
        bulbCenter,
        bulbRadius * 2.4,
        [
          mercuryColor.withOpacity(0.55 * glowPulse),
          mercuryColor.withOpacity(0.0),
        ],
      );
    canvas.drawCircle(bulbCenter, bulbRadius * 2.4, glowPaint);

    // ----- Outer tube (glass) -----
    final tubeRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        centerX - tubeWidth / 2,
        bulbRadius * 0.4,
        tubeWidth,
        h - bulbRadius * 1.2,
      ),
      Radius.circular(tubeWidth / 2),
    );

    // glass background gradient
    final glassPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(centerX - tubeWidth / 2, 0),
        Offset(centerX + tubeWidth / 2, 0),
        [
          Colors.white.withOpacity(0.08),
          Colors.white.withOpacity(0.18),
          Colors.white.withOpacity(0.04),
        ],
        [0.0, 0.5, 1.0],
      );
    canvas.drawRRect(tubeRect, glassPaint);

    // glass border
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Colors.white.withOpacity(0.35);
    canvas.drawRRect(tubeRect, borderPaint);

    // outer bulb circle (glass)
    final bulbBgPaint = Paint()
      ..shader = ui.Gradient.radial(
        bulbCenter - Offset(bulbRadius * 0.3, bulbRadius * 0.3),
        bulbRadius,
        [
          Colors.white.withOpacity(0.25),
          Colors.white.withOpacity(0.05),
        ],
      );
    canvas.drawCircle(bulbCenter, bulbRadius, bulbBgPaint);
    canvas.drawCircle(bulbCenter, bulbRadius, borderPaint);

    // ----- Mercury fill -----
    canvas.save();
    canvas.clipRRect(tubeRect);

    // Mercury inside the tube — rises with temperature
    final tubeTop = bulbRadius * 0.4;
    final tubeBottom = h - bulbRadius * 1.2 + tubeTop;
    final tubeHeight = tubeBottom - tubeTop;
    final mercuryTop = tubeBottom - tubeHeight * temperature;

    final mercuryRect = Rect.fromLTRB(
      centerX - tubeWidth * 0.36,
      mercuryTop,
      centerX + tubeWidth * 0.36,
      tubeBottom + bulbRadius,
    );

    final mercuryGradient = Paint()
      ..shader = ui.Gradient.linear(
        Offset(centerX - tubeWidth / 2, mercuryTop),
        Offset(centerX + tubeWidth / 2, mercuryTop),
        [
          mercuryColor.withOpacity(0.6),
          mercuryColor,
          mercuryColor.withOpacity(0.7),
        ],
        [0.0, 0.5, 1.0],
      );

    canvas.drawRRect(
      RRect.fromRectAndRadius(mercuryRect, Radius.circular(tubeWidth / 2)),
      mercuryGradient,
    );

    // Highlight on mercury (a thin shine)
    final shinePaint = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(centerX - tubeWidth * 0.18, mercuryTop + 4),
      Offset(centerX - tubeWidth * 0.18, tubeBottom),
      shinePaint,
    );
    canvas.restore();

    // ----- Mercury bulb fill (inside) -----
    final bulbFillPaint = Paint()
      ..shader = ui.Gradient.radial(
        bulbCenter - Offset(bulbRadius * 0.25, bulbRadius * 0.3),
        bulbRadius * 0.95,
        [
          mercuryColor.withOpacity(0.95),
          mercuryColor,
          Color.lerp(mercuryColor, Colors.black, 0.35)!,
        ],
        [0.0, 0.6, 1.0],
      );
    canvas.drawCircle(bulbCenter, bulbRadius * 0.85, bulbFillPaint);

    // bulb specular highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.35);
    canvas.drawCircle(
      bulbCenter - Offset(bulbRadius * 0.35, bulbRadius * 0.35),
      bulbRadius * 0.18,
      highlightPaint,
    );

    // ----- Ticks -----
    if (showTicks) {
      final tickPaint = Paint()
        ..color = Colors.white.withOpacity(0.5)
        ..strokeWidth = 1.2;
      const ticks = 10;
      for (int i = 0; i <= ticks; i++) {
        final y = tubeTop + (tubeHeight - 10) * (i / ticks);
        final isMajor = i % 2 == 0;
        final xStart = centerX + tubeWidth / 2 + 2;
        final xEnd = xStart + (isMajor ? 8 : 5);
        canvas.drawLine(Offset(xStart, y), Offset(xEnd, y), tickPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ThermometerPainter old) =>
      old.temperature != temperature ||
      old.mercuryColor != mercuryColor ||
      old.glowPulse != glowPulse;
}

/// Animated background — falling snowflakes when cold, rising sparks when hot.
class _BackgroundParticlesPainter extends CustomPainter {
  final List<_FloatParticle> particles;
  final double progress;
  final double coldness; // 0..1
  final double heat; // 0..1

  _BackgroundParticlesPainter({
    required this.particles,
    required this.progress,
    required this.coldness,
    required this.heat,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    for (final p in particles) {
      // Position based on phase
      final phase = (p.phase + progress * p.speed) % 1.0;
      final x = (p.x * size.width + sin(phase * 2 * pi + p.phase * 5) * 25)
          .clamp(0.0, size.width);

      // Snowflake (cold) — falls top→bottom
      if (p.colorIdx == 0 && coldness > 0.05) {
        final y = phase * size.height;
        paint.color = const Color(0xFFB3E5FC).withOpacity(0.55 * coldness);
        canvas.drawCircle(Offset(x, y), p.size * 0.9, paint);
        // tiny outer halo
        paint.color = const Color(0xFFB3E5FC).withOpacity(0.18 * coldness);
        canvas.drawCircle(Offset(x, y), p.size * 1.6, paint);
      }
      // Spark (hot) — rises bottom→top
      if (p.colorIdx == 1 && heat > 0.05) {
        final y = (1.0 - phase) * size.height;
        paint.color = const Color(0xFFFFB347).withOpacity(0.55 * heat);
        canvas.drawCircle(Offset(x, y), p.size * 0.9, paint);
        paint.color = const Color(0xFFFF6B6B).withOpacity(0.25 * heat);
        canvas.drawCircle(Offset(x, y), p.size * 1.8, paint);
      }
      // Neutral dust — always present, faint
      if (p.colorIdx == 2) {
        final y = phase * size.height;
        paint.color = Colors.white.withOpacity(0.07);
        canvas.drawCircle(Offset(x, y), p.size * 0.6, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BackgroundParticlesPainter old) =>
      old.progress != progress ||
      old.coldness != coldness ||
      old.heat != heat;
}

class _FloatParticle {
  final double x;
  final double size;
  final double speed;
  final double phase;
  final int colorIdx; // 0 snow, 1 spark, 2 dust

  _FloatParticle(Random r)
      : x = r.nextDouble(),
        size = 1.5 + r.nextDouble() * 3.5,
        speed = 0.3 + r.nextDouble() * 0.7,
        phase = r.nextDouble(),
        colorIdx = r.nextInt(3);
}

/// Circular timer ring painter
class _CircularTimerPainter extends CustomPainter {
  final double progress; // 1..0
  final Color color;

  _CircularTimerPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // Background ring
    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc with glow
    final glowPaint = Paint()
      ..color = color.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * pi * progress.clamp(0.0, 1.0);
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, -pi / 2, sweepAngle, false, glowPaint);
    canvas.drawArc(rect, -pi / 2, sweepAngle, false, fgPaint);
  }

  @override
  bool shouldRepaint(covariant _CircularTimerPainter old) =>
      old.progress != progress || old.color != color;
}

/// Confetti / celebration particles painter
class _CelebrationPainter extends CustomPainter {
  final List<_CelebrationParticle> particles;
  final double progress; // 0..1

  _CelebrationPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final colors = [
      const Color(0xFFFFD166),
      const Color(0xFFFF6B35),
      const Color(0xFFE879F9),
      const Color(0xFFFFFFFF),
      const Color(0xFFFFB347),
    ];
    for (final p in particles) {
      final opacity = (1 - progress).clamp(0.0, 1.0);
      if (opacity <= 0) continue;
      final yOffset = -240 * progress + 600 * progress * progress;
      final xOffset = p.x * 220 * progress;
      final pos = Offset(
        size.width / 2 + xOffset,
        size.height / 2 + yOffset,
      );
      final paint = Paint()
        ..color = colors[p.colorIdx % colors.length].withOpacity(opacity);

      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(p.rotation + progress * 7);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
          const Radius.circular(1),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _CelebrationPainter old) =>
      old.progress != progress;
}

class _CelebrationParticle {
  final double x; // -1..1
  final double size;
  final double rotation;
  final int colorIdx;

  _CelebrationParticle(Random r)
      : x = r.nextDouble() * 2 - 1,
        size = 4 + r.nextDouble() * 6,
        rotation = r.nextDouble() * 2 * pi,
        colorIdx = r.nextInt(5);
}
