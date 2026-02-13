import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'preferences_service.dart';

/// Sincronizzazione dati utente tra storage locale (SharedPreferences) e Firestore.
///
/// Principio: l'app continua a usare i dati locali per UI/UX veloce e offline.
/// Firestore viene usato come backup/sync multi-device.
///
/// Sicurezza: il PIN hash NON viene mai caricato sul cloud.
class UserDataSyncService {
  UserDataSyncService._internal();

  static final UserDataSyncService instance = UserDataSyncService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  StreamSubscription<User?>? _authSub;

  String? _uid;
  bool _started = false;

  Completer<void>? _initialSyncCompleter;

  /// Avvia la sync (idempotente). Puoi chiamarla una volta in main().
  void start() {
    if (_started) return;
    _started = true;
    _initialSyncCompleter ??= Completer<void>();

    try {
      _authSub = FirebaseAuth.instance.authStateChanges().listen(
        (user) async {
          await _handleAuthState(user);
        },
        onError: (e) {
          debugPrint('⚠️ Sync authState error: $e');
          _completeInitialSyncIfPending();
        },
      );
    } catch (e) {
      // Firebase non disponibile o non inizializzato
      debugPrint('⚠️ Sync non avviata (Firebase non disponibile): $e');
      _completeInitialSyncIfPending();
    }
  }

  Future<void> dispose() async {
    await _authSub?.cancel();
    _authSub = null;
    _uid = null;
    _started = false;
  }

  /// Attende il primo giro di sync (utile prima di caricare dati utente).
  Future<void> waitInitialSync({Duration timeout = const Duration(seconds: 2)}) async {
    final completer = _initialSyncCompleter;
    if (completer == null) return;

    try {
      await completer.future.timeout(timeout);
    } catch (_) {
      // Timeout: non blocchiamo la UI.
    }
  }

  bool get isLoggedIn => _uid != null;

  // =============================
  // Public API (mirror write)
  // =============================

  Future<void> syncSettingsPatch(Map<String, dynamic> patch) async {
    final uid = _uid;
    if (uid == null) return;

    try {
      await _settingsDoc(uid).set(
        {
          ..._stripNulls(patch),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('⚠️ syncSettingsPatch failed: $e');
    }
  }

  Future<void> syncFavorite(String positionId, bool isFavorite) async {
    final uid = _uid;
    if (uid == null) return;

    try {
      // 1) Preferiti array (comodo per query)
      await _favoritesDoc(uid).set({
        'positions': isFavorite
            ? FieldValue.arrayUnion([positionId])
            : FieldValue.arrayRemove([positionId]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 2) Doc posizione
      await _positionDoc(uid, positionId).set({
        'isFavorite': isFavorite,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('⚠️ syncFavorite failed: $e');
    }
  }

  Future<void> syncView(String positionId, {DateTime? viewedAt}) async {
    final uid = _uid;
    if (uid == null) return;

    final now = viewedAt ?? DateTime.now();

    try {
      await _positionDoc(uid, positionId).set({
        'timesViewed': FieldValue.increment(1),
        'lastViewed': Timestamp.fromDate(now),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('⚠️ syncView failed: $e');
    }
  }

  Future<void> syncHistoryEntry({
    required String positionId,
    required DateTime viewedAt,
    required String reaction,
    String? notes,
  }) async {
    final uid = _uid;
    if (uid == null) return;

    try {
      await _historyCol(uid).add({
        'positionId': positionId,
        'reaction': reaction,
        if (notes != null) 'notes': notes,
        'viewedAt': Timestamp.fromDate(viewedAt),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('⚠️ syncHistoryEntry failed: $e');
    }
  }

  Future<void> syncSession(Map<String, dynamic> session) async {
    final uid = _uid;
    if (uid == null) return;

    final sessionId = (session['id'] ?? '').toString();
    if (sessionId.isEmpty) return;

    try {
      await _sessionDoc(uid, sessionId).set({
        ..._stripNulls(session),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('⚠️ syncSession failed: $e');
    }
  }

  Future<void> clearCloudHistory() async {
    final uid = _uid;
    if (uid == null) return;

    try {
      // Cancella a batch (max 500 per batch)
      while (true) {
        final snap = await _historyCol(uid).limit(500).get();
        if (snap.docs.isEmpty) break;

        final batch = _db.batch();
        for (final d in snap.docs) {
          batch.delete(d.reference);
        }
        await batch.commit();

        if (snap.docs.length < 500) break;
      }
    } catch (e) {
      debugPrint('⚠️ clearCloudHistory failed: $e');
    }
  }

  Future<void> clearCloudUserData() async {
    final uid = _uid;
    if (uid == null) return;

    try {
      // 1) history
      await clearCloudHistory();

      // 2) sessions
      while (true) {
        final snap = await _sessionsCol(uid).limit(500).get();
        if (snap.docs.isEmpty) break;
        final batch = _db.batch();
        for (final d in snap.docs) {
          batch.delete(d.reference);
        }
        await batch.commit();
        if (snap.docs.length < 500) break;
      }

      // 3) positions
      while (true) {
        final snap = await _positionsCol(uid).limit(500).get();
        if (snap.docs.isEmpty) break;
        final batch = _db.batch();
        for (final d in snap.docs) {
          batch.delete(d.reference);
        }
        await batch.commit();
        if (snap.docs.length < 500) break;
      }

      // 4) data docs
      await _favoritesDoc(uid).delete();
      await _progressDoc(uid).delete();
      await _settingsDoc(uid).delete();

      // 5) lascia il profilo base (email, createdAt) intatto
    } catch (e) {
      debugPrint('⚠️ clearCloudUserData failed: $e');
    }
  }

  // =============================
  // Auth flow & initial sync
  // =============================

  void _completeInitialSyncIfPending() {
    final c = _initialSyncCompleter;
    if (c != null && !c.isCompleted) {
      c.complete();
    }
  }

  Future<void> _handleAuthState(User? user) async {
    // reset completer per ogni login
    if (_initialSyncCompleter?.isCompleted == true) {
      _initialSyncCompleter = Completer<void>();
    }

    if (user == null) {
      _uid = null;
      _completeInitialSyncIfPending();
      return;
    }

    _uid = user.uid;

    try {
      await _ensureUserProfile(user);
      await _migrateLocalToCloudIfNeeded(user);
      await _pullCloudToLocal(user);
    } catch (e) {
      debugPrint('⚠️ Initial sync error: $e');
    } finally {
      _completeInitialSyncIfPending();
    }
  }

  Future<void> _ensureUserProfile(User user) async {
    try {
      await _userDoc(user.uid).set({
        'email': user.email,
        'displayName': user.displayName,
        'lastLoginAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('⚠️ ensureUserProfile failed: $e');
    }
  }

  Future<void> _migrateLocalToCloudIfNeeded(User user) async {
    final prefs = PreferencesService.instance;
    final migrationKey = 'migration_v1_done_${user.uid}';

    if (prefs.getBool(migrationKey) == true) {
      return;
    }

    // Push best-effort
    await _pushAllLocalToCloud(user);

    // Segna migrazione completata
    try {
      await prefs.setBool(migrationKey, true);
    } catch (_) {
      // ignore
    }
  }

  Future<void> _pushAllLocalToCloud(User user) async {
    final prefs = PreferencesService.instance;
    final uid = user.uid;

    // SETTINGS (NO pin_hash!)
    final settings = <String, dynamic>{
      'age_verified': prefs.getBool('age_verified'),
      'onboarding_completed': prefs.getBool('onboarding_completed'),
      'first_launch_date': prefs.getString('first_launch_date'),
      'pin_enabled': prefs.getBool('pin_enabled'),
      'biometric_enabled': prefs.getBool('biometric_enabled'),
      'discrete_icon_enabled': prefs.getBool('discrete_icon_enabled'),
      'panic_exit_enabled': prefs.getBool('panic_exit_enabled'),
      'locale': prefs.getString('locale'),
      'dark_mode': prefs.getBool('dark_mode'),
      'illustration_style': prefs.getString('illustration_style'),
      'default_intensity': prefs.getString('default_intensity'),
      'shuffle_card_count': prefs.getInt('shuffle_card_count'),
      'consent_check_in_interval': prefs.getInt('consent_check_in_interval'),
      'sound_effects': prefs.getBool('sound_effects'),
      'haptic_feedback': prefs.getBool('haptic_feedback'),
    };

    try {
      await _settingsDoc(uid).set({
        ..._stripNulls(settings),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('⚠️ push settings failed: $e');
    }

    // FAVORITES
    final favorites = prefs.favoritePositionIds;
    try {
      await _favoritesDoc(uid).set({
        'positions': favorites,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('⚠️ push favorites failed: $e');
    }

    // PROGRESS (streak + badges)
    try {
      await _progressDoc(uid).set({
        'current_streak': prefs.getInt('current_streak') ?? 0,
        'longest_streak': prefs.getInt('longest_streak') ?? 0,
        'last_streak_date': prefs.getString('last_streak_date'),
        'unlocked_badges': prefs.unlockedBadgeIds,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('⚠️ push progress failed: $e');
    }

    // POSITIONS DATA (views/lastViewed/favorite)
    final positionIds = <String>{...favorites};
    for (final key in prefs.keys) {
      if (key.startsWith('position_') && key.endsWith('_views')) {
        final id = key.substring('position_'.length, key.length - '_views'.length);
        if (id.isNotEmpty) positionIds.add(id);
      }
      if (key.startsWith('position_') && key.endsWith('_last_viewed')) {
        final id = key.substring('position_'.length, key.length - '_last_viewed'.length);
        if (id.isNotEmpty) positionIds.add(id);
      }
    }

    // Batch scritture in blocchi da 450 (per stare larghi).
    final idsList = positionIds.toList(growable: false);
    for (var i = 0; i < idsList.length; i += 450) {
      final chunk = idsList.sublist(i, i + 450 > idsList.length ? idsList.length : i + 450);
      final batch = _db.batch();

      for (final positionId in chunk) {
        final views = prefs.getInt('position_${positionId}_views') ?? 0;
        final lastViewedStr = prefs.getString('position_${positionId}_last_viewed');
        DateTime? lastViewed;
        if (lastViewedStr != null) {
          lastViewed = DateTime.tryParse(lastViewedStr);
        }

        batch.set(
          _positionDoc(uid, positionId),
          {
            'isFavorite': favorites.contains(positionId),
            'timesViewed': views,
            if (lastViewed != null) 'lastViewed': Timestamp.fromDate(lastViewed),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      try {
        await batch.commit();
      } catch (e) {
        debugPrint('⚠️ push positions batch failed: $e');
      }
    }

    // HISTORY (max 500 per batch)
    try {
      final history = await prefs.getHistory(limit: 1000);
      final trimmed = history.length > 500 ? history.sublist(history.length - 500) : history;

      if (trimmed.isNotEmpty) {
        final batch = _db.batch();
        var writes = 0;

        for (final h in trimmed) {
          if (writes >= 450) break;
          final positionId = (h['positionId'] ?? '').toString();
          final reaction = (h['reaction'] ?? '').toString();
          final notes = h['notes']?.toString();
          final viewedAtStr = (h['viewedAt'] ?? '').toString();

          DateTime? viewedAt;
          viewedAt = DateTime.tryParse(viewedAtStr);
          viewedAt ??= DateTime.now();

          final ref = _historyCol(uid).doc();
          batch.set(ref, {
            'positionId': positionId,
            'reaction': reaction,
            if (notes != null && notes.isNotEmpty) 'notes': notes,
            'viewedAt': Timestamp.fromDate(viewedAt),
            'createdAt': FieldValue.serverTimestamp(),
          });

          writes += 1;
        }

        await batch.commit();
      }
    } catch (e) {
      debugPrint('⚠️ push history failed: $e');
    }

    // SESSIONS (session_*)
    final sessionKeys = prefs.keys.where((k) => k.startsWith('session_')).toList();
    if (sessionKeys.isNotEmpty) {
      for (var i = 0; i < sessionKeys.length; i += 450) {
        final chunk = sessionKeys.sublist(i, i + 450 > sessionKeys.length ? sessionKeys.length : i + 450);
        final batch = _db.batch();

        for (final key in chunk) {
          final id = key.substring('session_'.length);
          final raw = prefs.getString(key);
          if (raw == null) continue;

          Map<String, dynamic>? decoded;
          try {
            final v = jsonDecode(raw);
            if (v is Map<String, dynamic>) decoded = v;
          } catch (_) {
            decoded = null;
          }

          batch.set(
            _sessionDoc(uid, id),
            {
              'id': id,
              if (decoded != null) ...decoded else 'raw': raw,
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
        }

        try {
          await batch.commit();
        } catch (e) {
          debugPrint('⚠️ push sessions batch failed: $e');
        }
      }
    }
  }

  Future<void> _pullCloudToLocal(User user) async {
    final prefs = PreferencesService.instance;
    final uid = user.uid;

    // SETTINGS
    try {
      final doc = await _settingsDoc(uid).get();
      final data = doc.data();
      if (data != null) {
        await _applySettingsFromCloud(prefs, data);
      }
    } catch (e) {
      debugPrint('⚠️ pull settings failed: $e');
    }

    // FAVORITES
    List<String> cloudFav = <String>[];
    try {
      final doc = await _favoritesDoc(uid).get();
      final data = doc.data();
      if (data != null) {
        cloudFav = List<String>.from(data['positions'] ?? const <String>[]);
      }
    } catch (e) {
      debugPrint('⚠️ pull favorites failed: $e');
    }

    // merge favorites locale + cloud
    final mergedFav = <String>{...prefs.favoritePositionIds, ...cloudFav}.toList();
    mergedFav.sort();
    await prefs.setFavoritePositionIds(mergedFav);

    // POSITIONS
    try {
      final snap = await _positionsCol(uid).get();
      for (final doc in snap.docs) {
        final positionId = doc.id;
        final data = doc.data();

        final cloudViews = (data['timesViewed'] as int?) ?? 0;
        final localViews = prefs.getInt('position_${positionId}_views') ?? 0;
        final bestViews = cloudViews > localViews ? cloudViews : localViews;

        if (bestViews != localViews) {
          await prefs.setInt('position_${positionId}_views', bestViews);
        }

        DateTime? cloudLast;
        final lastViewed = data['lastViewed'];
        if (lastViewed is Timestamp) {
          cloudLast = lastViewed.toDate();
        }

        final localLastStr = prefs.getString('position_${positionId}_last_viewed');
        final localLast = localLastStr != null ? DateTime.tryParse(localLastStr) : null;

        final bestLast = _maxDateTime(localLast, cloudLast);
        if (bestLast != null && (localLast == null || bestLast.isAfter(localLast))) {
          await prefs.setString('position_${positionId}_last_viewed', bestLast.toIso8601String());
        }

        // isFavorite: lo gestiamo tramite lista mergedFav
      }
    } catch (e) {
      debugPrint('⚠️ pull positions failed: $e');
    }

    // PROGRESS (streak + badges)
    try {
      final doc = await _progressDoc(uid).get();
      final data = doc.data();
      if (data != null) {
        // streak
        final cloudCurrent = (data['current_streak'] as int?) ?? 0;
        final cloudLongest = (data['longest_streak'] as int?) ?? 0;

        final localCurrentRaw = prefs.getInt('current_streak');
        final localLongestRaw = prefs.getInt('longest_streak');

        if (localCurrentRaw == null || cloudCurrent > (localCurrentRaw)) {
          await prefs.setInt('current_streak', cloudCurrent);
        }
        if (localLongestRaw == null || cloudLongest > (localLongestRaw)) {
          await prefs.setInt('longest_streak', cloudLongest);
        }

        final cloudLastDate = data['last_streak_date']?.toString();
        if (prefs.getString('last_streak_date') == null && cloudLastDate != null) {
          await prefs.setString('last_streak_date', cloudLastDate);
        }

        // badges (union)
        final cloudBadges = List<String>.from(data['unlocked_badges'] ?? const <String>[]);
        final mergedBadges = <String>{...prefs.unlockedBadgeIds, ...cloudBadges}.toList();
        mergedBadges.sort();
        await prefs.setStringList('unlocked_badges', mergedBadges);
      }
    } catch (e) {
      debugPrint('⚠️ pull progress failed: $e');
    }

    // HISTORY (solo se la locale è vuota o quasi; evita duplicazioni su device già in uso)
    try {
      final localHistoryRaw = prefs.getStringList('history') ?? const <String>[];
      if (localHistoryRaw.isEmpty) {
        // prova a leggere per viewedAt; se non esiste, fallback.
        QuerySnapshot<Map<String, dynamic>> snap;
        try {
          snap = await _historyCol(uid).orderBy('viewedAt', descending: true).limit(500).get();
        } catch (_) {
          snap = await _historyCol(uid).orderBy('createdAt', descending: true).limit(500).get();
        }

        final entries = <Map<String, dynamic>>[];
        for (final d in snap.docs) {
          final data = d.data();
          final ts = (data['viewedAt'] as Timestamp?) ?? (data['createdAt'] as Timestamp?);
          final viewedAt = ts?.toDate();

          entries.add({
            'positionId': (data['positionId'] ?? '').toString(),
            'viewedAt': (viewedAt ?? DateTime.now()).toIso8601String(),
            'reaction': (data['reaction'] ?? '').toString(),
            if (data.containsKey('notes')) 'notes': data['notes'],
          });
        }

        // salvare in ordine cronologico crescente (così reversed.take funziona uguale)
        entries.sort((a, b) => (a['viewedAt'] as String).compareTo(b['viewedAt'] as String));
        await prefs.setHistoryEntries(entries);
      }
    } catch (e) {
      debugPrint('⚠️ pull history failed: $e');
    }
  }

  Future<void> _applySettingsFromCloud(PreferencesService prefs, Map<String, dynamic> cloud) async {
    // Regola: applichiamo solo se la chiave locale non è impostata (raw getter == null).

    Future<void> applyBool(String key, bool? value) async {
      if (value == null) return;
      if (prefs.getBool(key) == null) {
        await prefs.setBool(key, value);
      }
    }

    Future<void> applyInt(String key, int? value) async {
      if (value == null) return;
      if (prefs.getInt(key) == null) {
        await prefs.setInt(key, value);
      }
    }

    Future<void> applyString(String key, String? value) async {
      if (value == null) return;
      if (prefs.getString(key) == null) {
        await prefs.setString(key, value);
      }
    }

    await applyBool('age_verified', cloud['age_verified'] as bool?);
    await applyBool('onboarding_completed', cloud['onboarding_completed'] as bool?);
    await applyString('first_launch_date', cloud['first_launch_date']?.toString());

    // pin_enabled: se locale già true, lo lasciamo; altrimenti prendiamo il cloud.
    final cloudPin = cloud['pin_enabled'] as bool?;
    if (cloudPin != null) {
      final localPin = prefs.getBool('pin_enabled');
      if (localPin == null) {
        await prefs.setBool('pin_enabled', cloudPin);
      }
    }

    await applyBool('biometric_enabled', cloud['biometric_enabled'] as bool?);
    await applyBool('discrete_icon_enabled', cloud['discrete_icon_enabled'] as bool?);
    await applyBool('panic_exit_enabled', cloud['panic_exit_enabled'] as bool?);
    await applyString('locale', cloud['locale']?.toString());
    await applyBool('dark_mode', cloud['dark_mode'] as bool?);
    await applyString('illustration_style', cloud['illustration_style']?.toString());
    await applyString('default_intensity', cloud['default_intensity']?.toString());
    await applyInt('shuffle_card_count', cloud['shuffle_card_count'] as int?);
    await applyInt('consent_check_in_interval', cloud['consent_check_in_interval'] as int?);
    await applyBool('sound_effects', cloud['sound_effects'] as bool?);
    await applyBool('haptic_feedback', cloud['haptic_feedback'] as bool?);
  }

  // =============================
  // Firestore refs
  // =============================

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _db.collection('users').doc(uid);

  DocumentReference<Map<String, dynamic>> _settingsDoc(String uid) =>
      _userDoc(uid).collection('data').doc('settings');

  DocumentReference<Map<String, dynamic>> _favoritesDoc(String uid) =>
      _userDoc(uid).collection('data').doc('favorites');

  DocumentReference<Map<String, dynamic>> _progressDoc(String uid) =>
      _userDoc(uid).collection('data').doc('progress');

  CollectionReference<Map<String, dynamic>> _positionsCol(String uid) =>
      _userDoc(uid).collection('positions');

  DocumentReference<Map<String, dynamic>> _positionDoc(String uid, String positionId) =>
      _positionsCol(uid).doc(positionId);

  CollectionReference<Map<String, dynamic>> _historyCol(String uid) =>
      _userDoc(uid).collection('history');

  CollectionReference<Map<String, dynamic>> _sessionsCol(String uid) =>
      _userDoc(uid).collection('sessions');

  DocumentReference<Map<String, dynamic>> _sessionDoc(String uid, String sessionId) =>
      _sessionsCol(uid).doc(sessionId);

  // =============================
  // Helpers
  // =============================

  Map<String, dynamic> _stripNulls(Map<String, dynamic> map) {
    final out = <String, dynamic>{};
    map.forEach((k, v) {
      if (v != null) out[k] = v;
    });
    return out;
  }

  DateTime? _maxDateTime(DateTime? a, DateTime? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a.isAfter(b) ? a : b;
  }
}
