import 'package:cloud_firestore/cloud_firestore.dart';

/// User settings model - synced to Firebase
class UserSettings {
  final String locale;
  final bool darkMode;
  final String illustrationStyle;
  final String defaultIntensity;
  final int shuffleCardCount;
  final int consentCheckInInterval;
  final bool soundEffects;
  final bool hapticFeedback;

  const UserSettings({
    this.locale = 'it',
    this.darkMode = true,
    this.illustrationStyle = 'line_art',
    this.defaultIntensity = 'soft',
    this.shuffleCardCount = 5,
    this.consentCheckInInterval = 15,
    this.soundEffects = true,
    this.hapticFeedback = true,
  });

  factory UserSettings.fromFirestore(Map<String, dynamic>? data) {
    if (data == null) return const UserSettings();
    return UserSettings(
      locale: data['locale'] as String? ?? 'it',
      darkMode: data['darkMode'] as bool? ?? true,
      illustrationStyle: data['illustrationStyle'] as String? ?? 'line_art',
      defaultIntensity: data['defaultIntensity'] as String? ?? 'soft',
      shuffleCardCount: data['shuffleCardCount'] as int? ?? 5,
      consentCheckInInterval: data['consentCheckInInterval'] as int? ?? 15,
      soundEffects: data['soundEffects'] as bool? ?? true,
      hapticFeedback: data['hapticFeedback'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'locale': locale,
    'darkMode': darkMode,
    'illustrationStyle': illustrationStyle,
    'defaultIntensity': defaultIntensity,
    'shuffleCardCount': shuffleCardCount,
    'consentCheckInInterval': consentCheckInInterval,
    'soundEffects': soundEffects,
    'hapticFeedback': hapticFeedback,
  };

  UserSettings copyWith({
    String? locale,
    bool? darkMode,
    String? illustrationStyle,
    String? defaultIntensity,
    int? shuffleCardCount,
    int? consentCheckInInterval,
    bool? soundEffects,
    bool? hapticFeedback,
  }) {
    return UserSettings(
      locale: locale ?? this.locale,
      darkMode: darkMode ?? this.darkMode,
      illustrationStyle: illustrationStyle ?? this.illustrationStyle,
      defaultIntensity: defaultIntensity ?? this.defaultIntensity,
      shuffleCardCount: shuffleCardCount ?? this.shuffleCardCount,
      consentCheckInInterval: consentCheckInInterval ?? this.consentCheckInInterval,
      soundEffects: soundEffects ?? this.soundEffects,
      hapticFeedback: hapticFeedback ?? this.hapticFeedback,
    );
  }
}

/// User progress model - synced to Firebase
class UserProgress {
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastActiveDate;
  final int graceDaysRemaining;
  final int totalTimeMinutes;
  final int gamesPlayed;
  final List<String> unlockedBadges;
  final Map<String, DateTime> badgeUnlockDates;

  const UserProgress({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastActiveDate,
    this.graceDaysRemaining = 2,
    this.totalTimeMinutes = 0,
    this.gamesPlayed = 0,
    this.unlockedBadges = const [],
    this.badgeUnlockDates = const {},
  });

  factory UserProgress.fromFirestore(Map<String, dynamic>? data) {
    if (data == null) return const UserProgress();
    
    // Parse badge unlock dates
    Map<String, DateTime> dates = {};
    if (data['badgeUnlockDates'] != null) {
      final rawDates = data['badgeUnlockDates'] as Map<String, dynamic>;
      dates = rawDates.map((key, value) {
        if (value is Timestamp) {
          return MapEntry(key, value.toDate());
        }
        return MapEntry(key, DateTime.now());
      });
    }
    
    return UserProgress(
      currentStreak: data['currentStreak'] as int? ?? 0,
      longestStreak: data['longestStreak'] as int? ?? 0,
      lastActiveDate: (data['lastActiveDate'] as Timestamp?)?.toDate(),
      graceDaysRemaining: data['graceDaysRemaining'] as int? ?? 2,
      totalTimeMinutes: data['totalTimeMinutes'] as int? ?? 0,
      gamesPlayed: data['gamesPlayed'] as int? ?? 0,
      unlockedBadges: List<String>.from(data['unlockedBadges'] ?? []),
      badgeUnlockDates: dates,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'currentStreak': currentStreak,
    'longestStreak': longestStreak,
    'lastActiveDate': lastActiveDate != null ? Timestamp.fromDate(lastActiveDate!) : null,
    'graceDaysRemaining': graceDaysRemaining,
    'totalTimeMinutes': totalTimeMinutes,
    'gamesPlayed': gamesPlayed,
    'unlockedBadges': unlockedBadges,
    'badgeUnlockDates': badgeUnlockDates.map(
      (key, value) => MapEntry(key, Timestamp.fromDate(value)),
    ),
  };

  UserProgress copyWith({
    int? currentStreak,
    int? longestStreak,
    DateTime? lastActiveDate,
    int? graceDaysRemaining,
    int? totalTimeMinutes,
    int? gamesPlayed,
    List<String>? unlockedBadges,
    Map<String, DateTime>? badgeUnlockDates,
  }) {
    return UserProgress(
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      graceDaysRemaining: graceDaysRemaining ?? this.graceDaysRemaining,
      totalTimeMinutes: totalTimeMinutes ?? this.totalTimeMinutes,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      unlockedBadges: unlockedBadges ?? this.unlockedBadges,
      badgeUnlockDates: badgeUnlockDates ?? this.badgeUnlockDates,
    );
  }

  /// Format total time as "Xh Ym"
  String get formattedTotalTime {
    if (totalTimeMinutes == 0) return '0m';
    final hours = totalTimeMinutes ~/ 60;
    final mins = totalTimeMinutes % 60;
    if (hours == 0) return '${mins}m';
    if (mins == 0) return '${hours}h';
    return '${hours}h ${mins}m';
  }
}

/// Position data for a user
class PositionUserData {
  final int views;
  final DateTime? lastViewed;
  final String? reaction;

  const PositionUserData({
    this.views = 0,
    this.lastViewed,
    this.reaction,
  });

  factory PositionUserData.fromMap(Map<String, dynamic> data) {
    return PositionUserData(
      views: data['views'] as int? ?? 0,
      lastViewed: (data['lastViewed'] as Timestamp?)?.toDate(),
      reaction: data['reaction'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'views': views,
    'lastViewed': lastViewed != null ? Timestamp.fromDate(lastViewed!) : null,
    if (reaction != null) 'reaction': reaction,
  };
}

/// User positions data - favorites and explored
class UserPositions {
  final List<String> favorites;
  final Map<String, PositionUserData> explored;

  const UserPositions({
    this.favorites = const [],
    this.explored = const {},
  });

  factory UserPositions.fromFirestore(Map<String, dynamic>? data) {
    if (data == null) return const UserPositions();
    
    Map<String, PositionUserData> exploredMap = {};
    if (data['explored'] != null) {
      final rawExplored = data['explored'] as Map<String, dynamic>;
      exploredMap = rawExplored.map((key, value) => 
        MapEntry(key, PositionUserData.fromMap(value as Map<String, dynamic>))
      );
    }
    
    return UserPositions(
      favorites: List<String>.from(data['favorites'] ?? []),
      explored: exploredMap,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'favorites': favorites,
    'explored': explored.map((key, value) => MapEntry(key, value.toMap())),
  };
}

/// History entry
class HistoryEntry {
  final String? id;
  final String positionId;
  final String positionName;
  final String? category;
  final String reaction;
  final DateTime date;

  const HistoryEntry({
    this.id,
    required this.positionId,
    required this.positionName,
    this.category,
    required this.reaction,
    required this.date,
  });

  factory HistoryEntry.fromFirestore(String id, Map<String, dynamic> data) {
    return HistoryEntry(
      id: id,
      positionId: data['positionId'] as String? ?? '',
      positionName: data['positionName'] as String? ?? '',
      category: data['category'] as String?,
      reaction: data['reaction'] as String? ?? '👍',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'positionId': positionId,
    'positionName': positionName,
    if (category != null) 'category': category,
    'reaction': reaction,
    'date': Timestamp.fromDate(date),
  };
}

// ============ GAME DATA MODELS ============

/// Love Notes game data
class LoveNotesData {
  final List<Map<String, dynamic>> savedNotes;
  final DateTime? updatedAt;

  const LoveNotesData({
    this.savedNotes = const [],
    this.updatedAt,
  });

  factory LoveNotesData.fromFirestore(Map<String, dynamic>? data) {
    if (data == null) return const LoveNotesData();
    return LoveNotesData(
      savedNotes: List<Map<String, dynamic>>.from(data['notes'] ?? []),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'notes': savedNotes,
    'updatedAt': FieldValue.serverTimestamp(),
  };
}

/// Fantasy Builder game data
class FantasyBuilderData {
  final List<Map<String, dynamic>> scenarios;
  final DateTime? updatedAt;

  const FantasyBuilderData({
    this.scenarios = const [],
    this.updatedAt,
  });

  factory FantasyBuilderData.fromFirestore(Map<String, dynamic>? data) {
    if (data == null) return const FantasyBuilderData();
    return FantasyBuilderData(
      scenarios: List<Map<String, dynamic>>.from(data['scenarios'] ?? []),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'scenarios': scenarios,
    'updatedAt': FieldValue.serverTimestamp(),
  };
}

/// Intimacy Map game data
class IntimacyMapData {
  final Map<String, Map<String, int>> player1Map;
  final Map<String, Map<String, int>> player2Map;
  final DateTime? updatedAt;

  const IntimacyMapData({
    this.player1Map = const {},
    this.player2Map = const {},
    this.updatedAt,
  });

  factory IntimacyMapData.fromFirestore(Map<String, dynamic>? data) {
    if (data == null) return const IntimacyMapData();
    
    Map<String, Map<String, int>> parseMap(dynamic raw) {
      if (raw == null) return {};
      final map = raw as Map<String, dynamic>;
      return map.map((key, value) => MapEntry(
        key,
        Map<String, int>.from(value as Map),
      ));
    }
    
    return IntimacyMapData(
      player1Map: parseMap(data['player1Map']),
      player2Map: parseMap(data['player2Map']),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'player1Map': player1Map,
    'player2Map': player2Map,
    'updatedAt': FieldValue.serverTimestamp(),
  };
}

/// Soundtrack game data
class SoundtrackData {
  final Map<String, String> songs; // promptKey -> songTitle
  final DateTime? updatedAt;

  const SoundtrackData({
    this.songs = const {},
    this.updatedAt,
  });

  factory SoundtrackData.fromFirestore(Map<String, dynamic>? data) {
    if (data == null) return const SoundtrackData();
    return SoundtrackData(
      songs: Map<String, String>.from(data['songs'] ?? {}),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'songs': songs,
    'updatedAt': FieldValue.serverTimestamp(),
  };
}

/// Question Quest game data
class QuestionQuestData {
  final int currentLevel;
  final List<String> answeredQuestions;
  final DateTime? updatedAt;

  const QuestionQuestData({
    this.currentLevel = 1,
    this.answeredQuestions = const [],
    this.updatedAt,
  });

  factory QuestionQuestData.fromFirestore(Map<String, dynamic>? data) {
    if (data == null) return const QuestionQuestData();
    return QuestionQuestData(
      currentLevel: data['currentLevel'] as int? ?? 1,
      answeredQuestions: List<String>.from(data['answeredQuestions'] ?? []),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'currentLevel': currentLevel,
    'answeredQuestions': answeredQuestions,
    'updatedAt': FieldValue.serverTimestamp(),
  };
}

/// Compliment Battle game data
class ComplimentBattleData {
  final int player1Score;
  final int player2Score;
  final List<Map<String, dynamic>> sessions;
  final DateTime? updatedAt;

  const ComplimentBattleData({
    this.player1Score = 0,
    this.player2Score = 0,
    this.sessions = const [],
    this.updatedAt,
  });

  factory ComplimentBattleData.fromFirestore(Map<String, dynamic>? data) {
    if (data == null) return const ComplimentBattleData();
    return ComplimentBattleData(
      player1Score: data['player1Score'] as int? ?? 0,
      player2Score: data['player2Score'] as int? ?? 0,
      sessions: List<Map<String, dynamic>>.from(data['sessions'] ?? []),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'player1Score': player1Score,
    'player2Score': player2Score,
    'sessions': sessions,
    'updatedAt': FieldValue.serverTimestamp(),
  };
}

/// Truth or Dare game data
class TruthDareData {
  final int truthsAnswered;
  final int daresCompleted;
  final DateTime? updatedAt;

  const TruthDareData({
    this.truthsAnswered = 0,
    this.daresCompleted = 0,
    this.updatedAt,
  });

  factory TruthDareData.fromFirestore(Map<String, dynamic>? data) {
    if (data == null) return const TruthDareData();
    return TruthDareData(
      truthsAnswered: data['truthsAnswered'] as int? ?? 0,
      daresCompleted: data['daresCompleted'] as int? ?? 0,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'truthsAnswered': truthsAnswered,
    'daresCompleted': daresCompleted,
    'updatedAt': FieldValue.serverTimestamp(),
  };
}
