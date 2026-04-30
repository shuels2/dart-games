import 'package:sqlite3/sqlite3.dart' as sqlite3;
import '../migration.dart';

/// Baseline migration that creates the initial schema.
///
/// Establishes all 7 application tables and seeds the default
/// dartboard row. This captures the schema as it existed before
/// the migration system was introduced.
class MigrationV1Baseline extends Migration {
  @override
  int get version => 1;

  @override
  String get description => 'Create baseline schema';

  @override
  void migrate(sqlite3.Database db) {
    db.execute('''
      CREATE TABLE IF NOT EXISTS settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      );
    ''');

    db.execute('''
      CREATE TABLE IF NOT EXISTS dartboard (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        name TEXT,
        serial_number TEXT,
        api_key TEXT,
        use_emulator INTEGER NOT NULL DEFAULT 0
      );
    ''');

    db.execute('''
      CREATE TABLE IF NOT EXISTS dartboard_profiles (
        serial_number TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        api_key TEXT NOT NULL,
        last_used TEXT NOT NULL
      );
    ''');

    db.execute('''
      CREATE TABLE IF NOT EXISTS players (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        photo_path TEXT,
        created_at TEXT NOT NULL,
        games_played INTEGER NOT NULL DEFAULT 0,
        games_won INTEGER NOT NULL DEFAULT 0
      );
    ''');

    db.execute('''
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

    db.execute('''
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

    db.execute('''
      CREATE TABLE IF NOT EXISTS victory_music (
        id TEXT PRIMARY KEY,
        file_name TEXT NOT NULL,
        file_path TEXT NOT NULL,
        is_current INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      );
    ''');

    // Seed the default singleton dartboard row.
    final result = db.select('SELECT COUNT(*) AS cnt FROM dartboard;');
    final count = result.first['cnt'] as int;
    if (count == 0) {
      db.execute(
        'INSERT INTO dartboard (id, use_emulator) VALUES (1, 0);',
      );
    }
  }
}
