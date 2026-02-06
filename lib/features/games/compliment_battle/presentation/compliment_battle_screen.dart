import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../../../data/models/user_data.dart';
import '../../../../data/services/firebase_user_service.dart';
import '../../../../data/providers/user_data_provider.dart';

class ComplimentBattleScreen extends ConsumerStatefulWidget {
  const ComplimentBattleScreen({super.key});

  @override
  ConsumerState<ComplimentBattleScreen> createState() => _ComplimentBattleScreenState();
}

class _ComplimentBattleScreenState extends ConsumerState<ComplimentBattleScreen> {
  bool _gameStarted = false;
  int _currentRound = 1;
  int _totalRounds = 5;
  int _currentPlayer = 1;
  String _currentCategory = '';
  int _player1Score = 0;
  int _player2Score = 0;
  
  ComplimentBattleData _stats = const ComplimentBattleData();
  
  final List<Map<String, dynamic>> _categories = [
    {'id': 'appearance', 'name': 'Aspetto', 'emoji': '✨', 'hint': 'Complimenta qualcosa del suo aspetto fisico'},
    {'id': 'personality', 'name': 'Personalità', 'emoji': '💫', 'hint': 'Complimenta un tratto del suo carattere'},
    {'id': 'skills', 'name': 'Talenti', 'emoji': '🌟', 'hint': 'Complimenta qualcosa che sa fare bene'},
    {'id': 'relationship', 'name': 'Come Partner', 'emoji': '💕', 'hint': 'Complimenta come ti fa sentire'},
    {'id': 'unique', 'name': 'Unicità', 'emoji': '🦋', 'hint': 'Complimenta qualcosa che solo lui/lei ha'},
    {'id': 'growth', 'name': 'Crescita', 'emoji': '🌱', 'hint': 'Complimenta come è migliorato/a'},
    {'id': 'support', 'name': 'Supporto', 'emoji': '🤝', 'hint': 'Complimenta come ti supporta'},
    {'id': 'humor', 'name': 'Umorismo', 'emoji': '😄', 'hint': 'Complimenta qualcosa che ti fa ridere'},
  ];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final data = await FirebaseUserService().getComplimentBattle();
    setState(() => _stats = data);
  }

  void _startGame() {
    _pickCategory();
    setState(() {
      _gameStarted = true;
      _currentRound = 1;
      _currentPlayer = 1;
      _player1Score = 0;
      _player2Score = 0;
    });
    
    ref.read(progressNotifierProvider.notifier).incrementGamesPlayed();
  }

  void _pickCategory() {
    final random = Random();
    final category = _categories[random.nextInt(_categories.length)];
    setState(() {
      _currentCategory = category['id'] as String;
    });
  }

  void _rateCompliment(int rating) async {
    setState(() {
      if (_currentPlayer == 1) {
        _player2Score += rating; // Player 1's compliment scored by player 2
        _currentPlayer = 2;
      } else {
        _player1Score += rating; // Player 2's compliment scored by player 1
        
        if (_currentRound < _totalRounds) {
          _currentRound++;
          _currentPlayer = 1;
          _pickCategory();
        } else {
          _endGame();
        }
      }
    });
  }

  void _endGame() async {
    
    try {
      final newStats = ComplimentBattleData(
        player1Score: _stats.player1Score + _player1Score,
        player2Score: _stats.player2Score + _player2Score,
        sessions: [
          ..._stats.sessions,
          {
            'player1Score': _player1Score,
            'player2Score': _player2Score,
            'date': DateTime.now().toIso8601String(),
          }
        ],
      );
      
      await FirebaseUserService().saveComplimentBattle(newStats);
      setState(() => _stats = newStats);
      
      _showResults();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore: $e')),
      );
    } finally {
    }
  }

  void _showResults() {
    final winner = _player1Score > _player2Score 
        ? 'Giocatore 1' 
        : _player2Score > _player1Score 
            ? 'Giocatore 2' 
            : 'Pareggio!';
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '🏆 Risultati',
          style: TextStyle(color: AppColors.textPrimary),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text('Giocatore 1', style: TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    Text(
                      '$_player1Score',
                      style: const TextStyle(
                        color: AppColors.burgundy,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Text('VS', style: TextStyle(color: AppColors.textSecondary)),
                Column(
                  children: [
                    const Text('Giocatore 2', style: TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    Text(
                      '$_player2Score',
                      style: const TextStyle(
                        color: AppColors.spicy,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              winner == 'Pareggio!' ? '🤝 Pareggio perfetto!' : '👑 Vince $winner!',
              style: const TextStyle(
                color: AppColors.gold,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Punteggio totale storico:\nP1: ${_stats.player1Score} • P2: ${_stats.player2Score}',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _gameStarted = false);
            },
            child: const Text('Chiudi'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startGame();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.burgundy),
            child: const Text('Rivincita!'),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> get _currentCategoryData =>
      _categories.firstWhere((c) => c['id'] == _currentCategory, orElse: () => _categories[0]);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Compliment Battle',
          style: TextStyle(fontFamily: 'PlayfairDisplay', fontWeight: FontWeight.bold),
        ),
      ),
      body: _gameStarted ? _buildGameView() : _buildSetupView(),
    );
  }

  Widget _buildSetupView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text('🎤', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            'Compliment Battle',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Chi fa i complimenti migliori?',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          
          // Historical stats
          if (_stats.player1Score > 0 || _stats.player2Score > 0) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text('Punteggio Storico', style: TextStyle(
                    color: AppColors.gold,
                    fontWeight: FontWeight.bold,
                  )),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('P1', style: TextStyle(color: AppColors.textSecondary)),
                          Text('${_stats.player1Score}', style: const TextStyle(
                            color: AppColors.burgundy,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          )),
                        ],
                      ),
                      const Text('vs', style: TextStyle(color: AppColors.textSecondary)),
                      Column(
                        children: [
                          const Text('P2', style: TextStyle(color: AppColors.textSecondary)),
                          Text('${_stats.player2Score}', style: const TextStyle(
                            color: AppColors.spicy,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          )),
                        ],
                      ),
                    ],
                  ),
                  Text('${_stats.sessions.length} partite giocate', style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  )),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 32),
          
          // Rules
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Come si gioca:', style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                )),
                const SizedBox(height: 12),
                _buildRuleItem('1', 'Una categoria viene estratta a caso'),
                _buildRuleItem('2', 'A turno, fate un complimento su quella categoria'),
                _buildRuleItem('3', 'L\'altro giocatore valuta da 1 a 5 stelle'),
                _buildRuleItem('4', 'Chi ha più punti alla fine vince!'),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Rounds selector
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Numero di round:', style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                )),
                const SizedBox(height: 12),
                Row(
                  children: [3, 5, 7, 10].map((n) {
                    final isSelected = _totalRounds == n;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _totalRounds = n),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.burgundy : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? AppColors.burgundy : AppColors.textSecondary.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            '$n',
                            style: TextStyle(
                              color: isSelected ? Colors.white : AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _startGame,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.burgundy,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Inizia la battaglia! 🎤', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleItem(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.burgundy.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(number, style: const TextStyle(
                color: AppColors.burgundy,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              )),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: const TextStyle(color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }

  Widget _buildGameView() {
    final categoryData = _currentCategoryData;
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Score board
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildScoreCard('P1', _player1Score, _currentPlayer == 1, AppColors.burgundy),
              Text(
                'Round $_currentRound/$_totalRounds',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              _buildScoreCard('P2', _player2Score, _currentPlayer == 2, AppColors.spicy),
            ],
          ),
          
          const Spacer(),
          
          // Category card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.burgundy.withOpacity(0.2),
                  AppColors.romantic.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.burgundy.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Text(categoryData['emoji'] as String, style: const TextStyle(fontSize: 64)),
                const SizedBox(height: 16),
                Text(
                  categoryData['name'] as String,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  categoryData['hint'] as String,
                  style: const TextStyle(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Current player indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: _currentPlayer == 1 ? AppColors.burgundy : AppColors.spicy,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Giocatore $_currentPlayer: fai il tuo complimento!',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          
          const Spacer(),
          
          // Rating section
          Text(
            'Giocatore ${_currentPlayer == 1 ? 2 : 1}: valuta il complimento',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final rating = index + 1;
              return GestureDetector(
                onTap: () => _rateCompliment(rating),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '⭐' * rating,
                    style: const TextStyle(fontSize: 8),
                  ),
                ),
              );
            }),
          ),
          
          const SizedBox(height: 8),
          
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text('1', style: TextStyle(color: AppColors.textSecondary)),
              Text('2', style: TextStyle(color: AppColors.textSecondary)),
              Text('3', style: TextStyle(color: AppColors.textSecondary)),
              Text('4', style: TextStyle(color: AppColors.textSecondary)),
              Text('5', style: TextStyle(color: AppColors.textSecondary)),
            ],
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildScoreCard(String player, int score, bool isActive, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isActive ? color.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? color : Colors.transparent,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Text(player, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          Text(
            '$score',
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
