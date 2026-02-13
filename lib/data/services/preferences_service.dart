import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

/// Service per gestire le preferenze utente usando SharedPreferences
/// Sostituisce completamente il vecchio servizio Hive
class PreferencesService {
  SharedPreferences? _prefs;
  bool _initialized = false;

  // Singleton
  static final PreferencesService _instance = PreferencesService._internal();
  static PreferencesService get instance => _instance;
  PreferencesService._internal();

  /// Inizializza il servizio
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      _prefs = await SharedPreferences.getInstance();
      _initialized = true;
      debugPrint('✅ PreferencesService inizializzato');
    } catch (e) {
      debugPrint('❌ Errore PreferencesService: $e');
    }
  }

  /// Restituisce tutte le chiavi presenti in SharedPreferences.
  /// Utile per migrazioni e debug.
  Set<String> get keys => _prefs?.getKeys() ?? <String>{};

  // ============ GENERIC GETTERS ============

  bool? getBool(String key) => _prefs?.getBool(key);
  String? getString(String key) => _prefs?.getString(key);
  int? getInt(String key) => _prefs?.getInt(key);
  double? getDouble(String key) => _prefs?.getDouble(key);
  List<String>? getStringList(String key) => _prefs?.getStringList(key);

  // ============ GENERIC SETTERS ============

  Future<void> setBool(String key, bool value) async {
    await _prefs?.setBool(key, value);
  }

  Future<void> setString(String key, String value) async {
    await _prefs?.setString(key, value);
  }

  Future<void> setInt(String key, int value) async {
    await _prefs?.setInt(key, value);
  }

  Future<void> setDouble(String key, double value) async {
    await _prefs?.setDouble(key, value);
  }

  Future<void> setStringList(String key, List<String> value) async {
    await _prefs?.setStringList(key, value);
  }

  Future<void> remove(String key) async {
    await _prefs?.remove(key);
  }

  // ============ AGE & ONBOARDING ============

  bool get isAgeVerified => getBool('age_verified') ?? false;
  Future<void> setAgeVerified(bool value) => setBool('age_verified', value);

  bool get hasCompletedOnboarding => getBool('onboarding_completed') ?? false;
  Future<void> setOnboardingCompleted(bool value) => setBool('onboarding_completed', value);

  DateTime? get firstLaunchDate {
    final str = getString('first_launch_date');
    return str != null ? DateTime.tryParse(str) : null;
  }
  Future<void> setFirstLaunchDate(DateTime date) => setString('first_launch_date', date.toIso8601String());

  // ============ PIN & SECURITY ============

  bool get isPinEnabled => getBool('pin_enabled') ?? false;
  Future<void> setPinEnabled(bool value) => setBool('pin_enabled', value);

  String? get pinHash => getString('pin_hash');
  Future<void> setPinHash(String? value) async {
    if (value == null) {
      await remove('pin_hash');
    } else {
      await setString('pin_hash', value);
    }
  }

  bool get isBiometricEnabled => getBool('biometric_enabled') ?? false;
  Future<void> setBiometricEnabled(bool value) => setBool('biometric_enabled', value);

  bool get isDiscreteIconEnabled => getBool('discrete_icon_enabled') ?? false;
  Future<void> setDiscreteIconEnabled(bool value) => setBool('discrete_icon_enabled', value);

  bool get isPanicExitEnabled => getBool('panic_exit_enabled') ?? true;
  Future<void> setPanicExitEnabled(bool value) => setBool('panic_exit_enabled', value);

  // Sessione corrente (non persistente, solo memoria)
  bool _isSessionAuthenticated = false;
  bool get isSessionAuthenticated => _isSessionAuthenticated;
  void setSessionAuthenticated(bool value) => _isSessionAuthenticated = value;
  
  // Alias per compatibilità
  void setAuthenticated(bool value) => setSessionAuthenticated(value);

  // ============ LOCALE & APPEARANCE ============

  String? get locale => getString('locale');
  Future<void> setLocale(String value) => setString('locale', value);

  bool? get isDarkMode => getBool('dark_mode');
  Future<void> setDarkMode(bool value) => setBool('dark_mode', value);

  String get illustrationStyle => getString('illustration_style') ?? 'line_art';
  Future<void> setIllustrationStyle(String value) => setString('illustration_style', value);

  // ============ GAME SETTINGS ============

  String? get defaultIntensity => getString('default_intensity');
  Future<void> setDefaultIntensity(String value) => setString('default_intensity', value);

  int get shuffleCardCount => getInt('shuffle_card_count') ?? 5;
  Future<void> setShuffleCardCount(int value) => setInt('shuffle_card_count', value);

  int get consentCheckInInterval => getInt('consent_check_in_interval') ?? 15;
  Future<void> setConsentCheckInInterval(int value) => setInt('consent_check_in_interval', value);

  // ============ SOUND & HAPTICS ============

  bool get areSoundEffectsEnabled => getBool('sound_effects') ?? true;
  Future<void> setSoundEffectsEnabled(bool value) => setBool('sound_effects', value);

  bool get isHapticFeedbackEnabled => getBool('haptic_feedback') ?? true;
  Future<void> setHapticFeedbackEnabled(bool value) => setBool('haptic_feedback', value);

  // ============ FAVORITES ============

  List<String> get favoritePositionIds => getStringList('favorite_positions') ?? [];

  /// Imposta l'intera lista dei preferiti (utile per sync cloud -> locale)
  Future<void> setFavoritePositionIds(List<String> positionIds) async {
    await setStringList('favorite_positions', positionIds);
  }
  
  Future<void> addFavorite(String positionId) async {
    final favorites = List<String>.from(favoritePositionIds);
    if (!favorites.contains(positionId)) {
      favorites.add(positionId);
      await setStringList('favorite_positions', favorites);
    }
  }

  Future<void> removeFavorite(String positionId) async {
    final favorites = List<String>.from(favoritePositionIds);
    favorites.remove(positionId);
    await setStringList('favorite_positions', favorites);
  }

  bool isFavorite(String positionId) => favoritePositionIds.contains(positionId);

  // ============ POSITION USER DATA ============

  Future<Map<String, dynamic>?> getPositionUserData(String positionId) async {
    final timesViewed = getInt('position_${positionId}_views') ?? 0;
    final lastViewedStr = getString('position_${positionId}_last_viewed');
    final isFav = isFavorite(positionId);
    
    return {
      'positionId': positionId,
      'isFavorite': isFav,
      'timesViewed': timesViewed,
      'lastViewed': lastViewedStr,
    };
  }

  Future<void> updatePositionUserData(
    String positionId, {
    bool? isFavorite,
    int? timesViewed,
    DateTime? lastViewed,
  }) async {
    if (isFavorite != null) {
      if (isFavorite) {
        await addFavorite(positionId);
      } else {
        await removeFavorite(positionId);
      }
    }
    if (timesViewed != null) {
      await setInt('position_${positionId}_views', timesViewed);
    }
    if (lastViewed != null) {
      await setString('position_${positionId}_last_viewed', lastViewed.toIso8601String());
    }
  }

  // ============ HISTORY ============

  Future<void> addHistoryEntry(Map<String, dynamic> entry) async {
    final history = getStringList('history') ?? [];
    // Salviamo in JSON per non perdere campi (es. notes).
    // Manteniamo retro-compatibilità: se in history ci sono stringhe legacy, le lasciamo.
    final safeEntry = <String, dynamic>{
      'positionId': entry['positionId'],
      'viewedAt': entry['viewedAt'],
      'reaction': entry['reaction'] ?? '',
      if (entry.containsKey('notes')) 'notes': entry['notes'],
    };
    history.add(jsonEncode(safeEntry));
    // Keep only last 500 entries
    if (history.length > 500) {
      history.removeRange(0, history.length - 500);
    }
    await setStringList('history', history);
  }

  Future<List<Map<String, dynamic>>> getHistory({int limit = 100}) async {
    final history = getStringList('history') ?? [];
    return history.reversed.take(limit).map((str) {
      // 1) Prova JSON
      try {
        final decoded = jsonDecode(str);
        if (decoded is Map) {
          return <String, dynamic>{
            'positionId': decoded['positionId'] ?? '',
            'viewedAt': decoded['viewedAt'] ?? '',
            'reaction': decoded['reaction'] ?? '',
            if (decoded.containsKey('notes')) 'notes': decoded['notes'],
          };
        }
      } catch (_) {
        // ignore
      }

      // 2) Fallback legacy: positionId|viewedAt|reaction
      final parts = str.split('|');
      return {
        'positionId': parts.isNotEmpty ? parts[0] : '',
        'viewedAt': parts.length > 1 ? parts[1] : '',
        'reaction': parts.length > 2 ? parts[2] : '',
      };
    }).toList();
  }

  /// Sovrascrive la history con una lista di entry (salvata in JSON)
  Future<void> setHistoryEntries(List<Map<String, dynamic>> entries) async {
    final encoded = entries.map((e) => jsonEncode(e)).toList(growable: false);
    // Keep only last 500 entries
    final trimmed = encoded.length > 500 ? encoded.sublist(encoded.length - 500) : encoded;
    await setStringList('history', trimmed);
  }

  // ============ SESSIONS ============

  Future<void> saveSession(Map<String, dynamic> session) async {
    final sessionId = session['id'] as String;
    // JSON per poterlo rileggere/portare su cloud.
    await setString('session_$sessionId', jsonEncode(session));
  }

  // ============ STREAKS ============

  int get currentStreak => getInt('current_streak') ?? 0;
  int get longestStreak => getInt('longest_streak') ?? 0;
  
  Future<void> updateStreak(int current, int longest) async {
    await setInt('current_streak', current);
    await setInt('longest_streak', longest);
    await setString('last_streak_date', DateTime.now().toIso8601String());
  }

  Future<Map<String, dynamic>?> getStreak() async {
    return {
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'last_date': getString('last_streak_date'),
    };
  }

  // ============ BADGES ============

  List<String> get unlockedBadgeIds => getStringList('unlocked_badges') ?? [];

  Future<void> unlockBadge(String badgeId) async {
    final badges = List<String>.from(unlockedBadgeIds);
    if (!badges.contains(badgeId)) {
      badges.add(badgeId);
      await setStringList('unlocked_badges', badges);
    }
  }

  Future<List<String>> getUnlockedBadgeIds() async => unlockedBadgeIds;

  // ============ CLEAR DATA ============

  Future<void> clearHistory() async {
    await remove('history');
  }

  Future<void> clearEverything() async {
    await _prefs?.clear();
    _isSessionAuthenticated = false;
  }
}
