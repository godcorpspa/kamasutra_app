import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Preferences service for managing app settings using Hive
class PreferencesService {
  static final PreferencesService instance = PreferencesService._init();
  static const String _boxName = 'preferences';
  static const String _secureBoxName = 'secure_preferences';
  
  late Box<dynamic> _box;
  late Box<dynamic> _secureBox;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  PreferencesService._init();

  Future<void> initialize() async {
    _box = await Hive.openBox(_boxName);
    
    // For secure data, we use encrypted box
    final encryptionKey = await _getOrCreateEncryptionKey();
    _secureBox = await Hive.openBox(
      _secureBoxName,
      encryptionCipher: HiveAesCipher(encryptionKey),
    );
  }

  Future<List<int>> _getOrCreateEncryptionKey() async {
    const keyName = 'hive_encryption_key';
    final existingKey = await _secureStorage.read(key: keyName);
    
    if (existingKey != null) {
      return existingKey.codeUnits;
    }
    
    final key = Hive.generateSecureKey();
    await _secureStorage.write(
      key: keyName,
      value: String.fromCharCodes(key),
    );
    return key;
  }

  // ==================== General Preferences ====================

  /// Get a preference value
  T? get<T>(String key) => _box.get(key) as T?;

  /// Set a preference value
  Future<void> set<T>(String key, T value) => _box.put(key, value);

  /// Remove a preference
  Future<void> remove(String key) => _box.delete(key);

  /// Check if a key exists
  bool containsKey(String key) => _box.containsKey(key);

  // ==================== Typed Getters ====================

  bool? getBool(String key) => _box.get(key) as bool?;
  int? getInt(String key) => _box.get(key) as int?;
  double? getDouble(String key) => _box.get(key) as double?;
  String? getString(String key) => _box.get(key) as String?;
  List<String>? getStringList(String key) {
    final value = _box.get(key);
    if (value == null) return null;
    return (value as List).cast<String>();
  }

  // ==================== Secure Preferences ====================

  /// Get a secure preference value
  T? getSecure<T>(String key) => _secureBox.get(key) as T?;

  /// Set a secure preference value
  Future<void> setSecure<T>(String key, T value) => _secureBox.put(key, value);

  /// Remove a secure preference
  Future<void> removeSecure(String key) => _secureBox.delete(key);

  // ==================== App Specific Preferences ====================

  // Onboarding & Authentication
  bool get isAgeVerified => getBool('age_verified') ?? false;
  Future<void> setAgeVerified(bool value) => set('age_verified', value);

  bool get hasCompletedOnboarding => getBool('onboarding_completed') ?? false;
  Future<void> setOnboardingCompleted(bool value) => set('onboarding_completed', value);

  bool get isPinEnabled => getBool('pin_enabled') ?? false;
  Future<void> setPinEnabled(bool value) => set('pin_enabled', value);

  String? get pinHash => getSecure<String>('pin_hash');
  Future<void> setPinHash(String? value) {
    if (value == null) return removeSecure('pin_hash');
    return setSecure('pin_hash', value);
  }

  bool get isBiometricEnabled => getBool('biometric_enabled') ?? false;
  Future<void> setBiometricEnabled(bool value) => set('biometric_enabled', value);

  bool get isAuthenticated => getBool('is_authenticated') ?? false;
  Future<void> setAuthenticated(bool value) => set('is_authenticated', value);

  // Privacy
  bool get isDiscreteIconEnabled => getBool('discrete_icon_enabled') ?? false;
  Future<void> setDiscreteIconEnabled(bool value) => set('discrete_icon_enabled', value);

  bool get isPanicExitEnabled => getBool('panic_exit_enabled') ?? true;
  Future<void> setPanicExitEnabled(bool value) => set('panic_exit_enabled', value);

  // Language
  String get locale => getString('locale') ?? 'it';
  Future<void> setLocale(String value) => set('locale', value);

  // Default Intensity
  String get defaultIntensity => getString('default_intensity') ?? 'soft';
  Future<void> setDefaultIntensity(String value) => set('default_intensity', value);

  // Cautions
  List<String> get excludedCautions => getStringList('excluded_cautions') ?? [];
  Future<void> setExcludedCautions(List<String> value) => set('excluded_cautions', value);

  // Theme
  bool get isDarkMode => getBool('dark_mode') ?? true;
  Future<void> setDarkMode(bool value) => set('dark_mode', value);

  // Shuffle Preferences
  int get shuffleCardCount => getInt('shuffle_card_count') ?? 5;
  Future<void> setShuffleCardCount(int value) => set('shuffle_card_count', value);

  // Consent Check-in Interval (in minutes)
  int get consentCheckInInterval => getInt('consent_checkin_interval') ?? 15;
  Future<void> setConsentCheckInInterval(int value) => set('consent_checkin_interval', value);

  // Sound Effects
  bool get areSoundEffectsEnabled => getBool('sound_effects_enabled') ?? true;
  Future<void> setSoundEffectsEnabled(bool value) => set('sound_effects_enabled', value);

  // Haptic Feedback
  bool get isHapticFeedbackEnabled => getBool('haptic_feedback_enabled') ?? true;
  Future<void> setHapticFeedbackEnabled(bool value) => set('haptic_feedback_enabled', value);

  // Illustration Style
  String get illustrationStyle => getString('illustration_style') ?? 'line_art';
  Future<void> setIllustrationStyle(String value) => set('illustration_style', value);

  // Pro/Full Version
  bool get isProVersion => getBool('is_pro_version') ?? false;
  Future<void> setProVersion(bool value) => set('is_pro_version', value);

  // First Launch Date
  DateTime? get firstLaunchDate {
    final dateStr = getString('first_launch_date');
    return dateStr != null ? DateTime.parse(dateStr) : null;
  }
  Future<void> setFirstLaunchDate(DateTime value) => 
      set('first_launch_date', value.toIso8601String());

  // Last Session Date
  DateTime? get lastSessionDate {
    final dateStr = getString('last_session_date');
    return dateStr != null ? DateTime.parse(dateStr) : null;
  }
  Future<void> setLastSessionDate(DateTime value) =>
      set('last_session_date', value.toIso8601String());

  // ==================== Utilities ====================

  /// Clear all preferences (keeps secure data)
  Future<void> clearAll() async {
    await _box.clear();
  }

  /// Clear everything including secure data
  Future<void> clearEverything() async {
    await _box.clear();
    await _secureBox.clear();
  }

  /// Close boxes
  Future<void> close() async {
    await _box.close();
    await _secureBox.close();
  }
}

/// Preference keys constants
class PreferenceKeys {
  // Onboarding
  static const String ageVerified = 'age_verified';
  static const String onboardingCompleted = 'onboarding_completed';
  static const String pinEnabled = 'pin_enabled';
  static const String biometricEnabled = 'biometric_enabled';
  static const String isAuthenticated = 'is_authenticated';
  
  // Privacy
  static const String discreteIconEnabled = 'discrete_icon_enabled';
  static const String panicExitEnabled = 'panic_exit_enabled';
  
  // App Settings
  static const String locale = 'locale';
  static const String defaultIntensity = 'default_intensity';
  static const String excludedCautions = 'excluded_cautions';
  static const String darkMode = 'dark_mode';
  static const String shuffleCardCount = 'shuffle_card_count';
  static const String consentCheckinInterval = 'consent_checkin_interval';
  static const String soundEffectsEnabled = 'sound_effects_enabled';
  static const String hapticFeedbackEnabled = 'haptic_feedback_enabled';
  static const String illustrationStyle = 'illustration_style';
  
  // Purchase
  static const String isProVersion = 'is_pro_version';
  
  // Usage
  static const String firstLaunchDate = 'first_launch_date';
  static const String lastSessionDate = 'last_session_date';
}
