import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../data/models/game.dart';

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

  Widget _buildStreakCard() {
    // Mock streak data - in real app, would come from provider
    const currentStreak = 5;
    const longestStreak = 12;
    const graceDaysRemaining = 2;

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
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                '🔥',
                style: TextStyle(fontSize: 32),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          
          // Streak info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'progress.current_streak'.tr(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$currentStreak',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        'progress.days'.tr(),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Best streak
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'progress.longest_streak'.tr(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
              Text(
                '$longestStreak ${'progress.days'.tr()}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$graceDaysRemaining ${'progress.grace_days'.tr()}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.gold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesTab() {
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 0.8,
      ),
      itemCount: _badges.length,
      itemBuilder: (context, index) {
        final badge = _badges[index];
        return _BadgeCard(badge: badge);
      },
    );
  }

  Widget _buildStatisticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          _buildStatRow(
            icon: Icons.explore,
            label: 'progress.positions_explored'.tr(),
            value: '42',
            color: AppColors.burgundy,
          ),
          _buildStatRow(
            icon: Icons.casino,
            label: 'progress.games_played'.tr(),
            value: '18',
            color: AppColors.gold,
          ),
          _buildStatRow(
            icon: Icons.timer,
            label: 'progress.total_time'.tr(),
            value: '12h 30m',
            color: AppColors.navy,
          ),
          _buildStatRow(
            icon: Icons.favorite,
            label: 'progress.favorites_count'.tr(),
            value: '15',
            color: AppColors.blush,
          ),
          
          const SizedBox(height: AppSpacing.xl),
          
          // Category breakdown
          Text(
            'Categorie esplorate',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          
          _buildCategoryProgress('Romantiche', 0.8, AppColors.burgundy),
          _buildCategoryProgress('Per iniziare', 0.6, AppColors.soft),
          _buildCategoryProgress('Atletiche', 0.3, AppColors.spicy),
          _buildCategoryProgress('Avventurose', 0.2, AppColors.extraSpicy),
          _buildCategoryProgress('Low Impact', 0.5, AppColors.navy),
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
          LinearProgressIndicator(
            value: progress,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    // Mock history data
    final history = [
      _HistoryItem(date: DateTime.now(), positionName: 'Posizione romantica', reaction: '❤️'),
      _HistoryItem(date: DateTime.now().subtract(const Duration(days: 1)), positionName: 'Posizione avventurosa', reaction: '👍'),
      _HistoryItem(date: DateTime.now().subtract(const Duration(days: 2)), positionName: 'Posizione rilassante', reaction: '😐'),
      _HistoryItem(date: DateTime.now().subtract(const Duration(days: 3)), positionName: 'Posizione atletica', reaction: '😅'),
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final item = history[index];
        return _buildHistoryItem(item);
      },
    );
  }

  Widget _buildHistoryItem(_HistoryItem item) {
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

class _HistoryItem {
  final DateTime date;
  final String positionName;
  final String reaction;

  _HistoryItem({
    required this.date,
    required this.positionName,
    required this.reaction,
  });
}

// Badge data
final List<_BadgeData> _badges = [
  _BadgeData(
    id: 'explorer',
    emoji: '🧭',
    nameKey: 'badges.explorer.name',
    descriptionKey: 'badges.explorer.description',
    isUnlocked: true,
    unlockedAt: DateTime.now().subtract(const Duration(days: 10)),
  ),
  _BadgeData(
    id: 'adventurer',
    emoji: '🏔️',
    nameKey: 'badges.adventurer.name',
    descriptionKey: 'badges.adventurer.description',
    isUnlocked: true,
    unlockedAt: DateTime.now().subtract(const Duration(days: 5)),
  ),
  _BadgeData(
    id: 'romantic',
    emoji: '💕',
    nameKey: 'badges.romantic.name',
    descriptionKey: 'badges.romantic.description',
    isUnlocked: false,
  ),
  _BadgeData(
    id: 'collector',
    emoji: '📚',
    nameKey: 'badges.collector.name',
    descriptionKey: 'badges.collector.description',
    isUnlocked: false,
  ),
  _BadgeData(
    id: 'dedicated',
    emoji: '🔥',
    nameKey: 'badges.dedicated.name',
    descriptionKey: 'badges.dedicated.description',
    isUnlocked: true,
    unlockedAt: DateTime.now().subtract(const Duration(days: 2)),
  ),
  _BadgeData(
    id: 'soul_explorers',
    emoji: '✨',
    nameKey: 'badges.soul_explorers.name',
    descriptionKey: 'badges.soul_explorers.description',
    isUnlocked: false,
  ),
  _BadgeData(
    id: 'intimacy_cartographers',
    emoji: '🗺️',
    nameKey: 'badges.intimacy_cartographers.name',
    descriptionKey: 'badges.intimacy_cartographers.description',
    isUnlocked: false,
  ),
  _BadgeData(
    id: 'poet',
    emoji: '📝',
    nameKey: 'badges.poet.name',
    descriptionKey: 'badges.poet.description',
    isUnlocked: false,
  ),
  _BadgeData(
    id: 'supreme_flatterer',
    emoji: '👑',
    nameKey: 'badges.supreme_flatterer.name',
    descriptionKey: 'badges.supreme_flatterer.description',
    isUnlocked: false,
  ),
];

class _BadgeData {
  final String id;
  final String emoji;
  final String nameKey;
  final String descriptionKey;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  _BadgeData({
    required this.id,
    required this.emoji,
    required this.nameKey,
    required this.descriptionKey,
    required this.isUnlocked,
    this.unlockedAt,
  });
}

class _BadgeCard extends StatelessWidget {
  final _BadgeData badge;

  const _BadgeCard({required this.badge});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showBadgeDetail(context),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: badge.isUnlocked
              ? Theme.of(context).colorScheme.surface
              : Theme.of(context).colorScheme.surface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: badge.isUnlocked
              ? Border.all(color: AppColors.gold.withOpacity(0.5))
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              badge.isUnlocked ? badge.emoji : '🔒',
              style: TextStyle(
                fontSize: 36,
                color: badge.isUnlocked ? null : Colors.grey,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              badge.nameKey.tr(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: badge.isUnlocked 
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
            if (badge.isUnlocked && badge.unlockedAt != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                'Sbloccato il ${DateFormat('d MMMM yyyy', 'it').format(badge.unlockedAt!)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.gold,
                ),
              ),
            ],
            if (!badge.isUnlocked) ...[
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
