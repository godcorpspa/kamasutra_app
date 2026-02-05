import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

/// Repository per gestire i dati utente su Firestore
class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  // Singleton
  static final UserRepository _instance = UserRepository._internal();
  factory UserRepository() => _instance;
  UserRepository._internal();

  // Reference all'utente corrente
  String? get _userId => _authService.userId;
  
  DocumentReference? get _userDoc => 
      _userId != null ? _firestore.collection('users').doc(_userId) : null;

  // ============ PROFILO UTENTE ============

  /// Crea il profilo utente dopo la registrazione
  Future<void> createUserProfile({
    required String email,
    String? displayName,
  }) async {
    if (_userDoc == null) return;
    
    try {
      // Crea documento utente principale
      await _userDoc!.set({
        'email': email,
        'displayName': displayName,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      // Inizializza progressi
      await _userDoc!.collection('data').doc('progress').set({
        'currentStreak': 0,
        'longestStreak': 0,
        'lastActiveDate': null,
        'positionsExplored': [],
        'positionsTried': [],
        'gamesPlayed': 0,
        'totalTimeMinutes': 0,
        'badges': [],
      }, SetOptions(merge: true));

      // Inizializza preferiti
      await _userDoc!.collection('data').doc('favorites').set({
        'positions': [],
      }, SetOptions(merge: true));

      debugPrint('✅ Profilo utente creato');
    } catch (e) {
      debugPrint('❌ Errore creazione profilo: $e');
    }
  }

  /// Aggiorna ultimo login
  Future<void> updateLastLogin() async {
    if (_userDoc == null) return;
    
    await _userDoc!.update({
      'lastLoginAt': FieldValue.serverTimestamp(),
    });
  }

  // ============ PROGRESSI ============

  /// Ottieni progressi
  Future<Map<String, dynamic>?> getProgress() async {
    if (_userDoc == null) return null;
    
    try {
      final doc = await _userDoc!.collection('data').doc('progress').get();
      return doc.data();
    } catch (e) {
      debugPrint('Errore lettura progressi: $e');
      return null;
    }
  }

  /// Aggiungi posizione esplorata
  Future<void> addPositionExplored(String positionId) async {
    if (_userDoc == null) return;
    
    await _userDoc!.collection('data').doc('progress').update({
      'positionsExplored': FieldValue.arrayUnion([positionId]),
      'lastActiveDate': FieldValue.serverTimestamp(),
    });
  }

  /// Incrementa partite giocate
  Future<void> incrementGamesPlayed() async {
    if (_userDoc == null) return;
    
    await _userDoc!.collection('data').doc('progress').update({
      'gamesPlayed': FieldValue.increment(1),
    });
  }

  /// Aggiungi badge
  Future<void> addBadge(String badgeId) async {
    if (_userDoc == null) return;
    
    await _userDoc!.collection('data').doc('progress').update({
      'badges': FieldValue.arrayUnion([badgeId]),
    });
  }

  // ============ PREFERITI ============

  /// Aggiungi ai preferiti
  Future<void> addFavorite(String positionId) async {
    if (_userDoc == null) return;
    
    await _userDoc!.collection('data').doc('favorites').update({
      'positions': FieldValue.arrayUnion([positionId]),
    });
  }

  /// Rimuovi dai preferiti
  Future<void> removeFavorite(String positionId) async {
    if (_userDoc == null) return;
    
    await _userDoc!.collection('data').doc('favorites').update({
      'positions': FieldValue.arrayRemove([positionId]),
    });
  }

  /// Ottieni lista preferiti
  Future<List<String>> getFavorites() async {
    if (_userDoc == null) return [];
    
    try {
      final doc = await _userDoc!.collection('data').doc('favorites').get();
      final data = doc.data();
      if (data == null) return [];
      return List<String>.from(data['positions'] ?? []);
    } catch (e) {
      debugPrint('Errore lettura preferiti: $e');
      return [];
    }
  }

  /// Stream dei preferiti (per aggiornamenti real-time)
  Stream<List<String>> favoritesStream() {
    if (_userDoc == null) return Stream.value([]);
    
    return _userDoc!.collection('data').doc('favorites').snapshots().map((doc) {
      final data = doc.data();
      if (data == null) return <String>[];
      return List<String>.from(data['positions'] ?? []);
    });
  }

  // ============ CRONOLOGIA ============

  /// Aggiungi alla cronologia
  Future<void> addToHistory({
    required String positionId,
    required String reaction,
  }) async {
    if (_userDoc == null) return;
    
    await _userDoc!.collection('history').add({
      'positionId': positionId,
      'reaction': reaction,
      'date': FieldValue.serverTimestamp(),
    });
  }

  // ============ SALVATAGGI GIOCHI ============

  /// Salva dati gioco
  Future<void> saveGameData(String gameId, Map<String, dynamic> data) async {
    if (_userDoc == null) return;
    
    await _userDoc!.collection('games').doc(gameId).set({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Ottieni dati gioco
  Future<Map<String, dynamic>?> getGameData(String gameId) async {
    if (_userDoc == null) return null;
    
    try {
      final doc = await _userDoc!.collection('games').doc(gameId).get();
      return doc.data();
    } catch (e) {
      return null;
    }
  }

  /// Salva love note
  Future<void> saveLoveNote(String text) async {
    if (_userDoc == null) return;
    
    await _userDoc!.collection('loveNotes').add({
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Salva fantasy scenario
  Future<void> saveFantasyScenario(String story) async {
    if (_userDoc == null) return;
    
    await _userDoc!.collection('fantasyScenarios').add({
      'story': story,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
