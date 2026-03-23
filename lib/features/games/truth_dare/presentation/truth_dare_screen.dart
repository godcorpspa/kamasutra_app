import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../../../data/models/game.dart';
import '../data/truth_dare_actions.dart';

/// Truth or Dare game screen - Obbligo o Verità
class TruthDareScreen extends ConsumerStatefulWidget {
  const TruthDareScreen({super.key});

  @override
  ConsumerState<TruthDareScreen> createState() => _TruthDareScreenState();
}

class _TruthDareScreenState extends ConsumerState<TruthDareScreen>
    with TickerProviderStateMixin {
  GameIntensity _intensity = GameIntensity.soft;
  bool _gameStarted = false;
  int _currentPlayer = 1;
  String? _currentCard;
  bool? _isTruth;
  int _round = 1;

  late AnimationController _pulseController;
  late AnimationController _glowController;
  late AnimationController _cardFlipController;
  late AnimationController _bgParticleController;
  late AnimationController _shimmerController;

  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _cardFlipAnimation;

  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _cardFlipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _cardFlipAnimation = CurvedAnimation(
      parent: _cardFlipController,
      curve: Curves.easeOutBack,
    );

    _bgParticleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    )..repeat();

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _glowController.dispose();
    _cardFlipController.dispose();
    _bgParticleController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  String _intensityKey(GameIntensity intensity) {
    switch (intensity) {
      case GameIntensity.soft:
        return 'soft';
      case GameIntensity.spicy:
        return 'spicy';
      case GameIntensity.extraSpicy:
        return 'extra_spicy';
    }
  }

  void _selectTruthOrDare(bool isTruth) {
    HapticFeedback.mediumImpact();

    final key = _intensityKey(_intensity);
    final card = isTruth
        ? TruthDareActions.getTruth(key)
        : TruthDareActions.getDare(key);

    setState(() {
      _isTruth = isTruth;
      _currentCard = card;
    });

    _cardFlipController.forward(from: 0);
  }

  void _nextTurn() {
    HapticFeedback.lightImpact();
    setState(() {
      _currentCard = null;
      _isTruth = null;
      _currentPlayer = _currentPlayer == 1 ? 2 : 1;
      _round++;
    });
  }

  void _skipCard() {
    HapticFeedback.lightImpact();
    _selectTruthOrDare(_isTruth!);
  }

  Color _getIntensityColor(GameIntensity intensity) {
    switch (intensity) {
      case GameIntensity.soft:
        return const Color(0xFFFF69B4);
      case GameIntensity.spicy:
        return const Color(0xFFFF6B35);
      case GameIntensity.extraSpicy:
        return const Color(0xFFDC143C);
    }
  }

  String _getIntensityEmoji(GameIntensity intensity) {
    switch (intensity) {
      case GameIntensity.soft:
        return '🌸';
      case GameIntensity.spicy:
        return '🔥';
      case GameIntensity.extraSpicy:
        return '🌶️';
    }
  }

  String _getIntensityLabel(GameIntensity intensity) {
    switch (intensity) {
      case GameIntensity.soft:
        return 'truth_dare_ui.intensity_soft'.tr();
      case GameIntensity.spicy:
        return 'truth_dare_ui.intensity_spicy'.tr();
      case GameIntensity.extraSpicy:
        return 'truth_dare_ui.intensity_extra'.tr();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
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
                'truth_dare_ui.title'.tr(),
                style: TextStyle(
                  fontFamily: 'PlayfairDisplay',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  decoration: TextDecoration.none,
                ),
              ),
      ),
      body: AnimatedBuilder(
        animation: _bgParticleController,
        builder: (context, child) {
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1A0A2E),
                  Color(0xFF16213E),
                  Color(0xFF0F3460),
                  Color(0xFF1A0A2E),
                ],
                stops: [0.0, 0.3, 0.7, 1.0],
              ),
            ),
            child: Stack(
              children: [
                // Floating particles background
                CustomPaint(
                  painter: _FloatingParticlesPainter(
                    progress: _bgParticleController.value,
                    color: _getIntensityColor(_intensity),
                  ),
                  size: Size.infinite,
                ),
                // Main content
                SafeArea(
                  child: _gameStarted ? _buildGameView() : _buildSetupView(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSetupView() {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseController, _glowController]),
      builder: (context, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Animated title icon
              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _getIntensityColor(_intensity).withOpacity(0.6),
                        _getIntensityColor(_intensity).withOpacity(0.1),
                        Colors.transparent,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _getIntensityColor(_intensity)
                            .withOpacity(0.4 * _glowAnimation.value),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      '🎭',
                      style: TextStyle(fontSize: 50),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Subtitle
              Text(
                'truth_dare_ui.subtitle_setup'.tr(),
                style: TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 15,
                  color: Colors.white.withOpacity(0.6),
                  fontStyle: FontStyle.italic,
                  decoration: TextDecoration.none,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // Intensity selector label
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.local_fire_department,
                    color: _getIntensityColor(_intensity),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'truth_dare_ui.choose_intensity'.tr(),
                    style: TextStyle(
                      fontFamily: 'PlayfairDisplay',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Intensity cards
              ...GameIntensity.values.map((intensity) {
                final isSelected = _intensity == intensity;
                final color = _getIntensityColor(intensity);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _intensity = intensity);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 20),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                colors: [
                                  color.withOpacity(0.3),
                                  color.withOpacity(0.1),
                                ],
                              )
                            : LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.05),
                                  Colors.white.withOpacity(0.02),
                                ],
                              ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? color.withOpacity(0.8)
                              : Colors.white.withOpacity(0.1),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withOpacity(
                                      0.3 * _glowAnimation.value),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        children: [
                          Text(
                            _getIntensityEmoji(intensity),
                            style: const TextStyle(fontSize: 32),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getIntensityLabel(intensity),
                                  style: TextStyle(
                                    fontFamily: 'PlayfairDisplay',
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected
                                        ? color
                                        : Colors.white.withOpacity(0.8),
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _getIntensityDescription(intensity),
                                  style: TextStyle(
                                    fontFamily: 'DMSans',
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.5),
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(Icons.check_circle, color: color, size: 24),
                        ],
                      ),
                    ),
                  ),
                );
              }),

              const SizedBox(height: 30),

              // How to play
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline,
                            color: Colors.white.withOpacity(0.5), size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'truth_dare_ui.how_to_play'.tr(),
                          style: TextStyle(
                            fontFamily: 'DMSans',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.7),
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildRuleRow('1', 'truth_dare_ui.rule_1'.tr()),
                    const SizedBox(height: 8),
                    _buildRuleRow('2', 'truth_dare_ui.rule_2'.tr()),
                    const SizedBox(height: 8),
                    _buildRuleRow('3', 'truth_dare_ui.rule_3'.tr()),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Start button
              GestureDetector(
                onTap: () {
                  HapticFeedback.heavyImpact();
                  setState(() => _gameStarted = true);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getIntensityColor(_intensity),
                        _getIntensityColor(_intensity).withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: _getIntensityColor(_intensity).withOpacity(0.5),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_arrow_rounded,
                          color: Colors.white, size: 28),
                      SizedBox(width: 8),
                      Text(
                        'truth_dare_ui.start_game'.tr(),
                        style: TextStyle(
                          fontFamily: 'DMSans',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 1.5,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRuleRow(String number, String text) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _getIntensityColor(_intensity).withOpacity(0.3),
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                fontFamily: 'DMSans',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _getIntensityColor(_intensity),
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
              color: Colors.white.withOpacity(0.6),
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ],
    );
  }

  String _getIntensityDescription(GameIntensity intensity) {
    switch (intensity) {
      case GameIntensity.soft:
        return 'truth_dare_ui.desc_soft'.tr();
      case GameIntensity.spicy:
        return 'truth_dare_ui.desc_spicy'.tr();
      case GameIntensity.extraSpicy:
        return 'truth_dare_ui.desc_extra'.tr();
    }
  }

  Widget _buildGameView() {
    return Column(
      children: [
        // Player & round indicator
        _buildPlayerIndicator(),

        Expanded(
          child: _currentCard == null
              ? _buildChoiceView()
              : _buildCardView(),
        ),
      ],
    );
  }

  Widget _buildPlayerIndicator() {
    final isPlayer1 = _currentPlayer == 1;
    final playerColor =
        isPlayer1 ? const Color(0xFFE879F9) : const Color(0xFFFFD700);

    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                playerColor.withOpacity(0.15),
                playerColor.withOpacity(0.05),
                playerColor.withOpacity(0.15),
              ],
              stops: [
                0.0,
                _shimmerController.value,
                1.0,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: playerColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          playerColor,
                          playerColor.withOpacity(0.5),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: playerColor.withOpacity(0.5),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        isPlayer1 ? '👩' : '👨',
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'truth_dare_ui.player_n'.tr(namedArgs: {'n': '$_currentPlayer'}),
                    style: TextStyle(
                      fontFamily: 'PlayfairDisplay',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: playerColor,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'truth_dare_ui.round_n'.tr(namedArgs: {'n': '$_round'}),
                  style: TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.6),
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChoiceView() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'truth_dare_ui.what_choose'.tr(),
                style: TextStyle(
                  fontFamily: 'PlayfairDisplay',
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withOpacity(0.9),
                  decoration: TextDecoration.none,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'truth_dare_ui.tap_card'.tr(),
                style: TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.5),
                  decoration: TextDecoration.none,
                ),
              ),

              const SizedBox(height: 40),

              Row(
                children: [
                  // VERITÀ card
                  Expanded(
                    child: _buildChoiceCard(
                      label: 'truth_dare_ui.truth'.tr(),
                      emoji: '💬',
                      subtitle: 'truth_dare_ui.truth_sub'.tr(),
                      gradient: const [Color(0xFF6B2D5B), Color(0xFF8B4078)],
                      glowColor: const Color(0xFFE879F9),
                      onTap: () => _selectTruthOrDare(true),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // OBBLIGO card
                  Expanded(
                    child: _buildChoiceCard(
                      label: 'truth_dare_ui.dare'.tr(),
                      emoji: '🎯',
                      subtitle: 'truth_dare_ui.dare_sub'.tr(),
                      gradient: const [Color(0xFFC62828), Color(0xFFE53935)],
                      glowColor: const Color(0xFFFF6B35),
                      onTap: () => _selectTruthOrDare(false),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // End game button
              TextButton.icon(
                onPressed: () => context.pop(),
                icon: Icon(Icons.exit_to_app,
                    color: Colors.white.withOpacity(0.4), size: 18),
                label: Text(
                  'truth_dare_ui.end_game'.tr(),
                  style: TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.4),
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChoiceCard({
    required String label,
    required String emoji,
    required String subtitle,
    required List<Color> gradient,
    required Color glowColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ScaleTransition(
        scale: _pulseAnimation,
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradient,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: glowColor.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: glowColor.withOpacity(0.3 * _glowAnimation.value),
                blurRadius: 25,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'PlayfairDisplay',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 2,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
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
        ),
      ),
    );
  }

  Widget _buildCardView() {
    final isTruth = _isTruth!;
    final cardColor =
        isTruth ? const Color(0xFF6B2D5B) : const Color(0xFFC62828);
    final accentColor =
        isTruth ? const Color(0xFFE879F9) : const Color(0xFFFF6B35);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Spacer(),

          // Main card
          ScaleTransition(
            scale: _cardFlipAnimation,
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 250),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    cardColor,
                    cardColor.withOpacity(0.8),
                    cardColor.withOpacity(0.6),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: accentColor.withOpacity(0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withOpacity(0.4),
                    blurRadius: 30,
                    spreadRadius: 2,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: cardColor.withOpacity(0.6),
                    blurRadius: 60,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Card type header
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: accentColor.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isTruth ? '💬' : '🎯',
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isTruth ? 'truth_dare_ui.truth'.tr() : 'truth_dare_ui.dare'.tr(),
                          style: TextStyle(
                            fontFamily: 'PlayfairDisplay',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: accentColor,
                            letterSpacing: 2,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Divider with glow
                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          accentColor.withOpacity(0.5),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Card text
                  Text(
                    _currentCard!,
                    style: const TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      height: 1.6,
                      decoration: TextDecoration.none,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 20),

                  // Intensity badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getIntensityColor(_intensity).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_getIntensityEmoji(_intensity)} ${_getIntensityLabel(_intensity)}',
                      style: TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 11,
                        color: _getIntensityColor(_intensity),
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Spacer(),

          // Action buttons
          Row(
            children: [
              // Skip button
              Expanded(
                child: GestureDetector(
                  onTap: _skipCard,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.15),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.refresh,
                            color: Colors.white.withOpacity(0.6), size: 20),
                        const SizedBox(width: 6),
                        Text(
                          'truth_dare_ui.change'.tr(),
                          style: TextStyle(
                            fontFamily: 'DMSans',
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.6),
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Done button
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: _nextTurn,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [accentColor, accentColor.withOpacity(0.7)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withOpacity(0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_rounded,
                            color: Colors.white, size: 22),
                        SizedBox(width: 6),
                        Text(
                          'truth_dare_ui.done_next'.tr(),
                          style: TextStyle(
                            fontFamily: 'DMSans',
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
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

          const SizedBox(height: 12),

          // End game
          TextButton.icon(
            onPressed: () => context.pop(),
            icon: Icon(Icons.exit_to_app,
                color: Colors.white.withOpacity(0.4), size: 16),
            label: Text(
              'Termina partita',
              style: TextStyle(
                fontFamily: 'DMSans',
                fontSize: 13,
                color: Colors.white.withOpacity(0.4),
                decoration: TextDecoration.none,
              ),
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// Floating particles background painter
class _FloatingParticlesPainter extends CustomPainter {
  final double progress;
  final Color color;

  _FloatingParticlesPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final random = Random(42);

    for (int i = 0; i < 30; i++) {
      final x = random.nextDouble() * size.width;
      final baseY = random.nextDouble() * size.height;
      final speed = 0.3 + random.nextDouble() * 0.7;
      final y = (baseY - progress * size.height * speed) % size.height;
      final radius = 1.0 + random.nextDouble() * 2.5;
      final opacity = 0.1 + random.nextDouble() * 0.2;

      paint.color = color.withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }

    // Subtle gradient orbs
    for (int i = 0; i < 5; i++) {
      final x = random.nextDouble() * size.width;
      final baseY = random.nextDouble() * size.height;
      final phase = (progress + i * 0.2) % 1.0;
      final y = (baseY + sin(phase * 2 * pi) * 30) % size.height;
      final orbRadius = 30.0 + random.nextDouble() * 40;

      final gradient = ui.Gradient.radial(
        Offset(x, y),
        orbRadius,
        [
          color.withOpacity(0.06),
          Colors.transparent,
        ],
      );
      paint.shader = gradient;
      canvas.drawCircle(Offset(x, y), orbRadius, paint);
    }
    paint.shader = null;
  }

  @override
  bool shouldRepaint(covariant _FloatingParticlesPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
