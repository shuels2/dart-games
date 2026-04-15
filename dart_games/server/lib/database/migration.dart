import 'package:sqlite3/sqlite3.dart' as sqlite3;
import 'migrations/migration_v1.dart';

/// Base class for all database schema migrations.
///
/// Each migration transforms the schema from version N-1 to version N.
/// Migrations run sequentially during [Database] initialization.
abstract class Migration {
  /// The schema version this migration produces. Must be sequential (1, 2, 3...).
  int get version;

  /// Human-readable description for logging.
  String get description;

  /// Execute the migration against the database.
  ///
  /// Runs inside a transaction — throw to abort and roll back.
  void migrate(sqlite3.Database db);
}

/// Runs pending database migrations during initialization.
///
/// Call [run] once in the [Database] constructor after configuring
/// PRAGMAs. The runner:
/// 1. Creates the `schema_version` table if it does not exist
/// 2. Reads the stored version (0 for fresh databases)
/// 3. Runs each pending migration in its own transaction
/// 4. Updates the version after each successful migration
class MigrationRunner {
  /// All registered migrations, in version order.
  /// Add new migrations at the end.
  static final List<Migration> migrations = [
    MigrationV1Baseline(),
  ];

  /// The current schema version (highest migration version).
  static int get currentVersion =>
      migrations.isEmpty ? 0 : migrations.last.version;

  /// Run any pending migrations against [db].
  ///
  /// Creates the `schema_version` tracking table on first run, then
  /// executes each pending migration inside its own transaction.
  /// If a migration throws, the transaction is rolled back and the
  /// exception is rethrown — the server should not start with a
  /// partially-migrated schema.
  static void run(sqlite3.Database db) {
    // Create version tracking table.
    db.execute('''
      CREATE TABLE IF NOT EXISTS schema_version (
        version INTEGER NOT NULL
      );
    ''');

    // Seed version 0 row if table is empty (fresh database).
    final result = db.select('SELECT version FROM schema_version;');
    if (result.isEmpty) {
      db.execute('INSERT INTO schema_version (version) VALUES (0);');
    }
    final storedVersion = result.isEmpty ? 0 : result.first['version'] as int;

    if (storedVersion >= currentVersion) return;

    // Run pending migrations.
    for (final migration in migrations) {
      if (migration.version <= storedVersion) continue;

      db.execute('BEGIN;');
      try {
        migration.migrate(db);
        db.execute(
          'UPDATE schema_version SET version = ?;',
          [migration.version],
        );
        db.execute('COMMIT;');
      } catch (e) {
        db.execute('ROLLBACK;');
        rethrow;
      }
    }
  }
}
