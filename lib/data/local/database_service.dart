import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

/// Database service for managing local SQLite storage
class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('kamasutra_app.db');
    return _database!;
  }

  Future<void> initialize() async {
    await database;
  }

  Future<Database> _initDB(String filePath) async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Positions table (user-specific data like favorites, view count)
    await db.execute('''
      CREATE TABLE positions_user_data (
        id TEXT PRIMARY KEY,
        is_favorite INTEGER DEFAULT 0,
        times_viewed INTEGER DEFAULT 0,
        last_viewed TEXT
      )
    ''');

    // Sessions table
    await db.execute('''
      CREATE TABLE sessions (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        started_at TEXT NOT NULL,
        ended_at TEXT,
        filters TEXT,
        position_ids TEXT,
        current_index INTEGER DEFAULT 0,
        completed INTEGER DEFAULT 0,
        game_id TEXT,
        game_state TEXT
      )
    ''');

    // History table
    await db.execute('''
      CREATE TABLE history (
        id TEXT PRIMARY KEY,
        position_id TEXT NOT NULL,
        viewed_at TEXT NOT NULL,
        reaction TEXT,
        notes TEXT
      )
    ''');

    // Badges table
    await db.execute('''
      CREATE TABLE badges (
        id TEXT PRIMARY KEY,
        unlocked_at TEXT
      )
    ''');

    // Streaks table
    await db.execute('''
      CREATE TABLE streaks (
        id INTEGER PRIMARY KEY,
        current_streak INTEGER DEFAULT 0,
        longest_streak INTEGER DEFAULT 0,
        last_activity_date TEXT,
        grace_days_used INTEGER DEFAULT 0
      )
    ''');

    // Game progress table
    await db.execute('''
      CREATE TABLE game_progress (
        game_id TEXT PRIMARY KEY,
        times_played INTEGER DEFAULT 0,
        last_played TEXT,
        high_score INTEGER,
        state TEXT
      )
    ''');

    // Love notes archive table
    await db.execute('''
      CREATE TABLE love_notes (
        id TEXT PRIMARY KEY,
        prompt TEXT NOT NULL,
        note1 TEXT,
        note2 TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // Fantasy scenarios archive
    await db.execute('''
      CREATE TABLE fantasy_scenarios (
        id TEXT PRIMARY KEY,
        title TEXT,
        content TEXT NOT NULL,
        intensity TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // Intimacy maps table
    await db.execute('''
      CREATE TABLE intimacy_maps (
        id TEXT PRIMARY KEY,
        player1_map TEXT NOT NULL,
        player2_map TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // Soundtracks table
    await db.execute('''
      CREATE TABLE soundtracks (
        id TEXT PRIMARY KEY,
        title TEXT,
        songs TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // Initialize streaks with default row
    await db.insert('streaks', {
      'id': 1,
      'current_streak': 0,
      'longest_streak': 0,
      'grace_days_used': 0,
    });

    // Create indexes
    await db.execute(
      'CREATE INDEX idx_history_position ON history(position_id)'
    );
    await db.execute(
      'CREATE INDEX idx_history_viewed_at ON history(viewed_at)'
    );
    await db.execute(
      'CREATE INDEX idx_sessions_type ON sessions(type)'
    );
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // Handle migrations for future versions
  }

  // ==================== Position User Data ====================

  Future<Map<String, dynamic>?> getPositionUserData(String positionId) async {
    final db = await database;
    final result = await db.query(
      'positions_user_data',
      where: 'id = ?',
      whereArgs: [positionId],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<void> updatePositionUserData(
    String positionId, {
    bool? isFavorite,
    int? timesViewed,
    DateTime? lastViewed,
  }) async {
    final db = await database;
    final existing = await getPositionUserData(positionId);
    
    final data = <String, dynamic>{'id': positionId};
    if (isFavorite != null) data['is_favorite'] = isFavorite ? 1 : 0;
    if (timesViewed != null) data['times_viewed'] = timesViewed;
    if (lastViewed != null) data['last_viewed'] = lastViewed.toIso8601String();
    
    if (existing == null) {
      await db.insert('positions_user_data', data);
    } else {
      await db.update(
        'positions_user_data',
        data,
        where: 'id = ?',
        whereArgs: [positionId],
      );
    }
  }

  Future<List<String>> getFavoritePositionIds() async {
    final db = await database;
    final result = await db.query(
      'positions_user_data',
      columns: ['id'],
      where: 'is_favorite = ?',
      whereArgs: [1],
    );
    return result.map((row) => row['id'] as String).toList();
  }

  // ==================== Sessions ====================

  Future<void> saveSession(Map<String, dynamic> session) async {
    final db = await database;
    await db.insert(
      'sessions',
      session,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getSession(String sessionId) async {
    final db = await database;
    final result = await db.query(
      'sessions',
      where: 'id = ?',
      whereArgs: [sessionId],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<List<Map<String, dynamic>>> getRecentSessions({
    String? type,
    int limit = 10,
  }) async {
    final db = await database;
    return db.query(
      'sessions',
      where: type != null ? 'type = ?' : null,
      whereArgs: type != null ? [type] : null,
      orderBy: 'started_at DESC',
      limit: limit,
    );
  }

  // ==================== History ====================

  Future<void> addHistoryEntry(Map<String, dynamic> entry) async {
    final db = await database;
    await db.insert('history', entry);
  }

  Future<List<Map<String, dynamic>>> getHistory({
    String? positionId,
    int limit = 50,
  }) async {
    final db = await database;
    return db.query(
      'history',
      where: positionId != null ? 'position_id = ?' : null,
      whereArgs: positionId != null ? [positionId] : null,
      orderBy: 'viewed_at DESC',
      limit: limit,
    );
  }

  Future<void> clearHistory() async {
    final db = await database;
    await db.delete('history');
  }

  // ==================== Badges ====================

  Future<void> unlockBadge(String badgeId) async {
    final db = await database;
    await db.insert(
      'badges',
      {
        'id': badgeId,
        'unlocked_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<List<String>> getUnlockedBadgeIds() async {
    final db = await database;
    final result = await db.query('badges', columns: ['id']);
    return result.map((row) => row['id'] as String).toList();
  }

  Future<DateTime?> getBadgeUnlockTime(String badgeId) async {
    final db = await database;
    final result = await db.query(
      'badges',
      columns: ['unlocked_at'],
      where: 'id = ?',
      whereArgs: [badgeId],
    );
    if (result.isEmpty) return null;
    final dateStr = result.first['unlocked_at'] as String?;
    return dateStr != null ? DateTime.parse(dateStr) : null;
  }

  // ==================== Streaks ====================

  Future<Map<String, dynamic>> getStreak() async {
    final db = await database;
    final result = await db.query('streaks', where: 'id = ?', whereArgs: [1]);
    return result.first;
  }

  Future<void> updateStreak(Map<String, dynamic> streak) async {
    final db = await database;
    await db.update(
      'streaks',
      streak,
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  // ==================== Game Progress ====================

  Future<void> updateGameProgress(String gameId, Map<String, dynamic> data) async {
    final db = await database;
    data['game_id'] = gameId;
    await db.insert(
      'game_progress',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getGameProgress(String gameId) async {
    final db = await database;
    final result = await db.query(
      'game_progress',
      where: 'game_id = ?',
      whereArgs: [gameId],
    );
    return result.isNotEmpty ? result.first : null;
  }

  // ==================== Love Notes ====================

  Future<void> saveLoveNote(Map<String, dynamic> note) async {
    final db = await database;
    await db.insert('love_notes', note);
  }

  Future<List<Map<String, dynamic>>> getLoveNotes({int limit = 50}) async {
    final db = await database;
    return db.query(
      'love_notes',
      orderBy: 'created_at DESC',
      limit: limit,
    );
  }

  // ==================== Fantasy Scenarios ====================

  Future<void> saveFantasyScenario(Map<String, dynamic> scenario) async {
    final db = await database;
    await db.insert('fantasy_scenarios', scenario);
  }

  Future<List<Map<String, dynamic>>> getFantasyScenarios({int limit = 50}) async {
    final db = await database;
    return db.query(
      'fantasy_scenarios',
      orderBy: 'created_at DESC',
      limit: limit,
    );
  }

  // ==================== Intimacy Maps ====================

  Future<void> saveIntimacyMap(Map<String, dynamic> map) async {
    final db = await database;
    await db.insert('intimacy_maps', map);
  }

  Future<Map<String, dynamic>?> getLatestIntimacyMap() async {
    final db = await database;
    final result = await db.query(
      'intimacy_maps',
      orderBy: 'created_at DESC',
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  // ==================== Soundtracks ====================

  Future<void> saveSoundtrack(Map<String, dynamic> soundtrack) async {
    final db = await database;
    await db.insert('soundtracks', soundtrack);
  }

  Future<List<Map<String, dynamic>>> getSoundtracks({int limit = 20}) async {
    final db = await database;
    return db.query(
      'soundtracks',
      orderBy: 'created_at DESC',
      limit: limit,
    );
  }

  // ==================== Utilities ====================

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('positions_user_data');
    await db.delete('sessions');
    await db.delete('history');
    await db.delete('badges');
    await db.delete('game_progress');
    await db.delete('love_notes');
    await db.delete('fantasy_scenarios');
    await db.delete('intimacy_maps');
    await db.delete('soundtracks');
    
    // Reset streaks
    await db.update(
      'streaks',
      {
        'current_streak': 0,
        'longest_streak': 0,
        'last_activity_date': null,
        'grace_days_used': 0,
      },
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
