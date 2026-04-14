import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:dart_games/services/api/api_client.dart';
import 'package:dart_games/services/api/api_config.dart';

/// In-memory mock server that simulates the Dart Games backend API.
///
/// Use [createMockApiClient] to get an ApiClient wired to this mock.
/// All data is stored in memory and isolated per instance.
class MockApiServer {
  final Map<String, String> settings = {};
  final List<Map<String, dynamic>> players = [];
  final List<Map<String, dynamic>> gameHistory = [];
  final List<Map<String, dynamic>> savedGames = [];
  final List<Map<String, dynamic>> musicFiles = [];
  Map<String, dynamic> dartboard = {
    'name': null,
    'serialNumber': null,
    'apiKey': null,
    'useEmulator': false,
  };
  final List<Map<String, dynamic>> dartboardProfiles = [];

  late final MockClient mockClient;
  late final ApiClient apiClient;

  MockApiServer() {
    ApiConfig.configure('http://localhost:8080');
    mockClient = MockClient(_handleRequest);
    apiClient = ApiClient(client: mockClient);
  }

  Future<http.Response> _handleRequest(http.Request request) async {
    final path = request.url.path;
    final method = request.method;

    // Settings routes
    if (path == '/api/v1/settings') {
      if (method == 'GET') {
        return _jsonResponse(settings);
      }
      if (method == 'PUT') {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        for (final entry in body.entries) {
          settings[entry.key] = entry.value as String;
        }
        return _jsonResponse(body);
      }
    }

    final settingsMatch = RegExp(r'^/api/v1/settings/(.+)$').firstMatch(path);
    if (settingsMatch != null) {
      final key = settingsMatch.group(1)!;
      if (method == 'GET') {
        if (settings.containsKey(key)) {
          return _jsonResponse({'key': key, 'value': settings[key]});
        }
        return http.Response(jsonEncode({'error': 'not found'}), 404);
      }
      if (method == 'PUT') {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        settings[key] = body['value'] as String;
        return _jsonResponse({'key': key, 'value': settings[key]});
      }
      if (method == 'DELETE') {
        settings.remove(key);
        return http.Response('', 204);
      }
    }

    // Dartboard routes
    if (path == '/api/v1/dartboard') {
      if (method == 'GET') return _jsonResponse(dartboard);
      if (method == 'PUT') {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        dartboard = {
          'name': body['name'],
          'serialNumber': body['serialNumber'],
          'apiKey': body['apiKey'],
          'useEmulator': body['useEmulator'] ?? false,
        };
        return _jsonResponse(dartboard);
      }
      if (method == 'DELETE') {
        dartboard = {'name': null, 'serialNumber': null, 'apiKey': null, 'useEmulator': false};
        return http.Response('', 204);
      }
    }

    if (path == '/api/v1/dartboard/profiles') {
      if (method == 'GET') {
        final sorted = List<Map<String, dynamic>>.from(dartboardProfiles);
        sorted.sort((a, b) => (b['lastUsed'] as String).compareTo(a['lastUsed'] as String));
        return _jsonResponse(sorted);
      }
    }

    final profileMatch = RegExp(r'^/api/v1/dartboard/profiles/(.+)$').firstMatch(path);
    if (profileMatch != null) {
      final sn = profileMatch.group(1)!;
      if (method == 'PUT') {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        dartboardProfiles.removeWhere((p) => p['serialNumber'] == sn);
        dartboardProfiles.add({
          'serialNumber': sn,
          'name': body['name'],
          'apiKey': body['apiKey'],
          'lastUsed': body['lastUsed'],
        });
        return _jsonResponse(dartboardProfiles.last);
      }
      if (method == 'DELETE') {
        dartboardProfiles.removeWhere((p) => p['serialNumber'] == sn);
        return http.Response('', 204);
      }
    }

    // Player routes
    if (path == '/api/v1/players') {
      if (method == 'GET') {
        final result = players.map((p) {
          final history = gameHistory.where((h) => h['playerId'] == p['id']).toList();
          return {...p, 'gameHistory': history};
        }).toList();
        return _jsonResponse(result);
      }
      if (method == 'POST') {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        final player = {
          'id': body['id'],
          'name': body['name'],
          'photoPath': body['photoPath'],
          'createdAt': body['createdAt'],
          'gamesPlayed': body['gamesPlayed'] ?? 0,
          'gamesWon': body['gamesWon'] ?? 0,
        };
        players.add(player);
        final history = gameHistory.where((h) => h['playerId'] == player['id']).toList();
        return http.Response(
          jsonEncode({...player, 'gameHistory': history}),
          201,
          headers: {'content-type': 'application/json'},
        );
      }
    }

    // Player-specific routes
    final playerStatsMatch = RegExp(r'^/api/v1/players/([^/]+)/stats$').firstMatch(path);
    if (playerStatsMatch != null && method == 'PUT') {
      final id = playerStatsMatch.group(1)!;
      final idx = players.indexWhere((p) => p['id'] == id);
      if (idx < 0) return http.Response('', 404);
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      players[idx]['gamesPlayed'] = body['gamesPlayed'];
      players[idx]['gamesWon'] = body['gamesWon'];
      return _jsonResponse(players[idx]);
    }

    final playerHistoryMatch = RegExp(r'^/api/v1/players/([^/]+)/history$').firstMatch(path);
    if (playerHistoryMatch != null && method == 'POST') {
      final id = playerHistoryMatch.group(1)!;
      final idx = players.indexWhere((p) => p['id'] == id);
      if (idx < 0) return http.Response('', 404);
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      final entry = {
        'id': 'hist-${gameHistory.length}',
        'playerId': id,
        ...body,
      };
      gameHistory.add(entry);
      // Increment games_played, games_won if applicable
      players[idx]['gamesPlayed'] = (players[idx]['gamesPlayed'] as int) + 1;
      final metadata = body['metadata'] as Map<String, dynamic>?;
      if (metadata != null && metadata['won'] == true) {
        players[idx]['gamesWon'] = (players[idx]['gamesWon'] as int) + 1;
      }
      return http.Response(jsonEncode(entry), 201, headers: {'content-type': 'application/json'});
    }

    final playerPhotoMatch = RegExp(r'^/api/v1/players/([^/]+)/photo$').firstMatch(path);
    if (playerPhotoMatch != null) {
      final id = playerPhotoMatch.group(1)!;
      if (method == 'POST') {
        final idx = players.indexWhere((p) => p['id'] == id);
        if (idx < 0) return http.Response('', 404);
        players[idx]['photoPath'] = '/photos/$id.jpg';
        return _jsonResponse({'photoPath': '/photos/$id.jpg'});
      }
      if (method == 'GET') {
        return http.Response('', 404);
      }
      if (method == 'DELETE') {
        final idx = players.indexWhere((p) => p['id'] == id);
        if (idx >= 0) players[idx]['photoPath'] = null;
        return http.Response('', 204);
      }
    }

    final playerMatch = RegExp(r'^/api/v1/players/([^/]+)$').firstMatch(path);
    if (playerMatch != null) {
      final id = playerMatch.group(1)!;
      if (method == 'GET') {
        final idx = players.indexWhere((p) => p['id'] == id);
        if (idx < 0) return http.Response(jsonEncode({'error': 'not found'}), 404);
        final history = gameHistory.where((h) => h['playerId'] == id).toList();
        return _jsonResponse({...players[idx], 'gameHistory': history});
      }
      if (method == 'PUT') {
        final idx = players.indexWhere((p) => p['id'] == id);
        if (idx < 0) return http.Response('', 404);
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        if (body.containsKey('name')) players[idx]['name'] = body['name'];
        final history = gameHistory.where((h) => h['playerId'] == id).toList();
        return _jsonResponse({...players[idx], 'gameHistory': history});
      }
      if (method == 'DELETE') {
        players.removeWhere((p) => p['id'] == id);
        gameHistory.removeWhere((h) => h['playerId'] == id);
        return http.Response('', 204);
      }
    }

    // Saved games routes
    if (path == '/api/v1/games') {
      if (method == 'GET') return _jsonResponse(savedGames);
      if (method == 'POST') {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        savedGames.removeWhere((g) => g['id'] == body['id']);
        savedGames.add(body);
        return _jsonResponse(body);
      }
    }

    final gamesTypeDeleteMatch = RegExp(r'^/api/v1/games/type/(.+)$').firstMatch(path);
    if (gamesTypeDeleteMatch != null && method == 'DELETE') {
      final gameType = gamesTypeDeleteMatch.group(1)!;
      savedGames.removeWhere((g) => g['gameType'] == gameType);
      return http.Response('', 204);
    }

    final gamesMatch = RegExp(r'^/api/v1/games/(.+)$').firstMatch(path);
    if (gamesMatch != null) {
      final idOrType = gamesMatch.group(1)!;
      if (method == 'GET') {
        // Filter by gameType
        final filtered = savedGames.where((g) => g['gameType'] == idOrType).toList();
        return _jsonResponse(filtered);
      }
      if (method == 'DELETE') {
        savedGames.removeWhere((g) => g['id'] == idOrType);
        return http.Response('', 204);
      }
    }

    // Music routes
    if (path == '/api/v1/music') {
      if (method == 'GET') return _jsonResponse(musicFiles);
      if (method == 'POST') {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        final id = 'music-${musicFiles.length}';
        final entry = {
          'id': id,
          'fileName': body['fileName'],
          'filePath': '/music/$id.mp3',
          'isCurrent': false,
          'createdAt': DateTime.now().toUtc().toIso8601String(),
        };
        musicFiles.add(entry);
        return http.Response(jsonEncode(entry), 201, headers: {'content-type': 'application/json'});
      }
      if (method == 'DELETE') {
        musicFiles.clear();
        return http.Response('', 204);
      }
    }

    if (path == '/api/v1/music/current') {
      if (method == 'GET') {
        final current = musicFiles.where((m) => m['isCurrent'] == true).toList();
        if (current.isEmpty) return http.Response(jsonEncode({'error': 'none'}), 404);
        return _jsonResponse(current.first);
      }
    }

    final musicCurrentMatch = RegExp(r'^/api/v1/music/([^/]+)/current$').firstMatch(path);
    if (musicCurrentMatch != null && method == 'PUT') {
      final id = musicCurrentMatch.group(1)!;
      for (final m in musicFiles) {
        m['isCurrent'] = m['id'] == id;
      }
      return _jsonResponse({});
    }

    final musicFileMatch = RegExp(r'^/api/v1/music/([^/]+)/file$').firstMatch(path);
    if (musicFileMatch != null && method == 'GET') {
      return http.Response.bytes([0, 1, 2], 200, headers: {'content-type': 'audio/mpeg'});
    }

    final musicMatch = RegExp(r'^/api/v1/music/([^/]+)$').firstMatch(path);
    if (musicMatch != null && method == 'DELETE') {
      final id = musicMatch.group(1)!;
      musicFiles.removeWhere((m) => m['id'] == id);
      return http.Response('', 204);
    }

    // Health
    if (path == '/api/v1/health') {
      return _jsonResponse({'status': 'ok', 'timestamp': DateTime.now().toUtc().toIso8601String()});
    }

    // Fallback
    return http.Response('Not found', 404);
  }

  http.Response _jsonResponse(Object data) {
    return http.Response(
      jsonEncode(data),
      200,
      headers: {'content-type': 'application/json'},
    );
  }
}

/// Creates a mock API server and returns the ApiClient for use in tests.
///
/// Usage:
/// ```dart
/// late MockApiServer mockServer;
/// late ApiClient apiClient;
///
/// setUp(() {
///   mockServer = MockApiServer();
///   apiClient = mockServer.apiClient;
/// });
/// ```
MockApiServer createMockApiServer() => MockApiServer();
