import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/position.dart';
import '../models/game.dart';
import '../repositories/position_repository.dart';
import '../services/preferences_service.dart';
import '../services/user_data_sync_service.dart';

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
    state = PositionFilter(
      categories: state.categories,
      minDifficulty: state.minDifficulty,
      maxDifficulty: state.maxDifficulty,
      energyLevels: state.energyLevels,
      focus: state.focus,
      durations: state.durations,
      favoritesOnly: state.favoritesOnly,
      excludeCautions: state.excludeCautions,
      searchQuery: query,
    );
  }

  void clear() {
    state = const PositionFilter();
  }

  void setAll({
    List<PositionCategory>? categories,
    int? minDifficulty,
    int? maxDifficulty,
    List<EnergyLevel>? energyLevels,
    List<PositionFocus>? focus,
    List<PositionDuration>? durations,
    bool? favoritesOnly,
    bool? excludeCautions,
    String? searchQuery,
  }) {
    state = PositionFilter(
      categories: categories,
      minDifficulty: minDifficulty,
      maxDifficulty: maxDifficulty,
      energyLevels: energyLevels,
      focus: focus,
      durations: durations,
      favoritesOnly: favoritesOnly,
      excludeCautions: excludeCautions,
      searchQuery: searchQuery,
    );
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
    
    // Save session to preferences
    final session = {
      'id': sessionId,
      'type': 'shuffle',
      'startedAt': DateTime.now().toIso8601String(),
      'positionIds': positions.map((p) => p.id).toList(),
      'currentIndex': 0,
      'completed': false,
    };
    await PreferencesService.instance.saveSession(session);

    // Mirror-write su cloud (best-effort)
    UserDataSyncService.instance.syncSession(session);
    
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
  }

  /// Move to previous position
  void previous() {
    if (state == null || !state!.hasPrevious) return;
    state = state!.copyWith(currentIndex: state!.currentIndex - 1);
  }

  /// Go to a specific position
  void goTo(int index) {
    if (state == null) return;
    if (index < 0 || index >= state!.positions.length) return;
    state = state!.copyWith(currentIndex: index);
  }

  /// Mark current position as viewed with reaction
  Future<void> recordReaction(PositionReaction reaction, {String? notes}) async {
    if (state?.currentPosition == null) return;
    
    final repo = _ref.read(positionRepositoryProvider);
    await repo.recordView(state!.currentPosition!.id);
    
    final now = DateTime.now();

    await PreferencesService.instance.addHistoryEntry({
      'positionId': state!.currentPosition!.id,
      'viewedAt': now.toIso8601String(),
      'reaction': reaction.name,
      'notes': notes,
    });

    // Mirror-write su cloud (best-effort)
    UserDataSyncService.instance.syncHistoryEntry(
      positionId: state!.currentPosition!.id,
      viewedAt: now,
      reaction: reaction.name,
      notes: notes,
    );
  }

  /// Complete the session
  Future<void> completeSession() async {
    if (state == null) return;
    state = state!.copyWith(isComplete: true);
  }

  /// End and clear session
  void endSession() {
    state = null;
  }
}

// ============================================================
// Game Providers
// ============================================================

/// Available games list
final gamesProvider = Provider<List<GameInfo>>((ref) {
  return [
    const GameInfo(
      id: 'goose_game',
      titleKey: 'games.goose_game.title',
      descriptionKey: 'games.goose_game.description',
      icon: '🪿',
      minPlayers: 2,
      maxPlayers: 2,
      durationMinutes: 30,
      intensities: GameIntensity.values,
    ),
    const GameInfo(
      id: 'truth_dare',
      titleKey: 'games.truth_dare.title',
      descriptionKey: 'games.truth_dare.subtitle',
      icon: '🎯',
      minPlayers: 2,
      maxPlayers: 2,
      durationMinutes: 20,
      intensities: GameIntensity.values,
    ),
    const GameInfo(
      id: 'wheel',
      titleKey: 'games.wheel.title',
      descriptionKey: 'games.wheel.subtitle',
      icon: '🎡',
      minPlayers: 2,
      maxPlayers: 2,
      durationMinutes: 15,
      intensities: GameIntensity.values,
    ),
    const GameInfo(
      id: 'hot_cold',
      titleKey: 'games.hot_cold.title',
      descriptionKey: 'games.hot_cold.subtitle',
      icon: '🔥',
      minPlayers: 2,
      maxPlayers: 2,
      durationMinutes: 10,
      intensities: [GameIntensity.soft, GameIntensity.spicy],
    ),
    const GameInfo(
      id: 'love_notes',
      titleKey: 'games.love_notes.title',
      descriptionKey: 'games.love_notes.subtitle',
      icon: '💌',
      minPlayers: 2,
      maxPlayers: 2,
      durationMinutes: 15,
      intensities: [GameIntensity.soft],
    ),
    const GameInfo(
      id: 'fantasy_builder',
      titleKey: 'games.fantasy_builder.title',
      descriptionKey: 'games.fantasy_builder.subtitle',
      icon: '✨',
      minPlayers: 2,
      maxPlayers: 2,
      durationMinutes: 20,
      intensities: GameIntensity.values,
    ),
    const GameInfo(
      id: 'compliment_battle',
      titleKey: 'games.compliment_battle.title',
      descriptionKey: 'games.compliment_battle.subtitle',
      icon: '💕',
      minPlayers: 2,
      maxPlayers: 2,
      durationMinutes: 10,
      intensities: [GameIntensity.soft],
    ),
    const GameInfo(
      id: 'question_quest',
      titleKey: 'games.question_quest.title',
      descriptionKey: 'games.question_quest.subtitle',
      icon: '❓',
      minPlayers: 2,
      maxPlayers: 2,
      durationMinutes: 30,
      intensities: [GameIntensity.soft],
    ),
    const GameInfo(
      id: 'two_minutes',
      titleKey: 'games.two_minutes.title',
      descriptionKey: 'games.two_minutes.subtitle',
      icon: '⏱️',
      minPlayers: 2,
      maxPlayers: 2,
      durationMinutes: 5,
      intensities: [GameIntensity.soft],
    ),
    const GameInfo(
      id: 'intimacy_map',
      titleKey: 'games.intimacy_map.title',
      descriptionKey: 'games.intimacy_map.subtitle',
      icon: '🗺️',
      minPlayers: 2,
      maxPlayers: 2,
      durationMinutes: 20,
      intensities: [GameIntensity.soft, GameIntensity.spicy],
    ),
    const GameInfo(
      id: 'soundtrack',
      titleKey: 'games.soundtrack.title',
      descriptionKey: 'games.soundtrack.subtitle',
      icon: '🎵',
      minPlayers: 2,
      maxPlayers: 2,
      durationMinutes: 15,
      intensities: [GameIntensity.soft],
    ),
    const GameInfo(
      id: 'mirror_challenge',
      titleKey: 'games.mirror_challenge.title',
      descriptionKey: 'games.mirror_challenge.subtitle',
      icon: '🪞',
      minPlayers: 2,
      maxPlayers: 2,
      durationMinutes: 10,
      intensities: [GameIntensity.soft, GameIntensity.spicy],
    ),
  ];
});

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
      soundEffectsEnabled: prefs.areSoundEffectsEnabled,
      hapticFeedbackEnabled: prefs.isHapticFeedbackEnabled,
      shuffleCardCount: prefs.shuffleCardCount,
      consentCheckInMinutes: prefs.consentCheckInInterval,
      isPinEnabled: prefs.isPinEnabled,
      isBiometricEnabled: prefs.isBiometricEnabled,
      isDiscreteIconEnabled: prefs.isDiscreteIconEnabled,
      isPanicExitEnabled: prefs.isPanicExitEnabled,
      illustrationStyle: prefs.illustrationStyle,
    );
  }

  Future<void> setLocale(String locale) async {
    await PreferencesService.instance.setLocale(locale);
    UserDataSyncService.instance.syncSettingsPatch({'locale': locale});
    state = state.copyWith(locale: locale);
  }

  Future<void> setDefaultIntensity(GameIntensity intensity) async {
    await PreferencesService.instance.setDefaultIntensity(intensity.name);
    UserDataSyncService.instance.syncSettingsPatch({'default_intensity': intensity.name});
    state = state.copyWith(defaultIntensity: intensity);
  }

  Future<void> setDarkMode(bool enabled) async {
    await PreferencesService.instance.setDarkMode(enabled);
    UserDataSyncService.instance.syncSettingsPatch({'dark_mode': enabled});
    state = state.copyWith(isDarkMode: enabled);
  }

  Future<void> setSoundEffects(bool enabled) async {
    await PreferencesService.instance.setSoundEffectsEnabled(enabled);
    UserDataSyncService.instance.syncSettingsPatch({'sound_effects': enabled});
    state = state.copyWith(soundEffectsEnabled: enabled);
  }

  Future<void> setHapticFeedback(bool enabled) async {
    await PreferencesService.instance.setHapticFeedbackEnabled(enabled);
    UserDataSyncService.instance.syncSettingsPatch({'haptic_feedback': enabled});
    state = state.copyWith(hapticFeedbackEnabled: enabled);
  }

  Future<void> setShuffleCardCount(int count) async {
    await PreferencesService.instance.setShuffleCardCount(count);
    UserDataSyncService.instance.syncSettingsPatch({'shuffle_card_count': count});
    state = state.copyWith(shuffleCardCount: count);
  }

  Future<void> setConsentCheckIn(int minutes) async {
    await PreferencesService.instance.setConsentCheckInInterval(minutes);
    UserDataSyncService.instance.syncSettingsPatch({'consent_check_in_interval': minutes});
    state = state.copyWith(consentCheckInMinutes: minutes);
  }

  Future<void> setPinEnabled(bool enabled) async {
    await PreferencesService.instance.setPinEnabled(enabled);
    UserDataSyncService.instance.syncSettingsPatch({'pin_enabled': enabled});
    state = state.copyWith(isPinEnabled: enabled);
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await PreferencesService.instance.setBiometricEnabled(enabled);
    UserDataSyncService.instance.syncSettingsPatch({'biometric_enabled': enabled});
    state = state.copyWith(isBiometricEnabled: enabled);
  }

  Future<void> setDiscreteIcon(bool enabled) async {
    await PreferencesService.instance.setDiscreteIconEnabled(enabled);
    UserDataSyncService.instance.syncSettingsPatch({'discrete_icon_enabled': enabled});
    state = state.copyWith(isDiscreteIconEnabled: enabled);
  }

  Future<void> setPanicExit(bool enabled) async {
    await PreferencesService.instance.setPanicExitEnabled(enabled);
    UserDataSyncService.instance.syncSettingsPatch({'panic_exit_enabled': enabled});
    state = state.copyWith(isPanicExitEnabled: enabled);
  }

  Future<void> setIllustrationStyle(String style) async {
    await PreferencesService.instance.setIllustrationStyle(style);
    UserDataSyncService.instance.syncSettingsPatch({'illustration_style': style});
    state = state.copyWith(illustrationStyle: style);
  }
}

// ============================================================
// Progress & Streaks Providers
// ============================================================

/// User statistics
final userStatsProvider = FutureProvider<UserStats>((ref) async {
  final prefs = PreferencesService.instance;
  final history = await prefs.getHistory(limit: 1000);
  final badges = await prefs.getUnlockedBadgeIds();
  
  return UserStats(
    positionsExplored: prefs.triedPositionIds.length,
    totalViews: history.length,
    currentStreak: prefs.currentStreak,
    longestStreak: prefs.longestStreak,
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
