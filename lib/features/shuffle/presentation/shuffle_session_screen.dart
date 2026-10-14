import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';

import '../../../app/theme.dart';
import '../../../shared/utils/display_text.dart';
import '../../../shared/widgets/brand.dart';
import '../../catalog/widgets/category_style.dart';
import '../../catalog/widgets/position_illustration.dart';
import '../../../app/router.dart';
import '../../../data/models/position.dart';
import '../../../data/models/game.dart';
import '../../../data/providers/providers.dart';
import '../../../data/services/preferences_service.dart';
import '../../catalog/presentation/position_detail_screen.dart';

/// Shuffle session - swipeable card stack experience
class ShuffleSessionScreen extends ConsumerStatefulWidget {
  final PositionFilter filter;
  final int cardCount;

  const ShuffleSessionScreen({
    super.key,
    required this.filter,
    required this.cardCount,
  });

  @override
  ConsumerState<ShuffleSessionScreen> createState() => _ShuffleSessionScreenState();
}

class _ShuffleSessionScreenState extends ConsumerState<ShuffleSessionScreen>
    with TickerProviderStateMixin {
  
  List<Position> _positions = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _sessionComplete = false;
  
  late AnimationController _cardController;
  late Animation<Offset> _cardAnimation;
  Offset _dragOffset = Offset.zero;
  
  late ConfettiController _confettiController;

  // Timer per tracciare il tempo della sessione
  late DateTime _sessionStartTime;

  @override
  void initState() {
    super.initState();
    _sessionStartTime = DateTime.now();
    _loadPositions();
    _setupAnimations();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
  }

  void _setupAnimations() {
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _cardAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeOut,
    ));
  }

  Future<void> _loadPositions() async {
    final repository = ref.read(positionRepositoryProvider);
    final allPositions = repository.getFiltered(widget.filter);

    if (allPositions.isEmpty) {
      setState(() {
        _positions = [];
        _isLoading = false;
      });
      return;
    }

    // Shuffle and take requested count
    final shuffled = List<Position>.from(allPositions)..shuffle();
    final selected = shuffled.take(widget.cardCount).toList();

    setState(() {
      _positions = selected;
      _isLoading = false;
    });
  } 

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond;
    final dx = _dragOffset.dx;
    
    if (dx.abs() > 100 || velocity.dx.abs() > 500) {
      _dismissCard(dx > 0 ? 'right' : 'left');
    } else {
      setState(() {
        _dragOffset = Offset.zero;
      });
    }
  }

  void _dismissCard(String direction) {
    HapticFeedback.mediumImpact();

    // Record reaction based on swipe direction
    final reaction = direction == 'right'
        ? PositionReaction.liked
        : PositionReaction.skipped;

    _recordReaction(reaction);

    // Se "Proviamo!" (destra), segna come posizione provata
    if (direction == 'right' && _currentIndex < _positions.length) {
      final position = _positions[_currentIndex];
      PreferencesService.instance.addTriedPosition(position.id);
    }

    setState(() {
      _dragOffset = Offset.zero;
      _currentIndex++;

      if (_currentIndex >= _positions.length) {
        _sessionComplete = true;
        _confettiController.play();

        // Traccia partita completata
        PreferencesService.instance.incrementGamesPlayed();
        // Registra uso per la streak
        PreferencesService.instance.recordUsageToday();
        // Traccia tempo insieme
        final durationMinutes = DateTime.now().difference(_sessionStartTime).inMinutes;
        PreferencesService.instance.addTimeTogetherMinutes(durationMinutes.clamp(1, 120));
      }
    });
  }

  void _recordReaction(PositionReaction reaction) {
    if (_currentIndex < _positions.length) {
      final position = _positions[_currentIndex];
      PreferencesService.instance.addHistoryEntry({
        'positionId': position.id,
        'viewedAt': DateTime.now().toIso8601String(),
        'reaction': reaction.name,
      });
    }
  }

  void _showPositionDetail() {
    if (_currentIndex < _positions.length) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PositionDetailScreen(
            positionId: _positions[_currentIndex].id,
          ),
        ),
      );
    }
  }

  void _toggleFavorite() async {
    if (_currentIndex >= _positions.length) return;

    HapticFeedback.lightImpact();
    final position = _positions[_currentIndex];
    final repo = ref.read(positionRepositoryProvider);

    // Toggle favorite (add or remove)
    await repo.toggleFavorite(position.id);
    final locale = Localizations.localeOf(context).languageCode;
    if (mounted) {
      ref.invalidate(positionsProvider(locale));
      // Update the local list so the heart icon reflects the new state immediately
      final updated = repo.getById(position.id);
      setState(() {
        if (updated != null) {
          _positions[_currentIndex] = updated;
        }
      });
    }
  }

  @override
  void dispose() {
    _cardController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: false,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: _isLoading || _sessionComplete
            ? null
            : Text(
                '${_currentIndex + 1} / ${_positions.length}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
        actions: [
          if (!_isLoading && !_sessionComplete)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _currentIndex = 0;
                  _sessionComplete = false;
                  _sessionStartTime = DateTime.now();
                });
                _loadPositions();
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            if (_isLoading)
              _buildLoading()
            else if (_positions.isEmpty)
              _buildEmptyState()
            else if (_sessionComplete)
              _buildSessionComplete()
            else
              _buildCardStack(),
            
          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              maxBlastForce: 5,
              minBlastForce: 2,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.1,
              colors: const [
                AppColors.champagne,
                AppColors.rose,
                AppColors.ivory,
              ],
            ),
          ),
        ],
      ),
    ));
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.outline),
              ),
              child: const Icon(
                Icons.favorite_border,
                size: 36,
                color: AppColors.rose,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'shuffle.no_positions'.tr(),
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              widget.filter.favoritesOnly == true
                  ? 'shuffle.no_favorites_desc'.tr()
                  : 'shuffle.no_filter_results_desc'.tr(),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.mist,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back),
              label: Text('common.back'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'shuffle.preparing_cards'.tr(),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildSessionComplete() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const BrandMark(size: 56),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'shuffle.session_complete'.tr(),
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'shuffle.explored_positions'.tr(namedArgs: {'count': _positions.length.toString()}),
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton.icon(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back),
                  label: Text('common.close'.tr()),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _currentIndex = 0;
                      _sessionComplete = false;
                      _sessionStartTime = DateTime.now();
                    });
                    _loadPositions();
                  },
                  icon: const Icon(Icons.refresh),
                  label: Text('shuffle.again'.tr()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardStack() {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background cards (preview)
                if (_currentIndex + 2 < _positions.length)
                  Transform.scale(
                    scale: 0.9,
                    child: _buildCard(_positions[_currentIndex + 2], isBackground: true),
                  ),
                if (_currentIndex + 1 < _positions.length)
                  Transform.scale(
                    scale: 0.95,
                    child: _buildCard(_positions[_currentIndex + 1], isBackground: true),
                  ),
                  
                // Current card
                GestureDetector(
                  onTap: _showPositionDetail,
                  onPanUpdate: _onPanUpdate,
                  onPanEnd: _onPanEnd,
                  child: Transform.translate(
                    offset: _dragOffset,
                    child: Transform.rotate(
                      angle: _dragOffset.dx * 0.001,
                      child: _buildCard(_positions[_currentIndex]),
                    ),
                  ),
                ),
                  
                // Swipe indicators
                if (_dragOffset.dx > 50)
                  Positioned(
                    left: 40,
                    child: _buildSwipeIndicator(Icons.check, AppColors.champagne),
                  ),
                if (_dragOffset.dx < -50)
                  Positioned(
                    right: 40,
                    child: _buildSwipeIndicator(Icons.close, AppColors.smoke),
                  ),
              ],
            ),
          ),
        ),
        
        // Action buttons
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildCard(Position position, {bool isBackground = false}) {
    final lang = Localizations.localeOf(context).languageCode;
    final alias = position.getAlias(lang);
    final category = position.categories.first;
    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      height: MediaQuery.of(context).size.height * 0.56,
      decoration: BoxDecoration(
        color: isBackground ? AppColors.inkRaised.withOpacity(0.6) : AppColors.inkRaised,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.hairline),
        boxShadow: isBackground
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 30,
                  offset: const Offset(0, 14),
                ),
              ],
      ),
      child: isBackground
          ? null
          : Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 3,
                    child: PositionIllustration(
                      position: position,
                      borderRadius: BorderRadius.circular(20),
                      monogramSize: 88,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 16, 12, 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'categories.${category.name}'.tr().toUpperCase(),
                            style: AppTypography.eyebrow
                                .copyWith(color: category.tint, fontSize: 10),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            position.getName(lang),
                            style: Theme.of(context).textTheme.headlineMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (alias != null && alias.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              alias,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: AppTypography.displayFont,
                                fontStyle: FontStyle.italic,
                                fontSize: 16,
                                color: AppColors.mist,
                              ),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            children: [
                              DifficultyMeter(
                                  difficulty: position.difficulty, barWidth: 7),
                              const SizedBox(width: AppSpacing.md),
                              _buildFact(position.energy.icon,
                                  'energy.${position.energy.name}'.tr()),
                              const SizedBox(width: AppSpacing.md),
                              _buildFact(position.duration.icon,
                                  'duration.${position.duration.name}'.tr()),
                            ],
                          ),
                          const Spacer(),
                          Center(
                            child: Text(
                              plainLabel('shuffle.tap_for_details'.tr())
                                  .toUpperCase(),
                              style: AppTypography.eyebrow.copyWith(fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildFact(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppColors.smoke),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12.5, color: AppColors.mist)),
      ],
    );
  }

  Widget _buildSwipeIndicator(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.ink.withOpacity(0.7),
        shape: BoxShape.circle,
        border: Border.all(color: color),
      ),
      child: Icon(
        icon,
        color: color,
        size: 30,
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.md,
        bottom: AppSpacing.xxl + 16,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Skip
          _ActionButton(
            icon: Icons.close,
            color: AppColors.mist,
            onPressed: () => _dismissCard('left'),
            label: 'shuffle.skip'.tr(),
          ),
          
          // Favorite
          _ActionButton(
            icon: (_currentIndex < _positions.length && _positions[_currentIndex].isFavorite)
                ? Icons.favorite
                : Icons.favorite_border,
            color: AppColors.rose,
            onPressed: _toggleFavorite,
            label: 'shuffle.save'.tr(),
          ),
          
          // Like / Try this
          _ActionButton(
            icon: Icons.check,
            color: AppColors.champagne,
            filled: true,
            onPressed: () => _dismissCard('right'),
            label: 'shuffle.tried'.tr(),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final String label;
  final bool filled;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onPressed,
    required this.label,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    const size = 62.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Material(
            color: filled ? color : Colors.transparent,
            shape: CircleBorder(
              side: BorderSide(color: filled ? color : AppColors.outline),
            ),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onPressed,
              child: Icon(
                icon,
                color: filled ? AppColors.onAccent : color,
                size: 26,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          plainLabel(label).toUpperCase(),
          style: AppTypography.eyebrow.copyWith(
            fontSize: 10,
            color: filled ? color : AppColors.mist,
          ),
        ),
      ],
    );
  }
}
