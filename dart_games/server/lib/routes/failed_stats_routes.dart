import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;
import 'package:uuid/uuid.dart';

import '../database/database_helpers.dart';

const _jsonHeaders = {'content-type': 'application/json'};

/// Routes for the failed-stats log.
///
/// When a client-side stats update fails (e.g. 404 because the player
/// was deleted), the client POSTs the original payload here so it can
/// be investigated or replayed later.
class FailedStatsRoutes {
  final sqlite3.Database _db;

  FailedStatsRoutes(this._db);

  Router get router {
    final router = Router();

    // GET /api/v1/stats/failed - List all failed stats entries
    router.get('/failed', _getAll);

    // POST /api/v1/stats/failed - Log a failed stats update
    router.post('/failed', _create);

    // DELETE /api/v1/stats/failed - Clear all entries
    router.delete('/failed', _deleteAll);

    // DELETE /api/v1/stats/failed/<id> - Delete a single entry
    router.delete('/failed/<id>', _deleteOne);

    return router;
  }

  /// GET /failed - List all failed stats entries, newest first.
  Future<Response> _getAll(Request request) async {
    final rows = _db.select(
      'SELECT * FROM failed_stats ORDER BY created_at DESC;',
    );
    final entries = resultSetToList(rows);

    return Response.ok(
      jsonEncode(entries),
      headers: _jsonHeaders,
    );
  }

  /// POST /failed - Log a failed stats update.
  Future<Response> _create(Request request) async {
    final body =
        jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    final id = const Uuid().v4();
    final playerId = body['playerId'] as String;
    final playerName = body['playerName'] as String?;
    final gameName = body['gameName'] as String?;
    final won = body['won'] as bool?;
    final durationMs = body['durationMs'] as int?;
    final dartThrows = body['dartThrows'] as int?;
    final turns = body['turns'] as int?;
    final playerCount = body['playerCount'] as int?;
    final errorMessage = body['errorMessage'] as String;
    final createdAt = DateTime.now().toUtc().toIso8601String();

    insertRow(
      _db,
      '''INSERT INTO failed_stats
         (id, player_id, player_name, game_name, won, duration_ms,
          dart_throws, turns, player_count, error_message, created_at)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);''',
      [
        id, playerId, playerName, gameName,
        won == true ? 1 : (won == false ? 0 : null),
        durationMs, dartThrows, turns, playerCount,
        errorMessage, createdAt,
      ],
    );

    return Response(
      201,
      body: jsonEncode({
        'id': id,
        'playerId': playerId,
        'playerName': playerName,
        'gameName': gameName,
        'won': won,
        'durationMs': durationMs,
        'dartThrows': dartThrows,
        'turns': turns,
        'playerCount': playerCount,
        'errorMessage': errorMessage,
        'createdAt': createdAt,
      }),
      headers: _jsonHeaders,
    );
  }

  /// DELETE /failed - Clear all failed stats entries.
  Future<Response> _deleteAll(Request request) async {
    executeUpdate(_db, 'DELETE FROM failed_stats;', []);
    return Response(204);
  }

  /// DELETE /failed/<id> - Delete a single entry.
  Future<Response> _deleteOne(Request request, String id) async {
    if (!rowExists(_db, 'failed_stats', 'id = ?', [id])) {
      return Response.notFound(
        jsonEncode({'error': 'Entry not found'}),
        headers: _jsonHeaders,
      );
    }
    executeUpdate(_db, 'DELETE FROM failed_stats WHERE id = ?;', [id]);
    return Response(204);
  }
}
