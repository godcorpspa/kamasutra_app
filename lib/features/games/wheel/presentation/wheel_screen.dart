import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/theme.dart';
import '../data/wheel_actions.dart';

class WheelScreen extends StatefulWidget {
  const WheelScreen({super.key});

  @override
  State<WheelScreen> createState() => _WheelScreenState();
}

class _WheelScreenState extends State<WheelScreen>
    with TickerProviderStateMixin {
  late AnimationController _spinController;
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late AnimationController _ledController;
  late Animation<double> _spinAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;

  double _currentRotation = 0;
  bool _isSpinning = false;
  String _intensity = 'spicy';
  int? _lastWinningIndex;
  int _spinCount = 0;
  final List<String> _history = [];

  final List<WheelSegment> _segments = [
    WheelSegment('Bacio\nProibito', '💋', const Color(0xFFE91E63), const Color(0xFFF48FB1)),
    WheelSegment('Massaggio\nErotico', '💆', const Color(0xFF9C27B0), const Color(0xFFCE93D8)),
    WheelSegment('Strip\nTease', '👙', const Color(0xFFFF9800), const Color(0xFFFFCC02)),
    WheelSegment('Posizione\nHot', '🔥', const Color(0xFFF44336), const Color(0xFFFF8A80)),
    WheelSegment('Gioco\ndi Ruolo', '🎭', const Color(0xFF7B1FA2), const Color(0xFFBA68C8)),
    WheelSegment('Desiderio\nSegreto', '✨', const Color(0xFF1565C0), const Color(0xFF64B5F6)),
    WheelSegment('Tocco\nSensuale', '🤚', const Color(0xFFD81B60), const Color(0xFFF8BBD0)),
    WheelSegment('Carta\nJolly', '🃏', const Color(0xFF00897B), const Color(0xFF80CBC4)),
  ];

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5500),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.9).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _ledController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _spinController.dispose();
    _pulseController.dispose();
    _glowController.dispose();
    _ledController.dispose();
    super.dispose();
  }

  void _spin() {
    if (_isSpinning) return;

    HapticFeedback.mediumImpact();

    setState(() {
      _isSpinning = true;
      _lastWinningIndex = null;
    });

    final random = Random();
    final extraSpins = 6 + random.nextInt(4);
    final targetSegment = random.nextInt(_segments.length);
    final segmentAngle = (2 * pi) / _segments.length;

    // Calculate the exact rotation so the pointer (fixed at top) lands
    // on the center of targetSegment.
    // Segments are drawn at startAngle = i * segmentAngle - π/2.
    // After rotating the wheel by θ, the pointer (at -π/2) points to
    // wheel-coordinate angle (-θ mod 2π). We need that to equal the
    // center of segment t: t * segmentAngle + segmentAngle/2.
    // So: θ mod 2π = (2π - t * segmentAngle - segmentAngle/2) mod 2π
    final desiredMod = (2 * pi - targetSegment * segmentAngle - segmentAngle / 2) % (2 * pi);
    final currentMod = _currentRotation % (2 * pi);
    double delta = desiredMod - currentMod;
    if (delta < 0) delta += 2 * pi;
    final targetAngle = extraSpins * 2 * pi + delta;

    _spinAnimation = Tween<double>(
      begin: _currentRotation,
      end: _currentRotation + targetAngle,
    ).animate(CurvedAnimation(
      parent: _spinController,
      curve: const _WheelSpinCurve(),
    ));

    _spinAnimation.addListener(() {
      setState(() {
        _currentRotation = _spinAnimation.value;
      });
      if (_spinController.value > 0.7) {
        final progress = (_spinController.value - 0.7) / 0.3;
        if (random.nextDouble() > progress * 0.8) {
          HapticFeedback.selectionClick();
        }
      }
    });

    _spinController.forward(from: 0).then((_) {
      HapticFeedback.heavyImpact();
      setState(() {
        _isSpinning = false;
        _lastWinningIndex = targetSegment;
        _spinCount++;
        final seg = _segments[targetSegment];
        _history.insert(0, '${seg.emoji} ${seg.name.replaceAll('\n', ' ')}');
        if (_history.length > 10) _history.removeLast();
      });
      _showResultDialog(targetSegment);
    });
  }

  void _showResultDialog(int segmentIndex) {
    final segment = _segments[segmentIndex];
    final action = _getActionForSegment(segment, _intensity);

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (_, __, ___) => const SizedBox(),
      transitionBuilder: (context, anim, secondaryAnim, child) {
        final curvedAnim = CurvedAnimation(
          parent: anim,
          curve: Curves.elasticOut,
        );
        return ScaleTransition(
          scale: curvedAnim,
          child: FadeTransition(
            opacity: anim,
            child: DefaultTextStyle(
              style: const TextStyle(decoration: TextDecoration.none),
              child: _ResultDialog(
                segment: segment,
                action: action,
                intensity: _intensity,
                spinCount: _spinCount,
                onSpinAgain: () {
                  Navigator.pop(context);
                  _spin();
                },
                onDone: () => Navigator.pop(context),
              ),
            ),
          ),
        );
      },
    );
  }

  String _getActionForSegment(WheelSegment segment, String intensity) {
    final key = segment.name.split('\n').first;
    return WheelActions.getAction(key, intensity);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final wheelSize = screenSize.width * 0.85;

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Ruota della Fortuna'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          if (_history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.history_rounded),
              onPressed: _showHistory,
              tooltip: 'Cronologia',
            ),
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            onPressed: _showRules,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A0A2E),
              Color(0xFF16213E),
              Color(0xFF0F3460),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 4),
              // Intensity selector
              _buildIntensitySelector(),

              // Spin counter
              if (_spinCount > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Giro #$_spinCount',
                    style: TextStyle(
                      color: AppColors.gold.withOpacity(0.6),
                      fontSize: 13,
                      fontFamily: AppTypography.bodyFont,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

              // Wheel area
              Expanded(
                child: Center(
                  child: SizedBox(
                    width: wheelSize + 40,
                    height: wheelSize + 60,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer glow
                        AnimatedBuilder(
                          animation: _glowAnimation,
                          builder: (context, child) {
                            return Container(
                              width: wheelSize + 30,
                              height: wheelSize + 30,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.gold.withOpacity(
                                        _glowAnimation.value * 0.4),
                                    blurRadius: 40,
                                    spreadRadius: 10,
                                  ),
                                  BoxShadow(
                                    color: AppColors.fuchsia.withOpacity(
                                        _glowAnimation.value * 0.2),
                                    blurRadius: 60,
                                    spreadRadius: 20,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        // The wheel with LED ring
                        AnimatedBuilder(
                          animation: _ledController,
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: _currentRotation,
                              child: CustomPaint(
                                size: Size(wheelSize, wheelSize),
                                painter: WheelPainter(
                                  segments: _segments,
                                  highlightIndex: _lastWinningIndex,
                                  ledPhase: _isSpinning ? _ledController.value : 0,
                                  isSpinning: _isSpinning,
                                ),
                              ),
                            );
                          },
                        ),

                        // Center button
                        _buildCenterButton(),

                        // Pointer at top
                        Positioned(
                          top: 0,
                          child: CustomPaint(
                            size: const Size(40, 50),
                            painter: PointerPainter(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom instruction
              _buildBottomInstruction(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntensitySelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildIntensityChip('soft', '🌸', 'Soft', const Color(0xFFFFB6C1)),
          _buildIntensityChip('spicy', '🌶️', 'Spicy', const Color(0xFFFF6B35)),
          _buildIntensityChip('extra_spicy', '🔥', 'Extra', const Color(0xFFDC143C)),
        ],
      ),
    );
  }

  Widget _buildIntensityChip(
      String value, String emoji, String label, Color color) {
    final isSelected = _intensity == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _intensity = value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [color, color.withOpacity(0.7)],
                )
              : null,
          borderRadius: BorderRadius.circular(26),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white60,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
                fontFamily: AppTypography.bodyFont,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterButton() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        final scale = _isSpinning ? 1.0 : _pulseAnimation.value;
        return Transform.scale(
          scale: scale,
          child: GestureDetector(
            onTap: _isSpinning ? null : _spin,
            child: Container(
              width: 85,
              height: 85,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: _isSpinning
                      ? [
                          const Color(0xFF2D1536),
                          const Color(0xFF1A0A1F),
                        ]
                      : [
                          const Color(0xFFFFD700),
                          const Color(0xFFD4A574),
                          const Color(0xFFB8860B),
                        ],
                  stops: _isSpinning ? null : const [0.0, 0.5, 1.0],
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (_isSpinning
                            ? AppColors.fuchsia
                            : AppColors.gold)
                        .withOpacity(0.5),
                    blurRadius: 25,
                    spreadRadius: 3,
                  ),
                  const BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: _isSpinning
                    ? const SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          color: AppColors.fuchsiaLight,
                          strokeWidth: 3,
                        ),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.touch_app_rounded,
                            color: Color(0xFF3E2723),
                            size: 26,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'GIRA',
                            style: TextStyle(
                              color: const Color(0xFF3E2723),
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              fontFamily: AppTypography.bodyFont,
                              letterSpacing: 2,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomInstruction() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(_isSpinning),
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isSpinning ? Icons.auto_awesome : Icons.touch_app_outlined,
              color: AppColors.gold,
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              _isSpinning
                  ? 'La ruota sta girando...'
                  : 'Tocca il centro per girare!',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 15,
                fontFamily: AppTypography.bodyFont,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHistory() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => DefaultTextStyle(
        style: const TextStyle(decoration: TextDecoration.none),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF2D1536), Color(0xFF1A0A2E)],
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Icon(Icons.history_rounded, color: AppColors.gold, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'Cronologia (${ _spinCount} giri)',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: AppTypography.displayFont,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ..._history.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = entry.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '${_spinCount - idx}',
                            style: TextStyle(
                              color: AppColors.gold.withOpacity(0.7),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              fontFamily: AppTypography.bodyFont,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        item,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 15,
                          fontFamily: AppTypography.bodyFont,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showRules() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DefaultTextStyle(
        style: const TextStyle(decoration: TextDecoration.none),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF2D1536), Color(0xFF1A0A2E)],
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('🎡', style: TextStyle(fontSize: 24)),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'Come si gioca',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      fontFamily: AppTypography.displayFont,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildRuleItem('Scegli l\'intensità: Soft, Spicy o Extra 🔥', Icons.tune_rounded),
              _buildRuleItem('Tocca il centro della ruota per farla girare', Icons.touch_app_rounded),
              _buildRuleItem('Esegui l\'azione indicata con il partner', Icons.favorite_rounded),
              _buildRuleItem('Potete sempre saltare e rigirare la ruota', Icons.refresh_rounded),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.fuchsia.withOpacity(0.15),
                      AppColors.fuchsia.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.fuchsia.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Text('💕', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Ricorda: il consenso viene prima di tutto!\nDivertitevi in sicurezza.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontStyle: FontStyle.italic,
                          fontSize: 14,
                          fontFamily: AppTypography.bodyFont,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRuleItem(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.gold.withOpacity(0.3),
                  AppColors.gold.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(child: Icon(icon, color: AppColors.gold, size: 18)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 15,
                fontFamily: AppTypography.bodyFont,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom spin curve: fast start, dramatic slowdown at end
class _WheelSpinCurve extends Curve {
  const _WheelSpinCurve();

  @override
  double transformInternal(double t) {
    return 1 - pow(1 - t, 4).toDouble();
  }
}

// ============================================
// Result Dialog — with confetti-like particles
// ============================================
class _ResultDialog extends StatefulWidget {
  final WheelSegment segment;
  final String action;
  final String intensity;
  final int spinCount;
  final VoidCallback onSpinAgain;
  final VoidCallback onDone;

  const _ResultDialog({
    required this.segment,
    required this.action,
    required this.intensity,
    required this.spinCount,
    required this.onSpinAgain,
    required this.onDone,
  });

  @override
  State<_ResultDialog> createState() => _ResultDialogState();
}

class _ResultDialogState extends State<_ResultDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _particleController;
  late List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    final random = Random();
    _particles = List.generate(20, (_) => _Particle(random));

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..forward();
  }

  @override
  void dispose() {
    _particleController.dispose();
    super.dispose();
  }

  String get _intensityLabel {
    switch (widget.intensity) {
      case 'soft':
        return '🌸 Soft';
      case 'spicy':
        return '🌶️ Spicy';
      case 'extra_spicy':
        return '🔥 Extra Hot';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = widget.segment.name.replaceAll('\n', ' ');

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Confetti particles
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, child) {
              return CustomPaint(
                size: const Size(350, 500),
                painter: _ParticlePainter(
                  particles: _particles,
                  progress: _particleController.value,
                  color: widget.segment.color,
                ),
              );
            },
          ),

          // Dialog card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2D1536), Color(0xFF1A0A2E)],
              ),
              border: Border.all(
                color: widget.segment.color.withOpacity(0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.segment.color.withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
                const BoxShadow(
                  color: Colors.black26,
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        widget.segment.color.withOpacity(0.35),
                        widget.segment.colorSecondary.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(26),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Emoji with glow
                      Container(
                        width: 90, height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              widget.segment.color.withOpacity(0.3),
                              widget.segment.color.withOpacity(0.05),
                            ],
                          ),
                          border: Border.all(
                            color: widget.segment.color.withOpacity(0.4),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: widget.segment.color.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            widget.segment.emoji,
                            style: const TextStyle(
                              fontSize: 44,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        displayName.toUpperCase(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          fontFamily: AppTypography.displayFont,
                          letterSpacing: 3,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _intensityLabel,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 12,
                                fontFamily: AppTypography.bodyFont,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Giro #${widget.spinCount}',
                              style: TextStyle(
                                color: AppColors.gold.withOpacity(0.8),
                                fontSize: 12,
                                fontFamily: AppTypography.bodyFont,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Action description
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Text(
                      widget.action,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                        height: 1.5,
                        fontFamily: AppTypography.bodyFont,
                        decoration: TextDecoration.none,
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

                // Buttons
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: widget.onSpinAgain,
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Gira ancora'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white70,
                            side: BorderSide(
                                color: Colors.white.withOpacity(0.2)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: widget.onDone,
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: const Text('Fatto!'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.segment.color,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 6,
                            shadowColor: widget.segment.color.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// Confetti particle system
// ============================================
class _Particle {
  final double x;        // -1..1 horizontal spread
  final double speed;    // fall speed multiplier
  final double size;
  final double rotation;
  final int colorIndex;  // 0 = segment, 1 = gold, 2 = white

  _Particle(Random r)
      : x = r.nextDouble() * 2 - 1,
        speed = 0.3 + r.nextDouble() * 0.7,
        size = 3 + r.nextDouble() * 5,
        rotation = r.nextDouble() * 2 * pi,
        colorIndex = r.nextInt(3);
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final Color color;

  _ParticlePainter({
    required this.particles,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final opacity = (1 - progress).clamp(0.0, 1.0);
      if (opacity <= 0) continue;

      final colors = [color, const Color(0xFFFFD700), Colors.white];
      final paint = Paint()
        ..color = colors[p.colorIndex].withOpacity(opacity * 0.8);

      // Particles fly upward then fall
      final yProgress = progress * p.speed;
      final yOffset = -200 * yProgress + 300 * yProgress * yProgress;
      final xOffset = p.x * 150 * progress;

      final pos = Offset(
        size.width / 2 + xOffset,
        size.height / 2 + yOffset,
      );

      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(p.rotation + progress * 6);
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
  bool shouldRepaint(covariant _ParticlePainter old) =>
      progress != old.progress;
}

// ============================================
// Data model
// ============================================
class WheelSegment {
  final String name;
  final String emoji;
  final Color color;
  final Color colorSecondary;

  WheelSegment(this.name, this.emoji, this.color, this.colorSecondary);
}

// ============================================
// Wheel Painter — Premium with LED lights
// ============================================
class WheelPainter extends CustomPainter {
  final List<WheelSegment> segments;
  final int? highlightIndex;
  final double ledPhase;
  final bool isSpinning;

  WheelPainter({
    required this.segments,
    this.highlightIndex,
    this.ledPhase = 0,
    this.isSpinning = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final segmentAngle = (2 * pi) / segments.length;

    // --- Outer decorative ring shadow ---
    final outerShadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(center + const Offset(0, 4), radius + 6, outerShadowPaint);

    // --- Draw segments with gradients ---
    for (int i = 0; i < segments.length; i++) {
      final startAngle = i * segmentAngle - pi / 2;

      // Gradient fill
      final segRect = Rect.fromCircle(center: center, radius: radius);
      final gradient = ui.Gradient.sweep(
        center,
        [
          segments[i].color,
          segments[i].colorSecondary,
          segments[i].color,
        ],
        [0.0, 0.5, 1.0],
        TileMode.clamp,
        startAngle,
        startAngle + segmentAngle,
      );

      final segPaint = Paint()
        ..shader = gradient
        ..style = PaintingStyle.fill;

      canvas.drawArc(segRect, startAngle, segmentAngle, true, segPaint);

      // Inner highlight
      final highlightPaint = Paint()
        ..shader = ui.Gradient.radial(
          center + Offset.fromDirection(startAngle + segmentAngle / 2, radius * 0.3),
          radius * 0.7,
          [
            Colors.white.withOpacity(0.18),
            Colors.transparent,
          ],
        )
        ..style = PaintingStyle.fill;
      canvas.drawArc(segRect, startAngle, segmentAngle, true, highlightPaint);

      // Segment divider lines
      final dividerPaint = Paint()
        ..color = Colors.white.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      final lineEnd = center + Offset.fromDirection(startAngle, radius);
      canvas.drawLine(center, lineEnd, dividerPaint);

      // --- Draw name + emoji (name ABOVE emoji) ---
      _drawSegmentContent(canvas, center, radius, startAngle, segmentAngle, i);
    }

    // --- Outer golden rim ---
    _drawOuterRim(canvas, center, radius);

    // --- Inner circle (hub background) ---
    _drawInnerHub(canvas, center, radius);

    // --- Decorative dots/lights around edge ---
    _drawEdgeLights(canvas, center, radius);
  }

  void _drawSegmentContent(Canvas canvas, Offset center, double radius,
      double startAngle, double segmentAngle, int index) {
    final midAngle = startAngle + segmentAngle / 2;

    // Name (outer — above emoji, where there is more space)
    final nameRadius = radius * 0.72;
    final namePos = center + Offset.fromDirection(midAngle, nameRadius);

    canvas.save();
    canvas.translate(namePos.dx, namePos.dy);
    canvas.rotate(midAngle + pi / 2);

    final namePainter = TextPainter(
      text: TextSpan(
        text: segments[index].name.replaceAll('\n', '\n'),
        style: TextStyle(
          fontSize: 9.5,
          color: Colors.white.withOpacity(0.95),
          fontWeight: FontWeight.w800,
          fontFamily: AppTypography.bodyFont,
          letterSpacing: 0.3,
          height: 1.15,
          shadows: const [
            Shadow(color: Colors.black87, blurRadius: 5),
            Shadow(color: Colors.black54, blurRadius: 2, offset: Offset(0, 1)),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    namePainter.layout();
    namePainter.paint(
      canvas,
      Offset(-namePainter.width / 2, -namePainter.height / 2),
    );
    canvas.restore();

    // Emoji (inner — below name, closer to center)
    final emojiRadius = radius * 0.46;
    final emojiPos = center + Offset.fromDirection(midAngle, emojiRadius);

    canvas.save();
    canvas.translate(emojiPos.dx, emojiPos.dy);
    canvas.rotate(midAngle + pi / 2);

    final emojiPainter = TextPainter(
      text: TextSpan(
        text: segments[index].emoji,
        style: const TextStyle(fontSize: 22),
      ),
      textDirection: TextDirection.ltr,
    );
    emojiPainter.layout();
    emojiPainter.paint(
      canvas,
      Offset(-emojiPainter.width / 2, -emojiPainter.height / 2),
    );
    canvas.restore();
  }

  void _drawOuterRim(Canvas canvas, Offset center, double radius) {
    // Outer golden ring with sweep gradient
    final outerRingPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..shader = ui.Gradient.sweep(
        center,
        [
          const Color(0xFFD4A574),
          const Color(0xFFFFD700),
          const Color(0xFFB8860B),
          const Color(0xFFFFD700),
          const Color(0xFFD4A574),
        ],
        [0.0, 0.25, 0.5, 0.75, 1.0],
      );
    canvas.drawCircle(center, radius + 3, outerRingPaint);

    // Inner accent ring
    final innerRingPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Colors.white.withOpacity(0.35);
    canvas.drawCircle(center, radius - 1, innerRingPaint);

    // Outermost thin bright edge
    final outerEdgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = const Color(0xFFFFD700).withOpacity(0.6);
    canvas.drawCircle(center, radius + 10, outerEdgePaint);
  }

  void _drawInnerHub(Canvas canvas, Offset center, double radius) {
    final hubRadius = radius * 0.18;

    // Hub shadow
    canvas.drawCircle(
      center + const Offset(0, 2),
      hubRadius + 4,
      Paint()
        ..color = Colors.black.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Hub ring
    final hubRingPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..shader = ui.Gradient.sweep(
        center,
        [
          const Color(0xFFFFD700),
          const Color(0xFFB8860B),
          const Color(0xFFFFD700),
        ],
        [0.0, 0.5, 1.0],
      );
    canvas.drawCircle(center, hubRadius, hubRingPaint);
  }

  void _drawEdgeLights(Canvas canvas, Offset center, double radius) {
    final lightCount = segments.length * 3; // 24 lights
    for (int i = 0; i < lightCount; i++) {
      final angle = (2 * pi / lightCount) * i - pi / 2;
      final pos = center + Offset.fromDirection(angle, radius + 3);

      final isHighlight = i % 3 == 0;

      // Alternate LED colors during spin
      double opacity;
      Color dotColor;
      double dotRadius;

      if (isSpinning) {
        // Alternate on/off based on ledPhase
        final isOn = (i % 2 == 0) ? ledPhase > 0.5 : ledPhase <= 0.5;
        opacity = isOn ? 1.0 : 0.2;
        dotColor = isOn
            ? (isHighlight ? const Color(0xFFFFD700) : Colors.white)
            : Colors.white24;
        dotRadius = isHighlight ? 4.0 : 2.5;
      } else {
        opacity = isHighlight ? 0.9 : 0.5;
        dotColor = isHighlight ? const Color(0xFFFFD700) : Colors.white;
        dotRadius = isHighlight ? 3.5 : 2.0;
      }

      canvas.drawCircle(pos, dotRadius, Paint()..color = dotColor.withOpacity(opacity));

      if ((isHighlight && !isSpinning) || (isSpinning && opacity > 0.5)) {
        canvas.drawCircle(
          pos,
          dotRadius + 4,
          Paint()
            ..color = const Color(0xFFFFD700).withOpacity(isSpinning ? 0.35 : 0.2)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant WheelPainter oldDelegate) =>
      highlightIndex != oldDelegate.highlightIndex ||
      ledPhase != oldDelegate.ledPhase ||
      isSpinning != oldDelegate.isSpinning;
}

// ============================================
// Pointer Painter — Gem shape
// ============================================
class PointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;

    // Drop shadow
    final shadowPath = Path()
      ..moveTo(centerX, size.height)
      ..lineTo(centerX - 12, 8)
      ..lineTo(centerX - 8, 0)
      ..lineTo(centerX + 8, 0)
      ..lineTo(centerX + 12, 8)
      ..close();

    canvas.drawPath(
      shadowPath.shift(const Offset(0, 3)),
      Paint()
        ..color = Colors.black.withOpacity(0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Main gem shape
    final gemPath = Path()
      ..moveTo(centerX, size.height)
      ..lineTo(centerX - 14, 10)
      ..lineTo(centerX - 10, 0)
      ..lineTo(centerX + 10, 0)
      ..lineTo(centerX + 14, 10)
      ..close();

    // Gold gradient
    final gemPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(centerX, 0),
        Offset(centerX, size.height),
        [
          const Color(0xFFFFD700),
          const Color(0xFFD4A574),
          const Color(0xFFB8860B),
        ],
        [0.0, 0.4, 1.0],
      );
    canvas.drawPath(gemPath, gemPaint);

    // Left facet highlight
    final leftFacet = Path()
      ..moveTo(centerX, size.height)
      ..lineTo(centerX - 14, 10)
      ..lineTo(centerX - 10, 0)
      ..lineTo(centerX, 0)
      ..lineTo(centerX, 10)
      ..close();
    canvas.drawPath(leftFacet, Paint()..color = Colors.white.withOpacity(0.2));

    // Top shine
    final shinePath = Path()
      ..moveTo(centerX - 6, 2)
      ..lineTo(centerX + 2, 2)
      ..lineTo(centerX, 6)
      ..close();
    canvas.drawPath(shinePath, Paint()..color = Colors.white.withOpacity(0.5));

    // Border
    canvas.drawPath(
      gemPath,
      Paint()
        ..color = const Color(0xFFFFD700).withOpacity(0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Glow at bottom tip
    canvas.drawCircle(
      Offset(centerX, size.height - 2),
      5,
      Paint()
        ..color = const Color(0xFFFFD700).withOpacity(0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
