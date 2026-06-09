import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class QuestionQuestScreen extends StatefulWidget {
  const QuestionQuestScreen({super.key});

  @override
  State<QuestionQuestScreen> createState() => _QuestionQuestScreenState();
}

class _QuestionQuestScreenState extends State<QuestionQuestScreen>
    with TickerProviderStateMixin {
  // ---------------------------------------------------------------------------
  // Game state
  // ---------------------------------------------------------------------------
  bool _gameStarted = false;
  bool _showingQuestion = false;
  String _selectedCategory = 'all';
  String _selectedDepth = 'medium';
  bool _timerEnabled = false;
  int _currentQuestionIndex = 0;
  int _currentPlayer = 1;

  // Connection mechanics
  int _connectionPoints = 0;
  int _surpriseCount = 0;
  int _answeredCount = 0;
  int _skippedCount = 0;

  Timer? _timer;
  static const int _timerSeconds = 60;
  int _timeRemaining = _timerSeconds;

  List<String> _currentQuestions = [];
  final Set<int> _bookmarked = {};

  // ---------------------------------------------------------------------------
  // Animations
  // ---------------------------------------------------------------------------
  late final AnimationController _bgStars;
  late final AnimationController _glow;
  late final AnimationController _shimmer;
  late final AnimationController _cardFlip;
  late final AnimationController _meterBump;
  late final AnimationController _celebrate;

  late Animation<double> _glowAnim;
  late Animation<double> _cardFlipAnim;
  late Animation<double> _meterBumpAnim;

  final List<_Star> _stars = List.generate(70, (i) => _Star(Random(i * 13 + 7)));
  final List<_NebulaOrb> _nebula =
      List.generate(5, (i) => _NebulaOrb(Random(i * 31 + 5)));
  final List<_Confetto> _confetti =
      List.generate(50, (i) => _Confetto(Random(i * 19 + 3)));

  final Random _random = Random();

  // ---------------------------------------------------------------------------
  // Categories & depths
  // ---------------------------------------------------------------------------
  List<Map<String, dynamic>> get _categories => [
        {
          'id': 'all',
          'emoji': '🎯',
          'color': const Color(0xFFE879F9),
        },
        {
          'id': 'dreams',
          'emoji': '✨',
          'color': const Color(0xFFB388FF),
        },
        {
          'id': 'memories',
          'emoji': '📸',
          'color': const Color(0xFFFFD166),
        },
        {
          'id': 'desires',
          'emoji': '💫',
          'color': const Color(0xFFFF8FB1),
        },
        {
          'id': 'fears',
          'emoji': '🌙',
          'color': const Color(0xFF7DD3FC),
        },
        {
          'id': 'future',
          'emoji': '🔮',
          'color': const Color(0xFF6EE7B7),
        },
        {
          'id': 'intimacy',
          'emoji': '💕',
          'color': const Color(0xFFFF6B6B),
        },
      ];

  List<Map<String, dynamic>> get _depths => [
        {
          'id': 'light',
          'emoji': '☀️',
          'color': const Color(0xFFFFD166),
          'multiplier': 1,
        },
        {
          'id': 'medium',
          'emoji': '🌊',
          'color': const Color(0xFF7DD3FC),
          'multiplier': 2,
        },
        {
          'id': 'deep',
          'emoji': '🌌',
          'color': const Color(0xFFB388FF),
          'multiplier': 3,
        },
      ];

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------
  @override
  void initState() {
    super.initState();
    _bgStars = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
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

    _cardFlip = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _cardFlipAnim = CurvedAnimation(
      parent: _cardFlip,
      curve: Curves.easeInOutCubic,
    );

    _meterBump = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _meterBumpAnim = Tween<double>(begin: 1.0, end: 1.18).chain(
      CurveTween(curve: Curves.elasticOut),
    ).animate(_meterBump);

    _celebrate = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _bgStars.dispose();
    _glow.dispose();
    _shimmer.dispose();
    _cardFlip.dispose();
    _meterBump.dispose();
    _celebrate.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Game logic
  // ---------------------------------------------------------------------------
  Map<String, Map<String, List<String>>> _buildQuestions() => {
        for (final depth in ['light', 'medium', 'deep'])
          depth: {
            for (final cat in [
              'dreams',
              'memories',
              'desires',
              'fears',
              'future',
              'intimacy'
            ])
              cat: List.generate(
                3,
                (i) => 'games.question_quest.q_${depth}_${cat}_${i + 1}'.tr(),
              ),
          },
      };

  void _loadQuestions() {
    final pool = _buildQuestions();
    final byDepth = pool[_selectedDepth]!;
    List<String> all = [];

    if (_selectedCategory == 'all') {
      for (final c in byDepth.values) {
        all.addAll(c);
      }
    } else {
      all = List.from(byDepth[_selectedCategory] ?? const []);
    }
    all.shuffle();
    _currentQuestions = all.take(10).toList();
  }

  void _startGame() {
    HapticFeedback.heavyImpact();
    _loadQuestions();
    setState(() {
      _gameStarted = true;
      _showingQuestion = false;
      _currentQuestionIndex = 0;
      _currentPlayer = _random.nextInt(2) + 1;
      _connectionPoints = 0;
      _surpriseCount = 0;
      _answeredCount = 0;
      _skippedCount = 0;
      _bookmarked.clear();
      _timeRemaining = _timerSeconds;
    });
  }

  int get _depthMultiplier {
    final d =
        _depths.firstWhere((dp) => dp['id'] == _selectedDepth);
    return d['multiplier'] as int;
  }

  void _revealQuestion() {
    HapticFeedback.mediumImpact();
    setState(() => _showingQuestion = true);
    _cardFlip.forward(from: 0);
    if (_timerEnabled) {
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _timeRemaining = _timerSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _timeRemaining--);
      if (_timeRemaining <= 5 && _timeRemaining > 0) {
        HapticFeedback.selectionClick();
      }
      if (_timeRemaining <= 0) {
        _timer?.cancel();
        HapticFeedback.heavyImpact();
        _answerQuestion(0);
      }
    });
  }

  /// 0 = skip, 1 = answered, 2 = surprise
  void _answerQuestion(int level) {
    HapticFeedback.mediumImpact();
    _timer?.cancel();
    setState(() {
      if (level == 0) {
        _skippedCount++;
      } else if (level == 1) {
        _answeredCount++;
        _connectionPoints += 1 * _depthMultiplier;
      } else if (level == 2) {
        _answeredCount++;
        _surpriseCount++;
        _connectionPoints += 3 * _depthMultiplier;
      }
    });
    if (level > 0) {
      _meterBump.forward(from: 0);
    }
    if (level == 2) {
      _celebrate.forward(from: 0);
    }
    _nextQuestion();
  }

  void _toggleBookmark() {
    HapticFeedback.selectionClick();
    setState(() {
      if (_bookmarked.contains(_currentQuestionIndex)) {
        _bookmarked.remove(_currentQuestionIndex);
      } else {
        _bookmarked.add(_currentQuestionIndex);
      }
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _currentQuestions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _currentPlayer = _currentPlayer == 1 ? 2 : 1;
        _showingQuestion = false;
      });
    } else {
      _showFinalResults();
    }
  }

  // ---------------------------------------------------------------------------
  // Final results
  // ---------------------------------------------------------------------------
  void _showFinalResults() {
    HapticFeedback.heavyImpact();
    _celebrate.forward(from: 0);
    final maxPoints = 3 * _depthMultiplier * _currentQuestions.length;
    final ratio = maxPoints == 0
        ? 0.0
        : (_connectionPoints / maxPoints).clamp(0.0, 1.0);
    final messageKey = ratio > 0.7
        ? 'games.question_quest.connection_message_high'
        : ratio > 0.4
            ? 'games.question_quest.connection_message_mid'
            : 'games.question_quest.connection_message_low';

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (context) => _FinalResultsDialog(
        connectionPoints: _connectionPoints,
        ratio: ratio,
        answered: _answeredCount,
        skipped: _skippedCount,
        surprises: _surpriseCount,
        bookmarkedQuestions:
            _bookmarked.map((i) => _currentQuestions[i]).toList(),
        connectionMessage: messageKey.tr(),
        onPlayAgain: () {
          Navigator.pop(context);
          _startGame();
        },
        onMenu: () {
          Navigator.pop(context);
          setState(() => _gameStarted = false);
        },
      ),
    );
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
                'games.question_quest.title'.tr(),
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
          // Cosmic gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F0729),
                  Color(0xFF1A0A4A),
                  Color(0xFF0A0F2C),
                  Color(0xFF050818),
                ],
              ),
            ),
          ),
          // Star field + nebula
          AnimatedBuilder(
            animation: _bgStars,
            builder: (context, _) {
              return CustomPaint(
                size: Size.infinite,
                painter: _CosmicBgPainter(
                  stars: _stars,
                  nebula: _nebula,
                  progress: _bgStars.value,
                  intensity: _gameStarted
                      ? (_connectionPoints /
                              (3 *
                                  _depthMultiplier *
                                  max(_currentQuestions.length, 1)))
                          .clamp(0.0, 1.0)
                      : 0.4,
                ),
              );
            },
          ),
          SafeArea(
            child: !_gameStarted ? _buildSetupView() : _buildGameView(),
          ),
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
              colors: [Color(0xFF1A0A4A), Color(0xFF0A0F2C)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🌌', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text(
                'games.question_quest.exit_confirm'.tr(),
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
          const SizedBox(height: 6),
          // Header — animated soul orb (heart inside galaxy)
          AnimatedBuilder(
            animation: _glowAnim,
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
                            const Color(0xFFB388FF).withOpacity(
                                0.35 + 0.18 * _glowAnim.value),
                            const Color(0xFFE879F9).withOpacity(0.18),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 140,
                      height: 140,
                      child: CustomPaint(
                        painter: _SoulOrbPainter(
                          pulse: _glowAnim.value,
                          rotation: _bgStars.value * 2 * pi,
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
            'games.question_quest.title'.tr(),
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
            'games.question_quest.subtitle'.tr(),
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

          // Depth selector (the most important choice)
          _sectionLabel(
            icon: Icons.waves,
            color: const Color(0xFF7DD3FC),
            label: 'games.question_quest.depth_label'.tr(),
          ),
          const SizedBox(height: 14),
          ..._depths.map((depth) {
            final id = depth['id'] as String;
            final isSelected = _selectedDepth == id;
            final color = depth['color'] as Color;
            final mult = depth['multiplier'] as int;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedDepth = id);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
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
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isSelected ? color : Colors.white.withOpacity(0.1),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
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
                        child: Text(
                          depth['emoji'] as String,
                          style: const TextStyle(fontSize: 26),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'games.question_quest.depth_$id'.tr(),
                                style: TextStyle(
                                  fontFamily: 'PlayfairDisplay',
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? color
                                      : Colors.white.withOpacity(0.85),
                                  decoration: TextDecoration.none,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '×$mult',
                                  style: TextStyle(
                                    fontFamily: 'DMSans',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: color,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'games.question_quest.depth_${id}_desc'.tr(),
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
          }),

          const SizedBox(height: 22),

          // Category selector (chips)
          _sectionLabel(
            icon: Icons.category,
            color: const Color(0xFFE879F9),
            label: 'games.question_quest.category_label'.tr(),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories.map((cat) {
              final id = cat['id'] as String;
              final color = cat['color'] as Color;
              final isSelected = _selectedCategory == id;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedCategory = id);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: [
                              color.withOpacity(0.32),
                              color.withOpacity(0.15),
                            ],
                          )
                        : null,
                    color: isSelected ? null : Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? color
                          : Colors.white.withOpacity(0.1),
                      width: isSelected ? 1.5 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withOpacity(0.3),
                              blurRadius: 12,
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(cat['emoji'] as String,
                          style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text(
                        'games.question_quest.cat_$id'.tr(),
                        style: TextStyle(
                          fontFamily: 'DMSans',
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withOpacity(0.8),
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 12,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 22),

          // Optional timer toggle
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _timerEnabled = !_timerEnabled);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: _timerEnabled
                    ? const Color(0xFFFFD166).withOpacity(0.15)
                    : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _timerEnabled
                      ? const Color(0xFFFFD166).withOpacity(0.6)
                      : Colors.white.withOpacity(0.08),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.timer,
                      color: _timerEnabled
                          ? const Color(0xFFFFD166)
                          : Colors.white.withOpacity(0.5),
                      size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'games.question_quest.timer_optional'.tr(),
                          style: const TextStyle(
                            fontFamily: 'PlayfairDisplay',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        Text(
                          _timerEnabled
                              ? 'games.question_quest.timer_on'.tr()
                              : 'games.question_quest.timer_off'.tr(),
                          style: TextStyle(
                            fontFamily: 'DMSans',
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.55),
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 44,
                    height: 24,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: _timerEnabled
                          ? const Color(0xFFFFD166)
                          : Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Align(
                      alignment: _timerEnabled
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 3,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 22),

          // Features hint card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFB388FF).withOpacity(0.10),
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
                        color: Color(0xFFB388FF), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'games.question_quest.features_title'.tr(),
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
                    _featureChip('🌌',
                        'games.question_quest.feature_connection'.tr()),
                    _featureChip('💞',
                        'games.question_quest.feature_surprise'.tr()),
                    _featureChip('⭐',
                        'games.question_quest.feature_bookmark'.tr()),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Start button — purple/pink shimmer
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
                        Color(0xFF6B2D5B),
                        Color(0xFFB388FF),
                        Color(0xFFE879F9),
                        Color(0xFFB388FF),
                        Color(0xFF6B2D5B),
                      ],
                      stops: [0.0, 0.25, 0.5, 0.75, 1.0],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFB388FF).withOpacity(0.5),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.rocket_launch,
                          color: Colors.white, size: 24),
                      const SizedBox(width: 10),
                      Text(
                        'games.question_quest.start_journey'.tr(),
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
    final color = _currentPlayer == 1
        ? const Color(0xFFE879F9)
        : const Color(0xFFFFD166);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        children: [
          // Top: progress + connection meter
          _buildTopHud(color),

          const SizedBox(height: 14),

          // Player indicator
          _buildPlayerIndicator(color),

          const SizedBox(height: 14),

          // Card or button to reveal
          Expanded(
            child: Center(
              child: _showingQuestion
                  ? _buildQuestionCard()
                  : _buildCardBack(),
            ),
          ),

          const SizedBox(height: 12),

          // Action area
          if (_showingQuestion) _buildActionRow(),
        ],
      ),
    );
  }

  Widget _buildTopHud(Color playerColor) {
    final maxPoints =
        3 * _depthMultiplier * max(_currentQuestions.length, 1);
    final ratio = (_connectionPoints / maxPoints).clamp(0.0, 1.0);
    return Column(
      children: [
        Row(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.help_outline,
                      color: Color(0xFFFFD166), size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'games.question_quest.question_short'.tr(namedArgs: {
                      'current': '${_currentQuestionIndex + 1}',
                      'total': '${_currentQuestions.length}',
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
            // Bookmark counter
            if (_bookmarked.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD166).withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bookmark,
                        color: Color(0xFFFFD166), size: 12),
                    const SizedBox(width: 4),
                    Text(
                      '${_bookmarked.length}',
                      style: const TextStyle(
                        fontFamily: 'PlayfairDisplay',
                        color: Color(0xFFFFD166),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        // Connection meter (cooperative score)
        AnimatedBuilder(
          animation: _meterBumpAnim,
          builder: (context, _) {
            return Transform.scale(
              scale: _meterBump.isAnimating ? _meterBumpAnim.value : 1.0,
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFB388FF).withOpacity(0.18),
                      const Color(0xFF6B2D5B).withOpacity(0.06),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: const Color(0xFFB388FF).withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('🌌',
                            style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Text(
                          'games.question_quest.connection'.tr(),
                          style: const TextStyle(
                            fontFamily: 'DMSans',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFB388FF),
                            letterSpacing: 1,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '$_connectionPoints',
                          style: const TextStyle(
                            fontFamily: 'PlayfairDisplay',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 6,
                      child: CustomPaint(
                        size: const Size(double.infinity, 6),
                        painter: _ConnectionMeterPainter(
                          ratio: ratio,
                          glow: _glowAnim.value,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPlayerIndicator(Color color) {
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (context, _) {
        return Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.18),
                color.withOpacity(0.06),
                color.withOpacity(0.18),
              ],
              stops: [0.0, _shimmer.value, 1.0],
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
                    '$_currentPlayer',
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
                'games.question_quest.partner_answers'
                    .tr(args: ['$_currentPlayer']),
                style: TextStyle(
                  fontFamily: 'PlayfairDisplay',
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCardBack() {
    return GestureDetector(
      onTap: _revealQuestion,
      child: AnimatedBuilder(
        animation: _glowAnim,
        builder: (context, _) {
          return Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 280),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF6B2D5B),
                  Color(0xFFB388FF),
                  Color(0xFF1A0A4A),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                  color: Colors.white.withOpacity(0.2), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFB388FF)
                      .withOpacity(0.45 + 0.18 * _glowAnim.value),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Magic circle pattern
                CustomPaint(
                  size: const Size(double.infinity, 280),
                  painter: _CardBackPatternPainter(
                    rotation: _bgStars.value * 2 * pi,
                    pulse: _glowAnim.value,
                  ),
                ),
                // Center content
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.white
                                  .withOpacity(0.4 + 0.2 * _glowAnim.value),
                              Colors.white.withOpacity(0.05),
                            ],
                          ),
                        ),
                        child: const Center(
                          child: Text('💫',
                              style: TextStyle(fontSize: 36)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'games.question_quest.tap_to_reveal'.tr(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'PlayfairDisplay',
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'games.question_quest.the_question'.tr(),
                        style: TextStyle(
                          fontFamily: 'DMSans',
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuestionCard() {
    final isBookmarked = _bookmarked.contains(_currentQuestionIndex);
    return AnimatedBuilder(
      animation: _cardFlipAnim,
      builder: (context, child) {
        // 3D flip effect
        final v = _cardFlipAnim.value;
        final angle = (1 - v) * pi;
        final isShowingFront = v > 0.5;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0015)
            ..rotateY(angle),
          child: isShowingFront ? child : const SizedBox.shrink(),
        );
      },
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 280),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFFCF2),
              Color(0xFFFFF1B0),
              Color(0xFFEAD2A8),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFFD4A574).withOpacity(0.6),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFB388FF).withOpacity(0.4),
              blurRadius: 26,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            // Top: depth badge + bookmark
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B2D5B).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _depths.firstWhere(
                            (d) => d['id'] == _selectedDepth)['emoji']
                            as String,
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'games.question_quest.depth_$_selectedDepth'.tr(),
                        style: const TextStyle(
                          fontFamily: 'DMSans',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6B2D5B),
                          letterSpacing: 0.8,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _toggleBookmark,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isBookmarked
                          ? const Color(0xFFFFD166)
                          : Colors.white.withOpacity(0.5),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: isBookmarked
                              ? const Color(0xFFFFD166).withOpacity(0.5)
                              : Colors.transparent,
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Icon(
                      isBookmarked
                          ? Icons.bookmark
                          : Icons.bookmark_border,
                      color: isBookmarked
                          ? const Color(0xFF3A2200)
                          : const Color(0xFF6B2D5B),
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Icon(Icons.format_quote,
                color: Color(0xFF6B2D5B), size: 36),
            const SizedBox(height: 8),
            Container(
              height: 1,
              width: 80,
              color: const Color(0xFF6B2D5B).withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              _currentQuestions[_currentQuestionIndex],
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'PlayfairDisplay',
                fontSize: 19,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3D1A2D),
                height: 1.45,
                fontStyle: FontStyle.italic,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 18),
            // Timer (if enabled)
            if (_timerEnabled) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.timer,
                    color: _timeRemaining <= 10
                        ? const Color(0xFFE53935)
                        : const Color(0xFF6B2D5B),
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_timeRemaining}s',
                    style: TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _timeRemaining <= 10
                          ? const Color(0xFFE53935)
                          : const Color(0xFF6B2D5B),
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionRow() {
    return Column(
      children: [
        // Surprise button — gold gradient
        AnimatedBuilder(
          animation: _shimmer,
          builder: (context, _) {
            return GestureDetector(
              onTap: () => _answerQuestion(2),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(-1 + 2 * _shimmer.value, 0),
                    end: Alignment(1 + 2 * _shimmer.value, 0),
                    colors: const [
                      Color(0xFFFFD166),
                      Color(0xFFFFB347),
                      Color(0xFFFFF1B0),
                      Color(0xFFFFB347),
                      Color(0xFFFFD166),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD166).withOpacity(0.5),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('💞',
                        style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text(
                      'games.question_quest.surprise_reaction'.tr(),
                      style: const TextStyle(
                        fontFamily: 'PlayfairDisplay',
                        fontSize: 16,
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
        const SizedBox(height: 8),
        Row(
          children: [
            // Skip
            Expanded(
              child: GestureDetector(
                onTap: () => _answerQuestion(0),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: Colors.white.withOpacity(0.15)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.skip_next,
                          color: Colors.white.withOpacity(0.6),
                          size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'games.question_quest.skip'.tr(),
                        style: TextStyle(
                          fontFamily: 'DMSans',
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Answered
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: () => _answerQuestion(1),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF6B2D5B),
                        Color(0xFFB388FF),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFB388FF).withOpacity(0.45),
                        blurRadius: 16,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_rounded,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'games.question_quest.answered'.tr(),
                        style: const TextStyle(
                          fontFamily: 'DMSans',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.8,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
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
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A0A4A), Color(0xFF0A0F2C)],
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
                'games.question_quest.how_to_play'.tr(),
                style: const TextStyle(
                  fontFamily: 'PlayfairDisplay',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 16),
              _ruleRow('1', 'games.question_quest.rule_1'.tr()),
              const SizedBox(height: 8),
              _ruleRow('2', 'games.question_quest.rule_2'.tr()),
              const SizedBox(height: 8),
              _ruleRow('3', 'games.question_quest.rule_3'.tr()),
              const SizedBox(height: 8),
              _ruleRow('4', 'games.question_quest.rule_4'.tr()),
              const SizedBox(height: 8),
              _ruleRow('5', 'games.question_quest.rule_5'.tr()),
              const SizedBox(height: 18),
              Text(
                'games.question_quest.closing'.tr(),
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
              colors: [Color(0xFFB388FF), Color(0xFF6B2D5B)],
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
// Final results dialog
// =============================================================================
class _FinalResultsDialog extends StatelessWidget {
  final int connectionPoints;
  final double ratio;
  final int answered;
  final int skipped;
  final int surprises;
  final List<String> bookmarkedQuestions;
  final String connectionMessage;
  final VoidCallback onPlayAgain;
  final VoidCallback onMenu;

  const _FinalResultsDialog({
    required this.connectionPoints,
    required this.ratio,
    required this.answered,
    required this.skipped,
    required this.surprises,
    required this.bookmarkedQuestions,
    required this.connectionMessage,
    required this.onPlayAgain,
    required this.onMenu,
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
              Color(0xFF1A0A4A),
              Color(0xFF0A0F2C),
              Color(0xFF050818),
            ],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
              color: const Color(0xFFB388FF).withOpacity(0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFB388FF).withOpacity(0.5),
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
                const Text('🌌', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 4),
                Text(
                  'games.question_quest.journey_complete'.tr(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'PlayfairDisplay',
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFB388FF),
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 18),
                // Connection level meter (big)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0x33B388FF),
                        Color(0x336B2D5B),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: const Color(0xFFB388FF).withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'games.question_quest.connection_level'.tr(),
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
                            Shadow(color: Color(0xFFB388FF), blurRadius: 18),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 8,
                        child: CustomPaint(
                          size: const Size(double.infinity, 8),
                          painter: _ConnectionMeterPainter(
                            ratio: ratio,
                            glow: 1.0,
                          ),
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
                // Stats
                Row(
                  children: [
                    Expanded(
                      child: _stat('💬',
                          'games.question_quest.revealed_count'.tr(),
                          '$answered'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _stat('💞',
                          'games.question_quest.surprise_count'.tr(),
                          '$surprises'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _stat('⏭️',
                          'games.question_quest.skipped_count'.tr(),
                          '$skipped'),
                    ),
                  ],
                ),
                if (bookmarkedQuestions.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      const Icon(Icons.bookmark,
                          color: Color(0xFFFFD166), size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'games.question_quest.bookmarked_questions'.tr(),
                        style: const TextStyle(
                          fontFamily: 'PlayfairDisplay',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFFFD166),
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...bookmarkedQuestions.map(
                    (q) => Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD166).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color(0xFFFFD166)
                                .withOpacity(0.25)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('⭐',
                              style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              q,
                              style: const TextStyle(
                                fontFamily: 'PlayfairDisplay',
                                color: Colors.white,
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                                height: 1.4,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: onMenu,
                        child: Container(
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color:
                                    Colors.white.withOpacity(0.18)),
                          ),
                          child: Center(
                            child: Text(
                              'games.question_quest.menu'.tr(),
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
                                Color(0xFFB388FF),
                                Color(0xFF6B2D5B),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFB388FF)
                                    .withOpacity(0.45),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'games.question_quest.play_again'.tr(),
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

  Widget _stat(String icon, String label, String value) {
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
              fontSize: 18,
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
              fontSize: 9,
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

/// Soul orb — galaxy with heart inside.
class _SoulOrbPainter extends CustomPainter {
  final double pulse;
  final double rotation;

  _SoulOrbPainter({required this.pulse, required this.rotation});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);
    final r = w * 0.45;

    // Halo
    final halo = Paint()
      ..shader = ui.Gradient.radial(
        center,
        r * 1.5,
        [
          const Color(0xFFB388FF).withOpacity(0.5 * pulse),
          Colors.transparent,
        ],
      );
    canvas.drawCircle(center, r * 1.5, halo);

    // Outer orb (galaxy)
    final orb = Paint()
      ..shader = ui.Gradient.radial(
        center - Offset(r * 0.3, r * 0.3),
        r,
        const [
          Color(0xFFE879F9),
          Color(0xFF6B2D5B),
          Color(0xFF1A0A4A),
        ],
        [0.0, 0.55, 1.0],
      );
    canvas.drawCircle(center, r, orb);

    // Spiraling stars inside
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    final starPaint = Paint()..color = Colors.white.withOpacity(0.7);
    for (int i = 0; i < 14; i++) {
      final t = i / 14.0;
      final angle = t * 4 * pi;
      final dist = r * (0.2 + 0.7 * t);
      final pos = Offset(cos(angle) * dist, sin(angle) * dist);
      canvas.drawCircle(pos, 1.5 + (1 - t) * 1.5, starPaint);
    }
    canvas.restore();

    // Heart inside
    final hr = r * 0.3;
    final heartCenter = center;
    final heartGradient = Paint()
      ..shader = ui.Gradient.radial(
        heartCenter - Offset(hr * 0.2, hr * 0.3),
        hr,
        const [
          Color(0xFFFFB6C1),
          Color(0xFFE53935),
        ],
      );
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
    canvas.drawPath(heart, heartGradient);

    // Specular highlight
    final shine = Paint()..color = Colors.white.withOpacity(0.55);
    canvas.drawCircle(
        center - Offset(r * 0.4, r * 0.45), r * 0.18, shine);
  }

  @override
  bool shouldRepaint(covariant _SoulOrbPainter old) =>
      old.pulse != pulse || old.rotation != rotation;
}

/// Cosmic background — twinkling stars, drifting nebula, density tied to connection.
class _CosmicBgPainter extends CustomPainter {
  final List<_Star> stars;
  final List<_NebulaOrb> nebula;
  final double progress;
  final double intensity; // 0..1

  _CosmicBgPainter({
    required this.stars,
    required this.nebula,
    required this.progress,
    required this.intensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Nebula orbs (drifting)
    for (final n in nebula) {
      final phase = (n.phase + progress * n.speed) % 1.0;
      final cx = n.x * size.width + sin(phase * 2 * pi) * 40;
      final cy = n.y * size.height + cos(phase * 2 * pi) * 40;
      final radius = 100 + 60 * intensity;
      final paint = Paint()
        ..shader = ui.Gradient.radial(
          Offset(cx, cy),
          radius,
          [
            n.color.withOpacity(0.10 + 0.06 * intensity),
            Colors.transparent,
          ],
        );
      canvas.drawCircle(Offset(cx, cy), radius, paint);
    }

    // Stars
    final paint = Paint();
    for (final s in stars) {
      final twinkle =
          0.4 + 0.6 * sin((progress + s.phase) * 2 * pi).abs();
      final brightness = 0.45 + 0.4 * intensity;
      paint.color = Colors.white.withOpacity(brightness * twinkle);
      canvas.drawCircle(
        Offset(s.x * size.width, s.y * size.height),
        s.size * twinkle,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CosmicBgPainter old) =>
      old.progress != progress || old.intensity != intensity;
}

class _Star {
  final double x;
  final double y;
  final double size;
  final double phase;
  _Star(Random r)
      : x = r.nextDouble(),
        y = r.nextDouble(),
        size = 0.6 + r.nextDouble() * 1.6,
        phase = r.nextDouble();
}

class _NebulaOrb {
  final double x;
  final double y;
  final double speed;
  final double phase;
  final Color color;
  _NebulaOrb(Random r)
      : x = r.nextDouble(),
        y = r.nextDouble(),
        speed = 0.1 + r.nextDouble() * 0.2,
        phase = r.nextDouble(),
        color = [
          const Color(0xFFB388FF),
          const Color(0xFFE879F9),
          const Color(0xFF7DD3FC),
          const Color(0xFFFF8FB1),
          const Color(0xFFFFD166),
        ][r.nextInt(5)];
}

/// Connection meter bar (gradient + glow).
class _ConnectionMeterPainter extends CustomPainter {
  final double ratio; // 0..1
  final double glow; // 0..1

  _ConnectionMeterPainter({required this.ratio, required this.glow});

  @override
  void paint(Canvas canvas, Size size) {
    // Track
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

      // Glow
      final glowPaint = Paint()
        ..color = const Color(0xFFB388FF).withOpacity(0.5 * glow)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawRRect(fillRect, glowPaint);

      // Fill
      final fillPaint = Paint()
        ..shader = ui.Gradient.linear(
          const Offset(0, 0),
          Offset(size.width * ratio, 0),
          const [
            Color(0xFF6B2D5B),
            Color(0xFFB388FF),
            Color(0xFFE879F9),
          ],
        );
      canvas.drawRRect(fillRect, fillPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConnectionMeterPainter old) =>
      old.ratio != ratio || old.glow != glow;
}

/// Pattern on the back of the question card — concentric arcs + sparkles.
class _CardBackPatternPainter extends CustomPainter {
  final double rotation;
  final double pulse;

  _CardBackPatternPainter({required this.rotation, required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.width * 0.5;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = Colors.white.withOpacity(0.18);
    for (int i = 1; i <= 4; i++) {
      canvas.drawCircle(Offset.zero, maxR * (i / 5), ringPaint);
    }

    final dotPaint = Paint()..color = Colors.white.withOpacity(0.4);
    for (int i = 0; i < 12; i++) {
      final a = (i / 12) * 2 * pi;
      canvas.drawCircle(
        Offset(cos(a) * maxR * 0.7, sin(a) * maxR * 0.7),
        1.6,
        dotPaint,
      );
    }
    canvas.restore();

    // Pulsing center glow
    final glowPaint = Paint()
      ..shader = ui.Gradient.radial(
        center,
        maxR * 0.6,
        [
          Colors.white.withOpacity(0.18 * pulse),
          Colors.transparent,
        ],
      );
    canvas.drawCircle(center, maxR * 0.6, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _CardBackPatternPainter old) =>
      old.rotation != rotation || old.pulse != pulse;
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
      const Color(0xFFB388FF),
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
