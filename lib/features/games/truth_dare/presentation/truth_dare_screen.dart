import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../../../data/models/game.dart';

/// Truth or Dare game screen
class TruthDareScreen extends ConsumerStatefulWidget {
  const TruthDareScreen({super.key});

  @override
  ConsumerState<TruthDareScreen> createState() => _TruthDareScreenState();
}

class _TruthDareScreenState extends ConsumerState<TruthDareScreen>
    with SingleTickerProviderStateMixin {
  
  GameIntensity _intensity = GameIntensity.soft;
  bool _gameStarted = false;
  int _currentPlayer = 1;
  String? _currentCard;
  bool? _isTruth;
  
  late AnimationController _cardController;
  late Animation<double> _cardAnimation;
  
  final Random _random = Random();

  // Sample cards (in real app, load from JSON)
  final Map<GameIntensity, List<String>> _truths = {
    GameIntensity.soft: [
      'Qual è il tuo ricordo più bello insieme?',
      'Cosa ti ha fatto innamorare del partner?',
      'Qual è il tuo momento preferito della giornata con il partner?',
      'Cosa apprezzi di più nella nostra relazione?',
      'Qual è stato il momento in cui hai capito di essere innamorato/a?',
    ],
    GameIntensity.spicy: [
      'Qual è la tua fantasia segreta che non hai mai condiviso?',
      'Qual è la cosa più audace che vorresti provare insieme?',
      'Dove vorresti fare l\'amore che non abbiamo mai provato?',
      'Cosa ti eccita di più del partner?',
      'Qual è il ricordo più intenso che abbiamo insieme?',
    ],
    GameIntensity.extraSpicy: [
      'Qual è la tua fantasia più selvaggia?',
      'Cosa vorresti che ti facessi stanotte?',
      'Qual è stata la nostra esperienza più intensa?',
      'C\'è qualcosa che non abbiamo mai provato e vorresti?',
      'Descrivi la serata perfetta dei tuoi sogni...',
    ],
  };

  final Map<GameIntensity, List<String>> _dares = {
    GameIntensity.soft: [
      'Dai un bacio sulla fronte al partner',
      'Abbraccia il partner per 30 secondi',
      'Sussurra qualcosa di dolce all\'orecchio del partner',
      'Massaggia le mani del partner per 1 minuto',
      'Guarda negli occhi il partner per 1 minuto senza parlare',
    ],
    GameIntensity.spicy: [
      'Bacia il collo del partner per 30 secondi',
      'Massaggia le spalle del partner per 2 minuti',
      'Togli un capo di abbigliamento al partner',
      'Dai un bacio in un punto a tua scelta',
      'Sussurra cosa faresti al partner se potessi...',
    ],
    GameIntensity.extraSpicy: [
      'Bacia il partner come se fosse l\'ultima volta',
      'Mostra al partner come ti piace essere toccato/a',
      'Scegli un punto del corpo del partner e dedicagli attenzione',
      'Guidate le mani del partner dove preferite',
      'Fate qualcosa che non avete mai provato prima',
    ],
  };

  @override
  void initState() {
    super.initState();
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _cardAnimation = CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeOutBack,
    );
  }

  @override
  void dispose() {
    _cardController.dispose();
    super.dispose();
  }

  void _selectTruthOrDare(bool isTruth) {
    HapticFeedback.mediumImpact();
    
    final cards = isTruth ? _truths[_intensity]! : _dares[_intensity]!;
    final card = cards[_random.nextInt(cards.length)];
    
    setState(() {
      _isTruth = isTruth;
      _currentCard = card;
    });
    
    _cardController.forward(from: 0);
  }

  void _nextTurn() {
    HapticFeedback.lightImpact();
    setState(() {
      _currentCard = null;
      _isTruth = null;
      _currentPlayer = _currentPlayer == 1 ? 2 : 1;
    });
  }

  void _skipCard() {
    HapticFeedback.lightImpact();
    _selectTruthOrDare(_isTruth!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('games.truth_dare.title'.tr()),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _gameStarted ? _buildGameView() : _buildSetupView(),
    );
  }

  Widget _buildSetupView() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Description
          Text(
            'games.truth_dare.description'.tr(),
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: AppSpacing.xxl),
          
          // Intensity selector
          Text(
            'games.goose_game.intensity'.tr(),
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          
          Row(
            children: GameIntensity.values.map((intensity) {
              final isSelected = _intensity == intensity;
              final color = _getIntensityColor(intensity);
              
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _intensity = intensity);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: isSelected ? color.withOpacity(0.2) : null,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: isSelected ? color : Colors.grey.withOpacity(0.3),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _getIntensityEmoji(intensity),
                            style: const TextStyle(fontSize: 32),
                          ),
                          const SizedBox(height: 8),
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
          ),
          
          const Spacer(),
          
          // Start button
          ElevatedButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              setState(() => _gameStarted = true);
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              backgroundColor: AppColors.spicy,
            ),
            child: Text(
              'games.start_game'.tr(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameView() {
    return Column(
      children: [
        // Current player indicator
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          color: _currentPlayer == 1 
              ? AppColors.burgundy.withOpacity(0.1)
              : AppColors.gold.withOpacity(0.1),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _currentPlayer == 1 ? AppColors.burgundy : AppColors.gold,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Giocatore $_currentPlayer',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
        
        Expanded(
          child: _currentCard == null 
              ? _buildChoiceView()
              : _buildCardView(),
        ),
      ],
    );
  }

  Widget _buildChoiceView() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Scegli:',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          
          const SizedBox(height: AppSpacing.xxl),
          
          Row(
            children: [
              Expanded(
                child: _ChoiceButton(
                  label: 'games.truth_dare.truth'.tr(),
                  emoji: '💬',
                  color: AppColors.soft,
                  onTap: () => _selectTruthOrDare(true),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: _ChoiceButton(
                  label: 'games.truth_dare.dare'.tr(),
                  emoji: '🎯',
                  color: AppColors.spicy,
                  onTap: () => _selectTruthOrDare(false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardView() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          const Spacer(),
          
          // Card
          ScaleTransition(
            scale: _cardAnimation,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _isTruth! ? AppColors.soft : AppColors.spicy,
                    (_isTruth! ? AppColors.soft : AppColors.spicy).withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppRadius.xl),
                boxShadow: [
                  BoxShadow(
                    color: (_isTruth! ? AppColors.soft : AppColors.spicy).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    _isTruth! ? '💬 VERITÀ' : '🎯 OBBLIGO',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    _currentCard!,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          
          const Spacer(),
          
          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _skipCard,
                  icon: const Icon(Icons.refresh),
                  label: Text('games.skip_card'.tr()),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _nextTurn,
                  icon: const Icon(Icons.check),
                  label: const Text('Fatto!'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          // End game button
          TextButton(
            onPressed: () => context.pop(),
            child: Text('games.end_game'.tr()),
          ),
        ],
      ),
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
}

class _ChoiceButton extends StatelessWidget {
  final String label;
  final String emoji;
  final Color color;
  final VoidCallback onTap;

  const _ChoiceButton({
    required this.label,
    required this.emoji,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color, color.withOpacity(0.8)],
          ),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
