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
}
