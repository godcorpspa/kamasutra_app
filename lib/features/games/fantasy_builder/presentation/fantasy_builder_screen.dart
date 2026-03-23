import 'dart:math';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../app/theme.dart';

class FantasyBuilderScreen extends StatefulWidget {
  const FantasyBuilderScreen({super.key});

  @override
  State<FantasyBuilderScreen> createState() => _FantasyBuilderScreenState();
}

class _FantasyBuilderScreenState extends State<FantasyBuilderScreen> {
  bool _gameStarted = false;
  int _currentStep = 0;
  int _currentPlayer = 1;
  String _intensity = 'spicy';

  // Fantasy building blocks
  String? _selectedSetting;
  String? _selectedMood;
  String? _selectedAction;
  String? _selectedSurprise;
  final List<String> _customDetails = [];
  final TextEditingController _detailController = TextEditingController();

  Map<String, List<Map<String, String>>> get _options => {
    'settings': [
      {'value': 'beach_sunset', 'emoji': '🏖️', 'label': 'games.fantasy_builder.settings.beach_sunset'.tr()},
      {'value': 'mountain_cabin', 'emoji': '🏔️', 'label': 'games.fantasy_builder.settings.mountain_cabin'.tr()},
      {'value': 'candlelit_room', 'emoji': '🕯️', 'label': 'games.fantasy_builder.settings.candlelit_room'.tr()},
      {'value': 'rooftop_city', 'emoji': '🌃', 'label': 'games.fantasy_builder.settings.rooftop_city'.tr()},
      {'value': 'forest_clearing', 'emoji': '🌲', 'label': 'games.fantasy_builder.settings.forest_clearing'.tr()},
      {'value': 'luxury_hotel', 'emoji': '🏨', 'label': 'games.fantasy_builder.settings.luxury_hotel'.tr()},
      {'value': 'private_pool', 'emoji': '🏊', 'label': 'games.fantasy_builder.settings.private_pool'.tr()},
      {'value': 'vintage_train', 'emoji': '🚂', 'label': 'games.fantasy_builder.settings.vintage_train'.tr()},
    ],
    'moods': [
      {'value': 'romantic', 'emoji': '💕', 'label': 'games.fantasy_builder.moods.romantic'.tr()},
      {'value': 'playful', 'emoji': '😏', 'label': 'games.fantasy_builder.moods.playful'.tr()},
      {'value': 'passionate', 'emoji': '🔥', 'label': 'games.fantasy_builder.moods.passionate'.tr()},
      {'value': 'mysterious', 'emoji': '🎭', 'label': 'games.fantasy_builder.moods.mysterious'.tr()},
      {'value': 'adventurous', 'emoji': '⚡', 'label': 'games.fantasy_builder.moods.adventurous'.tr()},
      {'value': 'tender', 'emoji': '🌸', 'label': 'games.fantasy_builder.moods.tender'.tr()},
    ],
    'actions_soft': [
      {'value': 'massage', 'emoji': '💆', 'label': 'games.fantasy_builder.actions_soft.massage'.tr()},
      {'value': 'dance', 'emoji': '💃', 'label': 'games.fantasy_builder.actions_soft.dance'.tr()},
      {'value': 'bath', 'emoji': '🛁', 'label': 'games.fantasy_builder.actions_soft.bath'.tr()},
      {'value': 'stargazing', 'emoji': '⭐', 'label': 'games.fantasy_builder.actions_soft.stargazing'.tr()},
      {'value': 'cooking', 'emoji': '👨‍🍳', 'label': 'games.fantasy_builder.actions_soft.cooking'.tr()},
      {'value': 'reading', 'emoji': '📖', 'label': 'games.fantasy_builder.actions_soft.reading'.tr()},
    ],
    'actions_spicy': [
      {'value': 'blindfold', 'emoji': '🙈', 'label': 'games.fantasy_builder.actions_spicy.blindfold'.tr()},
      {'value': 'roleplay', 'emoji': '🎭', 'label': 'games.fantasy_builder.actions_spicy.roleplay'.tr()},
      {'value': 'ice_game', 'emoji': '🧊', 'label': 'games.fantasy_builder.actions_spicy.ice_game'.tr()},
      {'value': 'feather', 'emoji': '🪶', 'label': 'games.fantasy_builder.actions_spicy.feather'.tr()},
      {'value': 'oil_massage', 'emoji': '✨', 'label': 'games.fantasy_builder.actions_spicy.oil_massage'.tr()},
      {'value': 'strip_game', 'emoji': '🎲', 'label': 'games.fantasy_builder.actions_spicy.strip_game'.tr()},
    ],
    'surprises': [
      {'value': 'music', 'emoji': '🎵', 'label': 'games.fantasy_builder.surprises.music'.tr()},
      {'value': 'champagne', 'emoji': '🥂', 'label': 'games.fantasy_builder.surprises.champagne'.tr()},
      {'value': 'chocolate', 'emoji': '🍫', 'label': 'games.fantasy_builder.surprises.chocolate'.tr()},
      {'value': 'flowers', 'emoji': '💐', 'label': 'games.fantasy_builder.surprises.flowers'.tr()},
      {'value': 'lingerie', 'emoji': '👙', 'label': 'games.fantasy_builder.surprises.lingerie'.tr()},
      {'value': 'letter', 'emoji': '💌', 'label': 'games.fantasy_builder.surprises.letter'.tr()},
      {'value': 'perfume', 'emoji': '✨', 'label': 'games.fantasy_builder.surprises.perfume'.tr()},
      {'value': 'game', 'emoji': '🎮', 'label': 'games.fantasy_builder.surprises.game'.tr()},
    ],
  };

  List<String> get _steps => [
    'games.fantasy_builder.steps.setting'.tr(),
    'games.fantasy_builder.steps.atmosphere'.tr(),
    'games.fantasy_builder.steps.main_action'.tr(),
    'games.fantasy_builder.steps.surprise'.tr(),
    'games.fantasy_builder.steps.final_details'.tr(),
  ];

  @override
  void dispose() {
    _detailController.dispose();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      _gameStarted = true;
      _currentStep = 0;
      _currentPlayer = Random().nextInt(2) + 1; // Random start
      _selectedSetting = null;
      _selectedMood = null;
      _selectedAction = null;
      _selectedSurprise = null;
      _customDetails.clear();
    });
  }

  void _selectOption(String value) {
    setState(() {
      switch (_currentStep) {
        case 0:
          _selectedSetting = value;
          break;
        case 1:
          _selectedMood = value;
          break;
        case 2:
          _selectedAction = value;
          break;
        case 3:
          _selectedSurprise = value;
          break;
      }
    });
  }

  void _nextStep() {
    if (_currentStep < 4) {
      setState(() {
        _currentStep++;
        _currentPlayer = _currentPlayer == 1 ? 2 : 1;
      });
    } else {
      _showFantasyResult();
    }
  }

  void _addDetail() {
    if (_detailController.text.trim().isNotEmpty) {
      setState(() {
        _customDetails.add(_detailController.text.trim());
        _detailController.clear();
      });
    }
  }

  Map<String, String> _getOptionData(String category, String value) {
    final list = _options[category] ?? [];
    return list.firstWhere(
      (o) => o['value'] == value,
      orElse: () => {'value': value, 'emoji': '❓', 'label': value},
    );
  }

  void _showFantasyResult() {
    final setting = _getOptionData('settings', _selectedSetting ?? '');
    final mood = _getOptionData('moods', _selectedMood ?? '');
    final actions = _intensity == 'soft' ? 'actions_soft' : 'actions_spicy';
    final action = _getOptionData(actions, _selectedAction ?? '');
    final surprise = _getOptionData('surprises', _selectedSurprise ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Header
                Center(
                  child: Column(
                    children: [
                      const Text(
                        '✨',
                        style: TextStyle(fontSize: 48),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'games.fantasy_builder.your_fantasy'.tr(),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.gold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Fantasy card
                Container(
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
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.gold.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFantasyItem(
                        'game_ui.setting'.tr(),
                        '${setting['emoji']} ${setting['label']}',
                      ),
                      const Divider(color: AppColors.gold, height: 24),
                      _buildFantasyItem(
                        'game_ui.atmosphere'.tr(),
                        '${mood['emoji']} ${mood['label']}',
                      ),
                      const Divider(color: AppColors.gold, height: 24),
                      _buildFantasyItem(
                        'game_ui.main_action'.tr(),
                        '${action['emoji']} ${action['label']}',
                      ),
                      const Divider(color: AppColors.gold, height: 24),
                      _buildFantasyItem(
                        'game_ui.surprise'.tr(),
                        '${surprise['emoji']} ${surprise['label']}',
                      ),
                      if (_customDetails.isNotEmpty) ...[
                        const Divider(color: AppColors.gold, height: 24),
                        _buildFantasyItem(
                          'game_ui.special_details'.tr(),
                          _customDetails.join('\n• '),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Narrative
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'game_ui.your_story'.tr(),
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _buildNarrative(setting, mood, action, surprise),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontStyle: FontStyle.italic,
                          height: 1.5,
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
                        onPressed: () {
                          Navigator.pop(context);
                          _startGame();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text('game_ui.new_fantasy'.tr()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _showRealizationOptions();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.burgundy,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text('game_ui.realize_it'.tr()),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _buildNarrative(
    Map<String, String> setting,
    Map<String, String> mood,
    Map<String, String> action,
    Map<String, String> surprise,
  ) {
    return 'games.fantasy_builder.narrative.body'.tr(namedArgs: {
      'setting': setting['label']?.toLowerCase() ?? 'games.fantasy_builder.narrative.default_setting'.tr(),
      'mood': mood['label']?.toLowerCase() ?? 'games.fantasy_builder.narrative.default_mood'.tr(),
      'action': action['label']?.toLowerCase() ?? 'games.fantasy_builder.narrative.default_action'.tr(),
      'surprise': surprise['label']?.toLowerCase() ?? 'games.fantasy_builder.narrative.default_surprise'.tr(),
      'customDetails': _customDetails.isNotEmpty
          ? '\n\n${'games.fantasy_builder.narrative.your_special_details'.tr()}: ${_customDetails.join(", ")}.'
          : '',
    });
  }

  Widget _buildFantasyItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _showRealizationOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'game_ui.when_realize'.tr(),
          style: const TextStyle(color: AppColors.gold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRealizationOption('🌙', 'game_ui.tonight'.tr(), 'game_ui.tonight_desc'.tr()),
            const SizedBox(height: 8),
            _buildRealizationOption('📅', 'game_ui.this_weekend'.tr(), 'game_ui.this_weekend_desc'.tr()),
            const SizedBox(height: 8),
            _buildRealizationOption('🎁', 'game_ui.special_occasion'.tr(), 'game_ui.special_occasion_desc'.tr()),
            const SizedBox(height: 8),
            _buildRealizationOption('💭', 'game_ui.just_fantasy'.tr(), 'game_ui.just_fantasy_desc'.tr()),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('common.close'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildRealizationOption(String emoji, String title, String subtitle) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$emoji ${'game_ui.perfect'.tr()} $title'),
            backgroundColor: AppColors.burgundy,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('games.fantasy_builder.title'.tr()),
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
              '✨',
              style: TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 16),
            Text(
              'games.fantasy_builder.title'.tr(),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'game_ui.build_perfect_fantasy'.tr(),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Intensity selection
            Text(
              'game_ui.intensity'.tr(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildIntensityOption('soft', '🌸 Soft'),
                const SizedBox(width: 12),
                _buildIntensityOption('spicy', '🔥 Spicy'),
              ],
            ),

            const Spacer(),

            // How it works
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    'game_ui.how_it_works'.tr(),
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'game_ui.how_it_works_description'.tr(),
                    style: TextStyle(
                      color: AppColors.textSecondary,
                    ),
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
                  'game_ui.start_creating'.tr(),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntensityOption(String value, String label) {
    final isSelected = _intensity == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _intensity = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.burgundy : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.burgundy : AppColors.textSecondary.withOpacity(0.3),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress
            Row(
              children: List.generate(5, (index) {
                final isCompleted = index < _currentStep;
                final isCurrent = index == _currentStep;
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? AppColors.gold
                          : isCurrent
                              ? AppColors.burgundy
                              : AppColors.surface,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),

            // Current player
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _currentPlayer == 1
                    ? AppColors.burgundy.withOpacity(0.2)
                    : AppColors.spicy.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'game_ui.player_chooses'.tr(namedArgs: {'player': '$_currentPlayer'}),
                style: TextStyle(
                  color: _currentPlayer == 1 ? AppColors.burgundy : AppColors.spicy,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Step title
            Text(
              _steps[_currentStep],
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Options or custom input
            Expanded(
              child: _currentStep < 4
                  ? _buildOptionsGrid()
                  : _buildCustomDetails(),
            ),

            // Next button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canProceed() ? _nextStep : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.burgundy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  _currentStep < 4 ? 'game_ui.confirm_and_pass'.tr() : 'game_ui.see_fantasy'.tr(),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _selectedSetting != null;
      case 1:
        return _selectedMood != null;
      case 2:
        return _selectedAction != null;
      case 3:
        return _selectedSurprise != null;
      case 4:
        return true;
      default:
        return false;
    }
  }

  Widget _buildOptionsGrid() {
    List<Map<String, String>> options;
    String? selectedValue;

    switch (_currentStep) {
      case 0:
        options = _options['settings']!;
        selectedValue = _selectedSetting;
        break;
      case 1:
        options = _options['moods']!;
        selectedValue = _selectedMood;
        break;
      case 2:
        options = _intensity == 'soft'
            ? _options['actions_soft']!
            : _options['actions_spicy']!;
        selectedValue = _selectedAction;
        break;
      case 3:
        options = _options['surprises']!;
        selectedValue = _selectedSurprise;
        break;
      default:
        options = [];
        selectedValue = null;
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: options.length,
      itemBuilder: (context, index) {
        final option = options[index];
        final isSelected = selectedValue == option['value'];

        return GestureDetector(
          onTap: () => _selectOption(option['value']!),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.burgundy.withOpacity(0.2) : AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppColors.burgundy : AppColors.textSecondary.withOpacity(0.3),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  option['emoji']!,
                  style: const TextStyle(fontSize: 28),
                ),
                const SizedBox(height: 8),
                Text(
                  option['label']!,
                  style: TextStyle(
                    color: isSelected ? AppColors.burgundy : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCustomDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'game_ui.add_special_details'.tr(),
          style: TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _detailController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'game_ui.detail_hint'.tr(),
                  hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.5)),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              onPressed: _addDetail,
              icon: const Icon(Icons.add_circle, color: AppColors.burgundy),
              iconSize: 32,
            ),
          ],
        ),

        const SizedBox(height: 16),

        Expanded(
          child: ListView.builder(
            itemCount: _customDetails.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Text('✨', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _customDetails[index],
                        style: const TextStyle(color: AppColors.textPrimary),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      color: AppColors.textSecondary,
                      onPressed: () {
                        setState(() {
                          _customDetails.removeAt(index);
                        });
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
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
              'game_ui.how_it_works'.tr(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildRuleItem('1', 'games.fantasy_builder.rules.rule_1'.tr()),
            _buildRuleItem('2', 'games.fantasy_builder.rules.rule_2'.tr()),
            _buildRuleItem('3', 'games.fantasy_builder.rules.rule_3'.tr()),
            _buildRuleItem('4', 'games.fantasy_builder.rules.rule_4'.tr()),
            const SizedBox(height: 16),
            Text(
              'games.fantasy_builder.rules.closing'.tr(),
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
