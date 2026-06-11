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

  group('loadOverrides', () {
    test('returns an empty map when the asset is the default {} file',
        () async {
      // The shipped asset is `{}` so the service should return empty.
      final out = await TestHeadshotLandmarksService.loadOverrides();
      expect(out, isEmpty);
    });
  });
}
