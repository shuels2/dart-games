/// Tests for face-landmarks integration in player photo upload routes.
///
/// Verifies:
/// - POST /<id>/photo runs face detection SYNCHRONOUSLY (waits for the
///   sidecar) and echoes the fresh landmarks in the response body.
/// - When detection fails, the response body carries a
///   `faceLandmarksError` reason string, the photo is still saved,
///   and the DB `face_landmarks` column stays null.
/// - `detectLandmarks: false` opt-out skips detection entirely — the
///   response has neither `faceLandmarks` nor `faceLandmarksError`,
///   and no detection process is spawned.
/// - GET /<id> returns faceLandmarks as a nested JSON object (not a string).
/// - GET /  returns faceLandmarks as a nested JSON object for all players.
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

/// Best-effort probe for a real Python interpreter. Returns null when no
/// candidate resolves — the caller should `markTestSkipped` in that case
/// so tests that legitimately need a sidecar process don't fail on CI
/// runners without Python.
Future<String?> _resolvePythonOrSkip() async {
  for (final cmd in ['py', 'python', 'python3']) {
    try {
      final r = await Process.run(cmd, ['--version'])
          .timeout(const Duration(seconds: 3));
      if (r.exitCode == 0) return cmd;
    } catch (_) {}
  }
  return null;
}

/// Write a fake sidecar script that emits [payload] on stdout and exits 0.
File _writeFakeSidecar(String dir, Map<String, dynamic> payload) {
  final sidecarDir = Directory(dir);
  sidecarDir.createSync(recursive: true);
  final sidecarFile = File(p.join(sidecarDir.path, 'fake_sidecar.py'));
  final escapedJson = jsonEncode(payload)
      .replaceAll('\\', '\\\\')
      .replaceAll("'", "\\'");
  sidecarFile.writeAsStringSync(
    'import sys\n'
    'sys.stdin.read()\n'
    "print('$escapedJson')\n"
    'sys.exit(0)\n',
  );
  return sidecarFile;
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
  // Synchronous detection — success path
  // ---------------------------------------------------------------------------

  group('POST /<id>/photo — synchronous detection success', () {
    test(
        'response carries the fresh landmarks AND the DB row is updated',
        () async {
      final python = await _resolvePythonOrSkip();
      if (python == null) {
        markTestSkipped('Python not available — skipping sync-detection test');
        return;
      }

      await _createPlayer();

      // Fake sidecar returns a known landmarks payload.
      final landmarks = {
        'detected': true,
        'boundingBox': {'x': 0.20, 'y': 0.15, 'width': 0.60, 'height': 0.70},
        'leftEye': {'x': 0.35, 'y': 0.42},
        'rightEye': {'x': 0.65, 'y': 0.42},
        'noseTip': {'x': 0.50, 'y': 0.57},
        'mouthCenter': {'x': 0.50, 'y': 0.73},
        'confidence': 1.0,
      };
      final sidecarFile =
          _writeFakeSidecar(p.join(dataDir, 'fake_py'), landmarks);
      FaceLandmarksService.instance.overridePythonForTesting(python);
      FaceLandmarksService.instance.overrideSidecarForTesting(sidecarFile.path);

      final response = await handler(_jsonRequest(
        'POST',
        '/$playerId/photo',
        {'photoData': _tinyPng, 'fileName': 'avatar.jpg'},
      ));
      expect(response.statusCode, 200);

      final body = await _readJson(response) as Map<String, dynamic>;
      expect(body['photoPath'], contains('/photo'));
      // Response includes fresh landmarks — no follow-up GET needed.
      expect(body.containsKey('faceLandmarks'), isTrue,
          reason: 'synchronous detection must echo landmarks on success');
      expect(body['faceLandmarksError'], isNull);
      final echoed = body['faceLandmarks'] as Map<String, dynamic>;
      // 'detected' is a control field and should have been stripped.
      expect(echoed.containsKey('detected'), isFalse);
      expect((echoed['leftEye'] as Map)['x'], 0.35);
      expect(echoed['confidence'], 1.0);

      // DB row was also updated with the same landmarks.
      final rows = database.rawDb.select(
        'SELECT face_landmarks FROM players WHERE id = ?;',
        [playerId],
      );
      final storedJson = rows.first['face_landmarks'] as String?;
      expect(storedJson, isNotNull,
          reason: 'face_landmarks column must be written synchronously');
      final storedMap = jsonDecode(storedJson!) as Map<String, dynamic>;
      expect((storedMap['leftEye'] as Map)['x'], 0.35);
      expect(storedMap['confidence'], 1.0);
    });
  });

  // ---------------------------------------------------------------------------
  // Synchronous detection — failure path
  // ---------------------------------------------------------------------------

  group('POST /<id>/photo — synchronous detection failures', () {
    test(
        'python-cannot-launch: response carries faceLandmarksError, '
        'DB row stays null, photo file is still saved', () async {
      await _createPlayer();

      // Point python at a nonexistent path so Process.start fails when
      // the service tries to spawn the sidecar. The exact error tag
      // depends on whether the failure surfaces as a ProcessException
      // (unexpected-error) or a startup timeout — both are treated as
      // detection failures and the important contract is: response
      // exposes a non-null `faceLandmarksError`, photo is still saved,
      // DB face_landmarks column stays null.
      FaceLandmarksService.instance
          .overridePythonForTesting('/nonexistent/python');

      final response = await handler(_jsonRequest(
        'POST',
        '/$playerId/photo',
        {'photoData': _tinyPng, 'fileName': 'avatar.jpg'},
      ));

      expect(response.statusCode, 200,
          reason: 'detection failure must not roll back the photo upload');
      final body = await _readJson(response) as Map<String, dynamic>;
      expect(body['photoPath'], contains('/photo'));
      expect(body.containsKey('faceLandmarks'), isFalse,
          reason: 'no landmarks on failure');
      expect(body['faceLandmarksError'], isNotNull);
      final err = body['faceLandmarksError'] as String;
      expect(err, isNotEmpty,
          reason: 'errorReason must be a real, non-empty string');
      // Sanity check: err starts with one of the known reason tags
      // documented in FaceLandmarksService.detectDetailed.
      final knownPrefixes = [
        'python-not-found',
        'sidecar-not-found',
        'sidecar-exit-',
        'sidecar-empty-output',
        'sidecar-error',
        'no-face-detected',
        'timeout',
        'unexpected-error',
      ];
      expect(knownPrefixes.any(err.startsWith), isTrue,
          reason:
              'errorReason must be one of the documented sidecar tags, got: $err');

      // Photo file still exists on disk.
      final photoFile = File(p.join(dataDir, 'photos', '$playerId.jpg'));
      expect(photoFile.existsSync(), isTrue,
          reason: 'photo file must be saved even when detection fails');

      // DB row: photo_path is set, face_landmarks is still null.
      final rows = database.rawDb.select(
        'SELECT photo_path, face_landmarks FROM players WHERE id = ?;',
        [playerId],
      );
      expect(rows.first['photo_path'], isNotNull);
      expect(rows.first['face_landmarks'], isNull,
          reason: 'failed detection must not touch the face_landmarks column');
    });

    test(
        'no-face-detected: sidecar returned {detected:false}; response '
        'carries faceLandmarksError, DB row stays null', () async {
      final python = await _resolvePythonOrSkip();
      if (python == null) {
        markTestSkipped('Python not available — skipping no-face-detected test');
        return;
      }

      await _createPlayer();

      // Fake sidecar returns detected:false.
      final sidecarFile = _writeFakeSidecar(
          p.join(dataDir, 'fake_py'), {'detected': false});
      FaceLandmarksService.instance.overridePythonForTesting(python);
      FaceLandmarksService.instance.overrideSidecarForTesting(sidecarFile.path);

      final response = await handler(_jsonRequest(
        'POST',
        '/$playerId/photo',
        {'photoData': _tinyPng, 'fileName': 'avatar.jpg'},
      ));

      expect(response.statusCode, 200);
      final body = await _readJson(response) as Map<String, dynamic>;
      expect(body.containsKey('faceLandmarks'), isFalse);
      expect(body['faceLandmarksError'], startsWith('no-face-detected'));

      final rows = database.rawDb.select(
        'SELECT face_landmarks FROM players WHERE id = ?;',
        [playerId],
      );
      expect(rows.first['face_landmarks'], isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // Opt-out — `detectLandmarks: false`
  // ---------------------------------------------------------------------------

  group('POST /<id>/photo — detectLandmarks:false opt-out', () {
    test('skips detection entirely; response has neither landmarks '
        'nor error, and DB row stays null', () async {
      await _createPlayer();

      // Point python at a nonexistent path so that IF the endpoint
      // tried to run detection, it would surface an error. The opt-out
      // must short-circuit before that even happens.
      FaceLandmarksService.instance
          .overridePythonForTesting('/nonexistent/python');

      final response = await handler(_jsonRequest(
        'POST',
        '/$playerId/photo',
        {
          'photoData': _tinyPng,
          'fileName': 'avatar.jpg',
          'detectLandmarks': false,
        },
      ));

      expect(response.statusCode, 200);
      final body = await _readJson(response) as Map<String, dynamic>;
      expect(body['photoPath'], contains('/photo'));
      expect(body.containsKey('faceLandmarks'), isFalse);
      expect(body.containsKey('faceLandmarksError'), isFalse,
          reason: 'opt-out must not spawn the sidecar or surface any error');

      final rows = database.rawDb.select(
        'SELECT face_landmarks FROM players WHERE id = ?;',
        [playerId],
      );
      expect(rows.first['face_landmarks'], isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // faceLandmarks field in GET responses (unchanged; kept for coverage)
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

    test('GET returns faceLandmarks as nested object after manual DB update',
        () async {
      await _createPlayer();

      // Simulate what a successful sidecar run stores.
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
  // Diagnostics endpoint — shape + newly-added taskModelFound field
  // ---------------------------------------------------------------------------

  group('GET /face-landmarks/diagnostics', () {
    test('response includes every field the client depends on', () async {
      final response = await handler(
        Request('GET', Uri.parse('http://localhost/face-landmarks/diagnostics')),
      );
      expect(response.statusCode, 200);
      final body = await _readJson(response) as Map<String, dynamic>;

      // Fields the loader preflight ping reads.
      expect(body.containsKey('pythonFound'), isTrue);
      expect(body.containsKey('sidecarFound'), isTrue);
      expect(body.containsKey('mediapipeOk'), isTrue);
      // NEW field: whether the MediaPipe FaceLandmarker task model is
      // present next to the sidecar. Distinguishes "MediaPipe broken"
      // from "Haar fallback active — landmarks less accurate".
      expect(body.containsKey('taskModelFound'), isTrue,
          reason:
              'client relies on this field to warn about a Haar-fallback state');
      expect(body['taskModelFound'], isA<bool>());
      expect(body.containsKey('taskModelPath'), isTrue);

      // Diagnostic context fields (kept for the operator's copy-paste).
      expect(body.containsKey('pythonCommand'), isTrue);
      expect(body.containsKey('sidecarPath'), isTrue);
      expect(body.containsKey('workingDirectory'), isTrue);
      expect(body.containsKey('scriptPath'), isTrue);
      expect(body.containsKey('platform'), isTrue);
    });

    test(
        'taskModelFound reflects whether face_landmarker.task exists '
        'next to the sidecar', () async {
      // Point the service at a temp sidecar that has NO task file next
      // to it — service should report taskModelFound:false.
      final tmp = Directory.systemTemp.createTempSync('diag_test_');
      addTearDown(() => tmp.deleteSync(recursive: true));
      final fakeSidecar = File(p.join(tmp.path, 'mediapipe_sidecar.py'));
      fakeSidecar.writeAsStringSync('# fake sidecar\n');
      FaceLandmarksService.instance
          .overrideSidecarForTesting(fakeSidecar.path);

      final response = await handler(
        Request('GET', Uri.parse('http://localhost/face-landmarks/diagnostics')),
      );
      var body = await _readJson(response) as Map<String, dynamic>;
      expect(body['sidecarFound'], isTrue,
          reason: 'we just wrote the fake sidecar file');
      expect(body['taskModelFound'], isFalse,
          reason: 'no task file was placed next to the fake sidecar');

      // Now drop a fake task file next to the fake sidecar — service
      // should flip taskModelFound to true.
      File(p.join(tmp.path, 'face_landmarker.task'))
          .writeAsStringSync('dummy task blob');
      final response2 = await handler(
        Request('GET', Uri.parse('http://localhost/face-landmarks/diagnostics')),
      );
      body = await _readJson(response2) as Map<String, dynamic>;
      expect(body['taskModelFound'], isTrue,
          reason: 'task file now exists next to the sidecar');
    });
  });

  group('GET / — faceLandmarks in list', () {
    test('GET / includes faceLandmarks field (null) for each player',
        () async {
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
}
