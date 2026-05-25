import 'package:sqlite3/sqlite3.dart' as sqlite3;
import '../migration.dart';

/// Adds the `is_auto_save` column to `saved_games`.
///
/// Auto-saves are created by the auto-save-on-pause mechanism (fires
/// when the dartboard connection drops during gameplay). The resume
/// modal uses this flag to prefix the date display with "AUTOSAVE — "
/// so the user can distinguish them from explicit user saves.
///
/// Pre-existing rows default to 0 (treated as user saves).
class MigrationV4AutoSaveFlag extends Migration {
  @override
  int get version => 4;

  @override
  String get description => 'Add is_auto_save column to saved_games';

  @override
  void migrate(sqlite3.Database db) {
    db.execute(
      'ALTER TABLE saved_games '
      'ADD COLUMN is_auto_save INTEGER NOT NULL DEFAULT 0;',
    );
  }
}
