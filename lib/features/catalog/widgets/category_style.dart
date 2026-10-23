import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../data/models/position.dart';

/// Single source of truth for how position attributes look: muted jewel
/// tints and line icons (no emoji). Used by the catalog card, the detail
/// screen, the filter sheet and the shuffle setup.
extension PositionCategoryStyle on PositionCategory {
  Color get tint {
    switch (this) {
      case PositionCategory.romantic:
        return AppColors.jewelRose;
      case PositionCategory.beginner:
        return AppColors.jewelSand;
      case PositionCategory.athletic:
        return AppColors.jewelEmber;
      case PositionCategory.supported:
        return AppColors.jewelDusk;
      case PositionCategory.lowImpact:
        return AppColors.jewelSage;
      case PositionCategory.adventurous:
        return AppColors.jewelGarnet;
      case PositionCategory.reconnect:
        return AppColors.jewelLilac;
      case PositionCategory.quickie:
        return AppColors.jewelAmber;
      case PositionCategory.foreplay:
        return AppColors.jewelTeal;
    }
  }

  IconData get icon {
    switch (this) {
      case PositionCategory.romantic:
        return Icons.favorite_border;
      case PositionCategory.beginner:
        return Icons.spa_outlined;
      case PositionCategory.athletic:
        return Icons.bolt_outlined;
      case PositionCategory.supported:
        return Icons.weekend_outlined;
      case PositionCategory.lowImpact:
        return Icons.self_improvement_outlined;
      case PositionCategory.adventurous:
        return Icons.explore_outlined;
      case PositionCategory.reconnect:
        return Icons.all_inclusive;
      case PositionCategory.quickie:
        return Icons.timer_outlined;
      case PositionCategory.foreplay:
        return Icons.local_florist_outlined;
    }
  }
}

extension EnergyLevelStyle on EnergyLevel {
  IconData get icon {
    switch (this) {
      case EnergyLevel.low:
        return Icons.air;
      case EnergyLevel.medium:
        return Icons.local_fire_department_outlined;
      case EnergyLevel.high:
        return Icons.bolt_outlined;
    }
  }
}

extension PositionDurationStyle on PositionDuration {
  IconData get icon {
    switch (this) {
      case PositionDuration.brief:
        return Icons.timer_outlined;
      case PositionDuration.medium:
        return Icons.schedule;
      case PositionDuration.long:
        return Icons.bedtime_outlined;
    }
  }
}

extension PositionFocusStyle on PositionFocus {
  IconData get icon {
    switch (this) {
      case PositionFocus.intimacy:
        return Icons.favorite_border;
      case PositionFocus.variety:
        return Icons.palette_outlined;
      case PositionFocus.connection:
        return Icons.all_inclusive;
      case PositionFocus.relax:
        return Icons.self_improvement_outlined;
      case PositionFocus.playfulness:
        return Icons.celebration_outlined;
      case PositionFocus.passion:
        return Icons.local_fire_department_outlined;
      case PositionFocus.trust:
        return Icons.handshake_outlined;
    }
  }
}

/// Difficulty shown as five short bars — quieter than coloured dots.
class DifficultyMeter extends StatelessWidget {
  final int difficulty;
  final double barWidth;

  const DifficultyMeter({super.key, required this.difficulty, this.barWidth = 9});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return Container(
          width: barWidth,
          height: 3,
          margin: const EdgeInsets.only(right: 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: i < difficulty ? AppColors.champagne : AppColors.inkHighest,
          ),
        );
      }),
    );
  }
}
