import 'dart:math';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class FantasyBuilderScreen extends StatefulWidget {
  const FantasyBuilderScreen({super.key});

  @override
  State<FantasyBuilderScreen> createState() => _FantasyBuilderScreenState();
}

class _FantasyBuilderScreenState extends State<FantasyBuilderScreen>
    with TickerProviderStateMixin {
  // ---------------------------------------------------------------------------
  // Game state
  // ---------------------------------------------------------------------------
  bool _gameStarted = false;
  bool _showingReveal = false;
  int _currentStep = 0;
  int _currentPlayer = 1;
  String _intensity = 'spicy';

  String? _selectedSetting;
  String? _selectedMood;
  String? _selectedAction;
  String? _selectedSurprise;
  int? _secretThemeIndex; // wild card revealed at the end
  final List<String> _customDetails = [];
  final TextEditingController _detailController = TextEditingController();

  // Vetoes — each player gets one per fantasy
  bool _player1VetoUsed = false;
  bool _player2VetoUsed = false;
  bool _vetoTriggered = false; // current step is a re-pick

  // Saved fantasies (in-memory for the session)
  final List<_BuiltFantasy> _savedFantasies = [];

  // Animations
  late final AnimationController _bgStars;
  late final AnimationController _orbPulse;
  late final AnimationController _shimmer;
  late final AnimationController _stepIntro;
  late final AnimationController _revealController;

  late Animation<double> _orbAnim;
  late Animation<double> _stepAnim;

  final List<_Star> _stars =
      List.generate(60, (i) => _Star(Random(i * 13 + 9)));
  final List<_Sparkle> _sparkles =
      List.generate(40, (i) => _Sparkle(Random(i * 17 + 5)));

  final Random _random = Random();

  // Quick-add detail chips (pre-baked common ideas)
  static const List<String> _detailChips = [
    'musica jazz',
    'candele',
    'profumo',
    'silenzio',
    'sussurri',
    'velluto',
  ];

  // ---------------------------------------------------------------------------
  // Static option data (emoji + value + i18n key)
  // ---------------------------------------------------------------------------
  Map<String, List<Map<String, String>>> get _options => {
        'settings': const [
          {'value': 'beach_sunset', 'emoji': '🏖️'},
          {'value': 'mountain_cabin', 'emoji': '🏔️'},
          {'value': 'candlelit_room', 'emoji': '🕯️'},
          {'value': 'rooftop_city', 'emoji': '🌃'},
          {'value': 'forest_clearing', 'emoji': '🌲'},
          {'value': 'luxury_hotel', 'emoji': '🏨'},
          {'value': 'private_pool', 'emoji': '🏊'},
          {'value': 'vintage_train', 'emoji': '🚂'},
        ].map((m) => {
              ...m,
              'label': 'games.fantasy_builder.settings.${m['value']}'.tr(),
            }).toList(),
        'moods': const [
          {'value': 'romantic', 'emoji': '💕'},
          {'value': 'playful', 'emoji': '😏'},
          {'value': 'passionate', 'emoji': '🔥'},
          {'value': 'mysterious', 'emoji': '🎭'},
          {'value': 'adventurous', 'emoji': '⚡'},
          {'value': 'tender', 'emoji': '🌸'},
        ].map((m) => {
              ...m,
              'label': 'games.fantasy_builder.moods.${m['value']}'.tr(),
            }).toList(),
        'actions_soft': const [
          {'value': 'massage', 'emoji': '💆'},
          {'value': 'dance', 'emoji': '💃'},
          {'value': 'bath', 'emoji': '🛁'},
          {'value': 'stargazing', 'emoji': '⭐'},
          {'value': 'cooking', 'emoji': '👨‍🍳'},
          {'value': 'reading', 'emoji': '📖'},
        ].map((m) => {
              ...m,
              'label':
                  'games.fantasy_builder.actions_soft.${m['value']}'.tr(),
            }).toList(),
        'actions_spicy': const [
          {'value': 'blindfold', 'emoji': '🙈'},
          {'value': 'roleplay', 'emoji': '🎭'},
          {'value': 'ice_game', 'emoji': '🧊'},
          {'value': 'feather', 'emoji': '🪶'},
          {'value': 'oil_massage', 'emoji': '✨'},
          {'value': 'strip_game', 'emoji': '🎲'},
        ].map((m) => {
              ...m,
              'label':
                  'games.fantasy_builder.actions_spicy.${m['value']}'.tr(),
            }).toList(),
        'surprises': const [
          {'value': 'music', 'emoji': '🎵'},
          {'value': 'champagne', 'emoji': '🥂'},
          {'value': 'chocolate', 'emoji': '🍫'},
          {'value': 'flowers', 'emoji': '💐'},
          {'value': 'lingerie', 'emoji': '👙'},
          {'value': 'letter', 'emoji': '💌'},
          {'value': 'perfume', 'emoji': '✨'},
          {'value': 'game', 'emoji': '🎮'},
        ].map((m) => {
              ...m,
              'label':
                  'games.fantasy_builder.surprises.${m['value']}'.tr(),
            }).toList(),
      };

  List<String> get _stepTitles => [
        'games.fantasy_builder.steps.setting'.tr(),
        'games.fantasy_builder.steps.atmosphere'.tr(),
        'games.fantasy_builder.steps.main_action'.tr(),
        'games.fantasy_builder.steps.surprise'.tr(),
        'games.fantasy_builder.steps.final_details'.tr(),
      ];

  static const List<IconData> _stepIcons = [
    Icons.place_rounded,
    Icons.auto_awesome,
    Icons.local_fire_department,
    Icons.card_giftcard,
    Icons.edit_note,
  ];

  // Themes for the secret wild card
  static const List<Map<String, String>> _secretThemes = [
    {'emoji': '🌹', 'key': 'theme_whispers'},
    {'emoji': '🪞', 'key': 'theme_mirror'},
    {'emoji': '🎭', 'key': 'theme_mystery'},
    {'emoji': '🌙', 'key': 'theme_moon'},
    {'emoji': '🍷', 'key': 'theme_velvet'},
    {'emoji': '🔥', 'key': 'theme_audacity'},
    {'emoji': '💋', 'key': 'theme_kiss'},
    {'emoji': '🌌', 'key': 'theme_eternity'},
  ];

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------
  @override
  void initState() {
    super.initState();
    _bgStars = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _orbPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _orbAnim = CurvedAnimation(parent: _orbPulse, curve: Curves.easeInOut);

    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _stepIntro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _stepAnim = CurvedAnimation(
      parent: _stepIntro,
      curve: Curves.easeOutCubic,
    );

    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    );
  }

  @override
  void dispose() {
    _detailController.dispose();
    _bgStars.dispose();
    _orbPulse.dispose();
    _shimmer.dispose();
    _stepIntro.dispose();
    _revealController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Game logic
  // ---------------------------------------------------------------------------
  void _startGame() {
    HapticFeedback.heavyImpact();
    setState(() {
      _gameStarted = true;
      _showingReveal = false;
      _currentStep = 0;
      _currentPlayer = _random.nextInt(2) + 1;
      _selectedSetting = null;
      _selectedMood = null;
      _selectedAction = null;
      _selectedSurprise = null;
      _secretThemeIndex = null;
      _customDetails.clear();
      _player1VetoUsed = false;
      _player2VetoUsed = false;
      _vetoTriggered = false;
    });
    _stepIntro.forward(from: 0);
  }

  void _selectOption(String value) {
    HapticFeedback.selectionClick();
    setState(() {
      switch (_currentStep) {
        case 0:
          _selectedSetting = value;
          break;
        case 1:
          _selectedMood = value;
          break;
        case 2:
          _selectedAction = value;
          break;
        case 3:
          _selectedSurprise = value;
          break;
      }
    });
  }

  void _surprisePick() {
    HapticFeedback.mediumImpact();
    final list = _currentOptions();
    if (list.isEmpty) return;
    final picked = list[_random.nextInt(list.length)]['value']!;
    _selectOption(picked);
  }

  List<Map<String, String>> _currentOptions() {
    switch (_currentStep) {
      case 0:
        return _options['settings']!;
      case 1:
        return _options['moods']!;
      case 2:
        return _intensity == 'soft'
            ? _options['actions_soft']!
            : _options['actions_spicy']!;
      case 3:
        return _options['surprises']!;
      default:
        return [];
    }
  }

  String? _currentSelection() {
    switch (_currentStep) {
      case 0:
        return _selectedSetting;
      case 1:
        return _selectedMood;
      case 2:
        return _selectedAction;
      case 3:
        return _selectedSurprise;
      default:
        return null;
    }
  }

  void _useVeto() {
    if (_currentSelection() == null) return; // nothing to veto
    final otherPlayer = _currentPlayer == 1 ? 2 : 1;
    final vetoUsedByOther =
        otherPlayer == 1 ? _player1VetoUsed : _player2VetoUsed;
    if (vetoUsedByOther) return; // already used

    HapticFeedback.heavyImpact();
    setState(() {
      if (otherPlayer == 1) {
        _player1VetoUsed = true;
      } else {
        _player2VetoUsed = true;
      }
      // Clear the current selection so player must re-pick
      switch (_currentStep) {
        case 0:
          _selectedSetting = null;
          break;
        case 1:
          _selectedMood = null;
          break;
        case 2:
          _selectedAction = null;
          break;
        case 3:
          _selectedSurprise = null;
          break;
      }
      _vetoTriggered = true;
    });
    _stepIntro.forward(from: 0);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _vetoTriggered = false);
    });
  }

  void _nextStep() {
    HapticFeedback.mediumImpact();
    if (_currentStep < 4) {
      setState(() {
        _currentStep++;
        _currentPlayer = _currentPlayer == 1 ? 2 : 1;
      });
      _stepIntro.forward(from: 0);
    } else {
      // Generate secret theme + show reveal
      setState(() {
        _secretThemeIndex = _random.nextInt(_secretThemes.length);
        _showingReveal = true;
      });
      _revealController.forward(from: 0);
    }
  }

  void _prevStep() {
    if (_currentStep == 0) return;
    HapticFeedback.lightImpact();
    setState(() {
      _currentStep--;
      _currentPlayer = _currentPlayer == 1 ? 2 : 1;
    });
    _stepIntro.forward(from: 0);
  }

  void _addDetail([String? prefilled]) {
    final text = (prefilled ?? _detailController.text).trim();
    if (text.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() {
      if (!_customDetails.contains(text)) {
        _customDetails.add(text);
      }
      if (prefilled == null) _detailController.clear();
    });
  }

  Map<String, String> _getOptionData(String category, String? value) {
    if (value == null) {
      return {'value': '', 'emoji': '✨', 'label': '—'};
    }
    final list = _options[category] ?? [];
    return list.firstWhere(
      (o) => o['value'] == value,
      orElse: () => {'value': value, 'emoji': '❓', 'label': value},
    );
  }

  void _saveFantasy() {
    HapticFeedback.heavyImpact();
    final fantasy = _BuiltFantasy(
      setting: _selectedSetting ?? '',
      mood: _selectedMood ?? '',
      action: _selectedAction ?? '',
      surprise: _selectedSurprise ?? '',
      details: List.of(_customDetails),
      themeIndex: _secretThemeIndex ?? 0,
      intensity: _intensity,
      timestamp: DateTime.now(),
    );
    setState(() => _savedFantasies.insert(0, fantasy));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Text('✨ ', style: TextStyle(fontSize: 18)),
            Expanded(
              child: Text(
                'games.fantasy_builder.fantasy_saved'.tr(),
                style: const TextStyle(
                    fontFamily: 'DMSans', color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF6B2D5B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
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
      resizeToAvoidBottomInset: true,
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
                'games.fantasy_builder.title'.tr(),
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
          // Mystical gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1A0532),
                  Color(0xFF2D1B5C),
                  Color(0xFF1A0A2E),
                  Color(0xFF0A0F2C),
                ],
                stops: [0.0, 0.35, 0.7, 1.0],
              ),
            ),
          ),
          // Twinkling stars + nebula
          AnimatedBuilder(
            animation: _bgStars,
            builder: (context, _) {
              return CustomPaint(
                size: Size.infinite,
                painter: _StarFieldPainter(
                  stars: _stars,
                  sparkles: _sparkles,
                  progress: _bgStars.value,
                ),
              );
            },
          ),
          SafeArea(
            child: !_gameStarted
                ? _buildSetupView()
                : _showingReveal
                    ? _buildRevealView()
                    : _buildGameView(),
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
              const Text('🌙', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text(
                'games.fantasy_builder.exit_confirm'.tr(),
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        children: [
          // Header — magical orb
          AnimatedBuilder(
            animation: _orbAnim,
            builder: (context, _) {
              return SizedBox(
                height: 200,
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // outer halo
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFFE879F9).withOpacity(
                                  0.35 + 0.18 * _orbAnim.value),
                              const Color(0xFF6B2D5B).withOpacity(0.15),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      // crystal ball
                      SizedBox(
                        width: 130,
                        height: 130,
                        child: CustomPaint(
                          painter: _CrystalBallPainter(
                            pulse: _orbAnim.value,
                            innerProgress: _bgStars.value,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 4),

          Text(
            'games.fantasy_builder.title'.tr(),
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
            'game_ui.build_perfect_fantasy'.tr(),
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
            label: 'game_ui.intensity'.tr(),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _intensityCard(
                value: 'soft',
                emoji: '🌸',
                label: 'game_ui.soft_label'.tr(),
                description: 'game_ui.soft_zones'.tr(),
                color: const Color(0xFFFF8FB1),
              ),
              const SizedBox(width: 12),
              _intensityCard(
                value: 'spicy',
                emoji: '🔥',
                label: 'game_ui.spicy_label'.tr(),
                description: 'game_ui.spicy_zones'.tr(),
                color: const Color(0xFFFF6B35),
              ),
            ],
          ),

          const SizedBox(height: 26),

          // How it works card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFE879F9).withOpacity(0.08),
                  const Color(0xFF6B2D5B).withOpacity(0.04),
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
                    const Icon(Icons.auto_awesome,
                        color: Color(0xFFE879F9), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'game_ui.how_it_works'.tr(),
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
                  'game_ui.how_it_works_description'.tr(),
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
                    _featureChip(Icons.casino,
                        'games.fantasy_builder.feature_random'.tr()),
                    _featureChip(Icons.front_hand,
                        'games.fantasy_builder.feature_veto'.tr()),
                    _featureChip(Icons.auto_awesome,
                        'games.fantasy_builder.feature_secret'.tr()),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          // Saved fantasies (if any)
          if (_savedFantasies.isNotEmpty) ...[
            _sectionLabel(
              icon: Icons.history_edu,
              color: const Color(0xFFFFD166),
              label: 'games.fantasy_builder.previous_fantasies'.tr(),
            ),
            const SizedBox(height: 12),
            ..._savedFantasies.take(3).map((f) => _savedFantasyTile(f)),
            const SizedBox(height: 22),
          ],

          // Start button — shimmer
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
                        Color(0xFFD946EF),
                        Color(0xFFFFE7A0),
                        Color(0xFFD946EF),
                        Color(0xFF6B2D5B),
                      ],
                      stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
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
                      const Icon(Icons.auto_awesome,
                          color: Colors.white, size: 24),
                      const SizedBox(width: 10),
                      Text(
                        'game_ui.start_creating'.tr(),
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

  Widget _intensityCard({
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
                      color: color.withOpacity(0.4),
                      blurRadius: 20,
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
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'PlayfairDisplay',
                  color: isSelected ? color : Colors.white.withOpacity(0.85),
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  decoration: TextDecoration.none,
                ),
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

  Widget _featureChip(IconData icon, String label) {
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
          Icon(icon, color: const Color(0xFFFFD166), size: 12),
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

  Widget _savedFantasyTile(_BuiltFantasy f) {
    final setting = _getOptionData('settings', f.setting);
    final mood = _getOptionData('moods', f.mood);
    final theme = _secretThemes[f.themeIndex];
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6B2D5B).withOpacity(0.25),
            const Color(0xFF2D1B5C).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Text('${theme['emoji']}',
              style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${setting['emoji']} ${setting['label']}',
                  style: const TextStyle(
                    fontFamily: 'PlayfairDisplay',
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    decoration: TextDecoration.none,
                  ),
                ),
                Text(
                  '${mood['label']}',
                  style: TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: Colors.white.withOpacity(0.6),
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
  // Game view (steps)
  // ---------------------------------------------------------------------------
  Widget _buildGameView() {
    final color = _currentPlayer == 1
        ? const Color(0xFFE879F9)
        : const Color(0xFFFFD166);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        children: [
          // Step progress (custom painted)
          SizedBox(
            height: 50,
            child: CustomPaint(
              size: Size.infinite,
              painter: _StepProgressPainter(
                totalSteps: 5,
                currentStep: _currentStep,
                pulse: _orbAnim.value,
              ),
            ),
          ),

          const SizedBox(height: 4),

          // Player turn shimmer pill
          AnimatedBuilder(
            animation: _shimmer,
            builder: (context, _) {
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withOpacity(0.18),
                      color.withOpacity(0.06),
                      color.withOpacity(0.18),
                    ],
                    stops: [0.0, _shimmer.value, 1.0],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [color, color.withOpacity(0.4)],
                        ),
                        boxShadow: [
                          BoxShadow(
                              color: color.withOpacity(0.5),
                              blurRadius: 12),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '$_currentPlayer',
                          style: const TextStyle(
                            fontFamily: 'PlayfairDisplay',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'game_ui.player_chooses'
                          .tr(namedArgs: {'player': '$_currentPlayer'}),
                      style: TextStyle(
                        fontFamily: 'PlayfairDisplay',
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    if (_vetoTriggered) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53935).withOpacity(0.25),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'games.fantasy_builder.vetoed'.tr(),
                          style: const TextStyle(
                            fontFamily: 'DMSans',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFFF6B6B),
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 14),

          // Step title with intro animation
          AnimatedBuilder(
            animation: _stepAnim,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, 14 * (1 - _stepAnim.value)),
                child: Opacity(opacity: _stepAnim.value, child: child),
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_stepIcons[_currentStep],
                    color: const Color(0xFFFFD166), size: 22),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    _stepTitles[_currentStep],
                    style: const TextStyle(
                      fontFamily: 'PlayfairDisplay',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      decoration: TextDecoration.none,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Content
          Expanded(
            child: AnimatedBuilder(
              animation: _stepAnim,
              builder: (context, child) {
                return Opacity(
                  opacity: _stepAnim.value,
                  child: Transform.translate(
                    offset: Offset(0, 18 * (1 - _stepAnim.value)),
                    child: child,
                  ),
                );
              },
              child:
                  _currentStep < 4 ? _buildOptionsGrid() : _buildCustomDetails(),
            ),
          ),

          // Action row: Sorpresa + Veto + Confirm
          _buildActionRow(),
        ],
      ),
    );
  }

  Widget _buildActionRow() {
    final canProceed = _canProceed();
    final otherPlayer = _currentPlayer == 1 ? 2 : 1;
    final otherVetoUsed =
        otherPlayer == 1 ? _player1VetoUsed : _player2VetoUsed;
    final canVeto = !otherVetoUsed && _currentSelection() != null && _currentStep < 4;

    return Column(
      children: [
        if (_currentStep < 4) ...[
          Row(
            children: [
              // Sorpresa (random pick)
              Expanded(
                child: GestureDetector(
                  onTap: _surprisePick,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
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
                            style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Text(
                          'games.fantasy_builder.random_pick'.tr(),
                          style: const TextStyle(
                            fontFamily: 'DMSans',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF3A2200),
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Veto (used by the OTHER player)
              Expanded(
                child: GestureDetector(
                  onTap: canVeto ? _useVeto : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: canVeto
                          ? const Color(0xFFE53935).withOpacity(0.15)
                          : Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: canVeto
                            ? const Color(0xFFE53935).withOpacity(0.5)
                            : Colors.white.withOpacity(0.08),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.front_hand,
                          color: canVeto
                              ? const Color(0xFFFF6B6B)
                              : Colors.white.withOpacity(0.3),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            otherVetoUsed
                                ? 'games.fantasy_builder.veto_used'.tr()
                                : 'games.fantasy_builder.gentle_veto'.tr(),
                            style: TextStyle(
                              fontFamily: 'DMSans',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: canVeto
                                  ? const Color(0xFFFF6B6B)
                                  : Colors.white.withOpacity(0.4),
                              decoration: TextDecoration.none,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        // Confirm
        AnimatedBuilder(
          animation: _shimmer,
          builder: (context, _) {
            return GestureDetector(
              onTap: canProceed ? _nextStep : null,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: canProceed ? 1.0 : 0.4,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(-1 + 2 * _shimmer.value, 0),
                      end: Alignment(1 + 2 * _shimmer.value, 0),
                      colors: const [
                        Color(0xFF6B2D5B),
                        Color(0xFFD946EF),
                        Color(0xFFE879F9),
                        Color(0xFFD946EF),
                        Color(0xFF6B2D5B),
                      ],
                      stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: canProceed
                        ? [
                            BoxShadow(
                              color: const Color(0xFFD946EF).withOpacity(0.5),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _currentStep < 4
                            ? Icons.arrow_forward_rounded
                            : Icons.auto_awesome,
                        color: Colors.white,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _currentStep < 4
                            ? 'game_ui.confirm_and_pass'.tr()
                            : 'game_ui.see_fantasy'.tr(),
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
              ),
            );
          },
        ),
        const SizedBox(height: 6),
        if (_currentStep > 0)
          TextButton.icon(
            onPressed: _prevStep,
            icon: Icon(Icons.arrow_back_ios_rounded,
                color: Colors.white.withOpacity(0.4), size: 14),
            label: Text(
              'common.back'.tr(),
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

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _selectedSetting != null;
      case 1:
        return _selectedMood != null;
      case 2:
        return _selectedAction != null;
      case 3:
        return _selectedSurprise != null;
      case 4:
        return true;
      default:
        return false;
    }
  }

  Widget _buildOptionsGrid() {
    final options = _currentOptions();
    final selectedValue = _currentSelection();

    return GridView.builder(
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.45,
      ),
      itemCount: options.length,
      itemBuilder: (context, index) {
        final option = options[index];
        final isSelected = selectedValue == option['value'];
        return GestureDetector(
          onTap: () => _selectOption(option['value']!),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isSelected
                    ? const [
                        Color(0xFFD946EF),
                        Color(0xFF6B2D5B),
                      ]
                    : [
                        Colors.white.withOpacity(0.05),
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
                        color: const Color(0xFFE879F9).withOpacity(0.4),
                        blurRadius: 18,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(option['emoji']!,
                    style: const TextStyle(fontSize: 30)),
                const SizedBox(height: 6),
                Text(
                  option['label']!,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'DMSans',
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withOpacity(0.85),
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
      },
    );
  }

  Widget _buildCustomDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'game_ui.add_special_details'.tr(),
          style: TextStyle(
            fontFamily: 'DMSans',
            color: Colors.white.withOpacity(0.7),
            fontSize: 13,
            decoration: TextDecoration.none,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _detailController,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _addDetail(),
                  style: const TextStyle(
                    fontFamily: 'DMSans',
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'game_ui.detail_hint'.tr(),
                    hintStyle: TextStyle(
                      fontFamily: 'DMSans',
                      color: Colors.white.withOpacity(0.4),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _addDetail(),
                icon: const Icon(Icons.add_circle, size: 28),
                color: const Color(0xFFE879F9),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _detailChips
              .where((c) => !_customDetails.contains(c))
              .map(
                (chip) => GestureDetector(
                  onTap: () => _addDetail(chip),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE879F9).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color:
                              const Color(0xFFE879F9).withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add,
                            size: 12, color: Color(0xFFE879F9)),
                        const SizedBox(width: 4),
                        Text(
                          chip,
                          style: const TextStyle(
                            fontFamily: 'DMSans',
                            color: Color(0xFFE879F9),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _customDetails.isEmpty
              ? Center(
                  child: Text(
                    'games.fantasy_builder.no_details_yet'.tr(),
                    style: TextStyle(
                      fontFamily: 'DMSans',
                      color: Colors.white.withOpacity(0.4),
                      fontStyle: FontStyle.italic,
                      fontSize: 13,
                      decoration: TextDecoration.none,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: _customDetails.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFE879F9).withOpacity(0.15),
                            const Color(0xFF6B2D5B).withOpacity(0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              const Color(0xFFE879F9).withOpacity(0.25),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Text('✨',
                              style: TextStyle(fontSize: 14)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _customDetails[index],
                              style: const TextStyle(
                                fontFamily: 'DMSans',
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              setState(
                                  () => _customDetails.removeAt(index));
                            },
                            child: Icon(Icons.close,
                                size: 18,
                                color: Colors.white.withOpacity(0.4)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Reveal view (cinematic)
  // ---------------------------------------------------------------------------
  Widget _buildRevealView() {
    final setting = _getOptionData('settings', _selectedSetting);
    final mood = _getOptionData('moods', _selectedMood);
    final actions =
        _intensity == 'soft' ? 'actions_soft' : 'actions_spicy';
    final action = _getOptionData(actions, _selectedAction);
    final surprise = _getOptionData('surprises', _selectedSurprise);
    final theme = _secretThemes[_secretThemeIndex ?? 0];

    return AnimatedBuilder(
      animation: _revealController,
      builder: (context, _) {
        final progress = _revealController.value;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            children: [
              // Magic circle + title
              SizedBox(
                height: 160,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 200,
                      height: 200,
                      child: CustomPaint(
                        painter: _MagicCirclePainter(
                          progress: progress,
                          rotation: _bgStars.value * 2 * pi,
                        ),
                      ),
                    ),
                    AnimatedBuilder(
                      animation: _orbAnim,
                      builder: (context, _) => Transform.scale(
                        scale: 0.95 + 0.1 * _orbAnim.value,
                        child: const Text(
                          '✨',
                          style: TextStyle(fontSize: 60),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'games.fantasy_builder.your_fantasy'.tr(),
                style: const TextStyle(
                  fontFamily: 'PlayfairDisplay',
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFFFD166),
                  letterSpacing: 1.4,
                  decoration: TextDecoration.none,
                  shadows: [
                    Shadow(color: Color(0xFFFFD166), blurRadius: 18),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Reveal each piece staggered (parchment cards)
              _revealPiece(
                progress: progress,
                start: 0.05,
                emoji: setting['emoji']!,
                label: 'game_ui.setting'.tr(),
                value: setting['label']!,
                color: const Color(0xFFE879F9),
              ),
              const SizedBox(height: 10),
              _revealPiece(
                progress: progress,
                start: 0.20,
                emoji: mood['emoji']!,
                label: 'game_ui.atmosphere'.tr(),
                value: mood['label']!,
                color: const Color(0xFFFF8FB1),
              ),
              const SizedBox(height: 10),
              _revealPiece(
                progress: progress,
                start: 0.35,
                emoji: action['emoji']!,
                label: 'game_ui.main_action'.tr(),
                value: action['label']!,
                color: const Color(0xFFFF6B35),
              ),
              const SizedBox(height: 10),
              _revealPiece(
                progress: progress,
                start: 0.50,
                emoji: surprise['emoji']!,
                label: 'game_ui.surprise'.tr(),
                value: surprise['label']!,
                color: const Color(0xFFFFD166),
              ),
              if (_customDetails.isNotEmpty) ...[
                const SizedBox(height: 10),
                _revealPiece(
                  progress: progress,
                  start: 0.65,
                  emoji: '📝',
                  label: 'game_ui.special_details'.tr(),
                  value: _customDetails.join(' · '),
                  color: const Color(0xFFB388FF),
                ),
              ],

              const SizedBox(height: 14),

              // Secret theme — last reveal, special styling
              _revealSecretTheme(progress, theme),

              const SizedBox(height: 22),

              // Narrative parchment
              _revealNarrative(
                  progress, setting, mood, action, surprise, theme),

              const SizedBox(height: 22),

              // Action buttons
              if (progress >= 0.92) _buildRevealActions(),
            ],
          ),
        );
      },
    );
  }

  Widget _revealPiece({
    required double progress,
    required double start,
    required String emoji,
    required String label,
    required String value,
    required Color color,
  }) {
    final localProgress = ((progress - start) / 0.15).clamp(0.0, 1.0);
    if (localProgress == 0) return const SizedBox.shrink();
    return Transform.translate(
      offset: Offset(0, 24 * (1 - localProgress)),
      child: Opacity(
        opacity: localProgress,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.18),
                color.withOpacity(0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.4)),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.25 * localProgress),
                blurRadius: 14,
                spreadRadius: 1,
              ),
            ],
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
                  child: Text(emoji,
                      style: const TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.5),
                        letterSpacing: 1,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _revealSecretTheme(double progress, Map<String, String> theme) {
    final localProgress =
        ((progress - 0.78) / 0.18).clamp(0.0, 1.0);
    if (localProgress == 0) return const SizedBox.shrink();
    return Transform.scale(
      scale: 0.85 + 0.15 * localProgress,
      child: Opacity(
        opacity: localProgress,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF6B2D5B),
                Color(0xFFD946EF),
                Color(0xFFFFD166),
              ],
              stops: [0.0, 0.55, 1.0],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: Colors.white.withOpacity(0.5), width: 1.2),
            boxShadow: [
              BoxShadow(
                color:
                    const Color(0xFFD946EF).withOpacity(0.5 * localProgress),
                blurRadius: 25,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            children: [
              Text(theme['emoji']!, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'games.fantasy_builder.secret_theme'.tr(),
                      style: const TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 11,
                        color: Colors.white,
                        letterSpacing: 1.2,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'games.fantasy_builder.themes.${theme['key']}'.tr(),
                      style: const TextStyle(
                        fontFamily: 'PlayfairDisplay',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        decoration: TextDecoration.none,
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

  Widget _revealNarrative(
    double progress,
    Map<String, String> setting,
    Map<String, String> mood,
    Map<String, String> action,
    Map<String, String> surprise,
    Map<String, String> theme,
  ) {
    final localProgress =
        ((progress - 0.85) / 0.15).clamp(0.0, 1.0);
    if (localProgress == 0) return const SizedBox.shrink();
    return Opacity(
      opacity: localProgress,
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFF1B0),
              Color(0xFFF5E0C3),
              Color(0xFFEAD2A8),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFD4A574).withOpacity(0.6),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD166).withOpacity(0.3),
              blurRadius: 22,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.auto_stories,
                    color: Color(0xFF6B2D5B), size: 18),
                const SizedBox(width: 8),
                Text(
                  'game_ui.your_story'.tr(),
                  style: const TextStyle(
                    fontFamily: 'PlayfairDisplay',
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6B2D5B),
                    letterSpacing: 1.2,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 1,
              width: 80,
              color: const Color(0xFF6B2D5B).withOpacity(0.3),
            ),
            const SizedBox(height: 12),
            Text(
              _buildNarrative(setting, mood, action, surprise, theme),
              style: const TextStyle(
                fontFamily: 'PlayfairDisplay',
                fontSize: 14,
                fontStyle: FontStyle.italic,
                height: 1.6,
                color: Color(0xFF3D1A2D),
                decoration: TextDecoration.none,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _buildNarrative(
    Map<String, String> setting,
    Map<String, String> mood,
    Map<String, String> action,
    Map<String, String> surprise,
    Map<String, String> theme,
  ) {
    final base = 'games.fantasy_builder.narrative.body'.tr(namedArgs: {
      'setting': (setting['label'] ?? '').toLowerCase(),
      'mood': (mood['label'] ?? '').toLowerCase(),
      'action': (action['label'] ?? '').toLowerCase(),
      'surprise': (surprise['label'] ?? '').toLowerCase(),
      'customDetails': _customDetails.isNotEmpty
          ? '\n\n${'games.fantasy_builder.narrative.your_special_details'.tr()}: ${_customDetails.join(", ")}.'
          : '',
    });
    final themeLabel = 'games.fantasy_builder.themes.${theme['key']}'.tr();
    return '$base\n\n${theme['emoji']} ${themeLabel.toUpperCase()} ${theme['emoji']}';
  }

  Widget _buildRevealActions() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _saveFantasy,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.18)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bookmark_add_outlined,
                          color: Colors.white.withOpacity(0.8), size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'games.fantasy_builder.save_scenario'.tr(),
                        style: TextStyle(
                          fontFamily: 'DMSans',
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.85),
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
            Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _startGame();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.18)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.refresh,
                          color: Colors.white.withOpacity(0.8), size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'game_ui.new_fantasy'.tr(),
                        style: TextStyle(
                          fontFamily: 'DMSans',
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.85),
                          fontWeight: FontWeight.w600,
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
        const SizedBox(height: 10),
        AnimatedBuilder(
          animation: _shimmer,
          builder: (context, _) {
            return GestureDetector(
              onTap: _showRealizationOptions,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
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
                      blurRadius: 22,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.local_fire_department,
                        color: Colors.white, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'game_ui.realize_it'.tr(),
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
    );
  }

  // ---------------------------------------------------------------------------
  // Realization options
  // ---------------------------------------------------------------------------
  void _showRealizationOptions() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2D1B5C),
              Color(0xFF1A0A2E),
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
            const SizedBox(height: 16),
            Center(
              child: Text(
                'game_ui.when_realize'.tr(),
                style: const TextStyle(
                  fontFamily: 'PlayfairDisplay',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFFFD166),
                  decoration: TextDecoration.none,
                ),
              ),
            ),
            const SizedBox(height: 18),
            _realizationTile('🌙', 'game_ui.tonight'.tr(),
                'game_ui.tonight_desc'.tr(), const Color(0xFFE879F9)),
            const SizedBox(height: 8),
            _realizationTile('📅', 'game_ui.this_weekend'.tr(),
                'game_ui.this_weekend_desc'.tr(), const Color(0xFFFFD166)),
            const SizedBox(height: 8),
            _realizationTile(
                '🎁',
                'game_ui.special_occasion'.tr(),
                'game_ui.special_occasion_desc'.tr(),
                const Color(0xFFFF6B35)),
            const SizedBox(height: 8),
            _realizationTile('💭', 'game_ui.just_fantasy'.tr(),
                'game_ui.just_fantasy_desc'.tr(), const Color(0xFFB388FF)),
          ],
        ),
      ),
    );
  }

  Widget _realizationTile(
      String emoji, String title, String subtitle, Color color) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${'game_ui.perfect'.tr()} $title',
                    style: const TextStyle(
                        fontFamily: 'DMSans', color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF6B2D5B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.2), color.withOpacity(0.06)],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.4)),
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
              ),
              child: Center(
                child: Text(emoji,
                    style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'PlayfairDisplay',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.6),
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: color.withOpacity(0.7)),
          ],
        ),
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
      builder: (context) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2D1B5C),
              Color(0xFF1A0A2E),
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
              'game_ui.how_it_works'.tr(),
              style: const TextStyle(
                fontFamily: 'PlayfairDisplay',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 16),
            _ruleRow('1', 'games.fantasy_builder.rules.rule_1'.tr()),
            const SizedBox(height: 10),
            _ruleRow('2', 'games.fantasy_builder.rules.rule_2'.tr()),
            const SizedBox(height: 10),
            _ruleRow('3', 'games.fantasy_builder.rules.rule_3'.tr()),
            const SizedBox(height: 10),
            _ruleRow('4', 'games.fantasy_builder.rules.rule_4'.tr()),
            const SizedBox(height: 18),
            Text(
              'games.fantasy_builder.rules.closing'.tr(),
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
class _BuiltFantasy {
  final String setting;
  final String mood;
  final String action;
  final String surprise;
  final List<String> details;
  final int themeIndex;
  final String intensity;
  final DateTime timestamp;

  _BuiltFantasy({
    required this.setting,
    required this.mood,
    required this.action,
    required this.surprise,
    required this.details,
    required this.themeIndex,
    required this.intensity,
    required this.timestamp,
  });
}

// =============================================================================
// Painters
// =============================================================================

/// Crystal ball with swirling magic inside.
class _CrystalBallPainter extends CustomPainter {
  final double pulse;
  final double innerProgress;

  _CrystalBallPainter({required this.pulse, required this.innerProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);
    final radius = w / 2 * 0.9;

    // Stand / base
    final basePath = Path()
      ..moveTo(w * 0.25, h * 0.95)
      ..lineTo(w * 0.4, h * 0.78)
      ..lineTo(w * 0.6, h * 0.78)
      ..lineTo(w * 0.75, h * 0.95)
      ..close();
    final basePaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, h * 0.78),
        Offset(0, h * 0.95),
        const [Color(0xFF8B4078), Color(0xFF3D1A2D)],
      );
    canvas.drawPath(basePath, basePaint);

    // Outer halo
    final haloPaint = Paint()
      ..shader = ui.Gradient.radial(
        center,
        radius * 1.5,
        [
          const Color(0xFFD946EF).withOpacity(0.45 * pulse),
          Colors.transparent,
        ],
      );
    canvas.drawCircle(center, radius * 1.5, haloPaint);

    // Glass orb
    final orbPaint = Paint()
      ..shader = ui.Gradient.radial(
        center - Offset(radius * 0.3, radius * 0.3),
        radius,
        const [
          Color(0xFFFCE4FF),
          Color(0xFFD946EF),
          Color(0xFF6B2D5B),
        ],
        [0.0, 0.55, 1.0],
      );
    canvas.drawCircle(center, radius, orbPaint);

    // Inner swirling magic — simulated with arcs at different angles
    final swirlPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFFFE7A0).withOpacity(0.65);
    final swirlRect = Rect.fromCircle(center: center, radius: radius * 0.5);
    final phase = innerProgress * 2 * pi;
    canvas.drawArc(swirlRect, phase, pi * 0.6, false, swirlPaint);
    canvas.drawArc(
        swirlRect, phase + pi, pi * 0.5, false, swirlPaint..color = const Color(0xFFFFB6C1).withOpacity(0.65));

    // Stars inside
    final starPaint = Paint()..color = Colors.white.withOpacity(0.85);
    canvas.drawCircle(
        center + Offset(cos(phase * 2) * radius * 0.55,
            sin(phase * 2) * radius * 0.55),
        2.5,
        starPaint);
    canvas.drawCircle(
        center +
            Offset(cos(phase * 2 + pi / 2) * radius * 0.4,
                sin(phase * 2 + pi / 2) * radius * 0.4),
        1.8,
        starPaint);

    // Outer rim
    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Colors.white.withOpacity(0.4);
    canvas.drawCircle(center, radius, rimPaint);

    // Specular highlight
    final shinePaint = Paint()
      ..shader = ui.Gradient.radial(
        center - Offset(radius * 0.4, radius * 0.45),
        radius * 0.25,
        [
          Colors.white.withOpacity(0.55),
          Colors.transparent,
        ],
      );
    canvas.drawCircle(
        center - Offset(radius * 0.4, radius * 0.45),
        radius * 0.25,
        shinePaint);
  }

  @override
  bool shouldRepaint(covariant _CrystalBallPainter old) =>
      old.pulse != pulse || old.innerProgress != innerProgress;
}

/// Step progress with circles + connecting line, current step pulses.
class _StepProgressPainter extends CustomPainter {
  final int totalSteps;
  final int currentStep;
  final double pulse;

  _StepProgressPainter({
    required this.totalSteps,
    required this.currentStep,
    required this.pulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cy = h / 2;
    final stepGap = w / (totalSteps + 0.0);
    final firstX = stepGap / 2;

    // Connecting line behind
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(firstX, cy),
      Offset(firstX + (totalSteps - 1) * stepGap, cy),
      linePaint,
    );

    // Filled progress line
    if (currentStep > 0) {
      final progressPaint = Paint()
        ..shader = ui.Gradient.linear(
          Offset(firstX, cy),
          Offset(firstX + currentStep * stepGap, cy),
          const [
            Color(0xFFD946EF),
            Color(0xFFFFD166),
          ],
        )
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(firstX, cy),
        Offset(firstX + currentStep * stepGap, cy),
        progressPaint,
      );
    }

    for (int i = 0; i < totalSteps; i++) {
      final cx = firstX + i * stepGap;
      final isCompleted = i < currentStep;
      final isCurrent = i == currentStep;

      // Glow for current
      if (isCurrent) {
        final glow = Paint()
          ..color = const Color(0xFFE879F9).withOpacity(0.45 * pulse)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
        canvas.drawCircle(Offset(cx, cy), 18 + 4 * pulse, glow);
      }

      // Background circle
      final bgPaint = Paint()
        ..color = isCompleted
            ? const Color(0xFFFFD166)
            : isCurrent
                ? const Color(0xFFE879F9)
                : Colors.white.withOpacity(0.15);
      canvas.drawCircle(Offset(cx, cy), isCurrent ? 13 : 10, bgPaint);

      // Border
      final borderPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.white.withOpacity(isCurrent ? 0.85 : 0.35);
      canvas.drawCircle(
          Offset(cx, cy), isCurrent ? 13 : 10, borderPaint);

      // Checkmark for completed
      if (isCompleted) {
        final checkPaint = Paint()
          ..color = const Color(0xFF3A2200)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
        canvas.drawLine(
            Offset(cx - 4, cy), Offset(cx - 1, cy + 3), checkPaint);
        canvas.drawLine(
            Offset(cx - 1, cy + 3), Offset(cx + 4, cy - 3), checkPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StepProgressPainter old) =>
      old.currentStep != currentStep || old.pulse != pulse;
}

/// Mystical magic circle with rotating runes for the reveal.
class _MagicCirclePainter extends CustomPainter {
  final double progress;
  final double rotation;

  _MagicCirclePainter({required this.progress, required this.rotation});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.width * 0.5;

    // Outer glow
    final glow = Paint()
      ..shader = ui.Gradient.radial(
        center,
        maxR,
        [
          const Color(0xFFD946EF).withOpacity(0.4 * progress),
          Colors.transparent,
        ],
      );
    canvas.drawCircle(center, maxR, glow);

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0xFFFFD166).withOpacity(0.6);

    // Rotating ring
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    // Outer ring
    canvas.drawCircle(Offset.zero, maxR * 0.85, ringPaint);
    // Inner ring
    canvas.drawCircle(
        Offset.zero,
        maxR * 0.6,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = const Color(0xFFE879F9).withOpacity(0.5));

    // Rune dots
    final runePaint = Paint()
      ..color = const Color(0xFFFFE7A0).withOpacity(0.85);
    for (int i = 0; i < 12; i++) {
      final a = (i / 12) * 2 * pi;
      final r = maxR * 0.85;
      canvas.drawCircle(
        Offset(cos(a) * r, sin(a) * r),
        2.2,
        runePaint,
      );
    }
    canvas.restore();

    // Counter-rotating star points
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-rotation * 0.5);
    final starPaint = Paint()
      ..color = Colors.white.withOpacity(0.6 * progress);
    for (int i = 0; i < 6; i++) {
      final a = (i / 6) * 2 * pi;
      canvas.drawCircle(Offset(cos(a) * maxR * 0.45, sin(a) * maxR * 0.45),
          1.5, starPaint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MagicCirclePainter old) =>
      old.progress != progress || old.rotation != rotation;
}

/// Twinkling stars + nebula background.
class _StarFieldPainter extends CustomPainter {
  final List<_Star> stars;
  final List<_Sparkle> sparkles;
  final double progress;

  _StarFieldPainter({
    required this.stars,
    required this.sparkles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Soft nebula orbs
    for (int i = 0; i < 4; i++) {
      final phase = (progress + i * 0.27) % 1.0;
      final cx = size.width * (0.2 + 0.6 * (i / 4)) +
          sin(phase * 2 * pi) * 30;
      final cy = size.height * (0.2 + 0.6 * ((i + 1) / 5)) +
          cos(phase * 2 * pi) * 30;
      final paint = Paint()
        ..shader = ui.Gradient.radial(
          Offset(cx, cy),
          120,
          [
            const Color(0xFFD946EF).withOpacity(0.07),
            Colors.transparent,
          ],
        );
      canvas.drawCircle(Offset(cx, cy), 120, paint);
    }

    // Stars (twinkling)
    final paint = Paint();
    for (final s in stars) {
      final twinkle =
          0.4 + 0.6 * (sin((progress + s.phase) * 2 * pi).abs());
      paint.color = Colors.white.withOpacity(0.45 * twinkle);
      canvas.drawCircle(
        Offset(s.x * size.width, s.y * size.height),
        s.size * twinkle,
        paint,
      );
    }

    // Magic sparkles drifting upward
    for (final sp in sparkles) {
      final phase = (sp.phase + progress * sp.speed) % 1.0;
      final x = sp.x * size.width +
          sin(phase * 2 * pi + sp.phase * 4) * 24;
      final y = (1 - phase) * size.height;
      final opacity =
          (0.2 + 0.4 * (1 - (phase - 0.5).abs() * 2)).clamp(0.0, 0.5);
      paint.color = sp.colorIdx == 0
          ? const Color(0xFFFFD166).withOpacity(opacity)
          : sp.colorIdx == 1
              ? const Color(0xFFE879F9).withOpacity(opacity)
              : Colors.white.withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), sp.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarFieldPainter old) =>
      old.progress != progress;
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

class _Sparkle {
  final double x;
  final double size;
  final double speed;
  final double phase;
  final int colorIdx;
  _Sparkle(Random r)
      : x = r.nextDouble(),
        size = 1.2 + r.nextDouble() * 2.5,
        speed = 0.2 + r.nextDouble() * 0.5,
        phase = r.nextDouble(),
        colorIdx = r.nextInt(3);
}
