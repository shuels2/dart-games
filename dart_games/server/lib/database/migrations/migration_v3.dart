import 'package:sqlite3/sqlite3.dart' as sqlite3;
import '../migration.dart';

/// Adds indexes on hot WHERE-clause columns.
///
/// Three indexes:
/// - `game_history.player_id` — every results screen + player listing
///   joins history by player_id; without this, every lookup is a full
///   table scan on game_history.
/// - `saved_games.game_type` — saved-game listings filter by type per
///   game launch.
/// - `victory_music.is_current` — partial index on the single "current"
///   row, accessed every game-end.
class MigrationV3HotIndexes extends Migration {
  @override
  int get version => 3;

  @override
  String get description => 'Add hot-WHERE indexes on game_history, saved_games, victory_music';

  @override
  void migrate(sqlite3.Database db) {
    db.execute(
      'CREATE INDEX IF NOT EXISTS idx_game_history_player_id '
      'ON game_history(player_id);',
    );
    db.execute(
      'CREATE INDEX IF NOT EXISTS idx_saved_games_game_type '
      'ON saved_games(game_type);',
    );
    db.execute(
      'CREATE INDEX IF NOT EXISTS idx_victory_music_is_current '
      'ON victory_music(is_current) WHERE is_current = 1;',
    );
  }
}
