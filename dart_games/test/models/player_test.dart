import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/models/player.dart';
import 'package:dart_games/models/game_history_entry.dart';

void main() {
  group('Player', () {
    test('creates player with factory constructor', () {
      final player = Player.create(name: 'Test Player');

      expect(player.id, isNotEmpty);
      expect(player.name, 'Test Player');
      expect(player.photoPath, isNull);
      expect(player.createdAt, isNotNull);
      expect(player.gamesPlayed, 0);
      expect(player.gamesWon, 0);
      expect(player.gameHistory, isEmpty);
    });

    test('creates player with photo', () {
      final player = Player.create(
        name: 'Photo Player',
        photoPath: '/path/to/photo.jpg',
      );

      expect(player.name, 'Photo Player');
      expect(player.photoPath, '/path/to/photo.jpg');
    });

    test('creates player with empty game history', () {
      final player = Player.create(name: 'New Player');

      expect(player.gameHistory, isNotNull);
      expect(player.gameHistory, isEmpty);
    });

    test('serializes to JSON correctly', () {
      final player = Player.create(name: 'Test Player');
      final json = player.toJson();

      expect(json['id'], player.id);
      expect(json['name'], 'Test Player');
      expect(json['photoPath'], isNull);
      expect(json['createdAt'], isNotNull);
      expect(json['gamesPlayed'], 0);
      expect(json['gamesWon'], 0);
      expect(json['gameHistory'], isList);
      expect(json['gameHistory'], isEmpty);
    });

    test('serializes game history to JSON', () {
      final player = Player.create(name: 'Winner');
      final history = [
        GameHistoryEntry.create(
          gameName: 'Carnival Derby',
          duration: const Duration(minutes: 5),
        ),
        GameHistoryEntry.create(
          gameName: 'Carnival Derby',
          duration: const Duration(minutes: 3, seconds: 30),
        ),
      ];

      final updatedPlayer = player.copyWith(
        gamesPlayed: 2,
        gamesWon: 2,
        gameHistory: history,
      );

      final json = updatedPlayer.toJson();

      expect(json['gamesPlayed'], 2);
      expect(json['gamesWon'], 2);
      expect(json['gameHistory'], isList);
      expect((json['gameHistory'] as List).length, 2);
      expect((json['gameHistory'] as List)[0]['gameName'], 'Carnival Derby');
    });

    test('deserializes from JSON correctly', () {
      final json = {
        'id': 'player-123',
        'name': 'JSON Player',
        'photoPath': '/path/to/photo.jpg',
        'createdAt': DateTime.now().toIso8601String(),
        'gamesPlayed': 5,
        'gamesWon': 3,
        'gameHistory': [],
      };

      final player = Player.fromJson(json);

      expect(player.id, 'player-123');
      expect(player.name, 'JSON Player');
      expect(player.photoPath, '/path/to/photo.jpg');
      expect(player.gamesPlayed, 5);
      expect(player.gamesWon, 3);
      expect(player.gameHistory, isEmpty);
    });

    test('deserializes game history from JSON', () {
      final json = {
        'id': 'player-456',
        'name': 'History Player',
        'createdAt': DateTime.now().toIso8601String(),
        'gamesPlayed': 2,
        'gamesWon': 2,
        'gameHistory': [
          {
            'id': 'entry-1',
            'gameName': 'Carnival Derby',
            'timestamp': DateTime.now().toIso8601String(),
            'durationMs': 300000,
          },
          {
            'id': 'entry-2',
            'gameName': 'Carnival Derby',
            'timestamp': DateTime.now().toIso8601String(),
            'durationMs': 210000,
          },
        ],
      };

      final player = Player.fromJson(json);

      expect(player.gameHistory.length, 2);
      expect(player.gameHistory[0].gameName, 'Carnival Derby');
      expect(player.gameHistory[0].duration.inMinutes, 5);
      expect(player.gameHistory[1].duration.inMinutes, 3);
    });

    test('handles missing gameHistory in JSON (backward compatibility)', () {
      final json = {
        'id': 'old-player',
        'name': 'Old Format',
        'createdAt': DateTime.now().toIso8601String(),
        'gamesPlayed': 10,
        'gamesWon': 5,
        // No gameHistory field
      };

      final player = Player.fromJson(json);

      expect(player.gameHistory, isNotNull);
      expect(player.gameHistory, isEmpty);
      expect(player.gamesPlayed, 10);
      expect(player.gamesWon, 5);
    });

    test('copyWith creates new instance with updated fields', () {
      final original = Player.create(name: 'Original');
      final updated = original.copyWith(
        name: 'Updated',
        gamesPlayed: 5,
        gamesWon: 3,
      );

      expect(updated.id, original.id); // ID stays the same
      expect(updated.name, 'Updated');
      expect(updated.gamesPlayed, 5);
      expect(updated.gamesWon, 3);
      expect(original.name, 'Original'); // Original unchanged
    });

    test('copyWith updates game history', () {
      final player = Player.create(name: 'Player');
      final history = [
        GameHistoryEntry.create(
          gameName: 'Carnival Derby',
          duration: const Duration(minutes: 5),
        ),
      ];

      final updated = player.copyWith(gameHistory: history);

      expect(updated.gameHistory.length, 1);
      expect(updated.gameHistory[0].gameName, 'Carnival Derby');
      expect(player.gameHistory, isEmpty); // Original unchanged
    });

    test('copyWith preserves fields when not specified', () {
      final original = Player.create(
        name: 'Original',
        photoPath: '/photo.jpg',
      );
      final history = [
        GameHistoryEntry.create(
          gameName: 'Test',
          duration: const Duration(minutes: 1),
        ),
      ];
      final withHistory = original.copyWith(
        gamesPlayed: 1,
        gamesWon: 1,
        gameHistory: history,
      );

      final updated = withHistory.copyWith(name: 'New Name');

      expect(updated.name, 'New Name');
      expect(updated.photoPath, '/photo.jpg'); // Preserved
      expect(updated.gamesPlayed, 1); // Preserved
      expect(updated.gamesWon, 1); // Preserved
      expect(updated.gameHistory.length, 1); // Preserved
    });

    test('round-trip serialization preserves all data', () {
      final original = Player.create(
        name: 'Test Player',
        photoPath: '/path/to/photo.jpg',
      );
      final history = [
        GameHistoryEntry.create(
          gameName: 'Carnival Derby',
          duration: const Duration(minutes: 5, seconds: 30),
        ),
        GameHistoryEntry.create(
          gameName: 'Carnival Derby',
          duration: const Duration(minutes: 3, seconds: 15),
        ),
      ];
      final withData = original.copyWith(
        gamesPlayed: 2,
        gamesWon: 2,
        gameHistory: history,
      );

      final json = withData.toJson();
      final deserialized = Player.fromJson(json);

      expect(deserialized.id, withData.id);
      expect(deserialized.name, withData.name);
      expect(deserialized.photoPath, withData.photoPath);
      expect(deserialized.gamesPlayed, withData.gamesPlayed);
      expect(deserialized.gamesWon, withData.gamesWon);
      expect(deserialized.gameHistory.length, withData.gameHistory.length);
    });

    test('equality operator works correctly', () {
      final player1 = Player.create(name: 'Player');
      final player2 = Player(
        id: player1.id,
        name: 'Different Name',
        createdAt: DateTime.now(),
      );
      final player3 = Player.create(name: 'Another Player');

      expect(player1 == player2, isTrue); // Same ID
      expect(player1 == player3, isFalse); // Different ID
    });

    test('hashCode is based on ID', () {
      final player1 = Player.create(name: 'Player');
      final player2 = Player(
        id: player1.id,
        name: 'Different Name',
        createdAt: DateTime.now(),
      );

      expect(player1.hashCode, player2.hashCode);
    });

    test('handles null photoPath correctly', () {
      final json = {
        'id': 'test-player',
        'name': 'No Photo',
        'photoPath': null,
        'createdAt': DateTime.now().toIso8601String(),
        'gamesPlayed': 0,
        'gamesWon': 0,
        'gameHistory': [],
      };

      final player = Player.fromJson(json);

      expect(player.photoPath, isNull);

      final jsonOut = player.toJson();
      expect(jsonOut['photoPath'], isNull);
    });

    test('gamesPlayed and gamesWon can be updated', () {
      final player = Player.create(name: 'Player');

      expect(player.gamesPlayed, 0);
      expect(player.gamesWon, 0);

      final updated = player.copyWith(
        gamesPlayed: 10,
        gamesWon: 7,
      );

      expect(updated.gamesPlayed, 10);
      expect(updated.gamesWon, 7);
    });
  });
}
