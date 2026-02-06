import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/user_data.dart';

/// Unified service for all user data on Firebase
class FirebaseUserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Singleton
  static final FirebaseUserService _instance = FirebaseUserService._internal();
  factory FirebaseUserService() => _instance;
  FirebaseUserService._internal();

  // ============ HELPERS ============

  String? get _userId => _auth.currentUser?.uid;
  
  DocumentReference? get _userDoc => 
      _userId != null ? _firestore.collection('users').doc(_userId) : null;

  bool get isLoggedIn => _userId != null;

  /// Initialize Firestore settings (call in main.dart)
  static Future<void> initialize() async {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    debugPrint('✅ FirebaseUserService initialized with offline persistence');
  }

  // ============ PROFILE ============

  /// Create or update user profile after login
  Future<void> initializeUserProfile({
    required String email,
    String? displayName,
  }) async {
    if (_userDoc == null) return;
    
    try {
      final doc = await _userDoc!.get();
      
      if (!doc.exists) {
        // New user - create all documents
        await _userDoc!.set({
          'email': email,
          'displayName': displayName,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
        });
        
        // Initialize settings with defaults
        await _userDoc!.collection('data').doc('settings').set(
          const UserSettings().toFirestore(),
        );
        
        // Initialize progress with defaults
        await _userDoc!.collection('data').doc('progress').set(
          const UserProgress().toFirestore(),
        );
        
        // Initialize positions
        await _userDoc!.collection('data').doc('positions').set(
          const UserPositions().toFirestore(),
        );
        
        debugPrint('✅ New user profile created');
      } else {
        // Existing user - just update last login
        await _userDoc!.update({
          'lastLoginAt': FieldValue.serverTimestamp(),
        });
        debugPrint('✅ User profile updated');
      }
    } catch (e) {
      debugPrint('❌ Error initializing user profile: $e');
    }
  }

  // ============ SETTINGS ============

  /// Get user settings
  Future<UserSettings> getSettings() async {
    if (_userDoc == null) return const UserSettings();
    
    try {
      final doc = await _userDoc!.collection('data').doc('settings').get();
      return UserSettings.fromFirestore(doc.data());
    } catch (e) {
      debugPrint('Error getting settings: $e');
      return const UserSettings();
    }
  }

  /// Stream user settings for real-time updates
  Stream<UserSettings> settingsStream() {
    if (_userDoc == null) return Stream.value(const UserSettings());
    
    return _userDoc!.collection('data').doc('settings')
      .snapshots()
      .map((doc) => UserSettings.fromFirestore(doc.data()));
  }

  /// Update user settings
  Future<void> updateSettings(UserSettings settings) async {
    if (_userDoc == null) return;
    
    try {
      await _userDoc!.collection('data').doc('settings').set(
        settings.toFirestore(),
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('Error updating settings: $e');
    }
  }

  /// Update single setting
  Future<void> updateSetting(String key, dynamic value) async {
    if (_userDoc == null) return;
    
    try {
      await _userDoc!.collection('data').doc('settings').update({key: value});
    } catch (e) {
      debugPrint('Error updating setting $key: $e');
    }
  }

  // ============ PROGRESS ============

  /// Get user progress
  Future<UserProgress> getProgress() async {
    if (_userDoc == null) return const UserProgress();
    
    try {
      final doc = await _userDoc!.collection('data').doc('progress').get();
      return UserProgress.fromFirestore(doc.data());
    } catch (e) {
      debugPrint('Error getting progress: $e');
      return const UserProgress();
    }
  }

  /// Stream user progress for real-time updates
  Stream<UserProgress> progressStream() {
    if (_userDoc == null) return Stream.value(const UserProgress());
    
    return _userDoc!.collection('data').doc('progress')
      .snapshots()
      .map((doc) => UserProgress.fromFirestore(doc.data()));
  }

  /// Update user progress
  Future<void> updateProgress(UserProgress progress) async {
    if (_userDoc == null) return;
    
    try {
      await _userDoc!.collection('data').doc('progress').set(
        progress.toFirestore(),
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('Error updating progress: $e');
    }
  }

  /// Record activity and update streak
  Future<UserProgress> recordActivity() async {
    if (_userDoc == null) return const UserProgress();
    
    try {
      final progress = await getProgress();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      int newStreak = progress.currentStreak;
      int newLongest = progress.longestStreak;
      int graceDays = progress.graceDaysRemaining;
      
      if (progress.lastActiveDate == null) {
        // First activity ever
        newStreak = 1;
        newLongest = 1;
        graceDays = 2;
      } else {
        final lastDay = DateTime(
          progress.lastActiveDate!.year,
          progress.lastActiveDate!.month,
          progress.lastActiveDate!.day,
        );
        
        final daysDiff = today.difference(lastDay).inDays;
        
        if (daysDiff == 0) {
          // Same day, no change to streak
        } else if (daysDiff == 1) {
          // Consecutive day
          newStreak = progress.currentStreak + 1;
          graceDays = 2; // Reset grace days
        } else if (daysDiff <= 1 + progress.graceDaysRemaining) {
          // Within grace period
          newStreak = progress.currentStreak + 1;
          graceDays = 2 - (daysDiff - 1);
        } else {
          // Streak broken
          newStreak = 1;
          graceDays = 2;
        }
        
        if (newStreak > newLongest) {
          newLongest = newStreak;
        }
      }
      
      final newProgress = progress.copyWith(
        currentStreak: newStreak,
        longestStreak: newLongest,
        lastActiveDate: now,
        graceDaysRemaining: graceDays,
      );
      
      await updateProgress(newProgress);
      return newProgress;
    } catch (e) {
      debugPrint('Error recording activity: $e');
      return const UserProgress();
    }
  }

  /// Unlock a badge
  Future<void> unlockBadge(String badgeId) async {
    if (_userDoc == null) return;
    
    try {
      final progress = await getProgress();
      if (progress.unlockedBadges.contains(badgeId)) return;
      
      final newBadges = [...progress.unlockedBadges, badgeId];
      final newDates = Map<String, DateTime>.from(progress.badgeUnlockDates);
      newDates[badgeId] = DateTime.now();
      
      await _userDoc!.collection('data').doc('progress').update({
        'unlockedBadges': newBadges,
        'badgeUnlockDates': newDates.map(
          (k, v) => MapEntry(k, Timestamp.fromDate(v)),
        ),
      });
    } catch (e) {
      debugPrint('Error unlocking badge: $e');
    }
  }

  /// Increment games played
  Future<void> incrementGamesPlayed() async {
    if (_userDoc == null) return;
    
    try {
      await _userDoc!.collection('data').doc('progress').update({
        'gamesPlayed': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('Error incrementing games: $e');
    }
  }

  /// Add time spent
  Future<void> addTimeSpent(int minutes) async {
    if (_userDoc == null) return;
    
    try {
      await _userDoc!.collection('data').doc('progress').update({
        'totalTimeMinutes': FieldValue.increment(minutes),
      });
    } catch (e) {
      debugPrint('Error adding time: $e');
    }
  }

  // ============ POSITIONS ============

  /// Get user positions data
  Future<UserPositions> getPositions() async {
    if (_userDoc == null) return const UserPositions();
    
    try {
      final doc = await _userDoc!.collection('data').doc('positions').get();
      return UserPositions.fromFirestore(doc.data());
    } catch (e) {
      debugPrint('Error getting positions: $e');
      return const UserPositions();
    }
  }

  /// Stream favorites
  Stream<List<String>> favoritesStream() {
    if (_userDoc == null) return Stream.value([]);
    
    return _userDoc!.collection('data').doc('positions')
      .snapshots()
      .map((doc) => List<String>.from(doc.data()?['favorites'] ?? []));
  }

  /// Toggle favorite
  Future<bool> toggleFavorite(String positionId) async {
    if (_userDoc == null) return false;
    
    try {
      final positions = await getPositions();
      final isFavorite = positions.favorites.contains(positionId);
      
      if (isFavorite) {
        await _userDoc!.collection('data').doc('positions').update({
          'favorites': FieldValue.arrayRemove([positionId]),
        });
        return false;
      } else {
        await _userDoc!.collection('data').doc('positions').update({
          'favorites': FieldValue.arrayUnion([positionId]),
        });
        return true;
      }
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
      return false;
    }
  }

  /// Record position view
  Future<void> recordPositionView(String positionId, {String? reaction}) async {
    if (_userDoc == null) return;
    
    try {
      final positions = await getPositions();
      final existing = positions.explored[positionId];
      
      final newData = PositionUserData(
        views: (existing?.views ?? 0) + 1,
        lastViewed: DateTime.now(),
        reaction: reaction ?? existing?.reaction,
      );
      
      await _userDoc!.collection('data').doc('positions').update({
        'explored.$positionId': newData.toMap(),
      });
      
      // Also record activity for streak
      await recordActivity();
    } catch (e) {
      debugPrint('Error recording position view: $e');
    }
  }

  // ============ HISTORY ============

  /// Add history entry
  Future<void> addHistoryEntry(HistoryEntry entry) async {
    if (_userDoc == null) return;
    
    try {
      await _userDoc!.collection('history').add(entry.toFirestore());
    } catch (e) {
      debugPrint('Error adding history entry: $e');
    }
  }

  /// Get history (most recent first)
  Future<List<HistoryEntry>> getHistory({int limit = 100}) async {
    if (_userDoc == null) return [];
    
    try {
      final snapshot = await _userDoc!.collection('history')
        .orderBy('date', descending: true)
        .limit(limit)
        .get();
      
      return snapshot.docs
        .map((doc) => HistoryEntry.fromFirestore(doc.id, doc.data()))
        .toList();
    } catch (e) {
      debugPrint('Error getting history: $e');
      return [];
    }
  }

  /// Stream history
  Stream<List<HistoryEntry>> historyStream({int limit = 50}) {
    if (_userDoc == null) return Stream.value([]);
    
    return _userDoc!.collection('history')
      .orderBy('date', descending: true)
      .limit(limit)
      .snapshots()
      .map((snapshot) => snapshot.docs
        .map((doc) => HistoryEntry.fromFirestore(doc.id, doc.data()))
        .toList()
      );
  }

  /// Clear history
  Future<void> clearHistory() async {
    if (_userDoc == null) return;
    
    try {
      final batch = _firestore.batch();
      final docs = await _userDoc!.collection('history').get();
      for (final doc in docs.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error clearing history: $e');
    }
  }

  // ============ GAMES ============

  /// Generic method to get game data
  Future<T> getGameData<T>(
    String gameId, 
    T Function(Map<String, dynamic>?) fromFirestore,
  ) async {
    if (_userDoc == null) return fromFirestore(null);
    
    try {
      final doc = await _userDoc!.collection('games').doc(gameId).get();
      return fromFirestore(doc.data());
    } catch (e) {
      debugPrint('Error getting game data for $gameId: $e');
      return fromFirestore(null);
    }
  }

  /// Generic method to save game data
  Future<void> saveGameData(String gameId, Map<String, dynamic> data) async {
    if (_userDoc == null) return;
    
    try {
      await _userDoc!.collection('games').doc(gameId).set(
        {...data, 'updatedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('Error saving game data for $gameId: $e');
    }
  }

  /// Stream game data
  Stream<T> gameDataStream<T>(
    String gameId,
    T Function(Map<String, dynamic>?) fromFirestore,
  ) {
    if (_userDoc == null) return Stream.value(fromFirestore(null));
    
    return _userDoc!.collection('games').doc(gameId)
      .snapshots()
      .map((doc) => fromFirestore(doc.data()));
  }

  // Specific game methods for convenience

  Future<LoveNotesData> getLoveNotes() => 
    getGameData('loveNotes', LoveNotesData.fromFirestore);
  
  Future<void> saveLoveNote(Map<String, dynamic> note) async {
    if (_userDoc == null) return;
    await _userDoc!.collection('games').doc('loveNotes').set({
      'notes': FieldValue.arrayUnion([note]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<IntimacyMapData> getIntimacyMap() => 
    getGameData('intimacyMap', IntimacyMapData.fromFirestore);
  
  Future<void> saveIntimacyMap(IntimacyMapData data) => 
    saveGameData('intimacyMap', data.toFirestore());

  Future<FantasyBuilderData> getFantasyBuilder() => 
    getGameData('fantasyBuilder', FantasyBuilderData.fromFirestore);
  
  Future<void> saveFantasyScenario(Map<String, dynamic> scenario) async {
    if (_userDoc == null) return;
    await _userDoc!.collection('games').doc('fantasyBuilder').set({
      'scenarios': FieldValue.arrayUnion([scenario]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<SoundtrackData> getSoundtrack() => 
    getGameData('soundtrack', SoundtrackData.fromFirestore);
  
  Future<void> saveSoundtrack(SoundtrackData data) => 
    saveGameData('soundtrack', data.toFirestore());

  Future<QuestionQuestData> getQuestionQuest() => 
    getGameData('questionQuest', QuestionQuestData.fromFirestore);
  
  Future<void> saveQuestionQuest(QuestionQuestData data) => 
    saveGameData('questionQuest', data.toFirestore());

  Future<ComplimentBattleData> getComplimentBattle() => 
    getGameData('complimentBattle', ComplimentBattleData.fromFirestore);
  
  Future<void> saveComplimentBattle(ComplimentBattleData data) => 
    saveGameData('complimentBattle', data.toFirestore());

  Future<TruthDareData> getTruthDare() => 
    getGameData('truthDare', TruthDareData.fromFirestore);
  
  Future<void> saveTruthDare(TruthDareData data) => 
    saveGameData('truthDare', data.toFirestore());

  // ============ DATA MIGRATION ============

  /// Migrate local data to Firebase (call once after login)
  Future<void> migrateFromLocal({
    required List<String> favorites,
    required Map<String, PositionUserData> explored,
    required int currentStreak,
    required int longestStreak,
    required List<String> unlockedBadges,
    required List<HistoryEntry> history,
  }) async {
    if (_userDoc == null) return;
    
    try {
      final batch = _firestore.batch();
      
      // Migrate positions
      batch.set(
        _userDoc!.collection('data').doc('positions'),
        UserPositions(favorites: favorites, explored: explored).toFirestore(),
        SetOptions(merge: true),
      );
      
      // Migrate progress
      batch.update(
        _userDoc!.collection('data').doc('progress'),
        {
          'currentStreak': currentStreak,
          'longestStreak': longestStreak,
          'unlockedBadges': unlockedBadges,
        },
      );
      
      await batch.commit();
      
      // Migrate history (separate because it's a subcollection)
      for (final entry in history.take(100)) {
        await addHistoryEntry(entry);
      }
      
      debugPrint('✅ Local data migrated to Firebase');
    } catch (e) {
      debugPrint('❌ Error migrating data: $e');
    }
  }

  // ============ CLEAR DATA ============

  /// Clear all user data (for account deletion or reset)
  Future<void> clearAllData() async {
    if (_userDoc == null) return;
    
    try {
      // Clear subcollections
      await clearHistory();
      
      final gamesDocs = await _userDoc!.collection('games').get();
      for (final doc in gamesDocs.docs) {
        await doc.reference.delete();
      }
      
      // Reset main documents
      await _userDoc!.collection('data').doc('settings').set(
        const UserSettings().toFirestore(),
      );
      await _userDoc!.collection('data').doc('progress').set(
        const UserProgress().toFirestore(),
      );
      await _userDoc!.collection('data').doc('positions').set(
        const UserPositions().toFirestore(),
      );
      
      debugPrint('✅ All user data cleared');
    } catch (e) {
      debugPrint('❌ Error clearing data: $e');
    }
  }
}
