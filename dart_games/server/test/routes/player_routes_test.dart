import 'dart:convert';
import 'dart:io';

import 'package:dart_games_server/database/database.dart';
import 'package:dart_games_server/routes/player_routes.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

/// A 1x1 transparent PNG encoded as base64.
const _tinyPng =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk'
    '+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';

/// Helper to build a JSON POST/PUT request.
Request _jsonRequest(
  String method,
  String path,
  Map<String, dynamic> body,
) {
  return Request(
    method,
    Uri.parse('http://localhost$path'),
    body: jsonEncode(body),
    headers: {'content-type': 'application/json'},
  );
}

/// Helper to decode a JSON response body.
Future<dynamic> _readJson(Response response) async {
  return jsonDecode(await response.readAsString());
}

void main() {
  late Database database;
  late Handler handler;
  late String dataDir;

  setUp(() {
    database = Database(':memory:');
    dataDir = Directory.systemTemp.createTempSync('player_test_').path;
    final routes = PlayerRoutes(database.rawDb, dataDir);
    handler = routes.router.call;
  });

  tearDown(() {
    database.close();
    final dir = Directory(dataDir);
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  // ---------------------------------------------------------------------------
  // Shared test data
  // ---------------------------------------------------------------------------

  const playerId = 'test-player-001';
  const playerName = 'Alice';
  const playerCreatedAt = '2026-04-14T12:00:00.000Z';

  Map<String, dynamic> playerBody({
    String id = playerId,
    String name = playerName,
    String createdAt = playerCreatedAt,
  }) =>
      {'id': id, 'name': name, 'createdAt': createdAt};

  Future<Response> createPlayer({
    String id = playerId,
    String name = playerName,
    String createdAt = playerCreatedAt,
  }) async =>
      handler(
        _jsonRequest('POST', '/', playerBody(
          id: id,
          name: name,
          createdAt: createdAt,
        )),
      );

  // ---------------------------------------------------------------------------
  // CRUD group
  // ---------------------------------------------------------------------------

  group('CRUD', () {
    test('GET / returns empty list initially', () async {
      final response = await handler(
        Request('GET', Uri.parse('http://localhost/')),
      );

      expect(response.statusCode, 200);
      final body = await _readJson(response) as List;
      expect(body, isEmpty);
    });

    test('POST / creates player and returns 201', () async {
      final response = await createPlayer();

      expect(response.statusCode, 201);
      final body = await _readJson(response) as Map<String, dynamic>;
      expect(body['id'], playerId);
      expect(body['name'], playerName);
      expect(body['createdAt'], playerCreatedAt);
      expect(body['gamesPlayed'], 0);
      expect(body['gamesWon'], 0);
      expect(body['gameHistory'], isEmpty);
      expect(body['photoPath'], isNull);
    });

    test('GET / returns created player in list', () async {
      await createPlayer();

      final response = await handler(
        Request('GET', Uri.parse('http://localhost/')),
      );

      expect(response.statusCode, 200);
      final body = await _readJson(response) as List;
      expect(body, hasLength(1));
      expect(body[0]['id'], playerId);
      expect(body[0]['name'], playerName);
    });

    test('GET /<id> returns player', () async {
      await createPlayer();

      final response = await handler(
        Request('GET', Uri.parse('http://localhost/$playerId')),
      );

      expect(response.statusCode, 200);
      final body = await _readJson(response) as Map<String, dynamic>;
      expect(body['id'], playerId);
      expect(body['name'], playerName);
      expect(body['createdAt'], playerCreatedAt);
      expect(body['gamesPlayed'], 0);
      expect(body['gamesWon'], 0);
      expect(body['gameHistory'], isEmpty);
    });

    test('GET /<id> returns 404 for unknown id', () async {
      final response = await handler(
        Request('GET', Uri.parse('http://localhost/unknown-id')),
      );

      expect(response.statusCode, 404);
      final body = await _readJson(response) as Map<String, dynamic>;
      expect(body['error'], contains('not found'));
    });

    test('PUT /<id> updates player name', () async {
      await createPlayer();

      final response = await handler(
        _jsonRequest('PUT', '/$playerId', {'name': 'Bob'}),
      );

      expect(response.statusCode, 200);
      final body = await _readJson(response) as Map<String, dynamic>;
      expect(body['id'], playerId);
      expect(body['name'], 'Bob');

      // Verify via GET
      final getResponse = await handler(
        Request('GET', Uri.parse('http://localhost/$playerId')),
      );
      final getBody = await _readJson(getResponse) as Map<String, dynamic>;
      expect(getBody['name'], 'Bob');
    });

    test('PUT /<id> returns 404 for unknown id', () async {
      final response = await handler(
        _jsonRequest('PUT', '/unknown-id', {'name': 'Bob'}),
      );

      expect(response.statusCode, 404);
      final body = await _readJson(response) as Map<String, dynamic>;
      expect(body['error'], contains('not found'));
    });

    test('DELETE /<id> removes player and returns 204', () async {
      await createPlayer();

      final response = await handler(
        Request('DELETE', Uri.parse('http://localhost/$playerId')),
      );

      expect(response.statusCode, 204);
    });

    test('GET / after delete returns empty list', () async {
      await createPlayer();
      await handler(
        Request('DELETE', Uri.parse('http://localhost/$playerId')),
      );

      final response = await handler(
        Request('GET', Uri.parse('http://localhost/')),
      );

      expect(response.statusCode, 200);
      final body = await _readJson(response) as List;
      expect(body, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // Photo group
  // ---------------------------------------------------------------------------

  group('Photo', () {
    test('POST /<id>/photo uploads photo successfully', () async {
      await createPlayer();

      final response = await handler(
        _jsonRequest('POST', '/$playerId/photo', {
          'photoData': _tinyPng,
          'fileName': 'avatar.png',
        }),
      );

      expect(response.statusCode, 200);
      final body = await _readJson(response) as Map<String, dynamic>;
      expect(body['photoPath'], isA<String>());
      expect(body['photoPath'], contains(playerId));

      // Verify the file was actually written to disk
      final file = File(body['photoPath'] as String);
      expect(file.existsSync(), isTrue);
    });

    test('GET /<id>/photo serves the uploaded photo', () async {
      await createPlayer();
      await handler(
        _jsonRequest('POST', '/$playerId/photo', {
          'photoData': _tinyPng,
          'fileName': 'avatar.png',
        }),
      );

      final response = await handler(
        Request('GET', Uri.parse('http://localhost/$playerId/photo')),
      );

      expect(response.statusCode, 200);
      expect(response.headers['content-type'], contains('image/png'));
      final bytes = await response.read().expand((chunk) => chunk).toList();
      expect(bytes, isNotEmpty);
      // Verify the bytes match the decoded base64
      expect(bytes, equals(base64Decode(_tinyPng)));
    });

    test('GET /<id>/photo returns 404 when no photo uploaded', () async {
      await createPlayer();

      final response = await handler(
        Request('GET', Uri.parse('http://localhost/$playerId/photo')),
      );

      expect(response.statusCode, 404);
      final body = await _readJson(response) as Map<String, dynamic>;
      expect(body['error'], contains('No photo'));
    });

    test('GET /<id>/photo returns 404 for unknown player', () async {
      final response = await handler(
        Request('GET', Uri.parse('http://localhost/unknown-id/photo')),
      );

      expect(response.statusCode, 404);
      final body = await _readJson(response) as Map<String, dynamic>;
      expect(body['error'], contains('not found'));
    });

    test('DELETE /<id>/photo removes photo and returns 204', () async {
      await createPlayer();

      // Upload a photo first
      final uploadResponse = await handler(
        _jsonRequest('POST', '/$playerId/photo', {
          'photoData': _tinyPng,
          'fileName': 'avatar.png',
        }),
      );
      final uploadBody =
          await _readJson(uploadResponse) as Map<String, dynamic>;
      final photoPath = uploadBody['photoPath'] as String;
      expect(File(photoPath).existsSync(), isTrue);

      // Delete the photo
      final response = await handler(
        Request('DELETE', Uri.parse('http://localhost/$playerId/photo')),
      );

      expect(response.statusCode, 204);

      // Verify file is removed from disk
      expect(File(photoPath).existsSync(), isFalse);

      // Verify GET photo now returns 404
      final getResponse = await handler(
        Request('GET', Uri.parse('http://localhost/$playerId/photo')),
      );
      expect(getResponse.statusCode, 404);
    });

    test('DELETE player also deletes photo file', () async {
      await createPlayer();

      // Upload a photo
      final uploadResponse = await handler(
        _jsonRequest('POST', '/$playerId/photo', {
          'photoData': _tinyPng,
          'fileName': 'avatar.png',
        }),
      );
      final uploadBody =
          await _readJson(uploadResponse) as Map<String, dynamic>;
      final photoPath = uploadBody['photoPath'] as String;
      expect(File(photoPath).existsSync(), isTrue);

      // Delete the player
      await handler(
        Request('DELETE', Uri.parse('http://localhost/$playerId')),
      );

      // Verify the photo file was cleaned up
      expect(File(photoPath).existsSync(), isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // Game history group
  // ---------------------------------------------------------------------------

  group('Game history', () {
    Map<String, dynamic> historyBody({
      String gameName = 'Target Tag',
      String timestamp = '2026-04-14T13:00:00.000Z',
      int durationMs = 120000,
      Map<String, dynamic>? metadata,
      int? dartThrows,
      int? turns,
      int? playerCount,
    }) =>
        {
          'gameName': gameName,
          'timestamp': timestamp,
          'durationMs': durationMs,
          if (metadata != null) 'metadata': metadata,
          if (dartThrows != null) 'dartThrows': dartThrows,
          if (turns != null) 'turns': turns,
          if (playerCount != null) 'playerCount': playerCount,
        };

    test('POST /<id>/history adds game history entry and returns 201',
        () async {
      await createPlayer();

      final response = await handler(
        _jsonRequest('POST', '/$playerId/history', historyBody(
          dartThrows: 42,
          turns: 10,
          playerCount: 4,
          metadata: {'placement': 1, 'won': true},
        )),
      );

      expect(response.statusCode, 201);
      final body = await _readJson(response) as Map<String, dynamic>;
      expect(body['id'], isA<String>());
      expect(body['playerId'], playerId);
      expect(body['gameName'], 'Target Tag');
      expect(body['timestamp'], '2026-04-14T13:00:00.000Z');
      expect(body['durationMs'], 120000);
      expect(body['dartThrows'], 42);
      expect(body['turns'], 10);
      expect(body['playerCount'], 4);
      expect(body['metadata'], isA<Map>());
      expect(body['metadata']['won'], true);
    });

    test('GET /<id> includes game history in response', () async {
      await createPlayer();
      await handler(
        _jsonRequest('POST', '/$playerId/history', historyBody(
          gameName: 'Carnival Derby',
        )),
      );

      final response = await handler(
        Request('GET', Uri.parse('http://localhost/$playerId')),
      );

      expect(response.statusCode, 200);
      final body = await _readJson(response) as Map<String, dynamic>;
      final history = body['gameHistory'] as List;
      expect(history, hasLength(1));
      expect(history[0]['gameName'], 'Carnival Derby');
      expect(history[0]['playerId'], playerId);
    });

    test('POST /<id>/history increments games_played', () async {
      await createPlayer();
      await handler(
        _jsonRequest('POST', '/$playerId/history', historyBody()),
      );

      final response = await handler(
        Request('GET', Uri.parse('http://localhost/$playerId')),
      );
      final body = await _readJson(response) as Map<String, dynamic>;
      expect(body['gamesPlayed'], 1);
      expect(body['gamesWon'], 0);
    });

    test('POST /<id>/history with metadata.won=true also increments games_won',
        () async {
      await createPlayer();
      await handler(
        _jsonRequest('POST', '/$playerId/history', historyBody(
          metadata: {'won': true, 'placement': 1},
        )),
      );

      final response = await handler(
        Request('GET', Uri.parse('http://localhost/$playerId')),
      );
      final body = await _readJson(response) as Map<String, dynamic>;
      expect(body['gamesPlayed'], 1);
      expect(body['gamesWon'], 1);
    });

    test('POST /<id>/history returns 404 for unknown player', () async {
      final response = await handler(
        _jsonRequest('POST', '/unknown-id/history', historyBody()),
      );

      expect(response.statusCode, 404);
      final body = await _readJson(response) as Map<String, dynamic>;
      expect(body['error'], contains('not found'));
    });

    test('POST /<id>/history handles optional fields (null values)', () async {
      await createPlayer();

      // Send without dartThrows, turns, playerCount
      final response = await handler(
        _jsonRequest('POST', '/$playerId/history', historyBody()),
      );

      expect(response.statusCode, 201);
      final body = await _readJson(response) as Map<String, dynamic>;
      expect(body['dartThrows'], isNull);
      expect(body['turns'], isNull);
      expect(body['playerCount'], isNull);
      expect(body['metadata'], isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // Stats group
  // ---------------------------------------------------------------------------

  group('Stats', () {
    test('PUT /<id>/stats updates gamesPlayed and gamesWon', () async {
      await createPlayer();

      final response = await handler(
        _jsonRequest('PUT', '/$playerId/stats', {
          'gamesPlayed': 15,
          'gamesWon': 7,
        }),
      );

      expect(response.statusCode, 200);
      final body = await _readJson(response) as Map<String, dynamic>;
      expect(body['gamesPlayed'], 15);
      expect(body['gamesWon'], 7);

      // Verify via GET
      final getResponse = await handler(
        Request('GET', Uri.parse('http://localhost/$playerId')),
      );
      final getBody = await _readJson(getResponse) as Map<String, dynamic>;
      expect(getBody['gamesPlayed'], 15);
      expect(getBody['gamesWon'], 7);
    });

    test('PUT /<id>/stats returns 404 for unknown player', () async {
      final response = await handler(
        _jsonRequest('PUT', '/unknown-id/stats', {
          'gamesPlayed': 5,
          'gamesWon': 2,
        }),
      );

      expect(response.statusCode, 404);
      final body = await _readJson(response) as Map<String, dynamic>;
      expect(body['error'], contains('not found'));
    });
  });

  // ---------------------------------------------------------------------------
  // Cascade group
  // ---------------------------------------------------------------------------

  group('Cascade', () {
    test('DELETE player cascades to game_history', () async {
      await createPlayer();

      // Add two history entries
      await handler(
        _jsonRequest('POST', '/$playerId/history', {
          'gameName': 'Target Tag',
          'timestamp': '2026-04-14T13:00:00.000Z',
          'durationMs': 60000,
        }),
      );
      await handler(
        _jsonRequest('POST', '/$playerId/history', {
          'gameName': 'Carnival Derby',
          'timestamp': '2026-04-14T14:00:00.000Z',
          'durationMs': 90000,
        }),
      );

      // Verify history exists
      final beforeResponse = await handler(
        Request('GET', Uri.parse('http://localhost/$playerId')),
      );
      final beforeBody =
          await _readJson(beforeResponse) as Map<String, dynamic>;
      expect((beforeBody['gameHistory'] as List), hasLength(2));

      // Delete the player
      final deleteResponse = await handler(
        Request('DELETE', Uri.parse('http://localhost/$playerId')),
      );
      expect(deleteResponse.statusCode, 204);

      // Re-create same player to check that old history is gone
      await createPlayer();
      final afterResponse = await handler(
        Request('GET', Uri.parse('http://localhost/$playerId')),
      );
      final afterBody =
          await _readJson(afterResponse) as Map<String, dynamic>;
      expect((afterBody['gameHistory'] as List), isEmpty);
      expect(afterBody['gamesPlayed'], 0);
    });
  });
}
