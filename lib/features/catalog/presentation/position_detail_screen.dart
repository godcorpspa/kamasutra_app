import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../data/services/preferences_service.dart';

import '../../../app/theme.dart';
import '../../../data/models/position.dart';
import '../../../data/providers/providers.dart';

class PositionDetailScreen extends ConsumerStatefulWidget {
  final String positionId;

  const PositionDetailScreen({
    super.key,
    required this.positionId,
  });

  @override
  ConsumerState<PositionDetailScreen> createState() => _PositionDetailScreenState();
}

class _PositionDetailScreenState extends ConsumerState<PositionDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Record view
    Future.microtask(() {
      ref.read(positionRepositoryProvider).recordView(widget.positionId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.languageCode;
    final repo = ref.watch(positionRepositoryProvider);
    final position = repo.getById(widget.positionId);

    if (position == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Text('errors.no_positions'.tr()),
        ),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App bar with illustration
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            stretch: true,
            backgroundColor: _getCategoryColor(position.categories.first),
            leading: IconButton(
              onPressed: () => context.pop(),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
            ),
            actions: [
              IconButton(
                onPressed: () async {
                  HapticFeedback.lightImpact();
                  final newStatus = await repo.toggleFavorite(position.id);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          newStatus
                              ? 'catalog.added_to_favorites'.tr()
                              : 'Rimosso dai preferiti',
                        ),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    ref.invalidate(positionsProvider(locale));
                    setState(() {});
                  }
                },
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    position.isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: position.isFavorite ? AppColors.burgundy : Colors.white,
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Gradient background
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          _getCategoryColor(position.categories.first),
                          _getCategoryColor(position.categories.first).withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                  // SVG Illustration
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 30,
                      ),
                      child: SvgPicture.asset(
                        'assets/images/positions/${position.illustrationRef}',
                        fit: BoxFit.contain,
                        placeholderBuilder: (_) => Center(
                          child: Icon(
                            _getCategoryIcon(position.categories.first),
                            size: 120,
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Bottom gradient for readability
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 100,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Theme.of(context).scaffoldBackgroundColor,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    position.name,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ).animate().fadeIn().slideX(begin: -0.1),

                  // Alias
                  if (position.alias != null && position.alias!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      position.alias!,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                            fontStyle: FontStyle.italic,
                          ),
                    ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1),
                  ],

                  const SizedBox(height: AppSpacing.lg),

                  // Quick info chips
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      _InfoChip(
                        icon: Icons.star,
                        label: '${'position.difficulty'.tr()}: ${position.difficulty}/5',
                        color: _getDifficultyColor(position.difficulty),
                      ),
                      _InfoChip(
                        icon: _getEnergyIcon(position.energy),
                        label: 'energy.${position.energy.name}'.tr(),
                        color: _getEnergyColor(position.energy),
                      ),
                      _InfoChip(
                        icon: Icons.timer,
                        label: 'duration.${position.duration.name}'.tr(),
                        color: AppColors.gold,
                      ),
                    ],
                  ).animate().fadeIn(delay: 200.ms),

                  const SizedBox(height: AppSpacing.lg),

                  // Categories
                  _buildSection(
                    context,
                    title: 'catalog.category'.tr(),
                    child: Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: position.categories.map((cat) {
                        return Chip(
                          label: Text('categories.${cat.name}'.tr()),
                          backgroundColor:
                              _getCategoryColor(cat).withOpacity(0.2),
                          side: BorderSide.none,
                        );
                      }).toList(),
                    ),
                  ),

                  // Focus areas
                  if (position.focus.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    _buildSection(
                      context,
                      title: 'catalog.focus'.tr(),
                      child: Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: position.focus.map((f) {
                          return Chip(
                            label: Text('focus.${f.name}'.tr()),
                            backgroundColor: AppColors.navy.withOpacity(0.2),
                            side: BorderSide.none,
                          );
                        }).toList(),
                      ),
                    ),
                  ],

                  // Setup instructions
                  if (position.setup != null && position.setup!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xl),
                    _buildSection(
                      context,
                      title: 'position.setup'.tr(),
                      child: Text(
                        position.setup!,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              height: 1.6,
                            ),
                      ),
                    ),
                  ],

                  // Prerequisites
                  if (position.prerequisites.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xl),
                    _buildSection(
                      context,
                      title: 'position.prerequisites'.tr(),
                      child: Column(
                        children: position.prerequisites.map((prereq) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.check_circle_outline,
                                  size: 20,
                                  color: AppColors.gold,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(prereq),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],

                  // Cautions
                  if (position.cautions != null && position.cautions!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xl),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.spicy.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: AppColors.spicy.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: AppColors.spicy,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              position.cautions!,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Easy variant
                  if (position.easyVariant != null &&
                      position.easyVariant!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xl),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.soft.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: AppColors.soft.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.spa,
                                color: AppColors.soft,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                'position.easy_version'.tr(),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      color: AppColors.soft,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            position.easyVariant!,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Check-in prompt
                  if (position.checkin != null && position.checkin!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xl),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.burgundy.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                color: AppColors.burgundy,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                'position.check_in'.tr(),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      color: AppColors.burgundy,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            '"${position.checkin}"',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontStyle: FontStyle.italic,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Tags
                  if (position.tags.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xl),
                    _buildSection(
                      context,
                      title: 'position.tags'.tr(),
                      child: Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: position.tags.map((tag) {
                          return Chip(
                            label: Text(
                              '#$tag',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .surface
                                .withOpacity(0.5),
                            side: BorderSide.none,
                            visualDensity: VisualDensity.compact,
                          );
                        }).toList(),
                      ),
                    ),
                  ],

                  // Similar positions
                  const SizedBox(height: AppSpacing.xxl),
                  _buildSimilarPositions(context, locale, position),

                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ],
      ),

      // Try this button
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ElevatedButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              // Segna come provata
              PreferencesService.instance.addTriedPosition(widget.positionId);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    PreferencesService.instance.isTriedPosition(widget.positionId)
                        ? '✅ Provata di nuovo!'
                        : '✅ Aggiunta alle posizioni provate!',
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              setState(() {});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.burgundy,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
            ),
            child: Text(
              PreferencesService.instance.isTriedPosition(widget.positionId)
                  ? 'Prova di nuovo 🔄'
                  : 'Prova questa 🔥',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        child,
      ],
    );
  }

  Widget _buildSimilarPositions(
    BuildContext context,
    String locale,
    Position position,
  ) {
    final repo = ref.watch(positionRepositoryProvider);
    final similar = repo.getSimilar(position.id, limit: 4);

    if (similar.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'position.similar_positions'.tr(),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: similar.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, index) {
              final p = similar[index];
              return GestureDetector(
                onTap: () => context.push('/catalog/${p.id}'),
                child: Container(
                  width: 140,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    color: _getCategoryColor(p.categories.first).withOpacity(0.1),
                    border: Border.all(
                      color: _getCategoryColor(p.categories.first).withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: SvgPicture.asset(
                            'assets/images/positions/${p.illustrationRef}.svg',
                            fit: BoxFit.contain,
                            placeholderBuilder: (_) => Center(
                              child: Icon(
                                _getCategoryIcon(p.categories.first),
                                size: 40,
                                color: _getCategoryColor(p.categories.first)
                                    .withOpacity(0.5),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        p.name,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Color _getCategoryColor(PositionCategory category) {
    switch (category) {
      case PositionCategory.romantic:
        return AppColors.burgundy;
      case PositionCategory.beginner:
        return AppColors.blush;
      case PositionCategory.athletic:
        return AppColors.spicy;
      case PositionCategory.supported:
        return AppColors.navy;
      case PositionCategory.lowImpact:
        return AppColors.soft;
      case PositionCategory.adventurous:
        return AppColors.extraSpicy;
      case PositionCategory.reconnect:
        return AppColors.gold;
      case PositionCategory.quickie:
        return Colors.purple;
    }
  }

  IconData _getCategoryIcon(PositionCategory category) {
    switch (category) {
      case PositionCategory.romantic:
        return Icons.favorite;
      case PositionCategory.beginner:
        return Icons.sentiment_satisfied;
      case PositionCategory.athletic:
        return Icons.fitness_center;
      case PositionCategory.supported:
        return Icons.support;
      case PositionCategory.lowImpact:
        return Icons.spa;
      case PositionCategory.adventurous:
        return Icons.explore;
      case PositionCategory.reconnect:
        return Icons.sync;
      case PositionCategory.quickie:
        return Icons.bolt;
    }
  }

  IconData _getEnergyIcon(EnergyLevel energy) {
    switch (energy) {
      case EnergyLevel.low:
        return Icons.battery_3_bar;
      case EnergyLevel.medium:
        return Icons.battery_5_bar;
      case EnergyLevel.high:
        return Icons.battery_full;
    }
  }

  Color _getEnergyColor(EnergyLevel energy) {
    switch (energy) {
      case EnergyLevel.low:
        return AppColors.soft;
      case EnergyLevel.medium:
        return AppColors.spicy;
      case EnergyLevel.high:
        return AppColors.extraSpicy;
    }
  }

  Color _getDifficultyColor(int difficulty) {
    if (difficulty <= 2) return AppColors.soft;
    if (difficulty <= 3) return AppColors.spicy;
    return AppColors.extraSpicy;
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppRadius.round),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
