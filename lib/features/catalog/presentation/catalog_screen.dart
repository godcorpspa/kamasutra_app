import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../app/theme.dart';
import '../../../data/models/position.dart';
import '../../../data/providers/providers.dart';
import '../widgets/position_card.dart';
import '../widgets/filter_sheet.dart';

class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({super.key});

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  final TextEditingController _searchController = TextEditingController();

  static final _pill = OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadius.round),
    borderSide: const BorderSide(color: AppColors.hairline),
  );

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    ref.read(positionFilterProvider.notifier).setSearchQuery(
      query.isEmpty ? null : query,
    );
  }

  void _toggleFavorites() {
    final current = ref.read(positionFilterProvider).favoritesOnly ?? false;
    ref.read(positionFilterProvider.notifier).setFavoritesOnly(!current);
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const FilterSheet(),
    );
  }

  void _onPositionTap(Position position) {
    HapticFeedback.lightImpact();
    context.push('/catalog/${position.id}');
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.languageCode;
    final positionsAsync = ref.watch(positionsProvider(locale));
    final filter = ref.watch(positionFilterProvider);
    // Derive from provider so external resets (e.g. tab switch) are reflected
    final showFavoritesOnly = filter.favoritesOnly ?? false;
    final hasActiveFilters = filter.categories != null ||
        filter.minDifficulty != null ||
        filter.maxDifficulty != null ||
        filter.energyLevels != null ||
        filter.focus != null ||
        filter.durations != null;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('KAMASUTRA',
                                style: AppTypography.eyebrow),
                            const SizedBox(height: 6),
                            Text(
                              showFavoritesOnly
                                  ? 'catalog.favorites'.tr()
                                  : 'catalog.title'.tr(),
                              style: Theme.of(context).textTheme.displaySmall,
                            ),
                          ],
                        ),
                      ),
                      // Favorites toggle
                      _HeaderIconButton(
                        icon: showFavoritesOnly
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: showFavoritesOnly
                            ? AppColors.rose
                            : AppColors.ivory,
                        onPressed: _toggleFavorites,
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Search bar
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: TextField(
                            controller: _searchController,
                            onChanged: _onSearchChanged,
                            style: Theme.of(context).textTheme.bodyMedium,
                            decoration: InputDecoration(
                              hintText: 'catalog.search_hint'.tr(),
                              prefixIcon: const Icon(Icons.search, size: 20),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.close, size: 18),
                                      onPressed: () {
                                        _searchController.clear();
                                        _onSearchChanged('');
                                      },
                                    )
                                  : null,
                              contentPadding: EdgeInsets.zero,
                              border: _pill,
                              enabledBorder: _pill,
                              focusedBorder: _pill.copyWith(
                                borderSide: const BorderSide(
                                    color: AppColors.champagne),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      // Filter button
                      _HeaderIconButton(
                        icon: Icons.tune,
                        onPressed: _showFilters,
                        filled: true,
                        showDot: hasActiveFilters,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: positionsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text('errors.generic'.tr()),
                      const SizedBox(height: AppSpacing.md),
                      TextButton(
                        onPressed: () => ref.refresh(positionsProvider(locale)),
                        child: Text('common.retry'.tr()),
                      ),
                    ],
                  ),
                ),
                data: (allPositions) {
                  final positions = ref.watch(filteredPositionsProvider(locale));

                  if (positions.isEmpty) {
                    return _buildEmptyState(context, allPositions.isNotEmpty, showFavoritesOnly);
                  }

                  return _buildGrid(positions);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool hasFilters, bool showFavoritesOnly) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              showFavoritesOnly ? Icons.favorite_border : Icons.search_off,
              size: 48,
              color: AppColors.smoke,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              showFavoritesOnly
                  ? 'catalog.no_favorites'.tr()
                  : hasFilters
                      ? 'errors.no_positions'.tr()
                      : 'errors.try_different_filters'.tr(),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
              textAlign: TextAlign.center,
            ),
            if (hasFilters) ...[
              const SizedBox(height: AppSpacing.lg),
              TextButton(
                onPressed: () {
                  ref.read(positionFilterProvider.notifier).clear();
                },
                child: Text('common.clear_filters'.tr()),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(List<Position> positions) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.lg),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.64,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: positions.length,
      itemBuilder: (context, index) {
        final position = positions[index];
        return PositionCard(
          position: position,
          onTap: () => _onPositionTap(position),
          onFavoriteTap: () async {
            HapticFeedback.lightImpact();
            final repo = ref.read(positionRepositoryProvider);
            await repo.toggleFavorite(position.id);
            if (mounted) {
              ref.invalidate(positionsProvider(context.locale.languageCode));
            }
          },
        ).animate().fadeIn(delay: Duration(milliseconds: 50 * (index % 10)));
      },
    );
  }
}

/// Round 48px header action: plain icon, or an [AppColors.inkHigh] disc with
/// a hairline border when [filled]; [showDot] adds a champagne status dot.
class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;
  final bool filled;
  final bool showDot;

  const _HeaderIconButton({
    required this.icon,
    required this.onPressed,
    this.color = AppColors.ivory,
    this.filled = false,
    this.showDot = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50,
      height: 50,
      child: Stack(
        children: [
          Positioned.fill(
            child: Material(
              color: filled ? AppColors.inkHigh : Colors.transparent,
              shape: CircleBorder(
                side: BorderSide(
                  color: filled ? AppColors.hairline : Colors.transparent,
                ),
              ),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onPressed,
                child: Icon(icon, size: 21, color: color),
              ),
            ),
          ),
          if (showDot)
            const Positioned(
              top: 12,
              right: 12,
              child: SizedBox(
                width: 8,
                height: 8,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.champagne,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
