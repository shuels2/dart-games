import 'package:sqlite3/sqlite3.dart' as sqlite3;
import '../migration.dart';

/// Adds the failed_stats table for logging stats update failures.
///
/// When a player's game-history or stats update fails (e.g. the player
/// was deleted between game-end and the async stats call), the client
/// POSTs the original payload here so it can be investigated or
/// replayed later.
class MigrationV2FailedStats extends Migration {
  @override
  int get version => 2;

  @override
  String get description => 'Add failed_stats table';

  @override
  void migrate(sqlite3.Database db) {
    db.execute('''
      CREATE TABLE IF NOT EXISTS failed_stats (
        id TEXT PRIMARY KEY,
        player_id TEXT NOT NULL,
        player_name TEXT,
        game_name TEXT,
        won INTEGER,
        duration_ms INTEGER,
        dart_throws INTEGER,
        turns INTEGER,
        player_count INTEGER,
        error_message TEXT NOT NULL,
        created_at TEXT NOT NULL
      );
    ''');
  }
}
