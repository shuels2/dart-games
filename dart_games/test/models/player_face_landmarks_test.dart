import 'dart:convert';
import 'package:dart_games/models/player.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Player.faceLandmarks', () {
    // ── 1. toJson includes faceLandmarks as nested Map when non-null ──────────
    test('toJson includes faceLandmarks as nested Map when non-null', () {
      final landmarks = {
        'boundingBox': {'x': 0.18, 'y': 0.12, 'width': 0.64, 'height': 0.72},
        'leftEye': {'x': 0.34, 'y': 0.40},
        'rightEye': {'x': 0.66, 'y': 0.40},
        'noseTip': {'x': 0.50, 'y': 0.55},
        'mouthCenter': {'x': 0.50, 'y': 0.72},
        'confidence': 0.97,
      };
      final player = Player(
        id: 'p1',
        name: 'Jack',
        createdAt: DateTime(2024),
        faceLandmarks: landmarks,
      );

      final json = player.toJson();
      expect(json['faceLandmarks'], isA<Map<String, dynamic>>());
      expect((json['faceLandmarks'] as Map)['confidence'], 0.97);
      expect(
        ((json['faceLandmarks'] as Map)['leftEye'] as Map)['x'],
        0.34,
      );
    });

    // ── 2. toJson emits null when faceLandmarks is null ───────────────────────
    test('toJson emits null for faceLandmarks when absent', () {
      final player = Player(
        id: 'p2',
        name: 'Pearl',
        createdAt: DateTime(2024),
      );
      final json = player.toJson();
      expect(json.containsKey('faceLandmarks'), isTrue);
      expect(json['faceLandmarks'], isNull);
    });

    // ── 3. fromJson reads faceLandmarks as Map when present ──────────────────
    test('fromJson reads faceLandmarks as Map<String, dynamic> when present',
        () {
      final json = {
        'id': 'p3',
        'name': 'Red',
        'photoPath': null,
        'createdAt': '2024-01-01T00:00:00.000',
        'gamesPlayed': 0,
        'gamesWon': 0,
        'gameHistory': [],
        'faceLandmarks': {
          'leftEye': {'x': 0.35, 'y': 0.41},
          'rightEye': {'x': 0.65, 'y': 0.41},
          'noseTip': {'x': 0.50, 'y': 0.56},
          'mouthCenter': {'x': 0.50, 'y': 0.73},
          'boundingBox': {'x': 0.19, 'y': 0.13, 'width': 0.62, 'height': 0.71},
          'confidence': 0.95,
        },
      };

      final player = Player.fromJson(json);
      expect(player.faceLandmarks, isNotNull);
      expect(player.faceLandmarks!['confidence'], 0.95);
      expect(
        (player.faceLandmarks!['leftEye'] as Map)['x'],
        0.35,
      );
    });

    // ── 4. fromJson returns null faceLandmarks when key is missing ────────────
    test('fromJson returns null faceLandmarks when key is absent', () {
      final json = {
        'id': 'p4',
        'name': 'Sparrow',
        'photoPath': null,
        'createdAt': '2024-01-01T00:00:00.000',
        'gamesPlayed': 2,
        'gamesWon': 1,
        'gameHistory': [],
        // No 'faceLandmarks' key — older API response from other games.
      };

      final player = Player.fromJson(json);
      expect(player.faceLandmarks, isNull);
    });

    // ── 5. fromJson returns null faceLandmarks when value is explicitly null ──
    test('fromJson returns null faceLandmarks when value is null', () {
      final json = {
        'id': 'p5',
        'name': 'Barbossa',
        'photoPath': null,
        'createdAt': '2024-01-01T00:00:00.000',
        'gamesPlayed': 0,
        'gamesWon': 0,
        'gameHistory': [],
        'faceLandmarks': null,
      };

      final player = Player.fromJson(json);
      expect(player.faceLandmarks, isNull);
    });

    // ── 6. copyWith preserves landmarks when not overridden ───────────────────
    test('copyWith preserves faceLandmarks when not explicitly overridden', () {
      final landmarks = {
        'leftEye': {'x': 0.34, 'y': 0.40},
      };
      final player = Player(
        id: 'p6',
        name: 'Will',
        createdAt: DateTime(2024),
        faceLandmarks: landmarks,
      );

      final updated = player.copyWith(name: 'William');
      expect(updated.faceLandmarks, equals(landmarks));
      expect(updated.name, 'William');
    });

    // ── 7. copyWith preserves landmarks when explicitly passing null (codebase
    //       convention: nullable fields use ?? so null means "keep existing") ──
    test('copyWith keeps existing faceLandmarks when null is passed (convention)',
        () {
      final landmarks = {'leftEye': {'x': 0.3, 'y': 0.4}};
      final player = Player(
        id: 'p7',
        name: 'Calypso',
        createdAt: DateTime(2024),
        faceLandmarks: landmarks,
      );

      // The codebase uses `faceLandmarks ?? this.faceLandmarks`, which means
      // passing null does NOT clear the field — it preserves the existing value.
      final copy = player.copyWith(faceLandmarks: null);
      expect(copy.faceLandmarks, equals(landmarks));
    });

    // ── 8. Roundtrip via jsonEncode / jsonDecode ───────────────────────────────
    test('roundtrip survives jsonEncode/jsonDecode', () {
      final landmarks = {
        'boundingBox': {'x': 0.18, 'y': 0.12, 'width': 0.64, 'height': 0.72},
        'leftEye': {'x': 0.34, 'y': 0.40},
        'rightEye': {'x': 0.66, 'y': 0.40},
        'noseTip': {'x': 0.50, 'y': 0.55},
        'mouthCenter': {'x': 0.50, 'y': 0.72},
        'confidence': 0.97,
      };
      final original = Player(
        id: 'p8',
        name: 'Davy',
        createdAt: DateTime(2024, 6, 1),
        gamesPlayed: 3,
        gamesWon: 1,
        faceLandmarks: landmarks,
      );

      final encoded = jsonEncode(original.toJson());
      final decoded = Player.fromJson(jsonDecode(encoded) as Map<String, dynamic>);

      expect(decoded.id, original.id);
      expect(decoded.name, original.name);
      expect(decoded.faceLandmarks, isNotNull);
      expect(decoded.faceLandmarks!['confidence'], 0.97);
      expect(
        (decoded.faceLandmarks!['boundingBox'] as Map)['width'],
        0.64,
      );
    });

    // ── 9. Player.create does not include faceLandmarks (null by default) ──────
    test('Player.create does not set faceLandmarks', () {
      final player = Player.create(name: 'Jones');
      expect(player.faceLandmarks, isNull);
    });

    // ── 10. fromJson is backward-compatible with other games' API payloads ─────
    // Other games' responses never include faceLandmarks — must not throw.
    test('fromJson does not throw when faceLandmarks key is absent (other games)',
        () {
      final json = {
        'id': 'p10',
        'name': 'Hook',
        'photoPath': null,
        'createdAt': '2024-03-15T10:00:00.000',
        'gamesPlayed': 7,
        'gamesWon': 3,
        'gameHistory': [],
        // Intentionally no 'faceLandmarks' — simulates other game API payload.
      };

      expect(() => Player.fromJson(json), returnsNormally);
      final player = Player.fromJson(json);
      expect(player.faceLandmarks, isNull);
      expect(player.gamesWon, 3);
    });
  });
}
