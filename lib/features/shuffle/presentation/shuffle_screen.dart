import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../catalog/widgets/category_style.dart';
import '../../catalog/widgets/filter_options.dart';
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
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'shuffle.subtitle'.tr(),
                      style: const TextStyle(
                        fontFamily: AppTypography.displayFont,
                        fontStyle: FontStyle.italic,
                        fontSize: 18,
                        color: AppColors.mist,
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
                      style: Theme.of(context).textTheme.headlineSmall,
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
            'shuffle.card_count'.tr().toUpperCase(),
            style: AppTypography.eyebrow,
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
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? AppColors.champagne
                          : Colors.transparent,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.champagne
                            : AppColors.outline,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontFamily: AppTypography.displayFont,
                          fontFeatures: AppTypography.lining,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? AppColors.onAccent
                              : AppColors.ivory,
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
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
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
          color: _favoritesOnly ? AppColors.rose : AppColors.mist,
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md),
      child: FilterSectionLabel(title),
    );
  }

  Widget _padded(Widget child) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: child,
      );

  // ─── filter sections ────────────────────────────────────────────────────────

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('catalog.category'.tr()),
        _padded(OptionGrid(chips: [
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
        ])),
      ],
    );
  }

  Widget _buildDifficultySlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('catalog.difficulty'.tr()),
        _padded(DifficultyRangeField(
          values: _difficultyRange,
          onChanged: (values) => setState(() => _difficultyRange = values),
        )),
      ],
    );
  }

  Widget _buildEnergySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('catalog.energy'.tr()),
        _padded(OptionRow(chips: [
          for (final energy in EnergyLevel.values)
            OptionChip(
              icon: energy.icon,
              label: 'energy.${energy.name}'.tr(),
              isSelected: _selectedEnergy == energy,
              onTap: () => setState(() {
                _selectedEnergy = _selectedEnergy == energy ? null : energy;
              }),
            ),
        ])),
      ],
    );
  }

  Widget _buildDurationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('catalog.duration'.tr()),
        _padded(OptionRow(chips: [
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
        ])),
      ],
    );
  }

  Widget _buildFocusSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('catalog.focus'.tr()),
        _padded(OptionGrid(chips: [
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
        ])),
      ],
    );
  }

  Widget _buildStartButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.ink,
        border: Border(top: BorderSide(color: AppColors.hairline)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_hasActiveFilters)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text(
                  'shuffle.filters_active'.tr().toUpperCase(),
                  style: AppTypography.eyebrow
                      .copyWith(color: AppColors.champagne),
                ),
              ),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _startSession,
                child: Text('shuffle.start_session'.tr()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}