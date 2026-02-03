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
  bool _showFavoritesOnly = false;

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
    setState(() {
      _showFavoritesOnly = !_showFavoritesOnly;
    });
    ref.read(positionFilterProvider.notifier).setFavoritesOnly(_showFavoritesOnly);
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
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'catalog.title'.tr(),
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ),
                      // Favorites toggle
                      IconButton(
                        onPressed: _toggleFavorites,
                        icon: Icon(
                          _showFavoritesOnly
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: _showFavoritesOnly
                              ? AppColors.burgundy
                              : null,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Search bar
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          decoration: InputDecoration(
                            hintText: 'catalog.search_hint'.tr(),
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      _onSearchChanged('');
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: Theme.of(context)
                                .colorScheme
                                .surface
                                .withOpacity(0.5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      // Filter button
                      Badge(
                        isLabelVisible: hasActiveFilters,
                        backgroundColor: AppColors.burgundy,
                        child: IconButton.filled(
                          onPressed: _showFilters,
                          style: IconButton.styleFrom(
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .surface
                                .withOpacity(0.5),
                          ),
                          icon: const Icon(Icons.tune),
                        ),
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
                    return _buildEmptyState(context, allPositions.isNotEmpty);
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

  Widget _buildEmptyState(BuildContext context, bool hasFilters) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _showFavoritesOnly ? Icons.favorite_border : Icons.search_off,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              _showFavoritesOnly
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
                  setState(() => _showFavoritesOnly = false);
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
      padding: const EdgeInsets.all(AppSpacing.md),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
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
              // Force rebuild
              ref.invalidate(positionsProvider(context.locale.languageCode));
            }
          },
        ).animate().fadeIn(delay: Duration(milliseconds: 50 * (index % 10)));
      },
    );
  }
}
