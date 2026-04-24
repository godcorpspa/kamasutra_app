import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../app/theme.dart';

class ComplimentBattleScreen extends StatefulWidget {
  const ComplimentBattleScreen({super.key});

  @override
  State<ComplimentBattleScreen> createState() => _ComplimentBattleScreenState();
}

class _ComplimentBattleScreenState extends State<ComplimentBattleScreen>
    with SingleTickerProviderStateMixin {
  bool _gameStarted = false;
  int _currentPlayer = 1;
  int _player1Score = 0;
  int _player2Score = 0;
  int _roundNumber = 1;
  int _totalRounds = 5;
  Timer? _timer;
  int _timeRemaining = 15;
  String _currentCategory = '';
  bool _isThinking = false;
  String _difficulty = 'normal';

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  List<Map<String, dynamic>> get _categories => [
    {'name': 'games.compliment_battle.cat_physical'.tr(), 'emoji': '👀', 'hint': 'games.compliment_battle.hint_physical'.tr()},
    {'name': 'games.compliment_battle.cat_personality'.tr(), 'emoji': '💫', 'hint': 'games.compliment_battle.hint_personality'.tr()},
    {'name': 'games.compliment_battle.cat_talents'.tr(), 'emoji': '🌟', 'hint': 'games.compliment_battle.hint_talents'.tr()},
    {'name': 'games.compliment_battle.cat_moments'.tr(), 'emoji': '💑', 'hint': 'games.compliment_battle.hint_moments'.tr()},
    {'name': 'games.compliment_battle.cat_feelings'.tr(), 'emoji': '💕', 'hint': 'games.compliment_battle.hint_feelings'.tr()},
    {'name': 'games.compliment_battle.cat_unique'.tr(), 'emoji': '✨', 'hint': 'games.compliment_battle.hint_unique'.tr()},
    {'name': 'games.compliment_battle.cat_intelligence'.tr(), 'emoji': '🧠', 'hint': 'games.compliment_battle.hint_intelligence'.tr()},
    {'name': 'games.compliment_battle.cat_kindness'.tr(), 'emoji': '🤗', 'hint': 'games.compliment_battle.hint_kindness'.tr()},
    {'name': 'games.compliment_battle.cat_passion'.tr(), 'emoji': '🔥', 'hint': 'games.compliment_battle.hint_passion'.tr()},
    {'name': 'games.compliment_battle.cat_creativity'.tr(), 'emoji': '🎨', 'hint': 'games.compliment_battle.hint_creativity'.tr()},
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startGame() {
    _pickCategory();
    setState(() {
      _gameStarted = true;
      _currentPlayer = 1;
      _player1Score = 0;
      _player2Score = 0;
      _roundNumber = 1;
      _isThinking = true;
    });

    // Give thinking time before starting
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isThinking = false;
        });
        _startTimer();
      }
    });
  }

  void _pickCategory() {
    final random = Random();
    final category = _categories[random.nextInt(_categories.length)];
    _currentCategory = category['name'];
  }

  void _startTimer() {
    _timer?.cancel();
    final baseTime = _difficulty == 'easy' ? 20 : _difficulty == 'hard' ? 10 : 15;
    setState(() {
      _timeRemaining = baseTime;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _timeRemaining--;
      });

      if (_timeRemaining <= 0) {
        _timer?.cancel();
        _handleTimeout();
      }
    });
  }

  void _handleTimeout() {
    // Current player loses the round
    _showRoundResult(false);
  }

  void _handleComplimentGiven() {
    _timer?.cancel();

    // Award points based on time remaining
    final bonus = (_timeRemaining / 5).ceil();
    final points = 10 + bonus;

    setState(() {
      if (_currentPlayer == 1) {
        _player1Score += points;
      } else {
        _player2Score += points;
      }
    });

    _showRoundResult(true, points);
  }

  void _handlePass() {
    _timer?.cancel();
    _showRoundResult(false);
  }

  void _showRoundResult(bool success, [int points = 0]) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          success ? 'games.compliment_battle.nice_compliment'.tr() : 'games.compliment_battle.time_up'.tr(),
          style: TextStyle(
            color: success ? AppColors.gold : AppColors.spicy,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (success) ...[
              Text(
                'games.compliment_battle.plus_points'.tr(args: [points.toString()]),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.gold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'games.compliment_battle.made_partner_special'.tr(),
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ] else ...[
              Text(
                'games.compliment_battle.no_points'.tr(),
                style: const TextStyle(
                  fontSize: 18,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
            const SizedBox(height: 16),
            _buildScoreRow(),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _nextTurn();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.burgundy,
              foregroundColor: Colors.white,
            ),
            child: Text('games.compliment_battle.continue'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreRow() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Text(
                'games.compliment_battle.player1'.tr(),
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              Text(
                '$_player1Score',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.burgundy,
                ),
              ),
            ],
          ),
          const Text('VS', style: TextStyle(color: AppColors.gold)),
          Column(
            children: [
              Text(
                'games.compliment_battle.player2'.tr(),
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              Text(
                '$_player2Score',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.spicy,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _nextTurn() {
    if (_currentPlayer == 1) {
      // Switch to player 2 with same category
      setState(() {
        _currentPlayer = 2;
        _isThinking = true;
      });

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _isThinking = false;
          });
          _startTimer();
        }
      });
    } else {
      // Both players done, next round or end
      if (_roundNumber < _totalRounds) {
        _pickCategory();
        setState(() {
          _roundNumber++;
          _currentPlayer = 1;
          _isThinking = true;
        });

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _isThinking = false;
            });
            _startTimer();
          }
        });
      } else {
        _showFinalResults();
      }
    }
  }

  void _showFinalResults() {
    final winner = _player1Score > _player2Score
        ? 'games.compliment_battle.player1'.tr()
        : _player1Score < _player2Score
            ? 'games.compliment_battle.player2'.tr()
            : null;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'games.compliment_battle.battle_over'.tr(),
          style: const TextStyle(color: AppColors.gold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              winner != null ? 'games.compliment_battle.winner'.tr(args: [winner]) : 'games.compliment_battle.tie'.tr(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text('🥇', style: TextStyle(fontSize: 32)),
                    Text(
                      '$_player1Score',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.burgundy,
                      ),
                    ),
                    Text(
                      'games.compliment_battle.player1'.tr(),
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Text('🥇', style: TextStyle(fontSize: 32)),
                    Text(
                      '$_player2Score',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.spicy,
                      ),
                    ),
                    Text(
                      'games.compliment_battle.player2'.tr(),
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              winner != null
                  ? 'games.compliment_battle.winner_reward'.tr()
                  : 'games.compliment_battle.both_champions'.tr(),
              style: const TextStyle(
                color: AppColors.gold,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _gameStarted = false;
              });
            },
            child: Text('games.compliment_battle.new_game'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.burgundy,
              foregroundColor: Colors.white,
            ),
            child: Text('games.compliment_battle.end'.tr()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('games.compliment_battle.title'.tr()),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showRules,
          ),
        ],
      ),
      body: _gameStarted ? _buildGameScreen() : _buildSetupScreen(),
    );
  }

  Widget _buildSetupScreen() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Header
            const Text(
              '💬',
              style: TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 16),
            Text(
              'games.compliment_battle.title'.tr(),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'games.compliment_battle.subtitle'.tr(),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Difficulty
            Text(
              'games.compliment_battle.difficulty_label'.tr(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildDifficultyOption('easy', 'games.compliment_battle.diff_easy'.tr(), 'games.compliment_battle.diff_easy_time'.tr()),
                const SizedBox(width: 8),
                _buildDifficultyOption('normal', 'games.compliment_battle.diff_normal'.tr(), 'games.compliment_battle.diff_normal_time'.tr()),
                const SizedBox(width: 8),
                _buildDifficultyOption('hard', 'games.compliment_battle.diff_hard'.tr(), 'games.compliment_battle.diff_hard_time'.tr()),
              ],
            ),

            const SizedBox(height: 24),

            // Rounds
            Text(
              'games.compliment_battle.rounds_label'.tr(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [3, 5, 7].map((rounds) {
                final isSelected = _totalRounds == rounds;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _totalRounds = rounds),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.burgundy : AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppColors.burgundy : AppColors.textSecondary.withOpacity(0.3),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '$rounds',
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const Spacer(),

            // Rules preview
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    'games.compliment_battle.quick_rules'.tr(),
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'games.compliment_battle.quick_rules_desc'.tr(),
                    style: const TextStyle(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Start button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _startGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.burgundy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'games.compliment_battle.start_battle'.tr(),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyOption(String value, String label, String time) {
    final isSelected = _difficulty == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _difficulty = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.burgundy : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.burgundy : AppColors.textSecondary.withOpacity(0.3),
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              Text(
                time,
                style: TextStyle(
                  color: isSelected ? Colors.white70 : AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameScreen() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'games.compliment_battle.round_of'.tr(args: [_roundNumber.toString(), _totalRounds.toString()]),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildScoreRow(),
              ],
            ),

            const SizedBox(height: 24),

            // Current player indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: _currentPlayer == 1
                    ? AppColors.burgundy
                    : AppColors.spicy,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'games.compliment_battle.player_turn'.tr(args: [_currentPlayer.toString()]),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Category card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.burgundy.withOpacity(0.2),
                    AppColors.romantic.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.gold.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Text(
                    'games.compliment_battle.compliment_on'.tr(),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _currentCategory,
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Timer
            if (_isThinking) ...[
              Text(
                'games.compliment_battle.get_ready'.tr(),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 16),
              const CircularProgressIndicator(
                color: AppColors.gold,
              ),
            ] else ...[
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _timeRemaining <= 5 ? _pulseAnimation.value : 1.0,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _timeRemaining <= 5
                            ? AppColors.spicy.withOpacity(0.2)
                            : AppColors.surface,
                        border: Border.all(
                          color: _timeRemaining <= 5
                              ? AppColors.spicy
                              : AppColors.gold,
                          width: 4,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '$_timeRemaining',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: _timeRemaining <= 5
                                ? AppColors.spicy
                                : AppColors.gold,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],

            const Spacer(),

            // Action buttons
            if (!_isThinking) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleComplimentGiven,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.background,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'games.compliment_battle.compliment_done'.tr(),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _handlePass,
                child: Text(
                  'games.compliment_battle.pass'.tr(),
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showRules() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'games.compliment_battle.how_to_play'.tr(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildRuleItem('1', 'games.compliment_battle.rule1'.tr()),
            _buildRuleItem('2', 'games.compliment_battle.rule2'.tr()),
            _buildRuleItem('3', 'games.compliment_battle.rule3'.tr()),
            _buildRuleItem('4', 'games.compliment_battle.rule4'.tr()),
            _buildRuleItem('5', 'games.compliment_battle.rule5'.tr()),
            const SizedBox(height: 16),
            Text(
              'games.compliment_battle.be_creative'.tr(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleItem(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.burgundy.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: AppColors.burgundy,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
