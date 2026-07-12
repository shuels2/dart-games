/// Unit tests for the test-headshot landmark override service.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:dart_games/models/player.dart';
import 'package:dart_games/services/test_data_service.dart';
import 'package:dart_games/services/test_headshot_landmarks_service.dart';

const _knownLandmarks = {
  'boundingBox': {'x': 0.20, 'y': 0.15, 'width': 0.60, 'height': 0.70},
  'leftEye': {'x': 0.38, 'y': 0.40},
  'rightEye': {'x': 0.62, 'y': 0.40},
  'noseTip': {'x': 0.50, 'y': 0.55},
  'mouthCenter': {'x': 0.50, 'y': 0.70},
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('filenameForIndex', () {
    test('matches the headshot naming convention', () {
      expect(TestHeadshotLandmarksService.filenameForIndex(0), 'headshot-01.png');
      expect(TestHeadshotLandmarksService.filenameForIndex(6), 'headshot-07.png');
      expect(TestHeadshotLandmarksService.filenameForIndex(19), 'headshot-20.png');
    });
  });

  group('buildExportPayload', () {
    final canonical = TestDataService.generateTestPlayers();

    test('returns an entry for every test player with corrected landmarks',
        () {
      // First and seventh canonical names — keep landmarks on these, drop
      // the rest. Build a Player list matching what the live provider
      // would expose after the user corrected those two photos.
      final loaded = [
        canonical[0].copyWith(faceLandmarks: _knownLandmarks),
        canonical[6].copyWith(faceLandmarks: _knownLandmarks),
        // 18 more players who have NO landmarks — they shouldn't show up
        // in the export.
        for (var i = 1; i < canonical.length; i++)
          if (i != 6) canonical[i],
      ];

      final out = TestHeadshotLandmarksService.buildExportPayload(loaded);

      expect(out.keys.toSet(), {'headshot-01.png', 'headshot-07.png'});
      expect(out['headshot-01.png'], _knownLandmarks);
      expect(out['headshot-07.png'], _knownLandmarks);
    });

    test('ignores players whose name does not match any test-data entry',
        () {
      final loaded = [
        Player(
          id: 'unrelated',
          name: 'Some Real Person',
          createdAt: DateTime.parse('2026-05-01T00:00:00.000Z'),
          gamesPlayed: 0,
          gamesWon: 0,
          faceLandmarks: _knownLandmarks,
        ),
      ];

      final out = TestHeadshotLandmarksService.buildExportPayload(loaded);
      expect(out, isEmpty);
    });

    test('returns an empty map when no test players are loaded', () {
      expect(
        TestHeadshotLandmarksService.buildExportPayload(const []),
        isEmpty,
      );
    });
  });

  group('cropToSquare', () {
    test('portrait crop drops top + bottom equally', () {
      // 100x200 portrait → side = 100, cropY = 50.
      // A point at (0.5, 0.5) is at pixel (50, 100). After cropping y by 50,
      // it's at (50, 50) of a 100x100 square → normalized (0.5, 0.5).
      final r = TestHeadshotLandmarksService.cropToSquare(
          0.5, 0.5, oldW: 100, oldH: 200);
      expect(r.x, closeTo(0.5, 1e-9));
      expect(r.y, closeTo(0.5, 1e-9));
    });

    test('portrait crop pushes a near-top point off the new image (clamped)',
        () {
      // 100x200 portrait → cropY = 50. A point at y=0.10 is at pixel y=20.
      // pixel y after crop = 20 - 50 = -30 → clamps to 0.
      final r = TestHeadshotLandmarksService.cropToSquare(
          0.5, 0.10, oldW: 100, oldH: 200);
      expect(r.y, 0.0);
    });

    test('landscape crop drops left + right equally', () {
      // 300x100 landscape → side = 100, cropX = 100.
      // Point at (0.5, 0.5) = pixel (150, 50). After crop x by 100, (50, 50)
      // of a 100x100 square → (0.5, 0.5).
      final r = TestHeadshotLandmarksService.cropToSquare(
          0.5, 0.5, oldW: 300, oldH: 100);
      expect(r.x, closeTo(0.5, 1e-9));
      expect(r.y, closeTo(0.5, 1e-9));
    });

    test('square input is a no-op', () {
      final r = TestHeadshotLandmarksService.cropToSquare(
          0.27, 0.83, oldW: 500, oldH: 500);
      expect(r.x, closeTo(0.27, 1e-9));
      expect(r.y, closeTo(0.83, 1e-9));
    });
  });

  group('transformOverrideForCanonicalCrop', () {
    test('transforms all five landmarks + recomputes bbox', () {
      // Use the same 100x200 portrait crop with sane mid-image landmarks
      // so we can hand-verify the math.
      final override = {
        'boundingBox': {'x': 0.20, 'y': 0.30, 'width': 0.60, 'height': 0.50},
        'leftEye': {'x': 0.40, 'y': 0.45},
        'rightEye': {'x': 0.60, 'y': 0.45},
        'noseTip': {'x': 0.50, 'y': 0.55},
        'mouthCenter': {'x': 0.50, 'y': 0.70},
        'confidence': 0.97,
      };

      final out = TestHeadshotLandmarksService
          .transformOverrideForCanonicalCrop(
        override,
        oldW: 100,
        oldH: 200,
      );

      // boundingBox top-left: pixel (20, 60), cropY=50 → cropped (20, 10) →
      // normalized in 100x100 square: (0.20, 0.10).
      // Bottom-right: pixel (80, 160) → cropped (80, 110) → normalized
      // (0.80, 1.10) → clamped (0.80, 1.00). Width = 0.60, height = 0.90.
      final bb = out['boundingBox'] as Map;
      expect(bb['x'], closeTo(0.20, 1e-9));
      expect(bb['y'], closeTo(0.10, 1e-9));
      expect(bb['width'], closeTo(0.60, 1e-9));
      expect(bb['height'], closeTo(0.90, 1e-9));

      // leftEye: pixel (40, 90) → cropped (40, 40) → norm (0.40, 0.40)
      expect((out['leftEye'] as Map)['x'], closeTo(0.40, 1e-9));
      expect((out['leftEye'] as Map)['y'], closeTo(0.40, 1e-9));

      // mouthCenter: pixel (50, 140) → cropped (50, 90) → norm (0.50, 0.90)
      expect((out['mouthCenter'] as Map)['x'], closeTo(0.50, 1e-9));
      expect((out['mouthCenter'] as Map)['y'], closeTo(0.90, 1e-9));

      // Pass-through fields survive.
      expect(out['confidence'], 0.97);
    });
  });

  group('loadOverrides', () {
    test('parses the bundled JSON into headshot-keyed landmark Maps',
        () async {
      // The shipped asset may start out as `{}` or be populated with real
      // overrides committed by the maintainer; either is valid. What the
      // service guarantees is that the result is a Map<String, Map> keyed
      // by headshot filename, where each value parses as a landmarks Map
      // with the expected sub-keys when present.
      final out = await TestHeadshotLandmarksService.loadOverrides();
      // Always a Map (may be empty).
      expect(out, isA<Map<String, Map<String, dynamic>>>());
      // Any populated entry must conform to the landmarks shape.
      for (final entry in out.entries) {
        expect(entry.key, matches(RegExp(r'^headshot-\d{2}\.png$')));
        expect(entry.value, contains('boundingBox'));
        expect(entry.value, contains('leftEye'));
        expect(entry.value, contains('rightEye'));
        expect(entry.value, contains('noseTip'));
        expect(entry.value, contains('mouthCenter'));
      }
    });
  });
}
