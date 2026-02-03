import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'game.g.dart';

/// Game intensity levels
enum GameIntensity {
  soft,    // 🌸
  spicy,   // 🔥
  extraSpicy, // 🌶️
}

/// Game types
enum GameType {
  gooseGame,
  wheel,
  truthDare,
  hotCold,
  loveNotes,
  fantasyBuilder,
  complimentBattle,
  questionQuest,
  twoMinutes,
  intimacyMap,
  soundtrack,
  mirrorChallenge,
}

/// Position reaction types for history tracking
enum PositionReaction {
  loved,     // ❤️ Loved it
  liked,     // 👍 Liked it  
  neutral,   // 😐 Neutral
  skipped,   // ⏭️ Skipped
  tooHard,   // 😰 Too hard
}

/// Mini game definition
@JsonSerializable()
class MiniGame extends Equatable {
  final String id;
  final GameType type;
  final String nameIt;
  final String nameEn;
  final String descriptionIt;
  final String descriptionEn;
  final String rulesIt;
  final String rulesEn;
  final int minPlayers;
  final int maxPlayers;
  final int durationMinutes;
  final List<GameIntensity> availableIntensities;
  final String iconRef;
  final bool isUnlocked;
  final int timesPlayed;

  const MiniGame({
    required this.id,
    required this.type,
    required this.nameIt,
    required this.nameEn,
    required this.descriptionIt,
    required this.descriptionEn,
    required this.rulesIt,
    required this.rulesEn,
    this.minPlayers = 2,
    this.maxPlayers = 2,
    required this.durationMinutes,
    required this.availableIntensities,
    required this.iconRef,
    this.isUnlocked = true,
    this.timesPlayed = 0,
  });

  String getName(String locale) => locale == 'it' ? nameIt : nameEn;
  String getDescription(String locale) => locale == 'it' ? descriptionIt : descriptionEn;
  String getRules(String locale) => locale == 'it' ? rulesIt : rulesEn;

  /// Get duration display string
  String getDurationDisplay(String locale) {
    if (durationMinutes < 60) {
      return '$durationMinutes min';
    }
    final hours = durationMinutes ~/ 60;
    final mins = durationMinutes % 60;
    if (mins == 0) {
      return locale == 'it' ? '$hours ora' : '$hours hr';
    }
    return locale == 'it' ? '$hours ora $mins min' : '$hours hr $mins min';
  }

  MiniGame copyWith({
    String? id,
    GameType? type,
    String? nameIt,
    String? nameEn,
    String? descriptionIt,
    String? descriptionEn,
    String? rulesIt,
    String? rulesEn,
    int? minPlayers,
    int? maxPlayers,
    int? durationMinutes,
    List<GameIntensity>? availableIntensities,
    String? iconRef,
    bool? isUnlocked,
    int? timesPlayed,
  }) {
    return MiniGame(
      id: id ?? this.id,
      type: type ?? this.type,
      nameIt: nameIt ?? this.nameIt,
      nameEn: nameEn ?? this.nameEn,
      descriptionIt: descriptionIt ?? this.descriptionIt,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      rulesIt: rulesIt ?? this.rulesIt,
      rulesEn: rulesEn ?? this.rulesEn,
      minPlayers: minPlayers ?? this.minPlayers,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      availableIntensities: availableIntensities ?? this.availableIntensities,
      iconRef: iconRef ?? this.iconRef,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      timesPlayed: timesPlayed ?? this.timesPlayed,
    );
  }

  factory MiniGame.fromJson(Map<String, dynamic> json) => _$MiniGameFromJson(json);
  Map<String, dynamic> toJson() => _$MiniGameToJson(this);

  @override
  List<Object?> get props => [
    id, type, nameIt, nameEn, descriptionIt, descriptionEn,
    rulesIt, rulesEn, minPlayers, maxPlayers, durationMinutes,
    availableIntensities, iconRef, isUnlocked, timesPlayed,
  ];
}

/// Session types
enum SessionType {
  shuffle,
  game,
}

/// Session model for tracking activity
@JsonSerializable()
class Session extends Equatable {
  final String id;
  final SessionType type;
  final DateTime startedAt;
  final DateTime? endedAt;
  final Map<String, dynamic>? filters;
  final List<String> positionIds;
  final int currentIndex;
  final bool completed;
  final String? gameId;
  final Map<String, dynamic>? gameState;

  const Session({
    required this.id,
    required this.type,
    required this.startedAt,
    this.endedAt,
    this.filters,
    this.positionIds = const [],
    this.currentIndex = 0,
    this.completed = false,
    this.gameId,
    this.gameState,
  });

  /// Duration of session
  Duration? get duration {
    if (endedAt == null) return null;
    return endedAt!.difference(startedAt);
  }

  Session copyWith({
    String? id,
    SessionType? type,
    DateTime? startedAt,
    DateTime? endedAt,
    Map<String, dynamic>? filters,
    List<String>? positionIds,
    int? currentIndex,
    bool? completed,
    String? gameId,
    Map<String, dynamic>? gameState,
  }) {
    return Session(
      id: id ?? this.id,
      type: type ?? this.type,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      filters: filters ?? this.filters,
      positionIds: positionIds ?? this.positionIds,
      currentIndex: currentIndex ?? this.currentIndex,
      completed: completed ?? this.completed,
      gameId: gameId ?? this.gameId,
      gameState: gameState ?? this.gameState,
    );
  }

  factory Session.fromJson(Map<String, dynamic> json) => _$SessionFromJson(json);
  Map<String, dynamic> toJson() => _$SessionToJson(this);

  @override
  List<Object?> get props => [
    id, type, startedAt, endedAt, filters,
    positionIds, currentIndex, completed, gameId, gameState,
  ];
}

/// History entry for position views
@JsonSerializable()
class HistoryEntry extends Equatable {
  final String id;
  final String positionId;
  final DateTime viewedAt;
  final String? reaction; // loved, liked, neutral, skipped, too_hard
  final String? notes;

  const HistoryEntry({
    required this.id,
    required this.positionId,
    required this.viewedAt,
    this.reaction,
    this.notes,
  });

  HistoryEntry copyWith({
    String? id,
    String? positionId,
    DateTime? viewedAt,
    String? reaction,
    String? notes,
  }) {
    return HistoryEntry(
      id: id ?? this.id,
      positionId: positionId ?? this.positionId,
      viewedAt: viewedAt ?? this.viewedAt,
      reaction: reaction ?? this.reaction,
      notes: notes ?? this.notes,
    );
  }

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => _$HistoryEntryFromJson(json);
  Map<String, dynamic> toJson() => _$HistoryEntryToJson(this);

  @override
  List<Object?> get props => [id, positionId, viewedAt, reaction, notes];
}

/// Badge model
@JsonSerializable()
class Badge extends Equatable {
  final String id;
  final String nameIt;
  final String nameEn;
  final String descriptionIt;
  final String descriptionEn;
  final String iconRef;
  final DateTime? unlockedAt;
  final Map<String, dynamic> criteria;

  const Badge({
    required this.id,
    required this.nameIt,
    required this.nameEn,
    required this.descriptionIt,
    required this.descriptionEn,
    required this.iconRef,
    this.unlockedAt,
    required this.criteria,
  });

  bool get isUnlocked => unlockedAt != null;
  
  String getName(String locale) => locale == 'it' ? nameIt : nameEn;
  String getDescription(String locale) => locale == 'it' ? descriptionIt : descriptionEn;

  Badge copyWith({
    String? id,
    String? nameIt,
    String? nameEn,
    String? descriptionIt,
    String? descriptionEn,
    String? iconRef,
    DateTime? unlockedAt,
    Map<String, dynamic>? criteria,
  }) {
    return Badge(
      id: id ?? this.id,
      nameIt: nameIt ?? this.nameIt,
      nameEn: nameEn ?? this.nameEn,
      descriptionIt: descriptionIt ?? this.descriptionIt,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      iconRef: iconRef ?? this.iconRef,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      criteria: criteria ?? this.criteria,
    );
  }

  factory Badge.fromJson(Map<String, dynamic> json) => _$BadgeFromJson(json);
  Map<String, dynamic> toJson() => _$BadgeToJson(this);

  @override
  List<Object?> get props => [
    id, nameIt, nameEn, descriptionIt, descriptionEn,
    iconRef, unlockedAt, criteria,
  ];
}

/// Streak tracking
@JsonSerializable()
class Streak extends Equatable {
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastActivityDate;
  final int graceDaysUsed;
  final int graceDaysAllowed;

  const Streak({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastActivityDate,
    this.graceDaysUsed = 0,
    this.graceDaysAllowed = 2,
  });

  /// Check if streak is active today
  bool get isActiveToday {
    if (lastActivityDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastDay = DateTime(
      lastActivityDate!.year,
      lastActivityDate!.month,
      lastActivityDate!.day,
    );
    return today.isAtSameMomentAs(lastDay);
  }

  /// Check if streak can be continued (within grace period)
  bool get canContinue {
    if (lastActivityDate == null) return true;
    final now = DateTime.now();
    final daysSinceLastActivity = now.difference(lastActivityDate!).inDays;
    return daysSinceLastActivity <= (graceDaysAllowed + 1);
  }

  Streak copyWith({
    int? currentStreak,
    int? longestStreak,
    DateTime? lastActivityDate,
    int? graceDaysUsed,
    int? graceDaysAllowed,
  }) {
    return Streak(
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastActivityDate: lastActivityDate ?? this.lastActivityDate,
      graceDaysUsed: graceDaysUsed ?? this.graceDaysUsed,
      graceDaysAllowed: graceDaysAllowed ?? this.graceDaysAllowed,
    );
  }

  factory Streak.fromJson(Map<String, dynamic> json) => _$StreakFromJson(json);
  Map<String, dynamic> toJson() => _$StreakToJson(this);

  @override
  List<Object?> get props => [
    currentStreak, longestStreak, lastActivityDate,
    graceDaysUsed, graceDaysAllowed,
  ];
}
