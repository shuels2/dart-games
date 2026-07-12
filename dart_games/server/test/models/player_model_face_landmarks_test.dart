import 'dart:convert';

import 'package:test/test.dart';

import 'package:dart_games_server/models/player_model.dart';

void main() {
  const _sampleLandmarks = {
    'boundingBox': {'x': 0.18, 'y': 0.12, 'width': 0.64, 'height': 0.72},
    'leftEye': {'x': 0.34, 'y': 0.40},
    'rightEye': {'x': 0.66, 'y': 0.40},
    'noseTip': {'x': 0.50, 'y': 0.55},
    'mouthCenter': {'x': 0.50, 'y': 0.72},
    'confidence': 0.97,
  };

  group('ServerPlayer.fromDbRow — faceLandmarks', () {
    Map<String, dynamic> _baseRow({String? faceLandmarksJson}) => {
          'id': 'player-1',
          'name': 'Alice',
          'photo_path': '/data/photos/alice.jpg',
          'created_at': '2026-01-01T00:00:00Z',
          'games_played': 5,
          'games_won': 2,
          'face_landmarks': faceLandmarksJson,
        };

    test('fromDbRow with null face_landmarks produces null faceLandmarks', () {
      final player = ServerPlayer.fromDbRow(_baseRow());
      expect(player.faceLandmarks, isNull);
    });

    test('fromDbRow with JSON string decodes to Map', () {
      final json = jsonEncode(_sampleLandmarks);
      final player = ServerPlayer.fromDbRow(_baseRow(faceLandmarksJson: json));

      expect(player.faceLandmarks, isNotNull);
      expect(player.faceLandmarks!['confidence'], 0.97);
      expect(player.faceLandmarks!['leftEye'], {'x': 0.34, 'y': 0.40});
      expect(
        (player.faceLandmarks!['boundingBox'] as Map)['width'],
        0.64,
      );
    });

    test('fromDbRow parses all spec keys correctly', () {
      final json = jsonEncode(_sampleLandmarks);
      final player = ServerPlayer.fromDbRow(_baseRow(faceLandmarksJson: json));
      final lm = player.faceLandmarks!;

      expect(lm.containsKey('boundingBox'), isTrue);
      expect(lm.containsKey('leftEye'), isTrue);
      expect(lm.containsKey('rightEye'), isTrue);
      expect(lm.containsKey('noseTip'), isTrue);
      expect(lm.containsKey('mouthCenter'), isTrue);
      expect(lm.containsKey('confidence'), isTrue);
    });
  });

  group('ServerPlayer.toJson — faceLandmarks', () {
    test('toJson with null faceLandmarks emits null field', () {
      final player = ServerPlayer(
        id: 'p1',
        name: 'Alice',
        createdAt: '2026-01-01T00:00:00Z',
        gamesPlayed: 0,
        gamesWon: 0,
      );
      final json = player.toJson();
      expect(json.containsKey('faceLandmarks'), isTrue);
      expect(json['faceLandmarks'], isNull);
    });

    test('toJson with non-null faceLandmarks emits nested object (NOT a string)', () {
      final player = ServerPlayer(
        id: 'p1',
        name: 'Alice',
        createdAt: '2026-01-01T00:00:00Z',
        gamesPlayed: 0,
        gamesWon: 0,
        faceLandmarks: _sampleLandmarks,
      );
      final json = player.toJson();

      // Must be a Map, not a JSON-encoded String.
      expect(json['faceLandmarks'], isA<Map>());
      expect((json['faceLandmarks'] as Map)['confidence'], 0.97);
    });

    test('toJson round-trips through jsonEncode/jsonDecode correctly', () {
      final player = ServerPlayer(
        id: 'p1',
        name: 'Alice',
        createdAt: '2026-01-01T00:00:00Z',
        gamesPlayed: 3,
        gamesWon: 1,
        faceLandmarks: _sampleLandmarks,
      );

      final encoded = jsonEncode(player.toJson());
      final decoded = jsonDecode(encoded) as Map<String, dynamic>;

      final lm = decoded['faceLandmarks'] as Map<String, dynamic>;
      expect(lm['confidence'], 0.97);
      expect((lm['leftEye'] as Map)['x'], 0.34);
      expect((lm['boundingBox'] as Map)['height'], 0.72);
    });
  });

  group('ServerPlayer.fromDbRow / toJson round-trip', () {
    test('full round-trip preserves landmark coordinates', () {
      final originalJson = jsonEncode(_sampleLandmarks);
      final player = ServerPlayer.fromDbRow({
        'id': 'p1',
        'name': 'Alice',
        'photo_path': null,
        'created_at': '2026-01-01T00:00:00Z',
        'games_played': 0,
        'games_won': 0,
        'face_landmarks': originalJson,
      });

      final apiJson = player.toJson();
      final lm = apiJson['faceLandmarks'] as Map<String, dynamic>;

      // Verify every coordinate survives the round-trip.
      expect((lm['boundingBox'] as Map)['x'], 0.18);
      expect((lm['boundingBox'] as Map)['y'], 0.12);
      expect((lm['boundingBox'] as Map)['width'], 0.64);
      expect((lm['boundingBox'] as Map)['height'], 0.72);
      expect((lm['leftEye'] as Map)['x'], 0.34);
      expect((lm['rightEye'] as Map)['x'], 0.66);
      expect((lm['noseTip'] as Map)['x'], 0.50);
      expect((lm['mouthCenter'] as Map)['x'], 0.50);
      expect(lm['confidence'], 0.97);
    });

    test('null landmark survives round-trip as null', () {
      final player = ServerPlayer.fromDbRow({
        'id': 'p2',
        'name': 'Bob',
        'photo_path': null,
        'created_at': '2026-01-01T00:00:00Z',
        'games_played': 0,
        'games_won': 0,
        'face_landmarks': null,
      });

      expect(player.toJson()['faceLandmarks'], isNull);
    });
  });
}
