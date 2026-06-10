import 'dart:math';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';


class IntimacyMapScreen extends StatefulWidget {
  const IntimacyMapScreen({super.key});

  @override
  State<IntimacyMapScreen> createState() => _IntimacyMapScreenState();
}

class _IntimacyMapScreenState extends State<IntimacyMapScreen>
    with TickerProviderStateMixin {
  // ---------------------------------------------------------------------------
  // Game state
  // ---------------------------------------------------------------------------
  bool _gameStarted = false;
  bool _showingReveal = false;
  String _mode = 'private'; // 'together' or 'private'
  int _currentPlayer = 1;
  String _selectedView = 'front';

  final Map<String, String> _player1Map = {}; // partId → touchTypeId
  final Map<String, String> _player2Map = {};

  // ---------------------------------------------------------------------------
  // Animations
  // ---------------------------------------------------------------------------
  late final AnimationController _bgController;
  late final AnimationController _glow;
  late final AnimationController _shimmer;
  late final AnimationController _pointsPulse;
  late final AnimationController _entry;
  late final AnimationController _revealAnim;

  late Animation<double> _glowAnim;
  late Animation<double> _entryAnim;

  final List<_Particle> _particles =
      List.generate(40, (i) => _Particle(Random(i * 13 + 9)));

  final Random _random = Random();

  // ---------------------------------------------------------------------------
  // Static data
  // ---------------------------------------------------------------------------
  List<Map<String, dynamic>> get _touchTypes => const [
        {'id': 'love', 'emoji': '💕', 'color': Color(0xFFE53935)},
        {'id': 'like', 'emoji': '💜', 'color': Color(0xFF8B5CF6)},
        {'id': 'sensitive', 'emoji': '✨', 'color': Color(0xFFFFD166)},
        {'id': 'ticklish', 'emoji': '🤭', 'color': Color(0xFF6EE7B7)},
        {'id': 'neutral', 'emoji': '😐', 'color': Color(0xFF9CA3AF)},
        {'id': 'avoid', 'emoji': '🚫', 'color': Color(0xFFEF4444)},
      ];

  Map<String, dynamic>? _touchTypeData(String? id) {
    if (id == null) return null;
    return _touchTypes.firstWhere((t) => t['id'] == id,
        orElse: () => _touchTypes.first);
  }

  List<Map<String, dynamic>> get _bodyPartsFront => const [
        {'id': 'forehead', 'x': 0.5, 'y': 0.06},
        {'id': 'eyes', 'x': 0.5, 'y': 0.10},
        {'id': 'cheeks', 'x': 0.62, 'y': 0.13},
        {'id': 'lips', 'x': 0.5, 'y': 0.155},
        {'id': 'neck_front', 'x': 0.5, 'y': 0.21},
        {'id': 'shoulders', 'x': 0.30, 'y': 0.27},
        {'id': 'chest', 'x': 0.5, 'y': 0.33},
        {'id': 'arms', 'x': 0.18, 'y': 0.40},
        {'id': 'hands', 'x': 0.10, 'y': 0.55},
        {'id': 'stomach', 'x': 0.5, 'y': 0.46},
        {'id': 'hips', 'x': 0.62, 'y': 0.55},
        {'id': 'thighs_front', 'x': 0.42, 'y': 0.66},
        {'id': 'knees', 'x': 0.45, 'y': 0.78},
        {'id': 'calves_front', 'x': 0.55, 'y': 0.86},
        {'id': 'feet', 'x': 0.5, 'y': 0.95},
      ];

  List<Map<String, dynamic>> get _bodyPartsBack => const [
        {'id': 'head_back', 'x': 0.5, 'y': 0.08},
        {'id': 'neck_back', 'x': 0.5, 'y': 0.18},
        {'id': 'upper_back', 'x': 0.4, 'y': 0.30},
        {'id': 'lower_back', 'x': 0.55, 'y': 0.45},
        {'id': 'buttocks', 'x': 0.5, 'y': 0.56},
        {'id': 'thighs_back', 'x': 0.45, 'y': 0.70},
        {'id': 'calves_back', 'x': 0.5, 'y': 0.86},
      ];

  List<Map<String, dynamic>> get _allParts =>
      [..._bodyPartsFront, ..._bodyPartsBack];

  String _bodyName(String id) => 'games.intimacy_map.body_${_bodyKey(id)}'.tr();

  // Some body part keys differ from the part id
  String _bodyKey(String id) {
    switch (id) {
      case 'neck_front':
        return 'neck';
      case 'thighs_front':
        return 'thighs';
      case 'calves_front':
        return 'calves';
      case 'head_back':
        return 'nape';
      default:
        return id;
    }
  }

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

    _glow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _glowAnim = CurvedAnimation(parent: _glow, curve: Curves.easeInOut);

    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _pointsPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _entry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _entryAnim = CurvedAnimation(parent: _entry, curve: Curves.easeOutCubic);
    _entry.forward();

    _revealAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  @override
  void dispose() {
    _bgController.dispose();
    _glow.dispose();
    _shimmer.dispose();
    _pointsPulse.dispose();
    _entry.dispose();
    _revealAnim.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Game flow
  // ---------------------------------------------------------------------------
  void _startGame() {
    HapticFeedback.heavyImpact();
    setState(() {
      _gameStarted = true;
      _showingReveal = false;
      _currentPlayer = 1;
      _selectedView = 'front';
      _player1Map.clear();
      _player2Map.clear();
    });
    _entry.forward(from: 0);
  }

  void _passToOtherPlayer() {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A0A4A), Color(0xFF0A0F2C)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: const Color(0xFF7DD3FC).withOpacity(0.4)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🤫', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 8),
              Text(
                'games.intimacy_map.pass_phone'.tr(namedArgs: {
                  'player': '${_currentPlayer == 1 ? 2 : 1}',
                }),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'PlayfairDisplay',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'games.intimacy_map.pass_phone_hint'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: Colors.white.withOpacity(0.6),
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 18),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  HapticFeedback.mediumImpact();
                  setState(() {
                    _currentPlayer = _currentPlayer == 1 ? 2 : 1;
                    _selectedView = 'front';
                  });
                  _entry.forward(from: 0);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7DD3FC), Color(0xFFB388FF)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color:
                            const Color(0xFF7DD3FC).withOpacity(0.45),
                        blurRadius: 18,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'games.intimacy_map.ready'.tr(),
                      style: const TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 16,
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
      ),
    );
  }

  void _markPart(String partId, String touchType) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_currentPlayer == 1) {
        _player1Map[partId] = touchType;
      } else {
        _player2Map[partId] = touchType;
      }
    });
  }

  void _clearPart(String partId) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_currentPlayer == 1) {
        _player1Map.remove(partId);
      } else {
        _player2Map.remove(partId);
      }
    });
  }

  void _resetMaps() {
    HapticFeedback.heavyImpact();
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
              const Text('🗑️', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 10),
              Text(
                'games.intimacy_map.reset_maps'.tr(),
                style: const TextStyle(
                  fontFamily: 'PlayfairDisplay',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'games.intimacy_map.reset_confirm'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.7),
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
                              color: Colors.white.withOpacity(0.18)),
                        ),
                        child: Center(
                          child: Text(
                            'games.intimacy_map.cancel'.tr(),
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
                        setState(() {
                          _player1Map.clear();
                          _player2Map.clear();
                        });
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
                            'games.intimacy_map.reset'.tr(),
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

  void _reveal() {
    HapticFeedback.heavyImpact();
    setState(() => _showingReveal = true);
    _revealAnim.forward(from: 0);
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
        // Material 3 paints an opaque surfaceTint band over a transparent
        // AppBar on scroll; disable it so the bar blends with the game
        // background as designed.
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white70),
          onPressed: () {
            if (_showingReveal) {
              setState(() => _showingReveal = false);
            } else if (_gameStarted) {
              _confirmExit();
            } else {
              context.pop();
            }
          },
        ),
        title: !_gameStarted
            ? Text(
                'games.intimacy_map.title'.tr(),
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
            onPressed: _showInstructions,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Cosmic background
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
          // Main content
          SafeArea(
            // Defensive width clamp: the body can never be laid out wider
            // than the physical screen — even if an ancestor hands down
            // oversized or unbounded width constraints — which would
            // otherwise crop content and push it off the right edge.
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width,
              ),
              child: !_gameStarted
                  ? _buildSetupView()
                  : _showingReveal
                      ? _buildRevealView()
                      : _buildMapView(),
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
              const Text('🗺️', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text(
                'games.intimacy_map.exit_confirm'.tr(),
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
      padding: const EdgeInsets.fromLTRB(24, kToolbarHeight, 24, 24),
      child: Column(
        children: [
          const SizedBox(height: 6),
          // Header — animated body silhouette icon
          AnimatedBuilder(
            animation: Listenable.merge([_glowAnim, _pointsPulse]),
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
                            const Color(0xFFE879F9).withOpacity(
                                0.32 + 0.18 * _glowAnim.value),
                            const Color(0xFF7DD3FC).withOpacity(0.15),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 110,
                      height: 170,
                      child: CustomPaint(
                        painter: _MiniSilhouettePainter(
                          glow: _glowAnim.value,
                          dotsPulse: _pointsPulse.value,
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
            'games.intimacy_map.title'.tr(),
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
            'games.intimacy_map.subtitle'.tr(),
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

          // Mode selector
          _sectionLabel(
            icon: Icons.style,
            color: const Color(0xFFB388FF),
            label: 'games.intimacy_map.mode_label'.tr(),
          ),
          const SizedBox(height: 14),
          _modeCard(
            id: 'private',
            emoji: '🤫',
            label: 'games.intimacy_map.mode_private'.tr(),
            desc: 'games.intimacy_map.mode_private_desc'.tr(),
            color: const Color(0xFFB388FF),
          ),
          const SizedBox(height: 10),
          _modeCard(
            id: 'together',
            emoji: '🤝',
            label: 'games.intimacy_map.mode_together'.tr(),
            desc: 'games.intimacy_map.mode_together_desc'.tr(),
            color: const Color(0xFF7DD3FC),
          ),

          const SizedBox(height: 22),

          // Sensation legend
          _sectionLabel(
            icon: Icons.palette,
            color: const Color(0xFFFFD166),
            label: 'games.intimacy_map.sensation_types'.tr(),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _touchTypes.map((t) {
              final color = t['color'] as Color;
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withOpacity(0.25),
                      color.withOpacity(0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withOpacity(0.45)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(t['emoji'] as String,
                        style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      'games.intimacy_map.touch_${t['id']}'.tr(),
                      style: TextStyle(
                        fontFamily: 'DMSans',
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 22),

          // Features hint
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFB388FF).withOpacity(0.10),
                  const Color(0xFF7DD3FC).withOpacity(0.04),
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
                      'games.intimacy_map.features_title'.tr(),
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
                    _featureChip('🤫',
                        'games.intimacy_map.feature_private'.tr()),
                    _featureChip('💎',
                        'games.intimacy_map.feature_compatibility'.tr()),
                    _featureChip('🔥',
                        'games.intimacy_map.feature_heatmap'.tr()),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Start button — purple/cyan shimmer
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
                        Color(0xFF7DD3FC),
                        Color(0xFFB388FF),
                        Color(0xFF6B2D5B),
                      ],
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
                      const Icon(Icons.explore,
                          color: Colors.white, size: 24),
                      const SizedBox(width: 10),
                      Text(
                        'games.intimacy_map.start_exploration'.tr(),
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

  Widget _modeCard({
    required String id,
    required String emoji,
    required String label,
    required String desc,
    required Color color,
  }) {
    final isSelected = _mode == id;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _mode = id);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
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
                  colors: [color.withOpacity(0.6), color.withOpacity(0.15)],
                ),
                border: Border.all(color: color.withOpacity(0.6)),
              ),
              child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 22))),
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
            if (isSelected) Icon(Icons.check_circle, color: color, size: 22),
          ],
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
  // Map view (active marking)
  // ---------------------------------------------------------------------------
  Widget _buildMapView() {
    final color = _currentPlayer == 1
        ? const Color(0xFFE879F9)
        : const Color(0xFFFFD166);
    final currentMap = _currentPlayer == 1 ? _player1Map : _player2Map;
    final otherMap = _currentPlayer == 1 ? _player2Map : _player1Map;

    return AnimatedBuilder(
      animation: _entryAnim,
      builder: (context, child) {
        return Opacity(
          opacity: _entryAnim.value,
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - _entryAnim.value)),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, kToolbarHeight, 20, 16),
        child: Column(
          children: [
            // Top: player + view toggle
            Row(
              children: [
                Expanded(
                  child: AnimatedBuilder(
                    animation: _shimmer,
                    builder: (context, _) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
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
                          children: [
                            Container(
                              width: 26,
                              height: 26,
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
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'games.intimacy_map.partner_label'
                                        .tr(namedArgs: {
                                      'player': '$_currentPlayer',
                                    }),
                                    style: TextStyle(
                                      fontFamily: 'PlayfairDisplay',
                                      color: color,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                  Text(
                                    'games.intimacy_map.zones_marked'
                                        .tr(namedArgs: {
                                      'count': '${currentMap.length}',
                                      'total': '${_allParts.length}',
                                    }),
                                    style: TextStyle(
                                      fontFamily: 'DMSans',
                                      color:
                                          Colors.white.withOpacity(0.65),
                                      fontSize: 11,
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
                ),
              ],
            ),
            const SizedBox(height: 12),
            // View toggle
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Row(
                children: [
                  _viewToggleButton('front',
                      'games.intimacy_map.view_front'.tr(), '👤'),
                  _viewToggleButton('back',
                      'games.intimacy_map.view_back'.tr(), '🔙'),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Body map
            Expanded(
              child: _buildBodyMap(
                currentMap: currentMap,
                otherMap: _mode == 'together' ? otherMap : null,
              ),
            ),
            const SizedBox(height: 10),
            // Action row
            Row(
              children: [
                Expanded(
                  child: _bottomButton(
                    icon: Icons.refresh,
                    label: 'games.intimacy_map.reset'.tr(),
                    onTap: _resetMaps,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _bottomButton(
                    icon: Icons.swap_horiz,
                    label: 'games.intimacy_map.pass_btn'.tr(),
                    onTap: _passToOtherPlayer,
                    color: const Color(0xFF7DD3FC),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: AnimatedBuilder(
                    animation: _shimmer,
                    builder: (context, _) {
                      final ready = _player1Map.isNotEmpty &&
                          _player2Map.isNotEmpty;
                      return GestureDetector(
                        onTap: ready ? _reveal : null,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: ready ? 1 : 0.4,
                          child: Container(
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment(-1 + 2 * _shimmer.value, 0),
                                end: Alignment(1 + 2 * _shimmer.value, 0),
                                colors: const [
                                  Color(0xFF6B2D5B),
                                  Color(0xFFD946EF),
                                  Color(0xFFFFD166),
                                  Color(0xFFD946EF),
                                  Color(0xFF6B2D5B),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: ready
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFFD946EF)
                                            .withOpacity(0.45),
                                        blurRadius: 16,
                                        offset: const Offset(0, 5),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.auto_awesome,
                                    color: Colors.white, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  'games.intimacy_map.reveal'.tr(),
                                  style: const TextStyle(
                                    fontFamily: 'DMSans',
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.6,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ],
                            ),
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

  Widget _viewToggleButton(String view, String label, String emoji) {
    final isSelected = _selectedView == view;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedView = view);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFFB388FF), Color(0xFF6B2D5B)],
                  )
                : null,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 13)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'DMSans',
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withOpacity(0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'DMSans',
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBodyMap({
    required Map<String, String> currentMap,
    Map<String, String>? otherMap,
  }) {
    final parts = _selectedView == 'front' ? _bodyPartsFront : _bodyPartsBack;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableW = constraints.maxWidth;
          final availableH = constraints.maxHeight;
          // Body silhouette has a roughly 1:2 (W:H) aspect ratio.
          // Compute the largest box that fits and preserve it.
          const bodyAspect = 0.5;
          double boxW;
          double boxH;
          if (availableW / availableH > bodyAspect) {
            // Height-constrained
            boxH = availableH * 0.95;
            boxW = boxH * bodyAspect;
          } else {
            // Width-constrained
            boxW = availableW * 0.78;
            boxH = boxW / bodyAspect;
          }
          final boxLeft = (availableW - boxW) / 2;
          final boxTop = (availableH - boxH) / 2;

          return Stack(
            // Let edge touch-points (e.g. hands at x=0.10) and the partner
            // mini-dot (drawn at a negative offset) paint outside the box
            // instead of being clipped.
            clipBehavior: Clip.none,
            children: [
              // Silhouette
              Positioned(
                left: boxLeft,
                top: boxTop,
                width: boxW,
                height: boxH,
                child: CustomPaint(
                  painter: _BodySilhouettePainter(
                    isFront: _selectedView == 'front',
                    glow: _glowAnim.value,
                    currentColor: _currentPlayer == 1
                        ? const Color(0xFFE879F9)
                        : const Color(0xFFFFD166),
                  ),
                ),
              ),
              // Touch points
              ...parts.map((part) {
                final id = part['id'] as String;
                final x = part['x'] as double;
                final y = part['y'] as double;
                final myType = currentMap[id];
                final partnerType = otherMap?[id];

                final myData = _touchTypeData(myType);
                final partnerData = _touchTypeData(partnerType);

                final dotColor = myData != null
                    ? myData['color'] as Color
                    : Colors.white.withOpacity(0.7);
                final dotEmoji = myData?['emoji'] as String?;

                return Positioned(
                  left: boxLeft + boxW * x - 18,
                  top: boxTop + boxH * y - 18,
                  child: GestureDetector(
                    onTap: () => _showTouchSelector(part),
                    onLongPress: myData != null ? () => _clearPart(id) : null,
                    child: AnimatedBuilder(
                      animation: _pointsPulse,
                      builder: (context, _) {
                        final pulse = myData == null
                            ? 0.5 + 0.5 * _pointsPulse.value
                            : 0.85;
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer glow
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: dotColor.withOpacity(0.3 * pulse),
                                boxShadow: [
                                  BoxShadow(
                                    color: dotColor.withOpacity(0.5 * pulse),
                                    blurRadius: 14,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    dotColor,
                                    dotColor.withOpacity(0.5),
                                  ],
                                ),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.85),
                                  width: 1.5,
                                ),
                              ),
                              child: Center(
                                child: dotEmoji != null
                                    ? Text(
                                        dotEmoji,
                                        style: const TextStyle(fontSize: 12),
                                      )
                                    : Icon(
                                        Icons.add,
                                        color: Colors.white
                                            .withOpacity(0.9),
                                        size: 14,
                                      ),
                              ),
                            ),
                            // Partner mini-dot if in 'together' mode
                            if (partnerData != null)
                              Positioned(
                                right: -2,
                                top: -2,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: partnerData['color'] as Color,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 1.2,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  void _showTouchSelector(Map<String, dynamic> part) {
    final id = part['id'] as String;
    final currentMap = _currentPlayer == 1 ? _player1Map : _player2Map;
    final selected = currentMap[id];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A0A4A), Color(0xFF0A0F2C)],
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
            const SizedBox(height: 16),
            Text(
              _bodyName(id),
              style: const TextStyle(
                fontFamily: 'PlayfairDisplay',
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'games.intimacy_map.how_touched_here'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'DMSans',
                color: Colors.white.withOpacity(0.6),
                fontSize: 13,
                fontStyle: FontStyle.italic,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: _touchTypes.map((t) {
                final color = t['color'] as Color;
                final isSelected = selected == t['id'];
                return GestureDetector(
                  onTap: () {
                    _markPart(id, t['id'] as String);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          color.withOpacity(isSelected ? 0.45 : 0.2),
                          color.withOpacity(isSelected ? 0.2 : 0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? color
                            : color.withOpacity(0.4),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withOpacity(0.4),
                                blurRadius: 14,
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(t['emoji'] as String,
                            style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 8),
                        Text(
                          'games.intimacy_map.touch_${t['id']}'.tr(),
                          style: TextStyle(
                            fontFamily: 'DMSans',
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            if (selected != null) ...[
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () {
                  _clearPart(id);
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.15),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.close,
                          color: Colors.white.withOpacity(0.6),
                          size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'games.intimacy_map.clear_mark'.tr(),
                        style: TextStyle(
                          fontFamily: 'DMSans',
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Reveal view
  // ---------------------------------------------------------------------------
  Widget _buildRevealView() {
    final allKeys = {..._player1Map.keys, ..._player2Map.keys};
    int matches = 0;
    int discoveries = 0;
    int onlyP1 = 0;
    int onlyP2 = 0;
    final matchedZones = <String>[];
    final discoveryZones = <String>[];
    for (final k in allKeys) {
      final p1 = _player1Map[k];
      final p2 = _player2Map[k];
      if (p1 != null && p2 != null) {
        if (p1 == p2) {
          matches++;
          matchedZones.add(k);
        } else {
          discoveries++;
          discoveryZones.add(k);
        }
      } else if (p1 != null) {
        onlyP1++;
      } else if (p2 != null) {
        onlyP2++;
      }
    }
    final totalShared =
        (matches + discoveries) > 0 ? (matches + discoveries) : 1;
    final compatibility = matches / totalShared;
    final messageKey = compatibility > 0.7
        ? 'games.intimacy_map.compatibility_msg_high'
        : compatibility > 0.4
            ? 'games.intimacy_map.compatibility_msg_mid'
            : 'games.intimacy_map.compatibility_msg_low';
    // Find favorite zones (love/sensitive) shared
    final favorites = matchedZones
        .where((id) {
          final t = _player1Map[id];
          return t == 'love' || t == 'sensitive';
        })
        .toList();

    return AnimatedBuilder(
      animation: _revealAnim,
      builder: (context, child) {
        return Opacity(
          opacity: _revealAnim.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _revealAnim.value)),
            child: child,
          ),
        );
      },
      child: SingleChildScrollView(
        padding:
            const EdgeInsets.fromLTRB(20, kToolbarHeight + 4, 20, 30),
        child: Column(
          children: [
            // Header
            const Text('💎', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 4),
            Text(
              'games.intimacy_map.compare_title'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'PlayfairDisplay',
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xFFD946EF),
                decoration: TextDecoration.none,
                shadows: [
                  Shadow(color: Color(0xFFD946EF), blurRadius: 18),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Compatibility gauge
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0x33B388FF),
                    Color(0x33D946EF),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: const Color(0xFFB388FF).withOpacity(0.35)),
              ),
              child: Column(
                children: [
                  Text(
                    'games.intimacy_map.compatibility_score'.tr(),
                    style: TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.6),
                      letterSpacing: 1.5,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: 160,
                    height: 90,
                    child: CustomPaint(
                      painter: _CompatibilityGaugePainter(
                        ratio: compatibility,
                        glow: _glowAnim.value,
                      ),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 30),
                          child: Text(
                            '${(compatibility * 100).round()}%',
                            style: const TextStyle(
                              fontFamily: 'PlayfairDisplay',
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              decoration: TextDecoration.none,
                              shadows: [
                                Shadow(
                                    color: Color(0xFFD946EF), blurRadius: 12),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    messageKey.tr(),
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
            // Stats
            Row(
              children: [
                Expanded(
                  child: _statBox(
                    icon: '✅',
                    label: 'games.intimacy_map.match_count'.tr(),
                    value: '$matches',
                    color: const Color(0xFF6EE7B7),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _statBox(
                    icon: '🔍',
                    label: 'games.intimacy_map.discovery_count'.tr(),
                    value: '$discoveries',
                    color: const Color(0xFFFFD166),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _statBox(
                    icon: '🗺️',
                    label: 'games.intimacy_map.mapped_total'.tr(),
                    value: '${_player1Map.length}/${_player2Map.length}',
                    color: const Color(0xFFB388FF),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Heatmap visualization
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.local_fire_department,
                          color: Color(0xFFFF6B35), size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'games.intimacy_map.heat_map'.tr(),
                        style: const TextStyle(
                          fontFamily: 'PlayfairDisplay',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 360,
                    child: _buildHeatmap(),
                  ),
                ],
              ),
            ),
            if (favorites.isNotEmpty) ...[
              const SizedBox(height: 14),
              _favoriteZonesCard(favorites),
            ],
            if (discoveryZones.isNotEmpty) ...[
              const SizedBox(height: 14),
              _discoveryZonesCard(discoveryZones),
            ],
            if (onlyP1 + onlyP2 > 0) ...[
              const SizedBox(height: 12),
              Text(
                'games.intimacy_map.only_one_marked'.tr(namedArgs: {
                  'p1': '$onlyP1',
                  'p2': '$onlyP2',
                }),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: Colors.white.withOpacity(0.5),
                  decoration: TextDecoration.none,
                ),
              ),
            ],
            const SizedBox(height: 22),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      setState(() {
                        _gameStarted = false;
                      });
                    },
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
                          'games.intimacy_map.menu'.tr(),
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
                    onTap: () {
                      setState(() => _showingReveal = false);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
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
                            color: const Color(0xFFB388FF).withOpacity(0.45),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'games.intimacy_map.continue_marking'.tr(),
                          style: const TextStyle(
                            fontFamily: 'DMSans',
                            color: Colors.white,
                            fontSize: 14,
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
    );
  }

  Widget _statBox({
    required String icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.18),
            color.withOpacity(0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'PlayfairDisplay',
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'DMSans',
              color: Colors.white.withOpacity(0.65),
              fontSize: 9,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmap() {
    // Combined heatmap: show body and dots colored by intensity (love=red glow, etc.)
    return LayoutBuilder(
      builder: (context, constraints) {
        // Body silhouette has a roughly 1:2 aspect ratio — preserve it.
        const bodyAspect = 0.5;
        final availableW = constraints.maxWidth;
        final availableH = constraints.maxHeight;
        double boxW;
        double boxH;
        if (availableW / availableH > bodyAspect) {
          boxH = availableH;
          boxW = boxH * bodyAspect;
        } else {
          boxW = availableW * 0.85;
          boxH = boxW / bodyAspect;
        }
        final boxLeft = (availableW - boxW) / 2;
        final boxTop = (availableH - boxH) / 2;
        return Stack(
          children: [
            Positioned(
              left: boxLeft,
              top: boxTop,
              width: boxW,
              height: boxH,
              child: CustomPaint(
                painter: _BodySilhouettePainter(
                  isFront: true,
                  glow: 0.5,
                  currentColor: const Color(0xFFE879F9),
                  ghost: true,
                ),
              ),
            ),
            // Front parts heatmap
            ..._bodyPartsFront.map((part) {
              final id = part['id'] as String;
              final p1 = _touchTypeData(_player1Map[id]);
              final p2 = _touchTypeData(_player2Map[id]);
              if (p1 == null && p2 == null) return const SizedBox.shrink();
              final x = part['x'] as double;
              final y = part['y'] as double;
              final isMatch = p1 != null &&
                  p2 != null &&
                  p1['id'] == p2['id'];
              final color =
                  (p1 ?? p2)!['color'] as Color;
              return Positioned(
                left: boxLeft + boxW * x - 14,
                top: boxTop + boxH * y - 14,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withOpacity(0.85),
                    border: Border.all(
                      color: isMatch
                          ? const Color(0xFFFFD166)
                          : Colors.white.withOpacity(0.7),
                      width: isMatch ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.6),
                        blurRadius: isMatch ? 14 : 8,
                      ),
                      if (isMatch)
                        const BoxShadow(
                          color: Color(0xFFFFD166),
                          blurRadius: 10,
                        ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      (p1 ?? p2)!['emoji'] as String,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _favoriteZonesCard(List<String> favorites) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0x33E53935), Color(0x33FFD166)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(0xFFE53935).withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.favorite,
                  color: Color(0xFFE53935), size: 16),
              const SizedBox(width: 6),
              Text(
                'games.intimacy_map.favorite_zones'.tr(),
                style: const TextStyle(
                  fontFamily: 'PlayfairDisplay',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFFF8FB1),
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: favorites
                .map((id) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _bodyName(id),
                        style: const TextStyle(
                          fontFamily: 'DMSans',
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _discoveryZonesCard(List<String> zones) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0x33FFD166), Color(0x33B388FF)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(0xFFFFD166).withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.explore,
                  color: Color(0xFFFFD166), size: 16),
              const SizedBox(width: 6),
              Text(
                'games.intimacy_map.zones_to_explore'.tr(),
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
          ...zones.take(8).map((id) {
            final p1 = _touchTypeData(_player1Map[id]);
            final p2 = _touchTypeData(_player2Map[id]);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _bodyName(id),
                      style: const TextStyle(
                        fontFamily: 'DMSans',
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                  Text(p1?['emoji'] as String? ?? '–',
                      style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  Container(
                      width: 1, height: 12, color: Colors.white24),
                  const SizedBox(width: 4),
                  Text(p2?['emoji'] as String? ?? '–',
                      style: const TextStyle(fontSize: 14)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Instructions sheet
  // ---------------------------------------------------------------------------
  void _showInstructions() {
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
                'games.intimacy_map.instructions_title'.tr(),
                style: const TextStyle(
                  fontFamily: 'PlayfairDisplay',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 16),
              _ruleRow('1', 'games.intimacy_map.instr1'.tr()),
              const SizedBox(height: 8),
              _ruleRow('2', 'games.intimacy_map.instr2'.tr()),
              const SizedBox(height: 8),
              _ruleRow('3', 'games.intimacy_map.instr3'.tr()),
              const SizedBox(height: 8),
              _ruleRow('4', 'games.intimacy_map.instr4'.tr()),
              const SizedBox(height: 8),
              _ruleRow('5', 'games.intimacy_map.instr5'.tr()),
              const SizedBox(height: 18),
              Text(
                'games.intimacy_map.closing_hint'.tr(),
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
// Painters
// =============================================================================

/// Anatomical body silhouette with gradient skin and glow.
class _BodySilhouettePainter extends CustomPainter {
  final bool isFront;
  final double glow;
  final Color currentColor;
  final bool ghost;

  _BodySilhouettePainter({
    required this.isFront,
    required this.glow,
    required this.currentColor,
    this.ghost = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final path = Path();

    // Head (slightly oval)
    path.addOval(Rect.fromCenter(
      center: Offset(cx, h * 0.085),
      width: w * 0.28,
      height: h * 0.115,
    ));

    // Neck
    path.moveTo(cx - w * 0.08, h * 0.14);
    path.lineTo(cx - w * 0.07, h * 0.18);
    path.quadraticBezierTo(cx, h * 0.20, cx + w * 0.07, h * 0.18);
    path.lineTo(cx + w * 0.08, h * 0.14);
    path.close();

    // Torso (curvy)
    final torso = Path();
    torso.moveTo(cx - w * 0.30, h * 0.20); // shoulder L
    torso.quadraticBezierTo(
        cx - w * 0.36, h * 0.30, cx - w * 0.24, h * 0.42); // armpit→waist
    torso.quadraticBezierTo(
        cx - w * 0.16, h * 0.50, cx - w * 0.20, h * 0.55); // hip L
    torso.lineTo(cx + w * 0.20, h * 0.55); // hip R
    torso.quadraticBezierTo(
        cx + w * 0.16, h * 0.50, cx + w * 0.24, h * 0.42);
    torso.quadraticBezierTo(
        cx + w * 0.36, h * 0.30, cx + w * 0.30, h * 0.20);
    torso.close();

    // Arms (left)
    final armL = Path();
    armL.moveTo(cx - w * 0.30, h * 0.20);
    armL.quadraticBezierTo(
        cx - w * 0.42, h * 0.30, cx - w * 0.42, h * 0.45);
    armL.quadraticBezierTo(
        cx - w * 0.40, h * 0.55, cx - w * 0.34, h * 0.62);
    armL.lineTo(cx - w * 0.27, h * 0.60);
    armL.quadraticBezierTo(
        cx - w * 0.32, h * 0.50, cx - w * 0.34, h * 0.40);
    armL.quadraticBezierTo(
        cx - w * 0.32, h * 0.27, cx - w * 0.26, h * 0.22);
    armL.close();

    // Arms (right)
    final armR = Path();
    armR.moveTo(cx + w * 0.30, h * 0.20);
    armR.quadraticBezierTo(
        cx + w * 0.42, h * 0.30, cx + w * 0.42, h * 0.45);
    armR.quadraticBezierTo(
        cx + w * 0.40, h * 0.55, cx + w * 0.34, h * 0.62);
    armR.lineTo(cx + w * 0.27, h * 0.60);
    armR.quadraticBezierTo(
        cx + w * 0.32, h * 0.50, cx + w * 0.34, h * 0.40);
    armR.quadraticBezierTo(
        cx + w * 0.32, h * 0.27, cx + w * 0.26, h * 0.22);
    armR.close();

    // Legs
    final legL = Path();
    legL.moveTo(cx - w * 0.20, h * 0.55);
    legL.quadraticBezierTo(
        cx - w * 0.22, h * 0.75, cx - w * 0.18, h * 0.95);
    legL.lineTo(cx - w * 0.06, h * 0.95);
    legL.quadraticBezierTo(
        cx - w * 0.04, h * 0.75, cx - w * 0.05, h * 0.55);
    legL.close();

    final legR = Path();
    legR.moveTo(cx + w * 0.20, h * 0.55);
    legR.quadraticBezierTo(
        cx + w * 0.22, h * 0.75, cx + w * 0.18, h * 0.95);
    legR.lineTo(cx + w * 0.06, h * 0.95);
    legR.quadraticBezierTo(
        cx + w * 0.04, h * 0.75, cx + w * 0.05, h * 0.55);
    legR.close();

    final fullPath = Path()
      ..addPath(path, Offset.zero)
      ..addPath(torso, Offset.zero)
      ..addPath(armL, Offset.zero)
      ..addPath(armR, Offset.zero)
      ..addPath(legL, Offset.zero)
      ..addPath(legR, Offset.zero);

    // Glow halo around body
    if (!ghost) {
      final haloPaint = Paint()
        ..color = currentColor.withOpacity(0.18 + 0.1 * glow)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
      canvas.drawPath(fullPath, haloPaint);
    }

    // Skin gradient fill
    final skinPaint = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(0, 0),
        Offset(0, h),
        ghost
            ? [
                Colors.white.withOpacity(0.07),
                Colors.white.withOpacity(0.04),
              ]
            : [
                currentColor.withOpacity(0.18),
                Colors.white.withOpacity(0.1),
                currentColor.withOpacity(0.10),
              ],
        ghost ? null : const [0.0, 0.5, 1.0],
      );
    canvas.drawPath(fullPath, skinPaint);

    // Outline
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = ghost
          ? Colors.white.withOpacity(0.18)
          : Colors.white.withOpacity(0.4);
    canvas.drawPath(fullPath, outline);

    // Subtle face hint (front view)
    if (isFront && !ghost) {
      final eyePaint = Paint()..color = Colors.white.withOpacity(0.35);
      canvas.drawCircle(
          Offset(cx - w * 0.06, h * 0.085), 1.3, eyePaint);
      canvas.drawCircle(
          Offset(cx + w * 0.06, h * 0.085), 1.3, eyePaint);
      // smile
      final smile = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withOpacity(0.3);
      canvas.drawArc(
        Rect.fromCenter(
            center: Offset(cx, h * 0.115), width: w * 0.06, height: h * 0.02),
        0,
        pi,
        false,
        smile,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BodySilhouettePainter old) =>
      old.isFront != isFront ||
      old.glow != glow ||
      old.currentColor != currentColor ||
      old.ghost != ghost;
}

/// Mini silhouette for the setup header — body + 3 glowing points.
class _MiniSilhouettePainter extends CustomPainter {
  final double glow;
  final double dotsPulse;

  _MiniSilhouettePainter({required this.glow, required this.dotsPulse});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    final fullPath = Path();
    fullPath.addOval(Rect.fromCenter(
      center: Offset(cx, h * 0.085),
      width: w * 0.30,
      height: h * 0.13,
    ));
    final torso = Path();
    torso.moveTo(cx - w * 0.32, h * 0.22);
    torso.quadraticBezierTo(
        cx - w * 0.20, h * 0.50, cx - w * 0.18, h * 0.55);
    torso.lineTo(cx + w * 0.18, h * 0.55);
    torso.quadraticBezierTo(
        cx + w * 0.20, h * 0.50, cx + w * 0.32, h * 0.22);
    torso.close();
    fullPath.addPath(torso, Offset.zero);

    final legs = Path();
    legs.moveTo(cx - w * 0.18, h * 0.55);
    legs.lineTo(cx - w * 0.16, h * 0.95);
    legs.lineTo(cx - w * 0.04, h * 0.95);
    legs.lineTo(cx - w * 0.02, h * 0.55);
    legs.moveTo(cx + w * 0.18, h * 0.55);
    legs.lineTo(cx + w * 0.16, h * 0.95);
    legs.lineTo(cx + w * 0.04, h * 0.95);
    legs.lineTo(cx + w * 0.02, h * 0.55);
    fullPath.addPath(legs, Offset.zero);

    // Glow
    final glowPaint = Paint()
      ..color = const Color(0xFFE879F9).withOpacity(0.3 + 0.2 * glow)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawPath(fullPath, glowPaint);

    // Body fill
    final bodyPaint = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(0, 0),
        Offset(0, h),
        const [
          Color(0xFFFFB6C1),
          Color(0xFFE879F9),
          Color(0xFFB388FF),
        ],
      );
    canvas.drawPath(fullPath, bodyPaint);

    // Outline
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withOpacity(0.5);
    canvas.drawPath(fullPath, outline);

    // Animated touch points
    final points = [
      Offset(cx, h * 0.16), // lips
      Offset(cx - w * 0.05, h * 0.35), // chest
      Offset(cx + w * 0.10, h * 0.50), // hip
    ];
    final colors = [
      const Color(0xFFE53935),
      const Color(0xFFFFD166),
      const Color(0xFF7DD3FC),
    ];
    for (int i = 0; i < points.length; i++) {
      final pulse = 0.7 + 0.3 * dotsPulse;
      final p = Paint()
        ..color = colors[i].withOpacity(0.4 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(points[i], 8, p);
      canvas.drawCircle(
        points[i],
        4,
        Paint()..color = colors[i],
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MiniSilhouettePainter old) =>
      old.glow != glow || old.dotsPulse != dotsPulse;
}

/// Compatibility gauge — semicircle with gradient sweep + needle.
class _CompatibilityGaugePainter extends CustomPainter {
  final double ratio; // 0..1
  final double glow;

  _CompatibilityGaugePainter({required this.ratio, required this.glow});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.95);
    final radius = size.height * 0.85;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Track
    final track = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, pi, pi, false, track);

    // Filled portion with gradient
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFD946EF).withOpacity(0.4 + 0.2 * glow)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    final fgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..shader = ui.Gradient.sweep(
        center,
        const [
          Color(0xFFE53935),
          Color(0xFFFFD166),
          Color(0xFF6EE7B7),
        ],
        const [0.0, 0.5, 1.0],
        TileMode.clamp,
        pi,
        pi + pi * ratio,
      );
    canvas.drawArc(rect, pi, pi * ratio, false, glowPaint);
    canvas.drawArc(rect, pi, pi * ratio, false, fgPaint);

    // Tick marks
    final tickPaint = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..strokeWidth = 1.2;
    for (int i = 0; i <= 10; i++) {
      final a = pi + (i / 10) * pi;
      final p1 = center +
          Offset(cos(a) * (radius - 14), sin(a) * (radius - 14));
      final p2 = center +
          Offset(cos(a) * (radius - 18), sin(a) * (radius - 18));
      canvas.drawLine(p1, p2, tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CompatibilityGaugePainter old) =>
      old.ratio != ratio || old.glow != glow;
}

/// Drifting particles for the cosmic background.
class _ParticlesPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ParticlesPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // Soft nebula
    for (int i = 0; i < 4; i++) {
      final phase = (progress + i * 0.27) % 1.0;
      final cx =
          size.width * (0.2 + 0.6 * (i / 4)) + sin(phase * 2 * pi) * 30;
      final cy = size.height * (0.2 + 0.6 * ((i + 1) / 5)) +
          cos(phase * 2 * pi) * 30;
      final paint = Paint()
        ..shader = ui.Gradient.radial(
          Offset(cx, cy),
          110,
          [
            const [
              Color(0xFFD946EF),
              Color(0xFF7DD3FC),
              Color(0xFFB388FF),
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
      const Color(0xFFB388FF),
      const Color(0xFFE879F9),
      Colors.white,
      const Color(0xFFFFD166),
    ];
    for (final p in particles) {
      final phase = (p.phase + progress * p.speed) % 1.0;
      final x = p.x * size.width + sin(phase * 2 * pi + p.phase * 4) * 18;
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
