import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

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

  List<Map<String, String>> get _categories => [
    {'id': 'all', 'name': 'games.question_quest.cat_all'.tr(), 'emoji': '🎯'},
    {'id': 'dreams', 'name': 'games.question_quest.cat_dreams'.tr(), 'emoji': '✨'},
    {'id': 'memories', 'name': 'games.question_quest.cat_memories'.tr(), 'emoji': '📸'},
    {'id': 'desires', 'name': 'games.question_quest.cat_desires'.tr(), 'emoji': '💫'},
    {'id': 'fears', 'name': 'games.question_quest.cat_fears'.tr(), 'emoji': '🌙'},
    {'id': 'future', 'name': 'games.question_quest.cat_future'.tr(), 'emoji': '🔮'},
    {'id': 'intimacy', 'name': 'games.question_quest.cat_intimacy'.tr(), 'emoji': '💕'},
  ];

  List<Map<String, String>> get _depths => [
    {'id': 'light', 'name': 'games.question_quest.depth_light'.tr(), 'emoji': '☀️', 'desc': 'games.question_quest.depth_light_desc'.tr()},
    {'id': 'medium', 'name': 'games.question_quest.depth_medium'.tr(), 'emoji': '🌊', 'desc': 'games.question_quest.depth_medium_desc'.tr()},
    {'id': 'deep', 'name': 'games.question_quest.depth_deep'.tr(), 'emoji': '🌌', 'desc': 'games.question_quest.depth_deep_desc'.tr()},
  ];

  // Questions by depth and category
  Map<String, Map<String, List<String>>> get _questions => {
    'light': {
      'dreams': [
        'games.question_quest.q_light_dreams_1'.tr(),
        'games.question_quest.q_light_dreams_2'.tr(),
        'games.question_quest.q_light_dreams_3'.tr(),
      ],
      'memories': [
        'games.question_quest.q_light_memories_1'.tr(),
        'games.question_quest.q_light_memories_2'.tr(),
        'games.question_quest.q_light_memories_3'.tr(),
      ],
      'desires': [
        'games.question_quest.q_light_desires_1'.tr(),
        'games.question_quest.q_light_desires_2'.tr(),
        'games.question_quest.q_light_desires_3'.tr(),
      ],
      'fears': [
        'games.question_quest.q_light_fears_1'.tr(),
        'games.question_quest.q_light_fears_2'.tr(),
        'games.question_quest.q_light_fears_3'.tr(),
      ],
      'future': [
        'games.question_quest.q_light_future_1'.tr(),
        'games.question_quest.q_light_future_2'.tr(),
        'games.question_quest.q_light_future_3'.tr(),
      ],
      'intimacy': [
        'games.question_quest.q_light_intimacy_1'.tr(),
        'games.question_quest.q_light_intimacy_2'.tr(),
        'games.question_quest.q_light_intimacy_3'.tr(),
      ],
    },
    'medium': {
      'dreams': [
        'games.question_quest.q_medium_dreams_1'.tr(),
        'games.question_quest.q_medium_dreams_2'.tr(),
        'games.question_quest.q_medium_dreams_3'.tr(),
      ],
      'memories': [
        'games.question_quest.q_medium_memories_1'.tr(),
        'games.question_quest.q_medium_memories_2'.tr(),
        'games.question_quest.q_medium_memories_3'.tr(),
      ],
      'desires': [
        'games.question_quest.q_medium_desires_1'.tr(),
        'games.question_quest.q_medium_desires_2'.tr(),
        'games.question_quest.q_medium_desires_3'.tr(),
      ],
      'fears': [
        'games.question_quest.q_medium_fears_1'.tr(),
        'games.question_quest.q_medium_fears_2'.tr(),
        'games.question_quest.q_medium_fears_3'.tr(),
      ],
      'future': [
        'games.question_quest.q_medium_future_1'.tr(),
        'games.question_quest.q_medium_future_2'.tr(),
        'games.question_quest.q_medium_future_3'.tr(),
      ],
      'intimacy': [
        'games.question_quest.q_medium_intimacy_1'.tr(),
        'games.question_quest.q_medium_intimacy_2'.tr(),
        'games.question_quest.q_medium_intimacy_3'.tr(),
      ],
    },
    'deep': {
      'dreams': [
        'games.question_quest.q_deep_dreams_1'.tr(),
        'games.question_quest.q_deep_dreams_2'.tr(),
        'games.question_quest.q_deep_dreams_3'.tr(),
      ],
      'memories': [
        'games.question_quest.q_deep_memories_1'.tr(),
        'games.question_quest.q_deep_memories_2'.tr(),
        'games.question_quest.q_deep_memories_3'.tr(),
      ],
      'desires': [
        'games.question_quest.q_deep_desires_1'.tr(),
        'games.question_quest.q_deep_desires_2'.tr(),
        'games.question_quest.q_deep_desires_3'.tr(),
      ],
      'fears': [
        'games.question_quest.q_deep_fears_1'.tr(),
        'games.question_quest.q_deep_fears_2'.tr(),
        'games.question_quest.q_deep_fears_3'.tr(),
      ],
      'future': [
        'games.question_quest.q_deep_future_1'.tr(),
        'games.question_quest.q_deep_future_2'.tr(),
        'games.question_quest.q_deep_future_3'.tr(),
      ],
      'intimacy': [
        'games.question_quest.q_deep_intimacy_1'.tr(),
        'games.question_quest.q_deep_intimacy_2'.tr(),
        'games.question_quest.q_deep_intimacy_3'.tr(),
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
        title: Text(
          'games.question_quest.journey_complete'.tr(),
          style: const TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'games.question_quest.explored_soul'.tr(),
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildScoreCard('games.question_quest.partner1'.tr(), _player1Score, const Color(0xFF8B5CF6)),
                _buildScoreCard('games.question_quest.partner2'.tr(), _player2Score, const Color(0xFFEC4899)),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'games.question_quest.questions_answered'.tr(args: [(_player1Score + _player2Score).toString(), _currentQuestions.length.toString()]),
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
            child: Text('games.question_quest.menu'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _startGame();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
            ),
            child: Text('games.question_quest.play_again'.tr()),
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
        title: Text(
          'games.question_quest.title'.tr(),
          style: const TextStyle(
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
          Center(
            child: Text(
              'games.question_quest.subtitle'.tr(),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Category Selection
          Text(
            'games.question_quest.category_label'.tr(),
            style: const TextStyle(
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
          Text(
            'games.question_quest.depth_label'.tr(),
            style: const TextStyle(
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
              child: Text(
                'games.question_quest.start_journey'.tr(),
                style: const TextStyle(
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
                'games.question_quest.question_of'.tr(args: [(_currentQuestionIndex + 1).toString(), _currentQuestions.length.toString()]),
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
                  'games.question_quest.partner_answers'.tr(args: [_currentPlayer.toString()]),
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.touch_app,
                      size: 60,
                      color: Colors.white70,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'games.question_quest.tap_to_reveal'.tr(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'games.question_quest.the_question'.tr(),
                      style: const TextStyle(
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
                    label: Text('games.question_quest.skip'.tr()),
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
                    label: Text('games.question_quest.answered'.tr()),
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
