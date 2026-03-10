import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/services/preferences_service.dart';
import '../../../data/repositories/position_repository.dart';
import '../../../data/providers/providers.dart';
import '../../../data/models/position.dart';
import '../../../app/theme.dart';

/// Progress screen showing badges, streaks, and statistics
class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen>
    with SingleTickerProviderStateMixin {
  
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Registra l'uso di oggi per la streak
    PreferencesService.instance.recordUsageToday();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'progress.title'.tr(),
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildStreakCard(),
                ],
              ),
            ),
            
            // Tab bar
            TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: 'progress.badges'.tr()),
                Tab(text: 'progress.statistics'.tr()),
                const Tab(text: 'Provate'),
              ],
            ),
            
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildBadgesTab(),
                  _buildStatisticsTab(),
                  _buildHistoryTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // STREAK CARD — dati reali, layout pulito
  // ============================================================

  Widget _buildStreakCard() {
    final prefs = PreferencesService.instance;
    final streak = prefs.currentStreak;
    final longest = prefs.longestStreak;

    // Messaggio motivazionale in base alla streak
    String motivationalMessage;
    if (streak == 0) {
      motivationalMessage = 'Inizia oggi la vostra avventura!';
    } else if (streak == 1) {
      motivationalMessage = 'Ottimo inizio! Tornate domani 💪';
    } else if (streak < 7) {
      motivationalMessage = 'State andando alla grande!';
    } else if (streak < 30) {
      motivationalMessage = 'Che coppia affiatata! 🔥';
    } else {
      motivationalMessage = 'Siete inarrestabili! 🏆';
    }

    // Singolare / plurale
    String giorni(int n) => n == 1 ? '1 giorno' : '$n giorni';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.burgundy,
            AppColors.burgundy.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Icona fuoco
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    streak == 0 ? '💤' : '🔥',
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Serie attuale
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Serie attuale',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withOpacity(0.7),
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      giorni(streak),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),

              // Serie più lunga
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Column(
                  children: [
                    Text(
                      '🏅 Record',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withOpacity(0.7),
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      giorni(longest),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Messaggio motivazionale
          const SizedBox(height: AppSpacing.sm),
          Text(
            motivationalMessage,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.gold.withOpacity(0.9),
                ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BADGES TAB — criteri reali, tutti bloccati all'inizio
  // ============================================================

  Widget _buildBadgesTab() {
    final prefs = PreferencesService.instance;
    final repo = ref.read(positionRepositoryProvider);
    final triedCount = prefs.triedPositionIds.length;
    final gamesPlayed = prefs.gamesPlayed;
    final streak = prefs.longestStreak;
    final currentStreak = prefs.currentStreak;
    final favoritesCount = repo.positions.where((p) => p.isFavorite).length;
    final timeMins = prefs.timeTogetherMinutes;

    // Categorie uniche provate
    final triedIds = prefs.triedPositionIds;
    final Set<String> uniqueCategories = {};
    int highDiffCount = 0;
    for (final id in triedIds) {
      final position = repo.getById(id);
      if (position != null) {
        for (final cat in position.categories) {
          uniqueCategories.add(cat.name);
        }
        if (position.difficulty >= 4) highDiffCount++;
      }
    }
    final totalCategories = 8; // romantic, beginner, athletic, supported, lowImpact, adventurous, reconnect, quickie

    // Per-category tried counts
    final Map<String, int> categoryTriedCount = {};
    int lowEnergyCount = 0;
    int highEnergyCount = 0;
    int longDurationCount = 0;
    int veryHighDiffCount = 0;
    final Set<String> triedFocusTypes = {};
    for (final id in triedIds) {
      final position = repo.getById(id);
      if (position != null) {
        for (final cat in position.categories) {
          categoryTriedCount[cat.name] = (categoryTriedCount[cat.name] ?? 0) + 1;
        }
        if (position.energy == EnergyLevel.low) lowEnergyCount++;
        if (position.energy == EnergyLevel.high) highEnergyCount++;
        if (position.duration == PositionDuration.long) longDurationCount++;
        if (position.difficulty == 5) veryHighDiffCount++;
        for (final f in position.focus) {
          triedFocusTypes.add(f.name);
        }
      }
    }
    final totalFocusTypes = 7; // intimacy, variety, connection, relax, playfulness, passion, trust

    final badges = [
      // ── ESPLORAZIONE ──
      _BadgeData(
        emoji: '🌱',
        name: 'Primo Passo',
        description: 'Prova la tua prima posizione',
        isUnlocked: triedCount >= 1,
        progress: '${triedCount.clamp(0, 1)}/1',
      ),
      _BadgeData(
        emoji: '🧭',
        name: 'Esploratore',
        description: 'Prova 5 posizioni diverse',
        isUnlocked: triedCount >= 5,
        progress: '${triedCount.clamp(0, 5)}/5',
      ),
      _BadgeData(
        emoji: '💫',
        name: 'Iniziatore',
        description: 'Prova 10 posizioni diverse',
        isUnlocked: triedCount >= 10,
        progress: '${triedCount.clamp(0, 10)}/10',
      ),
      _BadgeData(
        emoji: '⛰️',
        name: 'Avventuriero',
        description: 'Prova 20 posizioni diverse',
        isUnlocked: triedCount >= 20,
        progress: '${triedCount.clamp(0, 20)}/20',
      ),
      _BadgeData(
        emoji: '🌺',
        name: 'Appassionato',
        description: 'Prova 30 posizioni diverse',
        isUnlocked: triedCount >= 30,
        progress: '${triedCount.clamp(0, 30)}/30',
      ),
      _BadgeData(
        emoji: '📚',
        name: 'Collezionista',
        description: 'Prova 50 posizioni diverse',
        isUnlocked: triedCount >= 50,
        progress: '${triedCount.clamp(0, 50)}/50',
      ),
      _BadgeData(
        emoji: '💎',
        name: 'Maestro',
        description: 'Prova 100 posizioni diverse',
        isUnlocked: triedCount >= 100,
        progress: '${triedCount.clamp(0, 100)}/100',
      ),
      _BadgeData(
        emoji: '🌟',
        name: 'Leggenda',
        description: 'Prova 150 posizioni diverse',
        isUnlocked: triedCount >= 150,
        progress: '${triedCount.clamp(0, 150)}/150',
      ),
      _BadgeData(
        emoji: '👑',
        name: 'Gran Maestro',
        description: 'Prova 200 posizioni diverse',
        isUnlocked: triedCount >= 200,
        progress: '${triedCount.clamp(0, 200)}/200',
      ),

      // ── PREFERITI ──
      _BadgeData(
        emoji: '❤️',
        name: 'Prima Scintilla',
        description: 'Salva la tua prima posizione preferita',
        isUnlocked: favoritesCount >= 1,
        progress: '${favoritesCount.clamp(0, 1)}/1',
      ),
      _BadgeData(
        emoji: '💕',
        name: 'Romantico',
        description: 'Salva 5 posizioni nei preferiti',
        isUnlocked: favoritesCount >= 5,
        progress: '${favoritesCount.clamp(0, 5)}/5',
      ),
      _BadgeData(
        emoji: '💝',
        name: 'Cuore Grande',
        description: 'Salva 10 posizioni nei preferiti',
        isUnlocked: favoritesCount >= 10,
        progress: '${favoritesCount.clamp(0, 10)}/10',
      ),
      _BadgeData(
        emoji: '💖',
        name: 'Collezionista di Cuori',
        description: 'Salva 20 posizioni nei preferiti',
        isUnlocked: favoritesCount >= 20,
        progress: '${favoritesCount.clamp(0, 20)}/20',
      ),

      // ── SERIE ──
      _BadgeData(
        emoji: '📅',
        name: 'Terzo Giorno',
        description: 'Raggiungi una serie di 3 giorni',
        isUnlocked: streak >= 3,
        progress: '${streak.clamp(0, 3)}/3',
      ),
      _BadgeData(
        emoji: '🔥',
        name: 'Dedicato',
        description: 'Raggiungi una serie di 7 giorni',
        isUnlocked: streak >= 7,
        progress: '${streak.clamp(0, 7)}/7',
      ),
      _BadgeData(
        emoji: '⚡',
        name: 'Momentum',
        description: 'Raggiungi una serie di 14 giorni',
        isUnlocked: streak >= 14,
        progress: '${streak.clamp(0, 14)}/14',
      ),
      _BadgeData(
        emoji: '🏆',
        name: 'Campione',
        description: 'Raggiungi una serie di 30 giorni',
        isUnlocked: streak >= 30,
        progress: '${streak.clamp(0, 30)}/30',
      ),
      _BadgeData(
        emoji: '🌙',
        name: 'Fedele',
        description: 'Raggiungi una serie di 60 giorni',
        isUnlocked: streak >= 60,
        progress: '${streak.clamp(0, 60)}/60',
      ),
      _BadgeData(
        emoji: '☀️',
        name: 'Irresistibile',
        description: 'Raggiungi una serie di 100 giorni',
        isUnlocked: streak >= 100,
        progress: '${streak.clamp(0, 100)}/100',
      ),
      _BadgeData(
        emoji: '✨',
        name: 'In Serie Ora',
        description: 'Hai una serie attiva di almeno 3 giorni',
        isUnlocked: currentStreak >= 3,
        progress: '$currentStreak giorni',
      ),

      // ── GIOCHI ──
      _BadgeData(
        emoji: '🎮',
        name: 'Primo Gioco',
        description: 'Completa la tua prima sessione shuffle',
        isUnlocked: gamesPlayed >= 1,
        progress: '${gamesPlayed.clamp(0, 1)}/1',
      ),
      _BadgeData(
        emoji: '🃏',
        name: 'Giocatore',
        description: 'Completa 5 sessioni shuffle',
        isUnlocked: gamesPlayed >= 5,
        progress: '${gamesPlayed.clamp(0, 5)}/5',
      ),
      _BadgeData(
        emoji: '💞',
        name: 'Esploratori dell\'Anima',
        description: 'Completa 10 sessioni shuffle',
        isUnlocked: gamesPlayed >= 10,
        progress: '${gamesPlayed.clamp(0, 10)}/10',
      ),
      _BadgeData(
        emoji: '🎯',
        name: 'Esperto dei Giochi',
        description: 'Completa 25 sessioni shuffle',
        isUnlocked: gamesPlayed >= 25,
        progress: '${gamesPlayed.clamp(0, 25)}/25',
      ),
      _BadgeData(
        emoji: '🏅',
        name: 'Professionista',
        description: 'Completa 50 sessioni shuffle',
        isUnlocked: gamesPlayed >= 50,
        progress: '${gamesPlayed.clamp(0, 50)}/50',
      ),

      // ── CATEGORIE ──
      _BadgeData(
        emoji: '🌍',
        name: 'Esploratore Mondiale',
        description: 'Prova posizioni di 3 categorie diverse',
        isUnlocked: uniqueCategories.length >= 3,
        progress: '${uniqueCategories.length.clamp(0, 3)}/3',
      ),
      _BadgeData(
        emoji: '🌈',
        name: 'Versatile',
        description: 'Prova posizioni di 5 categorie diverse',
        isUnlocked: uniqueCategories.length >= 5,
        progress: '${uniqueCategories.length.clamp(0, 5)}/5',
      ),
      _BadgeData(
        emoji: '🎨',
        name: 'Artista Completo',
        description: 'Prova posizioni di tutte le categorie',
        isUnlocked: uniqueCategories.length >= totalCategories,
        progress: '${uniqueCategories.length.clamp(0, totalCategories)}/$totalCategories',
      ),

      // ── SFIDA ──
      _BadgeData(
        emoji: '💪',
        name: 'Coraggioso',
        description: 'Prova 5 posizioni di difficoltà alta (4-5⭐)',
        isUnlocked: highDiffCount >= 5,
        progress: '${highDiffCount.clamp(0, 5)}/5',
      ),
      _BadgeData(
        emoji: '🦸',
        name: 'Acrobata',
        description: 'Prova 15 posizioni di difficoltà alta (4-5⭐)',
        isUnlocked: highDiffCount >= 15,
        progress: '${highDiffCount.clamp(0, 15)}/15',
      ),

      // ── TEMPO INSIEME ──
      _BadgeData(
        emoji: '⏱️',
        name: 'Prima Ora',
        description: 'Trascorri 60 minuti insieme nell\'app',
        isUnlocked: timeMins >= 60,
        progress: '${timeMins.clamp(0, 60)}/60 min',
      ),
      _BadgeData(
        emoji: '🕐',
        name: 'Amanti del Tempo',
        description: 'Trascorri 5 ore insieme nell\'app',
        isUnlocked: timeMins >= 300,
        progress: '${timeMins.clamp(0, 300)}/300 min',
      ),
      _BadgeData(
        emoji: '🌅',
        name: 'Connessione Profonda',
        description: 'Trascorri 24 ore insieme nell\'app',
        isUnlocked: timeMins >= 1440,
        progress: '${timeMins.clamp(0, 1440)}/1440 min',
      ),

      // ── ESPLORAZIONE AVANZATA ──
      _BadgeData(
        emoji: '🌠',
        name: 'Sommità',
        description: 'Prova 250 posizioni diverse',
        isUnlocked: triedCount >= 250,
        progress: '${triedCount.clamp(0, 250)}/250',
      ),
      _BadgeData(
        emoji: '🎆',
        name: 'Olimpionico',
        description: 'Prova 300 posizioni diverse',
        isUnlocked: triedCount >= 300,
        progress: '${triedCount.clamp(0, 300)}/300',
      ),

      // ── PREFERITI AVANZATI ──
      _BadgeData(
        emoji: '💟',
        name: 'Grande Collezione',
        description: 'Salva 30 posizioni nei preferiti',
        isUnlocked: favoritesCount >= 30,
        progress: '${favoritesCount.clamp(0, 30)}/30',
      ),
      _BadgeData(
        emoji: '🏰',
        name: 'Castello d\'Amore',
        description: 'Salva 50 posizioni nei preferiti',
        isUnlocked: favoritesCount >= 50,
        progress: '${favoritesCount.clamp(0, 50)}/50',
      ),

      // ── SERIE AVANZATE ──
      _BadgeData(
        emoji: '🌞',
        name: 'Invincibile',
        description: 'Raggiungi una serie di 150 giorni',
        isUnlocked: streak >= 150,
        progress: '${streak.clamp(0, 150)}/150',
      ),
      _BadgeData(
        emoji: '🌌',
        name: 'Infinito',
        description: 'Raggiungi una serie di 200 giorni',
        isUnlocked: streak >= 200,
        progress: '${streak.clamp(0, 200)}/200',
      ),
      _BadgeData(
        emoji: '📆',
        name: 'Anno Insieme',
        description: 'Raggiungi una serie di 365 giorni',
        isUnlocked: streak >= 365,
        progress: '${streak.clamp(0, 365)}/365',
      ),

      // ── GIOCHI AVANZATI ──
      _BadgeData(
        emoji: '🎲',
        name: 'Gran Giocatore',
        description: 'Completa 75 sessioni shuffle',
        isUnlocked: gamesPlayed >= 75,
        progress: '${gamesPlayed.clamp(0, 75)}/75',
      ),
      _BadgeData(
        emoji: '🥇',
        name: 'Campione dei Giochi',
        description: 'Completa 100 sessioni shuffle',
        isUnlocked: gamesPlayed >= 100,
        progress: '${gamesPlayed.clamp(0, 100)}/100',
      ),
      _BadgeData(
        emoji: '🎪',
        name: 'Maestro dei Giochi',
        description: 'Completa 150 sessioni shuffle',
        isUnlocked: gamesPlayed >= 150,
        progress: '${gamesPlayed.clamp(0, 150)}/150',
      ),
      _BadgeData(
        emoji: '🎉',
        name: 'Leggenda dei Giochi',
        description: 'Completa 200 sessioni shuffle',
        isUnlocked: gamesPlayed >= 200,
        progress: '${gamesPlayed.clamp(0, 200)}/200',
      ),

      // ── SFIDA AVANZATA ──
      _BadgeData(
        emoji: '⚔️',
        name: 'Guerriero',
        description: 'Prova 25 posizioni di difficoltà alta (4-5⭐)',
        isUnlocked: highDiffCount >= 25,
        progress: '${highDiffCount.clamp(0, 25)}/25',
      ),
      _BadgeData(
        emoji: '🦅',
        name: 'Aquila',
        description: 'Prova 30 posizioni di difficoltà alta (4-5⭐)',
        isUnlocked: highDiffCount >= 30,
        progress: '${highDiffCount.clamp(0, 30)}/30',
      ),
      _BadgeData(
        emoji: '🎭',
        name: 'Estremo',
        description: 'Prova 3 posizioni di difficoltà massima (5⭐)',
        isUnlocked: veryHighDiffCount >= 3,
        progress: '${veryHighDiffCount.clamp(0, 3)}/3',
      ),
      _BadgeData(
        emoji: '🦁',
        name: 'Ultras',
        description: 'Prova 10 posizioni di difficoltà massima (5⭐)',
        isUnlocked: veryHighDiffCount >= 10,
        progress: '${veryHighDiffCount.clamp(0, 10)}/10',
      ),

      // ── TEMPO INSIEME AVANZATO ──
      _BadgeData(
        emoji: '🌊',
        name: 'Oceano di Tempo',
        description: 'Trascorri 10 ore insieme nell\'app',
        isUnlocked: timeMins >= 600,
        progress: '${timeMins.clamp(0, 600)}/600 min',
      ),
      _BadgeData(
        emoji: '🌃',
        name: 'Notte Senza Fine',
        description: 'Trascorri 48 ore insieme nell\'app',
        isUnlocked: timeMins >= 2880,
        progress: '${timeMins.clamp(0, 2880)}/2880 min',
      ),
      _BadgeData(
        emoji: '☄️',
        name: 'Un Viaggio',
        description: 'Trascorri 100 ore insieme nell\'app',
        isUnlocked: timeMins >= 6000,
        progress: '${timeMins.clamp(0, 6000)}/6000 min',
      ),

      // ── CATEGORIE SPECIFICHE ──
      _BadgeData(
        emoji: '🌹',
        name: 'Cuore Romantico',
        description: 'Prova 5 posizioni dalla categoria Romantica',
        isUnlocked: (categoryTriedCount['romantic'] ?? 0) >= 5,
        progress: '${(categoryTriedCount['romantic'] ?? 0).clamp(0, 5)}/5',
      ),
      _BadgeData(
        emoji: '🌿',
        name: 'Esperto Principiante',
        description: 'Prova 5 posizioni dalla categoria Principiante',
        isUnlocked: (categoryTriedCount['beginner'] ?? 0) >= 5,
        progress: '${(categoryTriedCount['beginner'] ?? 0).clamp(0, 5)}/5',
      ),
      _BadgeData(
        emoji: '🏋️',
        name: 'Atleta Passionale',
        description: 'Prova 5 posizioni dalla categoria Atletica',
        isUnlocked: (categoryTriedCount['athletic'] ?? 0) >= 5,
        progress: '${(categoryTriedCount['athletic'] ?? 0).clamp(0, 5)}/5',
      ),
      _BadgeData(
        emoji: '🤝',
        name: 'Coppia Sostenuta',
        description: 'Prova 5 posizioni dalla categoria Sorretta',
        isUnlocked: (categoryTriedCount['supported'] ?? 0) >= 5,
        progress: '${(categoryTriedCount['supported'] ?? 0).clamp(0, 5)}/5',
      ),
      _BadgeData(
        emoji: '🦋',
        name: 'Tocco Leggero',
        description: 'Prova 5 posizioni dalla categoria Delicata',
        isUnlocked: (categoryTriedCount['lowImpact'] ?? 0) >= 5,
        progress: '${(categoryTriedCount['lowImpact'] ?? 0).clamp(0, 5)}/5',
      ),
      _BadgeData(
        emoji: '🗺️',
        name: 'Spirito Avventuroso',
        description: 'Prova 5 posizioni dalla categoria Avventurosa',
        isUnlocked: (categoryTriedCount['adventurous'] ?? 0) >= 5,
        progress: '${(categoryTriedCount['adventurous'] ?? 0).clamp(0, 5)}/5',
      ),
      _BadgeData(
        emoji: '🔗',
        name: 'Legami Ritrovati',
        description: 'Prova 5 posizioni dalla categoria Riconnessione',
        isUnlocked: (categoryTriedCount['reconnect'] ?? 0) >= 5,
        progress: '${(categoryTriedCount['reconnect'] ?? 0).clamp(0, 5)}/5',
      ),
      _BadgeData(
        emoji: '⚡',
        name: 'Velocità Estrema',
        description: 'Prova 5 posizioni dalla categoria Quickie',
        isUnlocked: (categoryTriedCount['quickie'] ?? 0) >= 5,
        progress: '${(categoryTriedCount['quickie'] ?? 0).clamp(0, 5)}/5',
      ),

      // ── DIVERSITÀ ──
      _BadgeData(
        emoji: '🌬️',
        name: 'Calma e Relax',
        description: 'Prova 5 posizioni a bassa energia',
        isUnlocked: lowEnergyCount >= 5,
        progress: '${lowEnergyCount.clamp(0, 5)}/5',
      ),
      _BadgeData(
        emoji: '💥',
        name: 'Alta Energia',
        description: 'Prova 5 posizioni ad alta energia',
        isUnlocked: highEnergyCount >= 5,
        progress: '${highEnergyCount.clamp(0, 5)}/5',
      ),
      _BadgeData(
        emoji: '🐢',
        name: 'Prenditi il Tempo',
        description: 'Prova 3 posizioni a lunga durata',
        isUnlocked: longDurationCount >= 3,
        progress: '${longDurationCount.clamp(0, 3)}/3',
      ),
      _BadgeData(
        emoji: '🔭',
        name: 'Focus Completo',
        description: 'Prova posizioni che coprono tutti i 7 tipi di focus',
        isUnlocked: triedFocusTypes.length >= totalFocusTypes,
        progress: '${triedFocusTypes.length.clamp(0, totalFocusTypes)}/$totalFocusTypes',
      ),
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 0.8,
      ),
      itemCount: badges.length,
      itemBuilder: (context, index) {
        final badge = badges[index];
        return _buildBadgeCard(badge);
      },
    );
  }

  Widget _buildBadgeCard(_BadgeData badge) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Row(
              children: [
                Text(
                  badge.isUnlocked ? badge.emoji : '🔒',
                  style: const TextStyle(fontSize: 28),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    badge.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(badge.description),
                const SizedBox(height: 8),
                Text(
                  'Progresso: ${badge.progress}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                if (!badge.isUnlocked) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Continua a esplorare per sbloccare!',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: badge.isUnlocked
              ? Theme.of(context).colorScheme.surface
              : Theme.of(context).colorScheme.surface.withOpacity(0.4),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: badge.isUnlocked
                ? AppColors.gold.withOpacity(0.5)
                : Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              badge.isUnlocked ? badge.emoji : '🔒',
              style: const TextStyle(fontSize: 36),
            ),
            const SizedBox(height: 8),
            Text(
              badge.name,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: badge.isUnlocked
                        ? null
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.4),
                  ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // STATISTICS TAB — dati reali da zero
  // ============================================================

  Widget _buildStatisticsTab() {
    final prefs = PreferencesService.instance;
    final repo = ref.read(positionRepositoryProvider);

    // Dati reali
    final triedCount = prefs.triedPositionIds.length;
    final gamesPlayed = prefs.gamesPlayed;
    final timeTogether = prefs.formattedTimeTogether;
    final favoritesCount = repo.positions.where((p) => p.isFavorite).length;

    // Categorie esplorate
    final triedIds = prefs.triedPositionIds;
    final Map<String, int> categoryCount = {};
    int totalTried = 0;

    for (final id in triedIds) {
      final position = repo.getById(id);
      if (position != null) {
        for (final cat in position.categories) {
          categoryCount[cat.name] = (categoryCount[cat.name] ?? 0) + 1;
        }
        totalTried++;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          _buildStatRow(
            icon: Icons.explore,
            label: 'Posizioni esplorate',
            value: '$triedCount',
            color: AppColors.burgundy,
          ),
          _buildStatRow(
            icon: Icons.casino,
            label: 'Partite giocate',
            value: '$gamesPlayed',
            color: AppColors.gold,
          ),
          _buildStatRow(
            icon: Icons.timer,
            label: 'Tempo insieme',
            value: timeTogether,
            color: AppColors.navy,
          ),
          _buildStatRow(
            icon: Icons.favorite,
            label: 'Preferiti salvati',
            value: '$favoritesCount',
            color: AppColors.blush,
          ),
          
          const SizedBox(height: AppSpacing.xl),
          
          // Categorie esplorate
          Text(
            'Categorie esplorate',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.md),

          if (categoryCount.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                'Inizia a esplorare per vedere le tue statistiche!',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.5),
                    ),
                textAlign: TextAlign.center,
              ),
            )
          else
            ...categoryCount.entries.map((entry) {
              final percentage = totalTried > 0
                  ? (entry.value / totalTried)
                  : 0.0;
              return _buildCategoryProgress(
                'categories.${entry.key}'.tr(),
                percentage,
                AppColors.burgundy,
              );
            }),
        ],
      ),
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryProgress(String category, double progress, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(category, style: Theme.of(context).textTheme.bodySmall),
              Text(
                '${(progress * 100).round()}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HISTORY TAB (Provate) — già funzionante con dati reali
  // ============================================================

  Widget _buildHistoryTab() {
    final locale = context.locale.languageCode;
    final triedIds = PreferencesService.instance.triedPositionIds;
    final repo = PositionRepository.instance;

    if (triedIds.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.explore_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Nessuna posizione provata ancora',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Esplora il catalogo o gioca allo shuffle per aggiungere posizioni!',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.4),
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: triedIds.length,
      itemBuilder: (context, index) {
        final positionId = triedIds[triedIds.length - 1 - index];
        final position = repo.getById(positionId);

        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            children: [
              const Text('✅', style: TextStyle(fontSize: 24)),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      position?.getName(locale) ?? positionId,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    if (position?.getAlias(locale) != null)
                      Text(
                        position!.getAlias(locale)!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6),
                              fontStyle: FontStyle.italic,
                            ),
                      ),
                  ],
                ),
              ),
              if (position != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(5, (i) {
                    return Icon(
                      Icons.star,
                      size: 12,
                      color: i < position.difficulty
                          ? AppColors.gold
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.2),
                    );
                  }),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================
// Helper class per i badge
// ============================================================

class _BadgeData {
  final String emoji;
  final String name;
  final String description;
  final bool isUnlocked;
  final String progress;

  const _BadgeData({
    required this.emoji,
    required this.name,
    required this.description,
    required this.isUnlocked,
    required this.progress,
  });
}