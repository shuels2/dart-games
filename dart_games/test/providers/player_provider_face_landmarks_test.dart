/// Tests for PlayerProvider.updateFaceLandmarks +
/// PlayerProvider.redetectFaceLandmarks.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:dart_games/models/player.dart';
import 'package:dart_games/providers/player_provider.dart';

import '../shared/mock_api_helpers.dart';

void main() {
  late MockApiServer mock;
  late PlayerProvider provider;

  Player _seededPlayer() => Player(
        id: 'face-prov-1',
        name: 'Alex',
        createdAt: DateTime.parse('2026-05-01T00:00:00.000Z'),
        gamesPlayed: 0,
        gamesWon: 0,
      );

  setUp(() async {
    mock = MockApiServer();
    mock.players.add({
      'id': 'face-prov-1',
      'name': 'Alex',
      'createdAt': '2026-05-01T00:00:00.000Z',
      'gamesPlayed': 0,
      'gamesWon': 0,
      'photoPath': '/api/v1/players/face-prov-1/photo',
      'faceLandmarks': null,
    });
    provider = PlayerProvider();
    provider.initialize(mock.apiClient);
    await provider.loadPlayers();
  });

  group('PlayerProvider.updateFaceLandmarks', () {
    test('writes through and updates the local Player', () async {
      final landmarks = {
        'boundingBox': {'x': 0.18, 'y': 0.12, 'width': 0.64, 'height': 0.72},
        'leftEye': {'x': 0.34, 'y': 0.40},
        'rightEye': {'x': 0.66, 'y': 0.40},
        'noseTip': {'x': 0.50, 'y': 0.55},
        'mouthCenter': {'x': 0.50, 'y': 0.72},
      };

      var notified = 0;
      provider.addListener(() => notified++);

      await provider.updateFaceLandmarks('face-prov-1', landmarks);

      final p = provider.byId('face-prov-1');
      expect(p, isNotNull);
      expect(p!.faceLandmarks, isNotNull);
      expect((p.faceLandmarks!['leftEye'] as Map)['x'], 0.34);
      expect(notified, greaterThanOrEqualTo(1),
          reason: 'listeners should be notified on successful update');
    });

    test('rolls back to prior state when the server rejects', () async {
      // No player with this id on the mock server -> 404 from the route.
      Object? caught;
      try {
        await provider.updateFaceLandmarks('unknown-id', {
          'boundingBox': {'x': 0.1, 'y': 0.1, 'width': 0.5, 'height': 0.5},
          'leftEye': {'x': 0.3, 'y': 0.4},
          'rightEye': {'x': 0.7, 'y': 0.4},
          'noseTip': {'x': 0.5, 'y': 0.5},
          'mouthCenter': {'x': 0.5, 'y': 0.7},
        });
      } catch (e) {
        caught = e;
      }

      expect(caught, isNotNull, reason: 'ApiException should propagate');
      // The seeded player's landmarks remain untouched.
      expect(provider.byId('face-prov-1')!.faceLandmarks, isNull);
    });
  });

  group('PlayerProvider.redetectFaceLandmarks', () {
    test('overwrites local landmarks with the freshly detected payload',
        () async {
      final fresh = await provider.redetectFaceLandmarks('face-prov-1');
      expect(fresh['confidence'], 0.99);
      final p = provider.byId('face-prov-1');
      expect((p!.faceLandmarks!['leftEye'] as Map)['x'], 0.30);
    });
  });

  // ---------------------------------------------------------------------------
  // Synchronous photo-upload detection surfaced through savePlayer
  // ---------------------------------------------------------------------------

  group('PlayerProvider.savePlayer photo-upload detection outcomes', () {
    // Minimal base64 data URL — the mock server doesn't decode it; we
    // just need the `data:image/...,...` prefix so PlayerProvider's
    // "case 1" branch triggers an upload call.
    const _dataUrl = 'data:image/jpeg;base64,AAAA';

    test(
        'detection success — provider caches the returned landmarks on the '
        'local Player record without a follow-up GET', () async {
      final freshLandmarks = {
        'boundingBox': {'x': 0.20, 'y': 0.15, 'width': 0.60, 'height': 0.70},
        'leftEye': {'x': 0.35, 'y': 0.42},
        'rightEye': {'x': 0.65, 'y': 0.42},
        'noseTip': {'x': 0.50, 'y': 0.57},
        'mouthCenter': {'x': 0.50, 'y': 0.73},
        'confidence': 1.0,
      };
      mock.nextPhotoUploadDetection =
          MockNextPhotoUploadDetection.success(freshLandmarks);

      final updated = _seededPlayer().copyWith(photoPath: _dataUrl);
      await provider.savePlayer(updated);

      // The upload flow cached the fresh landmarks on the local record
      // — no need to loadPlayers() to see them.
      final p = provider.byId('face-prov-1');
      expect(p, isNotNull);
      expect(p!.faceLandmarks, isNotNull);
      expect((p.faceLandmarks!['leftEye'] as Map)['x'], 0.35);
      expect(p.faceLandmarks!['confidence'], 1.0);
      // No detection error surfaced.
      expect(provider.lastPhotoUploadFaceLandmarksError, isNull);
    });

    test(
        'detection failure — provider exposes the errorReason on '
        'lastPhotoUploadFaceLandmarksError; photo path still updated',
        () async {
      mock.nextPhotoUploadDetection = MockNextPhotoUploadDetection.failure(
          'no-face-detected: MediaPipe ran successfully but did not find '
          'a face in the current photo.');

      final updated = _seededPlayer().copyWith(photoPath: _dataUrl);
      await provider.savePlayer(updated);

      // Error is surfaced for the calling widget to render a hint.
      expect(provider.lastPhotoUploadFaceLandmarksError,
          startsWith('no-face-detected'));
      // Player row still has a photo path (the upload succeeded even
      // though detection failed).
      final p = provider.byId('face-prov-1');
      expect(p!.photoPath, isNotNull);
      // Face landmarks stay null — mock did not stage a landmarks map.
      expect(p.faceLandmarks, isNull);
    });

    test(
        'the error field is cleared at the START of the NEXT savePlayer call '
        'so a stale error from a prior save does not leak into a fresh upload',
        () async {
      // First save: fails detection.
      mock.nextPhotoUploadDetection =
          MockNextPhotoUploadDetection.failure('no-face-detected: …');
      await provider.savePlayer(_seededPlayer().copyWith(photoPath: _dataUrl));
      expect(provider.lastPhotoUploadFaceLandmarksError,
          startsWith('no-face-detected'));

      // Second save: succeeds. The mock does NOT stage a new detection
      // outcome, so the mock returns the default "no faceLandmarks /
      // no faceLandmarksError" shape — which is equivalent to a
      // `detectLandmarks:false` opt-out. The error field must have been
      // cleared at the start of savePlayer so the caller sees a clean
      // slate, not a stale failure from the previous call.
      await provider.savePlayer(_seededPlayer().copyWith(photoPath: _dataUrl));
      expect(provider.lastPhotoUploadFaceLandmarksError, isNull,
          reason: 'stale error must not carry over across savePlayer calls');
    });
  });
}
