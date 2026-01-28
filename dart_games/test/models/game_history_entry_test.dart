import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/models/game_history_entry.dart';

void main() {
  group('GameHistoryEntry', () {
    test('creates entry with factory constructor', () {
      final entry = GameHistoryEntry.create(
        gameName: 'Test Game',
        duration: const Duration(minutes: 5, seconds: 30),
      );

      expect(entry.id, isNotEmpty);
      expect(entry.gameName, 'Test Game');
      expect(entry.duration, const Duration(minutes: 5, seconds: 30));
      expect(entry.timestamp, isNotNull);
      expect(entry.metadata, isNull);
    });

    test('creates entry with metadata', () {
      final metadata = {'score': 180, 'difficulty': 'hard'};
      final entry = GameHistoryEntry.create(
        gameName: 'Carnival Derby',
        duration: const Duration(minutes: 3),
        metadata: metadata,
      );

      expect(entry.metadata, isNotNull);
      expect(entry.metadata!['score'], 180);
      expect(entry.metadata!['difficulty'], 'hard');
    });

    test('serializes to JSON correctly', () {
      final timestamp = DateTime(2024, 1, 15, 10, 30);
      final entry = GameHistoryEntry(
        id: 'test-id-123',
        gameName: 'Carnival Derby',
        timestamp: timestamp,
        duration: const Duration(minutes: 3, seconds: 45),
        metadata: {'score': 180},
      );

      final json = entry.toJson();

      expect(json['id'], 'test-id-123');
      expect(json['gameName'], 'Carnival Derby');
      expect(json['timestamp'], timestamp.toIso8601String());
      expect(json['durationMs'], 225000); // 3:45 in milliseconds
      expect(json['metadata'], {'score': 180});
    });

    test('deserializes from JSON correctly', () {
      final json = {
        'id': 'test-id-456',
        'gameName': 'Carnival Derby',
        'timestamp': '2024-01-15T10:30:00.000Z',
        'durationMs': 225000,
        'metadata': {'score': 180, 'rank': 1},
      };

      final entry = GameHistoryEntry.fromJson(json);

      expect(entry.id, 'test-id-456');
      expect(entry.gameName, 'Carnival Derby');
      expect(entry.timestamp, DateTime.parse('2024-01-15T10:30:00.000Z'));
      expect(entry.duration.inMilliseconds, 225000);
      expect(entry.duration.inMinutes, 3);
      expect(entry.metadata, {'score': 180, 'rank': 1});
    });

    test('deserializes from JSON without metadata', () {
      final json = {
        'id': 'test-id-789',
        'gameName': 'Test Game',
        'timestamp': '2024-01-15T10:30:00.000Z',
        'durationMs': 60000,
      };

      final entry = GameHistoryEntry.fromJson(json);

      expect(entry.id, 'test-id-789');
      expect(entry.gameName, 'Test Game');
      expect(entry.duration.inSeconds, 60);
      expect(entry.metadata, isNull);
    });

    test('round-trip serialization preserves data', () {
      final original = GameHistoryEntry.create(
        gameName: 'Carnival Derby',
        duration: const Duration(hours: 1, minutes: 23, seconds: 45),
        metadata: {'players': 4, 'winner': 'Player 1'},
      );

      final json = original.toJson();
      final deserialized = GameHistoryEntry.fromJson(json);

      expect(deserialized.id, original.id);
      expect(deserialized.gameName, original.gameName);
      expect(deserialized.duration, original.duration);
      expect(deserialized.metadata, original.metadata);
      // Timestamps might differ slightly, so check they're close
      expect(
        deserialized.timestamp.difference(original.timestamp).inSeconds,
        lessThan(1),
      );
    });

    test('handles different duration formats', () {
      final testCases = [
        const Duration(seconds: 30),
        const Duration(minutes: 5),
        const Duration(hours: 2, minutes: 30),
        const Duration(days: 1, hours: 3, minutes: 15, seconds: 45),
      ];

      for (final duration in testCases) {
        final entry = GameHistoryEntry.create(
          gameName: 'Test',
          duration: duration,
        );

        final json = entry.toJson();
        final deserialized = GameHistoryEntry.fromJson(json);

        expect(deserialized.duration, duration);
      }
    });

    test('timestamp is set to current time on creation', () {
      final before = DateTime.now();
      final entry = GameHistoryEntry.create(
        gameName: 'Test Game',
        duration: const Duration(minutes: 5),
      );
      final after = DateTime.now();

      expect(entry.timestamp.isAfter(before) || entry.timestamp.isAtSameMomentAs(before), isTrue);
      expect(entry.timestamp.isBefore(after) || entry.timestamp.isAtSameMomentAs(after), isTrue);
    });
  });
}
