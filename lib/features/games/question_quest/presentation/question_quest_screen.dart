import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../../../data/models/user_data.dart';
import '../../../../data/services/firebase_user_service.dart';
import '../../../../data/providers/user_data_provider.dart';

class QuestionQuestScreen extends ConsumerStatefulWidget {
  const QuestionQuestScreen({super.key});

  @override
  ConsumerState<QuestionQuestScreen> createState() => _QuestionQuestScreenState();
}

class _QuestionQuestScreenState extends ConsumerState<QuestionQuestScreen> {
  bool _gameStarted = false;
  bool _isLoading = false;
  int _currentLevel = 1;
  int _currentQuestionIndex = 0;
  List<String> _answeredQuestions = [];
  
  final Map<int, List<String>> _questions = {
    1: [ // Getting to Know
      'Qual è il tuo primo ricordo d\'infanzia?',
      'Se potessi cenare con una persona famosa, chi sceglieresti?',
      'Qual è la cosa che ti rende più felice nella vita?',
      'Qual è il tuo più grande sogno?',
      'Cosa faresti se vincessi alla lotteria?',
      'Qual è la tua paura più grande?',
      'Descrivi il tuo giorno perfetto',
      'Qual è il miglior consiglio che hai ricevuto?',
    ],
    2: [ // Dreams & Goals
      'Dove ti vedi tra 10 anni?',
      'Qual è un obiettivo che vorresti raggiungere insieme?',
      'Se potessi vivere ovunque, dove andresti?',
      'Qual è qualcosa che hai sempre voluto imparare?',
      'Come immagini la nostra vita tra 5 anni?',
      'Qual è il tuo più grande rimpianto?',
      'Cosa vorresti che la gente ricordasse di te?',
      'Qual è la tua definizione di successo?',
    ],
    3: [ // Relationship Deep Dive
      'Qual è il tuo ricordo preferito di noi?',
      'Cosa ti ha fatto innamorare di me?',
      'Qual è la cosa che ammiri di più della nostra relazione?',
      'C\'è qualcosa che vorresti migliorare tra noi?',
      'Qual è stato il momento più difficile insieme?',
      'Cosa ti fa sentire più amato/a da me?',
      'Qual è la nostra forza come coppia?',
      'Come posso supportarti meglio?',
    ],
    4: [ // Vulnerability
      'Qual è la tua insicurezza più grande?',
      'C\'è qualcosa di te che non ti ho mai detto?',
      'Qual è il tuo bisogno emotivo più importante?',
      'Quando ti senti più vulnerabile?',
      'Cosa ti spaventa del futuro insieme?',
      'C\'è qualcosa per cui vorresti essere perdonato/a?',
      'Qual è la cosa più difficile che hai dovuto superare?',
      'Quando hai capito che potevi fidarti di me?',
    ],
    5: [ // Intimacy & Connection
      'Come ti senti più connesso/a a me?',
      'Qual è la tua lingua dell\'amore?',
      'Cosa significa intimità per te?',
      'Come posso farti sentire più desiderato/a?',
      'Qual è il tuo modo preferito di ricevere affetto?',
      'C\'è qualcosa che vorresti provare insieme?',
      'Quando ti senti più vicino/a a me?',
      'Qual è il tuo ricordo più intimo di noi?',
    ],
  };

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    setState(() => _isLoading = true);
    
    try {
      final data = await FirebaseUserService().getQuestionQuest();
      setState(() {
        _currentLevel = data.currentLevel;
        _answeredQuestions = List.from(data.answeredQuestions);
      });
    } catch (e) {
      debugPrint('Error loading progress: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProgress() async {
    try {
      await FirebaseUserService().saveQuestionQuest(QuestionQuestData(
        currentLevel: _currentLevel,
        answeredQuestions: _answeredQuestions,
      ));
    } catch (e) {
      debugPrint('Error saving progress: $e');
    }
  }

  void _startGame() {
    setState(() {
      _gameStarted = true;
      _currentQuestionIndex = 0;
    });
    
    ref.read(progressNotifierProvider.notifier).incrementGamesPlayed();
  }

  void _answerQuestion() async {
    final questionKey = 'L${_currentLevel}_Q$_currentQuestionIndex';
    
    if (!_answeredQuestions.contains(questionKey)) {
      _answeredQuestions.add(questionKey);
    }
    
    final levelQuestions = _questions[_currentLevel]!;
    
    if (_currentQuestionIndex < levelQuestions.length - 1) {
      setState(() => _currentQuestionIndex++);
    } else {
      // Level complete
      if (_currentLevel < 5) {
        setState(() {
          _currentLevel++;
          _currentQuestionIndex = 0;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 Livello ${_currentLevel - 1} completato! Benvenuti al livello $_currentLevel'),
            backgroundColor: AppColors.burgundy,
          ),
        );
      } else {
        // All levels complete
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🏆 Congratulazioni! Avete completato tutti i livelli!'),
            backgroundColor: AppColors.gold,
          ),
        );
      }
    }
    
    await _saveProgress();
  }

  int _getLevelProgress(int level) {
    return _answeredQuestions.where((q) => q.startsWith('L${level}_')).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Question Quest',
          style: TextStyle(fontFamily: 'PlayfairDisplay', fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _gameStarted ? _buildGameView() : _buildSetupView(),
    );
  }

  Widget _buildSetupView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text('❓', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            'Question Quest',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Un viaggio di scoperta attraverso 5 livelli di intimità',
            style: TextStyle(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          
          // Level progress
          ...List.generate(5, (index) {
            final level = index + 1;
            final progress = _getLevelProgress(level);
            final total = _questions[level]!.length;
            final isUnlocked = level <= _currentLevel;
            final isComplete = progress >= total;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isUnlocked ? AppColors.surface : AppColors.surface.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: level == _currentLevel ? Border.all(color: AppColors.burgundy) : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isComplete 
                          ? AppColors.gold 
                          : isUnlocked 
                              ? AppColors.burgundy.withOpacity(0.2) 
                              : Colors.grey.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: isComplete
                          ? const Icon(Icons.check, color: Colors.white)
                          : Text(
                              '$level',
                              style: TextStyle(
                                color: isUnlocked ? AppColors.burgundy : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getLevelName(level),
                          style: TextStyle(
                            color: isUnlocked ? AppColors.textPrimary : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: progress / total,
                          backgroundColor: Colors.grey.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation(
                            isComplete ? AppColors.gold : AppColors.burgundy,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$progress/$total completate',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isUnlocked)
                    const Icon(Icons.lock, color: Colors.grey),
                ],
              ),
            );
          }),
          
          const SizedBox(height: 24),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _startGame,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.burgundy,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                _answeredQuestions.isEmpty ? 'Inizia il viaggio' : 'Continua il viaggio',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getLevelName(int level) {
    switch (level) {
      case 1: return 'Conoscersi';
      case 2: return 'Sogni e Obiettivi';
      case 3: return 'La Relazione';
      case 4: return 'Vulnerabilità';
      case 5: return 'Intimità Profonda';
      default: return 'Livello $level';
    }
  }

  Widget _buildGameView() {
    final levelQuestions = _questions[_currentLevel]!;
    final currentQuestion = levelQuestions[_currentQuestionIndex];
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Level indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.burgundy.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Livello $_currentLevel: ${_getLevelName(_currentLevel)}',
              style: TextStyle(
                color: AppColors.burgundy,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Domanda ${_currentQuestionIndex + 1}/${levelQuestions.length}',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          
          const Spacer(),
          
          // Question card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.burgundy.withOpacity(0.2),
                  AppColors.romantic.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.burgundy.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                const Text('💭', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 24),
                Text(
                  currentQuestion,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          const Spacer(),
          
          // Instructions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Text('💡', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Rispondete a turno, ascoltandovi con attenzione. Non c\'è fretta.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _gameStarted = false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Pausa'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _answerQuestion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.burgundy,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Abbiamo risposto ✓'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
