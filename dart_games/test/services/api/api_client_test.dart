import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:dart_games/services/api/api_client.dart';
import 'package:dart_games/services/api/api_config.dart';

void main() {
  setUp(() {
    ApiConfig.configure('http://localhost:8080');
  });

  group('ApiClient - Settings', () {
    test('getSettings returns map of settings', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/v1/settings');
        return http.Response(
          jsonEncode({'voice_enabled': 'true', 'voice_engine': 'Google'}),
          200,
        );
      });

      final client = ApiClient(client: mockClient);
      final settings = await client.getSettings();

      expect(settings, {'voice_enabled': 'true', 'voice_engine': 'Google'});
      client.dispose();
    });

    test('getSetting returns value for existing key', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/api/v1/settings/voice_enabled');
        return http.Response(
          jsonEncode({'key': 'voice_enabled', 'value': 'true'}),
          200,
        );
      });

      final client = ApiClient(client: mockClient);
      final value = await client.getSetting('voice_enabled');

      expect(value, 'true');
      client.dispose();
    });

    test('getSetting returns null for missing key', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'error': 'not found'}),
          404,
        );
      });

      final client = ApiClient(client: mockClient);
      final value = await client.getSetting('missing');

      expect(value, isNull);
      client.dispose();
    });

    test('putSetting sends PUT with value', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'PUT');
        expect(request.url.path, '/api/v1/settings/theme');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['value'], 'dark');
        return http.Response(
          jsonEncode({'key': 'theme', 'value': 'dark'}),
          200,
        );
      });

      final client = ApiClient(client: mockClient);
      await client.putSetting('theme', 'dark');
      client.dispose();
    });

    test('deleteSetting sends DELETE', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'DELETE');
        expect(request.url.path, '/api/v1/settings/theme');
        return http.Response('', 204);
      });

      final client = ApiClient(client: mockClient);
      await client.deleteSetting('theme');
      client.dispose();
    });

    test('putSettings sends bulk PUT', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'PUT');
        expect(request.url.path, '/api/v1/settings');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['k1'], 'v1');
        expect(body['k2'], 'v2');
        return http.Response(jsonEncode(body), 200);
      });

      final client = ApiClient(client: mockClient);
      await client.putSettings({'k1': 'v1', 'k2': 'v2'});
      client.dispose();
    });
  });

  group('ApiClient - Dartboard', () {
    test('getDartboard returns config', () async {
      final config = {
        'name': 'My Board',
        'serialNumber': 'SN-001',
        'apiKey': 'key-123',
        'useEmulator': false,
      };
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/api/v1/dartboard');
        return http.Response(jsonEncode(config), 200);
      });

      final client = ApiClient(client: mockClient);
      final result = await client.getDartboard();

      expect(result['name'], 'My Board');
      expect(result['useEmulator'], false);
      client.dispose();
    });

    test('updateDartboard sends PUT and returns updated config', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'PUT');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(jsonEncode(body), 200);
      });

      final client = ApiClient(client: mockClient);
      final result = await client.updateDartboard({
        'name': 'Board',
        'serialNumber': 'SN',
        'apiKey': 'key',
        'useEmulator': true,
      });

      expect(result['useEmulator'], true);
      client.dispose();
    });

    test('clearDartboard sends DELETE', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'DELETE');
        expect(request.url.path, '/api/v1/dartboard');
        return http.Response('', 204);
      });

      final client = ApiClient(client: mockClient);
      await client.clearDartboard();
      client.dispose();
    });

    test('getDartboardProfiles returns list', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode([
          {'serialNumber': 'SN-1', 'name': 'Board 1', 'apiKey': 'k1', 'lastUsed': '2026-01-01'},
        ]), 200);
      });

      final client = ApiClient(client: mockClient);
      final profiles = await client.getDartboardProfiles();

      expect(profiles.length, 1);
      expect(profiles.first['serialNumber'], 'SN-1');
      client.dispose();
    });

    test('upsertDartboardProfile sends PUT with serial in path', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'PUT');
        expect(request.url.path, '/api/v1/dartboard/profiles/SN-001');
        return http.Response(jsonEncode({}), 200);
      });

      final client = ApiClient(client: mockClient);
      await client.upsertDartboardProfile('SN-001', {
        'name': 'Board',
        'apiKey': 'key',
        'lastUsed': '2026-01-01',
      });
      client.dispose();
    });

    test('deleteDartboardProfile sends DELETE', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'DELETE');
        expect(request.url.path, '/api/v1/dartboard/profiles/SN-001');
        return http.Response('', 204);
      });

      final client = ApiClient(client: mockClient);
      await client.deleteDartboardProfile('SN-001');
      client.dispose();
    });
  });

  group('ApiClient - Players', () {
    test('getPlayers returns list', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode([
          {
            'id': 'p1',
            'name': 'Alice',
            'photoPath': null,
            'createdAt': '2026-01-01',
            'gamesPlayed': 0,
            'gamesWon': 0,
            'gameHistory': [],
          },
        ]), 200);
      });

      final client = ApiClient(client: mockClient);
      final players = await client.getPlayers();

      expect(players.length, 1);
      expect(players.first['name'], 'Alice');
      client.dispose();
    });

    test('getPlayer returns player or null', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('p1')) {
          return http.Response(jsonEncode({'id': 'p1', 'name': 'Alice'}), 200);
        }
        return http.Response('', 404);
      });

      final client = ApiClient(client: mockClient);

      final found = await client.getPlayer('p1');
      expect(found, isNotNull);
      expect(found!['name'], 'Alice');

      final missing = await client.getPlayer('p999');
      expect(missing, isNull);
      client.dispose();
    });

    test('createPlayer sends POST and returns 201 data', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/v1/players');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(jsonEncode(body), 201);
      });

      final client = ApiClient(client: mockClient);
      final result = await client.createPlayer({
        'id': 'p1',
        'name': 'Alice',
        'createdAt': '2026-01-01',
      });

      expect(result['name'], 'Alice');
      client.dispose();
    });

    test('updatePlayer sends PUT', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'PUT');
        expect(request.url.path, '/api/v1/players/p1');
        return http.Response(jsonEncode({'id': 'p1', 'name': 'Bob'}), 200);
      });

      final client = ApiClient(client: mockClient);
      final result = await client.updatePlayer('p1', {'name': 'Bob'});

      expect(result['name'], 'Bob');
      client.dispose();
    });

    test('deletePlayer sends DELETE', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'DELETE');
        return http.Response('', 204);
      });

      final client = ApiClient(client: mockClient);
      await client.deletePlayer('p1');
      client.dispose();
    });

    test('uploadPlayerPhoto sends base64 data', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/v1/players/p1/photo');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['photoData'], 'abc123');
        expect(body['fileName'], 'photo.jpg');
        return http.Response(jsonEncode({'photoPath': '/photos/p1.jpg'}), 200);
      });

      final client = ApiClient(client: mockClient);
      final path = await client.uploadPlayerPhoto('p1', 'abc123', 'photo.jpg');

      expect(path, '/photos/p1.jpg');
      client.dispose();
    });

    test('getPlayerPhoto returns bytes or null', () async {
      final testBytes = Uint8List.fromList([1, 2, 3, 4]);
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('p1/photo')) {
          return http.Response.bytes(testBytes, 200);
        }
        return http.Response('', 404);
      });

      final client = ApiClient(client: mockClient);

      final bytes = await client.getPlayerPhoto('p1');
      expect(bytes, testBytes);

      final missing = await client.getPlayerPhoto('p999');
      expect(missing, isNull);
      client.dispose();
    });

    test('addPlayerHistory sends POST', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/v1/players/p1/history');
        return http.Response(
          jsonEncode({'id': 'h1', 'gameName': 'CarnivalDerby'}),
          201,
        );
      });

      final client = ApiClient(client: mockClient);
      final result = await client.addPlayerHistory('p1', {
        'gameName': 'CarnivalDerby',
        'timestamp': '2026-01-01',
        'durationMs': 5000,
      });

      expect(result['gameName'], 'CarnivalDerby');
      client.dispose();
    });

    test('updatePlayerStats sends PUT', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'PUT');
        expect(request.url.path, '/api/v1/players/p1/stats');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['gamesPlayed'], 10);
        expect(body['gamesWon'], 3);
        return http.Response(jsonEncode({}), 200);
      });

      final client = ApiClient(client: mockClient);
      await client.updatePlayerStats('p1', gamesPlayed: 10, gamesWon: 3);
      client.dispose();
    });
  });

  group('ApiClient - Saved Games', () {
    test('getSavedGames returns list', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/api/v1/games');
        return http.Response(jsonEncode([]), 200);
      });

      final client = ApiClient(client: mockClient);
      final games = await client.getSavedGames();

      expect(games, isEmpty);
      client.dispose();
    });

    test('getSavedGamesByType filters by type', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/api/v1/games/CarnivalDerby');
        return http.Response(jsonEncode([{'id': 'g1'}]), 200);
      });

      final client = ApiClient(client: mockClient);
      final games = await client.getSavedGamesByType('CarnivalDerby');

      expect(games.length, 1);
      client.dispose();
    });

    test('saveGame sends POST', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        return http.Response(jsonEncode({'id': 'g1'}), 200);
      });

      final client = ApiClient(client: mockClient);
      final result = await client.saveGame({'id': 'g1', 'gameType': 'X'});

      expect(result['id'], 'g1');
      client.dispose();
    });

    test('deleteSavedGame sends DELETE', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'DELETE');
        expect(request.url.path, '/api/v1/games/g1');
        return http.Response('', 204);
      });

      final client = ApiClient(client: mockClient);
      await client.deleteSavedGame('g1');
      client.dispose();
    });

    test('deleteSavedGamesByType sends DELETE with type path', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'DELETE');
        expect(request.url.path, '/api/v1/games/type/CarnivalDerby');
        return http.Response('', 204);
      });

      final client = ApiClient(client: mockClient);
      await client.deleteSavedGamesByType('CarnivalDerby');
      client.dispose();
    });
  });

  group('ApiClient - Victory Music', () {
    test('getMusic returns list', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode([]), 200);
      });

      final client = ApiClient(client: mockClient);
      final music = await client.getMusic();

      expect(music, isEmpty);
      client.dispose();
    });

    test('getCurrentMusic returns info or null', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/current')) {
          return http.Response(jsonEncode({'id': 'm1', 'fileName': 'song.mp3'}), 200);
        }
        return http.Response('', 404);
      });

      final client = ApiClient(client: mockClient);
      final music = await client.getCurrentMusic();

      expect(music, isNotNull);
      expect(music!['fileName'], 'song.mp3');
      client.dispose();
    });

    test('getCurrentMusic returns null when none set', () async {
      final mockClient = MockClient((request) async {
        return http.Response('', 404);
      });

      final client = ApiClient(client: mockClient);
      final music = await client.getCurrentMusic();

      expect(music, isNull);
      client.dispose();
    });

    test('uploadMusic sends base64 data', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['fileName'], 'song.mp3');
        expect(body['fileData'], 'base64data');
        return http.Response(
          jsonEncode({'id': 'm1', 'fileName': 'song.mp3'}),
          201,
        );
      });

      final client = ApiClient(client: mockClient);
      final result = await client.uploadMusic('song.mp3', 'base64data');

      expect(result['id'], 'm1');
      client.dispose();
    });

    test('setCurrentMusic sends PUT', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'PUT');
        expect(request.url.path, '/api/v1/music/m1/current');
        return http.Response(jsonEncode({}), 200);
      });

      final client = ApiClient(client: mockClient);
      await client.setCurrentMusic('m1');
      client.dispose();
    });

    test('getMusicFile returns bytes or null', () async {
      final testBytes = Uint8List.fromList([10, 20, 30]);
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('m1')) {
          return http.Response.bytes(testBytes, 200);
        }
        return http.Response('', 404);
      });

      final client = ApiClient(client: mockClient);
      final bytes = await client.getMusicFile('m1');
      expect(bytes, testBytes);

      final missing = await client.getMusicFile('m999');
      expect(missing, isNull);
      client.dispose();
    });

    test('deleteMusic sends DELETE', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'DELETE');
        expect(request.url.path, '/api/v1/music/m1');
        return http.Response('', 204);
      });

      final client = ApiClient(client: mockClient);
      await client.deleteMusic('m1');
      client.dispose();
    });

    test('deleteAllMusic sends DELETE to root', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'DELETE');
        expect(request.url.path, '/api/v1/music');
        return http.Response('', 204);
      });

      final client = ApiClient(client: mockClient);
      await client.deleteAllMusic();
      client.dispose();
    });
  });

  group('ApiClient - Health', () {
    test('health returns status', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'status': 'ok', 'timestamp': '2026-01-01T00:00:00Z'}),
          200,
        );
      });

      final client = ApiClient(client: mockClient);
      final result = await client.health();

      expect(result['status'], 'ok');
      client.dispose();
    });
  });

  group('ApiClient - Error handling', () {
    test('throws ApiException on 500', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final client = ApiClient(client: mockClient);

      expect(
        () => client.getSettings(),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 500)),
      );
      client.dispose();
    });

    test('throws ApiException on 400', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Bad Request', 400);
      });

      final client = ApiClient(client: mockClient);

      expect(
        () => client.getPlayers(),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 400)),
      );
      client.dispose();
    });

    test('ApiException toString includes status and body', () {
      final exception = ApiException(500, 'Server Error');
      expect(exception.toString(), contains('500'));
      expect(exception.toString(), contains('Server Error'));
    });
  });
}
