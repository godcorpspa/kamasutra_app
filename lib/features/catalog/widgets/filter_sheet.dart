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
    
    notifier.setCategories(
      _selectedCategories.isEmpty ? null : _selectedCategories,
    );
    notifier.setDifficultyRange(
      _difficultyRange.start.round() == 1 ? null : _difficultyRange.start.round(),
      _difficultyRange.end.round() == 5 ? null : _difficultyRange.end.round(),
    );
    notifier.setEnergy(_selectedEnergy);
    notifier.setFocus(_selectedFocus.isEmpty ? null : _selectedFocus);
    notifier.setDuration(_selectedDuration);
    
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
                    // Categories
                    _buildSection(
                      title: 'catalog.category'.tr(),
                      child: Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: PositionCategory.values.map((category) {
                          final isSelected = _selectedCategories.contains(category);
                          return FilterChip(
                            label: Text('categories.${category.name}'.tr()),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedCategories.add(category);
                                } else {
                                  _selectedCategories.remove(category);
                                }
                              });
                            },
                            selectedColor: AppColors.burgundy.withOpacity(0.3),
                            checkmarkColor: AppColors.burgundy,
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Difficulty
                    _buildSection(
                      title: 'catalog.difficulty'.tr(),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${_difficultyRange.start.round()}'),
                              Text('${_difficultyRange.end.round()}'),
                            ],
                          ),
                          RangeSlider(
                            values: _difficultyRange,
                            min: 1,
                            max: 5,
                            divisions: 4,
                            labels: RangeLabels(
                              '${_difficultyRange.start.round()}',
                              '${_difficultyRange.end.round()}',
                            ),
                            onChanged: (values) {
                              setState(() => _difficultyRange = values);
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Energy
                    _buildSection(
                      title: 'catalog.energy'.tr(),
                      child: Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: EnergyLevel.values.map((energy) {
                          final isSelected = _selectedEnergy == energy;
                          return ChoiceChip(
                            label: Text('energy.${energy.name}'.tr()),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedEnergy = selected ? energy : null;
                              });
                            },
                            selectedColor: _getEnergyColor(energy).withOpacity(0.3),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Duration
                    _buildSection(
                      title: 'catalog.duration'.tr(),
                      child: Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: PositionDuration.values.map((duration) {
                          final isSelected = _selectedDuration == duration;
                          return ChoiceChip(
                            label: Text('duration.${duration.name}'.tr()),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedDuration = selected ? duration : null;
                              });
                            },
                            selectedColor: AppColors.gold.withOpacity(0.3),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Focus
                    _buildSection(
                      title: 'catalog.focus'.tr(),
                      child: Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: PositionFocus.values.map((focus) {
                          final isSelected = _selectedFocus.contains(focus);
                          return FilterChip(
                            label: Text('focus.${focus.name}'.tr()),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedFocus.add(focus);
                                } else {
                                  _selectedFocus.remove(focus);
                                }
                              });
                            },
                            selectedColor: AppColors.navy.withOpacity(0.3),
                            checkmarkColor: AppColors.navy,
                          );
                        }).toList(),
                      ),
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

  Widget _buildSection({
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
        const SizedBox(height: AppSpacing.md),
        child,
      ],
    );
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
