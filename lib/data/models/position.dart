import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'position.g.dart';

/// Position categories
enum PositionCategory {
  romantic,
  beginner,
  athletic,
  supported,
  lowImpact,
  adventurous,
  reconnect,
  quickie,
}

/// Energy levels
enum EnergyLevel {
  low,
  medium,
  high,
}

/// Focus areas
enum PositionFocus {
  intimacy,
  variety,
  connection,
  relax,
  playfulness,
  passion,
  trust,
}

/// Duration types
enum PositionDuration {
  brief,
  medium,
  long,
}

/// Position model
@JsonSerializable()
class Position extends Equatable {
  final String id;
  final String nameIt;
  final String nameEn;
  final String? aliasIt;
  final String? aliasEn;
  final List<PositionCategory> categories;
  final int difficulty; // 1-5
  final EnergyLevel energy;
  final List<PositionFocus> focus;
  final PositionDuration duration;
  final List<String> prerequisites;
  final String? cautionsIt;
  final String? cautionsEn;
  final String? easyVariantIt;
  final String? easyVariantEn;
  final String? setupIt;
  final String? setupEn;
  final String? checkinIt;
  final String? checkinEn;
  final List<String> tags;
  final String illustrationRef;
  final bool isFavorite;
  final int timesViewed;
  final DateTime? lastViewed;

  const Position({
    required this.id,
    required this.nameIt,
    required this.nameEn,
    this.aliasIt,
    this.aliasEn,
    required this.categories,
    required this.difficulty,
    required this.energy,
    required this.focus,
    required this.duration,
    this.prerequisites = const [],
    this.cautionsIt,
    this.cautionsEn,
    this.easyVariantIt,
    this.easyVariantEn,
    this.setupIt,
    this.setupEn,
    this.checkinIt,
    this.checkinEn,
    this.tags = const [],
    required this.illustrationRef,
    this.isFavorite = false,
    this.timesViewed = 0,
    this.lastViewed,
  });

  /// Get localized name
  String getName(String locale) => locale == 'it' ? nameIt : nameEn;
  
  /// Get localized alias
  String? getAlias(String locale) => locale == 'it' ? aliasIt : aliasEn;
  
  /// Get localized cautions
  String? getCautions(String locale) => locale == 'it' ? cautionsIt : cautionsEn;
  
  /// Get localized easy variant
  String? getEasyVariant(String locale) => locale == 'it' ? easyVariantIt : easyVariantEn;
  
  /// Get localized setup instructions
  String? getSetup(String locale) => locale == 'it' ? setupIt : setupEn;
  
  /// Get localized check-in prompt
  String? getCheckin(String locale) => locale == 'it' ? checkinIt : checkinEn;

  // Convenience getters (default to English)
  String get name => nameIt;
  String? get alias => aliasIt;
  String? get cautions => cautionsIt;
  String? get easyVariant => easyVariantIt;
  String? get setup => setupIt;
  String? get checkin => checkinIt;
  String get localizedName => nameEn;
  String? get localizedAlias => aliasEn;

  /// Check if position has cautions
  bool get hasCautions => cautionsIt != null || cautionsEn != null;
  
  /// Check if position has easy variant
  bool get hasEasyVariant => easyVariantIt != null || easyVariantEn != null;

  /// Copy with
  Position copyWith({
    String? id,
    String? nameIt,
    String? nameEn,
    String? aliasIt,
    String? aliasEn,
    List<PositionCategory>? categories,
    int? difficulty,
    EnergyLevel? energy,
    List<PositionFocus>? focus,
    PositionDuration? duration,
    List<String>? prerequisites,
    String? cautionsIt,
    String? cautionsEn,
    String? easyVariantIt,
    String? easyVariantEn,
    String? setupIt,
    String? setupEn,
    String? checkinIt,
    String? checkinEn,
    List<String>? tags,
    String? illustrationRef,
    bool? isFavorite,
    int? timesViewed,
    DateTime? lastViewed,
  }) {
    return Position(
      id: id ?? this.id,
      nameIt: nameIt ?? this.nameIt,
      nameEn: nameEn ?? this.nameEn,
      aliasIt: aliasIt ?? this.aliasIt,
      aliasEn: aliasEn ?? this.aliasEn,
      categories: categories ?? this.categories,
      difficulty: difficulty ?? this.difficulty,
      energy: energy ?? this.energy,
      focus: focus ?? this.focus,
      duration: duration ?? this.duration,
      prerequisites: prerequisites ?? this.prerequisites,
      cautionsIt: cautionsIt ?? this.cautionsIt,
      cautionsEn: cautionsEn ?? this.cautionsEn,
      easyVariantIt: easyVariantIt ?? this.easyVariantIt,
      easyVariantEn: easyVariantEn ?? this.easyVariantEn,
      setupIt: setupIt ?? this.setupIt,
      setupEn: setupEn ?? this.setupEn,
      checkinIt: checkinIt ?? this.checkinIt,
      checkinEn: checkinEn ?? this.checkinEn,
      tags: tags ?? this.tags,
      illustrationRef: illustrationRef ?? this.illustrationRef,
      isFavorite: isFavorite ?? this.isFavorite,
      timesViewed: timesViewed ?? this.timesViewed,
      lastViewed: lastViewed ?? this.lastViewed,
    );
  }

  factory Position.fromJson(Map<String, dynamic> json) => _$PositionFromJson(json);
  Map<String, dynamic> toJson() => _$PositionToJson(this);

  @override
  List<Object?> get props => [
    id,
    nameIt,
    nameEn,
    aliasIt,
    aliasEn,
    categories,
    difficulty,
    energy,
    focus,
    duration,
    prerequisites,
    cautionsIt,
    cautionsEn,
    easyVariantIt,
    easyVariantEn,
    setupIt,
    setupEn,
    checkinIt,
    checkinEn,
    tags,
    illustrationRef,
    isFavorite,
    timesViewed,
    lastViewed,
  ];
}

/// Position filter
class PositionFilter extends Equatable {
  final List<PositionCategory>? categories;
  final int? minDifficulty;
  final int? maxDifficulty;
  final List<EnergyLevel>? energyLevels;
  final List<PositionFocus>? focus;
  final List<PositionDuration>? durations;
  final bool? favoritesOnly;
  final bool? excludeCautions;
  final String? searchQuery;

  const PositionFilter({
    this.categories,
    this.minDifficulty,
    this.maxDifficulty,
    this.energyLevels,
    this.focus,
    this.durations,
    this.favoritesOnly,
    this.excludeCautions,
    this.searchQuery,
  });

  /// Check if filter is empty (no filters applied)
  bool get isEmpty =>
      categories == null &&
      minDifficulty == null &&
      maxDifficulty == null &&
      energyLevels == null &&
      focus == null &&
      durations == null &&
      favoritesOnly == null &&
      excludeCautions == null &&
      (searchQuery == null || searchQuery!.isEmpty);

  /// Apply filter to a list of positions
  List<Position> apply(List<Position> positions) {
    return positions.where((p) {
      // Category filter
      if (categories != null && categories!.isNotEmpty) {
        if (!p.categories.any((c) => categories!.contains(c))) {
          return false;
        }
      }
      
      // Difficulty filter
      if (minDifficulty != null && p.difficulty < minDifficulty!) {
        return false;
      }
      if (maxDifficulty != null && p.difficulty > maxDifficulty!) {
        return false;
      }
      
      // Energy filter
      if (energyLevels != null && energyLevels!.isNotEmpty) {
        if (!energyLevels!.contains(p.energy)) {
          return false;
        }
      }
      
      // Focus filter
      if (focus != null && focus!.isNotEmpty) {
        if (!p.focus.any((f) => focus!.contains(f))) {
          return false;
        }
      }
      
      // Duration filter
      if (durations != null && durations!.isNotEmpty) {
        if (!durations!.contains(p.duration)) {
          return false;
        }
      }
      
      // Favorites filter
      if (favoritesOnly == true && !p.isFavorite) {
        return false;
      }
      
      // Cautions filter
      if (excludeCautions == true && p.hasCautions) {
        return false;
      }
      
      // Search query
      if (searchQuery != null && searchQuery!.isNotEmpty) {
        final query = searchQuery!.toLowerCase();
        final nameMatch = p.nameIt.toLowerCase().contains(query) ||
            p.nameEn.toLowerCase().contains(query);
        final aliasMatch = (p.aliasIt?.toLowerCase().contains(query) ?? false) ||
            (p.aliasEn?.toLowerCase().contains(query) ?? false);
        final tagMatch = p.tags.any((t) => t.toLowerCase().contains(query));
        if (!nameMatch && !aliasMatch && !tagMatch) {
          return false;
        }
      }
      
      return true;
    }).toList();
  }

  /// Copy with
  PositionFilter copyWith({
    List<PositionCategory>? categories,
    int? minDifficulty,
    int? maxDifficulty,
    List<EnergyLevel>? energyLevels,
    List<PositionFocus>? focus,
    List<PositionDuration>? durations,
    bool? favoritesOnly,
    bool? excludeCautions,
    String? searchQuery,
  }) {
    return PositionFilter(
      categories: categories ?? this.categories,
      minDifficulty: minDifficulty ?? this.minDifficulty,
      maxDifficulty: maxDifficulty ?? this.maxDifficulty,
      energyLevels: energyLevels ?? this.energyLevels,
      focus: focus ?? this.focus,
      durations: durations ?? this.durations,
      favoritesOnly: favoritesOnly ?? this.favoritesOnly,
      excludeCautions: excludeCautions ?? this.excludeCautions,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() => {
    if (categories != null) 'categories': categories!.map((c) => c.name).toList(),
    if (minDifficulty != null) 'minDifficulty': minDifficulty,
    if (maxDifficulty != null) 'maxDifficulty': maxDifficulty,
    if (energyLevels != null) 'energyLevels': energyLevels!.map((e) => e.name).toList(),
    if (focus != null) 'focus': focus!.map((f) => f.name).toList(),
    if (durations != null) 'durations': durations!.map((d) => d.name).toList(),
    if (favoritesOnly != null) 'favoritesOnly': favoritesOnly,
    if (excludeCautions != null) 'excludeCautions': excludeCautions,
    if (searchQuery != null) 'searchQuery': searchQuery,
  };

  @override
  List<Object?> get props => [
    categories,
    minDifficulty,
    maxDifficulty,
    energyLevels,
    focus,
    durations,
    favoritesOnly,
    excludeCautions,
    searchQuery,
  ];
}
