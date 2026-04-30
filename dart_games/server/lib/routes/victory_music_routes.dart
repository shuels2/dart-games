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
import '../models/victory_music_model.dart';

class VictoryMusicRoutes {
  final String _dataDir;
  final sqlite3.Database? _testDb;
  sqlite3.Database get _db => _testDb ?? DatabaseRegistry.current;

  VictoryMusicRoutes(this._dataDir, [this._testDb]);

  Router get router {
    final router = Router();

    // GET /api/v1/music - List all music files
    router.get('/', _getAll);

    // GET /api/v1/music/current - Get current music file info
    router.get('/current', _getCurrent);

    // POST /api/v1/music - Upload music file (base64 in JSON body)
    router.post('/', _upload);

    // PUT /api/v1/music/<id>/current - Set as current music
    router.put('/<id>/current', _setCurrent);

    // GET /api/v1/music/<id>/file - Download/stream music file
    router.get('/<id>/file', _getFile);

    // DELETE /api/v1/music/<id> - Delete music file
    router.delete('/<id>', _delete);

    // DELETE /api/v1/music - Delete all music files
    router.delete('/', _deleteAll);

    return router;
  }

  Future<Response> _getAll(Request request) async {
    final results = _db.select(
      'SELECT * FROM victory_music ORDER BY created_at DESC;',
    );
    final musicList = resultSetToList(results)
        .map((row) => ServerVictoryMusic.fromDbRow(row).toJson())
        .toList();
    return Response.ok(
      jsonEncode(musicList),
      headers: {'content-type': 'application/json'},
    );
  }

  Future<Response> _getCurrent(Request request) async {
    final results = _db.select(
      'SELECT * FROM victory_music WHERE is_current = 1 LIMIT 1;',
    );
    final rows = resultSetToList(results);
    if (rows.isEmpty) {
      return Response.notFound(
        jsonEncode({'error': 'No current music set'}),
        headers: {'content-type': 'application/json'},
      );
    }
    final music = ServerVictoryMusic.fromDbRow(rows.first);
    return Response.ok(
      jsonEncode(music.toJson()),
      headers: {'content-type': 'application/json'},
    );
  }

  Future<Response> _upload(Request request) async {
    final body = await request.readAsString();
    final json = jsonDecode(body) as Map<String, dynamic>;

    final fileName = json['fileName'] as String;
    final fileData = json['fileData'] as String;

    final id = const Uuid().v4();
    final ext = p.extension(fileName);
    final storedFileName = '$id$ext';
    final musicDir = p.join(_dataDir, 'music');
    final filePath = p.join(musicDir, storedFileName);

    // Ensure the music directory exists
    final dir = Directory(musicDir);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    // Normalize and decode base64 (pad if needed, strip whitespace)
    var normalized = fileData.replaceAll(RegExp(r'\s+'), '');
    final remainder = normalized.length % 4;
    if (remainder != 0) {
      normalized = normalized.padRight(normalized.length + (4 - remainder), '=');
    }
    final bytes = base64Decode(normalized);
    File(filePath).writeAsBytesSync(bytes);

    // Insert into database
    final createdAt = DateTime.now().toUtc().toIso8601String();
    final stmt = _db.prepare('''
      INSERT INTO victory_music (id, file_name, file_path, is_current, created_at)
      VALUES (?, ?, ?, 0, ?);
    ''');
    try {
      stmt.execute([id, fileName, filePath, createdAt]);
    } finally {
      stmt.dispose();
    }

    final music = ServerVictoryMusic(
      id: id,
      fileName: fileName,
      filePath: filePath,
      isCurrent: false,
      createdAt: createdAt,
    );

    return Response(
      201,
      body: jsonEncode(music.toJson()),
      headers: {'content-type': 'application/json'},
    );
  }

  Future<Response> _setCurrent(Request request, String id) async {
    // Clear current flag on all rows
    _db.execute('UPDATE victory_music SET is_current = 0;');

    // Set the specified row as current
    int rowsUpdated;
    final stmt = _db.prepare(
      'UPDATE victory_music SET is_current = 1 WHERE id = ?;',
    );
    try {
      stmt.execute([id]);
      rowsUpdated = _db.updatedRows;
    } finally {
      stmt.dispose();
    }

    if (rowsUpdated == 0) {
      return Response.notFound(
        jsonEncode({'error': 'Music not found'}),
        headers: {'content-type': 'application/json'},
      );
    }

    final results = _db.select(
      'SELECT * FROM victory_music WHERE id = ?;',
      [id],
    );
    final music = ServerVictoryMusic.fromDbRow(resultSetToList(results).first);
    return Response.ok(
      jsonEncode(music.toJson()),
      headers: {'content-type': 'application/json'},
    );
  }

  Future<Response> _getFile(Request request, String id) async {
    final results = _db.select(
      'SELECT * FROM victory_music WHERE id = ?;',
      [id],
    );
    final rows = resultSetToList(results);
    if (rows.isEmpty) {
      return Response.notFound(
        jsonEncode({'error': 'Music not found'}),
        headers: {'content-type': 'application/json'},
      );
    }

    final music = ServerVictoryMusic.fromDbRow(rows.first);
    final file = File(music.filePath);
    if (!file.existsSync()) {
      return Response.notFound(
        jsonEncode({'error': 'Music file not found on disk'}),
        headers: {'content-type': 'application/json'},
      );
    }

    final contentType = lookupMimeType(music.filePath) ??
        'application/octet-stream';
    final bytes = file.readAsBytesSync();

    return Response.ok(
      bytes,
      headers: {'content-type': contentType},
    );
  }

  Future<Response> _delete(Request request, String id) async {
    // Look up the file path before deleting from DB
    final results = _db.select(
      'SELECT * FROM victory_music WHERE id = ?;',
      [id],
    );
    final rows = resultSetToList(results);
    if (rows.isNotEmpty) {
      final music = ServerVictoryMusic.fromDbRow(rows.first);
      final file = File(music.filePath);
      if (file.existsSync()) {
        file.deleteSync();
      }
    }

    final stmt = _db.prepare('DELETE FROM victory_music WHERE id = ?;');
    try {
      stmt.execute([id]);
    } finally {
      stmt.dispose();
    }
    return Response(204);
  }

  Future<Response> _deleteAll(Request request) async {
    // Delete all files from disk
    final results = _db.select('SELECT * FROM victory_music;');
    final rows = resultSetToList(results);
    for (final row in rows) {
      final music = ServerVictoryMusic.fromDbRow(row);
      final file = File(music.filePath);
      if (file.existsSync()) {
        file.deleteSync();
      }
    }

    // Delete all rows from DB
    _db.execute('DELETE FROM victory_music;');
    return Response(204);
  }
}
