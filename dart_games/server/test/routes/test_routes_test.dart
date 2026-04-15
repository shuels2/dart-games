import 'dart:convert';
import 'dart:io';

import 'package:dart_games_server/database/database.dart';
import 'package:dart_games_server/routes/player_routes.dart';
import 'package:dart_games_server/routes/saved_game_routes.dart';
import 'package:dart_games_server/routes/test_routes.dart';
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
  late Handler testHandler;
  late Handler playerHandler;
  late Handler savedGameHandler;
  late String dataDir;

  setUp(() {
    database = Database(':memory:');
    dataDir = Directory.systemTemp.createTempSync('test_routes_test_').path;
    testHandler = TestRoutes(database.rawDb, dataDir).router.call;
    playerHandler = PlayerRoutes(database.rawDb, dataDir).router.call;
    savedGameHandler = SavedGameRoutes(database.rawDb).router.call;
  });

  tearDown(() {
    database.close();
    final dir = Directory(dataDir);
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  group('TestRoutes', () {
    group('POST /reset', () {
      test('returns 200 with zero counts on empty database', () async {
        final response = await testHandler(
          Request('POST', Uri.parse('http://localhost/reset')),
        );
        final body = await _readJson(response) as Map<String, dynamic>;

        expect(response.statusCode, equals(200));
        expect(body['status'], equals('ok'));
        expect(body['deleted']['players'], equals(0));
        expect(body['deleted']['game_history'], equals(0));
        expect(body['deleted']['saved_games'], equals(0));
        expect(body['deleted']['victory_music'], equals(0));
        expect(body['deleted']['photos'], equals(0));
      });

      test('clears all players and returns correct count', () async {
        // Create two players
        await playerHandler(_jsonRequest('POST', '/', {
          'id': 'p1',
          'name': 'Alice',
          'createdAt': '2026-04-14T12:00:00.000Z',
        }));
        await playerHandler(_jsonRequest('POST', '/', {
          'id': 'p2',
          'name': 'Bob',
          'createdAt': '2026-04-14T12:00:00.000Z',
        }));

        // Verify players exist
        final listResponse = await playerHandler(
          Request('GET', Uri.parse('http://localhost/')),
        );
        final players = await _readJson(listResponse) as List;
        expect(players, hasLength(2));

        // Reset
        final response = await testHandler(
          Request('POST', Uri.parse('http://localhost/reset')),
        );
        final body = await _readJson(response) as Map<String, dynamic>;

        expect(response.statusCode, equals(200));
        expect(body['deleted']['players'], equals(2));

        // Verify players are gone
        final afterResponse = await playerHandler(
          Request('GET', Uri.parse('http://localhost/')),
        );
        final afterPlayers = await _readJson(afterResponse) as List;
        expect(afterPlayers, isEmpty);
      });

      test('clears all saved games and returns correct count', () async {
        // Create a saved game
        await savedGameHandler(_jsonRequest('POST', '/', {
          'id': 'game1',
          'gameType': 'target_tag',
          'savedAt': '2026-04-14T12:00:00.000Z',
          'playerNames': ['Alice', 'Bob'],
          'progressInfo': 'Round 3/10',
          'gameModeName': 'Standard',
          'leadingPlayerName': 'Alice',
          'leadingPlayerScore': '5',
          'gameState': {'round': 3},
          'waitingForTakeout': false,
        }));

        // Reset
        final response = await testHandler(
          Request('POST', Uri.parse('http://localhost/reset')),
        );
        final body = await _readJson(response) as Map<String, dynamic>;

        expect(response.statusCode, equals(200));
        expect(body['deleted']['saved_games'], equals(1));

        // Verify saved games are gone
        final afterResponse = await savedGameHandler(
          Request('GET', Uri.parse('http://localhost/')),
        );
        final afterGames = await _readJson(afterResponse) as List;
        expect(afterGames, isEmpty);
      });

      test('clears game history along with players', () async {
        // Create a player
        await playerHandler(_jsonRequest('POST', '/', {
          'id': 'p1',
          'name': 'Alice',
          'createdAt': '2026-04-14T12:00:00.000Z',
        }));

        // Add game history
        await playerHandler(_jsonRequest('POST', '/p1/history', {
          'gameName': 'target_tag',
          'timestamp': '2026-04-14T13:00:00.000Z',
          'durationMs': 60000,
          'metadata': {'won': true},
        }));

        // Reset
        final response = await testHandler(
          Request('POST', Uri.parse('http://localhost/reset')),
        );
        final body = await _readJson(response) as Map<String, dynamic>;

        expect(response.statusCode, equals(200));
        expect(body['deleted']['players'], equals(1));
        expect(body['deleted']['game_history'], equals(1));
      });

      test('is idempotent - calling twice returns zero counts on second call', () async {
        // Create a player
        await playerHandler(_jsonRequest('POST', '/', {
          'id': 'p1',
          'name': 'Alice',
          'createdAt': '2026-04-14T12:00:00.000Z',
        }));

        // First reset
        final response1 = await testHandler(
          Request('POST', Uri.parse('http://localhost/reset')),
        );
        final body1 = await _readJson(response1) as Map<String, dynamic>;
        expect(body1['deleted']['players'], equals(1));

        // Second reset - should be all zeros
        final response2 = await testHandler(
          Request('POST', Uri.parse('http://localhost/reset')),
        );
        final body2 = await _readJson(response2) as Map<String, dynamic>;
        expect(response2.statusCode, equals(200));
        expect(body2['deleted']['players'], equals(0));
        expect(body2['deleted']['game_history'], equals(0));
        expect(body2['deleted']['saved_games'], equals(0));
      });

      test('clears everything together', () async {
        // Create players
        await playerHandler(_jsonRequest('POST', '/', {
          'id': 'p1',
          'name': 'Alice',
          'createdAt': '2026-04-14T12:00:00.000Z',
        }));
        await playerHandler(_jsonRequest('POST', '/', {
          'id': 'p2',
          'name': 'Bob',
          'createdAt': '2026-04-14T12:00:00.000Z',
        }));

        // Add history for both
        await playerHandler(_jsonRequest('POST', '/p1/history', {
          'gameName': 'target_tag',
          'timestamp': '2026-04-14T13:00:00.000Z',
          'durationMs': 60000,
          'metadata': {'won': true},
        }));
        await playerHandler(_jsonRequest('POST', '/p2/history', {
          'gameName': 'carnival_derby',
          'timestamp': '2026-04-14T14:00:00.000Z',
          'durationMs': 120000,
          'metadata': {'won': false},
        }));

        // Create saved games
        await savedGameHandler(_jsonRequest('POST', '/', {
          'id': 'game1',
          'gameType': 'target_tag',
          'savedAt': '2026-04-14T12:00:00.000Z',
          'playerNames': ['Alice', 'Bob'],
          'progressInfo': 'Round 3/10',
          'gameModeName': 'Standard',
          'leadingPlayerName': 'Alice',
          'leadingPlayerScore': '5',
          'gameState': {'round': 3},
          'waitingForTakeout': false,
        }));
        await savedGameHandler(_jsonRequest('POST', '/', {
          'id': 'game2',
          'gameType': 'carnival_derby',
          'savedAt': '2026-04-14T13:00:00.000Z',
          'playerNames': ['Alice'],
          'progressInfo': 'Lap 2/3',
          'gameModeName': 'Classic',
          'leadingPlayerName': 'Alice',
          'leadingPlayerScore': '150',
          'gameState': {'lap': 2},
          'waitingForTakeout': false,
        }));

        // Reset everything
        final response = await testHandler(
          Request('POST', Uri.parse('http://localhost/reset')),
        );
        final body = await _readJson(response) as Map<String, dynamic>;

        expect(response.statusCode, equals(200));
        expect(body['status'], equals('ok'));
        expect(body['deleted']['players'], equals(2));
        expect(body['deleted']['game_history'], equals(2));
        expect(body['deleted']['saved_games'], equals(2));

        // Verify all tables are empty
        final playersResponse = await playerHandler(
          Request('GET', Uri.parse('http://localhost/')),
        );
        expect(await _readJson(playersResponse) as List, isEmpty);

        final gamesResponse = await savedGameHandler(
          Request('GET', Uri.parse('http://localhost/')),
        );
        expect(await _readJson(gamesResponse) as List, isEmpty);
      });
    });
  });
}
