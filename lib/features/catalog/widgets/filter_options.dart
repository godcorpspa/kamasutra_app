import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme.dart';

/// Hairline pill with a line icon used by every position filter (catalog
/// filter sheet, shuffle setup). Selected = champagne outline and tint.
class OptionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color tint;

  const OptionChip({
    super.key,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.tint = AppColors.mist,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? AppColors.champagne.withOpacity(0.10)
          : Colors.transparent,
      shape: StadiumBorder(
        side: BorderSide(
          color: isSelected ? AppColors.champagne : AppColors.outline,
        ),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            children: [
              Icon(icon,
                  size: 16, color: isSelected ? AppColors.champagne : tint),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? AppColors.champagne : AppColors.ivory,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Two-column grid of [OptionChip]s.
class OptionGrid extends StatelessWidget {
  final List<Widget> chips;

  const OptionGrid({super.key, required this.chips});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final w = (constraints.maxWidth - AppSpacing.sm) / 2;
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [for (final c in chips) SizedBox(width: w, child: c)],
        );
      },
    );
  }
}

/// One row of equally wide [OptionChip]s.
class OptionRow extends StatelessWidget {
  final List<Widget> chips;

  const OptionRow({super.key, required this.chips});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < chips.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.sm),
          Expanded(child: chips[i]),
        ],
      ],
    );
  }
}

/// Uppercase eyebrow label above a filter group.
class FilterSectionLabel extends StatelessWidget {
  final String title;

  const FilterSectionLabel(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(title.toUpperCase(), style: AppTypography.eyebrow);
  }
}

/// "1 ——●——●—— 5" difficulty range in champagne with lining numerals.
class DifficultyRangeField extends StatelessWidget {
  final RangeValues values;
  final ValueChanged<RangeValues> onChanged;

  const DifficultyRangeField({
    super.key,
    required this.values,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const numberStyle = TextStyle(
      fontFamily: AppTypography.displayFont,
      fontFeatures: AppTypography.lining,
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: AppColors.champagne,
    );
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${values.start.round()}', style: numberStyle),
            Text('${values.end.round()}', style: numberStyle),
          ],
        ),
        RangeSlider(
          values: values,
          min: 1,
          max: 5,
          divisions: 4,
          labels: RangeLabels(
            '${values.start.round()}',
            '${values.end.round()}',
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
