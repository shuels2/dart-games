/// Tests for face-landmarks integration in player photo upload routes.
///
/// Verifies:
/// - POST /<id>/photo returns 200 immediately (does NOT wait for detection)
/// - GET /<id> returns faceLandmarks as a nested JSON object (not a string)
/// - GET /  returns faceLandmarks as a nested JSON object for all players
/// - When detection succeeds, the row is updated in the background
library;

import 'dart:convert';
import 'dart:io';

import 'package:dart_games_server/database/database.dart';
import 'package:dart_games_server/routes/player_routes.dart';
import 'package:dart_games_server/services/face_landmarks_service.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;

/// A 1x1 transparent PNG encoded as base64.
const _tinyPng =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk'
    '+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';

/// Helper to build a JSON POST/PUT request.
Request _jsonRequest(String method, String path, Map<String, dynamic> body) {
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
    dataDir = Directory.systemTemp.createTempSync('player_fl_test_').path;
    final routes = PlayerRoutes(dataDir, database.rawDb);
    handler = routes.router.call;

    // Ensure the service's cached state is clear between tests.
    FaceLandmarksService.instance.resetForTesting();
  });

  tearDown(() {
    database.close();
    FaceLandmarksService.instance.resetForTesting();
    final dir = Directory(dataDir);
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  const playerId = 'fl-player-001';
  const playerName = 'FaceLandmarkAlice';
  const playerCreatedAt = '2026-05-01T00:00:00.000Z';

  Future<void> _createPlayer() async {
    await handler(_jsonRequest('POST', '/', {
      'id': playerId,
      'name': playerName,
      'createdAt': playerCreatedAt,
    }));
  }

  // ---------------------------------------------------------------------------
  // Photo upload returns immediately (does not wait for detection)
  // ---------------------------------------------------------------------------

  group('POST /<id>/photo — upload timing', () {
    test('returns 200 immediately without waiting for face detection', () async {
      await _createPlayer();

      // Point python at a nonexistent path so detection would hang/fail
      // if the endpoint were waiting for it.
      FaceLandmarksService.instance
          .overridePythonForTesting('/nonexistent/python');

      final stopwatch = Stopwatch()..start();
      final response = await handler(_jsonRequest(
        'POST',
        '/$playerId/photo',
        {'photoData': _tinyPng, 'fileName': 'avatar.jpg'},
      ));
      stopwatch.stop();

      expect(response.statusCode, 200);
      // Upload should complete well under 2 seconds even with no-op detection.
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(2000),
        reason: 'photo upload must return before detection completes',
      );

      final body = await _readJson(response) as Map<String, dynamic>;
      expect(body['photoPath'], contains('/photo'));
    });
  });

  // ---------------------------------------------------------------------------
  // faceLandmarks field in GET responses
  // ---------------------------------------------------------------------------

  group('GET /<id> — faceLandmarks field', () {
    test('newly created player has null faceLandmarks', () async {
      await _createPlayer();

      final response = await handler(
        Request('GET', Uri.parse('http://localhost/$playerId')),
      );

      expect(response.statusCode, 200);
      final body = await _readJson(response) as Map<String, dynamic>;
      expect(body.containsKey('faceLandmarks'), isTrue);
      expect(body['faceLandmarks'], isNull);
    });

    test('GET returns faceLandmarks as nested object after manual DB update', () async {
      await _createPlayer();

      // Simulate what the background sidecar would do: write JSON directly.
      const landmarksMap = {
        'boundingBox': {'x': 0.18, 'y': 0.12, 'width': 0.64, 'height': 0.72},
        'leftEye': {'x': 0.34, 'y': 0.40},
        'rightEye': {'x': 0.66, 'y': 0.40},
        'noseTip': {'x': 0.50, 'y': 0.55},
        'mouthCenter': {'x': 0.50, 'y': 0.72},
        'confidence': 0.97,
      };
      database.rawDb.execute(
        'UPDATE players SET face_landmarks = ? WHERE id = ?;',
        [jsonEncode(landmarksMap), playerId],
      );

      final response = await handler(
        Request('GET', Uri.parse('http://localhost/$playerId')),
      );

      expect(response.statusCode, 200);
      final body = await _readJson(response) as Map<String, dynamic>;

      // faceLandmarks must be a nested Map, NOT a JSON-encoded string.
      expect(body['faceLandmarks'], isA<Map>());
      final lm = body['faceLandmarks'] as Map<String, dynamic>;
      expect(lm['confidence'], 0.97);
      expect((lm['leftEye'] as Map)['x'], 0.34);
      expect((lm['boundingBox'] as Map)['width'], 0.64);
    });
  });

  // ---------------------------------------------------------------------------
  // GET / returns faceLandmarks for all players
  // ---------------------------------------------------------------------------

  group('GET / — faceLandmarks in list', () {
    test('GET / includes faceLandmarks field (null) for each player', () async {
      await _createPlayer();

      final response = await handler(
        Request('GET', Uri.parse('http://localhost/')),
      );

      expect(response.statusCode, 200);
      final body = await _readJson(response) as List;
      expect(body, hasLength(1));
      final player = body[0] as Map<String, dynamic>;
      expect(player.containsKey('faceLandmarks'), isTrue);
      expect(player['faceLandmarks'], isNull);
    });

    test('GET / returns faceLandmarks as nested object when set', () async {
      await _createPlayer();

      const landmarksMap = {
        'boundingBox': {'x': 0.10, 'y': 0.10, 'width': 0.80, 'height': 0.80},
        'leftEye': {'x': 0.30, 'y': 0.38},
        'rightEye': {'x': 0.70, 'y': 0.38},
        'noseTip': {'x': 0.50, 'y': 0.55},
        'mouthCenter': {'x': 0.50, 'y': 0.70},
        'confidence': 0.95,
      };
      database.rawDb.execute(
        'UPDATE players SET face_landmarks = ? WHERE id = ?;',
        [jsonEncode(landmarksMap), playerId],
      );

      final response = await handler(
        Request('GET', Uri.parse('http://localhost/')),
      );

      expect(response.statusCode, 200);
      final body = await _readJson(response) as List;
      final player = body[0] as Map<String, dynamic>;
      expect(player['faceLandmarks'], isA<Map>());
      expect((player['faceLandmarks'] as Map)['confidence'], 0.95);
    });
  });

  // ---------------------------------------------------------------------------
  // Background update path (with real py + fake sidecar)
  // ---------------------------------------------------------------------------

  group('POST /<id>/photo — background landmark detection', () {
    test('face_landmarks row is updated after detection completes', () async {
      // Only run if Python is available.
      String? python;
      for (final cmd in ['py', 'python', 'python3']) {
        try {
          final r = await Process.run(cmd, ['--version'])
              .timeout(const Duration(seconds: 3));
          if (r.exitCode == 0) {
            python = cmd;
            break;
          }
        } catch (_) {}
      }

      if (python == null) {
        markTestSkipped('Python not available — skipping background update test');
        return;
      }

      await _createPlayer();

      // Write a fake sidecar that returns a known landmarks JSON.
      final sidecarDir = Directory(p.join(dataDir, 'fake_py'));
      sidecarDir.createSync(recursive: true);
      final landmarks = {
        'detected': true,
        'boundingBox': {'x': 0.20, 'y': 0.15, 'width': 0.60, 'height': 0.70},
        'leftEye': {'x': 0.35, 'y': 0.42},
        'rightEye': {'x': 0.65, 'y': 0.42},
        'noseTip': {'x': 0.50, 'y': 0.57},
        'mouthCenter': {'x': 0.50, 'y': 0.73},
        'confidence': 1.0,
      };
      final sidecarFile = File(p.join(sidecarDir.path, 'fake_sidecar.py'));
      final escapedJson = jsonEncode(landmarks)
          .replaceAll('\\', '\\\\')
          .replaceAll("'", "\\'");
      sidecarFile.writeAsStringSync(
        'import sys\n'
        'sys.stdin.read()\n'
        "print('$escapedJson')\n"
        'sys.exit(0)\n',
      );

      FaceLandmarksService.instance.overridePythonForTesting(python);
      FaceLandmarksService.instance.overrideSidecarForTesting(sidecarFile.path);

      // Upload the photo (triggers unawaited background detection).
      final uploadResponse = await handler(_jsonRequest(
        'POST',
        '/$playerId/photo',
        {'photoData': _tinyPng, 'fileName': 'avatar.jpg'},
      ));
      expect(uploadResponse.statusCode, 200);

      // Wait for the background task to complete (it runs in a Future).
      await Future.delayed(const Duration(milliseconds: 500));

      // Query the DB directly to check the landmarks were written.
      final rows = database.rawDb.select(
        'SELECT face_landmarks FROM players WHERE id = ?;',
        [playerId],
      );
      final storedJson = rows.first['face_landmarks'] as String?;
      expect(storedJson, isNotNull,
          reason: 'face_landmarks should be written after background detection');

      final storedMap = jsonDecode(storedJson!) as Map<String, dynamic>;
      expect((storedMap['leftEye'] as Map)['x'], 0.35);
      expect(storedMap['confidence'], 1.0);
    });
  });
}
