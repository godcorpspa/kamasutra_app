import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../data/providers/user_data_provider.dart';
import '../../../data/models/user_data.dart';

/// Progress screen showing badges, streaks, and statistics
/// NOW USING FIREBASE DATA
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
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the progress stream for real-time updates
    final progressAsync = ref.watch(userProgressStreamProvider);
    
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
                  progressAsync.when(
                    data: (progress) => _buildStreakCard(progress),
                    loading: () => _buildStreakCardLoading(),
                    error: (e, _) => _buildStreakCard(const UserProgress()),
                  ),
                ],
              ),
            ),
            
            // Tab bar
            TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: 'progress.badges'.tr()),
                Tab(text: 'progress.statistics'.tr()),
                Tab(text: 'Cronologia'),
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

  Widget _buildStreakCard(UserProgress progress) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.burgundy,
            AppColors.burgundy.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          // Flame icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                '🔥',
                style: TextStyle(fontSize: 28),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          
          // Current streak
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'progress.current_streak'.tr(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${progress.currentStreak}',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'progress.days'.tr(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
                if (progress.currentStreak > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${progress.graceDaysRemaining} giorni di grazia',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.gold,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(width: AppSpacing.sm),
          
          // Best streak
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'progress.longest_streak'.tr(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 11,
                ),
                maxLines: 1,
              ),
              const SizedBox(height: 2),
              Text(
                '${progress.longestStreak} ${'progress.days'.tr()}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCardLoading() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.burgundy,
            AppColors.burgundy.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }

  Widget _buildBadgesTab() {
    final progressAsync = ref.watch(userProgressStreamProvider);
    
    return progressAsync.when(
      data: (progress) => GridView.builder(
        padding: const EdgeInsets.all(AppSpacing.lg),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: 0.8,
        ),
        itemCount: _allBadges.length,
        itemBuilder: (context, index) {
          final badgeData = _allBadges[index];
          final isUnlocked = progress.unlockedBadges.contains(badgeData.id);
          final unlockedAt = progress.badgeUnlockDates[badgeData.id];
          
          return _BadgeCard(
            badge: badgeData,
            isUnlocked: isUnlocked,
            unlockedAt: unlockedAt,
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Errore: $e')),
    );
  }

  Widget _buildStatisticsTab() {
    final progressAsync = ref.watch(userProgressStreamProvider);
    final favoritesAsync = ref.watch(favoritesStreamProvider);
    
    return progressAsync.when(
      data: (progress) {
        final favoritesCount = favoritesAsync.when(
          data: (list) => list.length,
          loading: () => 0,
          error: (_, __) => 0,
        );
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              _buildStatRow(
                icon: Icons.explore,
                label: 'progress.positions_explored'.tr(),
                value: '${progress.gamesPlayed}', // TODO: track positions separately
                color: AppColors.burgundy,
              ),
              _buildStatRow(
                icon: Icons.casino,
                label: 'progress.games_played'.tr(),
                value: '${progress.gamesPlayed}',
                color: AppColors.gold,
              ),
              _buildStatRow(
                icon: Icons.timer,
                label: 'progress.total_time'.tr(),
                value: progress.formattedTotalTime,
                color: AppColors.navy,
              ),
              _buildStatRow(
                icon: Icons.favorite,
                label: 'progress.favorites_count'.tr(),
                value: '$favoritesCount',
                color: AppColors.blush,
              ),
              
              if (progress.gamesPlayed == 0 && progress.currentStreak == 0) ...[
                const SizedBox(height: AppSpacing.xl),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  child: Column(
                    children: [
                      Icon(
                        Icons.bar_chart,
                        size: 64,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Inizia a esplorare per vedere le tue statistiche!',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Errore: $e')),
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

  Widget _buildHistoryTab() {
    final historyAsync = ref.watch(historyStreamProvider);

    return historyAsync.when(
      data: (history) {
        if (history.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'La tua cronologia apparirà qui',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Esplora posizioni per iniziare a tracciare i tuoi progressi!',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
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
          itemCount: history.length,
          itemBuilder: (context, index) {
            final item = history[index];
            return _buildHistoryItem(item);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Errore: $e')),
    );
  }

  Widget _buildHistoryItem(HistoryEntry item) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Text(
            item.reaction,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.positionName,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  DateFormat('d MMMM, HH:mm', 'it').format(item.date),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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

// Badge definitions (same as before)
class BadgeData {
  final String id;
  final String emoji;
  final String nameKey;
  final String descriptionKey;

  const BadgeData({
    required this.id,
    required this.emoji,
    required this.nameKey,
    required this.descriptionKey,
  });
}

const List<BadgeData> _allBadges = [
  BadgeData(id: 'explorer', emoji: '🧭', nameKey: 'badges.explorer.name', descriptionKey: 'badges.explorer.description'),
  BadgeData(id: 'adventurer', emoji: '🏔️', nameKey: 'badges.adventurer.name', descriptionKey: 'badges.adventurer.description'),
  BadgeData(id: 'romantic', emoji: '💕', nameKey: 'badges.romantic.name', descriptionKey: 'badges.romantic.description'),
  BadgeData(id: 'collector', emoji: '📚', nameKey: 'badges.collector.name', descriptionKey: 'badges.collector.description'),
  BadgeData(id: 'dedicated', emoji: '🔥', nameKey: 'badges.dedicated.name', descriptionKey: 'badges.dedicated.description'),
  BadgeData(id: 'soul_explorers', emoji: '✨', nameKey: 'badges.soul_explorers.name', descriptionKey: 'badges.soul_explorers.description'),
  BadgeData(id: 'intimacy_cartographers', emoji: '🗺️', nameKey: 'badges.intimacy_cartographers.name', descriptionKey: 'badges.intimacy_cartographers.description'),
  BadgeData(id: 'poet', emoji: '📝', nameKey: 'badges.poet.name', descriptionKey: 'badges.poet.description'),
  BadgeData(id: 'supreme_flatterer', emoji: '👑', nameKey: 'badges.supreme_flatterer.name', descriptionKey: 'badges.supreme_flatterer.description'),
];

class _BadgeCard extends StatelessWidget {
  final BadgeData badge;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  const _BadgeCard({
    required this.badge,
    required this.isUnlocked,
    this.unlockedAt,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showBadgeDetail(context),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: isUnlocked
              ? Theme.of(context).colorScheme.surface
              : Theme.of(context).colorScheme.surface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: isUnlocked
              ? Border.all(color: AppColors.gold.withOpacity(0.5))
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isUnlocked ? badge.emoji : '🔒',
              style: TextStyle(
                fontSize: 36,
                color: isUnlocked ? null : Colors.grey,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              badge.nameKey.tr(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: isUnlocked 
                    ? null 
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
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

  void _showBadgeDetail(BuildContext context) {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(badge.emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                badge.nameKey.tr(),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(badge.descriptionKey.tr()),
            if (isUnlocked && unlockedAt != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                'Sbloccato il ${DateFormat('d MMMM yyyy', 'it').format(unlockedAt!)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.gold,
                ),
              ),
            ],
            if (!isUnlocked) ...[
              const SizedBox(height: AppSpacing.md),
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
            onPressed: () => Navigator.pop(context),
            child: Text('common.close'.tr()),
          ),
        ],
      ),
    );
  }
}
