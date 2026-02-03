import 'package:flutter/material.dart';

class QuestionQuestScreen extends StatefulWidget {
  const QuestionQuestScreen({super.key});

  @override
  State<QuestionQuestScreen> createState() => _QuestionQuestScreenState();
}

class _QuestionQuestScreenState extends State<QuestionQuestScreen>
    with SingleTickerProviderStateMixin {
  bool _gameStarted = false;
  int _currentQuestionIndex = 0;
  String _selectedCategory = 'all';
  String _selectedDepth = 'medium';
  bool _showingQuestion = false;
  
  late AnimationController _cardController;
  late Animation<double> _cardAnimation;

  final List<Map<String, String>> _categories = [
    {'id': 'all', 'name': 'Tutte', 'emoji': '🎯'},
    {'id': 'dreams', 'name': 'Sogni', 'emoji': '✨'},
    {'id': 'memories', 'name': 'Ricordi', 'emoji': '📸'},
    {'id': 'desires', 'name': 'Desideri', 'emoji': '💫'},
    {'id': 'fears', 'name': 'Paure', 'emoji': '🌙'},
    {'id': 'future', 'name': 'Futuro', 'emoji': '🔮'},
    {'id': 'intimacy', 'name': 'Intimità', 'emoji': '💕'},
  ];

  final List<Map<String, String>> _depths = [
    {'id': 'light', 'name': 'Leggero', 'emoji': '☀️', 'desc': 'Domande semplici per rompere il ghiaccio'},
    {'id': 'medium', 'name': 'Profondo', 'emoji': '🌊', 'desc': 'Domande che richiedono riflessione'},
    {'id': 'deep', 'name': 'Abisso', 'emoji': '🌌', 'desc': 'Domande che toccano l\'anima'},
  ];

  // Mock questions by category and depth
  final Map<String, Map<String, List<String>>> _questions = {
    'light': {
      'dreams': [
        'Qual è il sogno più strano che ricordi?',
        'Se potessi sognare qualsiasi cosa stanotte, cosa sceglieresti?',
        'Hai mai fatto un sogno ricorrente?',
      ],
      'memories': [
        'Qual è il tuo primo ricordo d\'infanzia?',
        'Qual è stato il momento più divertente della tua vita?',
        'Racconta il tuo ricordo preferito di noi due.',
      ],
      'desires': [
        'Qual è un piccolo piacere che ti rende felice?',
        'Cosa vorresti fare questo weekend?',
        'Qual è il tuo comfort food preferito?',
      ],
      'fears': [
        'Qual è la cosa più buffa di cui hai paura?',
        'Hai paura del buio?',
        'Qual è l\'ultima cosa che ti ha spaventato in un film?',
      ],
      'future': [
        'Dove ti vedi tra 5 anni?',
        'Qual è il prossimo viaggio che vorresti fare?',
        'Cosa vorresti imparare a fare?',
      ],
      'intimacy': [
        'Qual è il tuo modo preferito di ricevere affetto?',
        'Ti piacciono di più le coccole mattutine o serali?',
        'Qual è il complimento più bello che ti ho fatto?',
      ],
    },
    'medium': {
      'dreams': [
        'Se potessi realizzare un sogno impossibile, quale sarebbe?',
        'Qual è un sogno che hai abbandonato e perché?',
        'Cosa significa per te "avere successo"?',
      ],
      'memories': [
        'Qual è il momento in cui ti sei sentito più orgoglioso di te stesso?',
        'Racconta un momento difficile che ti ha reso più forte.',
        'Qual è il ricordo più prezioso della tua famiglia?',
      ],
      'desires': [
        'Cosa desideri di più in questo momento della tua vita?',
        'C\'è qualcosa che non hai mai osato chiedermi?',
        'Qual è il tuo desiderio segreto?',
      ],
      'fears': [
        'Qual è la tua paura più grande riguardo al futuro?',
        'C\'è qualcosa che eviti di fare per paura?',
        'Qual è stata l\'ultima volta che hai affrontato una paura?',
      ],
      'future': [
        'Come immagini la nostra vita tra 10 anni?',
        'Qual è un obiettivo che vuoi assolutamente raggiungere?',
        'Se potessi cambiare una cosa del tuo futuro, cosa sarebbe?',
      ],
      'intimacy': [
        'Cosa ti fa sentire più amato/a?',
        'Qual è il momento in cui ti sei sentito più connesso a me?',
        'C\'è qualcosa che vorresti migliorare nella nostra intimità?',
      ],
    },
    'deep': {
      'dreams': [
        'Se oggi fosse l\'ultimo giorno, di cosa ti pentiresti?',
        'Qual è il sogno che non hai mai detto a nessuno?',
        'Cosa sacrificheresti per realizzare il tuo sogno più grande?',
      ],
      'memories': [
        'Qual è il momento che ti ha cambiato la vita per sempre?',
        'C\'è un ricordo doloroso che ancora ti accompagna?',
        'Qual è la lezione più importante che la vita ti ha insegnato?',
      ],
      'desires': [
        'Qual è il desiderio più profondo del tuo cuore?',
        'Cosa desideri veramente dalla nostra relazione?',
        'Se potessi avere una risposta a qualsiasi domanda, quale faresti?',
      ],
      'fears': [
        'Qual è la paura che ti tiene sveglio la notte?',
        'Di cosa hai paura nella nostra relazione?',
        'Qual è la verità che hai paura di affrontare?',
      ],
      'future': [
        'Cosa vuoi che si ricordi di te quando non ci sarai più?',
        'Qual è il tuo scopo nella vita?',
        'Come vuoi invecchiare insieme?',
      ],
      'intimacy': [
        'Qual è la cosa più vulnerabile che puoi condividere con me?',
        'Cosa significa per te l\'amore vero?',
        'Qual è il momento in cui ti sei sentito completamente al sicuro con me?',
      ],
    },
  };

  List<String> _currentQuestions = [];
  int _player1Score = 0;
  int _player2Score = 0;
  int _currentPlayer = 1;

  @override
  void initState() {
    super.initState();
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _cardAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _cardController.dispose();
    super.dispose();
  }

  void _startGame() {
    _loadQuestions();
    setState(() {
      _gameStarted = true;
      _currentQuestionIndex = 0;
      _player1Score = 0;
      _player2Score = 0;
      _currentPlayer = 1;
    });
  }

  void _loadQuestions() {
    List<String> allQuestions = [];
    
    if (_selectedCategory == 'all') {
      for (var category in _questions[_selectedDepth]!.values) {
        allQuestions.addAll(category);
      }
    } else {
      allQuestions = List.from(_questions[_selectedDepth]![_selectedCategory] ?? []);
    }
    
    allQuestions.shuffle();
    _currentQuestions = allQuestions.take(10).toList();
  }

  void _revealQuestion() {
    setState(() {
      _showingQuestion = true;
    });
    _cardController.forward(from: 0);
  }

  void _answerQuestion(bool answered) {
    if (answered) {
      setState(() {
        if (_currentPlayer == 1) {
          _player1Score++;
        } else {
          _player2Score++;
        }
      });
    }
    
    _nextQuestion();
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _currentQuestions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _currentPlayer = _currentPlayer == 1 ? 2 : 1;
        _showingQuestion = false;
      });
    } else {
      _showResults();
    }
  }

  void _showResults() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '🎉 Viaggio Completato!',
          style: TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Avete esplorato l\'anima dell\'altro.',
              style: TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildScoreCard('Partner 1', _player1Score, const Color(0xFF8B5CF6)),
                _buildScoreCard('Partner 2', _player2Score, const Color(0xFFEC4899)),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Domande risposte: ${_player1Score + _player2Score}/${_currentQuestions.length}',
              style: const TextStyle(color: Colors.white54),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _gameStarted = false;
              });
            },
            child: const Text('Menu'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _startGame();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
            ),
            child: const Text('Gioca Ancora'),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard(String player, int score, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Text(
            player,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '$score',
            style: TextStyle(
              color: color,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Question Quest',
          style: TextStyle(
            fontFamily: 'PlayfairDisplay',
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _gameStarted ? _buildGameView() : _buildSetupView(),
    );
  }

  Widget _buildSetupView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                Icons.psychology,
                size: 50,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Esplora l\'anima del tuo partner',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Category Selection
          const Text(
            'Categoria',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories.map((category) {
              final isSelected = _selectedCategory == category['id'];
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = category['id']!),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? const Color(0xFF6366F1) 
                        : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected 
                          ? const Color(0xFF6366F1) 
                          : Colors.white.withOpacity(0.2),
                    ),
                  ),
                  child: Text(
                    '${category['emoji']} ${category['name']}',
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),

          // Depth Selection
          const Text(
            'Profondità',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(_depths.length, (index) {
            final depth = _depths[index];
            final isSelected = _selectedDepth == depth['id'];
            return GestureDetector(
              onTap: () => setState(() => _selectedDepth = depth['id']!),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? const Color(0xFF6366F1).withOpacity(0.2) 
                      : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected 
                        ? const Color(0xFF6366F1) 
                        : Colors.white.withOpacity(0.1),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      depth['emoji']!,
                      style: const TextStyle(fontSize: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            depth['name']!,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            depth['desc']!,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      const Icon(Icons.check_circle, color: Color(0xFF6366F1)),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 32),

          // Start Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _startGame,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Inizia il Viaggio',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameView() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Domanda ${_currentQuestionIndex + 1}/${_currentQuestions.length}',
                style: const TextStyle(color: Colors.white70),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _currentPlayer == 1 
                      ? const Color(0xFF8B5CF6).withOpacity(0.3)
                      : const Color(0xFFEC4899).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Partner $_currentPlayer risponde',
                  style: TextStyle(
                    color: _currentPlayer == 1 
                        ? const Color(0xFF8B5CF6)
                        : const Color(0xFFEC4899),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (_currentQuestionIndex + 1) / _currentQuestions.length,
            backgroundColor: Colors.white.withOpacity(0.1),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
          ),
          
          // Scores
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildMiniScore('P1', _player1Score, const Color(0xFF8B5CF6)),
              const SizedBox(width: 24),
              _buildMiniScore('P2', _player2Score, const Color(0xFFEC4899)),
            ],
          ),
          
          const Spacer(),
          
          // Question Card
          if (!_showingQuestion)
            GestureDetector(
              onTap: _revealQuestion,
              child: Container(
                width: double.infinity,
                height: 300,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.touch_app,
                      size: 60,
                      color: Colors.white70,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Tocca per rivelare',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'la domanda',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            AnimatedBuilder(
              animation: _cardAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _cardAnimation.value,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A2E),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF6366F1).withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.format_quote,
                          size: 40,
                          color: Color(0xFF6366F1),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _currentQuestions[_currentQuestionIndex],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          
          const Spacer(),
          
          // Action Buttons
          if (_showingQuestion)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _answerQuestion(false),
                    icon: const Icon(Icons.skip_next),
                    label: const Text('Salta'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: BorderSide(color: Colors.white.withOpacity(0.3)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () => _answerQuestion(true),
                    icon: const Icon(Icons.check),
                    label: const Text('Ho Risposto'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildMiniScore(String label, int score, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$score',
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
