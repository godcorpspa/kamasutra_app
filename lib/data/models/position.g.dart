// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'position.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Position _$PositionFromJson(Map<String, dynamic> json) => Position(
      id: json['id'] as String,
      nameIt: json['nameIt'] as String,
      nameEn: json['nameEn'] as String,
      nameEs: json['nameEs'] as String?,
      aliasIt: json['aliasIt'] as String?,
      aliasEn: json['aliasEn'] as String?,
      aliasEs: json['aliasEs'] as String?,
      categories: (json['categories'] as List<dynamic>)
          .map((e) => $enumDecode(_$PositionCategoryEnumMap, e))
          .toList(),
      difficulty: (json['difficulty'] as num).toInt(),
      energy: $enumDecode(_$EnergyLevelEnumMap, json['energy']),
      focus: (json['focus'] as List<dynamic>)
          .map((e) => $enumDecode(_$PositionFocusEnumMap, e))
          .toList(),
      duration: $enumDecode(_$PositionDurationEnumMap, json['duration']),
      prerequisites: (json['prerequisites'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      cautionsIt: json['cautionsIt'] as String?,
      cautionsEn: json['cautionsEn'] as String?,
      cautionsEs: json['cautionsEs'] as String?,
      easyVariantIt: json['easyVariantIt'] as String?,
      easyVariantEn: json['easyVariantEn'] as String?,
      easyVariantEs: json['easyVariantEs'] as String?,
      setupIt: json['setupIt'] as String?,
      setupEn: json['setupEn'] as String?,
      setupEs: json['setupEs'] as String?,
      checkinIt: json['checkinIt'] as String?,
      checkinEn: json['checkinEn'] as String?,
      checkinEs: json['checkinEs'] as String?,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      illustrationRef: json['illustrationRef'] as String,
      isFavorite: json['isFavorite'] as bool? ?? false,
      timesViewed: (json['timesViewed'] as num?)?.toInt() ?? 0,
      lastViewed: json['lastViewed'] == null
          ? null
          : DateTime.parse(json['lastViewed'] as String),
    );

Map<String, dynamic> _$PositionToJson(Position instance) => <String, dynamic>{
      'id': instance.id,
      'nameIt': instance.nameIt,
      'nameEn': instance.nameEn,
      'nameEs': instance.nameEs,
      'aliasIt': instance.aliasIt,
      'aliasEn': instance.aliasEn,
      'aliasEs': instance.aliasEs,
      'categories': instance.categories
          .map((e) => _$PositionCategoryEnumMap[e]!)
          .toList(),
      'difficulty': instance.difficulty,
      'energy': _$EnergyLevelEnumMap[instance.energy]!,
      'focus': instance.focus.map((e) => _$PositionFocusEnumMap[e]!).toList(),
      'duration': _$PositionDurationEnumMap[instance.duration]!,
      'prerequisites': instance.prerequisites,
      'cautionsIt': instance.cautionsIt,
      'cautionsEn': instance.cautionsEn,
      'cautionsEs': instance.cautionsEs,
      'easyVariantIt': instance.easyVariantIt,
      'easyVariantEn': instance.easyVariantEn,
      'easyVariantEs': instance.easyVariantEs,
      'setupIt': instance.setupIt,
      'setupEn': instance.setupEn,
      'setupEs': instance.setupEs,
      'checkinIt': instance.checkinIt,
      'checkinEn': instance.checkinEn,
      'checkinEs': instance.checkinEs,
      'tags': instance.tags,
      'illustrationRef': instance.illustrationRef,
      'isFavorite': instance.isFavorite,
      'timesViewed': instance.timesViewed,
      'lastViewed': instance.lastViewed?.toIso8601String(),
    };

const _$PositionCategoryEnumMap = {
  PositionCategory.romantic: 'romantic',
  PositionCategory.beginner: 'beginner',
  PositionCategory.athletic: 'athletic',
  PositionCategory.supported: 'supported',
  PositionCategory.lowImpact: 'lowImpact',
  PositionCategory.adventurous: 'adventurous',
  PositionCategory.reconnect: 'reconnect',
  PositionCategory.quickie: 'quickie',
};

const _$EnergyLevelEnumMap = {
  EnergyLevel.low: 'low',
  EnergyLevel.medium: 'medium',
  EnergyLevel.high: 'high',
};

const _$PositionFocusEnumMap = {
  PositionFocus.intimacy: 'intimacy',
  PositionFocus.variety: 'variety',
  PositionFocus.connection: 'connection',
  PositionFocus.relax: 'relax',
  PositionFocus.playfulness: 'playfulness',
  PositionFocus.passion: 'passion',
  PositionFocus.trust: 'trust',
};

const _$PositionDurationEnumMap = {
  PositionDuration.brief: 'brief',
  PositionDuration.medium: 'medium',
  PositionDuration.long: 'long',
};
