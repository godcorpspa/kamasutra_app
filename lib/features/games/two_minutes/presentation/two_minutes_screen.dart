import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/game_scaffold.dart';

class TwoMinutesScreen extends StatefulWidget {
  const TwoMinutesScreen({super.key});

  @override
  State<TwoMinutesScreen> createState() => _TwoMinutesScreenState();
}

class _TwoMinutesScreenState extends State<TwoMinutesScreen>
    with TickerProviderStateMixin {
  // ---------------------------------------------------------------------------
  // Game state
  // ---------------------------------------------------------------------------
  bool _gameStarted = false;
  bool _challengeActive = false;
  bool _isPaused = false;
  bool _halfwayShown = false;

  String _selectedIntensity = 'spicy';
  int _selectedDuration = 120;
  int _challengeCount = 5;

  Timer? _timer;
  int _remainingSeconds = 120;
  int _currentChallengeIndex = 0;

  List<_ChallengeData> _currentChallenges = [];
  int _completedCount = 0;
  int _connectionPoints = 0;
  int _bestRating = 0;

  // ---------------------------------------------------------------------------
  // Animations
  // ---------------------------------------------------------------------------
  late final AnimationController _bgEmbers;
  late final AnimationController _glow;
  late final AnimationController _shimmer;
  late final AnimationController _breathe;
  late final AnimationController _cardEntry;
  late final AnimationController _celebrate;

  late Animation<double> _glowAnim;
  late Animation<double> _breatheAnim;
  late Animation<double> _cardEntryAnim;

  final List<_Ember> _embers =
      List.generate(50, (i) => _Ember(Random(i * 13 + 7)));
  final List<_Confetto> _confetti =
      List.generate(60, (i) => _Confetto(Random(i * 19 + 3)));

  final Random _random = Random();

  // ---------------------------------------------------------------------------
  // Challenge pools
  // ---------------------------------------------------------------------------
  Map<String, List<_ChallengeData>> get _challengePools => {
        'soft': const [
          _ChallengeData(
            id: 'deep_gaze',
            icon: Icons.visibility,
            color: Color(0xFFFF8FB1),
            isBreathing: false,
          ),
          _ChallengeData(
            id: 'hand_massage',
            icon: Icons.pan_tool,
            color: Color(0xFFFFD166),
            isBreathing: false,
          ),
          _ChallengeData(
            id: 'whispers',
            icon: Icons.hearing,
            color: Color(0xFFB388FF),
            isBreathing: false,
          ),
          _ChallengeData(
            id: 'sync_breathing',
            icon: Icons.air,
            color: Color(0xFF7DD3FC),
            isBreathing: true,
          ),
          _ChallengeData(
            id: 'light_caresses',
            icon: Icons.face,
            color: Color(0xFFFFB6C1),
            isBreathing: false,
          ),
        ],
        'spicy': const [
          _ChallengeData(
            id: 'exploring_kisses',
            icon: Icons.favorite,
            color: Color(0xFFE53935),
            isBreathing: false,
          ),
          _ChallengeData(
            id: 'neck_massage',
            icon: Icons.spa,
            color: Color(0xFFFFD166),
            isBreathing: false,
          ),
          _ChallengeData(
            id: 'total_hug',
            icon: Icons.people,
            color: Color(0xFFFF8FB1),
            isBreathing: true,
          ),
          _ChallengeData(
            id: 'slow_dance',
            icon: Icons.music_note,
            color: Color(0xFFE879F9),
            isBreathing: false,
          ),
          _ChallengeData(
            id: 'blind_touch',
            icon: Icons.touch_app,
            color: Color(0xFFFF6B35),
            isBreathing: false,
          ),
        ],
        'extra_spicy': const [
          _ChallengeData(
            id: 'sensitive_spots',
            icon: Icons.whatshot,
            color: Color(0xFFFF6B35),
            isBreathing: false,
          ),
          _ChallengeData(
            id: 'back_massage',
            icon: Icons.self_improvement,
            color: Color(0xFFFFD166),
            isBreathing: false,
          ),
          _ChallengeData(
            id: 'kisses_everywhere',
            icon: Icons.local_fire_department,
            color: Color(0xFFE53935),
            isBreathing: false,
          ),
          _ChallengeData(
            id: 'tactile_exploration',
            icon: Icons.explore,
            color: Color(0xFFB388FF),
            isBreathing: false,
          ),
          _ChallengeData(
            id: 'total_connection',
            icon: Icons.bolt,
            color: Color(0xFFD946EF),
            isBreathing: true,
          ),
        ],
      };

  String _challengeTitleKey(String intensity, String id) =>
      'games.two_minutes.$intensity.${id}_title';
  String _challengeDescKey(String intensity, String id) =>
      'games.two_minutes.$intensity.${id}_desc';

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------
  @override
  void initState() {
    super.initState();
    _bgEmbers = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();

    _glow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _glowAnim = CurvedAnimation(parent: _glow, curve: Curves.easeInOut);

    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    // 4-4 breathing rhythm: 4s in, 4s out
    _breathe = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _breatheAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.7, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.7)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
    ]).animate(_breathe);

    _cardEntry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _cardEntryAnim =
        CurvedAnimation(parent: _cardEntry, curve: Curves.easeOutCubic);

    _celebrate = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _bgEmbers.dispose();
    _glow.dispose();
    _shimmer.dispose();
    _breathe.dispose();
    _cardEntry.dispose();
    _celebrate.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Game logic
  // ---------------------------------------------------------------------------
  void _startGame({bool resetStats = true}) {
    HapticFeedback.heavyImpact();
    final pool = List<_ChallengeData>.from(_challengePools[_selectedIntensity]!)
      ..shuffle(_random);
    // If user wants more challenges than pool, repeat pool until enough.
    final selected = <_ChallengeData>[];
    while (selected.length < _challengeCount) {
      selected.addAll(pool);
    }
    setState(() {
      _gameStarted = true;
      _challengeActive = false;
      _isPaused = false;
      _halfwayShown = false;
      _currentChallengeIndex = 0;
      _currentChallenges = selected.take(_challengeCount).toList();
      if (resetStats) {
        _completedCount = 0;
        _connectionPoints = 0;
        _bestRating = 0;
      }
    });
    _cardEntry.forward(from: 0);
  }

  void _surprisePick() {
    HapticFeedback.mediumImpact();
    final pool = _challengePools[_selectedIntensity]!;
    final shuffled = List<_ChallengeData>.from(pool)..shuffle(_random);
    setState(() {
      // Replace the current challenge with a fresh random pick (different if possible)
      final current = _currentChallenges[_currentChallengeIndex].id;
      final pick = shuffled
          .firstWhere((c) => c.id != current, orElse: () => shuffled.first);
      _currentChallenges[_currentChallengeIndex] = pick;
    });
    _cardEntry.forward(from: 0);
  }

  void _startChallenge() {
    HapticFeedback.heavyImpact();
    setState(() {
      _challengeActive = true;
      _remainingSeconds = _selectedDuration;
      _isPaused = false;
      _halfwayShown = false;
    });
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_isPaused) return;
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
          // halfway notification (only once per challenge, and only for >= 60s)
          if (!_halfwayShown &&
              _selectedDuration >= 60 &&
              _remainingSeconds == _selectedDuration ~/ 2) {
            _halfwayShown = true;
            HapticFeedback.mediumImpact();
            _showHalfway();
          }
          if (_remainingSeconds == 5) {
            HapticFeedback.lightImpact();
          }
          if (_remainingSeconds <= 3 && _remainingSeconds > 0) {
            HapticFeedback.selectionClick();
          }
        } else {
          _timer?.cancel();
          HapticFeedback.heavyImpact();
          _onChallengeComplete(timeUp: true);
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
        backgroundColor: const Color(0xFFFFD166),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            const Text('⏳ ', style: TextStyle(fontSize: 18)),
            Expanded(
              child: Text(
                'games.two_minutes.halfway_message'.tr(),
                style: const TextStyle(
                  fontFamily: 'DMSans',
                  color: Color(0xFF3A2200),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _togglePause() {
    HapticFeedback.lightImpact();
    setState(() => _isPaused = !_isPaused);
  }

  void _onChallengeComplete({bool timeUp = false}) {
    _timer?.cancel();
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
    setState(() {
      _completedCount++;
      _connectionPoints += rating * 10;
      if (rating > _bestRating) _bestRating = rating;
    });
    if (rating >= 3) {
      _celebrate.forward(from: 0);
    }
    _nextChallenge();
  }

  void _nextChallenge() {
    if (_currentChallengeIndex < _currentChallenges.length - 1) {
      setState(() {
        _currentChallengeIndex++;
        _challengeActive = false;
        _isPaused = false;
        _halfwayShown = false;
      });
      _cardEntry.forward(from: 0);
    } else {
      _showSessionResults();
    }
  }

  void _skipChallenge() {
    HapticFeedback.lightImpact();
    _timer?.cancel();
    setState(() {
      _challengeActive = false;
    });
    if (_currentChallengeIndex < _currentChallenges.length - 1) {
      setState(() {
        _currentChallengeIndex++;
      });
      _cardEntry.forward(from: 0);
    } else {
      _showSessionResults();
    }
  }

  void _showSessionResults() {
    HapticFeedback.heavyImpact();
    _celebrate.forward(from: 0);
    final maxPoints = 30 * _currentChallenges.length;
    final ratio = maxPoints == 0
        ? 0.0
        : (_connectionPoints / maxPoints).clamp(0.0, 1.0);
    final messageKey = ratio > 0.7
        ? 'games.two_minutes.connection_msg_high'
        : ratio > 0.4
            ? 'games.two_minutes.connection_msg_mid'
            : 'games.two_minutes.connection_msg_low';
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (context) => _SessionResultsDialog(
        completed: _completedCount,
        total: _currentChallenges.length,
        connectionPoints: _connectionPoints,
        ratio: ratio,
        connectionMessage: messageKey.tr(),
        onPlayAgain: () {
          Navigator.pop(context);
          _startGame();
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
  String _formatTime(int s) {
    final m = s ~/ 60;
    final r = s % 60;
    return '${m.toString().padLeft(2, '0')}:${r.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isUrgent = _challengeActive && _remainingSeconds <= 5 && !_isPaused;
    return GameScaffold(
      onBack: () {
        if (_gameStarted) {
          _confirmExit();
        } else {
          context.pop();
        }
      },
      title: !_gameStarted
          ? Text(
              'games.two_minutes.title'.tr(),
              style: const TextStyle(
                fontFamily: 'PlayfairDisplay',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                decoration: TextDecoration.none,
              ),
            )
          : null,
      onHelp: _showRules,
      background: [
        // Warm sunset/candlelight gradient background
        AnimatedContainer(
          duration: const Duration(milliseconds: 600),
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
                      Color(0xFF2A0E2C),
                      Color(0xFF3D1A2D),
                      Color(0xFF4A1D40),
                      Color(0xFF1A0A2E),
                    ],
            ),
          ),
        ),
        // Drifting embers
        AnimatedBuilder(
          animation: _bgEmbers,
          builder: (context, _) {
            return CustomPaint(
              size: Size.infinite,
              painter: _EmbersPainter(
                embers: _embers,
                progress: _bgEmbers.value,
                intensity: _gameStarted ? 1.0 : 0.7,
              ),
            );
          },
        ),
      ],
      overlays: [
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
      body: !_gameStarted
          ? _buildSetupView()
          : _challengeActive
              ? _buildChallengeView()
              : _buildPreChallengeView(),
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
              const Text('⏳', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text(
                'games.two_minutes.exit_confirm'.tr(),
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
      padding: const EdgeInsets.fromLTRB(24, kToolbarHeight, 24, 24),
      child: Column(
        children: [
          const SizedBox(height: 6),
          // Header — candle + glow
          AnimatedBuilder(
            animation: Listenable.merge([_glowAnim, _breatheAnim]),
            builder: (context, _) {
              return SizedBox(
                height: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFFFF8C42).withOpacity(
                                0.32 + 0.18 * _glowAnim.value),
                            const Color(0xFFFFD166).withOpacity(0.15),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 130,
                      height: 130,
                      child: CustomPaint(
                        painter: _CandlePainter(
                          flicker: _glowAnim.value,
                          flameScale: _breatheAnim.value,
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
            'games.two_minutes.title'.tr(),
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
            'games.two_minutes.subtitle'.tr(),
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

          // Intensity
          _sectionLabel(
            icon: Icons.local_fire_department,
            color: const Color(0xFFFF6B35),
            label: 'games.two_minutes.intensity'.tr(),
          ),
          const SizedBox(height: 14),
          _intensityCard('soft', '🌸',
              'games.two_minutes.intensity_soft'.tr(),
              'games.two_minutes.intensity_soft_desc'.tr(),
              const Color(0xFFFF8FB1)),
          const SizedBox(height: 8),
          _intensityCard('spicy', '🌶️',
              'games.two_minutes.intensity_spicy'.tr(),
              'games.two_minutes.intensity_spicy_desc'.tr(),
              const Color(0xFFFF6B35)),
          const SizedBox(height: 8),
          _intensityCard(
              'extra_spicy',
              '🔥',
              'games.two_minutes.intensity_extra_spicy'.tr(),
              'games.two_minutes.intensity_extra_spicy_desc'.tr(),
              const Color(0xFFE53935)),

          const SizedBox(height: 22),

          // Duration
          _sectionLabel(
            icon: Icons.timer,
            color: const Color(0xFFFFD166),
            label: 'games.two_minutes.challenge_duration'.tr(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _durationChip(60, 'games.two_minutes.dur_1min'.tr()),
              const SizedBox(width: 8),
              _durationChip(120, 'games.two_minutes.dur_2min'.tr()),
              const SizedBox(width: 8),
              _durationChip(180, 'games.two_minutes.dur_3min'.tr()),
              const SizedBox(width: 8),
              _durationChip(300, 'games.two_minutes.dur_5min'.tr()),
            ],
          ),

          const SizedBox(height: 22),

          // Number of challenges
          _sectionLabel(
            icon: Icons.format_list_numbered,
            color: const Color(0xFFE879F9),
            label: 'games.two_minutes.challenges_count'.tr(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [3, 5, 7].map((count) {
              final isSelected = _challengeCount == count;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _challengeCount = count);
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
                                color: const Color(0xFFE879F9)
                                    .withOpacity(0.4),
                                blurRadius: 16,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '$count',
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

          // Features card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFF8C42).withOpacity(0.10),
                  const Color(0xFFE53935).withOpacity(0.04),
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
                        color: Color(0xFFFFD166), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'games.two_minutes.features_title'.tr(),
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
                        'games.two_minutes.feature_breathing'.tr()),
                    _featureChip('💕',
                        'games.two_minutes.feature_rating'.tr()),
                    _featureChip('🎲',
                        'games.two_minutes.feature_surprise'.tr()),
                    _featureChip('⏳',
                        'games.two_minutes.feature_halfway'.tr()),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Start button — sunset shimmer
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
                      const Icon(Icons.play_circle_filled,
                          color: Colors.white, size: 26),
                      const SizedBox(width: 10),
                      Text(
                        'games.two_minutes.start_session'.tr(),
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

  Widget _intensityCard(
    String id,
    String emoji,
    String label,
    String desc,
    Color color,
  ) {
    final isSelected = _selectedIntensity == id;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedIntensity = id);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isSelected
                ? [color.withOpacity(0.32), color.withOpacity(0.10)]
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
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    color.withOpacity(0.6),
                    color.withOpacity(0.15),
                  ],
                ),
                border: Border.all(color: color.withOpacity(0.6)),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'PlayfairDisplay',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? color
                          : Colors.white.withOpacity(0.85),
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.55),
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: color, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _durationChip(int seconds, String label) {
    final isSelected = _selectedDuration == seconds;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedDuration = seconds);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 12),
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
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFFFD166)
                  : Colors.white.withOpacity(0.1),
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFFFFD166).withOpacity(0.4),
                      blurRadius: 14,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'DMSans',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? const Color(0xFF3A2200)
                    : Colors.white,
                decoration: TextDecoration.none,
              ),
            ),
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
  // Pre-challenge view
  // ---------------------------------------------------------------------------
  Widget _buildPreChallengeView() {
    final challenge = _currentChallenges[_currentChallengeIndex];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, kToolbarHeight, 20, 16),
      child: Column(
        children: [
          _buildProgressBar(),
          const SizedBox(height: 18),
          Expanded(
            child: Center(
              child: AnimatedBuilder(
                animation: _cardEntryAnim,
                builder: (context, child) {
                  final v = _cardEntryAnim.value;
                  return Opacity(
                    opacity: v,
                    child: Transform.translate(
                      offset: Offset(0, 24 * (1 - v)),
                      child: child,
                    ),
                  );
                },
                child: _buildPreviewCard(challenge),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Surprise + Start row
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
                          color:
                              const Color(0xFFFFD166).withOpacity(0.4),
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
                          'games.two_minutes.surprise'.tr(),
                          style: const TextStyle(
                            fontFamily: 'DMSans',
                            color: Color(0xFF3A2200),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: AnimatedBuilder(
                  animation: _shimmer,
                  builder: (context, _) {
                    return GestureDetector(
                      onTap: _startChallenge,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
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
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF6B35)
                                  .withOpacity(0.45),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.play_arrow_rounded,
                                color: Colors.white, size: 24),
                            const SizedBox(width: 6),
                            Text(
                              'games.two_minutes.start_timer'.tr(),
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
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _skipChallenge,
            icon: Icon(Icons.skip_next,
                color: Colors.white.withOpacity(0.4), size: 16),
            label: Text(
              'games.two_minutes.skip'.tr(),
              style: TextStyle(
                fontFamily: 'DMSans',
                color: Colors.white.withOpacity(0.4),
                fontSize: 13,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'games.two_minutes.challenge_short'.tr(namedArgs: {
                      'current': '${_currentChallengeIndex + 1}',
                      'total': '${_currentChallenges.length}',
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
                  if (_connectionPoints > 0) ...[
                    const Icon(Icons.favorite,
                        color: Color(0xFFFF6B6B), size: 12),
                    const SizedBox(width: 4),
                    Text(
                      '$_connectionPoints',
                      style: const TextStyle(
                        fontFamily: 'PlayfairDisplay',
                        color: Color(0xFFFF6B6B),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  minHeight: 4,
                  value: (_currentChallengeIndex + 1) /
                      _currentChallenges.length,
                  backgroundColor: Colors.white.withOpacity(0.08),
                  valueColor:
                      const AlwaysStoppedAnimation(Color(0xFFFF6B35)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewCard(_ChallengeData challenge) {
    final intensity = _selectedIntensity;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            challenge.color.withOpacity(0.32),
            challenge.color.withOpacity(0.12),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: challenge.color.withOpacity(0.55), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: challenge.color.withOpacity(0.4),
            blurRadius: 26,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          // Icon disc
          AnimatedBuilder(
            animation: _glowAnim,
            builder: (context, _) {
              return Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      challenge.color.withOpacity(
                          0.6 + 0.2 * _glowAnim.value),
                      challenge.color.withOpacity(0.15),
                    ],
                  ),
                  border:
                      Border.all(color: challenge.color, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: challenge.color
                          .withOpacity(0.5 * _glowAnim.value),
                      blurRadius: 22,
                    ),
                  ],
                ),
                child: Icon(challenge.icon,
                    color: Colors.white, size: 42),
              );
            },
          ),
          const SizedBox(height: 16),
          if (challenge.isBreathing)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF7DD3FC).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🫁', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 4),
                  Text(
                    'games.two_minutes.breathing_mode'.tr(),
                    style: const TextStyle(
                      fontFamily: 'DMSans',
                      color: Color(0xFF7DD3FC),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
          if (challenge.isBreathing) const SizedBox(height: 10),
          Text(
            _challengeTitleKey(intensity, challenge.id).tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'PlayfairDisplay',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.5,
              decoration: TextDecoration.none,
              shadows: [
                Shadow(color: Color(0x66000000), blurRadius: 6),
              ],
            ),
          ),
          const SizedBox(height: 12),
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
          const SizedBox(height: 12),
          Text(
            _challengeDescKey(intensity, challenge.id).tr(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'DMSans',
              fontSize: 14,
              height: 1.5,
              color: Colors.white.withOpacity(0.85),
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer,
                    color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(
                  _formatTime(_selectedDuration),
                  style: const TextStyle(
                    fontFamily: 'PlayfairDisplay',
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Active challenge view
  // ---------------------------------------------------------------------------
  Widget _buildChallengeView() {
    final challenge = _currentChallenges[_currentChallengeIndex];
    final progress = _selectedDuration == 0
        ? 0.0
        : (1 - (_remainingSeconds / _selectedDuration)).clamp(0.0, 1.0);
    final intensity = _selectedIntensity;
    final isUrgent = _remainingSeconds <= 5 && !_isPaused;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, kToolbarHeight, 20, 16),
      child: Column(
        children: [
          _buildProgressBar(),
          const SizedBox(height: 14),

          // Title + breathing badge
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(challenge.icon, color: challenge.color, size: 18),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _challengeTitleKey(intensity, challenge.id).tr(),
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

          const SizedBox(height: 6),

          // BIG breathing/timer ring — responsive size that fits the box
          Expanded(
            child: Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Largest square that fits the available box, capped at 280.
                  // We must NOT force a lower bound larger than the available
                  // space, otherwise the ring overflows into the description /
                  // controls on short screens (RenderFlex overflow + clipping).
                  final maxSize = min(
                    constraints.maxWidth,
                    constraints.maxHeight,
                  );
                  final ringSize = min(maxSize, 280.0);
                  final innerSize = ringSize * 0.78;
                  final progressSize = ringSize * 0.85;
                  return AnimatedBuilder(
                    animation:
                        Listenable.merge([_breatheAnim, _glowAnim]),
                    builder: (context, _) {
                      final scale = challenge.isBreathing && !_isPaused
                          ? _breatheAnim.value
                          : 1.0;
                      return SizedBox(
                        width: ringSize,
                        height: ringSize,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer halo
                            Container(
                              width: ringSize,
                              height: ringSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    (isUrgent
                                            ? const Color(0xFFE53935)
                                            : challenge.color)
                                        .withOpacity(
                                            0.32 + 0.18 * _glowAnim.value),
                                    challenge.color.withOpacity(0.1),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                            // Breathing ring (if breathing challenge)
                            Transform.scale(
                              scale: scale,
                              child: Container(
                                width: innerSize,
                                height: innerSize,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      challenge.color.withOpacity(0.25),
                                      challenge.color.withOpacity(0.06),
                                    ],
                                  ),
                                  border: Border.all(
                                    color:
                                        challenge.color.withOpacity(0.5),
                                    width: 1,
                                  ),
                                ),
                              ),
                            ),
                            // Progress ring
                            SizedBox(
                              width: progressSize,
                              height: progressSize,
                              child: CustomPaint(
                                painter: _RingProgressPainter(
                                  progress: progress,
                                  color: isUrgent
                                      ? const Color(0xFFE53935)
                                      : challenge.color,
                                  pulse:
                                      isUrgent ? _glowAnim.value : 0.0,
                                ),
                              ),
                            ),
                            // Center number
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _formatTime(_remainingSeconds),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'PlayfairDisplay',
                                    fontSize:
                                        isUrgent ? ringSize * 0.22 : ringSize * 0.2,
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
                                  _isPaused
                                      ? 'games.two_minutes.paused'.tr()
                                      : challenge.isBreathing
                                          ? _breathePhaseLabel()
                                          : 'games.two_minutes.remaining'
                                              .tr(),
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
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Description reminder
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Text(
              _challengeDescKey(intensity, challenge.id).tr(),
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

          const SizedBox(height: 14),

          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _circleButton(
                icon: Icons.skip_next,
                color: Colors.white.withOpacity(0.5),
                onTap: _skipChallenge,
                size: 50,
              ),
              const SizedBox(width: 18),
              _circleButton(
                icon: _isPaused ? Icons.play_arrow : Icons.pause,
                color: Colors.white,
                onTap: _togglePause,
                size: 70,
                gradient: const [
                  Color(0xFFE53935),
                  Color(0xFFFF8C42),
                ],
                shadow: const Color(0xFFFF6B35),
              ),
              const SizedBox(width: 18),
              _circleButton(
                icon: Icons.check,
                color: const Color(0xFF6EE7B7),
                onTap: () => _onChallengeComplete(),
                size: 50,
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  String _breathePhaseLabel() {
    // First half of cycle = inhale, second half = exhale
    final v = _breathe.value;
    return v < 0.5
        ? 'games.two_minutes.breathe_in'.tr()
        : 'games.two_minutes.breathe_out'.tr();
  }

  Widget _circleButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required double size,
    List<Color>? gradient,
    Color? shadow,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: gradient != null
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradient,
                )
              : null,
          color: gradient == null ? Colors.white.withOpacity(0.06) : null,
          border: gradient == null
              ? Border.all(color: Colors.white.withOpacity(0.15))
              : null,
          boxShadow: shadow != null
              ? [
                  BoxShadow(
                    color: shadow.withOpacity(0.5),
                    blurRadius: 18,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Icon(icon, color: color, size: size * 0.45),
      ),
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
          maxHeight: MediaQuery.of(context).size.height * 0.8,
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
                'games.two_minutes.how_to_play'.tr(),
                style: const TextStyle(
                  fontFamily: 'PlayfairDisplay',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 16),
              _ruleRow('1', 'games.two_minutes.rule_1'.tr()),
              const SizedBox(height: 8),
              _ruleRow('2', 'games.two_minutes.rule_2'.tr()),
              const SizedBox(height: 8),
              _ruleRow('3', 'games.two_minutes.rule_3'.tr()),
              const SizedBox(height: 8),
              _ruleRow('4', 'games.two_minutes.rule_4'.tr()),
              const SizedBox(height: 8),
              _ruleRow('5', 'games.two_minutes.rule_5'.tr()),
              const SizedBox(height: 18),
              Text(
                'games.two_minutes.closing'.tr(),
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
// Data
// =============================================================================
class _ChallengeData {
  final String id;
  final IconData icon;
  final Color color;
  final bool isBreathing;

  const _ChallengeData({
    required this.id,
    required this.icon,
    required this.color,
    required this.isBreathing,
  });
}

// =============================================================================
// Rating bottom sheet
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
          colors: [
            Color(0xFF3D1A2D),
            Color(0xFF1A0A2E),
          ],
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
          const Text('💞', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 6),
          Text(
            'games.two_minutes.rate_connection'.tr(),
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
            'games.two_minutes.rate_hint'.tr(),
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
            emoji: '💕',
            label: 'games.two_minutes.rate_low'.tr(),
            desc: 'games.two_minutes.rate_low_desc'.tr(),
            color: const Color(0xFFFFB6C1),
          ),
          const SizedBox(height: 10),
          _ratingOption(
            rating: 2,
            emoji: '💖',
            label: 'games.two_minutes.rate_mid'.tr(),
            desc: 'games.two_minutes.rate_mid_desc'.tr(),
            color: const Color(0xFFFF8FB1),
          ),
          const SizedBox(height: 10),
          _ratingOption(
            rating: 3,
            emoji: '🔥',
            label: 'games.two_minutes.rate_high'.tr(),
            desc: 'games.two_minutes.rate_high_desc'.tr(),
            color: const Color(0xFFFF6B35),
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
// Session results dialog
// =============================================================================
class _SessionResultsDialog extends StatelessWidget {
  final int completed;
  final int total;
  final int connectionPoints;
  final double ratio;
  final String connectionMessage;
  final VoidCallback onPlayAgain;
  final VoidCallback onExit;

  const _SessionResultsDialog({
    required this.completed,
    required this.total,
    required this.connectionPoints,
    required this.ratio,
    required this.connectionMessage,
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
              Color(0xFF3D1A2D),
              Color(0xFF2A0E2C),
              Color(0xFF1A0A2E),
            ],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: const Color(0xFFFF6B35).withOpacity(0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF6B35).withOpacity(0.5),
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
                const Text('💕', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 4),
                Text(
                  'games.two_minutes.session_complete'.tr(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'PlayfairDisplay',
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFFF6B35),
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0x33FF6B35),
                        Color(0x33E53935),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: const Color(0xFFFF6B35).withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'games.two_minutes.connection_score'.tr(),
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
                        '$connectionPoints',
                        style: const TextStyle(
                          fontFamily: 'PlayfairDisplay',
                          fontSize: 44,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          decoration: TextDecoration.none,
                          shadows: [
                            Shadow(
                                color: Color(0xFFFF6B35),
                                blurRadius: 18),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 8,
                        child: CustomPaint(
                          size: const Size(double.infinity, 8),
                          painter: _ConnectionMeterPainter(
                              ratio: ratio, glow: 1.0),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        connectionMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'DMSans',
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: Colors.white.withOpacity(0.8),
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
                        icon: '✅',
                        label: 'games.two_minutes.challenges_completed'.tr(),
                        value: '$completed/$total',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _stat(
                        icon: '⏱️',
                        label: 'games.two_minutes.session_label'.tr(),
                        value: '${total * 2}m',
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
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.18)),
                          ),
                          child: Center(
                            child: Text(
                              'games.two_minutes.exit'.tr(),
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
                        onTap: onPlayAgain,
                        child: Container(
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFE53935),
                                Color(0xFFFF8C42),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF6B35)
                                    .withOpacity(0.45),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'games.two_minutes.play_again'.tr(),
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
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
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

/// Candle with flickering flame.
class _CandlePainter extends CustomPainter {
  final double flicker;
  final double flameScale;

  _CandlePainter({required this.flicker, required this.flameScale});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Halo
    final halo = Paint()
      ..shader = ui.Gradient.radial(
        Offset(w / 2, h * 0.3),
        w * 0.5,
        [
          const Color(0xFFFF8C42).withOpacity(0.5 * flicker),
          Colors.transparent,
        ],
      );
    canvas.drawCircle(Offset(w / 2, h * 0.3), w * 0.5, halo);

    // Candle body
    final bodyRect = Rect.fromCenter(
      center: Offset(w / 2, h * 0.7),
      width: w * 0.28,
      height: h * 0.48,
    );
    final bodyPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(bodyRect.left, 0),
        Offset(bodyRect.right, 0),
        const [
          Color(0xFFFFF1B0),
          Color(0xFFFFD166),
          Color(0xFFB8860B),
        ],
      );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(4)),
      bodyPaint,
    );

    // Body shading
    final shadingPaint = Paint()
      ..color = Colors.black.withOpacity(0.18);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(bodyRect.right - 4, bodyRect.top, bodyRect.right,
            bodyRect.bottom),
        const Radius.circular(2),
      ),
      shadingPaint,
    );

    // Wick
    final wickPaint = Paint()
      ..color = const Color(0xFF3A2200)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(w / 2, h * 0.46),
      Offset(w / 2, h * 0.4),
      wickPaint,
    );

    // Flame (animated by flameScale)
    final flameCenter = Offset(w / 2, h * 0.32);
    canvas.save();
    canvas.translate(flameCenter.dx, flameCenter.dy);
    canvas.scale(1, flameScale * 1.2);
    canvas.translate(-flameCenter.dx, -flameCenter.dy);

    final flamePath = Path()
      ..moveTo(w / 2, h * 0.42)
      ..quadraticBezierTo(
          w * 0.42, h * 0.32, w / 2, h * 0.18)
      ..quadraticBezierTo(
          w * 0.58, h * 0.32, w / 2, h * 0.42);
    final flamePaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(w / 2, h * 0.42),
        Offset(w / 2, h * 0.18),
        const [
          Color(0xFFE53935),
          Color(0xFFFF8C42),
          Color(0xFFFFD166),
        ],
        [0.0, 0.5, 1.0],
      );
    canvas.drawPath(flamePath, flamePaint);

    // Inner blue flame
    final inner = Path()
      ..moveTo(w / 2, h * 0.4)
      ..quadraticBezierTo(
          w * 0.46, h * 0.34, w / 2, h * 0.26)
      ..quadraticBezierTo(
          w * 0.54, h * 0.34, w / 2, h * 0.4);
    final innerPaint = Paint()
      ..color = const Color(0xFFFFE7A0).withOpacity(0.85);
    canvas.drawPath(inner, innerPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CandlePainter old) =>
      old.flicker != flicker || old.flameScale != flameScale;
}

/// Drifting embers (rising sparks) over the dark background.
class _EmbersPainter extends CustomPainter {
  final List<_Ember> embers;
  final double progress;
  final double intensity;

  _EmbersPainter({
    required this.embers,
    required this.progress,
    required this.intensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final e in embers) {
      final phase = (e.phase + progress * e.speed) % 1.0;
      final x = e.x * size.width +
          sin(phase * 2 * pi + e.phase * 4) * 24;
      final y = (1 - phase) * size.height; // bottom→top
      final opacity =
          (0.2 + 0.4 * (1 - (phase - 0.5).abs() * 2)).clamp(0.0, 0.55) *
              intensity;
      final color = e.colorIdx == 0
          ? const Color(0xFFFFD166)
          : e.colorIdx == 1
              ? const Color(0xFFFF8C42)
              : const Color(0xFFE53935);
      paint.color = color.withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), e.size, paint);
      paint.color = color.withOpacity(opacity * 0.3);
      canvas.drawCircle(Offset(x, y), e.size * 1.8, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _EmbersPainter old) =>
      old.progress != progress || old.intensity != intensity;
}

class _Ember {
  final double x;
  final double size;
  final double speed;
  final double phase;
  final int colorIdx;

  _Ember(Random r)
      : x = r.nextDouble(),
        size = 1.2 + r.nextDouble() * 2.5,
        speed = 0.2 + r.nextDouble() * 0.5,
        phase = r.nextDouble(),
        colorIdx = r.nextInt(3);
}

/// Outer ring progress (gradient sweep + glow).
class _RingProgressPainter extends CustomPainter {
  final double progress; // 0..1 (filled)
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

    // Track
    final track = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);

    if (progress <= 0) return;

    // Glow under
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

    // Tick marks
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

/// Connection meter for the final dialog.
class _ConnectionMeterPainter extends CustomPainter {
  final double ratio;
  final double glow;

  _ConnectionMeterPainter({required this.ratio, required this.glow});

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
      final glowPaint = Paint()
        ..color = const Color(0xFFFF6B35).withOpacity(0.5 * glow)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawRRect(fillRect, glowPaint);
      final fillPaint = Paint()
        ..shader = ui.Gradient.linear(
          const Offset(0, 0),
          Offset(size.width * ratio, 0),
          const [
            Color(0xFFE53935),
            Color(0xFFFF8C42),
            Color(0xFFFFD166),
          ],
        );
      canvas.drawRRect(fillRect, fillPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConnectionMeterPainter old) =>
      old.ratio != ratio || old.glow != glow;
}

/// Confetti for celebration overlay.
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
