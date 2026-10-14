import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../app/theme.dart';
import '../../../data/models/position.dart';
import '../../../data/providers/providers.dart';
import 'category_style.dart';
import 'filter_options.dart';

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

  // ─── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.inkHigh,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(top: BorderSide(color: AppColors.hairline)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, 0, AppSpacing.sm, AppSpacing.sm),
                child: Row(
                  children: [
                    Text(
                      'catalog.filter_by'.tr(),
                      style: Theme.of(context).textTheme.headlineSmall,
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
                    FilterSectionLabel('catalog.category'.tr()),
                    const SizedBox(height: AppSpacing.md),
                    OptionGrid(chips: [
                      for (final category in PositionCategory.values)
                        OptionChip(
                          icon: category.icon,
                          tint: category.tint,
                          label: 'categories.${category.name}'.tr(),
                          isSelected: _selectedCategories.contains(category),
                          onTap: () => setState(() {
                            _selectedCategories.contains(category)
                                ? _selectedCategories.remove(category)
                                : _selectedCategories.add(category);
                          }),
                        ),
                    ]),

                    const SizedBox(height: AppSpacing.xl),
                    FilterSectionLabel('catalog.difficulty'.tr()),
                    const SizedBox(height: AppSpacing.sm),
                    DifficultyRangeField(
                      values: _difficultyRange,
                      onChanged: (values) =>
                          setState(() => _difficultyRange = values),
                    ),

                    const SizedBox(height: AppSpacing.lg),
                    FilterSectionLabel('catalog.energy'.tr()),
                    const SizedBox(height: AppSpacing.md),
                    OptionRow(chips: [
                      for (final energy in EnergyLevel.values)
                        OptionChip(
                          icon: energy.icon,
                          label: 'energy.${energy.name}'.tr(),
                          isSelected: _selectedEnergy == energy,
                          onTap: () => setState(() {
                            _selectedEnergy =
                                _selectedEnergy == energy ? null : energy;
                          }),
                        ),
                    ]),

                    const SizedBox(height: AppSpacing.xl),
                    FilterSectionLabel('catalog.duration'.tr()),
                    const SizedBox(height: AppSpacing.md),
                    OptionRow(chips: [
                      for (final duration in PositionDuration.values)
                        OptionChip(
                          icon: duration.icon,
                          label: 'duration.${duration.name}'.tr(),
                          isSelected: _selectedDuration == duration,
                          onTap: () => setState(() {
                            _selectedDuration =
                                _selectedDuration == duration ? null : duration;
                          }),
                        ),
                    ]),

                    const SizedBox(height: AppSpacing.xl),
                    FilterSectionLabel('catalog.focus'.tr()),
                    const SizedBox(height: AppSpacing.md),
                    OptionGrid(chips: [
                      for (final focus in PositionFocus.values)
                        OptionChip(
                          icon: focus.icon,
                          label: 'focus.${focus.name}'.tr(),
                          isSelected: _selectedFocus.contains(focus),
                          onTap: () => setState(() {
                            _selectedFocus.contains(focus)
                                ? _selectedFocus.remove(focus)
                                : _selectedFocus.add(focus);
                          }),
                        ),
                    ]),

                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),

              // Apply button
              DecoratedBox(
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.hairline)),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
                    child: SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _applyFilters,
                        child: Text('common.done'.tr()),
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
}
