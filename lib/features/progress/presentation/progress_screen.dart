import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/services/preferences_service.dart';
import '../../../data/repositories/position_repository.dart';
import '../../../data/providers/providers.dart';
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
                const Tab(text: 'Provate'),
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
      motivationalMessage = 'Inizia oggi la vostra avventura!';
    } else if (streak == 1) {
      motivationalMessage = 'Ottimo inizio! Tornate domani 💪';
    } else if (streak < 7) {
      motivationalMessage = 'State andando alla grande!';
    } else if (streak < 30) {
      motivationalMessage = 'Che coppia affiatata! 🔥';
    } else {
      motivationalMessage = 'Siete inarrestabili! 🏆';
    }

    // Singolare / plurale
    String giorni(int n) => n == 1 ? '1 giorno' : '$n giorni';

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
                      'Serie attuale',
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
                      '🏅 Record',
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
    final favoritesCount = repo.positions.where((p) => p.isFavorite).length;

    // Categorie uniche provate
    final triedIds = prefs.triedPositionIds;
    final Set<String> uniqueCategories = {};
    for (final id in triedIds) {
      final position = repo.getById(id);
      if (position != null) {
        for (final cat in position.categories) {
          uniqueCategories.add(cat.name);
        }
      }
    }

    final badges = [
      _BadgeData(
        emoji: '🧭',
        name: 'Esploratore',
        description: 'Prova 5 posizioni diverse',
        isUnlocked: triedCount >= 5,
        progress: '${triedCount.clamp(0, 5)}/5',
      ),
      _BadgeData(
        emoji: '⛰️',
        name: 'Avventuriero',
        description: 'Prova 20 posizioni diverse',
        isUnlocked: triedCount >= 20,
        progress: '${triedCount.clamp(0, 20)}/20',
      ),
      _BadgeData(
        emoji: '💕',
        name: 'Romantico',
        description: 'Salva 5 posizioni nei preferiti',
        isUnlocked: favoritesCount >= 5,
        progress: '${favoritesCount.clamp(0, 5)}/5',
      ),
      _BadgeData(
        emoji: '📚',
        name: 'Collezionista',
        description: 'Prova 50 posizioni diverse',
        isUnlocked: triedCount >= 50,
        progress: '${triedCount.clamp(0, 50)}/50',
      ),
      _BadgeData(
        emoji: '🔥',
        name: 'Dedicato',
        description: 'Raggiungi una serie di 7 giorni',
        isUnlocked: streak >= 7,
        progress: '${streak.clamp(0, 7)}/7',
      ),
      _BadgeData(
        emoji: '💞',
        name: 'Esploratori dell\'Anima',
        description: 'Gioca 10 sessioni shuffle',
        isUnlocked: gamesPlayed >= 10,
        progress: '${gamesPlayed.clamp(0, 10)}/10',
      ),
      _BadgeData(
        emoji: '🌈',
        name: 'Versatile',
        description: 'Prova posizioni di 5 categorie diverse',
        isUnlocked: uniqueCategories.length >= 5,
        progress: '${uniqueCategories.length.clamp(0, 5)}/5',
      ),
      _BadgeData(
        emoji: '🏆',
        name: 'Campione',
        description: 'Raggiungi una serie di 30 giorni',
        isUnlocked: streak >= 30,
        progress: '${streak.clamp(0, 30)}/30',
      ),
      _BadgeData(
        emoji: '💎',
        name: 'Maestro',
        description: 'Prova 100 posizioni diverse',
        isUnlocked: triedCount >= 100,
        progress: '${triedCount.clamp(0, 100)}/100',
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
                  'Progresso: ${badge.progress}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                if (!badge.isUnlocked) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Continua a esplorare per sbloccare!',
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
            label: 'Posizioni esplorate',
            value: '$triedCount',
            color: AppColors.burgundy,
          ),
          _buildStatRow(
            icon: Icons.casino,
            label: 'Partite giocate',
            value: '$gamesPlayed',
            color: AppColors.gold,
          ),
          _buildStatRow(
            icon: Icons.timer,
            label: 'Tempo insieme',
            value: timeTogether,
            color: AppColors.navy,
          ),
          _buildStatRow(
            icon: Icons.favorite,
            label: 'Preferiti salvati',
            value: '$favoritesCount',
            color: AppColors.blush,
          ),
          
          const SizedBox(height: AppSpacing.xl),
          
          // Categorie esplorate
          Text(
            'Categorie esplorate',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.md),

          if (categoryCount.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                'Inizia a esplorare per vedere le tue statistiche!',
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
                'Nessuna posizione provata ancora',
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
                'Esplora il catalogo o gioca allo shuffle per aggiungere posizioni!',
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