import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/services/preferences_service.dart';
import '../../../data/repositories/position_repository.dart';
import '../../../data/providers/providers.dart';
import '../../../data/models/position.dart';
import '../../../app/theme.dart';

/// Progress screen showing badges, streaks, and statistics
class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen>
    with SingleTickerProviderStateMixin {
  
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Registra l'uso di oggi per la streak
    PreferencesService.instance.recordUsageToday();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'progress.title'.tr(),
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildStreakCard(),
                ],
              ),
            ),
            
            // Tab bar
            TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: 'progress.badges'.tr()),
                Tab(text: 'progress.statistics'.tr()),
                Tab(text: 'progress_ui.tried_tab'.tr()),
              ],
            ),
            
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildBadgesTab(),
                  _buildStatisticsTab(),
                  _buildHistoryTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // STREAK CARD — dati reali, layout pulito
  // ============================================================

  Widget _buildStreakCard() {
    final prefs = PreferencesService.instance;
    final streak = prefs.currentStreak;
    final longest = prefs.longestStreak;

    // Messaggio motivazionale in base alla streak
    String motivationalMessage;
    if (streak == 0) {
      motivationalMessage = 'progress_ui.motivational_0'.tr();
    } else if (streak == 1) {
      motivationalMessage = 'progress_ui.motivational_1'.tr();
    } else if (streak < 7) {
      motivationalMessage = 'progress_ui.motivational_7'.tr();
    } else if (streak < 30) {
      motivationalMessage = 'progress_ui.motivational_30'.tr();
    } else {
      motivationalMessage = 'progress_ui.motivational_100'.tr();
    }

    // Singolare / plurale
    String giorni(int n) => n == 1 ? 'progress_ui.day_singular'.tr() : 'progress_ui.day_plural'.tr(namedArgs: {'n': '$n'});

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.burgundy,
            AppColors.burgundy.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Icona fuoco
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    streak == 0 ? '💤' : '🔥',
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Serie attuale
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'progress_ui.current_streak'.tr(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withOpacity(0.7),
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      giorni(streak),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),

              // Serie più lunga
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Column(
                  children: [
                    Text(
                      'progress_ui.record'.tr(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withOpacity(0.7),
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      giorni(longest),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Messaggio motivazionale
          const SizedBox(height: AppSpacing.sm),
          Text(
            motivationalMessage,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.gold.withOpacity(0.9),
                ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BADGES TAB — criteri reali, tutti bloccati all'inizio
  // ============================================================

  Widget _buildBadgesTab() {
    final prefs = PreferencesService.instance;
    final repo = ref.read(positionRepositoryProvider);
    final triedCount = prefs.triedPositionIds.length;
    final gamesPlayed = prefs.gamesPlayed;
    final streak = prefs.longestStreak;
    final currentStreak = prefs.currentStreak;
    final favoritesCount = repo.positions.where((p) => p.isFavorite).length;
    final timeMins = prefs.timeTogetherMinutes;

    // Categorie uniche provate
    final triedIds = prefs.triedPositionIds;
    final Set<String> uniqueCategories = {};
    int highDiffCount = 0;
    for (final id in triedIds) {
      final position = repo.getById(id);
      if (position != null) {
        for (final cat in position.categories) {
          uniqueCategories.add(cat.name);
        }
        if (position.difficulty >= 4) highDiffCount++;
      }
    }
    final totalCategories = 8; // romantic, beginner, athletic, supported, lowImpact, adventurous, reconnect, quickie

    // Per-category tried counts
    final Map<String, int> categoryTriedCount = {};
    int lowEnergyCount = 0;
    int highEnergyCount = 0;
    int longDurationCount = 0;
    int veryHighDiffCount = 0;
    final Set<String> triedFocusTypes = {};
    for (final id in triedIds) {
      final position = repo.getById(id);
      if (position != null) {
        for (final cat in position.categories) {
          categoryTriedCount[cat.name] = (categoryTriedCount[cat.name] ?? 0) + 1;
        }
        if (position.energy == EnergyLevel.low) lowEnergyCount++;
        if (position.energy == EnergyLevel.high) highEnergyCount++;
        if (position.duration == PositionDuration.long) longDurationCount++;
        if (position.difficulty == 5) veryHighDiffCount++;
        for (final f in position.focus) {
          triedFocusTypes.add(f.name);
        }
      }
    }
    final totalFocusTypes = 7; // intimacy, variety, connection, relax, playfulness, passion, trust

    final badges = [
      // ── ESPLORAZIONE ──
      _BadgeData(
        emoji: '🌱',
        name: 'badge_list.first_step.name'.tr(),
        description: 'badge_list.first_step.desc'.tr(),
        isUnlocked: triedCount >= 1,
        progress: '${triedCount.clamp(0, 1)}/1',
      ),
      _BadgeData(
        emoji: '🧭',
        name: 'badge_list.explorer.name'.tr(),
        description: 'badge_list.explorer.desc'.tr(),
        isUnlocked: triedCount >= 5,
        progress: '${triedCount.clamp(0, 5)}/5',
      ),
      _BadgeData(
        emoji: '💫',
        name: 'badge_list.initiator.name'.tr(),
        description: 'badge_list.initiator.desc'.tr(),
        isUnlocked: triedCount >= 10,
        progress: '${triedCount.clamp(0, 10)}/10',
      ),
      _BadgeData(
        emoji: '⛰️',
        name: 'badge_list.adventurer.name'.tr(),
        description: 'badge_list.adventurer.desc'.tr(),
        isUnlocked: triedCount >= 20,
        progress: '${triedCount.clamp(0, 20)}/20',
      ),
      _BadgeData(
        emoji: '🌺',
        name: 'badge_list.enthusiast.name'.tr(),
        description: 'badge_list.enthusiast.desc'.tr(),
        isUnlocked: triedCount >= 30,
        progress: '${triedCount.clamp(0, 30)}/30',
      ),
      _BadgeData(
        emoji: '📚',
        name: 'badge_list.collector.name'.tr(),
        description: 'badge_list.collector.desc'.tr(),
        isUnlocked: triedCount >= 50,
        progress: '${triedCount.clamp(0, 50)}/50',
      ),
      _BadgeData(
        emoji: '💎',
        name: 'badge_list.master.name'.tr(),
        description: 'badge_list.master.desc'.tr(),
        isUnlocked: triedCount >= 100,
        progress: '${triedCount.clamp(0, 100)}/100',
      ),
      _BadgeData(
        emoji: '🌟',
        name: 'badge_list.legend.name'.tr(),
        description: 'badge_list.legend.desc'.tr(),
        isUnlocked: triedCount >= 150,
        progress: '${triedCount.clamp(0, 150)}/150',
      ),
      _BadgeData(
        emoji: '👑',
        name: 'badge_list.grand_master.name'.tr(),
        description: 'badge_list.grand_master.desc'.tr(),
        isUnlocked: triedCount >= 200,
        progress: '${triedCount.clamp(0, 200)}/200',
      ),

      // ── PREFERITI ──
      _BadgeData(
        emoji: '❤️',
        name: 'badge_list.first_spark.name'.tr(),
        description: 'badge_list.first_spark.desc'.tr(),
        isUnlocked: favoritesCount >= 1,
        progress: '${favoritesCount.clamp(0, 1)}/1',
      ),
      _BadgeData(
        emoji: '💕',
        name: 'badge_list.romantic.name'.tr(),
        description: 'badge_list.romantic.desc'.tr(),
        isUnlocked: favoritesCount >= 5,
        progress: '${favoritesCount.clamp(0, 5)}/5',
      ),
      _BadgeData(
        emoji: '💝',
        name: 'badge_list.big_heart.name'.tr(),
        description: 'badge_list.big_heart.desc'.tr(),
        isUnlocked: favoritesCount >= 10,
        progress: '${favoritesCount.clamp(0, 10)}/10',
      ),
      _BadgeData(
        emoji: '💖',
        name: 'badge_list.heart_collector.name'.tr(),
        description: 'badge_list.heart_collector.desc'.tr(),
        isUnlocked: favoritesCount >= 20,
        progress: '${favoritesCount.clamp(0, 20)}/20',
      ),

      // ── SERIE ──
      _BadgeData(
        emoji: '📅',
        name: 'badge_list.third_day.name'.tr(),
        description: 'badge_list.third_day.desc'.tr(),
        isUnlocked: streak >= 3,
        progress: '${streak.clamp(0, 3)}/3',
      ),
      _BadgeData(
        emoji: '🔥',
        name: 'badge_list.dedicated.name'.tr(),
        description: 'badge_list.dedicated.desc'.tr(),
        isUnlocked: streak >= 7,
        progress: '${streak.clamp(0, 7)}/7',
      ),
      _BadgeData(
        emoji: '⚡',
        name: 'badge_list.momentum.name'.tr(),
        description: 'badge_list.momentum.desc'.tr(),
        isUnlocked: streak >= 14,
        progress: '${streak.clamp(0, 14)}/14',
      ),
      _BadgeData(
        emoji: '🏆',
        name: 'badge_list.champion.name'.tr(),
        description: 'badge_list.champion.desc'.tr(),
        isUnlocked: streak >= 30,
        progress: '${streak.clamp(0, 30)}/30',
      ),
      _BadgeData(
        emoji: '🌙',
        name: 'badge_list.faithful.name'.tr(),
        description: 'badge_list.faithful.desc'.tr(),
        isUnlocked: streak >= 60,
        progress: '${streak.clamp(0, 60)}/60',
      ),
      _BadgeData(
        emoji: '☀️',
        name: 'badge_list.irresistible.name'.tr(),
        description: 'badge_list.irresistible.desc'.tr(),
        isUnlocked: streak >= 100,
        progress: '${streak.clamp(0, 100)}/100',
      ),
      _BadgeData(
        emoji: '✨',
        name: 'badge_list.on_streak.name'.tr(),
        description: 'badge_list.on_streak.desc'.tr(),
        isUnlocked: currentStreak >= 3,
        progress: 'progress_ui.streak_days'.tr(namedArgs: {'n': '$currentStreak'}),
      ),

      // ── GIOCHI ──
      _BadgeData(
        emoji: '🎮',
        name: 'badge_list.first_game.name'.tr(),
        description: 'badge_list.first_game.desc'.tr(),
        isUnlocked: gamesPlayed >= 1,
        progress: '${gamesPlayed.clamp(0, 1)}/1',
      ),
      _BadgeData(
        emoji: '🃏',
        name: 'badge_list.player.name'.tr(),
        description: 'badge_list.player.desc'.tr(),
        isUnlocked: gamesPlayed >= 5,
        progress: '${gamesPlayed.clamp(0, 5)}/5',
      ),
      _BadgeData(
        emoji: '💞',
        name: 'badge_list.soul_explorers.name'.tr(),
        description: 'badge_list.soul_explorers.desc'.tr(),
        isUnlocked: gamesPlayed >= 10,
        progress: '${gamesPlayed.clamp(0, 10)}/10',
      ),
      _BadgeData(
        emoji: '🎯',
        name: 'badge_list.game_expert.name'.tr(),
        description: 'badge_list.game_expert.desc'.tr(),
        isUnlocked: gamesPlayed >= 25,
        progress: '${gamesPlayed.clamp(0, 25)}/25',
      ),
      _BadgeData(
        emoji: '🏅',
        name: 'badge_list.professional.name'.tr(),
        description: 'badge_list.professional.desc'.tr(),
        isUnlocked: gamesPlayed >= 50,
        progress: '${gamesPlayed.clamp(0, 50)}/50',
      ),

      // ── CATEGORIE ──
      _BadgeData(
        emoji: '🌍',
        name: 'badge_list.world_explorer.name'.tr(),
        description: 'badge_list.world_explorer.desc'.tr(),
        isUnlocked: uniqueCategories.length >= 3,
        progress: '${uniqueCategories.length.clamp(0, 3)}/3',
      ),
      _BadgeData(
        emoji: '🌈',
        name: 'badge_list.versatile.name'.tr(),
        description: 'badge_list.versatile.desc'.tr(),
        isUnlocked: uniqueCategories.length >= 5,
        progress: '${uniqueCategories.length.clamp(0, 5)}/5',
      ),
      _BadgeData(
        emoji: '🎨',
        name: 'badge_list.complete_artist.name'.tr(),
        description: 'badge_list.complete_artist.desc'.tr(),
        isUnlocked: uniqueCategories.length >= totalCategories,
        progress: '${uniqueCategories.length.clamp(0, totalCategories)}/$totalCategories',
      ),

      // ── SFIDA ──
      _BadgeData(
        emoji: '💪',
        name: 'badge_list.brave.name'.tr(),
        description: 'badge_list.brave.desc'.tr(),
        isUnlocked: highDiffCount >= 5,
        progress: '${highDiffCount.clamp(0, 5)}/5',
      ),
      _BadgeData(
        emoji: '🦸',
        name: 'badge_list.acrobat.name'.tr(),
        description: 'badge_list.acrobat.desc'.tr(),
        isUnlocked: highDiffCount >= 15,
        progress: '${highDiffCount.clamp(0, 15)}/15',
      ),

      // ── TEMPO INSIEME ──
      _BadgeData(
        emoji: '⏱️',
        name: 'badge_list.first_hour.name'.tr(),
        description: 'badge_list.first_hour.desc'.tr(),
        isUnlocked: timeMins >= 60,
        progress: '${timeMins.clamp(0, 60)}/60 min',
      ),
      _BadgeData(
        emoji: '🕐',
        name: 'badge_list.time_lovers.name'.tr(),
        description: 'badge_list.time_lovers.desc'.tr(),
        isUnlocked: timeMins >= 300,
        progress: '${timeMins.clamp(0, 300)}/300 min',
      ),
      _BadgeData(
        emoji: '🌅',
        name: 'badge_list.deep_connection.name'.tr(),
        description: 'badge_list.deep_connection.desc'.tr(),
        isUnlocked: timeMins >= 1440,
        progress: '${timeMins.clamp(0, 1440)}/1440 min',
      ),

      // ── ESPLORAZIONE AVANZATA ──
      _BadgeData(
        emoji: '🌠',
        name: 'badge_list.summit.name'.tr(),
        description: 'badge_list.summit.desc'.tr(),
        isUnlocked: triedCount >= 250,
        progress: '${triedCount.clamp(0, 250)}/250',
      ),
      _BadgeData(
        emoji: '🎆',
        name: 'badge_list.olympian.name'.tr(),
        description: 'badge_list.olympian.desc'.tr(),
        isUnlocked: triedCount >= 300,
        progress: '${triedCount.clamp(0, 300)}/300',
      ),

      // ── PREFERITI AVANZATI ──
      _BadgeData(
        emoji: '💟',
        name: 'badge_list.great_collection.name'.tr(),
        description: 'badge_list.great_collection.desc'.tr(),
        isUnlocked: favoritesCount >= 30,
        progress: '${favoritesCount.clamp(0, 30)}/30',
      ),
      _BadgeData(
        emoji: '🏰',
        name: 'badge_list.love_castle.name'.tr(),
        description: 'badge_list.love_castle.desc'.tr(),
        isUnlocked: favoritesCount >= 50,
        progress: '${favoritesCount.clamp(0, 50)}/50',
      ),

      // ── SERIE AVANZATE ──
      _BadgeData(
        emoji: '🌞',
        name: 'badge_list.invincible.name'.tr(),
        description: 'badge_list.invincible.desc'.tr(),
        isUnlocked: streak >= 150,
        progress: '${streak.clamp(0, 150)}/150',
      ),
      _BadgeData(
        emoji: '🌌',
        name: 'badge_list.infinite.name'.tr(),
        description: 'badge_list.infinite.desc'.tr(),
        isUnlocked: streak >= 200,
        progress: '${streak.clamp(0, 200)}/200',
      ),
      _BadgeData(
        emoji: '📆',
        name: 'badge_list.year_together.name'.tr(),
        description: 'badge_list.year_together.desc'.tr(),
        isUnlocked: streak >= 365,
        progress: '${streak.clamp(0, 365)}/365',
      ),

      // ── GIOCHI AVANZATI ──
      _BadgeData(
        emoji: '🎲',
        name: 'badge_list.great_player.name'.tr(),
        description: 'badge_list.great_player.desc'.tr(),
        isUnlocked: gamesPlayed >= 75,
        progress: '${gamesPlayed.clamp(0, 75)}/75',
      ),
      _BadgeData(
        emoji: '🥇',
        name: 'badge_list.games_champion.name'.tr(),
        description: 'badge_list.games_champion.desc'.tr(),
        isUnlocked: gamesPlayed >= 100,
        progress: '${gamesPlayed.clamp(0, 100)}/100',
      ),
      _BadgeData(
        emoji: '🎪',
        name: 'badge_list.games_master.name'.tr(),
        description: 'badge_list.games_master.desc'.tr(),
        isUnlocked: gamesPlayed >= 150,
        progress: '${gamesPlayed.clamp(0, 150)}/150',
      ),
      _BadgeData(
        emoji: '🎉',
        name: 'badge_list.games_legend.name'.tr(),
        description: 'badge_list.games_legend.desc'.tr(),
        isUnlocked: gamesPlayed >= 200,
        progress: '${gamesPlayed.clamp(0, 200)}/200',
      ),

      // ── SFIDA AVANZATA ──
      _BadgeData(
        emoji: '⚔️',
        name: 'badge_list.warrior.name'.tr(),
        description: 'badge_list.warrior.desc'.tr(),
        isUnlocked: highDiffCount >= 25,
        progress: '${highDiffCount.clamp(0, 25)}/25',
      ),
      _BadgeData(
        emoji: '🦅',
        name: 'badge_list.eagle.name'.tr(),
        description: 'badge_list.eagle.desc'.tr(),
        isUnlocked: highDiffCount >= 30,
        progress: '${highDiffCount.clamp(0, 30)}/30',
      ),
      _BadgeData(
        emoji: '🎭',
        name: 'badge_list.extreme.name'.tr(),
        description: 'badge_list.extreme.desc'.tr(),
        isUnlocked: veryHighDiffCount >= 3,
        progress: '${veryHighDiffCount.clamp(0, 3)}/3',
      ),
      _BadgeData(
        emoji: '🦁',
        name: 'badge_list.ultras.name'.tr(),
        description: 'badge_list.ultras.desc'.tr(),
        isUnlocked: veryHighDiffCount >= 10,
        progress: '${veryHighDiffCount.clamp(0, 10)}/10',
      ),

      // ── TEMPO INSIEME AVANZATO ──
      _BadgeData(
        emoji: '🌊',
        name: 'badge_list.ocean_of_time.name'.tr(),
        description: 'badge_list.ocean_of_time.desc'.tr(),
        isUnlocked: timeMins >= 600,
        progress: '${timeMins.clamp(0, 600)}/600 min',
      ),
      _BadgeData(
        emoji: '🌃',
        name: 'badge_list.endless_night.name'.tr(),
        description: 'badge_list.endless_night.desc'.tr(),
        isUnlocked: timeMins >= 2880,
        progress: '${timeMins.clamp(0, 2880)}/2880 min',
      ),
      _BadgeData(
        emoji: '☄️',
        name: 'badge_list.a_journey.name'.tr(),
        description: 'badge_list.a_journey.desc'.tr(),
        isUnlocked: timeMins >= 6000,
        progress: '${timeMins.clamp(0, 6000)}/6000 min',
      ),

      // ── CATEGORIE SPECIFICHE ──
      _BadgeData(
        emoji: '🌹',
        name: 'badge_list.romantic_heart.name'.tr(),
        description: 'badge_list.romantic_heart.desc'.tr(),
        isUnlocked: (categoryTriedCount['romantic'] ?? 0) >= 5,
        progress: '${(categoryTriedCount['romantic'] ?? 0).clamp(0, 5)}/5',
      ),
      _BadgeData(
        emoji: '🌿',
        name: 'badge_list.expert_beginner.name'.tr(),
        description: 'badge_list.expert_beginner.desc'.tr(),
        isUnlocked: (categoryTriedCount['beginner'] ?? 0) >= 5,
        progress: '${(categoryTriedCount['beginner'] ?? 0).clamp(0, 5)}/5',
      ),
      _BadgeData(
        emoji: '🏋️',
        name: 'badge_list.passionate_athlete.name'.tr(),
        description: 'badge_list.passionate_athlete.desc'.tr(),
        isUnlocked: (categoryTriedCount['athletic'] ?? 0) >= 5,
        progress: '${(categoryTriedCount['athletic'] ?? 0).clamp(0, 5)}/5',
      ),
      _BadgeData(
        emoji: '🤝',
        name: 'badge_list.supported_couple.name'.tr(),
        description: 'badge_list.supported_couple.desc'.tr(),
        isUnlocked: (categoryTriedCount['supported'] ?? 0) >= 5,
        progress: '${(categoryTriedCount['supported'] ?? 0).clamp(0, 5)}/5',
      ),
      _BadgeData(
        emoji: '🦋',
        name: 'badge_list.light_touch.name'.tr(),
        description: 'badge_list.light_touch.desc'.tr(),
        isUnlocked: (categoryTriedCount['lowImpact'] ?? 0) >= 5,
        progress: '${(categoryTriedCount['lowImpact'] ?? 0).clamp(0, 5)}/5',
      ),
      _BadgeData(
        emoji: '🗺️',
        name: 'badge_list.adventurous_spirit.name'.tr(),
        description: 'badge_list.adventurous_spirit.desc'.tr(),
        isUnlocked: (categoryTriedCount['adventurous'] ?? 0) >= 5,
        progress: '${(categoryTriedCount['adventurous'] ?? 0).clamp(0, 5)}/5',
      ),
      _BadgeData(
        emoji: '🔗',
        name: 'badge_list.bonds_found.name'.tr(),
        description: 'badge_list.bonds_found.desc'.tr(),
        isUnlocked: (categoryTriedCount['reconnect'] ?? 0) >= 5,
        progress: '${(categoryTriedCount['reconnect'] ?? 0).clamp(0, 5)}/5',
      ),
      _BadgeData(
        emoji: '⚡',
        name: 'badge_list.extreme_speed.name'.tr(),
        description: 'badge_list.extreme_speed.desc'.tr(),
        isUnlocked: (categoryTriedCount['quickie'] ?? 0) >= 5,
        progress: '${(categoryTriedCount['quickie'] ?? 0).clamp(0, 5)}/5',
      ),

      // ── DIVERSITÀ ──
      _BadgeData(
        emoji: '🌬️',
        name: 'badge_list.calm_relax.name'.tr(),
        description: 'badge_list.calm_relax.desc'.tr(),
        isUnlocked: lowEnergyCount >= 5,
        progress: '${lowEnergyCount.clamp(0, 5)}/5',
      ),
      _BadgeData(
        emoji: '💥',
        name: 'badge_list.high_energy.name'.tr(),
        description: 'badge_list.high_energy.desc'.tr(),
        isUnlocked: highEnergyCount >= 5,
        progress: '${highEnergyCount.clamp(0, 5)}/5',
      ),
      _BadgeData(
        emoji: '🐢',
        name: 'badge_list.take_time.name'.tr(),
        description: 'badge_list.take_time.desc'.tr(),
        isUnlocked: longDurationCount >= 3,
        progress: '${longDurationCount.clamp(0, 3)}/3',
      ),
      _BadgeData(
        emoji: '🔭',
        name: 'badge_list.full_focus.name'.tr(),
        description: 'badge_list.full_focus.desc'.tr(),
        isUnlocked: triedFocusTypes.length >= totalFocusTypes,
        progress: '${triedFocusTypes.length.clamp(0, totalFocusTypes)}/$totalFocusTypes',
      ),
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 0.8,
      ),
      itemCount: badges.length,
      itemBuilder: (context, index) {
        final badge = badges[index];
        return _buildBadgeCard(badge);
      },
    );
  }

  Widget _buildBadgeCard(_BadgeData badge) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Row(
              children: [
                Text(
                  badge.isUnlocked ? badge.emoji : '🔒',
                  style: const TextStyle(fontSize: 28),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    badge.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(badge.description),
                const SizedBox(height: 8),
                Text(
                  'progress_ui.progress_label'.tr(namedArgs: {'progress': badge.progress}),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                if (!badge.isUnlocked) ...[
                  const SizedBox(height: 8),
                  Text(
                    'progress_ui.keep_exploring'.tr(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: badge.isUnlocked
              ? Theme.of(context).colorScheme.surface
              : Theme.of(context).colorScheme.surface.withOpacity(0.4),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: badge.isUnlocked
                ? AppColors.gold.withOpacity(0.5)
                : Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              badge.isUnlocked ? badge.emoji : '🔒',
              style: const TextStyle(fontSize: 36),
            ),
            const SizedBox(height: 8),
            Text(
              badge.name,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: badge.isUnlocked
                        ? null
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.4),
                  ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // STATISTICS TAB — dati reali da zero
  // ============================================================

  Widget _buildStatisticsTab() {
    final prefs = PreferencesService.instance;
    final repo = ref.read(positionRepositoryProvider);

    // Dati reali
    final triedCount = prefs.triedPositionIds.length;
    final gamesPlayed = prefs.gamesPlayed;
    final timeTogether = prefs.formattedTimeTogether;
    final favoritesCount = repo.positions.where((p) => p.isFavorite).length;

    // Categorie esplorate
    final triedIds = prefs.triedPositionIds;
    final Map<String, int> categoryCount = {};
    int totalTried = 0;

    for (final id in triedIds) {
      final position = repo.getById(id);
      if (position != null) {
        for (final cat in position.categories) {
          categoryCount[cat.name] = (categoryCount[cat.name] ?? 0) + 1;
        }
        totalTried++;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          _buildStatRow(
            icon: Icons.explore,
            label: 'progress_ui.positions_explored'.tr(),
            value: '$triedCount',
            color: AppColors.burgundy,
          ),
          _buildStatRow(
            icon: Icons.casino,
            label: 'progress_ui.games_played'.tr(),
            value: '$gamesPlayed',
            color: AppColors.gold,
          ),
          _buildStatRow(
            icon: Icons.timer,
            label: 'progress_ui.time_together'.tr(),
            value: timeTogether,
            color: AppColors.navy,
          ),
          _buildStatRow(
            icon: Icons.favorite,
            label: 'progress_ui.favorites_saved'.tr(),
            value: '$favoritesCount',
            color: AppColors.blush,
          ),
          
          const SizedBox(height: AppSpacing.xl),
          
          // Categorie esplorate
          Text(
            'progress_ui.categories_explored'.tr(),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.md),

          if (categoryCount.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                'progress_ui.start_exploring_stats'.tr(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.5),
                    ),
                textAlign: TextAlign.center,
              ),
            )
          else
            ...categoryCount.entries.map((entry) {
              final percentage = totalTried > 0
                  ? (entry.value / totalTried)
                  : 0.0;
              return _buildCategoryProgress(
                'categories.${entry.key}'.tr(),
                percentage,
                AppColors.burgundy,
              );
            }),
        ],
      ),
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryProgress(String category, double progress, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(category, style: Theme.of(context).textTheme.bodySmall),
              Text(
                '${(progress * 100).round()}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HISTORY TAB (Provate) — già funzionante con dati reali
  // ============================================================

  Widget _buildHistoryTab() {
    final locale = context.locale.languageCode;
    final triedIds = PreferencesService.instance.triedPositionIds;
    final repo = PositionRepository.instance;

    if (triedIds.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.explore_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'progress_ui.no_tried_yet'.tr(),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'progress_ui.explore_catalog_hint'.tr(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.4),
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: triedIds.length,
      itemBuilder: (context, index) {
        final positionId = triedIds[triedIds.length - 1 - index];
        final position = repo.getById(positionId);

        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            children: [
              const Text('✅', style: TextStyle(fontSize: 24)),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      position?.getName(locale) ?? positionId,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    if (position?.getAlias(locale) != null)
                      Text(
                        position!.getAlias(locale)!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6),
                              fontStyle: FontStyle.italic,
                            ),
                      ),
                  ],
                ),
              ),
              if (position != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(5, (i) {
                    return Icon(
                      Icons.star,
                      size: 12,
                      color: i < position.difficulty
                          ? AppColors.gold
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.2),
                    );
                  }),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================
// Helper class per i badge
// ============================================================

class _BadgeData {
  final String emoji;
  final String name;
  final String description;
  final bool isUnlocked;
  final String progress;

  const _BadgeData({
    required this.emoji,
    required this.name,
    required this.description,
    required this.isUnlocked,
    required this.progress,
  });
}