import 'dart:convert';

import 'package:dart_games_server/database/database.dart';
import 'package:dart_games_server/routes/failed_stats_routes.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

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

  setUp(() {
    database = Database(':memory:');
    handler = FailedStatsRoutes(database.rawDb).router.call;
  });

  tearDown(() {
    database.close();
  });

  group('FailedStatsRoutes', () {
    group('GET /failed', () {
      test('returns empty list initially', () async {
        final response = await handler(
          Request('GET', Uri.parse('http://localhost/failed')),
        );
        final body = await _readJson(response) as List<dynamic>;

        expect(response.statusCode, equals(200));
        expect(body, isEmpty);
      });
    });

    group('POST /failed', () {
      test('creates entry and returns 201', () async {
        final response = await handler(
          _jsonRequest('POST', '/failed', {
            'playerId': 'player-123',
            'playerName': 'Alice',
            'gameName': 'Target Tag',
            'won': true,
            'durationMs': 120000,
            'dartThrows': 42,
            'turns': 7,
            'playerCount': 3,
            'errorMessage': 'ApiException(404): Player not found',
          }),
        );
        final body = await _readJson(response) as Map<String, dynamic>;

        expect(response.statusCode, equals(201));
        expect(body['playerId'], equals('player-123'));
        expect(body['playerName'], equals('Alice'));
        expect(body['gameName'], equals('Target Tag'));
        expect(body['won'], isTrue);
        expect(body['durationMs'], equals(120000));
        expect(body['dartThrows'], equals(42));
        expect(body['turns'], equals(7));
        expect(body['playerCount'], equals(3));
        expect(body['errorMessage'], contains('404'));
        expect(body['id'], isNotNull);
        expect(body['createdAt'], isNotNull);
      });

      test('creates entry with minimal fields', () async {
        final response = await handler(
          _jsonRequest('POST', '/failed', {
            'playerId': 'player-456',
            'errorMessage': 'Player not found in local list',
          }),
        );
        final body = await _readJson(response) as Map<String, dynamic>;

        expect(response.statusCode, equals(201));
        expect(body['playerId'], equals('player-456'));
        expect(body['playerName'], isNull);
        expect(body['gameName'], isNull);
        expect(body['errorMessage'], equals('Player not found in local list'));
      });

      test('entries appear in GET after creation', () async {
        // Create two entries
        await handler(
          _jsonRequest('POST', '/failed', {
            'playerId': 'p1',
            'gameName': 'Target Tag',
            'errorMessage': 'error 1',
          }),
        );
        await handler(
          _jsonRequest('POST', '/failed', {
            'playerId': 'p2',
            'gameName': 'Monster Mash',
            'errorMessage': 'error 2',
          }),
        );

        final response = await handler(
          Request('GET', Uri.parse('http://localhost/failed')),
        );
        final body = await _readJson(response) as List<dynamic>;

        expect(body, hasLength(2));
      });
    });

    group('DELETE /failed', () {
      test('clears all entries and returns 204', () async {
        // Create an entry
        await handler(
          _jsonRequest('POST', '/failed', {
            'playerId': 'p1',
            'errorMessage': 'error',
          }),
        );

        // Delete all
        final deleteResponse = await handler(
          Request('DELETE', Uri.parse('http://localhost/failed')),
        );
        expect(deleteResponse.statusCode, equals(204));

        // Verify empty
        final getResponse = await handler(
          Request('GET', Uri.parse('http://localhost/failed')),
        );
        final body = await _readJson(getResponse) as List<dynamic>;
        expect(body, isEmpty);
      });
    });

    group('DELETE /failed/<id>', () {
      test('deletes single entry and returns 204', () async {
        // Create two entries
        final resp1 = await handler(
          _jsonRequest('POST', '/failed', {
            'playerId': 'p1',
            'errorMessage': 'error 1',
          }),
        );
        final entry1 = await _readJson(resp1) as Map<String, dynamic>;

        await handler(
          _jsonRequest('POST', '/failed', {
            'playerId': 'p2',
            'errorMessage': 'error 2',
          }),
        );

        // Delete the first entry
        final deleteResponse = await handler(
          Request('DELETE', Uri.parse('http://localhost/failed/${entry1['id']}')),
        );
        expect(deleteResponse.statusCode, equals(204));

        // Verify only one remains
        final getResponse = await handler(
          Request('GET', Uri.parse('http://localhost/failed')),
        );
        final body = await _readJson(getResponse) as List<dynamic>;
        expect(body, hasLength(1));
        expect(body[0]['player_id'], equals('p2'));
      });

      test('returns 404 for unknown id', () async {
        final response = await handler(
          Request('DELETE', Uri.parse('http://localhost/failed/nonexistent')),
        );
        expect(response.statusCode, equals(404));
      });
    });
  });
}
