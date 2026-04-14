import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

import '../database/database_helpers.dart';

class SettingsRoutes {
  final sqlite3.Database _db;

  SettingsRoutes(this._db);

  Router get router {
    final router = Router();

    // GET /api/v1/settings - Get all settings
    router.get('/', _getAll);

    // GET /api/v1/settings/<key> - Get single setting
    router.get('/<key>', _get);

    // PUT /api/v1/settings/<key> - Create/update setting
    router.put('/<key>', _put);

    // DELETE /api/v1/settings/<key> - Delete setting
    router.delete('/<key>', _delete);

    // PUT /api/v1/settings - Bulk update (batch set multiple settings)
    router.put('/', _putBatch);

    return router;
  }

  /// GET / - Returns all settings as a flat JSON object.
  Future<Response> _getAll(Request request) async {
    final results = _db.select('SELECT key, value FROM settings;');
    final map = <String, String>{};
    for (final row in results) {
      map[row['key'] as String] = row['value'] as String;
    }
    return Response.ok(
      jsonEncode(map),
      headers: {'content-type': 'application/json'},
    );
  }

  /// GET /<key> - Returns a single setting by key, or 404 if not found.
  Future<Response> _get(Request request, String key) async {
    final results = _db.select(
      'SELECT key, value FROM settings WHERE key = ?;',
      [key],
    );
    if (results.isEmpty) {
      return Response.notFound(
        jsonEncode({'error': 'Setting not found: $key'}),
        headers: {'content-type': 'application/json'},
      );
    }
    final row = rowToMap(results.first);
    return Response.ok(
      jsonEncode(row),
      headers: {'content-type': 'application/json'},
    );
  }

  /// PUT /<key> - Creates or updates a setting. Body: { "value": "v" }
  Future<Response> _put(Request request, String key) async {
    final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    final value = body['value'] as String;

    final stmt = _db.prepare(
      'INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?);',
    );
    try {
      stmt.execute([key, value]);
    } finally {
      stmt.dispose();
    }

    return Response.ok(
      jsonEncode({'key': key, 'value': value}),
      headers: {'content-type': 'application/json'},
    );
  }

  /// DELETE /<key> - Deletes a setting by key.
  Future<Response> _delete(Request request, String key) async {
    executeUpdate(_db, 'DELETE FROM settings WHERE key = ?;', [key]);
    return Response(204);
  }

  /// PUT / - Bulk upsert settings. Body: { "key1": "value1", "key2": "value2" }
  Future<Response> _putBatch(Request request) async {
    final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;

    final stmt = _db.prepare(
      'INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?);',
    );
    try {
      for (final entry in body.entries) {
        stmt.execute([entry.key, entry.value as String]);
      }
    } finally {
      stmt.dispose();
    }

    return Response.ok(
      jsonEncode(body),
      headers: {'content-type': 'application/json'},
    );
  }
}
