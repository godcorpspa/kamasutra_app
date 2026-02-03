import 'dart:convert';
import 'package:flutter/services.dart';

import '../models/position.dart';
import '../local/database_service.dart';

/// Repository for managing positions data
class PositionRepository {
  static PositionRepository? _instance;
  static PositionRepository get instance => _instance ??= PositionRepository._();
  
  PositionRepository._();

  List<Position>? _positions;
  final Map<String, PositionUserData> _userData = {};

  /// Load all positions from JSON assets
  Future<List<Position>> loadPositions(String locale) async {
    final jsonString = await rootBundle.loadString(
      'assets/positions/positions_$locale.json',
    );
    final List<dynamic> jsonList = json.decode(jsonString);
    
    _positions = jsonList
        .map((json) => Position.fromJson(json as Map<String, dynamic>))
        .toList();
    
    // Load user data (favorites, view counts)
    await _loadUserData();
    
    return _positions!;
  }

  Future<void> _loadUserData() async {
    if (_positions == null) return;
    
    for (final position in _positions!) {
      final data = await DatabaseService.instance.getPositionUserData(position.id);
      if (data != null) {
        _userData[position.id] = PositionUserData(
          positionId: data['positionId'] as String? ?? position.id,
          isFavorite: data['isFavorite'] as bool? ?? false,
          timesViewed: data['timesViewed'] as int? ?? 0,
          lastViewed: data['lastViewed'] != null 
              ? DateTime.tryParse(data['lastViewed'] as String)
              : null,
        );
      }
    }
  }

  /// Get all positions with user data applied
  List<Position> get positions {
    if (_positions == null) return [];
    
    return _positions!.map((p) {
      final userData = _userData[p.id];
      if (userData != null) {
        return p.copyWith(
          isFavorite: userData.isFavorite,
          timesViewed: userData.timesViewed,
          lastViewed: userData.lastViewed,
        );
      }
      return p;
    }).toList();
  }

  /// Get filtered positions
  List<Position> getFiltered(PositionFilter filter) {
    return filter.apply(positions);
  }

  /// Get favorite positions
  List<Position> get favorites {
    return positions.where((p) => p.isFavorite).toList();
  }

  /// Get a single position by ID
  Position? getById(String id) {
    try {
      return positions.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Toggle favorite status
  Future<bool> toggleFavorite(String positionId) async {
    final position = getById(positionId);
    if (position == null) return false;
    
    final newStatus = !position.isFavorite;
    
    await DatabaseService.instance.updatePositionUserData(
      positionId,
      isFavorite: newStatus,
    );
    
    _userData[positionId] = PositionUserData(
      positionId: positionId,
      isFavorite: newStatus,
      timesViewed: _userData[positionId]?.timesViewed ?? 0,
      lastViewed: _userData[positionId]?.lastViewed,
    );
    
    return newStatus;
  }

  /// Record that a position was viewed
  Future<void> recordView(String positionId) async {
    final existing = _userData[positionId];
    final newCount = (existing?.timesViewed ?? 0) + 1;
    final now = DateTime.now();
    
    await DatabaseService.instance.updatePositionUserData(
      positionId,
      timesViewed: newCount,
      lastViewed: now,
    );
    
    _userData[positionId] = PositionUserData(
      positionId: positionId,
      isFavorite: existing?.isFavorite ?? false,
      timesViewed: newCount,
      lastViewed: now,
    );
  }

  /// Get positions similar to a given position
  List<Position> getSimilar(String positionId, {int limit = 5}) {
    final position = getById(positionId);
    if (position == null) return [];
    
    // Score other positions by similarity
    final scored = positions
        .where((p) => p.id != positionId)
        .map((p) {
          int score = 0;
          
          // Same categories
          for (final cat in position.categories) {
            if (p.categories.contains(cat)) score += 3;
          }
          
          // Same focus areas
          for (final focus in position.focus) {
            if (p.focus.contains(focus)) score += 2;
          }
          
          // Similar difficulty (within 1)
          if ((p.difficulty - position.difficulty).abs() <= 1) score += 2;
          
          // Same energy level
          if (p.energy == position.energy) score += 1;
          
          // Same duration
          if (p.duration == position.duration) score += 1;
          
          return _ScoredPosition(p, score);
        })
        .toList();
    
    // Sort by score descending
    scored.sort((a, b) => b.score.compareTo(a.score));
    
    return scored.take(limit).map((s) => s.position).toList();
  }

  /// Get random positions matching a filter
  List<Position> getRandom(PositionFilter filter, int count) {
    final filtered = getFiltered(filter);
    if (filtered.isEmpty) return [];
    
    final shuffled = List<Position>.from(filtered)..shuffle();
    return shuffled.take(count).toList();
  }

  /// Get positions grouped by category
  Map<PositionCategory, List<Position>> getByCategory() {
    final result = <PositionCategory, List<Position>>{};
    
    for (final category in PositionCategory.values) {
      result[category] = positions
          .where((p) => p.categories.contains(category))
          .toList();
    }
    
    return result;
  }

  /// Get position count statistics
  PositionStats getStats() {
    final all = positions;
    return PositionStats(
      total: all.length,
      favorites: all.where((p) => p.isFavorite).length,
      explored: all.where((p) => p.timesViewed > 0).length,
      byCategory: {
        for (final cat in PositionCategory.values)
          cat: all.where((p) => p.categories.contains(cat)).length,
      },
      byDifficulty: {
        for (var i = 1; i <= 5; i++)
          i: all.where((p) => p.difficulty == i).length,
      },
    );
  }

  /// Clear cached data
  void clear() {
    _positions = null;
    _userData.clear();
  }
}

class _ScoredPosition {
  final Position position;
  final int score;
  
  _ScoredPosition(this.position, this.score);
}

/// User-specific data for a position
class PositionUserData {
  final String positionId;
  final bool isFavorite;
  final int timesViewed;
  final DateTime? lastViewed;

  PositionUserData({
    required this.positionId,
    required this.isFavorite,
    required this.timesViewed,
    this.lastViewed,
  });
}

/// Statistics about positions
class PositionStats {
  final int total;
  final int favorites;
  final int explored;
  final Map<PositionCategory, int> byCategory;
  final Map<int, int> byDifficulty;

  PositionStats({
    required this.total,
    required this.favorites,
    required this.explored,
    required this.byCategory,
    required this.byDifficulty,
  });

  double get exploredPercentage => total > 0 ? explored / total * 100 : 0;
}
