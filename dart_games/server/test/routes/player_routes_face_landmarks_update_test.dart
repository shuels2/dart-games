/// Tests for the manual-edit + redetect face-landmarks endpoints used by
/// the inspector UI in System Settings.
///
///   PATCH /<id>/face-landmarks            — overwrite stored landmarks
///   POST  /<id>/face-landmarks/redetect   — re-run mediapipe on the photo
library;

import 'dart:convert';
import 'dart:io';

import 'package:dart_games_server/database/database.dart';
import 'package:dart_games_server/routes/player_routes.dart';
import 'package:dart_games_server/services/face_landmarks_service.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;

const _tinyPng =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk'
    '+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';

Request _jsonRequest(String method, String path, Object body) {
  return Request(
    method,
    Uri.parse('http://localhost$path'),
    body: body is String ? body : jsonEncode(body),
    headers: {'content-type': 'application/json'},
  );
}

Future<dynamic> _readJson(Response response) async {
  return jsonDecode(await response.readAsString());
}

const _validLandmarks = {
  'boundingBox': {'x': 0.18, 'y': 0.12, 'width': 0.64, 'height': 0.72},
  'leftEye': {'x': 0.34, 'y': 0.40},
  'rightEye': {'x': 0.66, 'y': 0.40},
  'noseTip': {'x': 0.50, 'y': 0.55},
  'mouthCenter': {'x': 0.50, 'y': 0.72},
};

void main() {
  late Database database;
  late Handler handler;
  late String dataDir;

  setUp(() {
    database = Database(':memory:');
    dataDir = Directory.systemTemp.createTempSync('player_fl_upd_').path;
    final routes = PlayerRoutes(dataDir, database.rawDb);
    handler = routes.router.call;
    FaceLandmarksService.instance.resetForTesting();
  });

  tearDown(() {
    database.close();
    FaceLandmarksService.instance.resetForTesting();
    final dir = Directory(dataDir);
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  const playerId = 'fl-upd-player-001';
  Future<void> _createPlayer() async {
    await handler(_jsonRequest('POST', '/', {
      'id': playerId,
      'name': 'EditableEd',
      'createdAt': '2026-05-01T00:00:00.000Z',
    }));
  }

  // ---------------------------------------------------------------------------
  // PATCH /<id>/face-landmarks
  // ---------------------------------------------------------------------------

  group('PATCH /<id>/face-landmarks', () {
    test('writes the full payload and returns it back', () async {
      await _createPlayer();

      final response = await handler(_jsonRequest(
        'PATCH',
        '/$playerId/face-landmarks',
        _validLandmarks,
      ));

      expect(response.statusCode, 200);
      final body = await _readJson(response) as Map<String, dynamic>;
      expect(body['faceLandmarks'], isA<Map>());
      expect((body['faceLandmarks'] as Map)['leftEye'], _validLandmarks['leftEye']);

      // Verify the DB row received the JSON.
      final rows = database.rawDb.select(
        'SELECT face_landmarks FROM players WHERE id = ?;',
        [playerId],
      );
      final stored = rows.first['face_landmarks'] as String?;
      expect(stored, isNotNull);
      final decoded = jsonDecode(stored!) as Map<String, dynamic>;
      expect((decoded['boundingBox'] as Map)['width'], 0.64);
    });

    test('rejects missing landmark key with 400', () async {
      await _createPlayer();

      final partial = Map<String, dynamic>.from(_validLandmarks);
      partial.remove('mouthCenter');

      final response = await handler(_jsonRequest(
        'PATCH',
        '/$playerId/face-landmarks',
        partial,
      ));

      expect(response.statusCode, 400);
      final body = await _readJson(response) as Map<String, dynamic>;
      expect(body['error'], contains('mouthCenter'));
    });

    test('rejects out-of-range coord with 400', () async {
      await _createPlayer();

      final bad = Map<String, dynamic>.from(_validLandmarks);
      bad['noseTip'] = {'x': 1.5, 'y': 0.5};

      final response = await handler(_jsonRequest(
        'PATCH',
        '/$playerId/face-landmarks',
        bad,
      ));

      expect(response.statusCode, 400);
      final body = await _readJson(response) as Map<String, dynamic>;
      expect(body['error'], contains('0..1'));
    });

    test('returns 404 for unknown player id', () async {
      final response = await handler(_jsonRequest(
        'PATCH',
        '/does-not-exist/face-landmarks',
        _validLandmarks,
      ));

      expect(response.statusCode, 404);
    });

    test('rejects non-object JSON body with 400', () async {
      await _createPlayer();

      final response = await handler(_jsonRequest(
        'PATCH',
        '/$playerId/face-landmarks',
        '["not", "an", "object"]',
      ));

      expect(response.statusCode, 400);
    });
  });

  // ---------------------------------------------------------------------------
  // POST /<id>/face-landmarks/redetect
  // ---------------------------------------------------------------------------

  group('POST /<id>/face-landmarks/redetect', () {
    test('returns 404 when player has no photo', () async {
      await _createPlayer();

      final response = await handler(
        Request('POST', Uri.parse('http://localhost/$playerId/face-landmarks/redetect')),
      );

      expect(response.statusCode, 404);
    });

    test('overwrites stored landmarks when sidecar succeeds', () async {
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
        markTestSkipped('Python not available — skipping redetect happy path');
        return;
      }

      await _createPlayer();

      // Upload a photo so the player has a photo_path on disk.
      // Block redetection during upload so we can configure a known result.
      FaceLandmarksService.instance.overridePythonForTesting('/nonexistent');
      await handler(_jsonRequest(
        'POST',
        '/$playerId/photo',
        {'photoData': _tinyPng, 'fileName': 'avatar.jpg'},
      ));

      // Pre-seed stale landmarks so we can prove redetect overwrites.
      database.rawDb.execute(
        "UPDATE players SET face_landmarks = ? WHERE id = ?;",
        [jsonEncode({'stale': true}), playerId],
      );

      // Configure the sidecar to return a known fresh result.
      final fresh = {
        'boundingBox': {'x': 0.10, 'y': 0.10, 'width': 0.80, 'height': 0.80},
        'leftEye': {'x': 0.30, 'y': 0.38},
        'rightEye': {'x': 0.70, 'y': 0.38},
        'noseTip': {'x': 0.50, 'y': 0.55},
        'mouthCenter': {'x': 0.50, 'y': 0.70},
        'confidence': 0.99,
      };
      final sidecarDir = Directory(p.join(dataDir, 'fake_py'))..createSync(recursive: true);
      final sidecarFile = File(p.join(sidecarDir.path, 'fake_sidecar.py'));
      final escapedJson = jsonEncode(fresh)
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

      final response = await handler(
        Request('POST', Uri.parse('http://localhost/$playerId/face-landmarks/redetect')),
      );

      expect(response.statusCode, 200);
      final body = await _readJson(response) as Map<String, dynamic>;
      expect((body['faceLandmarks'] as Map)['confidence'], 0.99);

      final rows = database.rawDb.select(
        'SELECT face_landmarks FROM players WHERE id = ?;',
        [playerId],
      );
      final stored = jsonDecode(rows.first['face_landmarks'] as String)
          as Map<String, dynamic>;
      expect(stored['stale'], isNull, reason: 'stale landmarks should be overwritten');
      expect((stored['leftEye'] as Map)['x'], 0.30);
    });
  });
}
