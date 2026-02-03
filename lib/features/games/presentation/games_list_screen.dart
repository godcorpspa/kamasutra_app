import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../app/router.dart';
import '../../../data/models/game.dart';

/// Games hub screen showing all available mini-games
class GamesListScreen extends ConsumerWidget {
  const GamesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'games.title'.tr(),
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'games.subtitle'.tr(),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Games grid
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: AppSpacing.md,
                  crossAxisSpacing: AppSpacing.md,
                  childAspectRatio: 0.85,
                ),
                delegate: SliverChildListDelegate([
                  _GameCard(
                    game: _games[0], // Goose Game
                    color: AppColors.burgundy,
                    icon: Icons.casino,
                    onTap: () => context.push(AppRoutes.gooseGameSetup),
                  ),
                  _GameCard(
                    game: _games[1], // Truth or Dare
                    color: AppColors.spicy,
                    icon: Icons.psychology,
                    onTap: () => context.push(AppRoutes.truthDare),
                  ),
                  _GameCard(
                    game: _games[2], // Wheel
                    color: AppColors.gold,
                    icon: Icons.motion_photos_on,
                    onTap: () => context.push(AppRoutes.wheel),
                  ),
                  _GameCard(
                    game: _games[3], // Hot & Cold
                    color: AppColors.extraSpicy,
                    icon: Icons.thermostat,
                    onTap: () => context.push(AppRoutes.hotCold),
                  ),
                  _GameCard(
                    game: _games[4], // Love Notes
                    color: AppColors.blush,
                    icon: Icons.edit_note,
                    onTap: () => context.push(AppRoutes.loveNotes),
                  ),
                  _GameCard(
                    game: _games[5], // Fantasy Builder
                    color: const Color(0xFF6B4E71), // Purple
                    icon: Icons.auto_awesome,
                    onTap: () => context.push(AppRoutes.fantasyBuilder),
                  ),
                  _GameCard(
                    game: _games[6], // Compliment Battle
                    color: const Color(0xFF4A7C59), // Green
                    icon: Icons.favorite_border,
                    onTap: () => context.push(AppRoutes.complimentBattle),
                  ),
                  _GameCard(
                    game: _games[7], // Question Quest
                    color: AppColors.navy,
                    icon: Icons.question_answer,
                    onTap: () => context.push(AppRoutes.questionQuest),
                  ),
                  _GameCard(
                    game: _games[8], // Two Minutes
                    color: const Color(0xFFB85C38), // Terracotta
                    icon: Icons.timer,
                    onTap: () => context.push(AppRoutes.twoMinutes),
                  ),
                  _GameCard(
                    game: _games[9], // Intimacy Map
                    color: const Color(0xFF5C8984), // Teal
                    icon: Icons.map,
                    onTap: () => context.push(AppRoutes.intimacyMap),
                  ),
                  _GameCard(
                    game: _games[10], // Soundtrack
                    color: const Color(0xFF9B5DE5), // Violet
                    icon: Icons.music_note,
                    onTap: () => context.push(AppRoutes.soundtrack),
                  ),
                  _GameCard(
                    game: _games[11], // Mirror Challenge
                    color: const Color(0xFFE07A5F), // Coral
                    icon: Icons.compare_arrows,
                    onTap: () => context.push(AppRoutes.mirrorChallenge),
                  ),
                ]),
              ),
            ),
            
            // Bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
  }
}

/// Game data for display
final List<_GameInfo> _games = [
  _GameInfo(
    nameKey: 'games.goose_game.title',
    descriptionKey: 'games.goose_game.description',
    players: '2',
    duration: '20-45',
    intensities: [GameIntensity.soft, GameIntensity.spicy, GameIntensity.extraSpicy],
  ),
  _GameInfo(
    nameKey: 'games.truth_dare.title',
    descriptionKey: 'games.truth_dare.description',
    players: '2',
    duration: '15-30',
    intensities: [GameIntensity.soft, GameIntensity.spicy, GameIntensity.extraSpicy],
  ),
  _GameInfo(
    nameKey: 'games.wheel.title',
    descriptionKey: 'games.wheel.description',
    players: '2',
    duration: '10-20',
    intensities: [GameIntensity.soft, GameIntensity.spicy],
  ),
  _GameInfo(
    nameKey: 'games.hot_cold.title',
    descriptionKey: 'games.hot_cold.description',
    players: '2',
    duration: '15-25',
    intensities: [GameIntensity.spicy, GameIntensity.extraSpicy],
  ),
  _GameInfo(
    nameKey: 'games.love_notes.title',
    descriptionKey: 'games.love_notes.description',
    players: '2',
    duration: '10-15',
    intensities: [GameIntensity.soft],
  ),
  _GameInfo(
    nameKey: 'games.fantasy_builder.title',
    descriptionKey: 'games.fantasy_builder.description',
    players: '2',
    duration: '15-30',
    intensities: [GameIntensity.soft, GameIntensity.spicy, GameIntensity.extraSpicy],
  ),
  _GameInfo(
    nameKey: 'games.compliment_battle.title',
    descriptionKey: 'games.compliment_battle.description',
    players: '2',
    duration: '5-10',
    intensities: [GameIntensity.soft],
  ),
  _GameInfo(
    nameKey: 'games.question_quest.title',
    descriptionKey: 'games.question_quest.description',
    players: '2',
    duration: '20-40',
    intensities: [GameIntensity.soft, GameIntensity.spicy],
  ),
  _GameInfo(
    nameKey: 'games.two_minutes.title',
    descriptionKey: 'games.two_minutes.description',
    players: '2',
    duration: '10-20',
    intensities: [GameIntensity.soft, GameIntensity.spicy, GameIntensity.extraSpicy],
  ),
  _GameInfo(
    nameKey: 'games.intimacy_map.title',
    descriptionKey: 'games.intimacy_map.description',
    players: '2',
    duration: '15-25',
    intensities: [GameIntensity.soft, GameIntensity.spicy],
  ),
  _GameInfo(
    nameKey: 'games.soundtrack.title',
    descriptionKey: 'games.soundtrack.description',
    players: '2',
    duration: '10-20',
    intensities: [GameIntensity.soft],
  ),
  _GameInfo(
    nameKey: 'games.mirror_challenge.title',
    descriptionKey: 'games.mirror_challenge.description',
    players: '2',
    duration: '5-15',
    intensities: [GameIntensity.soft, GameIntensity.spicy],
  ),
];

class _GameInfo {
  final String nameKey;
  final String descriptionKey;
  final String players;
  final String duration;
  final List<GameIntensity> intensities;

  const _GameInfo({
    required this.nameKey,
    required this.descriptionKey,
    required this.players,
    required this.duration,
    required this.intensities,
  });
}

class _GameCard extends StatelessWidget {
  final _GameInfo game;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _GameCard({
    required this.game,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color,
              color.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              
              const Spacer(),
              
              // Name
              Text(
                game.nameKey.tr(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: AppSpacing.xs),
              
              // Info row
              Row(
                children: [
                  Icon(
                    Icons.people,
                    color: Colors.white.withOpacity(0.8),
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    game.players,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Icon(
                    Icons.timer,
                    color: Colors.white.withOpacity(0.8),
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${game.duration}\'',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: AppSpacing.sm),
              
              // Intensity dots
              Row(
                children: [
                  for (final intensity in game.intensities)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _getIntensityColor(intensity),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.5),
                            width: 1,
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

  Color _getIntensityColor(GameIntensity intensity) {
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
