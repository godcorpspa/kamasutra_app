import 'dart:math';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../app/theme.dart';

class LoveNotesScreen extends StatefulWidget {
  const LoveNotesScreen({super.key});

  @override
  State<LoveNotesScreen> createState() => _LoveNotesScreenState();
}

class _LoveNotesScreenState extends State<LoveNotesScreen> {
  bool _gameStarted = false;
  String _currentPrompt = '';
  int _currentPlayer = 1;
  int _roundNumber = 1;
  int _totalRounds = 5;
  final TextEditingController _noteController = TextEditingController();
  final List<Map<String, dynamic>> _savedNotes = [];
  String _category = 'romantic';

  final Map<String, List<String>> _promptKeys = {
    'romantic': [
      'games.love_notes.prompts.romantic_0',
      'games.love_notes.prompts.romantic_1',
      'games.love_notes.prompts.romantic_2',
      'games.love_notes.prompts.romantic_3',
      'games.love_notes.prompts.romantic_4',
      'games.love_notes.prompts.romantic_5',
      'games.love_notes.prompts.romantic_6',
      'games.love_notes.prompts.romantic_7',
      'games.love_notes.prompts.romantic_8',
      'games.love_notes.prompts.romantic_9',
    ],
    'compliment': [
      'games.love_notes.prompts.compliment_0',
      'games.love_notes.prompts.compliment_1',
      'games.love_notes.prompts.compliment_2',
      'games.love_notes.prompts.compliment_3',
      'games.love_notes.prompts.compliment_4',
      'games.love_notes.prompts.compliment_5',
      'games.love_notes.prompts.compliment_6',
      'games.love_notes.prompts.compliment_7',
      'games.love_notes.prompts.compliment_8',
      'games.love_notes.prompts.compliment_9',
    ],
    'spicy': [
      'games.love_notes.prompts.spicy_0',
      'games.love_notes.prompts.spicy_1',
      'games.love_notes.prompts.spicy_2',
      'games.love_notes.prompts.spicy_3',
      'games.love_notes.prompts.spicy_4',
      'games.love_notes.prompts.spicy_5',
      'games.love_notes.prompts.spicy_6',
      'games.love_notes.prompts.spicy_7',
      'games.love_notes.prompts.spicy_8',
      'games.love_notes.prompts.spicy_9',
    ],
  };

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _startGame() {
    _pickNewPrompt();
    setState(() {
      _gameStarted = true;
      _currentPlayer = 1;
      _roundNumber = 1;
      _savedNotes.clear();
    });
  }

  void _pickNewPrompt() {
    final promptKeys = _promptKeys[_category]!;
    _currentPrompt = promptKeys[Random().nextInt(promptKeys.length)].tr();
  }

  void _submitNote() {
    if (_noteController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('game_ui.write_first'.tr()),
          backgroundColor: AppColors.spicy,
        ),
      );
      return;
    }

    setState(() {
      _savedNotes.add({
        'player': _currentPlayer,
        'prompt': _currentPrompt,
        'note': _noteController.text.trim(),
        'round': _roundNumber,
      });
      _noteController.clear();
    });

    if (_currentPlayer == 1) {
      // Player 2's turn with same prompt
      setState(() {
        _currentPlayer = 2;
      });
    } else {
      // Both players done, next round or end
      if (_roundNumber < _totalRounds) {
        _pickNewPrompt();
        setState(() {
          _roundNumber++;
          _currentPlayer = 1;
        });
      } else {
        _showResults();
      }
    }
  }

  void _showResults() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text(
                      '💌',
                      style: TextStyle(fontSize: 48),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'game_ui.your_love_notes'.tr(),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'game_ui.read_together'.tr(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Notes list
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _totalRounds,
                  itemBuilder: (context, roundIndex) {
                    final roundNotes = _savedNotes
                        .where((n) => n['round'] == roundIndex + 1)
                        .toList();

                    if (roundNotes.isEmpty) return const SizedBox();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Prompt
                          Text(
                            '📝 ${roundNotes.first['prompt']}',
                            style: const TextStyle(
                              color: AppColors.gold,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Player 1's note
                          if (roundNotes.any((n) => n['player'] == 1))
                            _buildNoteCard(
                              'game_ui.player_1'.tr(),
                              roundNotes.firstWhere((n) => n['player'] == 1)['note'],
                              AppColors.burgundy,
                            ),

                          const SizedBox(height: 8),

                          // Player 2's note
                          if (roundNotes.any((n) => n['player'] == 2))
                            _buildNoteCard(
                              'game_ui.player_2'.tr(),
                              roundNotes.firstWhere((n) => n['player'] == 2)['note'],
                              AppColors.spicy,
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Action buttons
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _startGame();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text('game_ui.play_again'.tr()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.burgundy,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text('game_ui.end'.tr()),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoteCard(String player, String note, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            player,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            note,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontStyle: FontStyle.italic,
            ),
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
        title: Text('games.love_notes.title'.tr()),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Center(
              child: Column(
                children: [
                  const Text(
                    '💌',
                    style: TextStyle(fontSize: 64),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'games.love_notes.title'.tr(),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'game_ui.write_secret_messages'.tr(),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Category selection
            Text(
              'game_ui.category'.tr(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _buildCategoryOption('romantic', 'game_ui.romantic_cat'.tr(), 'game_ui.romantic_desc'.tr()),
            const SizedBox(height: 8),
            _buildCategoryOption('compliment', 'game_ui.compliment_cat'.tr(), 'game_ui.compliment_desc'.tr()),
            const SizedBox(height: 8),
            _buildCategoryOption('spicy', 'game_ui.spicy_cat'.tr(), 'game_ui.spicy_desc'.tr()),

            const SizedBox(height: 24),

            // Rounds selection
            Text(
              'game_ui.number_of_rounds'.tr(),
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
                  'game_ui.start_writing'.tr(),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryOption(String value, String label, String description) {
    final isSelected = _category == value;
    return GestureDetector(
      onTap: () => setState(() => _category = value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.burgundy.withOpacity(0.2) : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.burgundy : AppColors.textSecondary.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? AppColors.burgundy : AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.burgundy),
          ],
        ),
      ),
    );
  }

  Widget _buildGameScreen() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'game_ui.round_of'.tr(namedArgs: {'current': '$_roundNumber', 'total': '$_totalRounds'}),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _currentPlayer == 1
                        ? AppColors.burgundy.withOpacity(0.2)
                        : AppColors.spicy.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'game_ui.player_turn'.tr(namedArgs: {'player': '$_currentPlayer'}),
                    style: TextStyle(
                      color: _currentPlayer == 1 ? AppColors.burgundy : AppColors.spicy,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Prompt card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.burgundy.withOpacity(0.2),
                    AppColors.romantic.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.burgundy.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  const Text(
                    '📝',
                    style: TextStyle(fontSize: 32),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _currentPrompt,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Note input
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.textSecondary.withOpacity(0.2)),
                ),
                child: TextField(
                  controller: _noteController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'game_ui.write_message_hint'.tr(),
                    hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.5)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Privacy reminder
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.gold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Text('👀', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'game_ui.turn_away'.tr(namedArgs: {'player': _currentPlayer == 1 ? '2' : '1'}),
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitNote,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _currentPlayer == 1 ? AppColors.burgundy : AppColors.spicy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  _currentPlayer == 1 ? 'game_ui.send_pass'.tr(namedArgs: {'player': '2'}) : 'game_ui.send_note'.tr(),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
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
              'games.love_notes.rules_title'.tr(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildRuleItem('1', 'games.love_notes.rule_1'.tr()),
            _buildRuleItem('2', 'games.love_notes.rule_2'.tr()),
            _buildRuleItem('3', 'games.love_notes.rule_3'.tr()),
            _buildRuleItem('4', 'games.love_notes.rule_4'.tr()),
            const SizedBox(height: 16),
            Text(
              'game_ui.be_sincere_sweet'.tr(),
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
