// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MiniGame _$MiniGameFromJson(Map<String, dynamic> json) => MiniGame(
      id: json['id'] as String,
      type: $enumDecode(_$GameTypeEnumMap, json['type']),
      nameIt: json['nameIt'] as String,
      nameEn: json['nameEn'] as String,
      descriptionIt: json['descriptionIt'] as String,
      descriptionEn: json['descriptionEn'] as String,
      rulesIt: json['rulesIt'] as String,
      rulesEn: json['rulesEn'] as String,
      minPlayers: (json['minPlayers'] as num?)?.toInt() ?? 2,
      maxPlayers: (json['maxPlayers'] as num?)?.toInt() ?? 2,
      durationMinutes: (json['durationMinutes'] as num).toInt(),
      availableIntensities: (json['availableIntensities'] as List<dynamic>)
          .map((e) => $enumDecode(_$GameIntensityEnumMap, e))
          .toList(),
      iconRef: json['iconRef'] as String,
      isUnlocked: json['isUnlocked'] as bool? ?? true,
      timesPlayed: (json['timesPlayed'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$MiniGameToJson(MiniGame instance) => <String, dynamic>{
      'id': instance.id,
      'type': _$GameTypeEnumMap[instance.type]!,
      'nameIt': instance.nameIt,
      'nameEn': instance.nameEn,
      'descriptionIt': instance.descriptionIt,
      'descriptionEn': instance.descriptionEn,
      'rulesIt': instance.rulesIt,
      'rulesEn': instance.rulesEn,
      'minPlayers': instance.minPlayers,
      'maxPlayers': instance.maxPlayers,
      'durationMinutes': instance.durationMinutes,
      'availableIntensities': instance.availableIntensities
          .map((e) => _$GameIntensityEnumMap[e]!)
          .toList(),
      'iconRef': instance.iconRef,
      'isUnlocked': instance.isUnlocked,
      'timesPlayed': instance.timesPlayed,
    };

const _$GameTypeEnumMap = {
  GameType.gooseGame: 'gooseGame',
  GameType.wheel: 'wheel',
  GameType.truthDare: 'truthDare',
  GameType.hotCold: 'hotCold',
  GameType.loveNotes: 'loveNotes',
  GameType.fantasyBuilder: 'fantasyBuilder',
  GameType.complimentBattle: 'complimentBattle',
  GameType.questionQuest: 'questionQuest',
  GameType.twoMinutes: 'twoMinutes',
  GameType.intimacyMap: 'intimacyMap',
  GameType.soundtrack: 'soundtrack',
  GameType.mirrorChallenge: 'mirrorChallenge',
};

const _$GameIntensityEnumMap = {
  GameIntensity.soft: 'soft',
  GameIntensity.spicy: 'spicy',
  GameIntensity.extraSpicy: 'extraSpicy',
};

Session _$SessionFromJson(Map<String, dynamic> json) => Session(
      id: json['id'] as String,
      type: $enumDecode(_$SessionTypeEnumMap, json['type']),
      startedAt: DateTime.parse(json['startedAt'] as String),
      endedAt: json['endedAt'] == null
          ? null
          : DateTime.parse(json['endedAt'] as String),
      filters: json['filters'] as Map<String, dynamic>?,
      positionIds: (json['positionIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      currentIndex: (json['currentIndex'] as num?)?.toInt() ?? 0,
      completed: json['completed'] as bool? ?? false,
      gameId: json['gameId'] as String?,
      gameState: json['gameState'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$SessionToJson(Session instance) => <String, dynamic>{
      'id': instance.id,
      'type': _$SessionTypeEnumMap[instance.type]!,
      'startedAt': instance.startedAt.toIso8601String(),
      'endedAt': instance.endedAt?.toIso8601String(),
      'filters': instance.filters,
      'positionIds': instance.positionIds,
      'currentIndex': instance.currentIndex,
      'completed': instance.completed,
      'gameId': instance.gameId,
      'gameState': instance.gameState,
    };

const _$SessionTypeEnumMap = {
  SessionType.shuffle: 'shuffle',
  SessionType.game: 'game',
};

HistoryEntry _$HistoryEntryFromJson(Map<String, dynamic> json) => HistoryEntry(
      id: json['id'] as String,
      positionId: json['positionId'] as String,
      viewedAt: DateTime.parse(json['viewedAt'] as String),
      reaction: json['reaction'] as String?,
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$HistoryEntryToJson(HistoryEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'positionId': instance.positionId,
      'viewedAt': instance.viewedAt.toIso8601String(),
      'reaction': instance.reaction,
      'notes': instance.notes,
    };

Badge _$BadgeFromJson(Map<String, dynamic> json) => Badge(
      id: json['id'] as String,
      nameIt: json['nameIt'] as String,
      nameEn: json['nameEn'] as String,
      descriptionIt: json['descriptionIt'] as String,
      descriptionEn: json['descriptionEn'] as String,
      iconRef: json['iconRef'] as String,
      unlockedAt: json['unlockedAt'] == null
          ? null
          : DateTime.parse(json['unlockedAt'] as String),
      criteria: json['criteria'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$BadgeToJson(Badge instance) => <String, dynamic>{
      'id': instance.id,
      'nameIt': instance.nameIt,
      'nameEn': instance.nameEn,
      'descriptionIt': instance.descriptionIt,
      'descriptionEn': instance.descriptionEn,
      'iconRef': instance.iconRef,
      'unlockedAt': instance.unlockedAt?.toIso8601String(),
      'criteria': instance.criteria,
    };

Streak _$StreakFromJson(Map<String, dynamic> json) => Streak(
      currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 0,
      longestStreak: (json['longestStreak'] as num?)?.toInt() ?? 0,
      lastActivityDate: json['lastActivityDate'] == null
          ? null
          : DateTime.parse(json['lastActivityDate'] as String),
      graceDaysUsed: (json['graceDaysUsed'] as num?)?.toInt() ?? 0,
      graceDaysAllowed: (json['graceDaysAllowed'] as num?)?.toInt() ?? 2,
    );

Map<String, dynamic> _$StreakToJson(Streak instance) => <String, dynamic>{
      'currentStreak': instance.currentStreak,
      'longestStreak': instance.longestStreak,
      'lastActivityDate': instance.lastActivityDate?.toIso8601String(),
      'graceDaysUsed': instance.graceDaysUsed,
      'graceDaysAllowed': instance.graceDaysAllowed,
    };
