import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_data.dart';
import '../services/firebase_user_service.dart';
import '../services/preferences_service.dart';

/// Helper class to migrate data from SharedPreferences to Firebase
/// Call this once after user logs in for the first time after update
class DataMigrationHelper {
  static const String _migrationCompleteKey = 'firebase_migration_complete';
  
  /// Check if migration is needed
  static Future<bool> needsMigration() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_migrationCompleteKey) ?? false);
  }
  
  /// Perform the migration
  static Future<MigrationResult> migrate({
    required VoidCallback? onProgress,
  }) async {
    final result = MigrationResult();
    
    try {
      final prefs = PreferencesService.instance;
      final firebase = FirebaseUserService();
      
      if (!firebase.isLoggedIn) {
        result.error = 'Utente non loggato';
        return result;
      }
      
      // 1. Migrate Settings
      onProgress?.call();
      await _migrateSettings(prefs, firebase);
      result.settingsMigrated = true;
      
      // 2. Migrate Favorites
      onProgress?.call();
      final favorites = prefs.favoritePositionIds;
      result.favoritesMigrated = favorites.length;
      
      // 3. Migrate Progress/Streak
      onProgress?.call();
      final streakData = await prefs.getStreak();
      result.progressMigrated = true;
      
      // 4. Migrate Badges
      onProgress?.call();
      final badges = await prefs.getUnlockedBadgeIds();
      result.badgesMigrated = badges.length;
      
      // 5. Migrate History
      onProgress?.call();
      final history = await prefs.getHistory(limit: 100);
      final historyEntries = history.map((h) => HistoryEntry(
        positionId: h['positionId'] ?? '',
        positionName: h['positionId'] ?? '', // We don't have the name in old format
        reaction: h['reaction'] ?? '👍',
        date: DateTime.tryParse(h['viewedAt'] ?? '') ?? DateTime.now(),
      )).toList();
      result.historyMigrated = historyEntries.length;
      
      // 6. Build explored positions map
      final explored = <String, PositionUserData>{};
      for (final fav in favorites) {
        final posData = await prefs.getPositionUserData(fav);
        if (posData != null) {
          explored[fav] = PositionUserData(
            views: posData['timesViewed'] as int? ?? 1,
            lastViewed: posData['lastViewed'] != null 
                ? DateTime.tryParse(posData['lastViewed'] as String)
                : null,
          );
        }
      }
      
      // Perform the actual migration to Firebase
      await firebase.migrateFromLocal(
        favorites: favorites,
        explored: explored,
        currentStreak: streakData?['current_streak'] as int? ?? 0,
        longestStreak: streakData?['longest_streak'] as int? ?? 0,
        unlockedBadges: badges,
        history: historyEntries,
      );
      
      // Mark migration as complete
      final sharedPrefs = await SharedPreferences.getInstance();
      await sharedPrefs.setBool(_migrationCompleteKey, true);
      
      result.success = true;
      debugPrint('✅ Data migration completed successfully');
      
    } catch (e) {
      result.error = e.toString();
      debugPrint('❌ Data migration failed: $e');
    }
    
    return result;
  }
  
  static Future<void> _migrateSettings(
    PreferencesService prefs,
    FirebaseUserService firebase,
  ) async {
    final settings = UserSettings(
      locale: prefs.locale ?? 'it',
      darkMode: prefs.isDarkMode ?? true,
      illustrationStyle: prefs.illustrationStyle,
      defaultIntensity: prefs.defaultIntensity ?? 'soft',
      shuffleCardCount: prefs.shuffleCardCount,
      consentCheckInInterval: prefs.consentCheckInInterval,
      soundEffects: prefs.areSoundEffectsEnabled,
      hapticFeedback: prefs.isHapticFeedbackEnabled,
    );
    
    await firebase.updateSettings(settings);
  }
  
  /// Reset migration flag (for testing)
  static Future<void> resetMigration() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_migrationCompleteKey);
  }
}

/// Result of migration operation
class MigrationResult {
  bool success = false;
  String? error;
  
  bool settingsMigrated = false;
  int favoritesMigrated = 0;
  bool progressMigrated = false;
  int badgesMigrated = 0;
  int historyMigrated = 0;
  
  String get summary {
    if (!success) return 'Migrazione fallita: $error';
    
    return '''
Migrazione completata! ✅
• Impostazioni: ${settingsMigrated ? '✓' : '✗'}
• Preferiti: $favoritesMigrated
• Progressi: ${progressMigrated ? '✓' : '✗'}
• Badge: $badgesMigrated
• Cronologia: $historyMigrated elementi
''';
  }
}

/// Widget to show migration dialog
class MigrationDialog extends StatefulWidget {
  final VoidCallback onComplete;
  
  const MigrationDialog({
    super.key,
    required this.onComplete,
  });

  @override
  State<MigrationDialog> createState() => _MigrationDialogState();
}

class _MigrationDialogState extends State<MigrationDialog> {
  bool _isLoading = true;
  MigrationResult? _result;
  String _status = 'Preparazione...';
  
  @override
  void initState() {
    super.initState();
    _performMigration();
  }
  
  Future<void> _performMigration() async {
    int step = 0;
    final steps = [
      'Migrazione impostazioni...',
      'Migrazione preferiti...',
      'Migrazione progressi...',
      'Migrazione badge...',
      'Migrazione cronologia...',
      'Finalizzazione...',
    ];
    
    final result = await DataMigrationHelper.migrate(
      onProgress: () {
        if (step < steps.length) {
          setState(() => _status = steps[step]);
          step++;
        }
      },
    );
    
    setState(() {
      _isLoading = false;
      _result = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isLoading ? 'Migrazione in corso...' : 'Migrazione completata'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isLoading) ...[
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(_status),
          ] else if (_result != null) ...[
            Icon(
              _result!.success ? Icons.check_circle : Icons.error,
              color: _result!.success ? Colors.green : Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              _result!.summary,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
      actions: [
        if (!_isLoading)
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onComplete();
            },
            child: const Text('Continua'),
          ),
      ],
    );
  }
}

/// Example usage in app initialization:
/// 
/// ```dart
/// // In your home screen or after login
/// @override
/// void initState() {
///   super.initState();
///   _checkMigration();
/// }
/// 
/// Future<void> _checkMigration() async {
///   if (await DataMigrationHelper.needsMigration()) {
///     if (mounted) {
///       showDialog(
///         context: context,
///         barrierDismissible: false,
///         builder: (context) => MigrationDialog(
///           onComplete: () {
///             // Refresh data
///             ref.refresh(userDataNotifierProvider);
///           },
///         ),
///       );
///     }
///   }
/// }
/// ```
