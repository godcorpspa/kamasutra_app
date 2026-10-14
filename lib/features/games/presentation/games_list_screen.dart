import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../data/models/game.dart';
import '../../../shared/utils/display_text.dart';
import '../../../shared/widgets/brand.dart';

/// Games hub — an editorial index of the couple games: a featured game that
/// rotates daily, intensity filters and a numbered grid of dark cards, each
/// lit by a soft glow of its own muted jewel tone.
class GamesListScreen extends ConsumerStatefulWidget {
  const GamesListScreen({super.key});

  @override
  ConsumerState<GamesListScreen> createState() => _GamesListScreenState();
}

class _GamesListScreenState extends ConsumerState<GamesListScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entryController;
  late final Animation<double> _entryAnim;

  // 'all' / 'soft' / 'spicy' / 'extra' / 'quick'
  String _activeFilter = 'all';

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _entryAnim =
        CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic);
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Game catalog
  // ---------------------------------------------------------------------------
  static const List<_GameCardData> _allGames = [
    _GameCardData(
      route: AppRoutes.gooseGameSetup,
      nameKey: 'games.goose_game.title',
      icon: Icons.casino_outlined,
      tint: AppColors.jewelSand,
      players: '2',
      duration: '20-45',
      intensities: [
        GameIntensity.soft,
        GameIntensity.spicy,
        GameIntensity.extraSpicy,
      ],
      isImproved: true,
    ),
    _GameCardData(
      route: AppRoutes.truthDare,
      nameKey: 'games.truth_dare.title',
      icon: Icons.theater_comedy_outlined,
      tint: AppColors.jewelGarnet,
      players: '2',
      duration: '15-30',
      intensities: [
        GameIntensity.soft,
        GameIntensity.spicy,
        GameIntensity.extraSpicy,
      ],
      isImproved: true,
    ),
    _GameCardData(
      route: AppRoutes.wheel,
      nameKey: 'games.wheel.title',
      icon: Icons.donut_large,
      tint: AppColors.jewelAmber,
      players: '2',
      duration: '10-20',
      intensities: [GameIntensity.soft, GameIntensity.spicy],
      isImproved: true,
    ),
    _GameCardData(
      route: AppRoutes.hotCold,
      nameKey: 'games.hot_cold.title',
      icon: Icons.thermostat,
      tint: AppColors.jewelEmber,
      players: '2',
      duration: '15-25',
      intensities: [GameIntensity.spicy, GameIntensity.extraSpicy],
      isImproved: true,
    ),
    _GameCardData(
      route: AppRoutes.loveNotes,
      nameKey: 'games.love_notes.title',
      icon: Icons.mail_outline,
      tint: AppColors.jewelRose,
      players: '2',
      duration: '10-15',
      intensities: [GameIntensity.soft],
      isImproved: true,
    ),
    _GameCardData(
      route: AppRoutes.fantasyBuilder,
      nameKey: 'games.fantasy_builder.title',
      icon: Icons.auto_awesome_outlined,
      tint: AppColors.jewelLilac,
      players: '2',
      duration: '15-30',
      intensities: [
        GameIntensity.soft,
        GameIntensity.spicy,
        GameIntensity.extraSpicy,
      ],
      isImproved: true,
    ),
    _GameCardData(
      route: AppRoutes.complimentBattle,
      nameKey: 'games.compliment_battle.title',
      icon: Icons.workspace_premium_outlined,
      tint: AppColors.jewelAmber,
      players: '2',
      duration: '5-10',
      intensities: [GameIntensity.soft],
      isImproved: true,
    ),
    _GameCardData(
      route: AppRoutes.questionQuest,
      nameKey: 'games.question_quest.title',
      icon: Icons.forum_outlined,
      tint: AppColors.jewelDusk,
      players: '2',
      duration: '20-40',
      intensities: [GameIntensity.soft, GameIntensity.spicy],
      isImproved: true,
    ),
    _GameCardData(
      route: AppRoutes.twoMinutes,
      nameKey: 'games.two_minutes.title',
      icon: Icons.hourglass_empty,
      tint: AppColors.jewelEmber,
      players: '2',
      duration: '10-20',
      intensities: [
        GameIntensity.soft,
        GameIntensity.spicy,
        GameIntensity.extraSpicy,
      ],
      isImproved: true,
    ),
    _GameCardData(
      route: AppRoutes.intimacyMap,
      nameKey: 'games.intimacy_map.title',
      icon: Icons.map_outlined,
      tint: AppColors.jewelTeal,
      players: '2',
      duration: '15-25',
      intensities: [GameIntensity.soft, GameIntensity.spicy],
    ),
    _GameCardData(
      route: AppRoutes.soundtrack,
      nameKey: 'games.soundtrack.title',
      icon: Icons.music_note_outlined,
      tint: AppColors.jewelLilac,
      players: '2',
      duration: '10-20',
      intensities: [GameIntensity.soft],
    ),
    _GameCardData(
      route: AppRoutes.mirrorChallenge,
      nameKey: 'games.mirror_challenge.title',
      icon: Icons.flip,
      tint: AppColors.jewelRose,
      players: '2',
      duration: '5-15',
      intensities: [GameIntensity.soft, GameIntensity.spicy],
    ),
  ];

  List<_GameCardData> _filtered() {
    switch (_activeFilter) {
      case 'soft':
        return _allGames
            .where((g) => g.intensities.contains(GameIntensity.soft))
            .toList();
      case 'spicy':
        return _allGames
            .where((g) => g.intensities.contains(GameIntensity.spicy))
            .toList();
      case 'extra':
        return _allGames
            .where((g) => g.intensities.contains(GameIntensity.extraSpicy))
            .toList();
      case 'quick':
        return _allGames.where((g) {
          // duration like "10-20" → take min
          final m = RegExp(r'\d+').firstMatch(g.duration);
          if (m == null) return false;
          return int.parse(m.group(0)!) <= 15;
        }).toList();
      case 'all':
      default:
        return _allGames;
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
      body: VelvetBackground(
        child: SafeArea(
          child: FadeTransition(
            opacity: _entryAnim,
            child: SlideTransition(
              position: Tween(begin: const Offset(0, 0.03), end: Offset.zero)
                  .animate(_entryAnim),
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
                    SliverToBoxAdapter(
                        child: _buildGridLabel(filtered.length)),
                    _buildGrid(filtered),
                  ],
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------------
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'games.title'.tr(),
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 6),
          Text(
            'games.subtitle'.tr(),
            style: const TextStyle(
              fontFamily: AppTypography.displayFont,
              fontStyle: FontStyle.italic,
              fontSize: 18,
              color: AppColors.mist,
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
    const filters = [
      ('all', 'games_hub.filter_all'),
      ('soft', 'games_hub.filter_soft'),
      ('spicy', 'games_hub.filter_spicy'),
      ('extra', 'games_hub.filter_extra'),
      ('quick', 'games_hub.filter_quick'),
    ];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final (id, labelKey) = filters[i];
          final isActive = _activeFilter == id;
          return Material(
            color: isActive ? AppColors.champagne : Colors.transparent,
            shape: StadiumBorder(
              side: BorderSide(
                color: isActive ? AppColors.champagne : AppColors.outline,
              ),
            ),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _activeFilter = id);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Center(
                  child: Text(
                    plainLabel(labelKey.tr()),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                      color: isActive ? AppColors.onAccent : AppColors.ivory,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Featured banner
  // ---------------------------------------------------------------------------
  Widget _buildFeaturedBanner() {
    if (_activeFilter != 'all') return const SizedBox(height: 20);
    final game = _featured;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Material(
        color: AppColors.inkRaised,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: const BorderSide(color: AppColors.hairline),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            context.push(game.route);
          },
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(1.0, -1.0),
                radius: 1.3,
                colors: [game.tint.withOpacity(0.24), Colors.transparent],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        plainLabel('games_hub.featured'.tr()).toUpperCase(),
                        style: AppTypography.eyebrow
                            .copyWith(color: AppColors.champagne),
                      ),
                      const Spacer(),
                      _GameGlyph(game: game, size: 52),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    game.nameKey.tr(),
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(child: _MetaLine(game: game)),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.champagne,
                        ),
                        child: const Icon(
                          Icons.arrow_forward,
                          color: AppColors.onAccent,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGridLabel(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 14),
      child: Row(
        children: [
          Text(
            plainLabel('games_hub.all_games'.tr()).toUpperCase(),
            style: AppTypography.eyebrow,
          ),
          const SizedBox(width: 8),
          Text(
            '$count',
            style: AppTypography.eyebrow.copyWith(color: AppColors.champagne),
          ),
          const SizedBox(width: 12),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Grid
  // ---------------------------------------------------------------------------
  Widget _buildGrid(List<_GameCardData> games) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.86,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _GameCard(
            data: games[index],
            number: _allGames.indexOf(games[index]) + 1,
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
          const Icon(Icons.search_off, size: 40, color: AppColors.smoke),
          const SizedBox(height: 16),
          Text(
            'games_hub.no_games'.tr(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              setState(() => _activeFilter = 'all');
            },
            child: Text('games_hub.show_all'.tr()),
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
  final int number;
  final VoidCallback onTap;

  const _GameCard({
    required this.data,
    required this.number,
    required this.onTap,
  });

  @override
  State<_GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<_GameCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: AppColors.hairline),
            gradient: RadialGradient(
              center: const Alignment(-1.0, -1.0),
              radius: 1.2,
              colors: [data.tint.withOpacity(0.10), AppColors.inkRaised],
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _GameGlyph(game: data, size: 42),
                  const Spacer(),
                  Text(
                    widget.number.toString().padLeft(2, '0'),
                    style: const TextStyle(
                      fontFamily: AppTypography.displayFont,
                      fontFeatures: AppTypography.lining,
                      fontStyle: FontStyle.italic,
                      fontSize: 15,
                      color: AppColors.smoke,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                data.nameKey.tr(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: AppTypography.displayFont,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                  color: AppColors.ivory,
                ),
              ),
              const SizedBox(height: 10),
              _MetaLine(game: data, compact: true),
            ],
          ),
        ),
      ),
    );
  }
}

/// The game's line icon inside a hairline ring in its tint.
class _GameGlyph extends StatelessWidget {
  final _GameCardData game;
  final double size;

  const _GameGlyph({required this.game, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: game.tint.withOpacity(0.5)),
      ),
      child: Icon(game.icon, color: game.tint, size: size * 0.46),
    );
  }
}

/// "2 · 20–45′" plus intensity dots.
class _MetaLine extends StatelessWidget {
  final _GameCardData game;
  final bool compact;

  const _MetaLine({required this.game, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: compact ? 11.5 : 13,
      fontWeight: FontWeight.w500,
      color: AppColors.mist,
    );
    final iconSize = compact ? 13.0 : 15.0;
    return Row(
      children: [
        Icon(Icons.people_outline, size: iconSize, color: AppColors.smoke),
        const SizedBox(width: 4),
        Text(game.players, style: style),
        const SizedBox(width: 10),
        Icon(Icons.schedule, size: iconSize, color: AppColors.smoke),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            compact
                ? "${game.duration.replaceAll('-', '–')}'"
                : '${game.duration.replaceAll('-', '–')} min',
            style: style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        for (final intensity in game.intensities)
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(left: 4),
            decoration: BoxDecoration(
              color: _intensityColor(intensity),
              shape: BoxShape.circle,
            ),
          ),
      ],
    );
  }

  static Color _intensityColor(GameIntensity intensity) {
    switch (intensity) {
      case GameIntensity.soft:
        return AppColors.soft;
      case GameIntensity.spicy:
        return AppColors.spicy;
      case GameIntensity.extraSpicy:
        return AppColors.extraSpicy;
    }
  }
}

// =============================================================================
// Data
// =============================================================================
class _GameCardData {
  final String route;
  final String nameKey;
  final IconData icon;
  final Color tint;
  final String players;
  final String duration;
  final List<GameIntensity> intensities;
  final bool isImproved;

  const _GameCardData({
    required this.route,
    required this.nameKey,
    required this.icon,
    required this.tint,
    required this.players,
    required this.duration,
    required this.intensities,
    this.isImproved = false,
  });
}
