import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../app/theme.dart';
import '../../../data/models/position.dart';
import '../../../data/providers/providers.dart';

/// Bottom sheet for filtering positions
class FilterSheet extends ConsumerStatefulWidget {
  const FilterSheet({super.key});

  @override
  ConsumerState<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<FilterSheet> {
  late List<PositionCategory> _selectedCategories;
  late RangeValues _difficultyRange;
  EnergyLevel? _selectedEnergy;
  late List<PositionFocus> _selectedFocus;
  PositionDuration? _selectedDuration;

  @override
  void initState() {
    super.initState();
    final filter = ref.read(positionFilterProvider);
    _selectedCategories = filter.categories?.toList() ?? [];
    _difficultyRange = RangeValues(
      (filter.minDifficulty ?? 1).toDouble(),
      (filter.maxDifficulty ?? 5).toDouble(),
    );
    _selectedEnergy = filter.energyLevels?.isNotEmpty == true ? filter.energyLevels!.first : null;
    _selectedFocus = filter.focus?.toList() ?? [];
    _selectedDuration = filter.durations?.isNotEmpty == true ? filter.durations!.first : null;
  }

  void _applyFilters() {
    final notifier = ref.read(positionFilterProvider.notifier);
    notifier.setAll(
      categories: _selectedCategories.isEmpty ? null : _selectedCategories,
      minDifficulty: _difficultyRange.start.round() == 1 ? null : _difficultyRange.start.round(),
      maxDifficulty: _difficultyRange.end.round() == 5 ? null : _difficultyRange.end.round(),
      energyLevels: _selectedEnergy != null ? [_selectedEnergy!] : null,
      focus: _selectedFocus.isEmpty ? null : _selectedFocus,
      durations: _selectedDuration != null ? [_selectedDuration!] : null,
    );
    Navigator.of(context).pop();
  }

  void _clearFilters() {
    setState(() {
      _selectedCategories = [];
      _difficultyRange = const RangeValues(1, 5);
      _selectedEnergy = null;
      _selectedFocus = [];
      _selectedDuration = null;
    });
  }

  // ─── emoji helpers ─────────────────────────────────────────────────────────

  String _categoryEmoji(PositionCategory c) {
    switch (c) {
      case PositionCategory.romantic:    return '🌹';
      case PositionCategory.beginner:    return '🌿';
      case PositionCategory.athletic:    return '🏋️';
      case PositionCategory.supported:   return '🤝';
      case PositionCategory.lowImpact:   return '🦋';
      case PositionCategory.adventurous: return '🗺️';
      case PositionCategory.reconnect:   return '🔗';
      case PositionCategory.quickie:     return '⚡';
    }
  }

  String _energyEmoji(EnergyLevel e) {
    switch (e) {
      case EnergyLevel.low:    return '🍃';
      case EnergyLevel.medium: return '🔥';
      case EnergyLevel.high:   return '💥';
    }
  }

  String _durationEmoji(PositionDuration d) {
    switch (d) {
      case PositionDuration.brief:  return '⏱️';
      case PositionDuration.medium: return '🕐';
      case PositionDuration.long:   return '🌙';
    }
  }

  String _focusEmoji(PositionFocus f) {
    switch (f) {
      case PositionFocus.intimacy:     return '💕';
      case PositionFocus.variety:      return '🎨';
      case PositionFocus.connection:   return '🔮';
      case PositionFocus.relax:        return '🧘';
      case PositionFocus.playfulness:  return '🎉';
      case PositionFocus.passion:      return '❤️‍🔥';
      case PositionFocus.trust:        return '🤲';
    }
  }

  // ─── chip builders ─────────────────────────────────────────────────────────

  Widget _filterChip({
    required String label,
    required bool isSelected,
    required ValueChanged<bool> onSelected,
    required Color accentColor,
  }) {
    final theme = Theme.of(context);
    return FilterChip(
      label: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected
                ? accentColor
                : theme.colorScheme.onSurface.withOpacity(0.85),
          ),
        ),
      ),
      selected: isSelected,
      showCheckmark: false,
      onSelected: onSelected,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      backgroundColor: theme.colorScheme.surface,
      selectedColor: accentColor.withOpacity(0.12),
      side: isSelected
          ? BorderSide(color: accentColor, width: 1.5)
          : BorderSide(color: theme.colorScheme.outline.withOpacity(0.25)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    );
  }

  Widget _choiceChip({
    required String label,
    required bool isSelected,
    required ValueChanged<bool> onSelected,
    required Color accentColor,
  }) {
    final theme = Theme.of(context);
    return ChoiceChip(
      label: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected
                ? accentColor
                : theme.colorScheme.onSurface.withOpacity(0.85),
          ),
        ),
      ),
      selected: isSelected,
      showCheckmark: false,
      onSelected: onSelected,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      backgroundColor: theme.colorScheme.surface,
      selectedColor: accentColor.withOpacity(0.12),
      side: isSelected
          ? BorderSide(color: accentColor, width: 1.5)
          : BorderSide(color: theme.colorScheme.outline.withOpacity(0.25)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    );
  }

  // ─── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.xl),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Row(
                  children: [
                    Text(
                      'catalog.filter_by'.tr(),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _clearFilters,
                      child: Text('common.clear_filters'.tr()),
                    ),
                  ],
                ),
              ),

              const Divider(),

              // Filters
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    // ── Categorie ──────────────────────────────────────────
                    _buildSectionHeader('catalog.category'.tr(), Icons.grid_view_rounded),
                    const SizedBox(height: AppSpacing.md),
                    LayoutBuilder(
                      builder: (_, constraints) {
                        final w = (constraints.maxWidth - AppSpacing.sm) / 2;
                        return Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: PositionCategory.values.map((category) {
                            final isSelected = _selectedCategories.contains(category);
                            return SizedBox(
                              width: w,
                              child: _filterChip(
                                label: '${_categoryEmoji(category)}  ${'categories.${category.name}'.tr()}',
                                isSelected: isSelected,
                                accentColor: AppColors.burgundy,
                                onSelected: (v) => setState(() {
                                  v ? _selectedCategories.add(category) : _selectedCategories.remove(category);
                                }),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // ── Difficoltà ─────────────────────────────────────────
                    _buildSectionHeader('catalog.difficulty'.tr(), Icons.star_outline_rounded),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '⭐ ${_difficultyRange.start.round()}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.gold,
                          ),
                        ),
                        Text(
                          '${_difficultyRange.end.round()} ⭐',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.gold,
                          ),
                        ),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: AppColors.gold,
                        thumbColor: AppColors.gold,
                        inactiveTrackColor: AppColors.gold.withOpacity(0.2),
                        overlayColor: AppColors.gold.withOpacity(0.1),
                      ),
                      child: RangeSlider(
                        values: _difficultyRange,
                        min: 1,
                        max: 5,
                        divisions: 4,
                        labels: RangeLabels(
                          '${_difficultyRange.start.round()}',
                          '${_difficultyRange.end.round()}',
                        ),
                        onChanged: (values) => setState(() => _difficultyRange = values),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // ── Energia ────────────────────────────────────────────
                    _buildSectionHeader('catalog.energy'.tr(), Icons.bolt_rounded),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: EnergyLevel.values.asMap().entries.map((entry) {
                        final i = entry.key;
                        final energy = entry.value;
                        final isSelected = _selectedEnergy == energy;
                        final color = _getEnergyColor(energy);
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(right: i < EnergyLevel.values.length - 1 ? AppSpacing.sm : 0),
                            child: _choiceChip(
                              label: '${_energyEmoji(energy)}\n${'energy.${energy.name}'.tr()}',
                              isSelected: isSelected,
                              accentColor: color,
                              onSelected: (v) => setState(() {
                                _selectedEnergy = v ? energy : null;
                              }),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // ── Durata ─────────────────────────────────────────────
                    _buildSectionHeader('catalog.duration'.tr(), Icons.timer_outlined),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: PositionDuration.values.asMap().entries.map((entry) {
                        final i = entry.key;
                        final duration = entry.value;
                        final isSelected = _selectedDuration == duration;
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(right: i < PositionDuration.values.length - 1 ? AppSpacing.sm : 0),
                            child: _choiceChip(
                              label: '${_durationEmoji(duration)}\n${'duration.${duration.name}'.tr()}',
                              isSelected: isSelected,
                              accentColor: AppColors.gold,
                              onSelected: (v) => setState(() {
                                _selectedDuration = v ? duration : null;
                              }),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // ── Focus ──────────────────────────────────────────────
                    _buildSectionHeader('catalog.focus'.tr(), Icons.psychology_outlined),
                    const SizedBox(height: AppSpacing.md),
                    LayoutBuilder(
                      builder: (_, constraints) {
                        final w = (constraints.maxWidth - AppSpacing.sm) / 2;
                        return Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: PositionFocus.values.map((focus) {
                            final isSelected = _selectedFocus.contains(focus);
                            return SizedBox(
                              width: w,
                              child: _filterChip(
                                label: '${_focusEmoji(focus)}  ${'focus.${focus.name}'.tr()}',
                                isSelected: isSelected,
                                accentColor: AppColors.navy,
                                onSelected: (v) => setState(() {
                                  v ? _selectedFocus.add(focus) : _selectedFocus.remove(focus);
                                }),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),

                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),

              // Apply button
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _applyFilters,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.burgundy,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                      ),
                      child: Text(
                        'common.done'.tr(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: AppSpacing.sm),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }

  Color _getEnergyColor(EnergyLevel energy) {
    switch (energy) {
      case EnergyLevel.low:    return AppColors.soft;
      case EnergyLevel.medium: return AppColors.spicy;
      case EnergyLevel.high:   return AppColors.extraSpicy;
    }
  }
}
