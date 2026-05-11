import 'dart:math';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class SoundtrackScreen extends StatefulWidget {
  const SoundtrackScreen({super.key});

  @override
  State<SoundtrackScreen> createState() => _SoundtrackScreenState();
}

class _SoundtrackScreenState extends State<SoundtrackScreen>
    with TickerProviderStateMixin {
  // ---------------------------------------------------------------------------
  // Game state
  // ---------------------------------------------------------------------------
  bool _gameStarted = false;
  bool _showingPlaylist = false;
  bool _waitingReaction = false; // partner is reacting to the just-added song
  int _currentPlayer = 1;
  int _currentRound = 0;
  int _promptCount = 8;

  final List<_PlaylistEntry> _playlist = [];
  final TextEditingController _songController = TextEditingController();
  final TextEditingController _artistController = TextEditingController();

  List<_PromptData> _selectedPrompts = [];

  // ---------------------------------------------------------------------------
  // Animations
  // ---------------------------------------------------------------------------
  late final AnimationController _bgController;
  late final AnimationController _vinylController;
  late final AnimationController _glowController;
  late final AnimationController _shimmerController;
  late final AnimationController _equalizerController;
  late final AnimationController _entryController;

  late Animation<double> _glowAnim;
  late Animation<double> _entryAnim;

  final List<_NoteParticle> _notes =
      List.generate(40, (i) => _NoteParticle(Random(i * 13 + 9)));

  final Random _random = Random();

  // ---------------------------------------------------------------------------
  // Prompt catalog
  // ---------------------------------------------------------------------------
  static const List<_PromptData> _promptCatalog = [
    _PromptData(
      key: 'first_impression',
      emoji: '✨',
      color: Color(0xFFB388FF),
    ),
    _PromptData(
      key: 'special_moment',
      emoji: '💕',
      color: Color(0xFFFF8FB1),
    ),
    _PromptData(
      key: 'road_trip',
      emoji: '🚗',
      color: Color(0xFF7DD3FC),
    ),
    _PromptData(
      key: 'romantic_evening',
      emoji: '🕯️',
      color: Color(0xFFFFD166),
    ),
    _PromptData(
      key: 'energy',
      emoji: '💃',
      color: Color(0xFF6EE7B7),
    ),
    _PromptData(
      key: 'comfort',
      emoji: '🤗',
      color: Color(0xFFE879F9),
    ),
    _PromptData(
      key: 'passion',
      emoji: '🔥',
      color: Color(0xFFE53935),
    ),
    _PromptData(
      key: 'nostalgia',
      emoji: '⏳',
      color: Color(0xFFA78BFA),
    ),
    _PromptData(
      key: 'future_together',
      emoji: '🌟',
      color: Color(0xFFFF8C42),
    ),
    _PromptData(
      key: 'our_song',
      emoji: '💑',
      color: Color(0xFFD946EF),
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

    _vinylController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _glowAnim = CurvedAnimation(parent: _glowController, curve: Curves.easeInOut);

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _equalizerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _entryAnim = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutCubic,
    );
    _entryController.forward();
  }

  @override
  void dispose() {
    _songController.dispose();
    _artistController.dispose();
    _bgController.dispose();
    _vinylController.dispose();
    _glowController.dispose();
    _shimmerController.dispose();
    _equalizerController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Game flow
  // ---------------------------------------------------------------------------
  void _startGame() {
    HapticFeedback.heavyImpact();
    final pool = List<_PromptData>.from(_promptCatalog)..shuffle(_random);
    setState(() {
      _selectedPrompts = pool.take(_promptCount).toList();
      _gameStarted = true;
      _showingPlaylist = false;
      _waitingReaction = false;
      _currentRound = 0;
      _currentPlayer = _random.nextInt(2) + 1;
      _playlist.clear();
      _songController.clear();
      _artistController.clear();
    });
    _entryController.forward(from: 0);
  }

  void _addSong() {
    if (_songController.text.trim().isEmpty) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Text('🎵 ', style: TextStyle(fontSize: 16)),
              Expanded(
                child: Text(
                  'game_ui.enter_song_title'.tr(),
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
    final prompt = _selectedPrompts[_currentRound];
    setState(() {
      _playlist.add(_PlaylistEntry(
        song: _songController.text.trim(),
        artist: _artistController.text.trim().isEmpty
            ? 'game_ui.unknown_artist'.tr()
            : _artistController.text.trim(),
        prompt: prompt,
        addedBy: _currentPlayer,
        reaction: null,
      ));
      _songController.clear();
      _artistController.clear();
      _waitingReaction = true;
    });
  }

  void _registerReaction(String? reactionId) {
    HapticFeedback.heavyImpact();
    if (reactionId != null) {
      _playlist[_playlist.length - 1] =
          _playlist.last.copyWith(reaction: reactionId);
    }
    setState(() {
      _waitingReaction = false;
      _currentPlayer = _currentPlayer == 1 ? 2 : 1;
      _currentRound++;
    });
    if (_currentRound >= _selectedPrompts.length) {
      setState(() => _showingPlaylist = true);
    } else {
      _entryController.forward(from: 0);
    }
  }

  void _skipPrompt() {
    HapticFeedback.lightImpact();
    setState(() {
      _currentPlayer = _currentPlayer == 1 ? 2 : 1;
      _currentRound++;
      _songController.clear();
      _artistController.clear();
    });
    if (_currentRound >= _selectedPrompts.length) {
      setState(() => _showingPlaylist = true);
    } else {
      _entryController.forward(from: 0);
    }
  }

  void _restartGame() {
    HapticFeedback.heavyImpact();
    setState(() {
      _gameStarted = false;
    });
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
                'games.soundtrack.app_bar_title'.tr(),
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
          // Concert/stage gradient background
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
              ),
            ),
          ),
          // Floating music notes
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, _) {
              return CustomPaint(
                size: Size.infinite,
                painter: _NotesFieldPainter(
                  notes: _notes,
                  progress: _bgController.value,
                ),
              );
            },
          ),
          SafeArea(
            child: !_gameStarted
                ? _buildSetupView()
                : _showingPlaylist
                    ? _buildPlaylistView()
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
              const Text('🎶', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text(
                'games.soundtrack.exit_confirm'.tr(),
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
          const SizedBox(height: 4),
          // Header — spinning vinyl
          AnimatedBuilder(
            animation: Listenable.merge(
                [_vinylController, _glowAnim, _equalizerController]),
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
                    Transform.rotate(
                      angle: _vinylController.value * 2 * pi,
                      child: SizedBox(
                        width: 160,
                        height: 160,
                        child: CustomPaint(
                          painter: _VinylPainter(),
                        ),
                      ),
                    ),
                    // Equalizer bars at bottom
                    Positioned(
                      bottom: 4,
                      child: SizedBox(
                        width: 120,
                        height: 30,
                        child: CustomPaint(
                          painter: _EqualizerPainter(
                            progress: _equalizerController.value,
                            color: const Color(0xFFD946EF),
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
            'games.soundtrack.app_bar_title'.tr(),
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
            'game_ui.create_love_playlist'.tr(),
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

          // Number of prompts
          _sectionLabel(
            icon: Icons.format_list_numbered,
            color: const Color(0xFFFFD166),
            label: 'games.soundtrack.prompts_count'.tr(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [5, 8, 10].map((count) {
              final isSelected = _promptCount == count;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _promptCount = count);
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

          // Theme preview chips
          _sectionLabel(
            icon: Icons.queue_music,
            color: const Color(0xFFB388FF),
            label: 'game_ui.playlist_themes'.tr(),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _promptCatalog.take(6).map((p) {
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      p.color.withOpacity(0.25),
                      p.color.withOpacity(0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: p.color.withOpacity(0.45)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(p.emoji, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      'soundtrack_prompts.${p.key}.title'.tr(),
                      style: TextStyle(
                        fontFamily: 'DMSans',
                        color: p.color,
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
          const SizedBox(height: 6),
          Text(
            'game_ui.and_more_themes'.tr(args: ['${_promptCatalog.length - 6}']),
            style: TextStyle(
              fontFamily: 'DMSans',
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: Colors.white.withOpacity(0.4),
              decoration: TextDecoration.none,
            ),
          ),

          const SizedBox(height: 22),

          // Features card
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
                      'games.soundtrack.features_title'.tr(),
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
                    _featureChip('💕',
                        'games.soundtrack.feature_reactions'.tr()),
                    _featureChip('🏆',
                        'games.soundtrack.feature_top_picks'.tr()),
                    _featureChip('🎲',
                        'games.soundtrack.feature_random'.tr()),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Start button — purple/pink shimmer
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
                        Color(0xFFFFD166),
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
                      const Icon(Icons.play_circle_filled,
                          color: Colors.white, size: 24),
                      const SizedBox(width: 10),
                      Text(
                        'game_ui.create_playlist'.tr(),
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
  // Game view (compose / react)
  // ---------------------------------------------------------------------------
  Widget _buildGameView() {
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
      child: _waitingReaction ? _buildReactionView() : _buildComposeView(),
    );
  }

  Widget _buildComposeView() {
    final prompt = _selectedPrompts[_currentRound];
    final color = _currentPlayer == 1
        ? const Color(0xFFE879F9)
        : const Color(0xFFFFD166);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        children: [
          // Top bar: progress + player
          _buildTopBar(),
          const SizedBox(height: 12),
          // Player turn shimmer pill
          _buildPlayerPill(color, label: 'game_ui.player_chooses'.tr(
                  namedArgs: {'player': '$_currentPlayer'})),
          const SizedBox(height: 14),
          // Prompt card with vinyl background
          _buildPromptCard(prompt),

          const SizedBox(height: 14),

          // Inputs
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _inputField(
                    controller: _songController,
                    icon: Icons.music_note,
                    label: 'game_ui.song_title_label'.tr(),
                    color: prompt.color,
                  ),
                  const SizedBox(height: 10),
                  _inputField(
                    controller: _artistController,
                    icon: Icons.person,
                    label: 'game_ui.artist_label'.tr(),
                    color: prompt.color,
                  ),
                ],
              ),
            ),
          ),

          // Action row
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _skipPrompt,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
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
                            color: Colors.white.withOpacity(0.6), size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'game_ui.skip_action'.tr(),
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
              Expanded(
                flex: 2,
                child: AnimatedBuilder(
                  animation: _shimmerController,
                  builder: (context, _) {
                    return GestureDetector(
                      onTap: _addSong,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment(
                                -1 + 2 * _shimmerController.value, 0),
                            end:
                                Alignment(1 + 2 * _shimmerController.value, 0),
                            colors: [
                              prompt.color.withOpacity(0.7),
                              prompt.color,
                              Colors.white.withOpacity(0.85),
                              prompt.color,
                              prompt.color.withOpacity(0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: prompt.color.withOpacity(0.5),
                              blurRadius: 18,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_circle_outline,
                                color: Colors.white, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'game_ui.add_btn'.tr(),
                              style: const TextStyle(
                                fontFamily: 'DMSans',
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
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
    );
  }

  Widget _buildReactionView() {
    final lastSong = _playlist.last;
    final reactingPlayer = lastSong.addedBy == 1 ? 2 : 1;
    final color = reactingPlayer == 1
        ? const Color(0xFFE879F9)
        : const Color(0xFFFFD166);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        children: [
          _buildTopBar(),
          const SizedBox(height: 12),
          _buildPlayerPill(color,
              label: 'games.soundtrack.partner_reacts'
                  .tr(namedArgs: {'player': '$reactingPlayer'})),
          const SizedBox(height: 18),
          // Album-style card showing the just-added song
          AnimatedBuilder(
            animation: _vinylController,
            builder: (context, _) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      lastSong.prompt.color.withOpacity(0.45),
                      lastSong.prompt.color.withOpacity(0.18),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: lastSong.prompt.color.withOpacity(0.55),
                      width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: lastSong.prompt.color.withOpacity(0.45),
                      blurRadius: 22,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Spinning vinyl mini
                    Transform.rotate(
                      angle: _vinylController.value * 2 * pi,
                      child: SizedBox(
                        width: 70,
                        height: 70,
                        child: CustomPaint(painter: _VinylPainter()),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(lastSong.prompt.emoji,
                                    style:
                                        const TextStyle(fontSize: 11)),
                                const SizedBox(width: 4),
                                Text(
                                  'soundtrack_prompts.${lastSong.prompt.key}.title'
                                      .tr(),
                                  style: const TextStyle(
                                    fontFamily: 'DMSans',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.6,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            lastSong.song,
                            style: const TextStyle(
                              fontFamily: 'PlayfairDisplay',
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              decoration: TextDecoration.none,
                              shadows: [
                                Shadow(
                                    color: Color(0x66000000), blurRadius: 4),
                              ],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            lastSong.artist,
                            style: TextStyle(
                              fontFamily: 'DMSans',
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                              color: Colors.white.withOpacity(0.85),
                              decoration: TextDecoration.none,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 18),
          Text(
            'games.soundtrack.react_prompt'.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'PlayfairDisplay',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'games.soundtrack.react_hint'.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'DMSans',
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: Colors.white.withOpacity(0.55),
              decoration: TextDecoration.none,
            ),
          ),
          const Spacer(),
          // Reactions row
          Row(
            children: const [
              _ReactionButton(
                  reactionId: 'love',
                  emoji: '💕',
                  color: Color(0xFFE53935)),
              SizedBox(width: 10),
              _ReactionButton(
                  reactionId: 'fire',
                  emoji: '🔥',
                  color: Color(0xFFFF6B35)),
              SizedBox(width: 10),
              _ReactionButton(
                  reactionId: 'nice',
                  emoji: '👍',
                  color: Color(0xFF7DD3FC)),
              SizedBox(width: 10),
              _ReactionButton(
                  reactionId: 'meh',
                  emoji: '🤔',
                  color: Color(0xFF9CA3AF)),
            ]
                .map<Widget>((w) => w is _ReactionButton
                    ? Expanded(
                        child: GestureDetector(
                          onTap: () => _registerReaction(w.reactionId),
                          child: _buildReactionButton(w),
                        ),
                      )
                    : w)
                .toList(),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => _registerReaction(null),
            icon: Icon(Icons.skip_next,
                color: Colors.white.withOpacity(0.4), size: 14),
            label: Text(
              'games.soundtrack.skip_reaction'.tr(),
              style: TextStyle(
                fontFamily: 'DMSans',
                color: Colors.white.withOpacity(0.4),
                fontSize: 12,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReactionButton(_ReactionButton b) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            b.color.withOpacity(0.3),
            b.color.withOpacity(0.10),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: b.color.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: b.color.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          b.emoji,
          style: const TextStyle(fontSize: 32),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // UI helpers
  // ---------------------------------------------------------------------------
  Widget _buildTopBar() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.queue_music,
                      color: Color(0xFFFFD166), size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'game_ui.song_of'.tr(namedArgs: {
                      'current': '${_currentRound + 1}',
                      'total': '${_selectedPrompts.length}',
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
                  Text(
                    '${_playlist.length} ♬',
                    style: const TextStyle(
                      fontFamily: 'PlayfairDisplay',
                      color: Color(0xFFE879F9),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  minHeight: 4,
                  value: (_currentRound + 1) / _selectedPrompts.length,
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

  Widget _buildPlayerPill(Color color, {required String label}) {
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
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'PlayfairDisplay',
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
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

  Widget _buildPromptCard(_PromptData prompt) {
    return AnimatedBuilder(
      animation: Listenable.merge([_glowAnim, _equalizerController]),
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                prompt.color.withOpacity(0.32),
                prompt.color.withOpacity(0.12),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border:
                Border.all(color: prompt.color.withOpacity(0.55), width: 1.4),
            boxShadow: [
              BoxShadow(
                color: prompt.color.withOpacity(0.35 + 0.18 * _glowAnim.value),
                blurRadius: 22,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      prompt.color.withOpacity(0.6),
                      prompt.color.withOpacity(0.15),
                    ],
                  ),
                  border: Border.all(color: prompt.color, width: 1.5),
                ),
                child: Center(
                    child: Text(prompt.emoji,
                        style: const TextStyle(fontSize: 28))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'soundtrack_prompts.${prompt.key}.title'.tr(),
                      style: const TextStyle(
                        fontFamily: 'PlayfairDisplay',
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.none,
                        shadows: [
                          Shadow(color: Color(0x66000000), blurRadius: 4),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'soundtrack_prompts.${prompt.key}.desc'.tr(),
                      style: TextStyle(
                        fontFamily: 'DMSans',
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 12,
                        height: 1.4,
                        decoration: TextDecoration.none,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 24,
                height: 30,
                child: CustomPaint(
                  painter: _EqualizerPainter(
                    progress: _equalizerController.value,
                    color: prompt.color,
                    bars: 3,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(
          fontFamily: 'DMSans',
          color: Colors.white,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            fontFamily: 'DMSans',
            color: Colors.white.withOpacity(0.6),
            fontSize: 13,
          ),
          floatingLabelStyle: TextStyle(color: color),
          prefixIcon: Icon(icon, color: color, size: 18),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 14),
        ),
        cursorColor: color,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Final playlist view
  // ---------------------------------------------------------------------------
  Widget _buildPlaylistView() {
    // Compute "top picks" based on reactions
    final reactionScore = {'love': 3, 'fire': 2, 'nice': 1, 'meh': 0};
    final scored = _playlist
        .map((s) => MapEntry(s, reactionScore[s.reaction ?? ''] ?? 0))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topPicks = scored.where((e) => e.value > 0).take(3).toList();
    final hearts = _playlist.fold<int>(0, (sum, s) {
      switch (s.reaction) {
        case 'love':
          return sum + 3;
        case 'fire':
          return sum + 2;
        case 'nice':
          return sum + 1;
        default:
          return sum;
      }
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
      child: Column(
        children: [
          // Header
          AnimatedBuilder(
            animation: _vinylController,
            builder: (context, _) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFFD946EF).withOpacity(0.4),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  Transform.rotate(
                    angle: _vinylController.value * 2 * pi,
                    child: SizedBox(
                      width: 130,
                      height: 130,
                      child: CustomPaint(painter: _VinylPainter()),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 6),
          Text(
            'game_ui.your_playlist'.tr(),
            style: const TextStyle(
              fontFamily: 'PlayfairDisplay',
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: Color(0xFFE879F9),
              decoration: TextDecoration.none,
              shadows: [
                Shadow(color: Color(0xFFE879F9), blurRadius: 18),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'game_ui.songs_count'
                .tr(namedArgs: {'count': '${_playlist.length}'}),
            style: TextStyle(
              fontFamily: 'DMSans',
              color: Colors.white.withOpacity(0.55),
              fontSize: 13,
              fontStyle: FontStyle.italic,
              decoration: TextDecoration.none,
            ),
          ),

          const SizedBox(height: 16),

          // Stats row
          Row(
            children: [
              Expanded(
                child: _statBox(
                  emoji: '💖',
                  label: 'games.soundtrack.total_hearts'.tr(),
                  value: '$hearts',
                  color: const Color(0xFFE53935),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _statBox(
                  emoji: '🎵',
                  label: 'games.soundtrack.songs_added'.tr(),
                  value: '${_playlist.length}',
                  color: const Color(0xFFFFD166),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _statBox(
                  emoji: '🏆',
                  label: 'games.soundtrack.top_picks'.tr(),
                  value: '${topPicks.length}',
                  color: const Color(0xFFB388FF),
                ),
              ),
            ],
          ),

          // Top picks
          if (topPicks.isNotEmpty) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0x33FFD166),
                    Color(0x33E53935),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: const Color(0xFFFFD166).withOpacity(0.4),
                    width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD166).withOpacity(0.35),
                    blurRadius: 20,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🏆',
                          style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 6),
                      Text(
                        'games.soundtrack.top_picks'.tr(),
                        style: const TextStyle(
                          fontFamily: 'PlayfairDisplay',
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFFFD166),
                          letterSpacing: 1,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...topPicks.asMap().entries.map((entry) {
                    final i = entry.key;
                    final song = entry.value.key;
                    return _topPickRow(rank: i + 1, song: song);
                  }),
                ],
              ),
            ),
          ],

          const SizedBox(height: 18),

          // Full playlist
          if (_playlist.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(Icons.music_off,
                      color: Colors.white.withOpacity(0.3), size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'game_ui.no_songs_added'.tr(),
                    style: TextStyle(
                      fontFamily: 'DMSans',
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 14,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            )
          else
            ..._playlist.asMap().entries.map((entry) {
              final i = entry.key;
              final song = entry.value;
              return _albumCard(song: song, index: i);
            }),

          const SizedBox(height: 18),

          // Actions
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => context.pop(),
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
                        'game_ui.exit'.tr(),
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
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: AnimatedBuilder(
                  animation: _shimmerController,
                  builder: (context, _) {
                    return GestureDetector(
                      onTap: _restartGame,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment(
                                -1 + 2 * _shimmerController.value, 0),
                            end:
                                Alignment(1 + 2 * _shimmerController.value, 0),
                            colors: const [
                              Color(0xFF6B2D5B),
                              Color(0xFFD946EF),
                              Color(0xFFFFD166),
                              Color(0xFFD946EF),
                              Color(0xFF6B2D5B),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFD946EF).withOpacity(0.5),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.refresh,
                                color: Colors.white, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'game_ui.new_playlist'.tr(),
                              style: const TextStyle(
                                fontFamily: 'DMSans',
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
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
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statBox({
    required String emoji,
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
          Text(emoji, style: const TextStyle(fontSize: 18)),
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

  Widget _topPickRow({required int rank, required _PlaylistEntry song}) {
    final medals = ['🥇', '🥈', '🥉'];
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(medals[rank - 1], style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song.song,
                  style: const TextStyle(
                    fontFamily: 'PlayfairDisplay',
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.none,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${song.artist} · ${'soundtrack_prompts.${song.prompt.key}.title'.tr()}',
                  style: TextStyle(
                    fontFamily: 'DMSans',
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    decoration: TextDecoration.none,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            _reactionEmoji(song.reaction),
            style: const TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _albumCard({required _PlaylistEntry song, required int index}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            song.prompt.color.withOpacity(0.18),
            song.prompt.color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: song.prompt.color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  song.prompt.color,
                  song.prompt.color.withOpacity(0.5),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: song.prompt.color.withOpacity(0.4),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Center(
              child: Text(song.prompt.emoji,
                  style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song.song,
                  style: const TextStyle(
                    fontFamily: 'PlayfairDisplay',
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.none,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  song.artist,
                  style: TextStyle(
                    fontFamily: 'DMSans',
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    decoration: TextDecoration.none,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${'soundtrack_prompts.${song.prompt.key}.title'.tr()} · P${song.addedBy}',
                  style: TextStyle(
                    fontFamily: 'DMSans',
                    color: song.prompt.color,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    decoration: TextDecoration.none,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (song.reaction != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _reactionEmoji(song.reaction),
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
          const SizedBox(width: 6),
          Text(
            '${index + 1}',
            style: TextStyle(
              fontFamily: 'PlayfairDisplay',
              color: Colors.white.withOpacity(0.25),
              fontSize: 22,
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }

  String _reactionEmoji(String? id) {
    switch (id) {
      case 'love':
        return '💕';
      case 'fire':
        return '🔥';
      case 'nice':
        return '👍';
      case 'meh':
        return '🤔';
      default:
        return '–';
    }
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
              _ruleRow('1', 'games.soundtrack.rule_1'.tr()),
              const SizedBox(height: 8),
              _ruleRow('2', 'games.soundtrack.rule_2'.tr()),
              const SizedBox(height: 8),
              _ruleRow('3', 'games.soundtrack.rule_3'.tr()),
              const SizedBox(height: 8),
              _ruleRow('4', 'games.soundtrack.rule_4'.tr()),
              const SizedBox(height: 8),
              _ruleRow('5', 'games.soundtrack.rule_5'.tr()),
              const SizedBox(height: 18),
              Text(
                'games.soundtrack.closing'.tr(),
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
// Data classes
// =============================================================================
class _PromptData {
  final String key;
  final String emoji;
  final Color color;
  const _PromptData({
    required this.key,
    required this.emoji,
    required this.color,
  });
}

class _PlaylistEntry {
  final String song;
  final String artist;
  final _PromptData prompt;
  final int addedBy;
  final String? reaction;

  const _PlaylistEntry({
    required this.song,
    required this.artist,
    required this.prompt,
    required this.addedBy,
    required this.reaction,
  });

  _PlaylistEntry copyWith({String? reaction}) => _PlaylistEntry(
        song: song,
        artist: artist,
        prompt: prompt,
        addedBy: addedBy,
        reaction: reaction ?? this.reaction,
      );
}

class _ReactionButton {
  final String reactionId;
  final String emoji;
  final Color color;
  const _ReactionButton({
    required this.reactionId,
    required this.emoji,
    required this.color,
  });
}

// =============================================================================
// Painters
// =============================================================================

/// Vinyl record with grooves and label.
class _VinylPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Outer disc
    final disc = Paint()
      ..shader = ui.Gradient.radial(
        center,
        radius,
        const [
          Color(0xFF1A1A1A),
          Color(0xFF000000),
        ],
      );
    canvas.drawCircle(center, radius, disc);

    // Grooves
    final groovePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6
      ..color = Colors.white.withOpacity(0.08);
    for (double r = radius * 0.42; r < radius * 0.95; r += 3) {
      canvas.drawCircle(center, r, groovePaint);
    }

    // Highlight reflection (slight)
    final shinePaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(center.dx - radius, center.dy - radius),
        Offset(center.dx + radius, center.dy + radius),
        [
          Colors.white.withOpacity(0.08),
          Colors.transparent,
          Colors.white.withOpacity(0.04),
        ],
        const [0.0, 0.5, 1.0],
      );
    canvas.drawCircle(center, radius, shinePaint);

    // Label (center)
    final labelPaint = Paint()
      ..shader = ui.Gradient.radial(
        center,
        radius * 0.4,
        const [
          Color(0xFFD946EF),
          Color(0xFF6B2D5B),
        ],
      );
    canvas.drawCircle(center, radius * 0.4, labelPaint);

    // Label border
    final labelBorder = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withOpacity(0.3);
    canvas.drawCircle(center, radius * 0.4, labelBorder);

    // Tiny ring inside label
    canvas.drawCircle(
      center,
      radius * 0.32,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6
        ..color = Colors.white.withOpacity(0.2),
    );

    // Center hole
    final holePaint = Paint()..color = const Color(0xFF050505);
    canvas.drawCircle(center, radius * 0.06, holePaint);

    // Tiny ♬ symbol at edge of label
    final tp = TextPainter(
      text: const TextSpan(
        text: '♬',
        style: TextStyle(
          color: Color(0xFFFFD166),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas,
        Offset(center.dx - tp.width / 2, center.dy + radius * 0.18));
  }

  @override
  bool shouldRepaint(covariant _VinylPainter old) => false;
}

/// Equalizer bars (animated vertical bars).
class _EqualizerPainter extends CustomPainter {
  final double progress;
  final Color color;
  final int bars;

  _EqualizerPainter({
    required this.progress,
    required this.color,
    this.bars = 5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final glowPaint = Paint()
      ..color = color.withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    final w = size.width / bars;
    for (int i = 0; i < bars; i++) {
      // Each bar oscillates with phase offset
      final phase = (progress + i * 0.15) % 1.0;
      // Sine wave for height between 0.3 and 1.0
      final h = 0.35 +
          0.65 * (0.5 + 0.5 * sin(phase * 2 * pi + i.toDouble()));
      final barH = size.height * h;
      final rect = Rect.fromLTWH(
        i * w + w * 0.2,
        size.height - barH,
        w * 0.6,
        barH,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(2)),
        glowPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(2)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _EqualizerPainter old) =>
      old.progress != progress || old.color != color;
}

/// Floating music notes background.
class _NotesFieldPainter extends CustomPainter {
  final List<_NoteParticle> notes;
  final double progress;

  _NotesFieldPainter({required this.notes, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // Soft nebula
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
              Color(0xFFFFD166),
              Color(0xFFB388FF),
              Color(0xFF7DD3FC),
            ][i % 4]
                .withOpacity(0.07),
            Colors.transparent,
          ],
        );
      canvas.drawCircle(Offset(cx, cy), 110, paint);
    }
    // Notes glyphs
    final symbols = ['♪', '♫', '♬', '♩'];
    final colors = [
      const Color(0xFFD946EF),
      const Color(0xFFE879F9),
      const Color(0xFFFFD166),
      const Color(0xFFB388FF),
    ];
    for (final n in notes) {
      final phase = (n.phase + progress * n.speed) % 1.0;
      final x = n.x * size.width + sin(phase * 2 * pi + n.phase * 4) * 22;
      final y = (1 - phase) * size.height;
      final opacity =
          (0.15 + 0.3 * (1 - (phase - 0.5).abs() * 2)).clamp(0.0, 0.4);

      final tp = TextPainter(
        text: TextSpan(
          text: symbols[n.colorIdx % 4],
          style: TextStyle(
            color: colors[n.colorIdx].withOpacity(opacity),
            fontSize: 8 + n.size * 6,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset(x, y));
    }
  }

  @override
  bool shouldRepaint(covariant _NotesFieldPainter old) =>
      old.progress != progress;
}

class _NoteParticle {
  final double x;
  final double size;
  final double speed;
  final double phase;
  final int colorIdx;
  _NoteParticle(Random r)
      : x = r.nextDouble(),
        size = 0.5 + r.nextDouble() * 1.5,
        speed = 0.15 + r.nextDouble() * 0.4,
        phase = r.nextDouble(),
        colorIdx = r.nextInt(4);
}
