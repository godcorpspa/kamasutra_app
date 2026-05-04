import 'dart:math';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class LoveNotesScreen extends StatefulWidget {
  const LoveNotesScreen({super.key});

  @override
  State<LoveNotesScreen> createState() => _LoveNotesScreenState();
}

class _LoveNotesScreenState extends State<LoveNotesScreen>
    with TickerProviderStateMixin {
  // ---------------------------------------------------------------------------
  // Game state
  // ---------------------------------------------------------------------------
  bool _gameStarted = false;
  String _currentPrompt = '';
  int _currentPlayer = 1;
  int _roundNumber = 1;
  int _totalRounds = 5;
  String _category = 'romantic';

  final TextEditingController _noteController = TextEditingController();
  final FocusNode _noteFocus = FocusNode();
  final List<Map<String, dynamic>> _savedNotes = [];

  final Map<String, List<String>> _promptKeys = {
    'romantic': List.generate(
        10, (i) => 'games.love_notes.prompts.romantic_$i'),
    'compliment': List.generate(
        10, (i) => 'games.love_notes.prompts.compliment_$i'),
    'spicy': List.generate(10, (i) => 'games.love_notes.prompts.spicy_$i'),
  };

  // ---------------------------------------------------------------------------
  // Animations
  // ---------------------------------------------------------------------------
  late final AnimationController _bgParticles;
  late final AnimationController _glow;
  late final AnimationController _shimmer;
  late final AnimationController _envelopeIntro;
  late final AnimationController _promptFlip;
  late final AnimationController _heartBeat;

  late Animation<double> _glowAnim;
  late Animation<double> _envelopeAnim;
  late Animation<double> _promptFlipAnim;
  late Animation<double> _heartBeatAnim;

  final List<_FloatingHeart> _hearts = List.generate(
    28,
    (i) => _FloatingHeart(Random(i * 17 + 3)),
  );

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------
  @override
  void initState() {
    super.initState();
    _bgParticles = AnimationController(
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

    _envelopeIntro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _envelopeAnim = CurvedAnimation(
      parent: _envelopeIntro,
      curve: Curves.easeOutBack,
    );
    _envelopeIntro.forward();

    _promptFlip = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _promptFlipAnim = CurvedAnimation(
      parent: _promptFlip,
      curve: Curves.easeOutCubic,
    );

    _heartBeat = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _heartBeatAnim = Tween<double>(begin: 0.94, end: 1.06)
        .animate(CurvedAnimation(parent: _heartBeat, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _noteController.dispose();
    _noteFocus.dispose();
    _bgParticles.dispose();
    _glow.dispose();
    _shimmer.dispose();
    _envelopeIntro.dispose();
    _promptFlip.dispose();
    _heartBeat.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Game logic
  // ---------------------------------------------------------------------------
  void _startGame() {
    HapticFeedback.heavyImpact();
    _pickNewPrompt();
    setState(() {
      _gameStarted = true;
      _currentPlayer = 1;
      _roundNumber = 1;
      _savedNotes.clear();
    });
    _promptFlip.forward(from: 0);
  }

  void _pickNewPrompt() {
    final promptKeys = _promptKeys[_category]!;
    _currentPrompt = promptKeys[Random().nextInt(promptKeys.length)].tr();
  }

  void _submitNote() {
    if (_noteController.text.trim().isEmpty) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Text('💔 ', style: TextStyle(fontSize: 18)),
              Expanded(
                child: Text(
                  'game_ui.write_first'.tr(),
                  style: const TextStyle(
                    fontFamily: 'DMSans',
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFB23A48),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() {
      _savedNotes.add({
        'player': _currentPlayer,
        'prompt': _currentPrompt,
        'note': _noteController.text.trim(),
        'round': _roundNumber,
      });
      _noteController.clear();
    });

    if (_currentPlayer == 1) {
      setState(() => _currentPlayer = 2);
      _promptFlip.forward(from: 0);
    } else {
      if (_roundNumber < _totalRounds) {
        _pickNewPrompt();
        setState(() {
          _roundNumber++;
          _currentPlayer = 1;
        });
        _promptFlip.forward(from: 0);
      } else {
        _showResults();
      }
    }
    _noteFocus.unfocus();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white70),
          onPressed: () => context.pop(),
        ),
        title: _gameStarted
            ? null
            : Text(
                'games.love_notes.title'.tr(),
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
      body: Stack(
        children: [
          // Background gradient — deep romantic burgundy → purple → dark
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF2A0A1F),
                  Color(0xFF3D0F2D),
                  Color(0xFF1A0A2E),
                  Color(0xFF120822),
                ],
                stops: [0.0, 0.35, 0.7, 1.0],
              ),
            ),
          ),
          // Animated floating hearts/petals
          AnimatedBuilder(
            animation: _bgParticles,
            builder: (context, _) {
              return CustomPaint(
                size: Size.infinite,
                painter: _FloatingHeartsPainter(
                  hearts: _hearts,
                  progress: _bgParticles.value,
                  accentColor: _categoryColor(_category),
                ),
              );
            },
          ),
          SafeArea(
            child: _gameStarted ? _buildGameView() : _buildSetupView(),
          ),
        ],
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

          // Header — animated envelope + glow
          AnimatedBuilder(
            animation: Listenable.merge([_glowAnim, _heartBeatAnim, _envelopeAnim]),
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
                            _categoryColor(_category).withOpacity(
                                0.35 + 0.18 * _glowAnim.value),
                            _categoryColor(_category).withOpacity(0.1),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    Transform.scale(
                      scale: _heartBeatAnim.value * (0.6 + 0.4 * _envelopeAnim.value.clamp(0.0, 1.0)),
                      child: SizedBox(
                        width: 120,
                        height: 95,
                        child: CustomPaint(
                          painter: _EnvelopePainter(
                            color: _categoryColor(_category),
                            accent: _categoryAccent(_category),
                            glowPulse: _glowAnim.value,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 8),

          Text(
            'games.love_notes.title'.tr(),
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
            'game_ui.write_secret_messages'.tr(),
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

          // Category section
          _sectionLabel(
            icon: Icons.favorite,
            color: const Color(0xFFE879F9),
            label: 'game_ui.category'.tr(),
          ),
          const SizedBox(height: 14),
          _buildCategoryCard(
            value: 'romantic',
            emoji: '💕',
            label: 'game_ui.romantic_cat'.tr(),
            description: 'game_ui.romantic_desc'.tr(),
            color: const Color(0xFFFF8FB1),
            accent: const Color(0xFFFFB6C1),
          ),
          const SizedBox(height: 10),
          _buildCategoryCard(
            value: 'compliment',
            emoji: '✨',
            label: 'game_ui.compliment_cat'.tr(),
            description: 'game_ui.compliment_desc'.tr(),
            color: const Color(0xFFFFD166),
            accent: const Color(0xFFFFE7A0),
          ),
          const SizedBox(height: 10),
          _buildCategoryCard(
            value: 'spicy',
            emoji: '🔥',
            label: 'game_ui.spicy_cat'.tr(),
            description: 'game_ui.spicy_desc'.tr(),
            color: const Color(0xFFFF6B35),
            accent: const Color(0xFFFFB347),
          ),

          const SizedBox(height: 26),

          // Rounds
          _sectionLabel(
            icon: Icons.refresh,
            color: const Color(0xFFFFD166),
            label: 'game_ui.number_of_rounds'.tr(),
          ),
          const SizedBox(height: 14),
          Row(
            children: [3, 5, 7].map((rounds) {
              final isSelected = _totalRounds == rounds;
              final color = _categoryColor(_category);
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
                            ? [color, color.withOpacity(0.7)]
                            : [
                                Colors.white.withOpacity(0.06),
                                Colors.white.withOpacity(0.02),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? color
                            : Colors.white.withOpacity(0.1),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withOpacity(0.45),
                                blurRadius: 18,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '$rounds',
                        style: TextStyle(
                          fontFamily: 'PlayfairDisplay',
                          color: isSelected ? Colors.white : Colors.white,
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

          const SizedBox(height: 26),

          // Rules card preview
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
                      'games.love_notes.rules_title'.tr(),
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
                _ruleRow('1', 'games.love_notes.rule_1'.tr()),
                const SizedBox(height: 8),
                _ruleRow('2', 'games.love_notes.rule_2'.tr()),
                const SizedBox(height: 8),
                _ruleRow('3', 'games.love_notes.rule_3'.tr()),
                const SizedBox(height: 8),
                _ruleRow('4', 'games.love_notes.rule_4'.tr()),
              ],
            ),
          ),

          const SizedBox(height: 26),

          // Start button — shimmer pink/red
          AnimatedBuilder(
            animation: _shimmer,
            builder: (context, _) {
              final color = _categoryColor(_category);
              final accent = _categoryAccent(_category);
              return GestureDetector(
                onTap: _startGame,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(-1 + 2 * _shimmer.value, 0),
                      end: Alignment(1 + 2 * _shimmer.value, 0),
                      colors: [
                        color,
                        accent,
                        Colors.white.withOpacity(0.9),
                        accent,
                        color,
                      ],
                      stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.5),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.edit_rounded,
                          color: Colors.white, size: 24),
                      const SizedBox(width: 10),
                      Text(
                        'game_ui.start_writing'.tr(),
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

  Widget _buildCategoryCard({
    required String value,
    required String emoji,
    required String label,
    required String description,
    required Color color,
    required Color accent,
  }) {
    final isSelected = _category == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _category = value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isSelected
                ? [color.withOpacity(0.32), accent.withOpacity(0.12)]
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
                    blurRadius: 22,
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
                  colors: [color.withOpacity(0.6), color.withOpacity(0.15)],
                ),
                border: Border.all(color: color.withOpacity(0.6), width: 1),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 26)),
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
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? color : Colors.white.withOpacity(0.85),
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
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
              colors: [Color(0xFFE879F9), Color(0xFFFF8FB1)],
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
  Widget _buildGameView() {
    final color = _currentPlayer == 1
        ? const Color(0xFFE879F9)
        : const Color(0xFFFFD166);
    final accent = _currentPlayer == 1
        ? const Color(0xFFFFB6C1)
        : const Color(0xFFFFE7A0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        children: [
          // Round + player turn
          Row(
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
              AnimatedBuilder(
                animation: _shimmer,
                builder: (context, _) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
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
                      border: Border.all(color: color.withOpacity(0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(colors: [
                              color,
                              color.withOpacity(0.4),
                            ]),
                            boxShadow: [
                              BoxShadow(
                                  color: color.withOpacity(0.5),
                                  blurRadius: 10),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '$_currentPlayer',
                              style: const TextStyle(
                                fontFamily: 'PlayfairDisplay',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'game_ui.player_turn'.tr(
                              namedArgs: {'player': '$_currentPlayer'}),
                          style: TextStyle(
                            fontFamily: 'PlayfairDisplay',
                            color: color,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Animated prompt card (parchment-style)
          AnimatedBuilder(
            animation: _promptFlipAnim,
            builder: (context, child) {
              final v = _promptFlipAnim.value;
              return Transform.translate(
                offset: Offset(0, 14 * (1 - v)),
                child: Opacity(opacity: v, child: child),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFFFF1B0).withOpacity(0.95),
                    const Color(0xFFF5E0C3).withOpacity(0.9),
                    const Color(0xFFEAD2A8).withOpacity(0.85),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFFD4A574).withOpacity(0.6),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD166).withOpacity(0.25),
                    blurRadius: 18,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6B2D5B).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _categoryEmoji(_category),
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'game_ui.${_category}_cat'.tr(),
                          style: const TextStyle(
                            fontFamily: 'DMSans',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF6B2D5B),
                            letterSpacing: 1,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    height: 1,
                    width: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          const Color(0xFF6B2D5B).withOpacity(0.4),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _currentPrompt,
                    style: const TextStyle(
                      fontFamily: 'PlayfairDisplay',
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3D1A2D),
                      height: 1.4,
                      decoration: TextDecoration.none,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Privacy reminder
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFFD166).withOpacity(0.16),
                  const Color(0xFFFF8C42).withOpacity(0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFFFD166).withOpacity(0.4),
              ),
            ),
            child: Row(
              children: [
                const Text('🤫', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'game_ui.turn_away'.tr(namedArgs: {
                      'player': _currentPlayer == 1 ? '2' : '1',
                    }),
                    style: const TextStyle(
                      fontFamily: 'DMSans',
                      color: Color(0xFFFFD166),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Note paper input
          Expanded(
            child: AnimatedBuilder(
              animation: _glowAnim,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFFFFFCF2),
                        Color(0xFFFFF7E0),
                        Color(0xFFFFEEC9),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: color.withOpacity(0.45 + 0.25 * _glowAnim.value),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.25 + 0.15 * _glowAnim.value),
                        blurRadius: 20,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: child,
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  children: [
                    // Subtle ruled-paper lines
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _RuledPaperPainter(
                          lineColor: const Color(0xFFE6CFA0).withOpacity(0.4),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        controller: _noteController,
                        focusNode: _noteFocus,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        style: const TextStyle(
                          fontFamily: 'PlayfairDisplay',
                          color: Color(0xFF3D1A2D),
                          fontSize: 16,
                          height: 1.5,
                          fontStyle: FontStyle.italic,
                        ),
                        decoration: InputDecoration(
                          hintText: 'game_ui.write_message_hint'.tr(),
                          hintStyle: TextStyle(
                            fontFamily: 'DMSans',
                            color: const Color(0xFF6B2D5B).withOpacity(0.4),
                            fontStyle: FontStyle.italic,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        cursorColor: color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Submit button — gradient with shimmer
          AnimatedBuilder(
            animation: _shimmer,
            builder: (context, _) {
              return GestureDetector(
                onTap: _submitNote,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(-1 + 2 * _shimmer.value, 0),
                      end: Alignment(1 + 2 * _shimmer.value, 0),
                      colors: [
                        color,
                        accent,
                        Colors.white.withOpacity(0.9),
                        accent,
                        color,
                      ],
                      stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.5),
                        blurRadius: 22,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _currentPlayer == 1
                            ? Icons.send_rounded
                            : Icons.mark_email_read_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _currentPlayer == 1
                            ? 'game_ui.send_pass'.tr(namedArgs: {'player': '2'})
                            : 'game_ui.send_note'.tr(),
                        style: const TextStyle(
                          fontFamily: 'DMSans',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
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
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Results sheet
  // ---------------------------------------------------------------------------
  void _showResults() {
    HapticFeedback.heavyImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.6,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF2A0A1F),
                Color(0xFF1A0A2E),
                Color(0xFF120822),
              ],
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
                child: Column(
                  children: [
                    AnimatedBuilder(
                      animation: _heartBeatAnim,
                      builder: (context, _) => Transform.scale(
                        scale: _heartBeatAnim.value,
                        child: const Text('💌',
                            style: TextStyle(fontSize: 56)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'game_ui.your_love_notes'.tr(),
                      style: const TextStyle(
                        fontFamily: 'PlayfairDisplay',
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'game_ui.read_together'.tr(),
                      style: TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: Colors.white.withOpacity(0.55),
                        decoration: TextDecoration.none,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _totalRounds,
                  itemBuilder: (context, roundIndex) {
                    final roundNotes = _savedNotes
                        .where((n) => n['round'] == roundIndex + 1)
                        .toList();
                    if (roundNotes.isEmpty) return const SizedBox.shrink();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.08)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFD166)
                                      .withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '#${roundIndex + 1}',
                                  style: const TextStyle(
                                    fontFamily: 'DMSans',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFFFD166),
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '📝 ${roundNotes.first['prompt']}',
                                  style: const TextStyle(
                                    fontFamily: 'DMSans',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFFFD166),
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          if (roundNotes.any((n) => n['player'] == 1))
                            _buildResultNote(
                              'game_ui.player_1'.tr(),
                              roundNotes
                                  .firstWhere((n) => n['player'] == 1)['note'],
                              const Color(0xFFE879F9),
                              '👩',
                            ),
                          if (roundNotes.any((n) => n['player'] == 1) &&
                              roundNotes.any((n) => n['player'] == 2))
                            const SizedBox(height: 10),
                          if (roundNotes.any((n) => n['player'] == 2))
                            _buildResultNote(
                              'game_ui.player_2'.tr(),
                              roundNotes
                                  .firstWhere((n) => n['player'] == 2)['note'],
                              const Color(0xFFFFD166),
                              '👨',
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          _startGame();
                        },
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
                              'game_ui.play_again'.tr(),
                              style: TextStyle(
                                fontFamily: 'DMSans',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withOpacity(0.8),
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
                        onTap: () {
                          Navigator.pop(context);
                          if (mounted) context.pop();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFE879F9),
                                Color(0xFFFF8FB1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFE879F9).withOpacity(0.45),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'game_ui.end'.tr(),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultNote(
      String player, String note, Color color, String avatar) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.18),
            color.withOpacity(0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [color, color.withOpacity(0.4)],
                  ),
                ),
                child: Center(
                  child: Text(avatar,
                      style: const TextStyle(fontSize: 14)),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                player,
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
          const SizedBox(height: 8),
          Text(
            note,
            style: const TextStyle(
              fontFamily: 'PlayfairDisplay',
              fontSize: 14,
              color: Colors.white,
              fontStyle: FontStyle.italic,
              height: 1.5,
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
              Color(0xFF2A0A1F),
              Color(0xFF120822),
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
              'games.love_notes.rules_title'.tr(),
              style: const TextStyle(
                fontFamily: 'PlayfairDisplay',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 16),
            _ruleRow('1', 'games.love_notes.rule_1'.tr()),
            const SizedBox(height: 10),
            _ruleRow('2', 'games.love_notes.rule_2'.tr()),
            const SizedBox(height: 10),
            _ruleRow('3', 'games.love_notes.rule_3'.tr()),
            const SizedBox(height: 10),
            _ruleRow('4', 'games.love_notes.rule_4'.tr()),
            const SizedBox(height: 18),
            Text(
              'game_ui.be_sincere_sweet'.tr(),
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

  // ---------------------------------------------------------------------------
  // Color helpers
  // ---------------------------------------------------------------------------
  Color _categoryColor(String category) {
    switch (category) {
      case 'compliment':
        return const Color(0xFFFFD166);
      case 'spicy':
        return const Color(0xFFFF6B35);
      case 'romantic':
      default:
        return const Color(0xFFFF8FB1);
    }
  }

  Color _categoryAccent(String category) {
    switch (category) {
      case 'compliment':
        return const Color(0xFFFFE7A0);
      case 'spicy':
        return const Color(0xFFFFB347);
      case 'romantic':
      default:
        return const Color(0xFFFFB6C1);
    }
  }

  String _categoryEmoji(String category) {
    switch (category) {
      case 'compliment':
        return '✨';
      case 'spicy':
        return '🔥';
      case 'romantic':
      default:
        return '💕';
    }
  }
}

// =============================================================================
// Painters
// =============================================================================

/// Custom-painted love envelope with flap, accent and seal.
class _EnvelopePainter extends CustomPainter {
  final Color color;
  final Color accent;
  final double glowPulse;

  _EnvelopePainter({
    required this.color,
    required this.accent,
    this.glowPulse = 0.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Drop shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(4, 8, w, h),
        const Radius.circular(8),
      ),
      shadowPaint,
    );

    // Body of envelope (cream / paper)
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h),
      const Radius.circular(8),
    );
    final bodyPaint = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(0, 0),
        Offset(w, h),
        const [
          Color(0xFFFFF8E7),
          Color(0xFFF5E0C3),
        ],
      );
    canvas.drawRRect(bodyRect, bodyPaint);

    // Inner edge highlight
    final innerEdge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = const Color(0xFFD4A574).withOpacity(0.5);
    canvas.drawRRect(bodyRect, innerEdge);

    // Diagonal flap edges (folded look) — bottom V
    final flapBottomPath = Path()
      ..moveTo(0, h)
      ..lineTo(w / 2, h * 0.55)
      ..lineTo(w, h)
      ..close();
    final flapBottomPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, h * 0.55),
        Offset(0, h),
        [
          const Color(0xFFFFFCF2).withOpacity(0.0),
          const Color(0xFFE6CFA0).withOpacity(0.35),
        ],
      );
    canvas.drawPath(flapBottomPath, flapBottomPaint);

    // Top flap (open downward) — colored
    final flapPath = Path()
      ..moveTo(0, 0)
      ..lineTo(w / 2, h * 0.55)
      ..lineTo(w, 0)
      ..close();
    final flapPaint = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(0, 0),
        Offset(0, h * 0.55),
        [color, accent],
      );
    canvas.drawPath(flapPath, flapPaint);

    // Flap edge shine
    final flapEdgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withOpacity(0.4);
    canvas.drawLine(const Offset(0, 0), Offset(w / 2, h * 0.55), flapEdgePaint);
    canvas.drawLine(Offset(w / 2, h * 0.55), Offset(w, 0), flapEdgePaint);

    // Heart wax seal at the V tip
    final sealCenter = Offset(w / 2, h * 0.55);
    final sealGlow = Paint()
      ..shader = ui.Gradient.radial(
        sealCenter,
        w * 0.28,
        [
          const Color(0xFFE53935).withOpacity(0.55 * glowPulse),
          Colors.transparent,
        ],
      );
    canvas.drawCircle(sealCenter, w * 0.28, sealGlow);

    final sealPaint = Paint()
      ..shader = ui.Gradient.radial(
        sealCenter - Offset(w * 0.02, w * 0.02),
        w * 0.10,
        const [
          Color(0xFFFF6B6B),
          Color(0xFFC41E3A),
        ],
      );
    final heartPath = _heartPath(sealCenter, w * 0.10);
    canvas.drawPath(heartPath, sealPaint);

    // Seal border
    final sealBorder = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0xFF8B0000).withOpacity(0.6);
    canvas.drawPath(heartPath, sealBorder);

    // Tiny shine on seal
    final shine = Paint()..color = Colors.white.withOpacity(0.35);
    canvas.drawCircle(
      sealCenter - Offset(w * 0.03, w * 0.04),
      w * 0.018,
      shine,
    );
  }

  Path _heartPath(Offset c, double r) {
    final path = Path();
    path.moveTo(c.dx, c.dy + r * 0.9);
    path.cubicTo(
      c.dx - r * 1.6, c.dy + r * 0.1,
      c.dx - r * 1.0, c.dy - r * 1.1,
      c.dx, c.dy - r * 0.3,
    );
    path.cubicTo(
      c.dx + r * 1.0, c.dy - r * 1.1,
      c.dx + r * 1.6, c.dy + r * 0.1,
      c.dx, c.dy + r * 0.9,
    );
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _EnvelopePainter old) =>
      old.color != color ||
      old.accent != accent ||
      old.glowPulse != glowPulse;
}

/// Floating hearts/petals background painter
class _FloatingHeartsPainter extends CustomPainter {
  final List<_FloatingHeart> hearts;
  final double progress;
  final Color accentColor;

  _FloatingHeartsPainter({
    required this.hearts,
    required this.progress,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final h in hearts) {
      final phase = (h.phase + progress * h.speed) % 1.0;
      final swing = sin(phase * 2 * pi + h.phase * 3) * 35;
      final x = (h.x * size.width + swing).clamp(-30.0, size.width + 30);
      final y = (1.0 - phase) * (size.height + 60) - 30;

      final color = h.colorIdx == 0
          ? accentColor
          : h.colorIdx == 1
              ? const Color(0xFFE879F9)
              : Colors.white;

      final opacity = (0.15 + 0.25 * (1 - (phase - 0.5).abs() * 2))
          .clamp(0.0, 0.45);

      // Glow
      final glow = Paint()
        ..color = color.withOpacity(opacity * 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(Offset(x, y), h.size * 1.6, glow);

      // Heart shape (small)
      final paint = Paint()..color = color.withOpacity(opacity);
      final path = Path();
      final r = h.size;
      path.moveTo(x, y + r * 0.9);
      path.cubicTo(x - r * 1.6, y + r * 0.1, x - r * 1.0, y - r * 1.1,
          x, y - r * 0.3);
      path.cubicTo(x + r * 1.0, y - r * 1.1, x + r * 1.6, y + r * 0.1,
          x, y + r * 0.9);
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FloatingHeartsPainter old) =>
      old.progress != progress || old.accentColor != accentColor;
}

class _FloatingHeart {
  final double x;
  final double size;
  final double speed;
  final double phase;
  final int colorIdx;

  _FloatingHeart(Random r)
      : x = r.nextDouble(),
        size = 2.5 + r.nextDouble() * 4.5,
        speed = 0.25 + r.nextDouble() * 0.55,
        phase = r.nextDouble(),
        colorIdx = r.nextInt(3);
}

/// Subtle ruled-paper lines for the note input.
class _RuledPaperPainter extends CustomPainter {
  final Color lineColor;

  _RuledPaperPainter({required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 0.8;
    const lineGap = 28.0;
    for (double y = lineGap; y < size.height; y += lineGap) {
      canvas.drawLine(Offset(16, y), Offset(size.width - 16, y), paint);
    }
    // Left margin line
    final marginPaint = Paint()
      ..color = const Color(0xFFE57373).withOpacity(0.25)
      ..strokeWidth = 1;
    canvas.drawLine(
      const Offset(36, 8),
      Offset(36, size.height - 8),
      marginPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RuledPaperPainter old) =>
      old.lineColor != lineColor;
}
