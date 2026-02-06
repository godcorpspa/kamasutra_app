import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/position.dart';
import '../models/user_data.dart';
import '../services/firebase_user_service.dart';

/// Repository for managing positions data with Firebase integration
class PositionRepository {
  static PositionRepository? _instance;
  static PositionRepository get instance => _instance ??= PositionRepository._();
  
  PositionRepository._();

  final FirebaseUserService _firebaseService = FirebaseUserService();
  
  List<Position>? _positions;
  UserPositions _userPositions = const UserPositions();

  /// Load all positions from JSON assets
  Future<List<Position>> loadPositions(String locale) async {
    final jsonString = await rootBundle.loadString(
      'assets/positions/positions_$locale.json',
    );
    final List<dynamic> jsonList = json.decode(jsonString);
    
    _positions = jsonList
        .map((json) => Position.fromJson(json as Map<String, dynamic>))
        .toList();
    
    // Load user data from Firebase
    await _loadUserData();
    
    return _positions!;
  }

  Future<void> _loadUserData() async {
    if (_positions == null) return;
    _userPositions = await _firebaseService.getPositions();
  }

  /// Refresh user data from Firebase
  Future<void> refreshUserData() async {
    _userPositions = await _firebaseService.getPositions();
  }

  /// Get all positions with user data applied
  List<Position> get positions {
    if (_positions == null) return [];
    
    return _positions!.map((p) {
      final isFavorite = _userPositions.favorites.contains(p.id);
      final explored = _userPositions.explored[p.id];
      
      return p.copyWith(
        isFavorite: isFavorite,
        timesViewed: explored?.views ?? 0,
        lastViewed: explored?.lastViewed,
      );
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

  /// Toggle favorite status - NOW SAVES TO FIREBASE
  Future<bool> toggleFavorite(String positionId) async {
    final newStatus = await _firebaseService.toggleFavorite(positionId);
    
    // Update local cache
    if (newStatus) {
      _userPositions = UserPositions(
        favorites: [..._userPositions.favorites, positionId],
        explored: _userPositions.explored,
      );
    } else {
      _userPositions = UserPositions(
        favorites: _userPositions.favorites.where((id) => id != positionId).toList(),
        explored: _userPositions.explored,
      );
    }
    
    return newStatus;
  }

  /// Record that a position was viewed - NOW SAVES TO FIREBASE
  Future<void> recordView(String positionId, {String? reaction}) async {
    await _firebaseService.recordPositionView(positionId, reaction: reaction);
    
    // Update local cache
    final existing = _userPositions.explored[positionId];
    final newExplored = Map<String, PositionUserData>.from(_userPositions.explored);
    newExplored[positionId] = PositionUserData(
      views: (existing?.views ?? 0) + 1,
      lastViewed: DateTime.now(),
      reaction: reaction ?? existing?.reaction,
    );
    
    _userPositions = UserPositions(
      favorites: _userPositions.favorites,
      explored: newExplored,
    );
  }

  /// Add to history with full details
  Future<void> addToHistory({
    required String positionId,
    required String positionName,
    String? category,
    required String reaction,
  }) async {
    await _firebaseService.addHistoryEntry(HistoryEntry(
      positionId: positionId,
      positionName: positionName,
      category: category,
      reaction: reaction,
      date: DateTime.now(),
    ));
    
    // Also record the view
    await recordView(positionId, reaction: reaction);
  }

  /// Get positions similar to a given position
  List<Position> getSimilar(String positionId, {int limit = 5}) {
    final position = getById(positionId);
    if (position == null) return [];
    
    final scored = positions
        .where((p) => p.id != positionId)
        .map((p) {
          int score = 0;
          
          for (final cat in position.categories) {
            if (p.categories.contains(cat)) score += 3;
          }
          
          for (final focus in position.focus) {
            if (p.focus.contains(focus)) score += 2;
          }
          
          if ((p.difficulty - position.difficulty).abs() <= 1) score += 2;
          if (p.energy == position.energy) score += 1;
          if (p.duration == position.duration) score += 1;
          
          return _ScoredPosition(p, score);
        })
        .toList();
    
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
      favorites: _userPositions.favorites.length,
      explored: _userPositions.explored.length,
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
    _userPositions = const UserPositions();
  }
}

class _ScoredPosition {
  final Position position;
  final int score;
  
  _ScoredPosition(this.position, this.score);
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

// ============ RIVERPOD PROVIDERS ============

/// Provider for PositionRepository
final positionRepositoryProvider = Provider<PositionRepository>((ref) {
  return PositionRepository.instance;
});

/// Provider for all positions with user data
final positionsProvider = FutureProvider.family<List<Position>, String>((ref, locale) async {
  final repo = ref.watch(positionRepositoryProvider);
  return repo.loadPositions(locale);
});

/// Provider for favorites only
final favoritesPositionsProvider = Provider<List<Position>>((ref) {
  final repo = ref.watch(positionRepositoryProvider);
  return repo.favorites;
});

/// Provider for position stats
final positionStatsProvider = Provider<PositionStats>((ref) {
  final repo = ref.watch(positionRepositoryProvider);
  return repo.getStats();
});
