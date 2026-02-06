import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_data.dart';
import '../services/firebase_user_service.dart';

/// Provider for FirebaseUserService singleton
final firebaseUserServiceProvider = Provider<FirebaseUserService>((ref) {
  return FirebaseUserService();
});

// ============ SETTINGS ============

/// Stream provider for user settings
final userSettingsStreamProvider = StreamProvider<UserSettings>((ref) {
  final service = ref.watch(firebaseUserServiceProvider);
  return service.settingsStream();
});

/// Provider for current settings (one-time fetch)
final userSettingsProvider = FutureProvider<UserSettings>((ref) async {
  final service = ref.watch(firebaseUserServiceProvider);
  return service.getSettings();
});

/// Notifier for updating settings
class SettingsNotifier extends StateNotifier<UserSettings> {
  final FirebaseUserService _service;
  
  SettingsNotifier(this._service) : super(const UserSettings()) {
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    state = await _service.getSettings();
  }
  
  Future<void> updateLocale(String locale) async {
    state = state.copyWith(locale: locale);
    await _service.updateSetting('locale', locale);
  }
  
  Future<void> updateDarkMode(bool value) async {
    state = state.copyWith(darkMode: value);
    await _service.updateSetting('darkMode', value);
  }
  
  Future<void> updateIllustrationStyle(String style) async {
    state = state.copyWith(illustrationStyle: style);
    await _service.updateSetting('illustrationStyle', style);
  }
  
  Future<void> updateDefaultIntensity(String intensity) async {
    state = state.copyWith(defaultIntensity: intensity);
    await _service.updateSetting('defaultIntensity', intensity);
  }
  
  Future<void> updateShuffleCardCount(int count) async {
    state = state.copyWith(shuffleCardCount: count);
    await _service.updateSetting('shuffleCardCount', count);
  }
  
  Future<void> updateConsentCheckInInterval(int minutes) async {
    state = state.copyWith(consentCheckInInterval: minutes);
    await _service.updateSetting('consentCheckInInterval', minutes);
  }
  
  Future<void> updateSoundEffects(bool value) async {
    state = state.copyWith(soundEffects: value);
    await _service.updateSetting('soundEffects', value);
  }
  
  Future<void> updateHapticFeedback(bool value) async {
    state = state.copyWith(hapticFeedback: value);
    await _service.updateSetting('hapticFeedback', value);
  }
}

final settingsNotifierProvider = StateNotifierProvider<SettingsNotifier, UserSettings>((ref) {
  final service = ref.watch(firebaseUserServiceProvider);
  return SettingsNotifier(service);
});

// ============ PROGRESS ============

/// Stream provider for user progress
final userProgressStreamProvider = StreamProvider<UserProgress>((ref) {
  final service = ref.watch(firebaseUserServiceProvider);
  return service.progressStream();
});

/// Notifier for progress with actions
class ProgressNotifier extends StateNotifier<UserProgress> {
  final FirebaseUserService _service;
  
  ProgressNotifier(this._service) : super(const UserProgress()) {
    _loadProgress();
  }
  
  Future<void> _loadProgress() async {
    state = await _service.getProgress();
  }
  
  Future<void> refresh() async {
    state = await _service.getProgress();
  }
  
  Future<void> recordActivity() async {
    state = await _service.recordActivity();
  }
  
  Future<void> unlockBadge(String badgeId) async {
    await _service.unlockBadge(badgeId);
    await refresh();
  }
  
  Future<void> incrementGamesPlayed() async {
    await _service.incrementGamesPlayed();
    await refresh();
  }
  
  Future<void> addTimeSpent(int minutes) async {
    await _service.addTimeSpent(minutes);
    await refresh();
  }
}

final progressNotifierProvider = StateNotifierProvider<ProgressNotifier, UserProgress>((ref) {
  final service = ref.watch(firebaseUserServiceProvider);
  return ProgressNotifier(service);
});

// ============ FAVORITES ============

/// Stream provider for favorites list
final favoritesStreamProvider = StreamProvider<List<String>>((ref) {
  final service = ref.watch(firebaseUserServiceProvider);
  return service.favoritesStream();
});

/// Provider to check if a position is favorite
final isFavoriteProvider = Provider.family<bool, String>((ref, positionId) {
  final favorites = ref.watch(favoritesStreamProvider);
  return favorites.when(
    data: (list) => list.contains(positionId),
    loading: () => false,
    error: (_, __) => false,
  );
});

// ============ HISTORY ============

/// Stream provider for history
final historyStreamProvider = StreamProvider<List<HistoryEntry>>((ref) {
  final service = ref.watch(firebaseUserServiceProvider);
  return service.historyStream();
});

// ============ GAME DATA PROVIDERS ============

/// Love Notes data
final loveNotesProvider = FutureProvider<LoveNotesData>((ref) async {
  final service = ref.watch(firebaseUserServiceProvider);
  return service.getLoveNotes();
});

final loveNotesStreamProvider = StreamProvider<LoveNotesData>((ref) {
  final service = ref.watch(firebaseUserServiceProvider);
  return service.gameDataStream('loveNotes', LoveNotesData.fromFirestore);
});

/// Intimacy Map data
final intimacyMapProvider = FutureProvider<IntimacyMapData>((ref) async {
  final service = ref.watch(firebaseUserServiceProvider);
  return service.getIntimacyMap();
});

final intimacyMapStreamProvider = StreamProvider<IntimacyMapData>((ref) {
  final service = ref.watch(firebaseUserServiceProvider);
  return service.gameDataStream('intimacyMap', IntimacyMapData.fromFirestore);
});

/// Fantasy Builder data
final fantasyBuilderProvider = FutureProvider<FantasyBuilderData>((ref) async {
  final service = ref.watch(firebaseUserServiceProvider);
  return service.getFantasyBuilder();
});

/// Soundtrack data
final soundtrackProvider = FutureProvider<SoundtrackData>((ref) async {
  final service = ref.watch(firebaseUserServiceProvider);
  return service.getSoundtrack();
});

/// Question Quest data
final questionQuestProvider = FutureProvider<QuestionQuestData>((ref) async {
  final service = ref.watch(firebaseUserServiceProvider);
  return service.getQuestionQuest();
});

/// Compliment Battle data
final complimentBattleProvider = FutureProvider<ComplimentBattleData>((ref) async {
  final service = ref.watch(firebaseUserServiceProvider);
  return service.getComplimentBattle();
});

/// Truth or Dare data
final truthDareProvider = FutureProvider<TruthDareData>((ref) async {
  final service = ref.watch(firebaseUserServiceProvider);
  return service.getTruthDare();
});

// ============ COMBINED STATE ============

/// Combined user data state for easy access
class UserDataState {
  final UserSettings settings;
  final UserProgress progress;
  final List<String> favorites;
  final List<HistoryEntry> history;
  final bool isLoading;
  final String? error;

  const UserDataState({
    this.settings = const UserSettings(),
    this.progress = const UserProgress(),
    this.favorites = const [],
    this.history = const [],
    this.isLoading = true,
    this.error,
  });

  UserDataState copyWith({
    UserSettings? settings,
    UserProgress? progress,
    List<String>? favorites,
    List<HistoryEntry>? history,
    bool? isLoading,
    String? error,
  }) {
    return UserDataState(
      settings: settings ?? this.settings,
      progress: progress ?? this.progress,
      favorites: favorites ?? this.favorites,
      history: history ?? this.history,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Combined notifier for all user data
class UserDataNotifier extends StateNotifier<UserDataState> {
  final FirebaseUserService _service;
  
  UserDataNotifier(this._service) : super(const UserDataState()) {
    _loadAllData();
  }
  
  Future<void> _loadAllData() async {
    try {
      final settings = await _service.getSettings();
      final progress = await _service.getProgress();
      final positions = await _service.getPositions();
      final history = await _service.getHistory(limit: 50);
      
      state = state.copyWith(
        settings: settings,
        progress: progress,
        favorites: positions.favorites,
        history: history,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
  
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    await _loadAllData();
  }
  
  // Quick access methods
  Future<void> toggleFavorite(String positionId) async {
    final newStatus = await _service.toggleFavorite(positionId);
    final newFavorites = List<String>.from(state.favorites);
    if (newStatus) {
      newFavorites.add(positionId);
    } else {
      newFavorites.remove(positionId);
    }
    state = state.copyWith(favorites: newFavorites);
  }
  
  Future<void> recordPositionView(String positionId, String positionName, String? category, String reaction) async {
    await _service.recordPositionView(positionId, reaction: reaction);
    await _service.addHistoryEntry(HistoryEntry(
      positionId: positionId,
      positionName: positionName,
      category: category,
      reaction: reaction,
      date: DateTime.now(),
    ));
    
    // Refresh progress (streak might have changed)
    final progress = await _service.getProgress();
    final history = await _service.getHistory(limit: 50);
    state = state.copyWith(progress: progress, history: history);
  }
}

final userDataNotifierProvider = StateNotifierProvider<UserDataNotifier, UserDataState>((ref) {
  final service = ref.watch(firebaseUserServiceProvider);
  return UserDataNotifier(service);
});
