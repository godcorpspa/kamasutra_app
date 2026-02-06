import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../../../data/models/user_data.dart';
import '../../../../data/services/firebase_user_service.dart';
import '../../../../data/providers/user_data_provider.dart';

class TruthDareScreen extends ConsumerStatefulWidget {
  const TruthDareScreen({super.key});

  @override
  ConsumerState<TruthDareScreen> createState() => _TruthDareScreenState();
}

class _TruthDareScreenState extends ConsumerState<TruthDareScreen> {
  bool _gameStarted = false;
  bool _isLoading = false;
  int _currentPlayer = 1;
  String? _currentChallenge;
  String? _challengeType;
  String _intensity = 'soft';
  
  TruthDareData _stats = const TruthDareData();
  
  final Map<String, Map<String, List<String>>> _challenges = {
    'truth': {
      'soft': [
        'Qual è il tuo ricordo preferito insieme?',
        'Cosa ti ha fatto innamorare del partner?',
        'Qual è il complimento più bello che hai ricevuto?',
        'Cosa ammiri di più del tuo partner?',
        'Qual è il tuo sogno per il futuro insieme?',
        'Quando ti sei reso conto di essere innamorato/a?',
        'Qual è la cosa più romantica che hai fatto?',
        'Cosa ti fa sentire più amato/a?',
      ],
      'spicy': [
        'Qual è la tua fantasia segreta?',
        'Dove vorresti fare l\'amore che non avete mai provato?',
        'Qual è la cosa più sexy del tuo partner?',
        'Raccontami il tuo sogno più piccante',
        'Cosa ti eccita di più?',
        'Qual è stato il momento più passionale insieme?',
        'C\'è qualcosa che vorresti provare a letto?',
        'Qual è il tuo punto debole segreto?',
      ],
      'hot': [
        'Descrivi la tua fantasia più audace',
        'Cosa ti fa impazzire di desiderio?',
        'Racconta il tuo sogno erotico più intenso',
        'Qual è la cosa più trasgressiva che vorresti fare?',
        'Descrivi cosa vorresti che ti facesse ora',
        'Qual è il tuo desiderio più nascosto?',
        'Cosa non hai mai osato chiedere?',
        'Descrivi la serata perfetta senza limiti',
      ],
    },
    'dare': {
      'soft': [
        'Dai un bacio sulla fronte al partner',
        'Fai un complimento sincero',
        'Abbraccia il partner per 30 secondi',
        'Sussurra qualcosa di dolce all\'orecchio',
        'Accarezza i capelli del partner',
        'Bacia la mano del partner',
        'Scrivi un messaggio d\'amore',
        'Fai un massaggio alle spalle per 1 minuto',
      ],
      'spicy': [
        'Bacia il collo del partner per 10 secondi',
        'Togli un capo di abbigliamento',
        'Fai un massaggio sensuale',
        'Bacia il partner come nel vostro primo bacio',
        'Sussurra una fantasia all\'orecchio',
        'Accarezza il partner sotto la maglietta',
        'Fai un ballo sensuale insieme',
        'Bacia il partner ovunque tranne sulle labbra',
      ],
      'hot': [
        'Spogliati lentamente davanti al partner',
        'Bacia tutto il corpo del partner',
        'Fai un massaggio con olio',
        'Realizza una fantasia del partner',
        'Bendati e lasciati guidare',
        'Prendi tu il controllo per 5 minuti',
        'Esplora una zona nuova del partner',
        'Lasciati fare tutto quello che vuole',
      ],
    },
  };

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final data = await FirebaseUserService().getTruthDare();
    setState(() => _stats = data);
  }

  void _startGame() {
    setState(() {
      _gameStarted = true;
      _currentPlayer = 1;
      _currentChallenge = null;
      _challengeType = null;
    });
    
    ref.read(progressNotifierProvider.notifier).incrementGamesPlayed();
  }

  void _pickChallenge(String type) {
    final challenges = _challenges[type]![_intensity]!;
    final random = Random();
    
    setState(() {
      _challengeType = type;
      _currentChallenge = challenges[random.nextInt(challenges.length)];
    });
  }

  Future<void> _completeChallenge() async {
    setState(() => _isLoading = true);
    
    try {
      final newStats = TruthDareData(
        truthsAnswered: _stats.truthsAnswered + (_challengeType == 'truth' ? 1 : 0),
        daresCompleted: _stats.daresCompleted + (_challengeType == 'dare' ? 1 : 0),
      );
      
      await FirebaseUserService().saveTruthDare(newStats);
      
      setState(() {
        _stats = newStats;
        _currentChallenge = null;
        _challengeType = null;
        _currentPlayer = _currentPlayer == 1 ? 2 : 1;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _skipChallenge() {
    setState(() {
      _currentChallenge = null;
      _challengeType = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Verità o Sfida',
          style: TextStyle(fontFamily: 'PlayfairDisplay', fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_gameStarted)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  '${_stats.truthsAnswered + _stats.daresCompleted} completate',
                  style: TextStyle(color: AppColors.gold),
                ),
              ),
            ),
        ],
      ),
      body: _gameStarted ? _buildGameView() : _buildSetupView(),
    );
  }

  Widget _buildSetupView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text('🎭', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            'Verità o Sfida',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Il classico gioco per coppie coraggiose',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          
          // Stats
          if (_stats.truthsAnswered > 0 || _stats.daresCompleted > 0) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text('${_stats.truthsAnswered}', style: TextStyle(
                        color: AppColors.gold,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      )),
                      Text('Verità', style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                  Container(width: 1, height: 40, color: AppColors.textSecondary.withOpacity(0.3)),
                  Column(
                    children: [
                      Text('${_stats.daresCompleted}', style: TextStyle(
                        color: AppColors.spicy,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      )),
                      Text('Sfide', style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 32),
          
          // Intensity selection
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Intensità', style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                )),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildIntensityChip('soft', '🌸 Soft'),
                    const SizedBox(width: 8),
                    _buildIntensityChip('spicy', '🌶️ Spicy'),
                    const SizedBox(width: 8),
                    _buildIntensityChip('hot', '🔥 Hot'),
                  ],
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
              child: const Text('Inizia a giocare 🎭', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntensityChip(String value, String label) {
    final isSelected = _intensity == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _intensity = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.burgundy : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppColors.burgundy : AppColors.textSecondary.withOpacity(0.3),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textPrimary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildGameView() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Current player
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: _currentPlayer == 1 ? AppColors.burgundy : AppColors.spicy,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Turno del Giocatore $_currentPlayer',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          
          const Spacer(),
          
          if (_currentChallenge != null) ...[
            // Challenge card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _challengeType == 'truth'
                      ? [AppColors.gold.withOpacity(0.2), AppColors.gold.withOpacity(0.1)]
                      : [AppColors.spicy.withOpacity(0.2), AppColors.spicy.withOpacity(0.1)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _challengeType == 'truth' ? AppColors.gold : AppColors.spicy,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    _challengeType == 'truth' ? '🎯 VERITÀ' : '⚡ SFIDA',
                    style: TextStyle(
                      color: _challengeType == 'truth' ? AppColors.gold : AppColors.spicy,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _currentChallenge!,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _skipChallenge,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Salta'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _completeChallenge,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.burgundy,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('✓ Fatto!'),
                  ),
                ),
              ],
            ),
          ] else ...[
            // Choice buttons
            Text(
              'Scegli:',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 32),
            
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _pickChallenge('truth'),
                    child: Container(
                      height: 150,
                      decoration: BoxDecoration(
                        color: AppColors.gold.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.gold),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🎯', style: TextStyle(fontSize: 40)),
                          const SizedBox(height: 8),
                          Text(
                            'VERITÀ',
                            style: TextStyle(
                              color: AppColors.gold,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _pickChallenge('dare'),
                    child: Container(
                      height: 150,
                      decoration: BoxDecoration(
                        color: AppColors.spicy.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.spicy),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('⚡', style: TextStyle(fontSize: 40)),
                          const SizedBox(height: 8),
                          Text(
                            'SFIDA',
                            style: TextStyle(
                              color: AppColors.spicy,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          
          const Spacer(),
          
          TextButton(
            onPressed: () => setState(() => _gameStarted = false),
            child: const Text('Termina partita'),
          ),
        ],
      ),
    );
  }
}
