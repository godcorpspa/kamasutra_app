import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/position.dart';
import '../models/game.dart';
import '../models/goose_game.dart';
import '../repositories/position_repository.dart';
import '../local/database_service.dart';
import '../local/preferences_service.dart';

// ============================================================
// Position Providers
// ============================================================

/// Provider for the position repository
final positionRepositoryProvider = Provider<PositionRepository>((ref) {
  return PositionRepository.instance;
});

/// Provider for all positions (loads from JSON on first access)
final positionsProvider = FutureProvider.family<List<Position>, String>((ref, locale) async {
  final repo = ref.watch(positionRepositoryProvider);
  return repo.loadPositions(locale);
});

/// Current position filter state
final positionFilterProvider = StateNotifierProvider<PositionFilterNotifier, PositionFilter>((ref) {
  return PositionFilterNotifier();
});

class PositionFilterNotifier extends StateNotifier<PositionFilter> {
  PositionFilterNotifier() : super(const PositionFilter());

  void setCategories(List<PositionCategory>? categories) {
    state = state.copyWith(categories: categories);
  }

  void setDifficultyRange(int? min, int? max) {
    state = state.copyWith(minDifficulty: min, maxDifficulty: max);
  }

  void setEnergy(EnergyLevel? energy) {
    state = state.copyWith(energyLevels: energy != null ? [energy] : null);
  }

  void setFocus(List<PositionFocus>? focus) {
    state = state.copyWith(focus: focus);
  }

  void setDuration(PositionDuration? duration) {
    state = state.copyWith(durations: duration != null ? [duration] : null);
  }

  void setFavoritesOnly(bool value) {
    state = state.copyWith(favoritesOnly: value);
  }

  void setSearchQuery(String? query) {
    state = state.copyWith(searchQuery: query);
  }

  void clear() {
    state = const PositionFilter();
  }
}

/// Filtered positions based on current filter
final filteredPositionsProvider = Provider.family<List<Position>, String>((ref, locale) {
  final positionsAsync = ref.watch(positionsProvider(locale));
  final filter = ref.watch(positionFilterProvider);
  
  return positionsAsync.maybeWhen(
    data: (positions) => filter.apply(positions),
    orElse: () => [],
  );
});

/// Favorite positions
final favoritePositionsProvider = Provider.family<List<Position>, String>((ref, locale) {
  final positionsAsync = ref.watch(positionsProvider(locale));
  
  return positionsAsync.maybeWhen(
    data: (positions) => positions.where((p) => p.isFavorite).toList(),
    orElse: () => [],
  );
});

/// Provider to toggle favorite status
final toggleFavoriteProvider = FutureProvider.family<bool, String>((ref, positionId) async {
  final repo = ref.watch(positionRepositoryProvider);
  return repo.toggleFavorite(positionId);
});

// ============================================================
// Shuffle Session Providers
// ============================================================

/// Current shuffle session state
final shuffleSessionProvider = StateNotifierProvider<ShuffleSessionNotifier, ShuffleSession?>((ref) {
  return ShuffleSessionNotifier(ref);
});

class ShuffleSession {
  final List<Position> positions;
  final int currentIndex;
  final bool isComplete;
  final String? sessionId;

  ShuffleSession({
    required this.positions,
    this.currentIndex = 0,
    this.isComplete = false,
    this.sessionId,
  });

  Position? get currentPosition => 
      positions.isNotEmpty && currentIndex < positions.length
          ? positions[currentIndex]
          : null;

  bool get hasNext => currentIndex < positions.length - 1;
  bool get hasPrevious => currentIndex > 0;

  ShuffleSession copyWith({
    List<Position>? positions,
    int? currentIndex,
    bool? isComplete,
    String? sessionId,
  }) {
    return ShuffleSession(
      positions: positions ?? this.positions,
      currentIndex: currentIndex ?? this.currentIndex,
      isComplete: isComplete ?? this.isComplete,
      sessionId: sessionId ?? this.sessionId,
    );
  }
}

class ShuffleSessionNotifier extends StateNotifier<ShuffleSession?> {
  final Ref _ref;
  
  ShuffleSessionNotifier(this._ref) : super(null);

  /// Start a new shuffle session
  Future<void> startSession({
    required List<Position> positions,
    PositionFilter? filter,
  }) async {
    if (positions.isEmpty) return;
    
    final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
    
    // Save session to database
    final session = Session(
      id: sessionId,
      type: SessionType.shuffle,
      startedAt: DateTime.now(),
      filters: filter?.toJson(),
      positionIds: positions.map((p) => p.id).toList(),
      currentIndex: 0,
      completed: false,
    );
    await DatabaseService.instance.saveSession(session.toJson());
    
    state = ShuffleSession(
      positions: positions,
      currentIndex: 0,
      sessionId: sessionId,
    );
  }

  /// Move to next position
  void next() {
    if (state == null || !state!.hasNext) return;
    state = state!.copyWith(currentIndex: state!.currentIndex + 1);
    _updateSessionInDb();
  }

  /// Move to previous position
  void previous() {
    if (state == null || !state!.hasPrevious) return;
    state = state!.copyWith(currentIndex: state!.currentIndex - 1);
    _updateSessionInDb();
  }

  /// Go to a specific position
  void goTo(int index) {
    if (state == null) return;
    if (index < 0 || index >= state!.positions.length) return;
    state = state!.copyWith(currentIndex: index);
    _updateSessionInDb();
  }

  /// Mark current position as viewed with reaction
  Future<void> recordReaction(PositionReaction reaction, {String? notes}) async {
    if (state?.currentPosition == null) return;
    
    final repo = _ref.read(positionRepositoryProvider);
    await repo.recordView(state!.currentPosition!.id);
    
    final entry = HistoryEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      positionId: state!.currentPosition!.id,
      viewedAt: DateTime.now(),
      reaction: reaction.name,
      notes: notes,
    );
    await DatabaseService.instance.addHistoryEntry(entry.toJson());
  }

  /// Complete the session
  Future<void> completeSession() async {
    if (state == null) return;
    
    state = state!.copyWith(isComplete: true);
    
    if (state!.sessionId != null) {
      final session = Session(
        id: state!.sessionId!,
        type: SessionType.shuffle,
        startedAt: DateTime.now(),
        endedAt: DateTime.now(),
        positionIds: state!.positions.map((p) => p.id).toList(),
        currentIndex: state!.currentIndex,
        completed: true,
      );
      await DatabaseService.instance.saveSession(session.toJson());
    }
  }

  /// End and clear session
  void endSession() {
    state = null;
  }

  Future<void> _updateSessionInDb() async {
    if (state?.sessionId == null) return;
    
    final session = Session(
      id: state!.sessionId!,
      type: SessionType.shuffle,
      startedAt: DateTime.now(),
      positionIds: state!.positions.map((p) => p.id).toList(),
      currentIndex: state!.currentIndex,
      completed: false,
    );
    await DatabaseService.instance.saveSession(session.toJson());
  }
}

// ============================================================
// Game Providers
// ============================================================

/// Provider for available games
final gamesProvider = Provider<List<MiniGame>>((ref) {
  return [
    MiniGame(
      id: 'goose',
      type: GameType.gooseGame,
      nameIt: 'Gioco dell\'Oca Piccante',
      nameEn: 'Spicy Goose Game',
      descriptionIt: 'Il classico gioco dell\'oca rivisitato per coppie',
      descriptionEn: 'The classic goose game reimagined for couples',
      rulesIt: 'Tira il dado, avanza sulla casella e segui le istruzioni. '
          'Caselle speciali offrono sfide, verità o bonus. '
          'Vince chi raggiunge il traguardo per primo!',
      rulesEn: 'Roll the dice, advance to the square and follow instructions. '
          'Special squares offer challenges, truths or bonuses. '
          'First to reach the finish wins!',
      minPlayers: 2,
      maxPlayers: 2,
      durationMinutes: 30,
      availableIntensities: [GameIntensity.soft, GameIntensity.spicy, GameIntensity.extraSpicy],
      iconRef: 'goose',
      isUnlocked: true,
    ),
    MiniGame(
      id: 'truth_dare',
      type: GameType.truthDare,
      nameIt: 'Verità o Sfida',
      nameEn: 'Truth or Dare',
      descriptionIt: 'Sfide e confessioni per scoprirsi di più',
      descriptionEn: 'Challenges and confessions to discover more',
      rulesIt: 'A turno scegliete verità o sfida. '
          'Rispondete sinceramente o completate la sfida!',
      rulesEn: 'Take turns choosing truth or dare. '
          'Answer honestly or complete the challenge!',
      minPlayers: 2,
      maxPlayers: 2,
      durationMinutes: 20,
      availableIntensities: [GameIntensity.soft, GameIntensity.spicy, GameIntensity.extraSpicy],
      iconRef: 'truth_dare',
      isUnlocked: true,
    ),
    MiniGame(
      id: 'wheel',
      type: GameType.wheel,
      nameIt: 'Ruota del Destino',
      nameEn: 'Wheel of Fortune',
      descriptionIt: 'Gira la ruota e lasciati sorprendere',
      descriptionEn: 'Spin the wheel and let yourself be surprised',
      rulesIt: 'Girate la ruota insieme e scoprite cosa il destino ha in serbo per voi!',
      rulesEn: 'Spin the wheel together and discover what fate has in store!',
      minPlayers: 2,
      maxPlayers: 2,
      durationMinutes: 15,
      availableIntensities: [GameIntensity.soft, GameIntensity.spicy, GameIntensity.extraSpicy],
      iconRef: 'wheel',
      isUnlocked: true,
    ),
    MiniGame(
      id: 'hot_cold',
      type: GameType.hotCold,
      nameIt: 'Caldo o Freddo',
      nameEn: 'Hot or Cold',
      descriptionIt: 'Scopri cosa piace al partner con un gioco sensoriale',
      descriptionEn: 'Discover what your partner likes with a sensory game',
      rulesIt: 'Un partner guida, l\'altro esplora. '
          'Sussurrate "caldo" o "freddo" per guidare verso il punto perfetto!',
      rulesEn: 'One partner guides, the other explores. '
          'Whisper "hot" or "cold" to guide toward the perfect spot!',
      minPlayers: 2,
      maxPlayers: 2,
      durationMinutes: 15,
      availableIntensities: [GameIntensity.soft, GameIntensity.spicy, GameIntensity.extraSpicy],
      iconRef: 'hot_cold',
      isUnlocked: true,
    ),
    MiniGame(
      id: 'love_notes',
      type: GameType.loveNotes,
      nameIt: 'Bigliettini Segreti',
      nameEn: 'Secret Love Notes',
      descriptionIt: 'Scrivete messaggi anonimi da rivelare insieme',
      descriptionEn: 'Write anonymous messages to reveal together',
      rulesIt: 'Entrambi scrivete un messaggio segreto sullo stesso tema. '
          'Poi rivelateli insieme e scoprite quanto vi conoscete!',
      rulesEn: 'Both write a secret message on the same theme. '
          'Then reveal them together and discover how well you know each other!',
      minPlayers: 2,
      maxPlayers: 2,
      durationMinutes: 15,
      availableIntensities: [GameIntensity.soft, GameIntensity.spicy],
      iconRef: 'love_notes',
      isUnlocked: true,
    ),
    MiniGame(
      id: 'fantasy_builder',
      type: GameType.fantasyBuilder,
      nameIt: 'Costruttore di Fantasie',
      nameEn: 'Fantasy Builder',
      descriptionIt: 'Create insieme uno scenario romantico passo dopo passo',
      descriptionEn: 'Build a romantic scenario together step by step',
      rulesIt: 'A turno aggiungete elementi a una fantasia condivisa. '
          'Luogo, ambientazione, azioni... costruite insieme il momento perfetto!',
      rulesEn: 'Take turns adding elements to a shared fantasy. '
          'Place, setting, actions... build the perfect moment together!',
      minPlayers: 2,
      maxPlayers: 2,
      durationMinutes: 20,
      availableIntensities: [GameIntensity.soft, GameIntensity.spicy, GameIntensity.extraSpicy],
      iconRef: 'fantasy',
      isUnlocked: true,
    ),
    MiniGame(
      id: 'compliment_battle',
      type: GameType.complimentBattle,
      nameIt: 'Battaglia di Complimenti',
      nameEn: 'Compliment Battle',
      descriptionIt: 'Chi riesce a far arrossire l\'altro per primo?',
      descriptionEn: 'Who can make the other blush first?',
      rulesIt: 'A turno fatevi i complimenti più sinceri e creativi. '
          'Chi fa arrossire l\'altro guadagna un punto!',
      rulesEn: 'Take turns giving the most sincere and creative compliments. '
          'Make your partner blush and earn a point!',
      minPlayers: 2,
      maxPlayers: 2,
      durationMinutes: 10,
      availableIntensities: [GameIntensity.soft],
      iconRef: 'compliment',
      isUnlocked: true,
    ),
    MiniGame(
      id: 'question_quest',
      type: GameType.questionQuest,
      nameIt: 'Missione Domande',
      nameEn: 'Question Quest',
      descriptionIt: 'Domande sempre più profonde per conoscervi meglio',
      descriptionEn: 'Increasingly deep questions to know each other better',
      rulesIt: 'Rispondete insieme a domande che vanno dal leggero al profondo. '
          'Scoprite nuovi lati del vostro partner!',
      rulesEn: 'Answer questions together that go from light to deep. '
          'Discover new sides of your partner!',
      minPlayers: 2,
      maxPlayers: 2,
      durationMinutes: 25,
      availableIntensities: [GameIntensity.soft, GameIntensity.spicy],
      iconRef: 'question',
      isUnlocked: true,
    ),
    MiniGame(
      id: 'two_minutes',
      type: GameType.twoMinutes,
      nameIt: '2 Minuti di Cielo',
      nameEn: '2 Minutes in Heaven',
      descriptionIt: 'Timer sfidante per azioni romantiche',
      descriptionEn: 'Challenging timer for romantic actions',
      rulesIt: 'Pescate una carta e avete esattamente 2 minuti '
          'per completare l\'azione descritta!',
      rulesEn: 'Draw a card and you have exactly 2 minutes '
          'to complete the action described!',
      minPlayers: 2,
      maxPlayers: 2,
      durationMinutes: 15,
      availableIntensities: [GameIntensity.soft, GameIntensity.spicy, GameIntensity.extraSpicy],
      iconRef: 'timer',
      isUnlocked: true,
    ),
    MiniGame(
      id: 'intimacy_map',
      type: GameType.intimacyMap,
      nameIt: 'Mappa dell\'Intimità',
      nameEn: 'Intimacy Map',
      descriptionIt: 'Mappate insieme le zone di piacere',
      descriptionEn: 'Map the pleasure zones together',
      rulesIt: 'Create insieme una mappa delle preferenze. '
          'Segnate cosa vi piace, cosa vorreste provare, cosa evitare.',
      rulesEn: 'Create a preferences map together. '
          'Mark what you like, what you\'d like to try, what to avoid.',
      minPlayers: 2,
      maxPlayers: 2,
      durationMinutes: 30,
      availableIntensities: [GameIntensity.soft, GameIntensity.spicy],
      iconRef: 'map',
      isUnlocked: true,
    ),
    MiniGame(
      id: 'soundtrack',
      type: GameType.soundtrack,
      nameIt: 'La Nostra Colonna Sonora',
      nameEn: 'Our Soundtrack',
      descriptionIt: 'Create la playlist perfetta per la serata',
      descriptionEn: 'Create the perfect playlist for the evening',
      rulesIt: 'A turno scegliete canzoni che rappresentano momenti, '
          'emozioni o desideri da condividere.',
      rulesEn: 'Take turns choosing songs that represent moments, '
          'emotions or desires to share.',
      minPlayers: 2,
      maxPlayers: 2,
      durationMinutes: 20,
      availableIntensities: [GameIntensity.soft],
      iconRef: 'music',
      isUnlocked: true,
    ),
    MiniGame(
      id: 'mirror',
      type: GameType.mirrorChallenge,
      nameIt: 'Sfida allo Specchio',
      nameEn: 'Mirror Challenge',
      descriptionIt: 'Guardarsi negli occhi senza distogliere lo sguardo',
      descriptionEn: 'Look into each other\'s eyes without looking away',
      rulesIt: 'Seduti uno di fronte all\'altro, guardate negli occhi del partner. '
          'Seguite le istruzioni senza distogliere lo sguardo!',
      rulesEn: 'Sitting face to face, look into your partner\'s eyes. '
          'Follow the instructions without looking away!',
      minPlayers: 2,
      maxPlayers: 2,
      durationMinutes: 15,
      availableIntensities: [GameIntensity.soft, GameIntensity.spicy],
      iconRef: 'mirror',
      isUnlocked: true,
    ),
  ];
});

/// Current selected game
final currentGameProvider = StateProvider<MiniGame?>((ref) => null);

/// Goose game state provider
final gooseGameProvider = StateNotifierProvider<GooseGameNotifier, GooseGameState?>((ref) {
  return GooseGameNotifier();
});

class GooseGameNotifier extends StateNotifier<GooseGameState?> {
  GooseGameNotifier() : super(null);

  /// Start a new goose game
  void startGame(GooseGameConfig config) {
    final board = _generateBoard(config.boardSize, config.excludedSquareTypes);
    
    state = GooseGameState(
      config: config,
      board: board,
      player1Position: 0,
      player2Position: 0,
      currentPlayer: 1,
      startedAt: DateTime.now(),
    );
  }

  List<GooseSquare> _generateBoard(GooseBoardSize size, List<GooseSquareType> excluded) {
    final totalSquares = size.totalSquares;
    final board = <GooseSquare>[];
    
    // Start square
    board.add(const GooseSquare(position: 0, type: GooseSquareType.normal));
    
    // Generate middle squares
    for (var i = 1; i < totalSquares - 1; i++) {
      GooseSquareType type;
      
      // Special squares at specific positions
      if (i == 6 && !excluded.contains(GooseSquareType.bridge)) {
        type = GooseSquareType.bridge;
      } else if (i == totalSquares ~/ 3 && !excluded.contains(GooseSquareType.well)) {
        type = GooseSquareType.well;
      } else if (i == totalSquares ~/ 2 && !excluded.contains(GooseSquareType.labyrinth)) {
        type = GooseSquareType.labyrinth;
      } else if (i == (totalSquares * 2 ~/ 3) && !excluded.contains(GooseSquareType.inn)) {
        type = GooseSquareType.inn;
      } else if (i % 9 == 0 && !excluded.contains(GooseSquareType.goose)) {
        type = GooseSquareType.goose;
      } else if (i % 7 == 0 && !excluded.contains(GooseSquareType.challenge)) {
        type = GooseSquareType.challenge;
      } else if (i % 11 == 0 && !excluded.contains(GooseSquareType.truth)) {
        type = GooseSquareType.truth;
      } else if (i % 13 == 0 && !excluded.contains(GooseSquareType.bonus)) {
        type = GooseSquareType.bonus;
      } else if (i % 15 == 0 && !excluded.contains(GooseSquareType.couple)) {
        type = GooseSquareType.couple;
      } else {
        type = GooseSquareType.normal;
      }
      
      board.add(GooseSquare(position: i, type: type));
    }
    
    // Finish square
    board.add(GooseSquare(position: totalSquares - 1, type: GooseSquareType.finish));
    
    return board;
  }

  /// Roll dice and move current player
  int rollDice() {
    if (state == null) return 0;
    
    final useRigged = state!.config.useRiggedDice;
    final roll = useRigged
        ? (DateTime.now().millisecond % 3) + 3 // 3-5
        : (DateTime.now().millisecond % 6) + 1; // 1-6
    
    state = state!.copyWith(lastDiceRoll: roll);
    return roll;
  }

  /// Move the current player
  void movePlayer(int spaces) {
    if (state == null) return;
    
    final currentPos = state!.currentPlayer == 1
        ? state!.player1Position
        : state!.player2Position;
    
    var newPos = currentPos + spaces;
    final maxPos = state!.board.length - 1;
    
    // Bounce back if overshooting
    if (newPos > maxPos) {
      newPos = maxPos - (newPos - maxPos);
    }
    
    if (state!.currentPlayer == 1) {
      state = state!.copyWith(player1Position: newPos);
    } else {
      state = state!.copyWith(player2Position: newPos);
    }
    
    // Check if won
    if (newPos == maxPos) {
      state = state!.copyWith(gameCompleted: true);
    }
  }

  /// Get the square type at current player's position
  GooseSquareType getCurrentSquareType() {
    if (state == null) return GooseSquareType.normal;
    
    final pos = state!.currentPlayer == 1
        ? state!.player1Position
        : state!.player2Position;
    
    return state!.board[pos].type;
  }

  /// Set the current card being displayed
  void setCurrentCard(GooseCard? card) {
    if (state == null) return;
    state = state!.copyWith(currentCard: card);
  }

  /// Handle special square effects
  void handleSpecialSquare(GooseSquareType type) {
    if (state == null) return;
    
    switch (type) {
      case GooseSquareType.goose:
        // Double move - roll again
        break;
      case GooseSquareType.bridge:
        // Jump ahead
        final currentPos = state!.currentPlayer == 1
            ? state!.player1Position
            : state!.player2Position;
        final jumpTo = (currentPos + 6).clamp(0, state!.board.length - 1);
        if (state!.currentPlayer == 1) {
          state = state!.copyWith(player1Position: jumpTo);
        } else {
          state = state!.copyWith(player2Position: jumpTo);
        }
        break;
      case GooseSquareType.well:
        // Skip a turn
        if (state!.currentPlayer == 1) {
          state = state!.copyWith(player1InWell: true);
        } else {
          state = state!.copyWith(player2InWell: true);
        }
        break;
      case GooseSquareType.labyrinth:
        // Go back several spaces
        final currentPos = state!.currentPlayer == 1
            ? state!.player1Position
            : state!.player2Position;
        final goBack = (currentPos - 10).clamp(0, state!.board.length - 1);
        if (state!.currentPlayer == 1) {
          state = state!.copyWith(player1Position: goBack);
        } else {
          state = state!.copyWith(player2Position: goBack);
        }
        break;
      case GooseSquareType.inn:
        // Skip next turn
        if (state!.currentPlayer == 1) {
          state = state!.copyWith(player1InWell: true);
        } else {
          state = state!.copyWith(player2InWell: true);
        }
        break;
      default:
        break;
    }
  }

  /// Switch to next player
  void nextPlayer() {
    if (state == null) return;
    
    final nextPlayer = state!.currentPlayer == 1 ? 2 : 1;
    
    // Check if next player is in well/inn
    final isInWell = nextPlayer == 1 ? state!.player1InWell : state!.player2InWell;
    
    if (isInWell) {
      // Release from well but still skip
      if (nextPlayer == 1) {
        state = state!.copyWith(player1InWell: false, currentPlayer: state!.currentPlayer);
      } else {
        state = state!.copyWith(player2InWell: false, currentPlayer: state!.currentPlayer);
      }
    } else {
      state = state!.copyWith(currentPlayer: nextPlayer);
    }
  }

  /// End the game
  void endGame() {
    state = null;
  }
}

// ============================================================
// Settings Providers
// ============================================================

/// App settings state
final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});

class AppSettings {
  final String locale;
  final GameIntensity defaultIntensity;
  final bool isDarkMode;
  final bool soundEffectsEnabled;
  final bool hapticFeedbackEnabled;
  final int shuffleCardCount;
  final int consentCheckInMinutes;
  final bool isPinEnabled;
  final bool isBiometricEnabled;
  final bool isDiscreteIconEnabled;
  final bool isPanicExitEnabled;
  final String illustrationStyle;

  const AppSettings({
    this.locale = 'it',
    this.defaultIntensity = GameIntensity.soft,
    this.isDarkMode = true,
    this.soundEffectsEnabled = true,
    this.hapticFeedbackEnabled = true,
    this.shuffleCardCount = 5,
    this.consentCheckInMinutes = 15,
    this.isPinEnabled = false,
    this.isBiometricEnabled = false,
    this.isDiscreteIconEnabled = false,
    this.isPanicExitEnabled = true,
    this.illustrationStyle = 'line_art',
  });

  AppSettings copyWith({
    String? locale,
    GameIntensity? defaultIntensity,
    bool? isDarkMode,
    bool? soundEffectsEnabled,
    bool? hapticFeedbackEnabled,
    int? shuffleCardCount,
    int? consentCheckInMinutes,
    bool? isPinEnabled,
    bool? isBiometricEnabled,
    bool? isDiscreteIconEnabled,
    bool? isPanicExitEnabled,
    String? illustrationStyle,
  }) {
    return AppSettings(
      locale: locale ?? this.locale,
      defaultIntensity: defaultIntensity ?? this.defaultIntensity,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      soundEffectsEnabled: soundEffectsEnabled ?? this.soundEffectsEnabled,
      hapticFeedbackEnabled: hapticFeedbackEnabled ?? this.hapticFeedbackEnabled,
      shuffleCardCount: shuffleCardCount ?? this.shuffleCardCount,
      consentCheckInMinutes: consentCheckInMinutes ?? this.consentCheckInMinutes,
      isPinEnabled: isPinEnabled ?? this.isPinEnabled,
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      isDiscreteIconEnabled: isDiscreteIconEnabled ?? this.isDiscreteIconEnabled,
      isPanicExitEnabled: isPanicExitEnabled ?? this.isPanicExitEnabled,
      illustrationStyle: illustrationStyle ?? this.illustrationStyle,
    );
  }
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(const AppSettings()) {
    _loadSettings();
  }

  void _loadSettings() {
    final prefs = PreferencesService.instance;
    state = AppSettings(
      locale: prefs.locale ?? 'it',
      defaultIntensity: GameIntensity.values.firstWhere(
        (e) => e.name == (prefs.defaultIntensity ?? 'soft'),
        orElse: () => GameIntensity.soft,
      ),
      isDarkMode: prefs.isDarkMode ?? true,
      soundEffectsEnabled: prefs.areSoundEffectsEnabled ?? true,
      hapticFeedbackEnabled: prefs.isHapticFeedbackEnabled ?? true,
      shuffleCardCount: prefs.shuffleCardCount ?? 5,
      consentCheckInMinutes: prefs.consentCheckInInterval ?? 15,
      isPinEnabled: prefs.isPinEnabled ?? false,
      isBiometricEnabled: prefs.isBiometricEnabled ?? false,
      isDiscreteIconEnabled: prefs.isDiscreteIconEnabled ?? false,
      isPanicExitEnabled: prefs.isPanicExitEnabled ?? true,
      illustrationStyle: prefs.illustrationStyle ?? 'line_art',
    );
  }

  Future<void> setLocale(String locale) async {
    await PreferencesService.instance.setLocale(locale);
    state = state.copyWith(locale: locale);
  }

  Future<void> setDefaultIntensity(GameIntensity intensity) async {
    await PreferencesService.instance.setDefaultIntensity(intensity.name);
    state = state.copyWith(defaultIntensity: intensity);
  }

  Future<void> setDarkMode(bool enabled) async {
    await PreferencesService.instance.setDarkMode(enabled);
    state = state.copyWith(isDarkMode: enabled);
  }

  Future<void> setSoundEffects(bool enabled) async {
    await PreferencesService.instance.setSoundEffectsEnabled(enabled);
    state = state.copyWith(soundEffectsEnabled: enabled);
  }

  Future<void> setHapticFeedback(bool enabled) async {
    await PreferencesService.instance.setHapticFeedbackEnabled(enabled);
    state = state.copyWith(hapticFeedbackEnabled: enabled);
  }

  Future<void> setShuffleCardCount(int count) async {
    await PreferencesService.instance.setShuffleCardCount(count);
    state = state.copyWith(shuffleCardCount: count);
  }

  Future<void> setConsentCheckIn(int minutes) async {
    await PreferencesService.instance.setConsentCheckInInterval(minutes);
    state = state.copyWith(consentCheckInMinutes: minutes);
  }

  Future<void> setPinEnabled(bool enabled) async {
    await PreferencesService.instance.setPinEnabled(enabled);
    state = state.copyWith(isPinEnabled: enabled);
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await PreferencesService.instance.setBiometricEnabled(enabled);
    state = state.copyWith(isBiometricEnabled: enabled);
  }

  Future<void> setDiscreteIcon(bool enabled) async {
    await PreferencesService.instance.setDiscreteIconEnabled(enabled);
    state = state.copyWith(isDiscreteIconEnabled: enabled);
  }

  Future<void> setPanicExit(bool enabled) async {
    await PreferencesService.instance.setPanicExitEnabled(enabled);
    state = state.copyWith(isPanicExitEnabled: enabled);
  }

  Future<void> setIllustrationStyle(String style) async {
    await PreferencesService.instance.setIllustrationStyle(style);
    state = state.copyWith(illustrationStyle: style);
  }
}

// ============================================================
// Progress & Streaks Providers
// ============================================================

/// User statistics
final userStatsProvider = FutureProvider<UserStats>((ref) async {
  final db = DatabaseService.instance;
  final history = await db.getHistory(limit: 1000);
  final streak = await db.getStreak();
  final badges = await db.getUnlockedBadgeIds();
  
  return UserStats(
    positionsExplored: history.map((h) => h['positionId'] as String?).whereType<String>().toSet().length,
    totalViews: history.length,
    currentStreak: streak?['current_streak'] as int? ?? 0,
    longestStreak: streak?['longest_streak'] as int? ?? 0,
    badgesUnlocked: badges.length,
    favoriteReactions: history.where((h) => h['reaction'] == 'loved').length,
  );
});

class UserStats {
  final int positionsExplored;
  final int totalViews;
  final int currentStreak;
  final int longestStreak;
  final int badgesUnlocked;
  final int favoriteReactions;

  UserStats({
    required this.positionsExplored,
    required this.totalViews,
    required this.currentStreak,
    required this.longestStreak,
    required this.badgesUnlocked,
    required this.favoriteReactions,
  });
}
