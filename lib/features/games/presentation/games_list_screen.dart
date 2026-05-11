import 'dart:math';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../data/models/game.dart';

/// Games hub — premium cosmic look with categories, filters and a
/// rotating featured game.
class GamesListScreen extends ConsumerStatefulWidget {
  const GamesListScreen({super.key});

  @override
  ConsumerState<GamesListScreen> createState() => _GamesListScreenState();
}

class _GamesListScreenState extends ConsumerState<GamesListScreen>
    with TickerProviderStateMixin {
  late final AnimationController _bgController;
  late final AnimationController _glowController;
  late final AnimationController _shimmerController;
  late final AnimationController _entryController;

  late Animation<double> _glowAnim;
  late Animation<double> _entryAnim;

  final List<_Particle> _particles =
      List.generate(50, (i) => _Particle(Random(i * 13 + 9)));

  // 'all' / 'soft' / 'spicy' / 'extra' / 'quick'
  String _activeFilter = 'all';

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    )..repeat();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _glowAnim = CurvedAnimation(parent: _glowController, curve: Curves.easeInOut);

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _entryAnim =
        CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic);
    _entryController.forward();
  }

  @override
  void dispose() {
    _bgController.dispose();
    _glowController.dispose();
    _shimmerController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Game catalog
  // ---------------------------------------------------------------------------
  List<_GameCardData> get _allGames => const [
        _GameCardData(
          route: AppRoutes.gooseGameSetup,
          nameKey: 'games.goose_game.title',
          emoji: '🎲',
          gradient: [Color(0xFF722F37), Color(0xFFE53935)],
          glowColor: Color(0xFFE53935),
          players: '2',
          duration: '20-45',
          intensities: [
            GameIntensity.soft,
            GameIntensity.spicy,
            GameIntensity.extraSpicy,
          ],
          category: _GameCategory.classic,
          isImproved: true,
        ),
        _GameCardData(
          route: AppRoutes.truthDare,
          nameKey: 'games.truth_dare.title',
          emoji: '🎭',
          gradient: [Color(0xFF6B2D5B), Color(0xFFE53935)],
          glowColor: Color(0xFFE879F9),
          players: '2',
          duration: '15-30',
          intensities: [
            GameIntensity.soft,
            GameIntensity.spicy,
            GameIntensity.extraSpicy,
          ],
          category: _GameCategory.passion,
          isImproved: true,
        ),
        _GameCardData(
          route: AppRoutes.wheel,
          nameKey: 'games.wheel.title',
          emoji: '🎡',
          gradient: [Color(0xFFB8860B), Color(0xFFFFD166)],
          glowColor: Color(0xFFFFD166),
          players: '2',
          duration: '10-20',
          intensities: [GameIntensity.soft, GameIntensity.spicy],
          category: _GameCategory.passion,
          isImproved: true,
        ),
        _GameCardData(
          route: AppRoutes.hotCold,
          nameKey: 'games.hot_cold.title',
          emoji: '🌡️',
          gradient: [Color(0xFF1E90FF), Color(0xFFE53935)],
          glowColor: Color(0xFFFF6B35),
          players: '2',
          duration: '15-25',
          intensities: [GameIntensity.spicy, GameIntensity.extraSpicy],
          category: _GameCategory.passion,
          isImproved: true,
        ),
        _GameCardData(
          route: AppRoutes.loveNotes,
          nameKey: 'games.love_notes.title',
          emoji: '💌',
          gradient: [Color(0xFFFF8FB1), Color(0xFFE53935)],
          glowColor: Color(0xFFFF8FB1),
          players: '2',
          duration: '10-15',
          intensities: [GameIntensity.soft],
          category: _GameCategory.creative,
          isImproved: true,
        ),
        _GameCardData(
          route: AppRoutes.fantasyBuilder,
          nameKey: 'games.fantasy_builder.title',
          emoji: '✨',
          gradient: [Color(0xFF6B2D5B), Color(0xFFD946EF)],
          glowColor: Color(0xFFD946EF),
          players: '2',
          duration: '15-30',
          intensities: [
            GameIntensity.soft,
            GameIntensity.spicy,
            GameIntensity.extraSpicy,
          ],
          category: _GameCategory.creative,
          isImproved: true,
        ),
        _GameCardData(
          route: AppRoutes.complimentBattle,
          nameKey: 'games.compliment_battle.title',
          emoji: '🏆',
          gradient: [Color(0xFFE53935), Color(0xFFFFD166)],
          glowColor: Color(0xFFFFD166),
          players: '2',
          duration: '5-10',
          intensities: [GameIntensity.soft],
          category: _GameCategory.classic,
          isImproved: true,
        ),
        _GameCardData(
          route: AppRoutes.questionQuest,
          nameKey: 'games.question_quest.title',
          emoji: '🌌',
          gradient: [Color(0xFF1A0A4A), Color(0xFFB388FF)],
          glowColor: Color(0xFFB388FF),
          players: '2',
          duration: '20-40',
          intensities: [GameIntensity.soft, GameIntensity.spicy],
          category: _GameCategory.connection,
          isImproved: true,
        ),
        _GameCardData(
          route: AppRoutes.twoMinutes,
          nameKey: 'games.two_minutes.title',
          emoji: '⏱️',
          gradient: [Color(0xFFFF8C42), Color(0xFFFFD166)],
          glowColor: Color(0xFFFF6B35),
          players: '2',
          duration: '10-20',
          intensities: [
            GameIntensity.soft,
            GameIntensity.spicy,
            GameIntensity.extraSpicy,
          ],
          category: _GameCategory.connection,
          isImproved: true,
        ),
        _GameCardData(
          route: AppRoutes.intimacyMap,
          nameKey: 'games.intimacy_map.title',
          emoji: '🗺️',
          gradient: [Color(0xFF5C8984), Color(0xFF7DD3FC)],
          glowColor: Color(0xFF7DD3FC),
          players: '2',
          duration: '15-25',
          intensities: [GameIntensity.soft, GameIntensity.spicy],
          category: _GameCategory.connection,
        ),
        _GameCardData(
          route: AppRoutes.soundtrack,
          nameKey: 'games.soundtrack.title',
          emoji: '🎵',
          gradient: [Color(0xFF6B2D5B), Color(0xFF9B5DE5)],
          glowColor: Color(0xFF9B5DE5),
          players: '2',
          duration: '10-20',
          intensities: [GameIntensity.soft],
          category: _GameCategory.creative,
        ),
        _GameCardData(
          route: AppRoutes.mirrorChallenge,
          nameKey: 'games.mirror_challenge.title',
          emoji: '🪞',
          gradient: [Color(0xFFE07A5F), Color(0xFFFF8FB1)],
          glowColor: Color(0xFFE07A5F),
          players: '2',
          duration: '5-15',
          intensities: [GameIntensity.soft, GameIntensity.spicy],
          category: _GameCategory.connection,
        ),
      ];

  List<_GameCardData> _filtered() {
    final games = _allGames;
    switch (_activeFilter) {
      case 'soft':
        return games
            .where((g) => g.intensities.contains(GameIntensity.soft))
            .toList();
      case 'spicy':
        return games
            .where((g) => g.intensities.contains(GameIntensity.spicy))
            .toList();
      case 'extra':
        return games
            .where((g) => g.intensities.contains(GameIntensity.extraSpicy))
            .toList();
      case 'quick':
        return games.where((g) {
          // duration like "10-20" → take min
          final m = RegExp(r'\d+').firstMatch(g.duration);
          if (m == null) return false;
          return int.parse(m.group(0)!) <= 15;
        }).toList();
      case 'all':
      default:
        return games;
    }
  }

  /// Featured game — rotates daily based on day-of-year
  _GameCardData get _featured {
    final games = _allGames.where((g) => g.isImproved).toList();
    if (games.isEmpty) return _allGames.first;
    final dayOfYear =
        DateTime.now().difference(DateTime(DateTime.now().year)).inDays;
    return games[dayOfYear % games.length];
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final filtered = _filtered();

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Cosmic background
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
          // Floating particles
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, _) {
              return CustomPaint(
                size: Size.infinite,
                painter: _ParticleFieldPainter(
                  particles: _particles,
                  progress: _bgController.value,
                ),
              );
            },
          ),
          // Content
          SafeArea(
            child: AnimatedBuilder(
              animation: _entryAnim,
              builder: (context, child) {
                return Opacity(
                  opacity: _entryAnim.value,
                  child: Transform.translate(
                    offset: Offset(0, 24 * (1 - _entryAnim.value)),
                    child: child,
                  ),
                );
              },
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader()),
                  SliverToBoxAdapter(child: _buildFilterChips()),
                  SliverToBoxAdapter(child: _buildFeaturedBanner()),
                  if (filtered.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _emptyState(),
                    )
                  else ...[
                    SliverToBoxAdapter(child: _buildGridLabel(filtered.length)),
                    _buildGrid(filtered),
                  ],
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridLabel(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Row(
        children: [
          const Icon(Icons.style_outlined,
              color: Color(0xFFE879F9), size: 18),
          const SizedBox(width: 8),
          Text(
            'games_hub.all_games'.tr(),
            style: const TextStyle(
              fontFamily: 'PlayfairDisplay',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.4,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFE879F9).withOpacity(0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontFamily: 'DMSans',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFFE879F9),
                decoration: TextDecoration.none,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  // ---------------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------------
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
      child: Row(
        children: [
          // Animated icon
          AnimatedBuilder(
            animation: _glowAnim,
            builder: (context, _) {
              return Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFD946EF), Color(0xFFFFD166)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD946EF)
                          .withOpacity(0.4 + 0.25 * _glowAnim.value),
                      blurRadius: 22,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('🎮', style: TextStyle(fontSize: 26)),
                ),
              );
            },
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'games.title'.tr(),
                  style: const TextStyle(
                    fontFamily: 'PlayfairDisplay',
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                    decoration: TextDecoration.none,
                  ),
                ),
                Text(
                  'games.subtitle'.tr(),
                  style: TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: Colors.white.withOpacity(0.6),
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
          // Counter pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                const Icon(Icons.style,
                    color: Color(0xFFFFD166), size: 14),
                const SizedBox(width: 4),
                Text(
                  '${_allGames.length}',
                  style: const TextStyle(
                    fontFamily: 'PlayfairDisplay',
                    fontSize: 14,
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
    );
  }

  // ---------------------------------------------------------------------------
  // Filter chips
  // ---------------------------------------------------------------------------
  Widget _buildFilterChips() {
    final filters = [
      _Filter('all', 'games_hub.filter_all', null),
      _Filter('soft', 'games_hub.filter_soft', const Color(0xFFFF8FB1)),
      _Filter('spicy', 'games_hub.filter_spicy', const Color(0xFFFF6B35)),
      _Filter('extra', 'games_hub.filter_extra', const Color(0xFFE53935)),
      _Filter('quick', 'games_hub.filter_quick', const Color(0xFFFFD166)),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 14),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: filters.map((f) => _filterChip(f)).toList(),
        ),
      ),
    );
  }

  Widget _filterChip(_Filter f) {
    final isActive = _activeFilter == f.id;
    final color = f.color ?? const Color(0xFFE879F9);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _activeFilter = f.id);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            gradient: isActive
                ? LinearGradient(
                    colors: [color, color.withOpacity(0.7)],
                  )
                : null,
            color: isActive ? null : Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive ? color : Colors.white.withOpacity(0.1),
              width: isActive ? 1.5 : 1,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 14,
                    ),
                  ]
                : null,
          ),
          child: Text(
            f.labelKey.tr(),
            style: TextStyle(
              fontFamily: 'DMSans',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isActive ? Colors.white : Colors.white.withOpacity(0.7),
              letterSpacing: 0.3,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Featured banner
  // ---------------------------------------------------------------------------
  Widget _buildFeaturedBanner() {
    if (_activeFilter != 'all') return const SizedBox.shrink();
    final game = _featured;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          context.push(game.route);
        },
        child: AnimatedBuilder(
          animation: Listenable.merge([_shimmerController, _glowAnim]),
          builder: (context, _) {
            return Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    game.gradient[0].withOpacity(0.9),
                    game.gradient[1].withOpacity(0.7),
                    game.gradient[0].withOpacity(0.9),
                  ],
                  stops: [0.0, _shimmerController.value, 1.0],
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                    color: Colors.white.withOpacity(0.2), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: game.glowColor
                        .withOpacity(0.4 + 0.2 * _glowAnim.value),
                    blurRadius: 28,
                    spreadRadius: 2,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Big emoji disc
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withOpacity(0.4),
                          Colors.white.withOpacity(0.1),
                        ],
                      ),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.4), width: 1.5),
                    ),
                    child: Center(
                      child: Text(game.emoji,
                          style: const TextStyle(fontSize: 40)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'games_hub.featured'.tr(),
                            style: const TextStyle(
                              fontFamily: 'DMSans',
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 1.5,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          game.nameKey.tr(),
                          style: const TextStyle(
                            fontFamily: 'PlayfairDisplay',
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.3,
                            decoration: TextDecoration.none,
                            shadows: [
                              Shadow(color: Color(0x66000000), blurRadius: 6),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _miniBadge(Icons.people, '${game.players}p'),
                            const SizedBox(width: 6),
                            _miniBadge(Icons.timer, '${game.duration} min'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.2),
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _miniBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 11),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'DMSans',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Grid
  // ---------------------------------------------------------------------------
  Widget _buildGrid(List<_GameCardData> games) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.82,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _GameCard(
            data: games[index],
            glowAnim: _glowAnim,
            onTap: () {
              HapticFeedback.lightImpact();
              context.push(games[index].route);
            },
          ),
          childCount: games.length,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Empty state
  // ---------------------------------------------------------------------------
  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🔍', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 12),
          Text(
            'games_hub.no_games'.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'PlayfairDisplay',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _activeFilter = 'all');
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Text(
                'games_hub.show_all'.tr(),
                style: const TextStyle(
                  fontFamily: 'DMSans',
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Game card
// =============================================================================
class _GameCard extends StatefulWidget {
  final _GameCardData data;
  final Animation<double> glowAnim;
  final VoidCallback onTap;

  const _GameCard({
    required this.data,
    required this.glowAnim,
    required this.onTap,
  });

  @override
  State<_GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<_GameCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: AnimatedBuilder(
          animation: widget.glowAnim,
          builder: (context, _) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: widget.data.gradient,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: widget.data.glowColor.withOpacity(0.4),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.data.glowColor
                        .withOpacity(0.35 + 0.15 * widget.glowAnim.value),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Decorative emoji bg (very faded, big)
                  Positioned(
                    right: -10,
                    bottom: -16,
                    child: Opacity(
                      opacity: 0.12,
                      child: Text(
                        widget.data.emoji,
                        style: const TextStyle(fontSize: 110),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top row: emoji disc + improved badge
                        Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.18),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.3)),
                              ),
                              child: Center(
                                child: Text(
                                  widget.data.emoji,
                                  style: const TextStyle(fontSize: 22),
                                ),
                              ),
                            ),
                            const Spacer(),
                            if (widget.data.isImproved)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.22),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('✨',
                                        style: TextStyle(fontSize: 9)),
                                    const SizedBox(width: 3),
                                    Text(
                                      'games_hub.new_badge'.tr(),
                                      style: const TextStyle(
                                        fontFamily: 'DMSans',
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.6,
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const Spacer(),
                        // Title
                        Text(
                          widget.data.nameKey.tr(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'PlayfairDisplay',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.2,
                            decoration: TextDecoration.none,
                            shadows: [
                              Shadow(color: Color(0x66000000), blurRadius: 4),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Info row
                        Row(
                          children: [
                            Icon(Icons.people,
                                size: 11,
                                color: Colors.white.withOpacity(0.85)),
                            const SizedBox(width: 3),
                            Text(
                              widget.data.players,
                              style: TextStyle(
                                fontFamily: 'DMSans',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withOpacity(0.85),
                                decoration: TextDecoration.none,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.timer,
                                size: 11,
                                color: Colors.white.withOpacity(0.85)),
                            const SizedBox(width: 3),
                            Text(
                              '${widget.data.duration}\'',
                              style: TextStyle(
                                fontFamily: 'DMSans',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withOpacity(0.85),
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Intensity dots
                        Row(
                          children: [
                            for (final intensity
                                in widget.data.intensities)
                              Container(
                                width: 7,
                                height: 7,
                                margin: const EdgeInsets.only(right: 4),
                                decoration: BoxDecoration(
                                  color: _intensityColor(intensity),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.6),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _intensityColor(intensity)
                                          .withOpacity(0.6),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                          ],
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
    );
  }

  Color _intensityColor(GameIntensity intensity) {
    switch (intensity) {
      case GameIntensity.soft:
        return const Color(0xFFFF8FB1);
      case GameIntensity.spicy:
        return const Color(0xFFFF6B35);
      case GameIntensity.extraSpicy:
        return const Color(0xFFE53935);
    }
  }
}

// =============================================================================
// Data
// =============================================================================
enum _GameCategory {
  passion,
  connection,
  creative,
  classic,
}

class _GameCardData {
  final String route;
  final String nameKey;
  final String emoji;
  final List<Color> gradient;
  final Color glowColor;
  final String players;
  final String duration;
  final List<GameIntensity> intensities;
  final _GameCategory category;
  final bool isImproved;

  const _GameCardData({
    required this.route,
    required this.nameKey,
    required this.emoji,
    required this.gradient,
    required this.glowColor,
    required this.players,
    required this.duration,
    required this.intensities,
    required this.category,
    this.isImproved = false,
  });
}

class _Filter {
  final String id;
  final String labelKey;
  final Color? color;
  const _Filter(this.id, this.labelKey, this.color);
}

// =============================================================================
// Painter — floating colorful particles + nebula
// =============================================================================
class _Particle {
  final double x;
  final double size;
  final double speed;
  final double phase;
  final int colorIdx;

  _Particle(Random r)
      : x = r.nextDouble(),
        size = 1.5 + r.nextDouble() * 3,
        speed = 0.2 + r.nextDouble() * 0.45,
        phase = r.nextDouble(),
        colorIdx = r.nextInt(4);
}

class _ParticleFieldPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ParticleFieldPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // Nebula orbs
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
            const [
              Color(0xFFD946EF),
              Color(0xFFFFD166),
              Color(0xFFB388FF),
              Color(0xFFFF6B35),
            ][i % 4]
                .withOpacity(0.08),
            Colors.transparent,
          ],
        );
      canvas.drawCircle(Offset(cx, cy), 120, paint);
    }

    // Particles drifting upward
    final paint = Paint();
    final colors = [
      const Color(0xFFFFD166),
      const Color(0xFFE879F9),
      const Color(0xFFFFFFFF),
      const Color(0xFFFF6B35),
    ];
    for (final p in particles) {
      final phase = (p.phase + progress * p.speed) % 1.0;
      final x = p.x * size.width + sin(phase * 2 * pi + p.phase * 4) * 22;
      final y = (1 - phase) * size.height;
      final opacity =
          (0.15 + 0.35 * (1 - (phase - 0.5).abs() * 2)).clamp(0.0, 0.5);
      paint.color = colors[p.colorIdx].withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), p.size, paint);
      paint.color = colors[p.colorIdx].withOpacity(opacity * 0.3);
      canvas.drawCircle(Offset(x, y), p.size * 1.8, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticleFieldPainter old) =>
      old.progress != progress;
}
