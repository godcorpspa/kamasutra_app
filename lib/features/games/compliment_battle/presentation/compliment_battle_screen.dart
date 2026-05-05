import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class ComplimentBattleScreen extends StatefulWidget {
  const ComplimentBattleScreen({super.key});

  @override
  State<ComplimentBattleScreen> createState() =>
      _ComplimentBattleScreenState();
}

class _ComplimentBattleScreenState extends State<ComplimentBattleScreen>
    with TickerProviderStateMixin {
  // ---------------------------------------------------------------------------
  // Game state
  // ---------------------------------------------------------------------------
  bool _gameStarted = false;
  bool _isThinking = false;
  bool _judging = false; // partner is judging the compliment
  bool _bonusRound = false;
  int _currentPlayer = 1;
  int _player1Score = 0;
  int _player2Score = 0;
  int _roundNumber = 1;
  int _totalRounds = 5;
  Timer? _timer;
  int _timeRemaining = 16;
  int _baseTime = 16;
  String _difficulty = 'normal';
  int _player1Streak = 0;
  int _player2Streak = 0;
  int _longestStreak = 0;
  int _totalCompliments = 0;

  // Power-ups (each player has 1 of each)
  bool _player1ExtraTime = false; // true = used
  bool _player2ExtraTime = false;
  bool _player1Skip = false;
  bool _player2Skip = false;

  Map<String, dynamic>? _currentCategory;
  final List<String> _usedCategories = [];

  // ---------------------------------------------------------------------------
  // Animations
  // ---------------------------------------------------------------------------
  late final AnimationController _bgParticles;
  late final AnimationController _shimmer;
  late final AnimationController _glow;
  late final AnimationController _categoryFlip;
  late final AnimationController _scoreBump;
  late final AnimationController _bell;
  late final AnimationController _celebrate;

  late Animation<double> _glowAnim;
  late Animation<double> _categoryFlipAnim;
  late Animation<double> _scoreBumpAnim;

  final List<_Spark> _sparks =
      List.generate(40, (i) => _Spark(Random(i * 13 + 7)));
  final List<_Confetto> _confetti =
      List.generate(70, (i) => _Confetto(Random(i * 19 + 3)));

  final Random _random = Random();

  // ---------------------------------------------------------------------------
  // Categories (10)
  // ---------------------------------------------------------------------------
  List<Map<String, dynamic>> get _categories => [
        {
          'key': 'physical',
          'emoji': '👀',
          'color': const Color(0xFFE879F9),
        },
        {
          'key': 'personality',
          'emoji': '💫',
          'color': const Color(0xFFB388FF),
        },
        {
          'key': 'talents',
          'emoji': '🌟',
          'color': const Color(0xFFFFD166),
        },
        {
          'key': 'moments',
          'emoji': '💑',
          'color': const Color(0xFFFF8FB1),
        },
        {
          'key': 'feelings',
          'emoji': '💕',
          'color': const Color(0xFFFF6B6B),
        },
        {
          'key': 'unique',
          'emoji': '✨',
          'color': const Color(0xFF7DD3FC),
        },
        {
          'key': 'intelligence',
          'emoji': '🧠',
          'color': const Color(0xFFA78BFA),
        },
        {
          'key': 'kindness',
          'emoji': '🤗',
          'color': const Color(0xFF6EE7B7),
        },
        {
          'key': 'passion',
          'emoji': '🔥',
          'color': const Color(0xFFFF6B35),
        },
        {
          'key': 'creativity',
          'emoji': '🎨',
          'color': const Color(0xFFE6B4FF),
        },
      ];

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------
  @override
  void initState() {
    super.initState();
    _bgParticles = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();

    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _glow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _glowAnim = CurvedAnimation(parent: _glow, curve: Curves.easeInOut);

    _categoryFlip = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _categoryFlipAnim = CurvedAnimation(
      parent: _categoryFlip,
      curve: Curves.easeOutBack,
    );

    _scoreBump = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scoreBumpAnim = Tween<double>(begin: 1.0, end: 1.25).chain(
      CurveTween(curve: Curves.elasticOut),
    ).animate(_scoreBump);

    _bell = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _celebrate = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _bgParticles.dispose();
    _shimmer.dispose();
    _glow.dispose();
    _categoryFlip.dispose();
    _scoreBump.dispose();
    _bell.dispose();
    _celebrate.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Game logic
  // ---------------------------------------------------------------------------
  int _baseTimeForDifficulty() {
    switch (_difficulty) {
      case 'easy':
        return 22;
      case 'hard':
        return 10;
      case 'normal':
      default:
        return 16;
    }
  }

  void _startGame() {
    HapticFeedback.heavyImpact();
    setState(() {
      _gameStarted = true;
      _currentPlayer = 1;
      _player1Score = 0;
      _player2Score = 0;
      _roundNumber = 1;
      _isThinking = true;
      _judging = false;
      _player1Streak = 0;
      _player2Streak = 0;
      _longestStreak = 0;
      _totalCompliments = 0;
      _player1ExtraTime = false;
      _player2ExtraTime = false;
      _player1Skip = false;
      _player2Skip = false;
      _usedCategories.clear();
      _baseTime = _baseTimeForDifficulty();
    });
    _pickCategory();
    _categoryFlip.forward(from: 0);
    _bell.forward(from: 0);
    _startThinkingPhase();
  }

  void _pickCategory({bool forceSkip = false}) {
    // 20% bonus round chance (skip on first round to avoid weirdness)
    final bonus = !forceSkip && _roundNumber > 1 && _random.nextInt(5) == 0;

    // Cycle through categories without immediate repeats
    final available = _categories
        .where((c) => !_usedCategories.contains(c['key']))
        .toList();
    final pool = available.isEmpty ? _categories : available;
    final cat = pool[_random.nextInt(pool.length)];
    if (available.isEmpty) {
      _usedCategories.clear();
    }
    _usedCategories.add(cat['key']);

    setState(() {
      _currentCategory = cat;
      _bonusRound = bonus;
    });
  }

  void _startThinkingPhase() {
    _timer?.cancel();
    setState(() => _isThinking = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _isThinking = false);
      _startTimer();
    });
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _timeRemaining = _baseTime);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _timeRemaining--);

      if (_timeRemaining == 5) {
        HapticFeedback.lightImpact();
      } else if (_timeRemaining <= 3 && _timeRemaining > 0) {
        HapticFeedback.selectionClick();
      }

      if (_timeRemaining <= 0) {
        _timer?.cancel();
        HapticFeedback.heavyImpact();
        _handleTimeout();
      }
    });
  }

  void _useExtraTime() {
    final used =
        _currentPlayer == 1 ? _player1ExtraTime : _player2ExtraTime;
    if (used) return;
    HapticFeedback.mediumImpact();
    setState(() {
      if (_currentPlayer == 1) {
        _player1ExtraTime = true;
      } else {
        _player2ExtraTime = true;
      }
      _timeRemaining += 5;
    });
  }

  void _useSkip() {
    final used = _currentPlayer == 1 ? _player1Skip : _player2Skip;
    if (used) return;
    HapticFeedback.mediumImpact();
    setState(() {
      if (_currentPlayer == 1) {
        _player1Skip = true;
      } else {
        _player2Skip = true;
      }
    });
    _pickCategory(forceSkip: true);
    _categoryFlip.forward(from: 0);
  }

  void _handleComplimentGiven() {
    if (_judging) return;
    HapticFeedback.mediumImpact();
    _timer?.cancel();
    setState(() => _judging = true);
  }

  void _handleTimeout() {
    setState(() {
      // Streak broken
      if (_currentPlayer == 1) {
        _player1Streak = 0;
      } else {
        _player2Streak = 0;
      }
    });
    _showRoundResult(0, timeout: true);
  }

  void _handlePass() {
    HapticFeedback.lightImpact();
    _timer?.cancel();
    setState(() {
      if (_currentPlayer == 1) {
        _player1Streak = 0;
      } else {
        _player2Streak = 0;
      }
    });
    _showRoundResult(0, passed: true);
  }

  /// Partner's judgement: 2 = great (👍), 1 = ok (👌), 0 = weak (👎)
  void _judgeCompliment(int judgment) {
    HapticFeedback.heavyImpact();

    // base points by judgment
    int points = 0;
    if (judgment == 2) {
      points = 12;
    } else if (judgment == 1) {
      points = 6;
    } else {
      points = 0;
    }

    // time bonus (only if non-zero judgment)
    if (judgment > 0) {
      points += (_timeRemaining / 4).ceil();
      _totalCompliments++;
    }

    // streak handling
    final currentStreak =
        _currentPlayer == 1 ? _player1Streak : _player2Streak;
    int newStreak;
    int displayPoints = points;
    if (judgment > 0) {
      newStreak = currentStreak + 1;
      // streak multiplier: 3+ streak → 1.5x, 5+ → 2x
      double multiplier = 1.0;
      if (newStreak >= 5) {
        multiplier = 2.0;
      } else if (newStreak >= 3) {
        multiplier = 1.5;
      }
      displayPoints = (points * multiplier).round();
    } else {
      newStreak = 0;
    }

    // bonus round 2x
    if (_bonusRound && judgment > 0) {
      displayPoints *= 2;
    }

    setState(() {
      if (_currentPlayer == 1) {
        _player1Score += displayPoints;
        _player1Streak = newStreak;
      } else {
        _player2Score += displayPoints;
        _player2Streak = newStreak;
      }
      if (newStreak > _longestStreak) _longestStreak = newStreak;
      _judging = false;
    });
    _scoreBump.forward(from: 0);
    if (newStreak >= 3) {
      _celebrate.forward(from: 0);
    }
    _showRoundResult(displayPoints, judgment: judgment);
  }

  void _showRoundResult(int points,
      {int judgment = -1, bool timeout = false, bool passed = false}) {
    final success = points > 0;
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (context) => _RoundResultDialog(
        success: success,
        points: points,
        judgment: judgment,
        timeout: timeout,
        passed: passed,
        bonusRound: _bonusRound,
        currentPlayerStreak: _currentPlayer == 1
            ? _player1Streak
            : _player2Streak,
        player1Score: _player1Score,
        player2Score: _player2Score,
        onNext: () {
          Navigator.pop(context);
          _nextTurn();
        },
      ),
    );
  }

  void _nextTurn() {
    if (_currentPlayer == 1) {
      // Switch to player 2 with same category
      setState(() {
        _currentPlayer = 2;
        _isThinking = true;
      });
      _categoryFlip.forward(from: 0);
      _bell.forward(from: 0);
      _startThinkingPhase();
    } else {
      // Both players done
      if (_roundNumber < _totalRounds) {
        setState(() {
          _roundNumber++;
          _currentPlayer = 1;
          _isThinking = true;
        });
        _pickCategory();
        _categoryFlip.forward(from: 0);
        _bell.forward(from: 0);
        _startThinkingPhase();
      } else {
        _showFinalResults();
      }
    }
  }

  void _showFinalResults() {
    HapticFeedback.heavyImpact();
    _celebrate.forward(from: 0);
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (context) => _FinalResultsDialog(
        player1Score: _player1Score,
        player2Score: _player2Score,
        longestStreak: _longestStreak,
        totalCompliments: _totalCompliments,
        onNewGame: () {
          Navigator.pop(context);
          setState(() => _gameStarted = false);
        },
        onEnd: () {
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
    final urgencyTime = !_isThinking && !_judging && _timeRemaining <= 5;
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
                'games.compliment_battle.title'.tr(),
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
          // Background gradient — burgundy/gold arena vibe
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: urgencyTime
                    ? const [
                        Color(0xFF3D0F1A),
                        Color(0xFF5C1B1B),
                        Color(0xFF1A0532),
                      ]
                    : const [
                        Color(0xFF1A0532),
                        Color(0xFF3D1A2D),
                        Color(0xFF1A0A2E),
                        Color(0xFF120822),
                      ],
              ),
            ),
          ),
          // Sparks particles
          AnimatedBuilder(
            animation: _bgParticles,
            builder: (context, _) {
              return CustomPaint(
                size: Size.infinite,
                painter: _SparksPainter(
                  sparks: _sparks,
                  progress: _bgParticles.value,
                  urgency: urgencyTime ? 1.0 : 0.0,
                ),
              );
            },
          ),
          SafeArea(
            child: !_gameStarted ? _buildSetupView() : _buildGameView(),
          ),
          // Celebration overlay
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _celebrate,
              builder: (context, _) {
                if (_celebrate.value == 0) return const SizedBox.shrink();
                return CustomPaint(
                  size: Size.infinite,
                  painter: _ConfettiPainter(
                    confetti: _confetti,
                    progress: _celebrate.value,
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
              colors: [Color(0xFF3D1A2D), Color(0xFF1A0A2E)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🥊', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text(
                'games.compliment_battle.exit_confirm'.tr(),
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
                        Navigator.pop(context);
                        context.pop();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE53935), Color(0xFFFF8C42)],
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
          const SizedBox(height: 8),
          // Header with animated battle icon
          AnimatedBuilder(
            animation: _glowAnim,
            builder: (context, _) {
              return SizedBox(
                height: 180,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFFFFD166)
                                .withOpacity(0.35 + 0.18 * _glowAnim.value),
                            const Color(0xFFE53935).withOpacity(0.15),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 130,
                      height: 130,
                      child: CustomPaint(
                        painter: _LaurelTrophyPainter(
                          pulse: _glowAnim.value,
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
            'games.compliment_battle.title'.tr(),
            style: const TextStyle(
              fontFamily: 'PlayfairDisplay',
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 1.2,
              decoration: TextDecoration.none,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'games.compliment_battle.subtitle'.tr(),
            style: TextStyle(
              fontFamily: 'DMSans',
              fontSize: 14,
              color: Colors.white.withOpacity(0.6),
              fontStyle: FontStyle.italic,
              decoration: TextDecoration.none,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 30),

          // Difficulty
          _sectionLabel(
            icon: Icons.timer,
            color: const Color(0xFFFFD166),
            label: 'games.compliment_battle.difficulty_label'.tr(),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _difficultyCard(
                value: 'easy',
                emoji: '😊',
                label: 'games.compliment_battle.diff_easy'.tr(),
                time: '22s',
                color: const Color(0xFF6EE7B7),
              ),
              const SizedBox(width: 8),
              _difficultyCard(
                value: 'normal',
                emoji: '😏',
                label: 'games.compliment_battle.diff_normal'.tr(),
                time: '16s',
                color: const Color(0xFFFFD166),
              ),
              const SizedBox(width: 8),
              _difficultyCard(
                value: 'hard',
                emoji: '🔥',
                label: 'games.compliment_battle.diff_hard'.tr(),
                time: '10s',
                color: const Color(0xFFFF6B35),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Rounds
          _sectionLabel(
            icon: Icons.refresh,
            color: const Color(0xFFE879F9),
            label: 'games.compliment_battle.rounds_label'.tr(),
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
                                Color(0xFFD946EF),
                                Color(0xFF6B2D5B),
                              ]
                            : [
                                Colors.white.withOpacity(0.06),
                                Colors.white.withOpacity(0.02),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(16),
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
                                    const Color(0xFFE879F9).withOpacity(0.45),
                                blurRadius: 18,
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

          const SizedBox(height: 24),

          // Features card (new mechanics highlight)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFFD166).withOpacity(0.10),
                  const Color(0xFFE53935).withOpacity(0.04),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.local_fire_department,
                        color: Color(0xFFFFD166), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'games.compliment_battle.quick_rules'.tr(),
                      style: const TextStyle(
                        fontFamily: 'PlayfairDisplay',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'games.compliment_battle.quick_rules_desc'.tr(),
                  style: TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.7),
                    height: 1.4,
                    decoration: TextDecoration.none,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _featureChip('🔥',
                        'games.compliment_battle.feature_streak'.tr()),
                    _featureChip('⚖️',
                        'games.compliment_battle.feature_judge'.tr()),
                    _featureChip('💎',
                        'games.compliment_battle.feature_bonus'.tr()),
                    _featureChip('⚡',
                        'games.compliment_battle.feature_powerups'.tr()),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 26),

          // Start button — gold/red shimmer
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
                      stops: [0.0, 0.25, 0.5, 0.75, 1.0],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF6B35).withOpacity(0.5),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.sports_kabaddi,
                          color: Colors.white, size: 26),
                      const SizedBox(width: 10),
                      Text(
                        'games.compliment_battle.start_battle'.tr(),
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

          const SizedBox(height: 20),
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

  Widget _difficultyCard({
    required String value,
    required String emoji,
    required String label,
    required String time,
    required Color color,
  }) {
    final isSelected = _difficulty == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _difficulty = value);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isSelected
                  ? [color.withOpacity(0.32), color.withOpacity(0.12)]
                  : [
                      Colors.white.withOpacity(0.05),
                      Colors.white.withOpacity(0.02),
                    ],
            ),
            borderRadius: BorderRadius.circular(16),
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
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'PlayfairDisplay',
                  color: isSelected
                      ? color
                      : Colors.white.withOpacity(0.85),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  decoration: TextDecoration.none,
                ),
                textAlign: TextAlign.center,
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
  // Game view
  // ---------------------------------------------------------------------------
  Widget _buildGameView() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        children: [
          // Top bar: round + scoreboard
          _buildTopBar(),
          const SizedBox(height: 12),
          // Vs. nameplates with streaks
          _buildPlayersBar(),
          const SizedBox(height: 12),
          // Category card or judging UI
          Expanded(
            child: _judging
                ? _buildJudgingView()
                : _buildPlayingView(),
          ),
          // Bottom: action area
          if (!_judging) _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        // Round indicator
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Row(
            children: [
              const Icon(Icons.casino,
                  color: Color(0xFFFFD166), size: 16),
              const SizedBox(width: 6),
              Text(
                'game_ui.round_of'.tr(namedArgs: {
                  'current': '$_roundNumber',
                  'total': '$_totalRounds',
                }),
                style: const TextStyle(
                  fontFamily: 'DMSans',
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        // Bonus round badge
        if (_bonusRound)
          AnimatedBuilder(
            animation: _glowAnim,
            builder: (context, _) {
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD166), Color(0xFFFFB347)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD166)
                          .withOpacity(0.45 * _glowAnim.value),
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('💎',
                        style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      'games.compliment_battle.bonus_x2'.tr(),
                      style: const TextStyle(
                        fontFamily: 'DMSans',
                        color: Color(0xFF3A2200),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildPlayersBar() {
    return Row(
      children: [
        Expanded(
          child: _buildPlayerNameplate(1, _player1Score, _player1Streak,
              const Color(0xFFE879F9), '👩'),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE53935), Color(0xFFFFD166)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              'VS',
              style: TextStyle(
                fontFamily: 'PlayfairDisplay',
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ),
        Expanded(
          child: _buildPlayerNameplate(2, _player2Score, _player2Streak,
              const Color(0xFFFFD166), '👨'),
        ),
      ],
    );
  }

  Widget _buildPlayerNameplate(
      int player, int score, int streak, Color color, String avatar) {
    final isCurrent = _currentPlayer == player && !_judging;
    return AnimatedBuilder(
      animation: Listenable.merge([_shimmer, _scoreBumpAnim]),
      builder: (context, _) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            gradient: isCurrent
                ? LinearGradient(
                    colors: [
                      color.withOpacity(0.22),
                      color.withOpacity(0.06),
                      color.withOpacity(0.22),
                    ],
                    stops: [0.0, _shimmer.value, 1.0],
                  )
                : LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.05),
                      Colors.white.withOpacity(0.02),
                    ],
                  ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isCurrent ? color.withOpacity(0.6) : Colors.white.withOpacity(0.08),
              width: isCurrent ? 1.5 : 1,
            ),
            boxShadow: isCurrent
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.35),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [color, color.withOpacity(0.4)],
                  ),
                  boxShadow: [
                    BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 8),
                  ],
                ),
                child: Center(
                  child: Text(avatar,
                      style: const TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player == 1
                          ? 'game_ui.player_1'.tr()
                          : 'game_ui.player_2'.tr(),
                      style: TextStyle(
                        fontFamily: 'DMSans',
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 9,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    Transform.scale(
                      scale: (isCurrent && _scoreBump.isAnimating)
                          ? _scoreBumpAnim.value
                          : 1.0,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '$score',
                        style: TextStyle(
                          fontFamily: 'PlayfairDisplay',
                          color: color,
                          fontWeight: FontWeight.w700,
                          fontSize: 22,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Streak indicator
              if (streak > 0)
                _buildStreakBadge(streak),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStreakBadge(int streak) {
    final multiplier = streak >= 5
        ? 2.0
        : streak >= 3
            ? 1.5
            : 1.0;
    final highMult = multiplier > 1.0;
    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: highMult
                  ? const [Color(0xFFFF6B35), Color(0xFFE53935)]
                  : const [Color(0xFFFF8C42), Color(0xFFFFB347)],
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: highMult
                ? [
                    BoxShadow(
                      color: const Color(0xFFFF6B35)
                          .withOpacity(0.4 * _glowAnim.value),
                      blurRadius: 10,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🔥', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 2),
              Text(
                '$streak',
                style: const TextStyle(
                  fontFamily: 'PlayfairDisplay',
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.none,
                ),
              ),
              if (highMult) ...[
                const SizedBox(width: 3),
                Text(
                  multiplier == 2.0 ? '×2' : '×1.5',
                  style: const TextStyle(
                    fontFamily: 'DMSans',
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlayingView() {
    return AnimatedBuilder(
      animation: _categoryFlipAnim,
      builder: (context, child) {
        final v = _categoryFlipAnim.value;
        return Opacity(
          opacity: v.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - v).clamp(0.0, 1.0)),
            child: child,
          ),
        );
      },
      child: Column(
        children: [
          const SizedBox(height: 8),
          // Compliment-on label
          Text(
            'games.compliment_battle.compliment_on'.tr(),
            style: TextStyle(
              fontFamily: 'DMSans',
              fontSize: 13,
              color: Colors.white.withOpacity(0.55),
              letterSpacing: 1.2,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 10),
          // Category card (gold-edged)
          _buildCategoryCard(),
          const SizedBox(height: 18),
          // Timer / thinking indicator
          if (_isThinking)
            _buildThinkingIndicator()
          else
            _buildTimerRing(),
          const Spacer(),
          // Power-up buttons (only during play)
          if (!_isThinking) _buildPowerUps(),
        ],
      ),
    );
  }

  Widget _buildCategoryCard() {
    if (_currentCategory == null) return const SizedBox.shrink();
    final color = _currentCategory!['color'] as Color;
    final emoji = _currentCategory!['emoji'] as String;
    final key = _currentCategory!['key'] as String;
    final hint = 'games.compliment_battle.hint_$key'.tr();
    final name = 'games.compliment_battle.cat_$key'.tr();

    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (context, _) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.3),
                color.withOpacity(0.12),
              ],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: color.withOpacity(0.7), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.35 + 0.15 * _glowAnim.value),
                blurRadius: 24,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                emoji,
                style: const TextStyle(fontSize: 56),
              ),
              const SizedBox(height: 8),
              Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'PlayfairDisplay',
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 1.2,
                  decoration: TextDecoration.none,
                  shadows: [
                    Shadow(color: Color(0x66000000), blurRadius: 6),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                hint,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.7),
                  fontStyle: FontStyle.italic,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThinkingIndicator() {
    return Column(
      children: [
        SizedBox(
          width: 60,
          height: 60,
          child: AnimatedBuilder(
            animation: _bgParticles,
            builder: (context, _) {
              return CustomPaint(
                painter: _SpinnerPainter(progress: _bgParticles.value * 4),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'games.compliment_battle.get_ready'.tr(),
          style: TextStyle(
            fontFamily: 'PlayfairDisplay',
            color: Colors.white.withOpacity(0.7),
            fontSize: 15,
            fontStyle: FontStyle.italic,
            decoration: TextDecoration.none,
          ),
        ),
      ],
    );
  }

  Widget _buildTimerRing() {
    final isUrgent = _timeRemaining <= 5;
    return SizedBox(
      width: 130,
      height: 130,
      child: CustomPaint(
        painter: _CircularTimerPainter(
          progress: _timeRemaining / _baseTime,
          color: isUrgent
              ? const Color(0xFFE53935)
              : const Color(0xFFFFD166),
          pulse: isUrgent ? _glowAnim.value : 0.0,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$_timeRemaining',
                style: TextStyle(
                  fontFamily: 'PlayfairDisplay',
                  fontSize: isUrgent ? 56 : 48,
                  fontWeight: FontWeight.w700,
                  color: isUrgent
                      ? const Color(0xFFFF6B6B)
                      : Colors.white,
                  decoration: TextDecoration.none,
                  shadows: isUrgent
                      ? const [
                          Shadow(
                              color: Color(0xFFE53935), blurRadius: 18),
                        ]
                      : null,
                ),
              ),
              Text(
                'sec',
                style: TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.5),
                  letterSpacing: 1.5,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPowerUps() {
    final extraTimeUsed = _currentPlayer == 1
        ? _player1ExtraTime
        : _player2ExtraTime;
    final skipUsed = _currentPlayer == 1 ? _player1Skip : _player2Skip;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: _powerUpButton(
              emoji: '⏰',
              label: 'games.compliment_battle.power_extra_time'.tr(),
              color: const Color(0xFF7DD3FC),
              used: extraTimeUsed,
              onTap: extraTimeUsed ? null : _useExtraTime,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _powerUpButton(
              emoji: '🔄',
              label: 'games.compliment_battle.power_skip'.tr(),
              color: const Color(0xFFB388FF),
              used: skipUsed,
              onTap: skipUsed ? null : _useSkip,
            ),
          ),
        ],
      ),
    );
  }

  Widget _powerUpButton({
    required String emoji,
    required String label,
    required Color color,
    required bool used,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: used
              ? Colors.white.withOpacity(0.04)
              : color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: used
                ? Colors.white.withOpacity(0.08)
                : color.withOpacity(0.5),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              emoji,
              style: TextStyle(
                fontSize: 16,
                color: used ? Colors.white.withOpacity(0.3) : null,
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                used
                    ? 'games.compliment_battle.power_used'.tr()
                    : label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: used
                      ? Colors.white.withOpacity(0.35)
                      : color,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJudgingView() {
    final otherPlayer = _currentPlayer == 1 ? 2 : 1;
    final otherColor = _currentPlayer == 1
        ? const Color(0xFFFFD166)
        : const Color(0xFFE879F9);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: otherColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: otherColor.withOpacity(0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.gavel, color: otherColor, size: 16),
                const SizedBox(width: 8),
                Text(
                  'games.compliment_battle.judge_now'
                      .tr(namedArgs: {'player': '$otherPlayer'}),
                  style: TextStyle(
                    fontFamily: 'PlayfairDisplay',
                    color: otherColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'games.compliment_battle.judge_prompt'.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'PlayfairDisplay',
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'games.compliment_battle.judge_hint'.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'DMSans',
              color: Colors.white.withOpacity(0.55),
              fontSize: 13,
              fontStyle: FontStyle.italic,
              decoration: TextDecoration.none,
            ),
          ),
          const Spacer(),
          // Big judgment buttons
          _judgeButton(
            judgment: 2,
            emoji: '💎',
            label: 'games.compliment_battle.judge_great'.tr(),
            description: 'games.compliment_battle.judge_great_desc'.tr(),
            gradient: const [Color(0xFFFFD166), Color(0xFFFFB347)],
            shadowColor: const Color(0xFFFFD166),
          ),
          const SizedBox(height: 10),
          _judgeButton(
            judgment: 1,
            emoji: '👌',
            label: 'games.compliment_battle.judge_ok'.tr(),
            description: 'games.compliment_battle.judge_ok_desc'.tr(),
            gradient: const [Color(0xFFB388FF), Color(0xFF6B2D5B)],
            shadowColor: const Color(0xFFB388FF),
          ),
          const SizedBox(height: 10),
          _judgeButton(
            judgment: 0,
            emoji: '👎',
            label: 'games.compliment_battle.judge_weak'.tr(),
            description: 'games.compliment_battle.judge_weak_desc'.tr(),
            gradient: const [Color(0xFFE53935), Color(0xFF7A1A1A)],
            shadowColor: const Color(0xFFE53935),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _judgeButton({
    required int judgment,
    required String emoji,
    required String label,
    required String description,
    required List<Color> gradient,
    required Color shadowColor,
  }) {
    return GestureDetector(
      onTap: () => _judgeCompliment(judgment),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: shadowColor.withOpacity(0.4),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 36)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'PlayfairDisplay',
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontFamily: 'DMSans',
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 12,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.7)),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    if (_isThinking) return const SizedBox(height: 64);
    return Column(
      children: [
        // Compliment fatto button — gold shimmer
        AnimatedBuilder(
          animation: _shimmer,
          builder: (context, _) {
            return GestureDetector(
              onTap: _handleComplimentGiven,
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
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle,
                        color: Color(0xFF3A2200), size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'games.compliment_battle.compliment_done'.tr(),
                      style: const TextStyle(
                        fontFamily: 'PlayfairDisplay',
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF3A2200),
                        letterSpacing: 1,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 6),
        TextButton.icon(
          onPressed: _handlePass,
          icon: Icon(Icons.skip_next,
              color: Colors.white.withOpacity(0.4), size: 16),
          label: Text(
            'games.compliment_battle.pass'.tr(),
            style: TextStyle(
              fontFamily: 'DMSans',
              color: Colors.white.withOpacity(0.4),
              fontSize: 13,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ],
    );
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
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF3D1A2D), Color(0xFF1A0A2E)],
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
                'games.compliment_battle.how_to_play'.tr(),
                style: const TextStyle(
                  fontFamily: 'PlayfairDisplay',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 16),
              _ruleRow('1', 'games.compliment_battle.rule1'.tr()),
              const SizedBox(height: 8),
              _ruleRow('2', 'games.compliment_battle.rule2'.tr()),
              const SizedBox(height: 8),
              _ruleRow('3', 'games.compliment_battle.rule3'.tr()),
              const SizedBox(height: 8),
              _ruleRow('4', 'games.compliment_battle.rule4'.tr()),
              const SizedBox(height: 8),
              _ruleRow('5', 'games.compliment_battle.rule5'.tr()),
              const SizedBox(height: 16),
              Text(
                'games.compliment_battle.be_creative'.tr(),
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
              colors: [Color(0xFFE53935), Color(0xFFFF8C42)],
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
// Round result dialog
// =============================================================================
class _RoundResultDialog extends StatelessWidget {
  final bool success;
  final int points;
  final int judgment;
  final bool timeout;
  final bool passed;
  final bool bonusRound;
  final int currentPlayerStreak;
  final int player1Score;
  final int player2Score;
  final VoidCallback onNext;

  const _RoundResultDialog({
    required this.success,
    required this.points,
    required this.judgment,
    required this.timeout,
    required this.passed,
    required this.bonusRound,
    required this.currentPlayerStreak,
    required this.player1Score,
    required this.player2Score,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final color = success
        ? (judgment == 2
            ? const Color(0xFFFFD166)
            : const Color(0xFFB388FF))
        : const Color(0xFFE53935);
    final emoji = timeout
        ? '⏰'
        : passed
            ? '🤐'
            : judgment == 2
                ? '💎'
                : judgment == 1
                    ? '👌'
                    : '👎';
    final title = timeout
        ? 'games.compliment_battle.time_up'.tr()
        : success
            ? (judgment == 2
                ? 'games.compliment_battle.judge_great'.tr()
                : 'games.compliment_battle.judge_ok'.tr())
            : 'games.compliment_battle.no_points'.tr();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3D1A2D), Color(0xFF1A0A2E)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.45), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.35),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'PlayfairDisplay',
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: color,
                decoration: TextDecoration.none,
              ),
            ),
            if (success) ...[
              const SizedBox(height: 8),
              Text(
                '+$points',
                style: const TextStyle(
                  fontFamily: 'PlayfairDisplay',
                  fontSize: 44,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFFFD166),
                  decoration: TextDecoration.none,
                ),
              ),
              if (currentPlayerStreak >= 3 || bonusRound) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  alignment: WrapAlignment.center,
                  children: [
                    if (currentPlayerStreak >= 3)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF6B35), Color(0xFFE53935)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '🔥 ×$currentPlayerStreak ${currentPlayerStreak >= 5 ? "×2" : "×1.5"}',
                          style: const TextStyle(
                            fontFamily: 'DMSans',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    if (bonusRound)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFD166), Color(0xFFFFB347)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '💎 BONUS ×2',
                          style: TextStyle(
                            fontFamily: 'DMSans',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF3A2200),
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Text(
                'games.compliment_battle.made_partner_special'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.7),
                  fontStyle: FontStyle.italic,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.25),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _scoreCol('game_ui.player_1'.tr(), player1Score,
                      const Color(0xFFE879F9)),
                  const Text('VS',
                      style: TextStyle(
                        fontFamily: 'PlayfairDisplay',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFFFD166),
                        decoration: TextDecoration.none,
                      )),
                  _scoreCol('game_ui.player_2'.tr(), player2Score,
                      const Color(0xFFFFD166)),
                ],
              ),
            ),
            const SizedBox(height: 18),
            GestureDetector(
              onTap: onNext,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE53935), Color(0xFFFF8C42)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE53935).withOpacity(0.45),
                      blurRadius: 16,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'games.compliment_battle.continue'.tr(),
                    style: const TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
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

  Widget _scoreCol(String label, int score, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'DMSans',
            fontSize: 10,
            color: Colors.white.withOpacity(0.55),
            decoration: TextDecoration.none,
          ),
        ),
        Text(
          '$score',
          style: TextStyle(
            fontFamily: 'PlayfairDisplay',
            fontSize: 24,
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
// Final results dialog
// =============================================================================
class _FinalResultsDialog extends StatelessWidget {
  final int player1Score;
  final int player2Score;
  final int longestStreak;
  final int totalCompliments;
  final VoidCallback onNewGame;
  final VoidCallback onEnd;

  const _FinalResultsDialog({
    required this.player1Score,
    required this.player2Score,
    required this.longestStreak,
    required this.totalCompliments,
    required this.onNewGame,
    required this.onEnd,
  });

  @override
  Widget build(BuildContext context) {
    final isDraw = player1Score == player2Score;
    final winnerLabel = isDraw
        ? 'games.compliment_battle.tie'.tr()
        : 'games.compliment_battle.winner'.tr(args: [
            player1Score > player2Score
                ? 'game_ui.player_1'.tr()
                : 'game_ui.player_2'.tr(),
          ]);

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
              Color(0xFF3D1A2D),
              Color(0xFF1A0A2E),
              Color(0xFF120822),
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
              'games.compliment_battle.battle_over'.tr(),
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
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'PlayfairDisplay',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _bigScore('game_ui.player_1'.tr(), player1Score,
                      const Color(0xFFE879F9)),
                  Container(
                    width: 1,
                    height: 60,
                    color: Colors.white.withOpacity(0.15),
                  ),
                  _bigScore('game_ui.player_2'.tr(), player2Score,
                      const Color(0xFFFFD166)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // Stats row
            Row(
              children: [
                Expanded(
                  child: _statBox(
                    icon: '🔥',
                    label: 'games.compliment_battle.longest_streak'.tr(),
                    value: '$longestStreak',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _statBox(
                    icon: '💬',
                    label: 'games.compliment_battle.total_compliments'.tr(),
                    value: '$totalCompliments',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              isDraw
                  ? 'games.compliment_battle.both_champions'.tr()
                  : 'games.compliment_battle.winner_reward'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'DMSans',
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: Color(0xFFFFD166),
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 22),
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
                        border: Border.all(
                            color: Colors.white.withOpacity(0.18)),
                      ),
                      child: Center(
                        child: Text(
                          'games.compliment_battle.end'.tr(),
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
                            color:
                                const Color(0xFFFFD166).withOpacity(0.45),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'games.compliment_battle.new_game'.tr(),
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

  Widget _bigScore(String label, int score, Color color) {
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

  Widget _statBox({
    required String icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
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
              fontSize: 18,
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.none,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'DMSans',
              color: Colors.white.withOpacity(0.5),
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

/// Trophy with laurel leaves for the setup header.
class _LaurelTrophyPainter extends CustomPainter {
  final double pulse;

  _LaurelTrophyPainter({required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);

    // Halo
    final halo = Paint()
      ..shader = ui.Gradient.radial(
        center,
        w * 0.55,
        [
          const Color(0xFFFFD166).withOpacity(0.5 * pulse),
          Colors.transparent,
        ],
      );
    canvas.drawCircle(center, w * 0.55, halo);

    // Trophy cup body
    final cupRect = Rect.fromCenter(
      center: Offset(w / 2, h * 0.42),
      width: w * 0.55,
      height: h * 0.5,
    );
    final cupPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(cupRect.left, cupRect.top),
        Offset(cupRect.right, cupRect.bottom),
        const [
          Color(0xFFFFF1B0),
          Color(0xFFFFD166),
          Color(0xFFB8860B),
        ],
        [0.0, 0.5, 1.0],
      );
    final cupPath = Path()
      ..moveTo(cupRect.left, cupRect.top)
      ..quadraticBezierTo(cupRect.left, cupRect.bottom * 0.75,
          cupRect.left + cupRect.width * 0.2, cupRect.bottom)
      ..lineTo(cupRect.right - cupRect.width * 0.2, cupRect.bottom)
      ..quadraticBezierTo(cupRect.right, cupRect.bottom * 0.75,
          cupRect.right, cupRect.top)
      ..close();
    canvas.drawPath(cupPath, cupPaint);

    // Cup handles
    final handlePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.04
      ..color = const Color(0xFFB8860B);
    canvas.drawArc(
      Rect.fromCircle(
          center: Offset(cupRect.left, cupRect.top + cupRect.height * 0.25),
          radius: w * 0.1),
      pi / 2,
      pi,
      false,
      handlePaint,
    );
    canvas.drawArc(
      Rect.fromCircle(
          center: Offset(cupRect.right, cupRect.top + cupRect.height * 0.25),
          radius: w * 0.1),
      -pi / 2,
      pi,
      false,
      handlePaint,
    );

    // Cup base
    final basePaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, h * 0.7),
        Offset(0, h * 0.95),
        const [Color(0xFFB8860B), Color(0xFF6B4500)],
      );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(w / 2, h * 0.78),
            width: w * 0.3,
            height: h * 0.08),
        const Radius.circular(2),
      ),
      basePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(w / 2, h * 0.88),
            width: w * 0.5,
            height: h * 0.1),
        const Radius.circular(4),
      ),
      basePaint,
    );

    // Heart inside trophy
    final heartCenter = Offset(w / 2, h * 0.4);
    final heartPaint = Paint()
      ..color = const Color(0xFFE53935);
    final hr = w * 0.12;
    final heart = Path()
      ..moveTo(heartCenter.dx, heartCenter.dy + hr * 0.9)
      ..cubicTo(
          heartCenter.dx - hr * 1.6,
          heartCenter.dy + hr * 0.1,
          heartCenter.dx - hr * 1.0,
          heartCenter.dy - hr * 1.1,
          heartCenter.dx,
          heartCenter.dy - hr * 0.3)
      ..cubicTo(
          heartCenter.dx + hr * 1.0,
          heartCenter.dy - hr * 1.1,
          heartCenter.dx + hr * 1.6,
          heartCenter.dy + hr * 0.1,
          heartCenter.dx,
          heartCenter.dy + hr * 0.9)
      ..close();
    canvas.drawPath(heart, heartPaint);

    // Sparkle highlight
    final shine = Paint()..color = Colors.white.withOpacity(0.45);
    canvas.drawCircle(
        Offset(cupRect.left + cupRect.width * 0.25,
            cupRect.top + cupRect.height * 0.18),
        w * 0.02,
        shine);
  }

  @override
  bool shouldRepaint(covariant _LaurelTrophyPainter old) =>
      old.pulse != pulse;
}

/// Circular timer ring with glow.
class _CircularTimerPainter extends CustomPainter {
  final double progress; // 1..0
  final Color color;
  final double pulse;

  _CircularTimerPainter({
    required this.progress,
    required this.color,
    this.pulse = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    // Halo
    if (pulse > 0) {
      final halo = Paint()
        ..shader = ui.Gradient.radial(
          center,
          radius * 1.4,
          [
            color.withOpacity(0.5 * pulse),
            Colors.transparent,
          ],
        );
      canvas.drawCircle(center, radius * 1.4, halo);
    }

    // Background ring
    final bg = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bg);

    // Progress arc
    final glow = Paint()
      ..color = color.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 11
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    final fg = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;

    final sweep = 2 * pi * progress.clamp(0.0, 1.0);
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, -pi / 2, sweep, false, glow);
    canvas.drawArc(rect, -pi / 2, sweep, false, fg);

    // Tick marks every 12 segments
    final tickPaint = Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..strokeWidth = 1;
    for (int i = 0; i < 12; i++) {
      final a = (i / 12) * 2 * pi;
      final p1 =
          center + Offset(cos(a) * (radius - 14), sin(a) * (radius - 14));
      final p2 = center +
          Offset(cos(a) * (radius - 18), sin(a) * (radius - 18));
      canvas.drawLine(p1, p2, tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CircularTimerPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.pulse != pulse;
}

/// Spinner for thinking phase
class _SpinnerPainter extends CustomPainter {
  final double progress;
  _SpinnerPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..shader = ui.Gradient.sweep(
        center,
        const [
          Color(0xFFFFD166),
          Color(0xFFE53935),
          Color(0xFFFFD166),
        ],
        const [0.0, 0.5, 1.0],
        TileMode.clamp,
        progress * 2 * pi,
        progress * 2 * pi + 2 * pi,
      );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      progress * 2 * pi,
      pi * 1.4,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _SpinnerPainter old) =>
      old.progress != progress;
}

/// Sparks/embers floating background — speeds up under urgency.
class _SparksPainter extends CustomPainter {
  final List<_Spark> sparks;
  final double progress;
  final double urgency; // 0..1

  _SparksPainter({
    required this.sparks,
    required this.progress,
    required this.urgency,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final speed = 1.0 + 1.5 * urgency;
    final paint = Paint();
    for (final s in sparks) {
      final phase = (s.phase + progress * s.speed * speed) % 1.0;
      final x = s.x * size.width +
          sin(phase * 2 * pi + s.phase * 4) * 22;
      final y = (1 - phase) * size.height; // rises bottom→top
      final opacity =
          (0.2 + 0.4 * (1 - (phase - 0.5).abs() * 2)).clamp(0.0, 0.55);

      final color = s.colorIdx == 0
          ? const Color(0xFFFFD166)
          : s.colorIdx == 1
              ? const Color(0xFFFF6B35)
              : const Color(0xFFE53935);
      paint.color = color.withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), s.size, paint);
      paint.color = color.withOpacity(opacity * 0.3);
      canvas.drawCircle(Offset(x, y), s.size * 1.8, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparksPainter old) =>
      old.progress != progress || old.urgency != urgency;
}

class _Spark {
  final double x;
  final double size;
  final double speed;
  final double phase;
  final int colorIdx;

  _Spark(Random r)
      : x = r.nextDouble(),
        size = 1.2 + r.nextDouble() * 2.5,
        speed = 0.25 + r.nextDouble() * 0.6,
        phase = r.nextDouble(),
        colorIdx = r.nextInt(3);
}

/// Confetti for celebration overlay
class _ConfettiPainter extends CustomPainter {
  final List<_Confetto> confetti;
  final double progress;

  _ConfettiPainter({required this.confetti, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final colors = [
      const Color(0xFFFFD166),
      const Color(0xFFFF6B35),
      const Color(0xFFE879F9),
      const Color(0xFFFFFFFF),
      const Color(0xFFFFB347),
      const Color(0xFFE53935),
    ];
    for (final c in confetti) {
      final opacity = (1 - progress).clamp(0.0, 1.0);
      if (opacity <= 0) continue;
      final yOffset = -260 * progress + 700 * progress * progress;
      final xOffset = c.x * 240 * progress;
      final pos = Offset(
        size.width / 2 + xOffset,
        size.height / 2 + yOffset,
      );
      final paint = Paint()
        ..color = colors[c.colorIdx % colors.length].withOpacity(opacity);

      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(c.rotation + progress * 8);
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
        size = 5 + r.nextDouble() * 8,
        rotation = r.nextDouble() * 2 * pi,
        colorIdx = r.nextInt(6);
}
