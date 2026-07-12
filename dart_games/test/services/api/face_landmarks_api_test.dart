/// Tests for ApiClient.updatePlayerFaceLandmarks +
/// ApiClient.redetectPlayerFaceLandmarks against the in-memory MockApiServer.
library;

import 'package:flutter_test/flutter_test.dart';

import '../../shared/mock_api_helpers.dart';

void main() {
  late MockApiServer mock;

  setUp(() {
    mock = MockApiServer();
    mock.players.add({
      'id': 'face-edit-1',
      'name': 'Alex',
      'createdAt': '2026-05-01T00:00:00.000Z',
      'gamesPlayed': 0,
      'gamesWon': 0,
      'photoPath': '/api/v1/players/face-edit-1/photo',
      'faceLandmarks': null,
    });
  });

  group('ApiClient.updatePlayerFaceLandmarks', () {
    test('PATCHes the payload and returns the persisted landmarks', () async {
      final landmarks = {
        'boundingBox': {'x': 0.18, 'y': 0.12, 'width': 0.64, 'height': 0.72},
        'leftEye': {'x': 0.34, 'y': 0.40},
        'rightEye': {'x': 0.66, 'y': 0.40},
        'noseTip': {'x': 0.50, 'y': 0.55},
        'mouthCenter': {'x': 0.50, 'y': 0.72},
      };

      final result = await mock.apiClient
          .updatePlayerFaceLandmarks('face-edit-1', landmarks);

      expect((result['leftEye'] as Map)['x'], 0.34);
      expect((result['boundingBox'] as Map)['width'], 0.64);
      // Mock server stored it on the player record.
      expect(mock.players[0]['faceLandmarks'], isA<Map>());
    });
  });

  group('ApiClient.redetectPlayerFaceLandmarks', () {
    test('POSTs and returns the freshly-detected landmarks', () async {
      final fresh =
          await mock.apiClient.redetectPlayerFaceLandmarks('face-edit-1');

      expect(fresh['confidence'], 0.99);
      expect((fresh['leftEye'] as Map)['x'], 0.30);
      expect(mock.players[0]['faceLandmarks'], isNotNull);
    });
  });
}
