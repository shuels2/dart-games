import 'dart:convert';
import 'dart:io';

import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;
import 'package:uuid/uuid.dart';

import '../database/database_helpers.dart';
import '../database/database_registry.dart';
import '../models/game_history_model.dart';
import '../models/player_model.dart';

const _jsonHeaders = {'content-type': 'application/json'};

class PlayerRoutes {
  final String _dataDir;
  final sqlite3.Database? _testDb;
  sqlite3.Database get _db => _testDb ?? DatabaseRegistry.current;

  PlayerRoutes(this._dataDir, [this._testDb]);

  Router get router {
    final router = Router();

    // GET /api/v1/players - List all players (with game history)
    router.get('/', _getAll);

    // GET /api/v1/players/<id> - Get single player (with game history)
    router.get('/<id>', _getOne);

    // POST /api/v1/players - Create player
    router.post('/', _create);

    // PUT /api/v1/players/<id> - Update player
    router.put('/<id>', _update);

    // DELETE /api/v1/players - Delete all players (cascades to history)
    router.delete('/', _deleteAll);

    // DELETE /api/v1/players/<id> - Delete player (cascades to history)
    router.delete('/<id>', _delete);

    // POST /api/v1/players/<id>/photo - Upload player photo (base64 in JSON body)
    router.post('/<id>/photo', _uploadPhoto);

    // GET /api/v1/players/<id>/photo - Get player photo (serves file)
    router.get('/<id>/photo', _getPhoto);

    // DELETE /api/v1/players/<id>/photo - Delete player photo
    router.delete('/<id>/photo', _deletePhoto);

    // POST /api/v1/players/<id>/history - Add game history entry
    router.post('/<id>/history', _addHistory);

    // POST /api/v1/players/history/batch - Add history entries for many players
    router.post('/history/batch', _addHistoryBatch);

    // PUT /api/v1/players/<id>/stats - Update player stats
    router.put('/<id>/stats', _updateStats);

    return router;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Loads all game history entries for a given player.
  List<ServerGameHistoryEntry> _loadHistory(String playerId) {
    final rows = _db.select(
      'SELECT * FROM game_history WHERE player_id = ? ORDER BY timestamp DESC;',
      [playerId],
    );
    return resultSetToList(rows)
        .map((r) => ServerGameHistoryEntry.fromDbRow(r))
        .toList();
  }

  /// Loads a single player by id, including game history.
  /// Returns null if not found.
  ServerPlayer? _loadPlayer(String id) {
    final rows = _db.select('SELECT * FROM players WHERE id = ?;', [id]);
    if (rows.isEmpty) return null;
    final player = ServerPlayer.fromDbRow(rowToMap(rows.first));
    final history = _loadHistory(id);
    return ServerPlayer(
      id: player.id,
      name: player.name,
      photoPath: player.photoPath,
      createdAt: player.createdAt,
      gamesPlayed: player.gamesPlayed,
      gamesWon: player.gamesWon,
      gameHistory: history,
    );
  }

  /// Returns the photos directory path, creating it if necessary.
  String _photosDir() {
    final dir = p.join(_dataDir, 'photos');
    Directory(dir).createSync(recursive: true);
    return dir;
  }

  // ---------------------------------------------------------------------------
  // Handlers
  // ---------------------------------------------------------------------------

  /// GET / - List all players with their game history.
  ///
  /// Uses a single LEFT JOIN against `game_history` instead of an N+1
  /// per-player follow-up query. With the `idx_game_history_player_id`
  /// index from migration v3, the lookup is O(log H) per player.
  Future<Response> _getAll(Request request) async {
    final rows = _db.select('''
      SELECT
        p.id              AS p_id,
        p.name            AS p_name,
        p.photo_path      AS p_photo_path,
        p.created_at      AS p_created_at,
        p.games_played    AS p_games_played,
        p.games_won       AS p_games_won,
        h.id              AS h_id,
        h.game_name       AS h_game_name,
        h.timestamp       AS h_timestamp,
        h.duration_ms     AS h_duration_ms,
        h.metadata        AS h_metadata,
        h.dart_throws     AS h_dart_throws,
        h.turns           AS h_turns,
        h.player_count    AS h_player_count
      FROM players p
      LEFT JOIN game_history h ON h.player_id = p.id
      ORDER BY p.name ASC, h.timestamp DESC;
    ''');

    // Group rows by player.id, preserving the players-name ordering and
    // history-timestamp DESC ordering produced by the SQL.
    final byId = <String, ServerPlayer>{};
    final order = <String>[];
    final histories = <String, List<ServerGameHistoryEntry>>{};

    for (final raw in rows) {
      final row = rowToMap(raw);
      final pid = row['p_id'] as String;
      if (!byId.containsKey(pid)) {
        byId[pid] = ServerPlayer.fromDbRow({
          'id': row['p_id'],
          'name': row['p_name'],
          'photo_path': row['p_photo_path'],
          'created_at': row['p_created_at'],
          'games_played': row['p_games_played'],
          'games_won': row['p_games_won'],
        });
        histories[pid] = [];
        order.add(pid);
      }
      // h_id is NULL for players with no history (LEFT JOIN).
      if (row['h_id'] != null) {
        histories[pid]!.add(ServerGameHistoryEntry.fromDbRow({
          'id': row['h_id'],
          'player_id': pid,
          'game_name': row['h_game_name'],
          'timestamp': row['h_timestamp'],
          'duration_ms': row['h_duration_ms'],
          'metadata': row['h_metadata'],
          'dart_throws': row['h_dart_throws'],
          'turns': row['h_turns'],
          'player_count': row['h_player_count'],
        }));
      }
    }

    final players = order.map((id) {
      final p = byId[id]!;
      return ServerPlayer(
        id: p.id,
        name: p.name,
        photoPath: p.photoPath,
        createdAt: p.createdAt,
        gamesPlayed: p.gamesPlayed,
        gamesWon: p.gamesWon,
        gameHistory: histories[id]!,
      ).toJson();
    }).toList();

    return Response.ok(
      jsonEncode(players),
      headers: _jsonHeaders,
    );
  }

  /// GET /<id> - Get a single player with game history.
  Future<Response> _getOne(Request request, String id) async {
    final player = _loadPlayer(id);
    if (player == null) {
      return Response.notFound(
        jsonEncode({'error': 'Player not found'}),
        headers: _jsonHeaders,
      );
    }
    return Response.ok(
      jsonEncode(player.toJson()),
      headers: _jsonHeaders,
    );
  }

  /// POST / - Create a new player.
  Future<Response> _create(Request request) async {
    final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    final id = body['id'] as String;
    final name = body['name'] as String;
    final createdAt = body['createdAt'] as String;

    if (rowExists(_db, 'players', 'id = ?', [id])) {
      return Response(409,
        body: jsonEncode({'error': 'Player already exists', 'id': id}),
        headers: _jsonHeaders,
      );
    }

    insertRow(
      _db,
      'INSERT INTO players (id, name, created_at) VALUES (?, ?, ?);',
      [id, name, createdAt],
    );

    final player = _loadPlayer(id)!;
    return Response(
      201,
      body: jsonEncode(player.toJson()),
      headers: _jsonHeaders,
    );
  }

  /// PUT /<id> - Update a player's name.
  Future<Response> _update(Request request, String id) async {
    if (!rowExists(_db, 'players', 'id = ?', [id])) {
      return Response.notFound(
        jsonEncode({'error': 'Player not found'}),
        headers: _jsonHeaders,
      );
    }

    final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    final name = body['name'] as String;

    executeUpdate(
      _db,
      'UPDATE players SET name = ? WHERE id = ?;',
      [name, id],
    );

    final player = _loadPlayer(id)!;
    return Response.ok(
      jsonEncode(player.toJson()),
      headers: _jsonHeaders,
    );
  }

  /// DELETE / - Delete all players, their photos, and game history.
  Future<Response> _deleteAll(Request request) async {
    // Delete all photo files.
    final rows = _db.select('SELECT photo_path FROM players WHERE photo_path IS NOT NULL;');
    for (final row in resultSetToList(rows)) {
      final photoPath = row['photo_path'] as String?;
      if (photoPath != null) {
        final file = File(photoPath);
        if (file.existsSync()) {
          file.deleteSync();
        }
      }
    }

    // CASCADE will handle game_history deletion.
    executeUpdate(_db, 'DELETE FROM players;', []);

    return Response(204);
  }

  /// DELETE /<id> - Delete a player and their photo file.
  Future<Response> _delete(Request request, String id) async {
    // Delete photo file if it exists.
    final rows = _db.select('SELECT photo_path FROM players WHERE id = ?;', [id]);
    if (rows.isNotEmpty) {
      final photoPath = rows.first['photo_path'] as String?;
      if (photoPath != null) {
        final file = File(photoPath);
        if (file.existsSync()) {
          file.deleteSync();
        }
      }
    }

    // CASCADE will handle game_history deletion.
    executeUpdate(_db, 'DELETE FROM players WHERE id = ?;', [id]);

    return Response(204);
  }

  /// POST /<id>/photo - Upload a player photo from base64 JSON body.
  Future<Response> _uploadPhoto(Request request, String id) async {
    if (!rowExists(_db, 'players', 'id = ?', [id])) {
      return Response.notFound(
        jsonEncode({'error': 'Player not found'}),
        headers: _jsonHeaders,
      );
    }

    final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    final photoData = body['photoData'] as String;
    final fileName = body['fileName'] as String;
    final ext = p.extension(fileName).isNotEmpty ? p.extension(fileName) : '.jpg';

    final photosDir = _photosDir();
    final filePath = p.join(photosDir, '$id$ext');

    // Normalize and decode base64 (pad if needed, strip whitespace).
    var normalized = photoData.replaceAll(RegExp(r'\s+'), '');
    final remainder = normalized.length % 4;
    if (remainder != 0) {
      normalized = normalized.padRight(normalized.length + (4 - remainder), '=');
    }
    final bytes = base64Decode(normalized);
    File(filePath).writeAsBytesSync(bytes);

    // Update the player's photo_path in the database.
    executeUpdate(
      _db,
      'UPDATE players SET photo_path = ? WHERE id = ?;',
      [filePath, id],
    );

    return Response.ok(
      jsonEncode({'photoPath': filePath}),
      headers: _jsonHeaders,
    );
  }

  /// GET /<id>/photo - Serve the player's photo file.
  Future<Response> _getPhoto(Request request, String id) async {
    final rows = _db.select(
      'SELECT photo_path FROM players WHERE id = ?;',
      [id],
    );

    if (rows.isEmpty) {
      return Response.notFound(
        jsonEncode({'error': 'Player not found'}),
        headers: _jsonHeaders,
      );
    }

    final photoPath = rows.first['photo_path'] as String?;
    if (photoPath == null) {
      return Response.notFound(
        jsonEncode({'error': 'No photo for this player'}),
        headers: _jsonHeaders,
      );
    }

    final file = File(photoPath);
    if (!file.existsSync()) {
      return Response.notFound(
        jsonEncode({'error': 'Photo file not found'}),
        headers: _jsonHeaders,
      );
    }

    final mimeType =
        lookupMimeType(photoPath) ?? 'application/octet-stream';
    final bytes = file.readAsBytesSync();

    return Response.ok(
      bytes,
      headers: {'content-type': mimeType},
    );
  }

  /// DELETE /<id>/photo - Delete a player's photo.
  Future<Response> _deletePhoto(Request request, String id) async {
    if (!rowExists(_db, 'players', 'id = ?', [id])) {
      return Response.notFound(
        jsonEncode({'error': 'Player not found'}),
        headers: _jsonHeaders,
      );
    }

    final rows = _db.select(
      'SELECT photo_path FROM players WHERE id = ?;',
      [id],
    );
    final photoPath = rows.first['photo_path'] as String?;

    if (photoPath != null) {
      final file = File(photoPath);
      if (file.existsSync()) {
        file.deleteSync();
      }
    }

    executeUpdate(
      _db,
      'UPDATE players SET photo_path = NULL WHERE id = ?;',
      [id],
    );

    return Response(204);
  }

  /// POST /<id>/history - Add a game history entry for a player.
  Future<Response> _addHistory(Request request, String id) async {
    if (!rowExists(_db, 'players', 'id = ?', [id])) {
      return Response.notFound(
        jsonEncode({'error': 'Player not found'}),
        headers: _jsonHeaders,
      );
    }

    final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    final historyId = const Uuid().v4();
    final gameName = body['gameName'] as String;
    final timestamp = body['timestamp'] as String;
    final durationMs = body['durationMs'] as int;
    final metadata = body['metadata'] as Map<String, dynamic>?;
    final dartThrows = body['dartThrows'] as int?;
    final turns = body['turns'] as int?;
    final playerCount = body['playerCount'] as int?;

    final metadataJson = metadata != null ? jsonEncode(metadata) : null;

    insertRow(
      _db,
      '''INSERT INTO game_history
         (id, player_id, game_name, timestamp, duration_ms, metadata, dart_throws, turns, player_count)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);''',
      [historyId, id, gameName, timestamp, durationMs, metadataJson, dartThrows, turns, playerCount],
    );

    // Increment games_played; also increment games_won if metadata.won is true.
    final won = metadata != null && metadata['won'] == true;
    if (won) {
      executeUpdate(
        _db,
        'UPDATE players SET games_played = games_played + 1, games_won = games_won + 1 WHERE id = ?;',
        [id],
      );
    } else {
      executeUpdate(
        _db,
        'UPDATE players SET games_played = games_played + 1 WHERE id = ?;',
        [id],
      );
    }

    final entry = ServerGameHistoryEntry(
      id: historyId,
      playerId: id,
      gameName: gameName,
      timestamp: timestamp,
      durationMs: durationMs,
      metadata: metadata,
      dartThrows: dartThrows,
      turns: turns,
      playerCount: playerCount,
    );

    return Response(
      201,
      body: jsonEncode(entry.toJson()),
      headers: _jsonHeaders,
    );
  }

  /// POST /history/batch - Add history entries for many players in one transaction.
  ///
  /// Body: `{"entries": [{"playerId": "...", "gameName": "...", "timestamp": "...",
  /// "durationMs": ..., "metadata": {...}, "dartThrows": ..., "turns": ...,
  /// "playerCount": ...}, ...]}`. Returns `{"saved": <count>, "failed":
  /// [{"playerId": "...", "reason": "..."}]}`. Per-entry failures (unknown
  /// player id) are captured in the `failed` array; the surviving entries
  /// still commit. Body errors return 400.
  Future<Response> _addHistoryBatch(Request request) async {
    final Map<String, dynamic> body;
    try {
      body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    } catch (_) {
      return Response.badRequest(
        body: jsonEncode({'error': 'Invalid JSON body'}),
        headers: _jsonHeaders,
      );
    }

    final entries = body['entries'];
    if (entries is! List) {
      return Response.badRequest(
        body: jsonEncode({'error': 'entries must be a list'}),
        headers: _jsonHeaders,
      );
    }

    if (entries.isEmpty) {
      return Response.ok(
        jsonEncode({'saved': 0, 'failed': []}),
        headers: _jsonHeaders,
      );
    }

    final failed = <Map<String, String>>[];
    var saved = 0;

    _db.execute('BEGIN;');
    try {
      // Reuse a single prepared statement across the batch.
      final insertHistory = _db.prepare(
        'INSERT INTO game_history '
        '(id, player_id, game_name, timestamp, duration_ms, metadata, '
        'dart_throws, turns, player_count) '
        'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);',
      );
      final updateWon = _db.prepare(
        'UPDATE players SET games_played = games_played + 1, '
        'games_won = games_won + 1 WHERE id = ?;',
      );
      final updateLoss = _db.prepare(
        'UPDATE players SET games_played = games_played + 1 WHERE id = ?;',
      );

      try {
        for (final raw in entries) {
          if (raw is! Map<String, dynamic>) {
            failed.add({
              'playerId': '<unknown>',
              'reason': 'entry is not an object',
            });
            continue;
          }
          final playerId = raw['playerId'] as String?;
          if (playerId == null) {
            failed.add({
              'playerId': '<missing>',
              'reason': 'playerId is required',
            });
            continue;
          }
          if (!rowExists(_db, 'players', 'id = ?', [playerId])) {
            failed.add({
              'playerId': playerId,
              'reason': 'Player not found',
            });
            continue;
          }

          final historyId = const Uuid().v4();
          final gameName = raw['gameName'] as String;
          final timestamp = raw['timestamp'] as String;
          final durationMs = raw['durationMs'] as int;
          final metadata = raw['metadata'] as Map<String, dynamic>?;
          final dartThrows = raw['dartThrows'] as int?;
          final turns = raw['turns'] as int?;
          final playerCount = raw['playerCount'] as int?;
          final metadataJson = metadata != null ? jsonEncode(metadata) : null;

          insertHistory.execute([
            historyId, playerId, gameName, timestamp, durationMs,
            metadataJson, dartThrows, turns, playerCount,
          ]);

          final won = metadata != null && metadata['won'] == true;
          if (won) {
            updateWon.execute([playerId]);
          } else {
            updateLoss.execute([playerId]);
          }
          saved++;
        }
      } finally {
        insertHistory.dispose();
        updateWon.dispose();
        updateLoss.dispose();
      }

      _db.execute('COMMIT;');
    } catch (e) {
      _db.execute('ROLLBACK;');
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: _jsonHeaders,
      );
    }

    return Response.ok(
      jsonEncode({'saved': saved, 'failed': failed}),
      headers: _jsonHeaders,
    );
  }

  /// PUT /<id>/stats - Directly update a player's stats.
  Future<Response> _updateStats(Request request, String id) async {
    if (!rowExists(_db, 'players', 'id = ?', [id])) {
      return Response.notFound(
        jsonEncode({'error': 'Player not found'}),
        headers: _jsonHeaders,
      );
    }

    final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    final gamesPlayed = body['gamesPlayed'] as int;
    final gamesWon = body['gamesWon'] as int;

    executeUpdate(
      _db,
      'UPDATE players SET games_played = ?, games_won = ? WHERE id = ?;',
      [gamesPlayed, gamesWon, id],
    );

    final player = _loadPlayer(id)!;
    return Response.ok(
      jsonEncode(player.toJson()),
      headers: _jsonHeaders,
    );
  }
}
