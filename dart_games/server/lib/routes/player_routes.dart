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
  Future<Response> _getAll(Request request) async {
    final rows = _db.select(
      'SELECT * FROM players ORDER BY name ASC;',
    );
    final players = resultSetToList(rows).map((row) {
      final player = ServerPlayer.fromDbRow(row);
      final history = _loadHistory(player.id);
      return ServerPlayer(
        id: player.id,
        name: player.name,
        photoPath: player.photoPath,
        createdAt: player.createdAt,
        gamesPlayed: player.gamesPlayed,
        gamesWon: player.gamesWon,
        gameHistory: history,
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
