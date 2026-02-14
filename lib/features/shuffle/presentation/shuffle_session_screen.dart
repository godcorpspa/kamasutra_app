import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';

import '../../../app/theme.dart';
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ "${position.getName(Localizations.localeOf(context).languageCode)}" aggiunta alle provate!'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
          ),
        );
      }
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
    if (_currentIndex < _positions.length) {
      HapticFeedback.lightImpact();
      final position = _positions[_currentIndex];
      final newStatus = await ref.read(positionRepositoryProvider).toggleFavorite(position.id);

      final locale = Localizations.localeOf(context).languageCode;
      ref.invalidate(positionsProvider(locale));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus
                  ? '❤️ Aggiunta ai preferiti!'
                  : 'Rimossa dai preferiti',
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
          ),
        );
        setState(() {});
      }
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
                AppColors.burgundy,
                AppColors.gold,
                AppColors.blush,
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
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.burgundy.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite_border,
                size: 48,
                color: AppColors.burgundy,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Nessuna posizione trovata',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              widget.filter.favoritesOnly == true
                  ? 'Non hai ancora salvato posizioni tra i preferiti.\n'
                    'Esplora il catalogo e tocca ❤️ per aggiungerne!'
                  : 'Nessuna posizione corrisponde ai filtri selezionati.\n'
                    'Prova a cambiare i filtri.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Torna indietro'),
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
            'Preparo le carte...',
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
            const Icon(
              Icons.celebration,
              size: 80,
              color: AppColors.gold,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'shuffle.session_complete'.tr(),
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Avete esplorato ${_positions.length} posizioni insieme!',
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
                  label: const Text('Esci'),
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
                  label: const Text('Ancora'),
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
                    child: _buildSwipeIndicator(Icons.favorite, AppColors.burgundy),
                  ),
                if (_dragOffset.dx < -50)
                  Positioned(
                    right: 40,
                    child: _buildSwipeIndicator(Icons.skip_next, Colors.grey),
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
    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      height: MediaQuery.of(context).size.height * 0.55,
      decoration: BoxDecoration(
        color: isBackground 
            ? Theme.of(context).colorScheme.surface.withOpacity(0.5)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: isBackground ? null : [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: isBackground 
          ? null 
          : ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // SVG Illustration
                  Expanded(
                    flex: 3,
                    child: Container(
                      color: AppColors.burgundy.withOpacity(0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: SvgPicture.asset(
                          'assets/images/positions/${position.illustrationRef}',
                          fit: BoxFit.contain,
                          placeholderBuilder: (_) => Center(
                            child: Icon(
                              Icons.image,
                              size: 80,
                              color: AppColors.burgundy.withOpacity(0.3),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Info section
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            position.getName(Localizations.localeOf(context).languageCode),
                            style: Theme.of(context).textTheme.headlineSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (position.getAlias(Localizations.localeOf(context).languageCode) != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              position.getAlias(Localizations.localeOf(context).languageCode)!,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontStyle: FontStyle.italic,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.md),
                          
                          // Tags
                          Wrap(
                            spacing: AppSpacing.xs,
                            runSpacing: AppSpacing.xs,
                            children: [
                              _buildTag(_getDifficultyLabel(position.difficulty)),
                              _buildTag('energy.${position.energy.name}'.tr()),
                              _buildTag('duration.${position.duration.name}'.tr()),
                            ],
                          ),
                          
                          const Spacer(),
                          
                          // Tap hint
                          Center(
                            child: Text(
                              'Tocca per dettagli',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                              ),
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

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  String _getDifficultyLabel(int difficulty) {
    switch (difficulty) {
      case 1: return '⭐';
      case 2: return '⭐⭐';
      case 3: return '⭐⭐⭐';
      case 4: return '⭐⭐⭐⭐';
      case 5: return '⭐⭐⭐⭐⭐';
      default: return '⭐⭐⭐';
    }
  }

  Widget _buildSwipeIndicator(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 32,
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
            color: Colors.grey,
            onPressed: () => _dismissCard('left'),
            label: 'Salta',
          ),
          
          // Favorite
          _ActionButton(
            icon: Icons.favorite,
            color: AppColors.burgundy,
            onPressed: _toggleFavorite,
            label: 'Salva',
          ),
          
          // Like / Try this
          _ActionButton(
            icon: Icons.check,
            color: AppColors.spicy,
            onPressed: () => _dismissCard('right'),
            label: 'Provata',
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

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onPressed,
    required this.label
  });

  @override
  Widget build(BuildContext context) {
    const size = 64.0;
    const iconSize = 32.0;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: color.withOpacity(0.5),
              width: 2,
            ),
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(icon, color: color, size: iconSize),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: color,
          ),
        ),
      ],
    );
  }
}