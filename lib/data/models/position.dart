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
  final String? nameEs;
  final String? nameFr;
  final String? namePt;
  final String? aliasIt;
  final String? aliasEn;
  final String? aliasEs;
  final String? aliasFr;
  final String? aliasPt;
  final List<PositionCategory> categories;
  final int difficulty; // 1-5
  final EnergyLevel energy;
  final List<PositionFocus> focus;
  final PositionDuration duration;
  final List<String> prerequisites;
  final String? cautionsIt;
  final String? cautionsEn;
  final String? cautionsEs;
  final String? cautionsFr;
  final String? cautionsPt;
  final String? easyVariantIt;
  final String? easyVariantEn;
  final String? easyVariantEs;
  final String? easyVariantFr;
  final String? easyVariantPt;
  final String? setupIt;
  final String? setupEn;
  final String? setupEs;
  final String? setupFr;
  final String? setupPt;
  final String? checkinIt;
  final String? checkinEn;
  final String? checkinEs;
  final String? checkinFr;
  final String? checkinPt;
  final List<String> tags;
  final String illustrationRef;
  final bool isFavorite;
  final int timesViewed;
  final DateTime? lastViewed;

  const Position({
    required this.id,
    required this.nameIt,
    required this.nameEn,
    this.nameEs,
    this.nameFr,
    this.namePt,
    this.aliasIt,
    this.aliasEn,
    this.aliasEs,
    this.aliasFr,
    this.aliasPt,
    required this.categories,
    required this.difficulty,
    required this.energy,
    required this.focus,
    required this.duration,
    this.prerequisites = const [],
    this.cautionsIt,
    this.cautionsEn,
    this.cautionsEs,
    this.cautionsFr,
    this.cautionsPt,
    this.easyVariantIt,
    this.easyVariantEn,
    this.easyVariantEs,
    this.easyVariantFr,
    this.easyVariantPt,
    this.setupIt,
    this.setupEn,
    this.setupEs,
    this.setupFr,
    this.setupPt,
    this.checkinIt,
    this.checkinEn,
    this.checkinEs,
    this.checkinFr,
    this.checkinPt,
    this.tags = const [],
    required this.illustrationRef,
    this.isFavorite = false,
    this.timesViewed = 0,
    this.lastViewed,
  });

  /// Get localized name
  String getName(String locale) {
    switch (locale) {
      case 'it': return nameIt;
      case 'es': return nameEs ?? nameEn;
      case 'fr': return nameFr ?? nameEn;
      case 'pt': return namePt ?? nameEn;
      default: return nameEn;
    }
  }

  /// Get localized alias
  String? getAlias(String locale) {
    switch (locale) {
      case 'it': return aliasIt;
      case 'es': return aliasEs ?? aliasEn;
      case 'fr': return aliasFr ?? aliasEn;
      case 'pt': return aliasPt ?? aliasEn;
      default: return aliasEn;
    }
  }

  /// Get localized cautions
  String? getCautions(String locale) {
    switch (locale) {
      case 'it': return cautionsIt;
      case 'es': return cautionsEs ?? cautionsEn;
      case 'fr': return cautionsFr ?? cautionsEn;
      case 'pt': return cautionsPt ?? cautionsEn;
      default: return cautionsEn;
    }
  }

  /// Get localized easy variant
  String? getEasyVariant(String locale) {
    switch (locale) {
      case 'it': return easyVariantIt;
      case 'es': return easyVariantEs ?? easyVariantEn;
      case 'fr': return easyVariantFr ?? easyVariantEn;
      case 'pt': return easyVariantPt ?? easyVariantEn;
      default: return easyVariantEn;
    }
  }

  /// Get localized setup instructions
  String? getSetup(String locale) {
    switch (locale) {
      case 'it': return setupIt;
      case 'es': return setupEs ?? setupEn;
      case 'fr': return setupFr ?? setupEn;
      case 'pt': return setupPt ?? setupEn;
      default: return setupEn;
    }
  }

  /// Get localized check-in prompt
  String? getCheckin(String locale) {
    switch (locale) {
      case 'it': return checkinIt;
      case 'es': return checkinEs ?? checkinEn;
      case 'fr': return checkinFr ?? checkinEn;
      case 'pt': return checkinPt ?? checkinEn;
      default: return checkinEn;
    }
  }

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
    String? nameEs,
    String? nameFr,
    String? namePt,
    String? aliasIt,
    String? aliasEn,
    String? aliasEs,
    String? aliasFr,
    String? aliasPt,
    List<PositionCategory>? categories,
    int? difficulty,
    EnergyLevel? energy,
    List<PositionFocus>? focus,
    PositionDuration? duration,
    List<String>? prerequisites,
    String? cautionsIt,
    String? cautionsEn,
    String? cautionsEs,
    String? cautionsFr,
    String? cautionsPt,
    String? easyVariantIt,
    String? easyVariantEn,
    String? easyVariantEs,
    String? easyVariantFr,
    String? easyVariantPt,
    String? setupIt,
    String? setupEn,
    String? setupEs,
    String? setupFr,
    String? setupPt,
    String? checkinIt,
    String? checkinEn,
    String? checkinEs,
    String? checkinFr,
    String? checkinPt,
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
      nameEs: nameEs ?? this.nameEs,
      nameFr: nameFr ?? this.nameFr,
      namePt: namePt ?? this.namePt,
      aliasIt: aliasIt ?? this.aliasIt,
      aliasEn: aliasEn ?? this.aliasEn,
      aliasEs: aliasEs ?? this.aliasEs,
      aliasFr: aliasFr ?? this.aliasFr,
      aliasPt: aliasPt ?? this.aliasPt,
      categories: categories ?? this.categories,
      difficulty: difficulty ?? this.difficulty,
      energy: energy ?? this.energy,
      focus: focus ?? this.focus,
      duration: duration ?? this.duration,
      prerequisites: prerequisites ?? this.prerequisites,
      cautionsIt: cautionsIt ?? this.cautionsIt,
      cautionsEn: cautionsEn ?? this.cautionsEn,
      cautionsEs: cautionsEs ?? this.cautionsEs,
      cautionsFr: cautionsFr ?? this.cautionsFr,
      cautionsPt: cautionsPt ?? this.cautionsPt,
      easyVariantIt: easyVariantIt ?? this.easyVariantIt,
      easyVariantEn: easyVariantEn ?? this.easyVariantEn,
      easyVariantEs: easyVariantEs ?? this.easyVariantEs,
      easyVariantFr: easyVariantFr ?? this.easyVariantFr,
      easyVariantPt: easyVariantPt ?? this.easyVariantPt,
      setupIt: setupIt ?? this.setupIt,
      setupEn: setupEn ?? this.setupEn,
      setupEs: setupEs ?? this.setupEs,
      setupFr: setupFr ?? this.setupFr,
      setupPt: setupPt ?? this.setupPt,
      checkinIt: checkinIt ?? this.checkinIt,
      checkinEn: checkinEn ?? this.checkinEn,
      checkinEs: checkinEs ?? this.checkinEs,
      checkinFr: checkinFr ?? this.checkinFr,
      checkinPt: checkinPt ?? this.checkinPt,
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
    nameEs,
    nameFr,
    namePt,
    aliasIt,
    aliasEn,
    aliasEs,
    aliasFr,
    aliasPt,
    categories,
    difficulty,
    energy,
    focus,
    duration,
    prerequisites,
    cautionsIt,
    cautionsEn,
    cautionsEs,
    cautionsFr,
    cautionsPt,
    easyVariantIt,
    easyVariantEn,
    easyVariantEs,
    easyVariantFr,
    easyVariantPt,
    setupIt,
    setupEn,
    setupEs,
    setupFr,
    setupPt,
    checkinIt,
    checkinEn,
    checkinEs,
    checkinFr,
    checkinPt,
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
            p.nameEn.toLowerCase().contains(query) ||
            (p.nameEs?.toLowerCase().contains(query) ?? false) ||
            (p.nameFr?.toLowerCase().contains(query) ?? false) ||
            (p.namePt?.toLowerCase().contains(query) ?? false);
        final aliasMatch = (p.aliasIt?.toLowerCase().contains(query) ?? false) ||
            (p.aliasEn?.toLowerCase().contains(query) ?? false) ||
            (p.aliasEs?.toLowerCase().contains(query) ?? false) ||
            (p.aliasFr?.toLowerCase().contains(query) ?? false) ||
            (p.aliasPt?.toLowerCase().contains(query) ?? false);
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
