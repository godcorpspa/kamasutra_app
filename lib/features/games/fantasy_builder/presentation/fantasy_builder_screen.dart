import 'dart:math';
import 'package:flutter/material.dart';
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

  final Map<String, List<Map<String, String>>> _options = {
    'settings': [
      {'value': 'beach_sunset', 'emoji': '🏖️', 'label': 'Spiaggia al tramonto'},
      {'value': 'mountain_cabin', 'emoji': '🏔️', 'label': 'Baita in montagna'},
      {'value': 'candlelit_room', 'emoji': '🕯️', 'label': 'Stanza a lume di candela'},
      {'value': 'rooftop_city', 'emoji': '🌃', 'label': 'Terrazza sulla città'},
      {'value': 'forest_clearing', 'emoji': '🌲', 'label': 'Radura nel bosco'},
      {'value': 'luxury_hotel', 'emoji': '🏨', 'label': 'Hotel di lusso'},
      {'value': 'private_pool', 'emoji': '🏊', 'label': 'Piscina privata'},
      {'value': 'vintage_train', 'emoji': '🚂', 'label': 'Treno d\'epoca'},
    ],
    'moods': [
      {'value': 'romantic', 'emoji': '💕', 'label': 'Romantico e dolce'},
      {'value': 'playful', 'emoji': '😏', 'label': 'Giocoso e scherzoso'},
      {'value': 'passionate', 'emoji': '🔥', 'label': 'Passionale e intenso'},
      {'value': 'mysterious', 'emoji': '🎭', 'label': 'Misterioso e seducente'},
      {'value': 'adventurous', 'emoji': '⚡', 'label': 'Avventuroso e audace'},
      {'value': 'tender', 'emoji': '🌸', 'label': 'Tenero e delicato'},
    ],
    'actions_soft': [
      {'value': 'massage', 'emoji': '💆', 'label': 'Massaggio rilassante'},
      {'value': 'dance', 'emoji': '💃', 'label': 'Ballo lento insieme'},
      {'value': 'bath', 'emoji': '🛁', 'label': 'Bagno caldo insieme'},
      {'value': 'stargazing', 'emoji': '⭐', 'label': 'Guardare le stelle'},
      {'value': 'cooking', 'emoji': '👨‍🍳', 'label': 'Cucinare insieme'},
      {'value': 'reading', 'emoji': '📖', 'label': 'Leggere poesie'},
    ],
    'actions_spicy': [
      {'value': 'blindfold', 'emoji': '🙈', 'label': 'Gioco della benda'},
      {'value': 'roleplay', 'emoji': '🎭', 'label': 'Gioco di ruolo'},
      {'value': 'ice_game', 'emoji': '🧊', 'label': 'Gioco del ghiaccio'},
      {'value': 'feather', 'emoji': '🪶', 'label': 'Esplorazione con piuma'},
      {'value': 'oil_massage', 'emoji': '✨', 'label': 'Massaggio con oli'},
      {'value': 'strip_game', 'emoji': '🎲', 'label': 'Gioco a eliminazione'},
    ],
    'surprises': [
      {'value': 'music', 'emoji': '🎵', 'label': 'Playlist speciale'},
      {'value': 'champagne', 'emoji': '🥂', 'label': 'Champagne o drink'},
      {'value': 'chocolate', 'emoji': '🍫', 'label': 'Cioccolato e fragole'},
      {'value': 'flowers', 'emoji': '💐', 'label': 'Petali di rosa'},
      {'value': 'lingerie', 'emoji': '👙', 'label': 'Sorpresa di stile'},
      {'value': 'letter', 'emoji': '💌', 'label': 'Lettera d\'amore'},
      {'value': 'perfume', 'emoji': '✨', 'label': 'Profumo preferito'},
      {'value': 'game', 'emoji': '🎮', 'label': 'Gioco a sorpresa'},
    ],
  };

  final List<String> _steps = [
    'Ambientazione',
    'Atmosfera',
    'Azione principale',
    'Sorpresa',
    'Dettagli finali',
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
                        'La vostra fantasia',
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
                        'Ambientazione',
                        '${setting['emoji']} ${setting['label']}',
                      ),
                      const Divider(color: AppColors.gold, height: 24),
                      _buildFantasyItem(
                        'Atmosfera',
                        '${mood['emoji']} ${mood['label']}',
                      ),
                      const Divider(color: AppColors.gold, height: 24),
                      _buildFantasyItem(
                        'Azione',
                        '${action['emoji']} ${action['label']}',
                      ),
                      const Divider(color: AppColors.gold, height: 24),
                      _buildFantasyItem(
                        'Sorpresa',
                        '${surprise['emoji']} ${surprise['label']}',
                      ),
                      if (_customDetails.isNotEmpty) ...[
                        const Divider(color: AppColors.gold, height: 24),
                        _buildFantasyItem(
                          'Dettagli speciali',
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
                      const Text(
                        '📖 La vostra storia:',
                        style: TextStyle(
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
                        child: const Text('Nuova fantasia'),
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
                        child: const Text('Realizzala! 🔥'),
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
    return 'Immaginate di essere in ${setting['label']?.toLowerCase() ?? 'un luogo speciale'}. '
        'L\'atmosfera è ${mood['label']?.toLowerCase() ?? 'magica'}. '
        'Iniziate con ${action['label']?.toLowerCase() ?? 'qualcosa di speciale'}, '
        'mentre una ${surprise['label']?.toLowerCase() ?? 'sorpresa'} rende tutto ancora più memorabile. '
        '${_customDetails.isNotEmpty ? '\n\nI vostri dettagli speciali: ${_customDetails.join(", ")}.' : ''}'
        '\n\nLasciatevi trasportare dalla fantasia e rendetela realtà quando vi sentite pronti! 💫';
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
        title: const Text(
          'Quando realizzarla? 📅',
          style: TextStyle(color: AppColors.gold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRealizationOption('🌙', 'Stasera', 'Iniziamo subito!'),
            const SizedBox(height: 8),
            _buildRealizationOption('📅', 'Questo weekend', 'Pianifichiamo con calma'),
            const SizedBox(height: 8),
            _buildRealizationOption('🎁', 'Occasione speciale', 'Per un\'occasione memorabile'),
            const SizedBox(height: 8),
            _buildRealizationOption('💭', 'Solo fantasia', 'Per ora solo da immaginare'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Chiudi'),
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
            content: Text('$emoji Perfetto! $title'),
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
        title: const Text('Fantasy Builder'),
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
              'Fantasy Builder',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Costruite insieme la fantasia perfetta',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            // Intensity selection
            Text(
              'Intensità',
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
                  const Text(
                    'Come funziona:',
                    style: TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'A turno scegliete gli elementi della fantasia. '
                    'Alla fine avrete una storia unica da realizzare insieme!',
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
                child: const Text(
                  'Inizia a creare',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                'Giocatore $_currentPlayer sceglie',
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
                  _currentStep < 4 ? 'Conferma e passa' : 'Vedi la fantasia! ✨',
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
          'Aggiungete dettagli speciali (opzionale)',
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
                  hintText: 'Es: musica jazz, champagne...',
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
              'Come funziona ✨',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildRuleItem('1', 'A turno scegliete gli elementi'),
            _buildRuleItem('2', 'Ogni scelta costruisce la fantasia'),
            _buildRuleItem('3', 'Aggiungete dettagli personali'),
            _buildRuleItem('4', 'Alla fine, decidete quando realizzarla!'),
            const SizedBox(height: 16),
            Text(
              'Create qualcosa di unico insieme! 💕',
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
