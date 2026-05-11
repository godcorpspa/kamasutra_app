import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class MirrorChallengeScreen extends StatefulWidget {
  const MirrorChallengeScreen({super.key});

  @override
  State<MirrorChallengeScreen> createState() =>
      _MirrorChallengeScreenState();
}

class _MirrorChallengeScreenState extends State<MirrorChallengeScreen>
    with TickerProviderStateMixin {
  // ---------------------------------------------------------------------------
  // Game state
  // ---------------------------------------------------------------------------
  bool _gameStarted = false;
  bool _roundActive = false;
  bool _halfwayShown = false;
  bool _bonusRound = false;
  int _currentRound = 0;
  int _currentLeader = 1;
  String _selectedDifficulty = 'medium';
  int _roundDuration = 60;
  int _totalRounds = 5;
  Timer? _timer;
  int _remainingTime = 60;

  // Connection scoring
  int _connectionScore = 0;
  int _bestStreak = 0;
  int _currentStreak = 0;
  int _completedRounds = 0;

  List<_ChallengeData> _sessionChallenges = [];

  // ---------------------------------------------------------------------------
  // Animations
  // ---------------------------------------------------------------------------
  late final AnimationController _bgController;
  late final AnimationController _breathController;
  late final AnimationController _glowController;
  late final AnimationController _shimmerController;
  late final AnimationController _entryController;
  late final AnimationController _celebrateController;
  late final AnimationController _mirrorRipple;

  late Animation<double> _breathAnim;
  late Animation<double> _glowAnim;
  late Animation<double> _entryAnim;

  final List<_Particle> _particles =
      List.generate(40, (i) => _Particle(Random(i * 13 + 9)));
  final List<_Confetto> _confetti =
      List.generate(60, (i) => _Confetto(Random(i * 19 + 5)));

  final Random _random = Random();

  // ---------------------------------------------------------------------------
  // Challenges
  // ---------------------------------------------------------------------------
  List<_ChallengeData> get _allChallenges => const [
        _ChallengeData(
          key: 'ch1',
          icon: Icons.pan_tool,
          color: Color(0xFFE879F9),
          isBreathing: false,
        ),
        _ChallengeData(
          key: 'ch2',
          icon: Icons.face,
          color: Color(0xFFFF8FB1),
          isBreathing: false,
        ),
        _ChallengeData(
          key: 'ch3',
          icon: Icons.accessibility_new,
          color: Color(0xFFB388FF),
          isBreathing: false,
        ),
        _ChallengeData(
          key: 'ch4',
          icon: Icons.air,
          color: Color(0xFF7DD3FC),
          isBreathing: true,
        ),
        _ChallengeData(
          key: 'ch5',
          icon: Icons.visibility_off,
          color: Color(0xFFA78BFA),
          isBreathing: false,
        ),
        _ChallengeData(
          key: 'ch6',
          icon: Icons.slow_motion_video,
          color: Color(0xFF6EE7B7),
          isBreathing: false,
        ),
        _ChallengeData(
          key: 'ch7',
          icon: Icons.person,
          color: Color(0xFFFFD166),
          isBreathing: false,
        ),
        _ChallengeData(
          key: 'ch8',
          icon: Icons.people,
          color: Color(0xFFE53935),
          isBreathing: true,
        ),
      ];

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------
  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    )..repeat();

    // 4-4 breathing rhythm
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _breathAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.85, end: 1.05)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.05, end: 0.85)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
    ]).animate(_breathController);

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _glowAnim =
        CurvedAnimation(parent: _glowController, curve: Curves.easeInOut);

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _mirrorRipple = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _entryAnim = CurvedAnimation(
        parent: _entryController, curve: Curves.easeOutCubic);
    _entryController.forward();

    _celebrateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _bgController.dispose();
    _breathController.dispose();
    _glowController.dispose();
    _shimmerController.dispose();
    _mirrorRipple.dispose();
    _entryController.dispose();
    _celebrateController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Game flow
  // ---------------------------------------------------------------------------
  int _difficultyMultiplier() {
    switch (_selectedDifficulty) {
      case 'easy':
        return 1;
      case 'hard':
        return 3;
      case 'medium':
      default:
        return 2;
    }
  }

  void _startGame() {
    HapticFeedback.heavyImpact();
    final pool = List<_ChallengeData>.from(_allChallenges)..shuffle(_random);
    setState(() {
      _gameStarted = true;
      _roundActive = false;
      _halfwayShown = false;
      _bonusRound = false;
      _currentRound = 0;
      _currentLeader = _random.nextInt(2) + 1;
      _connectionScore = 0;
      _bestStreak = 0;
      _currentStreak = 0;
      _completedRounds = 0;
      _sessionChallenges = pool.take(_totalRounds).toList();
    });
    _entryController.forward(from: 0);
  }

  void _surprisePick() {
    HapticFeedback.mediumImpact();
    final pool = List<_ChallengeData>.from(_allChallenges)..shuffle(_random);
    final current = _sessionChallenges[_currentRound].key;
    final pick =
        pool.firstWhere((c) => c.key != current, orElse: () => pool.first);
    setState(() => _sessionChallenges[_currentRound] = pick);
    _entryController.forward(from: 0);
  }

  void _startRound() {
    HapticFeedback.heavyImpact();
    setState(() {
      _roundActive = true;
      _halfwayShown = false;
      _remainingTime = _roundDuration;
      // 20% chance of bonus round after round 1
      _bonusRound = _currentRound > 0 && _random.nextInt(5) == 0;
    });
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_remainingTime > 0) {
          _remainingTime--;
          // Halfway cue (≥30s rounds only)
          if (!_halfwayShown &&
              _roundDuration >= 30 &&
              _remainingTime == _roundDuration ~/ 2) {
            _halfwayShown = true;
            HapticFeedback.mediumImpact();
            _showHalfway();
          }
          if (_remainingTime == 5) {
            HapticFeedback.lightImpact();
          }
          if (_remainingTime <= 3 && _remainingTime > 0) {
            HapticFeedback.selectionClick();
          }
        } else {
          _timer?.cancel();
          HapticFeedback.heavyImpact();
          _endRound();
        }
      });
    });
  }

  void _showHalfway() {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFFB388FF),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            const Text('🪞 ', style: TextStyle(fontSize: 18)),
            Expanded(
              child: Text(
                'games.mirror_challenge.halfway_msg'.tr(),
                style: const TextStyle(
                  fontFamily: 'DMSans',
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _endRound() {
    _timer?.cancel();
    setState(() => _roundActive = false);
    _showRatingSheet();
  }

  void _showRatingSheet() {
    HapticFeedback.heavyImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => _RatingSheet(
        onRate: (rating) {
          Navigator.pop(context);
          _registerRating(rating);
        },
      ),
    );
  }

  void _registerRating(int rating) {
    HapticFeedback.heavyImpact();
    final basePoints = rating == 3 ? 20 : rating == 2 ? 10 : 5;
    final mult = _difficultyMultiplier();
    int points = basePoints * mult;

    // Streak handling: rating 3 keeps streak alive, others reset
    int newStreak = _currentStreak;
    if (rating == 3) {
      newStreak = _currentStreak + 1;
      if (newStreak >= 3) {
        points = (points * 1.5).round();
      }
    } else {
      newStreak = 0;
    }

    if (_bonusRound) {
      points *= 2;
    }

    setState(() {
      _connectionScore += points;
      _currentStreak = newStreak;
      if (newStreak > _bestStreak) _bestStreak = newStreak;
      _completedRounds++;
    });
    if (rating == 3) {
      _celebrateController.forward(from: 0);
    }
    _nextRound();
  }

  void _nextRound() {
    if (_currentRound < _sessionChallenges.length - 1) {
      setState(() {
        _currentRound++;
        _currentLeader = _currentLeader == 1 ? 2 : 1;
        _halfwayShown = false;
        _bonusRound = false;
      });
      _entryController.forward(from: 0);
    } else {
      _showFinalResults();
    }
  }

  void _showFinalResults() {
    HapticFeedback.heavyImpact();
    _celebrateController.forward(from: 0);
    final maxScore = 20 * _difficultyMultiplier() * 2 * _totalRounds;
    final ratio = maxScore == 0
        ? 0.0
        : (_connectionScore / maxScore).clamp(0.0, 1.0);
    final messageKey = ratio > 0.7
        ? 'games.mirror_challenge.connection_msg_high'
        : ratio > 0.4
            ? 'games.mirror_challenge.connection_msg_mid'
            : 'games.mirror_challenge.connection_msg_low';
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (context) => _FinalResultsDialog(
        score: _connectionScore,
        ratio: ratio,
        bestStreak: _bestStreak,
        completedRounds: _completedRounds,
        totalRounds: _totalRounds,
        message: messageKey.tr(),
        onPlayAgain: () {
          Navigator.pop(context);
          setState(() => _gameStarted = false);
        },
        onExit: () {
          Navigator.pop(context);
          if (mounted) context.pop();
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final isUrgent =
        _roundActive && _remainingTime <= 5;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white70),
          onPressed: () {
            if (_gameStarted) {
              _confirmExit();
            } else {
              context.pop();
            }
          },
        ),
        title: !_gameStarted
            ? Text(
                'games.mirror_challenge.app_bar_title'.tr(),
                style: const TextStyle(
                  fontFamily: 'PlayfairDisplay',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  decoration: TextDecoration.none,
                ),
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white70),
            onPressed: _showRules,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Reflective background
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isUrgent
                    ? const [
                        Color(0xFF3D0F1A),
                        Color(0xFF5C1B1B),
                        Color(0xFF1A0A2E),
                      ]
                    : const [
                        Color(0xFF1A0532),
                        Color(0xFF2D1B5C),
                        Color(0xFF1A0A2E),
                        Color(0xFF0A0F2C),
                      ],
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, _) {
              return CustomPaint(
                size: Size.infinite,
                painter: _ParticlesPainter(
                  particles: _particles,
                  progress: _bgController.value,
                ),
              );
            },
          ),
          SafeArea(
            child: !_gameStarted
                ? _buildSetupView()
                : _roundActive
                    ? _buildActiveRoundView()
                    : _buildPreRoundView(),
          ),
          // Celebration overlay
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _celebrateController,
              builder: (context, _) {
                if (_celebrateController.value == 0) {
                  return const SizedBox.shrink();
                }
                return CustomPaint(
                  size: Size.infinite,
                  painter: _ConfettiPainter(
                    confetti: _confetti,
                    progress: _celebrateController.value,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _confirmExit() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2D1B5C), Color(0xFF1A0A2E)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🪞', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text(
                'games.mirror_challenge.exit_confirm'.tr(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'PlayfairDisplay',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.15)),
                        ),
                        child: Center(
                          child: Text(
                            'common.cancel'.tr(),
                            style: TextStyle(
                              fontFamily: 'DMSans',
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
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
                    child: GestureDetector(
                      onTap: () {
                        _timer?.cancel();
                        Navigator.pop(context);
                        context.pop();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFE53935),
                              Color(0xFFFF8C42),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            'common.yes'.tr(),
                            style: const TextStyle(
                              fontFamily: 'DMSans',
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
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
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Setup view
  // ---------------------------------------------------------------------------
  Widget _buildSetupView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        children: [
          const SizedBox(height: 4),
          // Header — mirror with reflection
          AnimatedBuilder(
            animation: Listenable.merge(
                [_breathAnim, _glowAnim, _mirrorRipple]),
            builder: (context, _) {
              return SizedBox(
                height: 220,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFFD946EF).withOpacity(
                                0.32 + 0.18 * _glowAnim.value),
                            const Color(0xFFB388FF).withOpacity(0.15),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    Transform.scale(
                      scale: _breathAnim.value,
                      child: SizedBox(
                        width: 170,
                        height: 170,
                        child: CustomPaint(
                          painter: _MirrorPainter(
                            ripple: _mirrorRipple.value,
                            glow: _glowAnim.value,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          Text(
            'games.mirror_challenge.app_bar_title'.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'PlayfairDisplay',
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.8,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'games.mirror_challenge.subtitle_desc'.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'DMSans',
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: Colors.white.withOpacity(0.6),
              decoration: TextDecoration.none,
            ),
          ),

          const SizedBox(height: 26),

          // Difficulty
          _sectionLabel(
            icon: Icons.local_fire_department,
            color: const Color(0xFFFF6B35),
            label: 'games.mirror_challenge.difficulty'.tr(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _difficultyCard('easy',
                  'games.mirror_challenge.easy'.tr(), '30s', 30, '×1',
                  color: const Color(0xFF6EE7B7)),
              const SizedBox(width: 8),
              _difficultyCard('medium',
                  'games.mirror_challenge.medium'.tr(), '60s', 60, '×2',
                  color: const Color(0xFFFFD166)),
              const SizedBox(width: 8),
              _difficultyCard('hard',
                  'games.mirror_challenge.hard'.tr(), '90s', 90, '×3',
                  color: const Color(0xFFFF6B35)),
            ],
          ),

          const SizedBox(height: 22),

          // Rounds
          _sectionLabel(
            icon: Icons.refresh,
            color: const Color(0xFFE879F9),
            label: 'games.mirror_challenge.number_of_rounds'.tr(),
          ),
          const SizedBox(height: 12),
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
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isSelected
                            ? const [
                                Color(0xFFD946EF),
                                Color(0xFF6B2D5B),
                              ]
                            : [
                                Colors.white.withOpacity(0.06),
                                Colors.white.withOpacity(0.02),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFE879F9)
                            : Colors.white.withOpacity(0.1),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color:
                                    const Color(0xFFE879F9).withOpacity(0.4),
                                blurRadius: 16,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '$rounds',
                        style: const TextStyle(
                          fontFamily: 'PlayfairDisplay',
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 22),

          // Features
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFD946EF).withOpacity(0.10),
                  const Color(0xFF6B2D5B).withOpacity(0.04),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.auto_awesome,
                        color: Color(0xFFE879F9), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'games.mirror_challenge.features_title'.tr(),
                      style: const TextStyle(
                        fontFamily: 'PlayfairDisplay',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _featureChip('🫁',
                        'games.mirror_challenge.feature_breathing'.tr()),
                    _featureChip('🔥',
                        'games.mirror_challenge.feature_streak'.tr()),
                    _featureChip('💎',
                        'games.mirror_challenge.feature_bonus'.tr()),
                    _featureChip('🌌',
                        'games.mirror_challenge.feature_connection'.tr()),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Start button
          AnimatedBuilder(
            animation: _shimmerController,
            builder: (context, _) {
              return GestureDetector(
                onTap: _startGame,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(-1 + 2 * _shimmerController.value, 0),
                      end: Alignment(1 + 2 * _shimmerController.value, 0),
                      colors: const [
                        Color(0xFF6B2D5B),
                        Color(0xFFD946EF),
                        Color(0xFFE879F9),
                        Color(0xFFD946EF),
                        Color(0xFF6B2D5B),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD946EF).withOpacity(0.5),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.spa, color: Colors.white, size: 24),
                      const SizedBox(width: 10),
                      Text(
                        'games.mirror_challenge.start_challenge'.tr(),
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
    );
  }

  Widget _sectionLabel({
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

  Widget _difficultyCard(String id, String label, String time, int seconds,
      String mult,
      {required Color color}) {
    final isSelected = _selectedDifficulty == id;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _selectedDifficulty = id;
            _roundDuration = seconds;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isSelected
                  ? [color.withOpacity(0.32), color.withOpacity(0.12)]
                  : [
                      Colors.white.withOpacity(0.06),
                      Colors.white.withOpacity(0.02),
                    ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? color : Colors.white.withOpacity(0.1),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 18,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'PlayfairDisplay',
                  color:
                      isSelected ? color : Colors.white.withOpacity(0.85),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                time,
                style: TextStyle(
                  fontFamily: 'DMSans',
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 10,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  mult,
                  style: TextStyle(
                    fontFamily: 'DMSans',
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _featureChip(String emoji, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'DMSans',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.8),
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Pre-round view
  // ---------------------------------------------------------------------------
  Widget _buildPreRoundView() {
    final challenge = _sessionChallenges[_currentRound];
    final color = _currentLeader == 1
        ? const Color(0xFFE879F9)
        : const Color(0xFFFFD166);

    return AnimatedBuilder(
      animation: _entryAnim,
      builder: (context, child) {
        return Opacity(
          opacity: _entryAnim.value,
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - _entryAnim.value)),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          children: [
            _buildTopBar(),
            const SizedBox(height: 12),
            _buildLeaderPill(color),
            const SizedBox(height: 16),
            Expanded(child: Center(child: _buildChallengeCard(challenge))),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _surprisePick,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFFD166),
                            Color(0xFFFFB347),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFD166).withOpacity(0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🎲',
                              style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 6),
                          Text(
                            'games.mirror_challenge.surprise'.tr(),
                            style: const TextStyle(
                              fontFamily: 'DMSans',
                              color: Color(0xFF3A2200),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: AnimatedBuilder(
                    animation: _shimmerController,
                    builder: (context, _) {
                      return GestureDetector(
                        onTap: _startRound,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment(
                                  -1 + 2 * _shimmerController.value, 0),
                              end: Alignment(
                                  1 + 2 * _shimmerController.value, 0),
                              colors: const [
                                Color(0xFF6B2D5B),
                                Color(0xFFD946EF),
                                Color(0xFFE879F9),
                                Color(0xFFD946EF),
                                Color(0xFF6B2D5B),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    const Color(0xFFD946EF).withOpacity(0.45),
                                blurRadius: 18,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.play_arrow_rounded,
                                  color: Colors.white, size: 22),
                              const SizedBox(width: 6),
                              Text(
                                'games.mirror_challenge.start_seconds'.tr(
                                    namedArgs: {
                                      'seconds': '$_roundDuration',
                                    }),
                                style: const TextStyle(
                                  fontFamily: 'DMSans',
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.spa,
                      color: Color(0xFFE879F9), size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'games.mirror_challenge.round_of'.tr(namedArgs: {
                      'current': '${_currentRound + 1}',
                      'total': '$_totalRounds',
                    }),
                    style: TextStyle(
                      fontFamily: 'DMSans',
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const Spacer(),
                  if (_currentStreak > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF6B35), Color(0xFFE53935)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🔥',
                              style: TextStyle(fontSize: 10)),
                          const SizedBox(width: 3),
                          Text(
                            '$_currentStreak',
                            style: const TextStyle(
                              fontFamily: 'PlayfairDisplay',
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFB388FF).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$_connectionScore',
                      style: const TextStyle(
                        fontFamily: 'PlayfairDisplay',
                        color: Color(0xFFB388FF),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  minHeight: 4,
                  value: (_currentRound + 1) / _totalRounds,
                  backgroundColor: Colors.white.withOpacity(0.08),
                  valueColor:
                      const AlwaysStoppedAnimation(Color(0xFFD946EF)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderPill(Color color) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.18),
                color.withOpacity(0.06),
                color.withOpacity(0.18),
              ],
              stops: [0.0, _shimmerController.value, 1.0],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [color, color.withOpacity(0.4)],
                  ),
                  boxShadow: [
                    BoxShadow(
                        color: color.withOpacity(0.5), blurRadius: 10),
                  ],
                ),
                child: Center(
                  child: Text(
                    '$_currentLeader',
                    style: const TextStyle(
                      fontFamily: 'PlayfairDisplay',
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'games.mirror_challenge.partner_leads'
                    .tr(namedArgs: {'player': '$_currentLeader'}),
                style: TextStyle(
                  fontFamily: 'PlayfairDisplay',
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  decoration: TextDecoration.none,
                ),
              ),
              if (_bonusRound) ...[
                const SizedBox(width: 10),
                AnimatedBuilder(
                  animation: _glowAnim,
                  builder: (context, _) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD166), Color(0xFFFFB347)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFD166)
                                .withOpacity(0.5 * _glowAnim.value),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const Text(
                        '💎 ×2',
                        style: TextStyle(
                          fontFamily: 'DMSans',
                          color: Color(0xFF3A2200),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildChallengeCard(_ChallengeData c) {
    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (context, _) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                c.color.withOpacity(0.32),
                c.color.withOpacity(0.12),
              ],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: c.color.withOpacity(0.55), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: c.color.withOpacity(0.35 + 0.15 * _glowAnim.value),
                blurRadius: 22,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      c.color.withOpacity(0.7),
                      c.color.withOpacity(0.15),
                    ],
                  ),
                  border: Border.all(color: c.color, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: c.color.withOpacity(0.4 * _glowAnim.value),
                      blurRadius: 18,
                    ),
                  ],
                ),
                child: Icon(c.icon, color: Colors.white, size: 38),
              ),
              const SizedBox(height: 12),
              if (c.isBreathing)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7DD3FC).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text('🫁', style: TextStyle(fontSize: 11)),
                      SizedBox(width: 4),
                      Text(
                        'BREATHING MODE',
                        style: TextStyle(
                          fontFamily: 'DMSans',
                          color: Color(0xFF7DD3FC),
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ),
              if (c.isBreathing) const SizedBox(height: 8),
              Text(
                'games.mirror_challenge.${c.key}_title'.tr(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'PlayfairDisplay',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.3,
                  decoration: TextDecoration.none,
                  shadows: [
                    Shadow(color: Color(0x66000000), blurRadius: 4),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Container(
                height: 1,
                width: 70,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.white.withOpacity(0.4),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'games.mirror_challenge.${c.key}_desc'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 13,
                  height: 1.5,
                  color: Colors.white.withOpacity(0.85),
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lightbulb_outline,
                        color: Color(0xFFFFD166), size: 14),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'games.mirror_challenge.${c.key}_tip'.tr(),
                        style: TextStyle(
                          fontFamily: 'DMSans',
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Active round view
  // ---------------------------------------------------------------------------
  Widget _buildActiveRoundView() {
    final c = _sessionChallenges[_currentRound];
    final progress = (1 - (_remainingTime / _roundDuration)).clamp(0.0, 1.0);
    final isUrgent = _remainingTime <= 5;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        children: [
          _buildTopBar(),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(c.icon, color: c.color, size: 18),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'games.mirror_challenge.${c.key}_title'.tr(),
                  style: const TextStyle(
                    fontFamily: 'PlayfairDisplay',
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    decoration: TextDecoration.none,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'games.mirror_challenge.partner_guides'.tr(
                namedArgs: {'player': '$_currentLeader'}),
            style: TextStyle(
              fontFamily: 'DMSans',
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: Colors.white.withOpacity(0.55),
              decoration: TextDecoration.none,
            ),
          ),

          // BIG breathing/timer ring
          Expanded(
            child: Center(
              child: AnimatedBuilder(
                animation: Listenable.merge([_breathAnim, _glowAnim]),
                builder: (context, _) {
                  final scale =
                      c.isBreathing ? _breathAnim.value : 1.0;
                  return SizedBox(
                    width: 280,
                    height: 280,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer halo
                        Container(
                          width: 280,
                          height: 280,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                (isUrgent
                                        ? const Color(0xFFE53935)
                                        : c.color)
                                    .withOpacity(
                                        0.32 + 0.18 * _glowAnim.value),
                                c.color.withOpacity(0.1),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        // Breathing ring
                        Transform.scale(
                          scale: scale,
                          child: Container(
                            width: 220,
                            height: 220,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  c.color.withOpacity(0.25),
                                  c.color.withOpacity(0.06),
                                ],
                              ),
                              border: Border.all(
                                color: c.color.withOpacity(0.5),
                                width: 1,
                              ),
                            ),
                          ),
                        ),
                        // Progress ring
                        SizedBox(
                          width: 240,
                          height: 240,
                          child: CustomPaint(
                            painter: _RingProgressPainter(
                              progress: progress,
                              color: isUrgent
                                  ? const Color(0xFFE53935)
                                  : c.color,
                              pulse: isUrgent ? _glowAnim.value : 0.0,
                            ),
                          ),
                        ),
                        // Center number
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$_remainingTime',
                              style: TextStyle(
                                fontFamily: 'PlayfairDisplay',
                                fontSize: isUrgent ? 70 : 60,
                                fontWeight: FontWeight.w700,
                                color: isUrgent
                                    ? const Color(0xFFFF6B6B)
                                    : Colors.white,
                                decoration: TextDecoration.none,
                                shadows: isUrgent
                                    ? const [
                                        Shadow(
                                            color: Color(0xFFE53935),
                                            blurRadius: 20),
                                      ]
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              c.isBreathing
                                  ? _breathePhaseLabel()
                                  : 'games.mirror_challenge.seconds'.tr(),
                              style: TextStyle(
                                fontFamily: 'DMSans',
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.55),
                                letterSpacing: 1.5,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Tip reminder
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline,
                    color: Color(0xFFFFD166), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'games.mirror_challenge.${c.key}_tip'.tr(),
                    style: TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.white.withOpacity(0.7),
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // End early
          TextButton.icon(
            onPressed: _endRound,
            icon: Icon(Icons.check_circle_outline,
                color: Colors.white.withOpacity(0.5), size: 16),
            label: Text(
              'games.mirror_challenge.end_early'.tr(),
              style: TextStyle(
                fontFamily: 'DMSans',
                color: Colors.white.withOpacity(0.5),
                fontSize: 13,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _breathePhaseLabel() {
    final v = _breathController.value;
    return v < 0.5
        ? 'games.mirror_challenge.inhale'.tr()
        : 'games.mirror_challenge.exhale'.tr();
  }

  // ---------------------------------------------------------------------------
  // Rules
  // ---------------------------------------------------------------------------
  void _showRules() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2D1B5C), Color(0xFF1A0A2E)],
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 30),
        child: SingleChildScrollView(
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
                'games.mirror_challenge.how_to_play'.tr(),
                style: const TextStyle(
                  fontFamily: 'PlayfairDisplay',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 16),
              _ruleRow('1', 'games.mirror_challenge.instruction_1'.tr()),
              const SizedBox(height: 8),
              _ruleRow('2', 'games.mirror_challenge.instruction_2'.tr()),
              const SizedBox(height: 8),
              _ruleRow('3', 'games.mirror_challenge.instruction_3'.tr()),
              const SizedBox(height: 8),
              _ruleRow('4', 'games.mirror_challenge.instruction_4'.tr()),
              const SizedBox(height: 16),
              Text(
                'games.mirror_challenge.closing'.tr(),
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
      ),
    );
  }

  Widget _ruleRow(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFFD946EF), Color(0xFF6B2D5B)],
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
}

// =============================================================================
// Data
// =============================================================================
class _ChallengeData {
  final String key;
  final IconData icon;
  final Color color;
  final bool isBreathing;
  const _ChallengeData({
    required this.key,
    required this.icon,
    required this.color,
    required this.isBreathing,
  });
}

// =============================================================================
// Rating sheet
// =============================================================================
class _RatingSheet extends StatelessWidget {
  final ValueChanged<int> onRate;
  const _RatingSheet({required this.onRate});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2D1B5C), Color(0xFF1A0A2E)],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 18),
          const Text('🪞', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 6),
          Text(
            'games.mirror_challenge.connection_how'.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'PlayfairDisplay',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'games.mirror_challenge.rate_hint'.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'DMSans',
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: Colors.white.withOpacity(0.55),
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 22),
          _ratingOption(
            rating: 1,
            emoji: '😕',
            label: 'games.mirror_challenge.feedback_hard'.tr(),
            desc: 'games.mirror_challenge.rate_low_desc'.tr(),
            color: const Color(0xFFFFB6C1),
          ),
          const SizedBox(height: 10),
          _ratingOption(
            rating: 2,
            emoji: '😊',
            label: 'games.mirror_challenge.feedback_good'.tr(),
            desc: 'games.mirror_challenge.rate_mid_desc'.tr(),
            color: const Color(0xFFB388FF),
          ),
          const SizedBox(height: 10),
          _ratingOption(
            rating: 3,
            emoji: '🤩',
            label: 'games.mirror_challenge.feedback_perfect'.tr(),
            desc: 'games.mirror_challenge.rate_high_desc'.tr(),
            color: const Color(0xFFFFD166),
          ),
        ],
      ),
    );
  }

  Widget _ratingOption({
    required int rating,
    required String emoji,
    required String label,
    required String desc,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () => onRate(rating),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.25),
              color.withOpacity(0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.25),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'PlayfairDisplay',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  Text(
                    desc,
                    style: TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.65),
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Final results dialog
// =============================================================================
class _FinalResultsDialog extends StatelessWidget {
  final int score;
  final double ratio;
  final int bestStreak;
  final int completedRounds;
  final int totalRounds;
  final String message;
  final VoidCallback onPlayAgain;
  final VoidCallback onExit;

  const _FinalResultsDialog({
    required this.score,
    required this.ratio,
    required this.bestStreak,
    required this.completedRounds,
    required this.totalRounds,
    required this.message,
    required this.onPlayAgain,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2D1B5C),
              Color(0xFF1A0A2E),
              Color(0xFF120822),
            ],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
              color: const Color(0xFFD946EF).withOpacity(0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD946EF).withOpacity(0.5),
              blurRadius: 35,
              spreadRadius: 3,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🪞', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 4),
                Text(
                  'games.mirror_challenge.session_complete_title'.tr(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'PlayfairDisplay',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFD946EF),
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0x33D946EF),
                        Color(0x336B2D5B),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: const Color(0xFFD946EF).withOpacity(0.35)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'games.mirror_challenge.connection_score'.tr(),
                        style: TextStyle(
                          fontFamily: 'DMSans',
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.6),
                          letterSpacing: 1.5,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$score',
                        style: const TextStyle(
                          fontFamily: 'PlayfairDisplay',
                          fontSize: 44,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          decoration: TextDecoration.none,
                          shadows: [
                            Shadow(color: Color(0xFFD946EF), blurRadius: 18),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 8,
                        child: CustomPaint(
                          size: const Size(double.infinity, 8),
                          painter: _MeterPainter(ratio: ratio),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'DMSans',
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: Colors.white.withOpacity(0.85),
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _stat(
                        icon: '🔥',
                        label: 'games.mirror_challenge.best_streak'.tr(),
                        value: '$bestStreak',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _stat(
                        icon: '🪞',
                        label:
                            'games.mirror_challenge.rounds_done'.tr(),
                        value: '$completedRounds/$totalRounds',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: onExit,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.18)),
                          ),
                          child: Center(
                            child: Text(
                              'games.mirror_challenge.exit'.tr(),
                              style: TextStyle(
                                fontFamily: 'DMSans',
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 14,
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
                        onTap: onPlayAgain,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFD946EF),
                                Color(0xFF6B2D5B),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFD946EF).withOpacity(0.45),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'games.mirror_challenge.play_again'.tr(),
                              style: const TextStyle(
                                fontFamily: 'DMSans',
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
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
        ),
      ),
    );
  }

  Widget _stat({
    required String icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'PlayfairDisplay',
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.none,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'DMSans',
              color: Colors.white.withOpacity(0.55),
              fontSize: 10,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Painters
// =============================================================================

/// Mirror with face reflection (yin-yang style two profiles).
class _MirrorPainter extends CustomPainter {
  final double ripple;
  final double glow;

  _MirrorPainter({required this.ripple, required this.glow});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);
    final r = w * 0.45;

    // Frame halo
    final frameHalo = Paint()
      ..color = const Color(0xFFD946EF).withOpacity(0.4 + 0.2 * glow)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(center, r * 1.1, frameHalo);

    // Frame ring
    final framePaint = Paint()
      ..shader = ui.Gradient.sweep(
        center,
        const [
          Color(0xFFFFD166),
          Color(0xFFD946EF),
          Color(0xFFE879F9),
          Color(0xFFFFD166),
        ],
        const [0.0, 0.33, 0.66, 1.0],
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    canvas.drawCircle(center, r * 1.05, framePaint);

    // Inner glass background
    final glass = Paint()
      ..shader = ui.Gradient.radial(
        center - Offset(r * 0.3, r * 0.3),
        r,
        const [
          Color(0xFFE0B8FF),
          Color(0xFF6B2D5B),
          Color(0xFF1A0A2E),
        ],
        [0.0, 0.55, 1.0],
      );
    canvas.drawCircle(center, r, glass);

    // Two facing profiles (yin-yang style)
    final leftProfile = Paint()
      ..color = Colors.white.withOpacity(0.65)
      ..style = PaintingStyle.fill;
    final rightProfile = Paint()
      ..color = const Color(0xFF6B2D5B).withOpacity(0.85)
      ..style = PaintingStyle.fill;

    // Left silhouette (profile facing right)
    final leftPath = Path();
    leftPath.moveTo(center.dx, center.dy - r * 0.7); // top of head
    leftPath.quadraticBezierTo(center.dx - r * 0.5, center.dy - r * 0.5,
        center.dx - r * 0.45, center.dy - r * 0.15); // back of head
    leftPath.quadraticBezierTo(
        center.dx - r * 0.4, center.dy + r * 0.1, center.dx - r * 0.1,
        center.dy + r * 0.15); // neck
    leftPath.lineTo(center.dx - r * 0.08, center.dy + r * 0.45);
    leftPath.lineTo(center.dx - r * 0.6, center.dy + r * 0.6);
    leftPath.lineTo(center.dx - r * 0.7, center.dy + r * 0.7);
    leftPath.lineTo(center.dx, center.dy + r * 0.7);
    leftPath.lineTo(center.dx, center.dy - r * 0.7);
    leftPath.close();
    canvas.drawPath(leftPath, leftProfile);

    // Right silhouette (profile facing left, mirror of left)
    final rightPath = Path();
    rightPath.moveTo(center.dx, center.dy - r * 0.7);
    rightPath.quadraticBezierTo(center.dx + r * 0.5, center.dy - r * 0.5,
        center.dx + r * 0.45, center.dy - r * 0.15);
    rightPath.quadraticBezierTo(
        center.dx + r * 0.4, center.dy + r * 0.1, center.dx + r * 0.1,
        center.dy + r * 0.15);
    rightPath.lineTo(center.dx + r * 0.08, center.dy + r * 0.45);
    rightPath.lineTo(center.dx + r * 0.6, center.dy + r * 0.6);
    rightPath.lineTo(center.dx + r * 0.7, center.dy + r * 0.7);
    rightPath.lineTo(center.dx, center.dy + r * 0.7);
    rightPath.lineTo(center.dx, center.dy - r * 0.7);
    rightPath.close();
    canvas.drawPath(rightPath, rightProfile);

    // Ripple effect from center
    final ripplePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withOpacity(0.3 * (1 - ripple));
    canvas.drawCircle(center, r * ripple * 0.9, ripplePaint);
    canvas.drawCircle(center, r * ((ripple + 0.5) % 1) * 0.9,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = Colors.white.withOpacity(0.2));

    // Clip frame: ensure the profiles stay inside the mirror disc
    // (we already painted them with the same radius, so no clip needed)

    // Specular highlight on the glass
    final shine = Paint()
      ..shader = ui.Gradient.radial(
        center - Offset(r * 0.4, r * 0.5),
        r * 0.25,
        [
          Colors.white.withOpacity(0.4),
          Colors.transparent,
        ],
      );
    canvas.drawCircle(
        center - Offset(r * 0.4, r * 0.5), r * 0.25, shine);
  }

  @override
  bool shouldRepaint(covariant _MirrorPainter old) =>
      old.ripple != ripple || old.glow != glow;
}

/// Outer ring progress with sweep gradient + glow.
class _RingProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double pulse;

  _RingProgressPainter({
    required this.progress,
    required this.color,
    this.pulse = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;

    final track = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);

    if (progress <= 0) return;

    final glow = Paint()
      ..color = color.withOpacity(0.45 + 0.25 * pulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    final fg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..shader = ui.Gradient.sweep(
        center,
        [
          color.withOpacity(0.6),
          color,
          color.withOpacity(0.85),
        ],
        const [0.0, 0.5, 1.0],
        TileMode.clamp,
        -pi / 2,
        -pi / 2 + 2 * pi * progress,
      );

    final rect = Rect.fromCircle(center: center, radius: radius);
    final sweep = 2 * pi * progress.clamp(0.0, 1.0);
    canvas.drawArc(rect, -pi / 2, sweep, false, glow);
    canvas.drawArc(rect, -pi / 2, sweep, false, fg);

    final tickPaint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..strokeWidth = 1.2;
    for (int i = 0; i < 12; i++) {
      final a = (i / 12) * 2 * pi;
      final p1 = center +
          Offset(cos(a) * (radius - 16), sin(a) * (radius - 16));
      final p2 = center +
          Offset(cos(a) * (radius - 22), sin(a) * (radius - 22));
      canvas.drawLine(p1, p2, tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RingProgressPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.pulse != pulse;
}

/// Cosmic particle background.
class _Particle {
  final double x;
  final double size;
  final double speed;
  final double phase;
  final int colorIdx;
  _Particle(Random r)
      : x = r.nextDouble(),
        size = 1.2 + r.nextDouble() * 2.5,
        speed = 0.2 + r.nextDouble() * 0.5,
        phase = r.nextDouble(),
        colorIdx = r.nextInt(4);
}

class _ParticlesPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ParticlesPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // Nebula
    for (int i = 0; i < 4; i++) {
      final phase = (progress + i * 0.27) % 1.0;
      final cx = size.width * (0.2 + 0.6 * (i / 4)) +
          sin(phase * 2 * pi) * 30;
      final cy = size.height * (0.2 + 0.6 * ((i + 1) / 5)) +
          cos(phase * 2 * pi) * 30;
      final paint = Paint()
        ..shader = ui.Gradient.radial(
          Offset(cx, cy),
          110,
          [
            const [
              Color(0xFFD946EF),
              Color(0xFFB388FF),
              Color(0xFFE879F9),
              Color(0xFFFFD166),
            ][i % 4]
                .withOpacity(0.07),
            Colors.transparent,
          ],
        );
      canvas.drawCircle(Offset(cx, cy), 110, paint);
    }
    // Particles
    final paint = Paint();
    final colors = [
      const Color(0xFFD946EF),
      const Color(0xFFE879F9),
      Colors.white,
      const Color(0xFFFFD166),
    ];
    for (final p in particles) {
      final phase = (p.phase + progress * p.speed) % 1.0;
      final x = p.x * size.width + sin(phase * 2 * pi + p.phase * 4) * 22;
      final y = (1 - phase) * size.height;
      final opacity =
          (0.15 + 0.3 * (1 - (phase - 0.5).abs() * 2)).clamp(0.0, 0.45);
      paint.color = colors[p.colorIdx].withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlesPainter old) =>
      old.progress != progress;
}

/// Connection meter (gradient bar).
class _MeterPainter extends CustomPainter {
  final double ratio;
  _MeterPainter({required this.ratio});
  @override
  void paint(Canvas canvas, Size size) {
    final track = Paint()..color = Colors.white.withOpacity(0.1);
    final trackRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(size.height / 2),
    );
    canvas.drawRRect(trackRect, track);
    if (ratio > 0) {
      final fillRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width * ratio, size.height),
        Radius.circular(size.height / 2),
      );
      final glow = Paint()
        ..color = const Color(0xFFD946EF).withOpacity(0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawRRect(fillRect, glow);
      final fill = Paint()
        ..shader = ui.Gradient.linear(
          const Offset(0, 0),
          Offset(size.width * ratio, 0),
          const [
            Color(0xFF6B2D5B),
            Color(0xFFD946EF),
            Color(0xFFFFD166),
          ],
        );
      canvas.drawRRect(fillRect, fill);
    }
  }

  @override
  bool shouldRepaint(covariant _MeterPainter old) => old.ratio != ratio;
}

/// Confetti overlay.
class _ConfettiPainter extends CustomPainter {
  final List<_Confetto> confetti;
  final double progress;
  _ConfettiPainter({required this.confetti, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final colors = [
      const Color(0xFFFFD166),
      const Color(0xFFD946EF),
      const Color(0xFFE879F9),
      Colors.white,
      const Color(0xFFFFB347),
    ];
    for (final c in confetti) {
      final opacity = (1 - progress).clamp(0.0, 1.0);
      if (opacity <= 0) continue;
      final yOffset = -240 * progress + 600 * progress * progress;
      final xOffset = c.x * 220 * progress;
      final pos = Offset(
        size.width / 2 + xOffset,
        size.height / 2 + yOffset,
      );
      final paint = Paint()
        ..color = colors[c.colorIdx % colors.length].withOpacity(opacity);
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(c.rotation + progress * 7);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset.zero, width: c.size, height: c.size * 0.55),
          const Radius.circular(1),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) =>
      old.progress != progress;
}

class _Confetto {
  final double x;
  final double size;
  final double rotation;
  final int colorIdx;
  _Confetto(Random r)
      : x = r.nextDouble() * 2 - 1,
        size = 4 + r.nextDouble() * 7,
        rotation = r.nextDouble() * 2 * pi,
        colorIdx = r.nextInt(5);
}
