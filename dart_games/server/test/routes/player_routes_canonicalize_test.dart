/// Tests for the server-side image canonicalization that runs as part
/// of POST /api/v1/players/<id>/photo.
///
/// Every uploaded photo — regardless of input dimensions or format — must
/// end up on disk as a 512x512 JPEG. The route also normalizes the stored
/// file extension to .jpg so subsequent reads (GET /photo) hit the right
/// path.
library;

import 'dart:convert';
import 'dart:io';

import 'package:dart_games_server/database/database.dart';
import 'package:dart_games_server/routes/player_routes.dart';
import 'package:dart_games_server/services/face_landmarks_service.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

Request _jsonRequest(String method, String path, Object body) {
  return Request(
    method,
    Uri.parse('http://localhost$path'),
    body: body is String ? body : jsonEncode(body),
    headers: {'content-type': 'application/json'},
  );
}

/// Build a base64-encoded PNG of the given dimensions filled with a single
/// solid color. We use a distinct color per test so we can also verify
/// pixel content survives canonicalization roundtripping.
String _solidPngBase64(int w, int h, {int r = 200, int g = 100, int b = 50}) {
  final image = img.Image(width: w, height: h);
  img.fill(image, color: img.ColorRgb8(r, g, b));
  final bytes = img.encodePng(image);
  return base64Encode(bytes);
}

void main() {
  late Database database;
  late Handler handler;
  late String dataDir;

  setUp(() {
    database = Database(':memory:');
    dataDir = Directory.systemTemp.createTempSync('player_canon_').path;
    final routes = PlayerRoutes(dataDir, database.rawDb);
    handler = routes.router.call;
    // Block mediapipe from running so it doesn't tamper with the file we
    // want to inspect.
    FaceLandmarksService.instance
        .overridePythonForTesting('/nonexistent/python');
  });

  tearDown(() {
    database.close();
    FaceLandmarksService.instance.resetForTesting();
    final dir = Directory(dataDir);
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  const playerId = 'canon-player-001';

  Future<void> _createPlayer() async {
    await handler(_jsonRequest('POST', '/', {
      'id': playerId,
      'name': 'CanonAlice',
      'createdAt': '2026-05-01T00:00:00.000Z',
    }));
  }

  Future<File> _waitForCanonicalFile() async {
    // Upload writes synchronously inside the handler, so the file should
    // exist as soon as the response returns.
    final file = File(p.join(dataDir, 'photos', '$playerId.jpg'));
    expect(file.existsSync(), isTrue,
        reason: 'canonicalized photo must be written to <dataDir>/photos/<id>.jpg');
    return file;
  }

  group('POST /<id>/photo canonicalization', () {
    test('square input is resized to 512x512 JPEG', () async {
      await _createPlayer();

      // 600x600 square -> should be resized down to 512x512 without crop.
      final response = await handler(_jsonRequest('POST', '/$playerId/photo', {
        'photoData': _solidPngBase64(600, 600),
        'fileName': 'avatar.png',
      }));
      expect(response.statusCode, 200);

      final file = await _waitForCanonicalFile();
      final decoded = img.decodeImage(file.readAsBytesSync());
      expect(decoded, isNotNull);
      expect(decoded!.width, 512);
      expect(decoded.height, 512);
    });

    test('landscape input is center-cropped to square then resized to 512x512',
        () async {
      await _createPlayer();

      // 1200x800 landscape -> crop 800x800 from the center -> 512x512.
      final response = await handler(_jsonRequest('POST', '/$playerId/photo', {
        'photoData': _solidPngBase64(1200, 800),
        'fileName': 'avatar.png',
      }));
      expect(response.statusCode, 200);

      final file = await _waitForCanonicalFile();
      final decoded = img.decodeImage(file.readAsBytesSync());
      expect(decoded!.width, 512);
      expect(decoded.height, 512);
    });

    test('portrait input is center-cropped to square then resized to 512x512',
        () async {
      await _createPlayer();

      // 600x900 portrait -> crop 600x600 from the center -> 512x512.
      final response = await handler(_jsonRequest('POST', '/$playerId/photo', {
        'photoData': _solidPngBase64(600, 900),
        'fileName': 'avatar.png',
      }));
      expect(response.statusCode, 200);

      final file = await _waitForCanonicalFile();
      final decoded = img.decodeImage(file.readAsBytesSync());
      expect(decoded!.width, 512);
      expect(decoded.height, 512);
    });

    test('photoPath in DB always uses .jpg extension', () async {
      await _createPlayer();

      // Even a .png upload should land at <id>.jpg on disk and in the row.
      await handler(_jsonRequest('POST', '/$playerId/photo', {
        'photoData': _solidPngBase64(400, 400),
        'fileName': 'avatar.png',
      }));

      final rows = database.rawDb.select(
        'SELECT photo_path FROM players WHERE id = ?;',
        [playerId],
      );
      final storedPath = rows.first['photo_path'] as String;
      expect(storedPath, endsWith('.jpg'),
          reason: 'canonicalized files are JPEG regardless of input type');
    });
  });
}
