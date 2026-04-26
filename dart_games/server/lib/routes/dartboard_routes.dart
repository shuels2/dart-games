import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

import '../database/database_helpers.dart';
import '../database/database_registry.dart';
import '../models/dartboard_model.dart';

class DartboardRoutes {
  final sqlite3.Database? _testDb;
  sqlite3.Database get _db => _testDb ?? DatabaseRegistry.current;

  DartboardRoutes([this._testDb]);

  Router get router {
    final router = Router();

    // GET /api/v1/dartboard - Get dartboard config
    router.get('/', _getConfig);

    // PUT /api/v1/dartboard - Update dartboard config
    router.put('/', _updateConfig);

    // DELETE /api/v1/dartboard - Clear dartboard config
    router.delete('/', _clearConfig);

    // GET /api/v1/dartboard/profiles - List all profiles
    router.get('/profiles', _getProfiles);

    // PUT /api/v1/dartboard/profiles/<serialNumber> - Upsert profile
    router.put('/profiles/<serialNumber>', _upsertProfile);

    // DELETE /api/v1/dartboard/profiles/<serialNumber> - Delete profile
    router.delete('/profiles/<serialNumber>', _deleteProfile);

    return router;
  }

  /// GET / - Returns the singleton dartboard configuration.
  Future<Response> _getConfig(Request request) async {
    final results = _db.select('SELECT * FROM dartboard WHERE id = 1;');
    final row = rowToMap(results.first);
    final config = ServerDartboard.fromDbRow(row);
    return Response.ok(
      jsonEncode(config.toJson()),
      headers: {'content-type': 'application/json'},
    );
  }

  /// PUT / - Updates the dartboard configuration. Body is ServerDartboard JSON.
  Future<Response> _updateConfig(Request request) async {
    final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    final dartboard = ServerDartboard.fromJson(body);

    executeUpdate(
      _db,
      'UPDATE dartboard SET name = ?, serial_number = ?, api_key = ?, use_emulator = ? WHERE id = 1;',
      [
        dartboard.name,
        dartboard.serialNumber,
        dartboard.apiKey,
        dartboard.useEmulator ? 1 : 0,
      ],
    );

    // Return the updated config
    final results = _db.select('SELECT * FROM dartboard WHERE id = 1;');
    final row = rowToMap(results.first);
    final updated = ServerDartboard.fromDbRow(row);
    return Response.ok(
      jsonEncode(updated.toJson()),
      headers: {'content-type': 'application/json'},
    );
  }

  /// DELETE / - Clears the dartboard configuration (resets to defaults).
  Future<Response> _clearConfig(Request request) async {
    executeUpdate(
      _db,
      'UPDATE dartboard SET name = NULL, serial_number = NULL, api_key = NULL, use_emulator = 0 WHERE id = 1;',
      [],
    );
    return Response(204);
  }

  /// GET /profiles - Returns all dartboard profiles ordered by most recently used.
  Future<Response> _getProfiles(Request request) async {
    final results = _db.select(
      'SELECT * FROM dartboard_profiles ORDER BY last_used DESC;',
    );
    final rows = resultSetToList(results);
    final profiles = rows
        .map((row) => ServerDartboardProfile.fromDbRow(row).toJson())
        .toList();
    return Response.ok(
      jsonEncode(profiles),
      headers: {'content-type': 'application/json'},
    );
  }

  /// PUT /profiles/<serialNumber> - Creates or updates a dartboard profile.
  /// Body: { "name": "...", "apiKey": "...", "lastUsed": "..." }
  Future<Response> _upsertProfile(
    Request request,
    String serialNumber,
  ) async {
    final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    final name = body['name'] as String;
    final apiKey = body['apiKey'] as String;
    final lastUsed = body['lastUsed'] as String;

    final stmt = _db.prepare(
      'INSERT OR REPLACE INTO dartboard_profiles (serial_number, name, api_key, last_used) '
      'VALUES (?, ?, ?, ?);',
    );
    try {
      stmt.execute([serialNumber, name, apiKey, lastUsed]);
    } finally {
      stmt.dispose();
    }

    final profile = ServerDartboardProfile(
      serialNumber: serialNumber,
      name: name,
      apiKey: apiKey,
      lastUsed: lastUsed,
    );
    return Response.ok(
      jsonEncode(profile.toJson()),
      headers: {'content-type': 'application/json'},
    );
  }

  /// DELETE /profiles/<serialNumber> - Deletes a dartboard profile.
  Future<Response> _deleteProfile(
    Request request,
    String serialNumber,
  ) async {
    executeUpdate(
      _db,
      'DELETE FROM dartboard_profiles WHERE serial_number = ?;',
      [serialNumber],
    );
    return Response(204);
  }
}
