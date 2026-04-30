import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

import '../database/database_registry.dart';

const _jsonHeaders = {'content-type': 'application/json'};

/// Routes for test-only operations.
///
/// Provides a single atomic reset endpoint that clears all user data
/// in one transaction — more reliable than multiple independent DELETE
/// calls which can fail silently or race with the app's data loading.
class TestRoutes {
  final String _dataDir;
  final sqlite3.Database? _testDb;
  sqlite3.Database get _db => _testDb ?? DatabaseRegistry.current;

  TestRoutes(this._dataDir, [this._testDb]);

  Router get router {
    final router = Router();

    // POST /api/v1/test/reset - Atomically clear all user data
    router.post('/reset', _reset);

    return router;
  }

  /// POST /reset - Delete all players, saved games, game history, victory
  /// music, and player-related settings in a single transaction.
  ///
  /// Also deletes photo files from disk. Returns counts of deleted rows
  /// so the caller can verify the reset succeeded.
  Future<Response> _reset(Request request) async {
    final requestId = request.headers['x-request-id'] ?? 'no-id';

    print('[TestRoutes] POST /test/reset  request_id=$requestId');

    try {
      // Collect photo paths before deleting rows.
      final photoRows = _db.select(
        'SELECT photo_path FROM players WHERE photo_path IS NOT NULL;',
      );
      final photoPaths = <String>[];
      for (final row in photoRows) {
        final path = row['photo_path'] as String?;
        if (path != null) photoPaths.add(path);
      }

      // Delete all user data in a single transaction.
      _db.execute('BEGIN;');
      try {
        _db.execute('DELETE FROM game_history;');
        final historyCount = _db.updatedRows;

        _db.execute('DELETE FROM saved_games;');
        final savedGamesCount = _db.updatedRows;

        _db.execute('DELETE FROM victory_music;');
        final musicCount = _db.updatedRows;

        _db.execute('DELETE FROM failed_stats;');
        final failedStatsCount = _db.updatedRows;

        _db.execute('DELETE FROM players;');
        final playersCount = _db.updatedRows;

        // Clear player-related settings (e.g. sort timestamp)
        _db.execute(
          "DELETE FROM settings WHERE key = 'players_last_sorted_at';",
        );

        _db.execute('COMMIT;');

        // Force a WAL checkpoint so the on-disk database file is fully
        // up-to-date.
        _db.execute('PRAGMA wal_checkpoint(TRUNCATE);');

        // Delete photo files after the transaction succeeds.
        for (final path in photoPaths) {
          final file = File(path);
          if (file.existsSync()) {
            file.deleteSync();
          }
        }

        print('[TestRoutes] Reset complete  request_id=$requestId  '
            'deleted: players=$playersCount  saved_games=$savedGamesCount  '
            'history=$historyCount  music=$musicCount  '
            'failed_stats=$failedStatsCount  photos=${photoPaths.length}');

        return Response.ok(
          jsonEncode({
            'status': 'ok',
            'deleted': {
              'players': playersCount,
              'game_history': historyCount,
              'saved_games': savedGamesCount,
              'victory_music': musicCount,
              'failed_stats': failedStatsCount,
              'photos': photoPaths.length,
            },
          }),
          headers: _jsonHeaders,
        );
      } catch (e) {
        _db.execute('ROLLBACK;');
        rethrow;
      }
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({
          'status': 'error',
          'message': e.toString(),
        }),
        headers: _jsonHeaders,
      );
    }
  }
}
