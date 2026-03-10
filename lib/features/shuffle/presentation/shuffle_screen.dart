import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../app/router.dart';
import '../../../data/models/position.dart';

/// Shuffle mode configuration screen
class ShuffleScreen extends ConsumerStatefulWidget {
  const ShuffleScreen({super.key});

  @override
  ConsumerState<ShuffleScreen> createState() => _ShuffleScreenState();
}

class _ShuffleScreenState extends ConsumerState<ShuffleScreen> {
  // Filter state
  Set<PositionCategory> _selectedCategories = {};
  RangeValues _difficultyRange = const RangeValues(1, 5);
  EnergyLevel? _selectedEnergy;
  Set<PositionFocus> _selectedFocus = {};
  PositionDuration? _selectedDuration;
  bool _favoritesOnly = false;
  int _cardCount = 5;

  @override
  void initState() {
    super.initState();
    // Load default card count from preferences
    _loadPreferences();
  }

  void _loadPreferences() {
    // Could load from PreferencesService
    setState(() {
      _cardCount = 5;
    });
  }

  void _startSession() {
    HapticFeedback.mediumImpact();
    
    final filter = PositionFilter(
      categories: _selectedCategories.isEmpty ? null : _selectedCategories.toList(),
      minDifficulty: _difficultyRange.start.round(),
      maxDifficulty: _difficultyRange.end.round(),
      energyLevels: _selectedEnergy != null ? [_selectedEnergy!] : null,
      focus: _selectedFocus.isEmpty ? null : _selectedFocus.toList(),
      durations: _selectedDuration != null ? [_selectedDuration!] : null,
      favoritesOnly: _favoritesOnly,
    );

    // Navigate to session with filter
    context.push(
      AppRoutes.shuffleSession,
      extra: {
        'filter': filter,
        'cardCount': _cardCount,
      },
    );
  }

  void _clearFilters() {
    setState(() {
      _selectedCategories = {};
      _difficultyRange = const RangeValues(1, 5);
      _selectedEnergy = null;
      _selectedFocus = {};
      _selectedDuration = null;
      _favoritesOnly = false;
    });
  }

  bool get _hasActiveFilters =>
      _selectedCategories.isNotEmpty ||
      _difficultyRange.start > 1 ||
      _difficultyRange.end < 5 ||
      _selectedEnergy != null ||
      _selectedFocus.isNotEmpty ||
      _selectedDuration != null ||
      _favoritesOnly;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'shuffle.title'.tr(),
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'shuffle.subtitle'.tr(),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Card count selector
            SliverToBoxAdapter(
              child: _buildCardCountSelector(),
            ),

            // Filter section header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'catalog.filter_by'.tr(),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (_hasActiveFilters)
                      TextButton(
                        onPressed: _clearFilters,
                        child: Text('common.clear_filters'.tr()),
                      ),
                  ],
                ),
              ),
            ),

            // Favorites toggle
            SliverToBoxAdapter(
              child: _buildFavoritesToggle(),
            ),

            // Categories
            SliverToBoxAdapter(
              child: _buildCategorySection(),
            ),

            // Difficulty slider
            SliverToBoxAdapter(
              child: _buildDifficultySlider(),
            ),

            // Energy level
            SliverToBoxAdapter(
              child: _buildEnergySection(),
            ),

            // Duration
            SliverToBoxAdapter(
              child: _buildDurationSection(),
            ),

            // Focus areas
            SliverToBoxAdapter(
              child: _buildFocusSection(),
            ),

            // Bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: 120),
            ),
          ],
        ),
      ),
      bottomSheet: _buildStartButton(),
    );
  }

  Widget _buildCardCountSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Numero di carte',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [3, 5, 7, 10].map((count) {
              final isSelected = _cardCount == count;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _cardCount = count);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context)
                                .colorScheme
                                .outline
                                .withOpacity(0.3),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '$count',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: isSelected
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.onSurface,
                              fontWeight:
                                  isSelected ? FontWeight.bold : FontWeight.w500,
                            ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: SwitchListTile(
        title: Text('catalog.favorites'.tr()),
        subtitle: Text(
          _favoritesOnly 
            ? 'Solo dalle tue scoperte salvate'
            : 'Includi tutte le posizioni',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        value: _favoritesOnly,
        onChanged: (value) {
          HapticFeedback.selectionClick();
          setState(() => _favoritesOnly = value);
        },
        secondary: Icon(
          _favoritesOnly ? Icons.favorite : Icons.favorite_border,
          color: _favoritesOnly ? AppColors.burgundy : null,
        ),
      ),
    );
  }

  // ─── emoji helpers ──────────────────────────────────────────────────────────

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
      case PositionFocus.intimacy:    return '💕';
      case PositionFocus.variety:     return '🎨';
      case PositionFocus.connection:  return '🔮';
      case PositionFocus.relax:       return '🧘';
      case PositionFocus.playfulness: return '🎉';
      case PositionFocus.passion:     return '❤️‍🔥';
      case PositionFocus.trust:       return '🤲';
    }
  }

  Color _energyColor(EnergyLevel e) {
    switch (e) {
      case EnergyLevel.low:    return AppColors.soft;
      case EnergyLevel.medium: return AppColors.spicy;
      case EnergyLevel.high:   return AppColors.extraSpicy;
    }
  }

  // ─── chip builders ──────────────────────────────────────────────────────────

  Widget _filterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
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
            color: isSelected ? accentColor : theme.colorScheme.onSurface.withOpacity(0.85),
          ),
        ),
      ),
      selected: isSelected,
      showCheckmark: false,
      onSelected: (_) { HapticFeedback.selectionClick(); onTap(); },
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      backgroundColor: theme.colorScheme.surface,
      selectedColor: accentColor.withOpacity(0.12),
      side: isSelected
          ? BorderSide(color: accentColor, width: 1.5)
          : BorderSide(color: theme.colorScheme.outline.withOpacity(0.25)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
    );
  }

  Widget _choiceChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
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
            color: isSelected ? accentColor : theme.colorScheme.onSurface.withOpacity(0.85),
          ),
        ),
      ),
      selected: isSelected,
      showCheckmark: false,
      onSelected: (_) { HapticFeedback.selectionClick(); onTap(); },
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      backgroundColor: theme.colorScheme.surface,
      selectedColor: accentColor.withOpacity(0.12),
      side: isSelected
          ? BorderSide(color: accentColor, width: 1.5)
          : BorderSide(color: theme.colorScheme.outline.withOpacity(0.25)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  // ─── filter sections ────────────────────────────────────────────────────────

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('catalog.category'.tr(), Icons.grid_view_rounded),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: LayoutBuilder(
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
                      onTap: () => setState(() {
                        isSelected ? _selectedCategories.remove(category) : _selectedCategories.add(category);
                      }),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDifficultySlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('catalog.difficulty'.tr(), Icons.star_outline_rounded),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
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
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: SliderTheme(
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
                _difficultyRange.start.round().toString(),
                _difficultyRange.end.round().toString(),
              ),
              onChanged: (values) => setState(() => _difficultyRange = values),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnergySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('catalog.energy'.tr(), Icons.bolt_rounded),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: EnergyLevel.values.asMap().entries.map((entry) {
              final i = entry.key;
              final energy = entry.value;
              final isSelected = _selectedEnergy == energy;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < EnergyLevel.values.length - 1 ? AppSpacing.sm : 0),
                  child: _choiceChip(
                    label: '${_energyEmoji(energy)}  ${'energy.${energy.name}'.tr()}',
                    isSelected: isSelected,
                    accentColor: _energyColor(energy),
                    onTap: () => setState(() {
                      _selectedEnergy = isSelected ? null : energy;
                    }),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDurationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('catalog.duration'.tr(), Icons.timer_outlined),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: PositionDuration.values.asMap().entries.map((entry) {
              final i = entry.key;
              final duration = entry.value;
              final isSelected = _selectedDuration == duration;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < PositionDuration.values.length - 1 ? AppSpacing.sm : 0),
                  child: _choiceChip(
                    label: '${_durationEmoji(duration)}  ${'duration.${duration.name}'.tr()}',
                    isSelected: isSelected,
                    accentColor: AppColors.gold,
                    onTap: () => setState(() {
                      _selectedDuration = isSelected ? null : duration;
                    }),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildFocusSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('catalog.focus'.tr(), Icons.psychology_outlined),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: LayoutBuilder(
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
                      onTap: () => setState(() {
                        isSelected ? _selectedFocus.remove(focus) : _selectedFocus.add(focus);
                      }),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStartButton() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_hasActiveFilters)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text(
                  'shuffle.filters_active'.tr(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _startSession,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
                child: Text(
                  'shuffle.start_session'.tr(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}