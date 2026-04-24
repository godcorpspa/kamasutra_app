import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../app/theme.dart';
import '../../../../app/router.dart';
import '../../../../data/models/goose_game.dart';

/// Setup screen: enter player names, view tutorial, start game
class GooseSetupScreen extends StatefulWidget {
  const GooseSetupScreen({super.key});

  @override
  State<GooseSetupScreen> createState() => _GooseSetupScreenState();
}

class _GooseSetupScreenState extends State<GooseSetupScreen> {
  late final TextEditingController _player1Controller;
  late final TextEditingController _player2Controller;
  final _formKey = GlobalKey<FormState>();
  PlayerGender _player1Gender = PlayerGender.male;
  PlayerGender _player2Gender = PlayerGender.female;

  @override
  void initState() {
    super.initState();
    _player1Controller = TextEditingController(text: 'games.goose_game.player_1_default'.tr());
    _player2Controller = TextEditingController(text: 'games.goose_game.player_2_default'.tr());
    WidgetsBinding.instance.addPostFrameCallback((_) => _showTutorial());
  }

  @override
  void dispose() {
    _player1Controller.dispose();
    _player2Controller.dispose();
    super.dispose();
  }

  void _showTutorial() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _TutorialDialog(),
    );
  }

  void _startGame() {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();

    final config = GooseGameConfig(
      player1Name: _player1Controller.text.trim().isEmpty
          ? 'games.goose_game.player_1_default'.tr()
          : _player1Controller.text.trim(),
      player2Name: _player2Controller.text.trim().isEmpty
          ? 'games.goose_game.player_2_default'.tr()
          : _player2Controller.text.trim(),
      player1Gender: _player1Gender,
      player2Gender: _player2Gender,
    );

    context.push(AppRoutes.gooseGame, extra: config);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('games.goose_game.spicy_goose_game_title'.tr()),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: _showTutorial,
            icon: const Icon(Icons.help_outline),
            label: Text('games.goose_game.rules'.tr()),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.burgundy.withOpacity(0.15),
                      AppColors.gold.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: AppColors.burgundy.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    const Text('🎲', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'games.goose_game.spicy_goose_game_title'.tr(),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.burgundy,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'games.goose_game.subtitle_description'.tr(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.6),
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              // Player names
              Text(
                'games.goose_game.player_names'.tr(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Player 1
              _PlayerNameField(
                controller: _player1Controller,
                playerNumber: 1,
                color: AppColors.burgundy,
                emoji: '🔴',
                gender: _player1Gender,
                onGenderChanged: (g) => setState(() => _player1Gender = g),
              ),

              const SizedBox(height: AppSpacing.md),

              // Player 2
              _PlayerNameField(
                controller: _player2Controller,
                playerNumber: 2,
                color: AppColors.gold,
                emoji: '🟡',
                gender: _player2Gender,
                onGenderChanged: (g) => setState(() => _player2Gender = g),
              ),

              const SizedBox(height: AppSpacing.xxl),

              // Quick rules reminder
              _buildQuickRules(context),

              const SizedBox(height: AppSpacing.xxl),

              // Start button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _startGame,
                  icon: const Text('🎲', style: TextStyle(fontSize: 20)),
                  label: Text(
                    'games.goose_game.start_game'.tr(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.burgundy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickRules(BuildContext context) {
    final rules = [
      ('🚀', 'games.goose_game.quick_rule_exit'.tr()),
      ('👕', 'games.goose_game.quick_rule_clothing'.tr()),
      ('👗', 'games.goose_game.quick_rule_every20'.tr()),
      ('🪜', 'games.goose_game.quick_rule_ladder'.tr()),
      ('🕳️', 'games.goose_game.quick_rule_hole'.tr()),
      ('🔥', 'games.goose_game.quick_rule_penance'.tr()),
      ('🎲', 'games.goose_game.quick_rule_six'.tr()),
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'games.goose_game.quick_rules_title'.tr(),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...rules.map(
            (r) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Text(r.$1, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      r.$2,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== PLAYER NAME FIELD ====================

class _PlayerNameField extends StatelessWidget {
  final TextEditingController controller;
  final int playerNumber;
  final Color color;
  final String emoji;
  final PlayerGender gender;
  final ValueChanged<PlayerGender> onGenderChanged;

  const _PlayerNameField({
    required this.controller,
    required this.playerNumber,
    required this.color,
    required this.emoji,
    required this.gender,
    required this.onGenderChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          maxLength: 20,
          decoration: InputDecoration(
            labelText: '$emoji ${'games.goose_game.player_label'.tr(namedArgs: {'number': '$playerNumber'})}',
            prefixIcon: Container(
              margin: const EdgeInsets.all(8),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$playerNumber',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: color, width: 2),
            ),
            counterText: '',
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'games.goose_game.enter_name'.tr();
            return null;
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            const SizedBox(width: 4),
            Text('games.goose_game.gender_label'.tr(), style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(width: AppSpacing.sm),
            _GenderChip(
              label: 'games.goose_game.gender_male'.tr(),
              selected: gender == PlayerGender.male,
              color: color,
              onTap: () => onGenderChanged(PlayerGender.male),
            ),
            const SizedBox(width: AppSpacing.sm),
            _GenderChip(
              label: 'games.goose_game.gender_female'.tr(),
              selected: gender == PlayerGender.female,
              color: color,
              onTap: () => onGenderChanged(PlayerGender.female),
            ),
          ],
        ),
      ],
    );
  }
}

class _GenderChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _GenderChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: selected ? color : Theme.of(context).colorScheme.outline.withOpacity(0.3),
            width: selected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            color: selected ? color : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ),
    );
  }
}

// ==================== TUTORIAL DIALOG ====================

class _TutorialDialog extends StatefulWidget {
  const _TutorialDialog();

  @override
  State<_TutorialDialog> createState() => _TutorialDialogState();
}

class _TutorialDialogState extends State<_TutorialDialog> {
  int _page = 0;
  final PageController _pageController = PageController();

  static List<_TutorialPage> get _pages => [
    _TutorialPage(
      emoji: '🎲',
      title: 'games.goose_game.tutorial_welcome_title'.tr(),
      body: 'games.goose_game.tutorial_welcome_body'.tr(),
    ),
    _TutorialPage(
      emoji: '👕',
      title: 'games.goose_game.tutorial_clothing_title'.tr(),
      body: 'games.goose_game.tutorial_clothing_body'.tr(),
    ),
    _TutorialPage(
      emoji: '🚀',
      title: 'games.goose_game.tutorial_exit_title'.tr(),
      body: 'games.goose_game.tutorial_exit_body'.tr(),
    ),
    _TutorialPage(
      emoji: '👗',
      title: 'games.goose_game.tutorial_rule20_title'.tr(),
      body: 'games.goose_game.tutorial_rule20_body'.tr(),
    ),
    _TutorialPage(
      emoji: '🪜',
      title: 'games.goose_game.tutorial_ladders_title'.tr(),
      body: 'games.goose_game.tutorial_ladders_body'.tr(),
    ),
    _TutorialPage(
      emoji: '🔥',
      title: 'games.goose_game.tutorial_penance_title'.tr(),
      body: 'games.goose_game.tutorial_penance_body'.tr(),
    ),
    _TutorialPage(
      emoji: '🎲',
      title: 'games.goose_game.tutorial_six_title'.tr(),
      body: 'games.goose_game.tutorial_six_body'.tr(),
    ),
    _TutorialPage(
      emoji: '⏱️',
      title: 'games.goose_game.tutorial_timer_title'.tr(),
      body: 'games.goose_game.tutorial_timer_body'.tr(),
    ),
    _TutorialPage(
      emoji: '🏆',
      title: 'games.goose_game.tutorial_victory_title'.tr(),
      body: 'games.goose_game.tutorial_victory_body'.tr(),
    ),
  ];

  void _next() {
    if (_page < _pages.length - 1) {
      setState(() => _page++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  void _skipAll() => Navigator.of(context).pop();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _pages.length - 1;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Page indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _page ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == _page
                        ? AppColors.burgundy
                        : AppColors.burgundy.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Content
            Flexible(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: _pages.length,
                itemBuilder: (context, i) => _pages[i].build(context),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Buttons
            Row(
              children: [
                // Skip All
                TextButton(
                  onPressed: _skipAll,
                  child: Text(
                    'games.goose_game.skip_all'.tr(),
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ),
                const Spacer(),
                // Next / Done
                ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.burgundy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.sm,
                    ),
                  ),
                  child: Text(isLast ? 'games.goose_game.lets_start'.tr() : 'games.goose_game.forward'.tr()),
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _TutorialPage {
  final String emoji;
  final String title;
  final String body;

  const _TutorialPage({
    required this.emoji,
    required this.title,
    required this.body,
  });

  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 52)),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.burgundy,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
