
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../../../data/services/firebase_user_service.dart';
import '../../../../data/providers/user_data_provider.dart';

class FantasyBuilderScreen extends ConsumerStatefulWidget {
  const FantasyBuilderScreen({super.key});

  @override
  ConsumerState<FantasyBuilderScreen> createState() => _FantasyBuilderScreenState();
}

class _FantasyBuilderScreenState extends ConsumerState<FantasyBuilderScreen> {
  bool _isBuilding = false;
  bool _isLoading = false;
  int _currentStep = 0;
  String _intensity = 'romantic';
  
  final Map<String, String> _selections = {};
  String _generatedStory = '';
  
  final List<Map<String, dynamic>> _buildSteps = [
    {
      'title': 'Ambientazione',
      'key': 'setting',
      'options': {
        'romantic': ['Camera d\'hotel di lusso', 'Spiaggia al tramonto', 'Cabina in montagna', 'Villa con piscina'],
        'spicy': ['Ascensore bloccato', 'Ufficio dopo lavoro', 'Camerino negozio', 'Terrazza panoramica'],
        'wild': ['Isola deserta', 'Yacht privato', 'Suite presidenziale', 'Castello antico'],
      },
    },
    {
      'title': 'Chi prende l\'iniziativa?',
      'key': 'initiator',
      'options': {
        'romantic': ['Tu, con dolcezza', 'Il partner, con romanticismo', 'Entrambi, occhi negli occhi'],
        'spicy': ['Tu, con decisione', 'Il partner, con passione', 'È un gioco di sguardi'],
        'wild': ['Tu, con audacia', 'Il partner, senza preavviso', 'Sfida reciproca'],
      },
    },
    {
      'title': 'Come inizia?',
      'key': 'start',
      'options': {
        'romantic': ['Un bacio tenero', 'Una carezza sul viso', 'Un abbraccio stretto', 'Parole dolci sussurrate'],
        'spicy': ['Un bacio appassionato', 'Mani che esplorano', 'Uno sguardo intenso', 'Un sussurro provocante'],
        'wild': ['Un bacio travolgente', 'Vestiti che volano', 'Contro il muro', 'Sorpresa inaspettata'],
      },
    },
    {
      'title': 'L\'atmosfera',
      'key': 'mood',
      'options': {
        'romantic': ['Candele profumate', 'Musica soft', 'Luce soffusa', 'Petali di rosa'],
        'spicy': ['Musica sensuale', 'Luci soffuse', 'Profumo inebriante', 'Tensione palpabile'],
        'wild': ['Adrenalina pura', 'Rischio eccitante', 'Passione sfrenata', 'Nessun limite'],
      },
    },
    {
      'title': 'Il momento clou',
      'key': 'climax',
      'options': {
        'romantic': ['Connessione profonda', 'Occhi negli occhi', 'Promesse sussurrate', 'Unione perfetta'],
        'spicy': ['Piacere intenso', 'Desiderio appagato', 'Complicità totale', 'Estasi condivisa'],
        'wild': ['Esplosione di passione', 'Trasgressione', 'Fantasia realizzata', 'Oltre ogni limite'],
      },
    },
    {
      'title': 'Il finale',
      'key': 'ending',
      'options': {
        'romantic': ['Abbraccio infinito', 'Promesse per il futuro', 'Addormentarsi insieme', 'Un ultimo bacio'],
        'spicy': ['Sorrisi complici', 'Ancora voglia di più', 'Pianificare il prossimo', 'Soddisfazione totale'],
        'wild': ['Ricominciare daccapo', 'Ricordo indelebile', 'Patto segreto', 'La notte è ancora giovane'],
      },
    },
  ];

  @override
  void initState() {
    super.initState();
  }

  void _startBuilding() {
    setState(() {
      _isBuilding = true;
      _currentStep = 0;
      _selections.clear();
      _generatedStory = '';
    });
    
    ref.read(progressNotifierProvider.notifier).incrementGamesPlayed();
  }

  void _selectOption(String option) {
    final step = _buildSteps[_currentStep];
    setState(() {
      _selections[step['key'] as String] = option;
    });
    
    if (_currentStep < _buildSteps.length - 1) {
      setState(() => _currentStep++);
    } else {
      _generateStory();
    }
  }

  void _generateStory() {
    final setting = _selections['setting'] ?? '';
    final initiator = _selections['initiator'] ?? '';
    final start = _selections['start'] ?? '';
    final mood = _selections['mood'] ?? '';
    final climax = _selections['climax'] ?? '';
    final ending = _selections['ending'] ?? '';
    
    _generatedStory = '''
🌟 La Vostra Fantasia 🌟

📍 Siete in: $setting

$initiator. L'aria è carica di $mood.

Tutto inizia con $start. La tensione cresce, il desiderio è palpabile.

Il momento più intenso: $climax.

E alla fine... $ending.

💕 Una fantasia da vivere insieme 💕
''';
    
    setState(() {});
  }

  Future<void> _saveFantasy() async {
    setState(() => _isLoading = true);
    
    try {
      await FirebaseUserService().saveFantasyScenario({
        'story': _generatedStory,
        'selections': _selections,
        'intensity': _intensity,
        'createdAt': DateTime.now().toIso8601String(),
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fantasia salvata! ✨'),
          backgroundColor: AppColors.burgundy,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Fantasy Builder',
          style: TextStyle(fontFamily: 'PlayfairDisplay', fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _showSavedFantasies,
            tooltip: 'Fantasie salvate',
          ),
        ],
      ),
      body: _isBuilding ? _buildBuilderView() : _buildSetupView(),
    );
  }

  Widget _buildSetupView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text('✨', style: TextStyle(fontSize: 64)),
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
            'Costruite insieme la vostra fantasia perfetta',
            style: TextStyle(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
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
                const Text(
                  'Scegli l\'intensità',
                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildIntensityOption('romantic', '💕 Romantico', 'Dolce e sensuale'),
                const SizedBox(height: 8),
                _buildIntensityOption('spicy', '🌶️ Piccante', 'Passionale e intrigante'),
                const SizedBox(height: 8),
                _buildIntensityOption('wild', '🔥 Selvaggio', 'Senza limiti'),
              ],
            ),
          ),
          const SizedBox(height: 32),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _startBuilding,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.burgundy,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Inizia a costruire ✨', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntensityOption(String value, String title, String subtitle) {
    final isSelected = _intensity == value;
    return GestureDetector(
      onTap: () => setState(() => _intensity = value),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.burgundy.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.burgundy : AppColors.textSecondary.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(
                    color: isSelected ? AppColors.burgundy : AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  )),
                  Text(subtitle, style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  )),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle, color: AppColors.burgundy),
          ],
        ),
      ),
    );
  }

  Widget _buildBuilderView() {
    if (_generatedStory.isNotEmpty) {
      return _buildResultView();
    }
    
    final step = _buildSteps[_currentStep];
    final options = (step['options'] as Map<String, List<String>>)[_intensity] ?? [];
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Progress
          LinearProgressIndicator(
            value: (_currentStep + 1) / _buildSteps.length,
            backgroundColor: AppColors.surface,
            valueColor: const AlwaysStoppedAnimation(AppColors.burgundy),
          ),
          const SizedBox(height: 8),
          Text(
            'Step ${_currentStep + 1}/${_buildSteps.length}',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 32),
          
          Text(
            step['title'] as String,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          
          Expanded(
            child: ListView.separated(
              itemCount: options.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => _selectOption(options[index]),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.burgundy.withOpacity(0.3)),
                    ),
                    child: Text(
                      options[index],
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              },
            ),
          ),
          
          if (_currentStep > 0)
            TextButton(
              onPressed: () => setState(() => _currentStep--),
              child: const Text('← Indietro'),
            ),
        ],
      ),
    );
  }

  Widget _buildResultView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.burgundy.withOpacity(0.2), AppColors.romantic.withOpacity(0.1)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.burgundy.withOpacity(0.3)),
            ),
            child: Text(
              _generatedStory,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, height: 1.6),
            ),
          ),
          const SizedBox(height: 24),
          
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _startBuilding,
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: const Text('Ricomincia'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveFantasy,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.burgundy,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('💾 Salva'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSavedFantasies() async {
    final data = await FirebaseUserService().getFantasyBuilder();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        builder: (context, controller) => Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Fantasie salvate (${data.scenarios.length})',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: data.scenarios.isEmpty
                    ? const Center(child: Text('Nessuna fantasia salvata', style: TextStyle(color: AppColors.textSecondary)))
                    : ListView.builder(
                        controller: controller,
                        padding: const EdgeInsets.all(16),
                        itemCount: data.scenarios.length,
                        itemBuilder: (context, index) {
                          final scenario = data.scenarios[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              scenario['story'] ?? '',
                              style: const TextStyle(color: AppColors.textPrimary),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
