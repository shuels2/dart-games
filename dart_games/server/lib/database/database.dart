import 'package:sqlite3/sqlite3.dart' as sqlite3;

/// SQLite database layer for the Dart Games server.
///
/// Manages the connection to SQLite with WAL mode enabled and creates
/// all required tables on initialization. Pass `:memory:` as the path
/// for in-memory databases (useful for testing).
class Database {
  late final sqlite3.Database _db;

  /// The raw sqlite3 Database handle for use by route handlers.
  sqlite3.Database get rawDb => _db;

  /// Creates and initializes a database at the given [path].
  ///
  /// Use `:memory:` for an in-memory database (tests).
  Database(String path) {
    _db = path == ':memory:'
        ? sqlite3.sqlite3.openInMemory()
        : sqlite3.sqlite3.open(path);

    _configure();
    _createTables();
    _seedDefaults();
  }

  /// Enables WAL mode and foreign key enforcement.
  void _configure() {
    _db.execute('PRAGMA journal_mode = WAL;');
    _db.execute('PRAGMA foreign_keys = ON;');
  }

  /// Creates all application tables if they do not already exist.
  void _createTables() {
    _db.execute('''
      CREATE TABLE IF NOT EXISTS settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      );
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS dartboard (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        name TEXT,
        serial_number TEXT,
        api_key TEXT,
        use_emulator INTEGER NOT NULL DEFAULT 0
      );
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS dartboard_profiles (
        serial_number TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        api_key TEXT NOT NULL,
        last_used TEXT NOT NULL
      );
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS players (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        photo_path TEXT,
        created_at TEXT NOT NULL,
        games_played INTEGER NOT NULL DEFAULT 0,
        games_won INTEGER NOT NULL DEFAULT 0
      );
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS game_history (
        id TEXT PRIMARY KEY,
        player_id TEXT NOT NULL,
        game_name TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        duration_ms INTEGER NOT NULL,
        metadata TEXT,
        dart_throws INTEGER,
        turns INTEGER,
        player_count INTEGER,
        FOREIGN KEY (player_id) REFERENCES players(id) ON DELETE CASCADE
      );
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS saved_games (
        id TEXT PRIMARY KEY,
        game_type TEXT NOT NULL,
        saved_at TEXT NOT NULL,
        player_names TEXT NOT NULL,
        progress_info TEXT NOT NULL,
        game_mode_name TEXT NOT NULL,
        leading_player_name TEXT NOT NULL,
        leading_player_score TEXT NOT NULL,
        game_state TEXT NOT NULL,
        waiting_for_takeout INTEGER NOT NULL DEFAULT 0
      );
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS victory_music (
        id TEXT PRIMARY KEY,
        file_name TEXT NOT NULL,
        file_path TEXT NOT NULL,
        is_current INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      );
    ''');
  }

  /// Inserts the default singleton dartboard row if it does not exist.
  void _seedDefaults() {
    final result = _db.select('SELECT COUNT(*) AS cnt FROM dartboard;');
    final count = result.first['cnt'] as int;
    if (count == 0) {
      _db.execute(
        'INSERT INTO dartboard (id, use_emulator) VALUES (1, 0);',
      );
    }
  }

  /// Closes the database connection and releases resources.
  void close() {
    _db.dispose();
  }
}
