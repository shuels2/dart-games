import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

import 'database.dart';

/// Zone key for the per-request database session ID.
final _dbSessionKey = Symbol('dbSession');

/// Manages a default database plus lazily-created per-session databases.
///
/// In production, every request uses the default database.  During UI
/// automation testing, each browser instance sends an `X-DB-Session`
/// header with a unique ID; the [dbSessionMiddleware] looks up (or
/// creates) a dedicated database for that session so the two browser
/// instances spawned by Flutter bug #67090 cannot interfere.
class DatabaseRegistry {
  final Database _default;
  final String _dataDir;
  final Map<String, Database> _sessions = {};

  DatabaseRegistry(this._default, this._dataDir);

  /// The raw sqlite3 handle for the default database.
  sqlite3.Database get defaultDb => _default.rawDb;

  /// Returns the raw sqlite3 handle for the current Zone's session,
  /// falling back to the default database when no session is active.
  static sqlite3.Database get current {
    final sessionId = Zone.current[_dbSessionKey] as String?;
    if (sessionId == null) return _instance!.defaultDb;
    return _instance!._getOrCreate(sessionId).rawDb;
  }

  static DatabaseRegistry? _instance;

  /// Set the global singleton so [current] and [dbSessionMiddleware]
  /// can resolve databases.
  static void initialize(DatabaseRegistry registry) {
    _instance = registry;
  }

  Database _getOrCreate(String sessionId) {
    return _sessions.putIfAbsent(sessionId, () {
      final sessDir = p.join(_dataDir, 'sessions');
      Directory(sessDir).createSync(recursive: true);
      final dbPath = p.join(sessDir, '$sessionId.db');
      print('[DatabaseRegistry] Creating session database: $dbPath');
      return Database(dbPath);
    });
  }

  /// Close the default database and all session databases.
  void closeAll() {
    for (final db in _sessions.values) {
      db.close();
    }
    _sessions.clear();
    _default.close();
    _instance = null;
  }
}

/// Shelf middleware that extracts `X-DB-Session` from the request
/// header and runs the inner handler in a Zone with the session ID
/// set.  Route handlers read the correct database via
/// [DatabaseRegistry.current].
Middleware dbSessionMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      final sessionId = request.headers['x-db-session'];
      if (sessionId == null || sessionId.isEmpty) {
        return innerHandler(request);
      }
      return runZoned(
        () => innerHandler(request),
        zoneValues: {_dbSessionKey: sessionId},
      );
    };
  };
}
