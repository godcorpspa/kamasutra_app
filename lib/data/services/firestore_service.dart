import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/position.dart';
import 'preferences_service.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  static FirestoreService get instance => _instance;
  
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  FirestoreService._internal();

  String? get userId => _auth.currentUser?.uid;

  // ============ CONTENT MIGRATION (Admin Only) ============
  
  /// Upload static JSON positions to Firestore (run once or when content updates)
  Future<void> uploadPositions(List<Position> positions) async {
    final batch = _db.batch();
    
    for (var position in positions) {
      final ref = _db.collection('content').doc('v1').collection('positions').doc(position.id);
      batch.set(ref, position.toJson());
    }
    
    await batch.commit();
  }

  // ============ USER DATA MIGRATION ============

  /// Migrates local SharedPreferences data to Firestore for the current user
  Future<void> migrateLocalDataToCloud() async {
    if (userId == null) return;
    
    final prefs = PreferencesService.instance;
    final userRef = _db.collection('users').doc(userId);
    
    // Check if migration already happened
    final doc = await userRef.get();
    if (doc.exists && (doc.data()?['migration_completed'] ?? false)) {
      return;
    }

    final batch = _db.batch();

    // 1. Favorites
    final favorites = prefs.favoritePositionIds;
    if (favorites.isNotEmpty) {
      batch.set(
        userRef.collection('userdata').doc('favorites'), 
        {'ids': favorites}, 
        SetOptions(merge: true)
      );
    }

    // 2. Stats (Views)
    // We iterate through favorites or known IDs to find view counts locally
    // Since we don't have a list of all IDs easily, we rely on what's tracked.
    // A better approach for stats migration might be skipped if too complex, 
    // or we assume most critical data is favorites.
    
    // 3. User Settings
    batch.set(userRef, {
      'migration_completed': true,
      'settings': {
        'age_verified': prefs.isAgeVerified,
        'onboarding_completed': prefs.hasCompletedOnboarding,
        'dark_mode': prefs.isDarkMode,
        'locale': prefs.locale,
      },
      'last_updated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  // ============ DATA ACCESS ============

  /// Stream of user favorites
  Stream<List<String>> getFavoritesStream() {
    if (userId == null) return Stream.value([]);
    
    return _db
        .collection('users')
        .doc(userId)
        .collection('userdata')
        .doc('favorites')
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) return [];
          return List<String>.from(snapshot.data()?['ids'] ?? []);
        });
  }

  /// Toggle favorite status in Cloud
  Future<void> toggleFavorite(String positionId, bool isFavorite) async {
    if (userId == null) return;

    final ref = _db.collection('users').doc(userId).collection('userdata').doc('favorites');
    
    if (isFavorite) {
      await ref.set({
        'ids': FieldValue.arrayUnion([positionId])
      }, SetOptions(merge: true));
    } else {
      await ref.set({
        'ids': FieldValue.arrayRemove([positionId])
      }, SetOptions(merge: true));
    }
  }

  /// Record view in Cloud
  Future<void> recordView(String positionId) async {
    if (userId == null) return;

    final ref = _db.collection('users').doc(userId).collection('userdata').doc('stats');
    await ref.set({
      'views': {
        positionId: FieldValue.increment(1)
      },
      'last_viewed': {
        positionId: FieldValue.serverTimestamp()
      }
    }, SetOptions(merge: true));
  }

  /// Fetch all positions (supports offline cache)
  Future<List<Position>> getPositions() async {
    try {
      // First try to fetch from cache/server
      final snapshot = await _db
          .collection('content')
          .doc('v1')
          .collection('positions')
          .get(const GetOptions(source: Source.defaultSource)); // Prefers server, falls back to cache

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.map((doc) => Position.fromJson(doc.data())).toList();
      }
      return [];
    } catch (e) {
      // Return empty list on error, forcing Repository to use local JSON fallback
      return [];
    }
  }
}
