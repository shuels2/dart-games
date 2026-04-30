import 'package:sqlite3/sqlite3.dart' as sqlite3;
import 'migration.dart';

/// SQLite database layer for the Dart Games server.
///
/// Manages the connection to SQLite with WAL mode enabled and runs
/// schema migrations on initialization. Pass `:memory:` as the path
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
    MigrationRunner.run(_db);
  }

  /// Enables WAL mode and foreign key enforcement.
  void _configure() {
    _db.execute('PRAGMA journal_mode = WAL;');
    _db.execute('PRAGMA foreign_keys = ON;');
  }

  /// Closes the database connection and releases resources.
  void close() {
    _db.dispose();
  }
}
