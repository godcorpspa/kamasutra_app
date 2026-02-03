import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../../../app/router.dart';
import '../../../../data/models/goose_game.dart';
import '../../../../data/models/game.dart';

/// Goose Game setup screen - configure board, mode, and intensity
class GooseSetupScreen extends ConsumerStatefulWidget {
  const GooseSetupScreen({super.key});

  @override
  ConsumerState<GooseSetupScreen> createState() => _GooseSetupScreenState();
}

class _GooseSetupScreenState extends ConsumerState<GooseSetupScreen> {
  GooseBoardSize _boardSize = GooseBoardSize.medium;
  GoosePlayMode _playMode = GoosePlayMode.cooperative;
  GameIntensity _intensity = GameIntensity.soft;
  bool _useRiggedDice = false;
  Set<GooseSquareType> _excludedTypes = {};

  void _startGame() {
    HapticFeedback.mediumImpact();
    
    final config = GooseGameConfig(
      boardSize: _boardSize,
      playMode: _playMode,
      intensity: _intensity,
      useRiggedDice: _useRiggedDice,
      excludedSquareTypes: _excludedTypes.toList(),
    );

    context.push(
      AppRoutes.gooseGame,
      extra: config,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('games.goose_game.title'.tr()),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Description
            Text(
              'games.goose_game.description'.tr(),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            
            const SizedBox(height: AppSpacing.xl),
            
            // Board size
            _buildSectionTitle('games.goose_game.board_size'.tr()),
            const SizedBox(height: AppSpacing.sm),
            _buildBoardSizeSelector(),
            
            const SizedBox(height: AppSpacing.xl),
            
            // Play mode
            _buildSectionTitle('games.goose_game.play_mode'.tr()),
            const SizedBox(height: AppSpacing.sm),
            _buildPlayModeSelector(),
            
            const SizedBox(height: AppSpacing.xl),
            
            // Intensity
            _buildSectionTitle('games.goose_game.intensity'.tr()),
            const SizedBox(height: AppSpacing.sm),
            _buildIntensitySelector(),
            
            const SizedBox(height: AppSpacing.xl),
            
            // Advanced options
            _buildSectionTitle('Opzioni avanzate'),
            const SizedBox(height: AppSpacing.sm),
            _buildAdvancedOptions(),
            
            const SizedBox(height: AppSpacing.xxl),
            
            // Start button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _startGame,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  backgroundColor: AppColors.burgundy,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  'games.start_game'.tr(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildBoardSizeSelector() {
    return Column(
      children: GooseBoardSize.values.map((size) {
        final isSelected = _boardSize == size;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _boardSize = size);
            },
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: isSelected 
                    ? AppColors.burgundy.withOpacity(0.1)
                    : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: isSelected 
                      ? AppColors.burgundy 
                      : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? AppColors.burgundy 
                          : Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Center(
                      child: Text(
                        '${size.totalSquares}',
                        style: TextStyle(
                          color: isSelected ? Colors.white : null,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'games.goose_game.${size.name}'.tr(),
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _getBoardDescription(size),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: AppColors.burgundy,
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _getBoardDescription(GooseBoardSize size) {
    switch (size) {
      case GooseBoardSize.quick:
        return '15-20 minuti • Perfetto per iniziare';
      case GooseBoardSize.medium:
        return '25-35 minuti • L\'esperienza classica';
      case GooseBoardSize.long:
        return '45-60 minuti • Per una serata speciale';
    }
  }

  Widget _buildPlayModeSelector() {
    return Row(
      children: GoosePlayMode.values.map((mode) {
        final isSelected = _playMode == mode;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: mode == GoosePlayMode.cooperative ? AppSpacing.sm : 0,
              left: mode == GoosePlayMode.sweetChallenge ? AppSpacing.sm : 0,
            ),
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _playMode = mode);
              },
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? AppColors.burgundy.withOpacity(0.1)
                      : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: isSelected 
                        ? AppColors.burgundy 
                        : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      mode == GoosePlayMode.cooperative 
                          ? Icons.favorite 
                          : Icons.emoji_events,
                      color: isSelected ? AppColors.burgundy : null,
                      size: 32,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'games.goose_game.${mode.name}'.tr(),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getModeDescription(mode),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _getModeDescription(GoosePlayMode mode) {
    switch (mode) {
      case GoosePlayMode.cooperative:
        return 'Insieme verso il traguardo';
      case GoosePlayMode.sweetChallenge:
        return 'Chi vince sceglie il finale';
    }
  }

  Widget _buildIntensitySelector() {
    return Row(
      children: GameIntensity.values.map((intensity) {
        final isSelected = _intensity == intensity;
        final color = _getIntensityColor(intensity);
        
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _intensity = intensity);
              },
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.md,
                  horizontal: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? color.withOpacity(0.2)
                      : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: isSelected 
                        ? color 
                        : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      _getIntensityEmoji(intensity),
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'intensity.${intensity.name}'.tr(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: isSelected ? FontWeight.bold : null,
                        color: isSelected ? color : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _getIntensityColor(GameIntensity intensity) {
    switch (intensity) {
      case GameIntensity.soft:
        return AppColors.soft;
      case GameIntensity.spicy:
        return AppColors.spicy;
      case GameIntensity.extraSpicy:
        return AppColors.extraSpicy;
    }
  }

  String _getIntensityEmoji(GameIntensity intensity) {
    switch (intensity) {
      case GameIntensity.soft:
        return '🌸';
      case GameIntensity.spicy:
        return '🌶️';
      case GameIntensity.extraSpicy:
        return '🔥';
    }
  }

  Widget _buildAdvancedOptions() {
    return Column(
      children: [
        // Rigged dice option
        SwitchListTile(
          title: Text('games.goose_game.rigged_dice'.tr()),
          subtitle: Text(
            _useRiggedDice 
                ? 'Dado 3-5: partita più veloce'
                : 'Dado classico 1-6',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          value: _useRiggedDice,
          onChanged: (value) {
            HapticFeedback.selectionClick();
            setState(() => _useRiggedDice = value);
          },
          contentPadding: EdgeInsets.zero,
        ),
        
        // Excluded square types
        ExpansionTile(
          title: const Text('Caselle escluse'),
          subtitle: Text(
            _excludedTypes.isEmpty 
                ? 'Tutte le caselle attive'
                : '${_excludedTypes.length} tipi esclusi',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          tilePadding: EdgeInsets.zero,
          children: [
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                GooseSquareType.well,
                GooseSquareType.labyrinth,
                GooseSquareType.inn,
              ].map((type) {
                final isExcluded = _excludedTypes.contains(type);
                return FilterChip(
                  label: Text('games.goose_game.square_${type.name}'.tr()),
                  selected: isExcluded,
                  onSelected: (_) {
                    setState(() {
                      if (isExcluded) {
                        _excludedTypes.remove(type);
                      } else {
                        _excludedTypes.add(type);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ],
    );
  }
}
