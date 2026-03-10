import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

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
  final _player1Controller = TextEditingController(text: 'Giocatore 1');
  final _player2Controller = TextEditingController(text: 'Giocatore 2');
  final _formKey = GlobalKey<FormState>();
  PlayerGender _player1Gender = PlayerGender.male;
  PlayerGender _player2Gender = PlayerGender.female;

  @override
  void initState() {
    super.initState();
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
          ? 'Giocatore 1'
          : _player1Controller.text.trim(),
      player2Name: _player2Controller.text.trim().isEmpty
          ? 'Giocatore 2'
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
        title: const Text('🎲 Gioco dell\'Oca Piccante'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: _showTutorial,
            icon: const Icon(Icons.help_outline),
            label: const Text('Regole'),
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
                      'Gioco dell\'Oca Piccante',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.burgundy,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '100 caselle • 4 capi a testa • Scale, Buchi e Penitenze 🔥',
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
                'Nomi dei Giocatori',
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
                  label: const Text(
                    'INIZIA IL GIOCO',
                    style: TextStyle(
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
      ('🚀', 'Per uscire dalla partenza: tira 4, 5 o 6'),
      ('👕', 'Iniziate con 4 capi ciascuno'),
      ('👗', 'Ogni 20 caselle superate: l\'avversario toglie un capo'),
      ('🪜', 'Scala: avanza + ricompensa dal partner'),
      ('🕳️', 'Buco: torna indietro + penitenza'),
      ('🔥', 'Casella Penitenza: azione piccante'),
      ('🎲', '6 sul dado: tira ancora (max 2 volte)'),
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
            'Regole Veloci',
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
            labelText: '$emoji Giocatore $playerNumber',
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
            if (v == null || v.trim().isEmpty) return 'Inserisci un nome';
            return null;
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            const SizedBox(width: 4),
            Text('Sesso:', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(width: AppSpacing.sm),
            _GenderChip(
              label: '♂ Maschio',
              selected: gender == PlayerGender.male,
              color: color,
              onTap: () => onGenderChanged(PlayerGender.male),
            ),
            const SizedBox(width: AppSpacing.sm),
            _GenderChip(
              label: '♀ Femmina',
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

  static const _pages = [
    _TutorialPage(
      emoji: '🎲',
      title: 'Benvenuti!',
      body:
          'Il Gioco dell\'Oca Piccante è un gioco di coppia su 100 caselle, '
          'pieno di ricompense bollenti, penitenze hot e colpi di scena! '
          'Vince chi arriva alla casella 100 e ottiene una ricompensa speciale dal partner 😈',
    ),
    _TutorialPage(
      emoji: '👕',
      title: '4 Capi a Testa',
      body:
          'Ogni giocatore inizia con 4 capi di abbigliamento. '
          'Man mano che il gioco avanza, li perderete... '
          'Se non avete più capi da togliere, scatta una penitenza piccante! 🔥',
    ),
    _TutorialPage(
      emoji: '🚀',
      title: 'Uscire dalla Partenza',
      body:
          'Per lasciare la casella 0 devi tirare 4, 5 o 6. '
          'Se non ci riesci per DUE turni consecutivi, il partner toglie un tuo capo!\n\n'
          'Quando esci, tira di nuovo il dado per muoverti.',
    ),
    _TutorialPage(
      emoji: '👗',
      title: 'Regola dei 20',
      body:
          'Ogni volta che superi un multiplo di 20 (caselle 20, 40, 60, 80), '
          'il tuo avversario deve togliere un capo di abbigliamento!\n\n'
          'Avanza veloce per spogliare il partner 😏',
    ),
    _TutorialPage(
      emoji: '🪜',
      title: 'Scale e Buchi',
      body:
          '🪜 SCALA: salti in avanti a una casella più alta '
          'e ricevi una ricompensa dal partner!\n\n'
          '🕳️ BUCO: torni indietro a una casella più bassa '
          'e devi fare una penitenza al partner!',
    ),
    _TutorialPage(
      emoji: '🔥',
      title: 'Caselle Penitenza',
      body:
          'Sparse per la plancia ci sono le caselle Penitenza 🔥\n\n'
          'Se ci atterri, pesca una penitenza piccante e... eseguila! '
          'Nessuna scusa! 😈',
    ),
    _TutorialPage(
      emoji: '🎲',
      title: 'Il 6 Fortunato',
      body:
          'Se tiri un 6, tira di nuovo il dado!\n\n'
          'Puoi farlo al massimo 2 volte consecutive '
          '(quindi 3 lanci in totale per un turno). '
          'Approfittane per fare il salto più grande! 🚀',
    ),
    _TutorialPage(
      emoji: '⏱️',
      title: 'Ricompense a Tempo',
      body:
          'Alcune ricompense e penitenze hanno un timer!\n\n'
          'Quando appare il conto alla rovescia, '
          'dovete eseguire l\'azione per tutto il tempo indicato. '
          'Il timer parte automaticamente. Pronti? 😉',
    ),
    _TutorialPage(
      emoji: '🏆',
      title: 'La Vittoria!',
      body:
          'Chi arriva esattamente alla casella 100 vince!\n\n'
          'Se il tiro ti porta oltre il 100, rimbalzi indietro. '
          'Il vincitore riceve una ricompensa speciale dal partner!\n\n'
          'Buon gioco! 🎉',
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
                    'Salta tutto',
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
                  child: Text(isLast ? 'Iniziamo! 🎲' : 'Avanti →'),
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
