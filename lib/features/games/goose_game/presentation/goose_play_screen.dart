import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';

import '../../../../app/theme.dart';
import '../../../../data/models/goose_game.dart';
import '../../../../data/models/game.dart';

/// Goose Game play screen - the actual board game experience
class GoosePlayScreen extends ConsumerStatefulWidget {
  final GooseGameConfig config;

  const GoosePlayScreen({
    super.key,
    required this.config,
  });

  @override
  ConsumerState<GoosePlayScreen> createState() => _GoosePlayScreenState();
}

class _GoosePlayScreenState extends ConsumerState<GoosePlayScreen>
    with TickerProviderStateMixin {
  
  late GooseGameState _gameState;
  final Random _random = Random();
  
  bool _isRolling = false;
  bool _showCard = false;
  GooseCard? _currentCard;
  
  late AnimationController _diceController;
  late AnimationController _moveController;
  late ConfettiController _confettiController;

  // Sample cards (in real app, load from JSON)
  final List<GooseCard> _sampleCards = [
    GooseCard(id: '1', textIt: 'Sussurra qualcosa di dolce all\'orecchio del partner', textEn: 'Whisper something sweet', intensity: GameIntensity.soft, isChallenge: false),
    GooseCard(id: '2', textIt: 'Raccontate il vostro primo ricordo insieme', textEn: 'Share your first memory together', intensity: GameIntensity.soft, isChallenge: false),
    GooseCard(id: '3', textIt: 'Un bacio di almeno 10 secondi', textEn: 'A kiss of at least 10 seconds', intensity: GameIntensity.spicy, isChallenge: true),
    GooseCard(id: '4', textIt: 'Massaggio alla schiena per 1 minuto', textEn: '1 minute back massage', intensity: GameIntensity.spicy, isChallenge: true),
    GooseCard(id: '5', textIt: 'Cosa apprezzi di più nel partner? Dillo guardandolo negli occhi', textEn: 'What do you appreciate most?', intensity: GameIntensity.soft, isChallenge: false),
  ];

  @override
  void initState() {
    super.initState();
    _initializeGame();
    _setupAnimations();
  }

  void _initializeGame() {
    final board = _generateBoard();
    _gameState = GooseGameState(
      config: widget.config,
      board: board,
      player1Position: 0,
      player2Position: 0,
      currentPlayer: 1,
      player1InWell: false,
      player2InWell: false,
      currentCard: null,
      gameCompleted: false,
      startedAt: DateTime.now(),
    );
  }

  List<GooseSquare> _generateBoard() {
    final squares = <GooseSquare>[];
    final totalSquares = widget.config.boardSize.totalSquares;
    
    for (int i = 0; i <= totalSquares; i++) {
      GooseSquareType type = GooseSquareType.normal;
      
      if (i == 0) {
        type = GooseSquareType.normal; // Start
      } else if (i == totalSquares) {
        type = GooseSquareType.finish;
      } else if (i % 9 == 0) {
        type = GooseSquareType.goose; // Traditional goose squares
      } else if (i == 6) {
        type = GooseSquareType.bridge;
      } else if (i == totalSquares ~/ 3 && !widget.config.excludedSquareTypes.contains(GooseSquareType.well)) {
        type = GooseSquareType.well;
      } else if (i == totalSquares ~/ 2 && !widget.config.excludedSquareTypes.contains(GooseSquareType.inn)) {
        type = GooseSquareType.inn;
      } else if (i == (totalSquares * 2 ~/ 3) && !widget.config.excludedSquareTypes.contains(GooseSquareType.labyrinth)) {
        type = GooseSquareType.labyrinth;
      } else if (i % 7 == 0) {
        type = GooseSquareType.challenge;
      } else if (i % 11 == 0) {
        type = GooseSquareType.truth;
      } else if (i % 13 == 0) {
        type = GooseSquareType.bonus;
      } else if (i % 17 == 0) {
        type = GooseSquareType.couple;
      }
      
      squares.add(GooseSquare(position: i, type: type));
    }
    
    return squares;
  }

  void _setupAnimations() {
    _diceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _moveController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
  }

  void _rollDice() async {
    if (_isRolling || _gameState.gameCompleted) return;
    
    // Check if current player is in well
    final isInWell = _gameState.currentPlayer == 1 
        ? _gameState.player1InWell 
        : _gameState.player2InWell;
    
    if (isInWell) {
      // Need to roll 5 or 6 to escape
      HapticFeedback.mediumImpact();
      setState(() => _isRolling = true);
      _diceController.repeat();
      
      await Future.delayed(const Duration(milliseconds: 800));
      
      final roll = widget.config.useRiggedDice 
          ? _random.nextInt(3) + 3 // 3-5
          : _random.nextInt(6) + 1; // 1-6
      
      _diceController.stop();
      
      setState(() {
        _gameState = _gameState.copyWith(lastDiceRoll: roll);
        _isRolling = false;
        
        if (roll >= 5) {
          // Escaped!
          if (_gameState.currentPlayer == 1) {
            _gameState = _gameState.copyWith(player1InWell: false);
          } else {
            _gameState = _gameState.copyWith(player2InWell: false);
          }
          _showMessage('games.goose_game.well_escape'.tr());
        } else {
          _showMessage('Hai bisogno di 5 o 6 per uscire!');
          _switchPlayer();
        }
      });
      return;
    }
    
    HapticFeedback.mediumImpact();
    setState(() => _isRolling = true);
    _diceController.repeat();
    
    await Future.delayed(const Duration(milliseconds: 800));
    
    final roll = widget.config.useRiggedDice 
        ? _random.nextInt(3) + 3 // 3-5
        : _random.nextInt(6) + 1; // 1-6
    
    _diceController.stop();
    
    setState(() {
      _gameState = _gameState.copyWith(lastDiceRoll: roll);
      _isRolling = false;
    });
    
    await _movePlayer(roll);
  }

  Future<void> _movePlayer(int spaces) async {
    final currentPos = _gameState.currentPlayer == 1 
        ? _gameState.player1Position 
        : _gameState.player2Position;
    
    int newPos = currentPos + spaces;
    final maxPos = widget.config.boardSize.totalSquares;
    
    // Check for overshoot
    if (newPos > maxPos) {
      final overshoot = newPos - maxPos;
      newPos = maxPos - overshoot;
      _showMessage('games.goose_game.bounce_back'.tr());
    }
    
    // Animate movement
    setState(() {
      if (_gameState.currentPlayer == 1) {
        _gameState = _gameState.copyWith(player1Position: newPos);
      } else {
        _gameState = _gameState.copyWith(player2Position: newPos);
      }
    });
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Handle square effect
    await _handleSquareEffect(newPos);
  }

  Future<void> _handleSquareEffect(int position) async {
    if (position >= _gameState.board.length) return;
    
    final square = _gameState.board[position];
    
    switch (square.type) {
      case GooseSquareType.finish:
        _handleVictory();
        break;
        
      case GooseSquareType.goose:
        // Move forward same amount again
        _showMessage('🪿 Oca! Tira di nuovo il dado!');
        // In real game, would trigger another roll
        _switchPlayer();
        break;
        
      case GooseSquareType.bridge:
        _showMessage('🌉 Ponte! Avanza alla casella 12');
        setState(() {
          if (_gameState.currentPlayer == 1) {
            _gameState = _gameState.copyWith(player1Position: 12);
          } else {
            _gameState = _gameState.copyWith(player2Position: 12);
          }
        });
        _switchPlayer();
        break;
        
      case GooseSquareType.well:
        _showMessage('games.goose_game.well_trap'.tr());
        setState(() {
          if (_gameState.currentPlayer == 1) {
            _gameState = _gameState.copyWith(player1InWell: true);
          } else {
            _gameState = _gameState.copyWith(player2InWell: true);
          }
        });
        _switchPlayer();
        break;
        
      case GooseSquareType.inn:
        _showMessage('games.goose_game.inn_message'.tr());
        _switchPlayer();
        break;
        
      case GooseSquareType.labyrinth:
        _showMessage('🌀 Labirinto! Torna alla casella ${widget.config.boardSize.totalSquares ~/ 4}');
        setState(() {
          final newPos = widget.config.boardSize.totalSquares ~/ 4;
          if (_gameState.currentPlayer == 1) {
            _gameState = _gameState.copyWith(player1Position: newPos);
          } else {
            _gameState = _gameState.copyWith(player2Position: newPos);
          }
        });
        _switchPlayer();
        break;
        
      case GooseSquareType.challenge:
      case GooseSquareType.truth:
        _drawCard(square.type == GooseSquareType.challenge);
        break;
        
      case GooseSquareType.bonus:
        _showMessage('🎁 Bonus! Scegli una ricompensa per il partner');
        _switchPlayer();
        break;
        
      case GooseSquareType.couple:
        _showMessage('💑 Casella coppia! Fate qualcosa insieme');
        _drawCard(true);
        break;
        
      default:
        _switchPlayer();
    }
  }

  void _drawCard(bool isChallenge) {
    final filteredCards = _sampleCards
        .where((c) => c.intensity == widget.config.intensity || c.intensity == GameIntensity.soft)
        .toList();
    
    if (filteredCards.isEmpty) {
      _switchPlayer();
      return;
    }
    
    final card = filteredCards[_random.nextInt(filteredCards.length)];
    
    setState(() {
      _currentCard = card;
      _showCard = true;
    });
  }

  void _onCardDismissed() {
    setState(() {
      _showCard = false;
      _currentCard = null;
    });
    _switchPlayer();
  }

  void _switchPlayer() {
    if (widget.config.playMode == GoosePlayMode.cooperative) {
      // In cooperative mode, alternate turns
      setState(() {
        _gameState = _gameState.copyWith(
          currentPlayer: _gameState.currentPlayer == 1 ? 2 : 1,
        );
      });
    } else {
      // In challenge mode, same logic but tracking who's ahead
      setState(() {
        _gameState = _gameState.copyWith(
          currentPlayer: _gameState.currentPlayer == 1 ? 2 : 1,
        );
      });
    }
  }

  void _handleVictory() {
    HapticFeedback.heavyImpact();
    _confettiController.play();
    
    setState(() {
      _gameState = _gameState.copyWith(gameCompleted: true);
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _diceController.dispose();
    _moveController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('games.goose_game.title'.tr()),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showRules,
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Game board
              Expanded(
                child: _buildBoard(),
              ),
              
              // Player info and dice
              _buildControlPanel(),
            ],
          ),
          
          // Card overlay
          if (_showCard && _currentCard != null)
            _buildCardOverlay(),
          
          // Victory overlay
          if (_gameState.gameCompleted)
            _buildVictoryOverlay(),
          
          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              maxBlastForce: 10,
              minBlastForce: 5,
              emissionFrequency: 0.05,
              numberOfParticles: 30,
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
    );
  }

  Widget _buildBoard() {
    final totalSquares = widget.config.boardSize.totalSquares + 1;
    final columns = 10;
    
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
        ),
        itemCount: totalSquares,
        itemBuilder: (context, index) {
          final square = _gameState.board[index];
          final hasPlayer1 = _gameState.player1Position == index;
          final hasPlayer2 = _gameState.player2Position == index;
          
          return _buildSquare(square, hasPlayer1, hasPlayer2);
        },
      ),
    );
  }

  Widget _buildSquare(GooseSquare square, bool hasPlayer1, bool hasPlayer2) {
    return Container(
      decoration: BoxDecoration(
        color: _getSquareColor(square.type),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Square number
          Text(
            '${square.position}',
            style: TextStyle(
              fontSize: 8,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
          
          // Square icon
          if (square.type != GooseSquareType.normal)
            Text(
              _getSquareEmoji(square.type),
              style: const TextStyle(fontSize: 12),
            ),
          
          // Players
          if (hasPlayer1 || hasPlayer2)
            Positioned(
              bottom: 2,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasPlayer1)
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.burgundy,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                    ),
                  if (hasPlayer1 && hasPlayer2)
                    const SizedBox(width: 2),
                  if (hasPlayer2)
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color _getSquareColor(GooseSquareType type) {
    switch (type) {
      case GooseSquareType.normal:
        return AppColors.navy.withOpacity(0.3);
      case GooseSquareType.goose:
        return Colors.green.withOpacity(0.5);
      case GooseSquareType.bridge:
        return Colors.brown.withOpacity(0.5);
      case GooseSquareType.well:
        return Colors.blue.withOpacity(0.5);
      case GooseSquareType.labyrinth:
        return Colors.purple.withOpacity(0.5);
      case GooseSquareType.inn:
        return Colors.orange.withOpacity(0.5);
      case GooseSquareType.challenge:
        return AppColors.spicy.withOpacity(0.5);
      case GooseSquareType.truth:
        return AppColors.soft.withOpacity(0.5);
      case GooseSquareType.bonus:
        return AppColors.gold.withOpacity(0.5);
      case GooseSquareType.couple:
        return AppColors.burgundy.withOpacity(0.5);
      case GooseSquareType.finish:
        return Colors.yellow.withOpacity(0.7);
    }
  }

  String _getSquareEmoji(GooseSquareType type) {
    switch (type) {
      case GooseSquareType.goose:
        return '🪿';
      case GooseSquareType.bridge:
        return '🌉';
      case GooseSquareType.well:
        return '🕳️';
      case GooseSquareType.labyrinth:
        return '🌀';
      case GooseSquareType.inn:
        return '🏨';
      case GooseSquareType.challenge:
        return '🎯';
      case GooseSquareType.truth:
        return '💬';
      case GooseSquareType.bonus:
        return '🎁';
      case GooseSquareType.couple:
        return '💑';
      case GooseSquareType.finish:
        return '🏆';
      default:
        return '';
    }
  }

  Widget _buildControlPanel() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
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
            // Current player indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildPlayerIndicator(1),
                const SizedBox(width: AppSpacing.xl),
                _buildPlayerIndicator(2),
              ],
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Dice and roll button
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Last roll display
                if (_gameState.lastDiceRoll != null)
                  AnimatedBuilder(
                    animation: _diceController,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _isRolling ? _diceController.value * 2 * pi : 0,
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 5,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              _isRolling ? '?' : '${_gameState.lastDiceRoll}',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: AppColors.navy,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                
                const SizedBox(width: AppSpacing.lg),
                
                // Roll button
                ElevatedButton(
                  onPressed: _isRolling ? null : _rollDice,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.md,
                    ),
                    backgroundColor: AppColors.burgundy,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    _isRolling 
                        ? '...' 
                        : 'games.roll_dice'.tr(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerIndicator(int player) {
    final isCurrentPlayer = _gameState.currentPlayer == player;
    final position = player == 1 
        ? _gameState.player1Position 
        : _gameState.player2Position;
    final isInWell = player == 1 
        ? _gameState.player1InWell 
        : _gameState.player2InWell;
    final color = player == 1 ? AppColors.burgundy : AppColors.gold;
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: isCurrentPlayer ? color.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: isCurrentPlayer 
                ? Border.all(color: color, width: 2)
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Giocatore $player',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    isInWell ? '🕳️ Nel pozzo' : 'Casella $position',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (isCurrentPlayer)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'games.your_turn'.tr(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCardOverlay() {
    return GestureDetector(
      onTap: _onCardDismissed,
      child: Container(
        color: Colors.black.withOpacity(0.7),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(AppSpacing.xl),
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _currentCard!.isChallenge ? '🎯 Sfida!' : '💬 Verità',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  _currentCard!.localizedText,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                ElevatedButton(
                  onPressed: _onCardDismissed,
                  child: Text('common.done'.tr()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVictoryOverlay() {
    final winner = _gameState.currentPlayer;
    
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '🏆',
              style: const TextStyle(fontSize: 80),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'games.goose_game.victory'.tr(),
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: Colors.white,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              widget.config.playMode == GoosePlayMode.cooperative
                  ? 'Avete completato il gioco insieme!'
                  : 'Giocatore $winner vince!',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _initializeGame();
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                  ),
                  child: const Text('Gioca ancora'),
                ),
                const SizedBox(width: AppSpacing.md),
                ElevatedButton(
                  onPressed: () => context.pop(),
                  child: const Text('Fine'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showRules() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Regole del Gioco',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildRuleItem('🎲', 'Tira il dado e muovi la tua pedina'),
              _buildRuleItem('🪿', 'Oca: tira di nuovo!'),
              _buildRuleItem('🌉', 'Ponte: avanza alla casella 12'),
              _buildRuleItem('🕳️', 'Pozzo: bloccato finché non tiri 5 o 6'),
              _buildRuleItem('🏨', 'Locanda: salta un turno'),
              _buildRuleItem('🌀', 'Labirinto: torna indietro'),
              _buildRuleItem('🎯', 'Sfida: completa una sfida divertente'),
              _buildRuleItem('💬', 'Verità: rispondi a una domanda'),
              _buildRuleItem('🎁', 'Bonus: scegli una ricompensa'),
              _buildRuleItem('💑', 'Coppia: fate qualcosa insieme'),
              _buildRuleItem('🏆', 'Arrivo: devi entrare con il numero esatto!'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRuleItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
