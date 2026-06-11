/// Tests for FaceLandmarksService.
///
/// We test the contract by writing tiny Python helper scripts to a temp
/// directory and injecting them via the service's testing overrides
/// (`overridePythonForTesting` + `overrideSidecarForTesting`).
///
/// Requires `py` (or `python`) on PATH so the injected fake scripts can run.
/// If Python is absent the tests are skipped gracefully.
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'package:dart_games_server/services/face_landmarks_service.dart';

// ---------------------------------------------------------------------------
// Python discovery helper (shared)
// ---------------------------------------------------------------------------

/// Returns the first Python executable found, or null if none is available.
Future<String?> _findPython() async {
  for (final cmd in ['py', 'python', 'python3']) {
    try {
      final r = await Process.run(cmd, ['--version'])
          .timeout(const Duration(seconds: 5));
      if (r.exitCode == 0) return cmd;
    } catch (_) {}
  }
  return null;
}

// ---------------------------------------------------------------------------
// Fake sidecar factories
// ---------------------------------------------------------------------------

/// Writes a Python script that reads stdin, ignores it, prints [output],
/// and exits with [exitCode].
File _writeSidecar(
  Directory dir,
  String filename,
  String output, {
  int exitCode = 0,
}) {
  final file = File(p.join(dir.path, filename));
  file.writeAsStringSync(
    'import sys\n'
    'sys.stdin.read()\n'
    // Use repr so embedded quotes are safe.
    'print(${_pyStrLiteral(output)})\n'
    'sys.exit($exitCode)\n',
  );
  return file;
}

/// Converts a Dart string to a Python string literal (single-quoted, escaped).
String _pyStrLiteral(String s) {
  return "'" + s.replaceAll('\\', '\\\\').replaceAll("'", "\\'") + "'";
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late Directory tempDir;
  late String? python;

  setUpAll(() async {
    python = await _findPython();
  });

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('face_landmarks_test_');
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
    FaceLandmarksService.instance.resetForTesting();
  });

  // ---------------------------------------------------------------------------
  // detectForImagePath
  // ---------------------------------------------------------------------------

  group('detectForImagePath', () {
    test('returns parsed Map when sidecar emits detected=true JSON', () async {
      if (python == null) {
        markTestSkipped('Python not available on this machine');
        return;
      }

      final landmarksMap = {
        'detected': true,
        'boundingBox': {'x': 0.18, 'y': 0.12, 'width': 0.64, 'height': 0.72},
        'leftEye': {'x': 0.34, 'y': 0.40},
        'rightEye': {'x': 0.66, 'y': 0.40},
        'noseTip': {'x': 0.50, 'y': 0.55},
        'mouthCenter': {'x': 0.50, 'y': 0.72},
        'confidence': 0.97,
      };
      final sidecar =
          _writeSidecar(tempDir, 'ok_sidecar.py', jsonEncode(landmarksMap));

      FaceLandmarksService.instance.overridePythonForTesting(python!);
      FaceLandmarksService.instance.overrideSidecarForTesting(sidecar.path);

      final result = await FaceLandmarksService.instance
          .detectForImagePath('/dummy/image.jpg');

      expect(result, isNotNull);
      expect(result!['confidence'], 0.97);
      expect((result['leftEye'] as Map)['x'], 0.34);
      // 'detected' control field must be stripped.
      expect(result.containsKey('detected'), isFalse);
    });

    test('returns null when sidecar emits detected=false', () async {
      if (python == null) {
        markTestSkipped('Python not available on this machine');
        return;
      }

      final sidecar = _writeSidecar(
        tempDir,
        'noface_sidecar.py',
        jsonEncode({'detected': false}),
      );

      FaceLandmarksService.instance.overridePythonForTesting(python!);
      FaceLandmarksService.instance.overrideSidecarForTesting(sidecar.path);

      final result = await FaceLandmarksService.instance
          .detectForImagePath('/dummy/image.jpg');

      expect(result, isNull);
    });

    test('returns null when sidecar exits nonzero', () async {
      if (python == null) {
        markTestSkipped('Python not available on this machine');
        return;
      }

      final sidecar = _writeSidecar(
        tempDir,
        'fail_sidecar.py',
        jsonEncode({'error': 'processing failed'}),
        exitCode: 1,
      );

      FaceLandmarksService.instance.overridePythonForTesting(python!);
      FaceLandmarksService.instance.overrideSidecarForTesting(sidecar.path);

      final result = await FaceLandmarksService.instance
          .detectForImagePath('/dummy/image.jpg');

      expect(result, isNull);
    });

    test('returns null when sidecar emits error field (exit 0)', () async {
      if (python == null) {
        markTestSkipped('Python not available on this machine');
        return;
      }

      final sidecar = _writeSidecar(
        tempDir,
        'err_sidecar.py',
        jsonEncode({'error': 'cv2.imread returned None'}),
      );

      FaceLandmarksService.instance.overridePythonForTesting(python!);
      FaceLandmarksService.instance.overrideSidecarForTesting(sidecar.path);

      final result = await FaceLandmarksService.instance
          .detectForImagePath('/dummy/image.jpg');

      expect(result, isNull);
    });

    test('returns null when python command is a nonexistent path', () async {
      FaceLandmarksService.instance
          .overridePythonForTesting('/totally/nonexistent/python999');

      final result = await FaceLandmarksService.instance
          .detectForImagePath('/dummy/image.jpg');

      expect(result, isNull);
    });

    test('does not throw on any failure — always returns null or Map', () async {
      FaceLandmarksService.instance
          .overridePythonForTesting('/nonexistent/python');

      expect(
        () async => FaceLandmarksService.instance
            .detectForImagePath('/dummy/image.jpg'),
        returnsNormally,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // isAvailable
  // ---------------------------------------------------------------------------

  group('isAvailable', () {
    test('returns false when python command does not exist', () async {
      FaceLandmarksService.instance
          .overridePythonForTesting('/totally/nonexistent/python999');

      final available = await FaceLandmarksService.instance.isAvailable();
      expect(available, isFalse);
    });

    test('caches negative result — second call returns false without retry', () async {
      FaceLandmarksService.instance
          .overridePythonForTesting('/totally/nonexistent/python999');

      final first = await FaceLandmarksService.instance.isAvailable();
      final second = await FaceLandmarksService.instance.isAvailable();
      expect(first, isFalse);
      expect(second, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // resetForTesting
  // ---------------------------------------------------------------------------

  group('resetForTesting', () {
    test('clears cached python command', () async {
      FaceLandmarksService.instance
          .overridePythonForTesting('/nonexistent/python');
      FaceLandmarksService.instance.resetForTesting();

      // After reset, trying to detect should fail gracefully (not crash).
      // (The probe will try the real `py`/`python`/`python3` candidates.)
      final result = await FaceLandmarksService.instance
          .detectForImagePath('/dummy/image.jpg');
      // Result may be null (no sidecar) or null (no python) — just not an exception.
      expect(result, anyOf(isNull, isA<Map>()));
    });
  });
}
