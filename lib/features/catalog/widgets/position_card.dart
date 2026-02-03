import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../app/theme.dart';
import '../../../data/models/position.dart';

/// A card displaying a position preview
class PositionCard extends StatelessWidget {
  final Position position;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteTap;
  final bool showFavorite;

  const PositionCard({
    super.key,
    required this.position,
    this.onTap,
    this.onFavoriteTap,
    this.showFavorite = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _getCategoryColor(position.categories.first).withOpacity(0.3),
              _getCategoryColor(position.categories.first).withOpacity(0.1),
            ],
          ),
          border: Border.all(
            color: _getCategoryColor(position.categories.first).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Stack(
          children: [
            // Content
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Illustration placeholder
                  Expanded(
                    child: Center(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          color: Theme.of(context)
                              .colorScheme
                              .surface
                              .withOpacity(0.5),
                        ),
                        child: Center(
                          child: Icon(
                            _getCategoryIcon(position.categories.first),
                            size: 48,
                            color: _getCategoryColor(position.categories.first)
                                .withOpacity(0.7),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // Name
                  Text(
                    position.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Alias if available
                  if (position.alias != null && position.alias!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      position.alias!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                            fontStyle: FontStyle.italic,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  const SizedBox(height: AppSpacing.sm),

                  // Info row
                  Row(
                    children: [
                      // Difficulty
                      _DifficultyIndicator(difficulty: position.difficulty),
                      const Spacer(),
                      // Energy
                      Icon(
                        _getEnergyIcon(position.energy),
                        size: 16,
                        color: _getEnergyColor(position.energy),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Favorite button
            if (showFavorite)
              Positioned(
                top: AppSpacing.xs,
                right: AppSpacing.xs,
                child: IconButton(
                  onPressed: onFavoriteTap,
                  icon: Icon(
                    position.isFavorite
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: position.isFavorite
                        ? AppColors.burgundy
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.5),
                  ),
                  iconSize: 20,
                  visualDensity: VisualDensity.compact,
                ),
              ),

            // Category badge
            Positioned(
              top: AppSpacing.sm,
              left: AppSpacing.sm,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: _getCategoryColor(position.categories.first)
                      .withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  'categories.${position.categories.first.name}'.tr(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: _getCategoryColor(position.categories.first),
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
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
}

class _DifficultyIndicator extends StatelessWidget {
  final int difficulty;

  const _DifficultyIndicator({required this.difficulty});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final isFilled = index < difficulty;
        return Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(right: 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled
                ? _getDifficultyColor(difficulty)
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
          ),
        );
      }),
    );
  }

  Color _getDifficultyColor(int difficulty) {
    if (difficulty <= 2) return AppColors.soft;
    if (difficulty <= 3) return AppColors.spicy;
    return AppColors.extraSpicy;
  }
}
