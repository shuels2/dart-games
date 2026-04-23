import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

const _jsonHeaders = {'content-type': 'application/json'};

/// Routes for test-only operations.
///
/// Provides a single atomic reset endpoint that clears all user data
/// in one transaction — more reliable than multiple independent DELETE
/// calls which can fail silently or race with the app's data loading.
class TestRoutes {
  final sqlite3.Database _db;
  final String _dataDir;

  /// Monotonically-increasing epoch counter.  Incremented on every
  /// POST /test/reset so the server can reject stale writes that were
  /// already in-flight when the reset happened.
  static int _testEpoch = 0;

  /// Current epoch — checked by write-path routes (saved games, players)
  /// against the `X-Test-Epoch` header sent by ApiClient.
  static int get currentTestEpoch => _testEpoch;

  /// Reset rate-limit state so unit tests don't interfere with each other.
  static void resetRateLimitState() {
    _lastEpochAdvance = null;
  }

  /// Timestamp of the last epoch-advancing reset.  Used to rate-limit
  /// phantom resets: legitimate setUp calls are 10+ seconds apart,
  /// while phantom bursts arrive within milliseconds.
  static DateTime? _lastEpochAdvance;
  static const _epochCooldown = Duration(seconds: 8);

  TestRoutes(this._db, this._dataDir);

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
  ///
  /// If the request carries an `X-Test-Epoch` header, the server checks
  /// that it matches the current epoch.  A mismatch means this is a stale
  /// reset from a previous test that arrived late — reject it with 409
  /// so it doesn't bump the epoch and invalidate the current test's writes.
  Future<Response> _reset(Request request) async {
    final requestId = request.headers['x-request-id'] ?? 'no-id';

    // Idempotent check: if X-Target-Epoch already matches the current
    // server epoch, another request (phantom or legitimate) already
    // advanced to this target.  Return success without wiping the DB.
    final targetEpochHeader = request.headers['x-target-epoch'];
    if (targetEpochHeader != null) {
      final targetEpoch = int.tryParse(targetEpochHeader);
      if (targetEpoch != null && targetEpoch == _testEpoch) {
        print('[TestRoutes] IDEMPOTENT duplicate — target=$targetEpoch '
            'already matches current epoch  request_id=$requestId');
        return Response.ok(
          jsonEncode({
            'status': 'ok',
            'test_epoch': _testEpoch,
            'idempotent': true,
            'deleted': {
              'players': 0,
              'game_history': 0,
              'saved_games': 0,
              'victory_music': 0,
              'failed_stats': 0,
              'photos': 0,
            },
          }),
          headers: _jsonHeaders,
        );
      }
    }

    // Guard against stale resets from previous tests.
    final epochHeader = request.headers['x-test-epoch'];
    if (epochHeader != null) {
      final requestEpoch = int.tryParse(epochHeader);
      if (requestEpoch != null && requestEpoch != _testEpoch) {
        print('[TestRoutes] REJECTED stale POST /test/reset — '
            'request epoch=$requestEpoch, current=$_testEpoch  '
            'request_id=$requestId');
        return Response(409,
          body: jsonEncode({
            'error': 'Stale test reset',
            'current_epoch': _testEpoch,
          }),
          headers: _jsonHeaders,
        );
      }
    }

    print('[TestRoutes] POST /test/reset  request_id=$requestId  '
        'client_epoch=${epochHeader ?? "none"}  '
        'target_epoch=${targetEpochHeader ?? "none"}  '
        'server_epoch=$_testEpoch');

    // Rate-limit epoch-advancing resets to catch phantom requests.
    // Legitimate setUp calls are 10+ seconds apart; phantom bursts
    // from the same Dart isolate arrive within milliseconds.
    if (targetEpochHeader != null && _lastEpochAdvance != null) {
      final elapsed = DateTime.now().difference(_lastEpochAdvance!);
      if (elapsed < _epochCooldown) {
        print('[TestRoutes] RATE-LIMITED phantom reset — '
            '${elapsed.inMilliseconds}ms since last epoch advance  '
            'request_id=$requestId');
        return Response.ok(
          jsonEncode({
            'status': 'ok',
            'test_epoch': _testEpoch,
            'rate_limited': true,
            'deleted': {
              'players': 0,
              'game_history': 0,
              'saved_games': 0,
              'victory_music': 0,
              'failed_stats': 0,
              'photos': 0,
            },
          }),
          headers: _jsonHeaders,
        );
      }
    }

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
        // up-to-date. This prevents a subsequent read from seeing stale
        // data from a pre-reset WAL frame.
        _db.execute('PRAGMA wal_checkpoint(TRUNCATE);');

        // Advance the epoch so stale writes from the previous test are
        // rejected.  Must happen after COMMIT so the new epoch is only
        // visible once the database is actually clean.
        //
        // The client controls the target value via `X-Target-Epoch`.
        // The server SETs (not increments) to that value.  This makes
        // the operation idempotent: if phantom duplicate resets arrive
        // with the same target, the epoch is set to the same value —
        // no drift.  Without this header the epoch stays unchanged.
        if (targetEpochHeader != null) {
          final targetEpoch = int.tryParse(targetEpochHeader);
          if (targetEpoch != null) {
            final previousEpoch = _testEpoch;
            _testEpoch = targetEpoch;
            if (targetEpoch != previousEpoch) {
              _lastEpochAdvance = DateTime.now();
              print('[TestRoutes] Epoch ADVANCED: $previousEpoch → $targetEpoch  '
                  'request_id=$requestId');
            } else {
              print('[TestRoutes] Epoch UNCHANGED (idempotent duplicate): '
                  '$previousEpoch → $targetEpoch  request_id=$requestId');
            }
          }
        }

        // Delete photo files after the transaction succeeds.
        for (final path in photoPaths) {
          final file = File(path);
          if (file.existsSync()) {
            file.deleteSync();
          }
        }

        print('[TestRoutes] Reset complete  request_id=$requestId  '
            'epoch=$_testEpoch  '
            'deleted: players=$playersCount  saved_games=$savedGamesCount  '
            'history=$historyCount  music=$musicCount  '
            'failed_stats=$failedStatsCount  photos=${photoPaths.length}');

        return Response.ok(
          jsonEncode({
            'status': 'ok',
            'test_epoch': _testEpoch,
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
