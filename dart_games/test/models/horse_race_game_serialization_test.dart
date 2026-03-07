import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/models/horse_race_game.dart';

void main() {
  group('HorseRaceGame serialization', () {
    HorseRaceGame _createGameWithState() {
      final game = HorseRaceGame.create(
        playerIds: ['p1', 'p2', 'p3'],
        targetScore: 301,
        exactScoreMode: true,
      );
      // Simulate some gameplay
      game.recordDartThrow('p1', 20, dartDisplay: '20');
      game.recordDartThrow('p1', 5, dartDisplay: '5');
      game.recordDartThrow('p1', 1, dartDisplay: '1');
      game.advanceToNextPlayer();
      game.recordDartThrow('p2', 60, dartDisplay: 'T20');
      return game;
    }

    test('toJson includes all fields', () {
      final game = _createGameWithState();
      final json = game.toJson();

      expect(json['id'], game.id);
      expect(json['playerIds'], ['p1', 'p2', 'p3']);
      expect(json['targetScore'], 301);
      expect(json['exactScoreMode'], true);
      expect(json['startedAt'], game.startedAt.toIso8601String());
      expect(json['maxDartsPerTurn'], 3);
      expect(json['state'], 'playing');
      expect(json['currentPlayerIndex'], game.currentPlayerIndex);
      expect(json['scores'], isA<Map>());
      expect(json['dartsThrown'], isA<Map>());
      expect(json['totalDartsThrown'], isA<Map>());
      expect(json['totalTurns'], isA<Map>());
      expect(json['currentTurnDartScores'], isA<Map>());
      expect(json['currentPlayerBusted'], false);
      expect(json['turnStartScores'], isA<Map>());
      expect(json['turnStartState'], isA<String>());
      expect(json['turnStartCurrentPlayerBusted'], false);
    });

    test('toJson serializes enums as .name strings', () {
      final game = _createGameWithState();
      final json = game.toJson();

      expect(json['state'], 'playing');
      expect(json['turnStartState'], isA<String>());
      // Should NOT contain "GameState." prefix
      expect(json['state'].toString().contains('.'), false);
    });

    test('fromJson restores all basic fields', () {
      final original = _createGameWithState();
      final json = original.toJson();
      final restored = HorseRaceGame.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.playerIds, original.playerIds);
      expect(restored.targetScore, original.targetScore);
      expect(restored.exactScoreMode, original.exactScoreMode);
      expect(restored.startedAt, original.startedAt);
      expect(restored.maxDartsPerTurn, original.maxDartsPerTurn);
      expect(restored.state, original.state);
      expect(restored.currentPlayerIndex, original.currentPlayerIndex);
      expect(restored.winnerId, original.winnerId);
      expect(restored.currentPlayerBusted, original.currentPlayerBusted);
    });

    test('fromJson restores scores and dart tracking', () {
      final original = _createGameWithState();
      final json = original.toJson();
      final restored = HorseRaceGame.fromJson(json);

      expect(restored.scores, original.scores);
      expect(restored.dartsThrown, original.dartsThrown);
      expect(restored.totalDartsThrown, original.totalDartsThrown);
      expect(restored.totalTurns, original.totalTurns);
      expect(restored.currentTurnDartScores, original.currentTurnDartScores);
    });

    test('fromJson restores turn start state', () {
      final original = _createGameWithState();
      final json = original.toJson();
      final restored = HorseRaceGame.fromJson(json);

      expect(restored.turnStartScores, original.turnStartScores);
      expect(restored.turnStartWinnerId, original.turnStartWinnerId);
      expect(restored.turnStartState, original.turnStartState);
      expect(restored.turnStartCurrentPlayerBusted,
          original.turnStartCurrentPlayerBusted);
    });

    test('round-trip preserves totalDartsThrown and totalTurns', () {
      final original = _createGameWithState();
      final json = original.toJson();
      final restored = HorseRaceGame.fromJson(json);

      // p1 threw 3 darts, p2 threw 1 dart
      expect(restored.totalDartsThrown['p1'], 3);
      expect(restored.totalDartsThrown['p2'], 1);
      expect(restored.totalTurns['p1'], 1);
      expect(restored.totalTurns['p2'], 1);
    });

    test('round-trip with null winnerId', () {
      final game = HorseRaceGame.create(
        playerIds: ['p1', 'p2'],
        targetScore: 301,
      );
      final json = game.toJson();
      final restored = HorseRaceGame.fromJson(json);

      expect(restored.winnerId, isNull);
    });

    test('round-trip with winner', () {
      final game = HorseRaceGame.create(
        playerIds: ['p1', 'p2'],
        targetScore: 50,
      );
      // Score enough to win
      game.recordDartThrow('p1', 50, dartDisplay: '50');

      final json = game.toJson();
      final restored = HorseRaceGame.fromJson(json);

      expect(restored.winnerId, 'p1');
      expect(restored.state, GameState.finished);
    });

    test('round-trip with exact score mode bust', () {
      final game = HorseRaceGame.create(
        playerIds: ['p1', 'p2'],
        targetScore: 50,
        exactScoreMode: true,
      );
      game.recordDartThrow('p1', 40, dartDisplay: '40');
      game.advanceToNextPlayer();
      game.recordDartThrow('p2', 10, dartDisplay: '10');
      game.advanceToNextPlayer();
      // P1 at 40, throw 20 → bust (60 > 50)
      game.recordDartThrow('p1', 20, dartDisplay: '20');

      expect(game.currentPlayerBusted, true);
      final json = game.toJson();
      final restored = HorseRaceGame.fromJson(json);

      expect(restored.currentPlayerBusted, true);
      expect(restored.scores['p1'], 40); // Score unchanged after bust
    });

    test('round-trip with empty maps', () {
      final game = HorseRaceGame(
        id: 'test-id',
        playerIds: ['p1'],
        targetScore: 100,
        startedAt: DateTime(2024, 1, 1),
        state: GameState.playing,
      );
      final json = game.toJson();
      final restored = HorseRaceGame.fromJson(json);

      expect(restored.scores['p1'], 0);
      expect(restored.dartsThrown['p1'], 0);
      expect(restored.totalDartsThrown['p1'], 0);
      expect(restored.totalTurns['p1'], 0);
    });

    test('gameplay continues correctly after restore', () {
      final original = _createGameWithState();
      final json = original.toJson();
      final restored = HorseRaceGame.fromJson(json);

      // Continue gameplay on restored game
      final currentPlayerId = restored.getCurrentPlayerId();
      final dartsBefore = restored.dartsThrown[currentPlayerId]!;
      restored.recordDartThrow(currentPlayerId, 10, dartDisplay: '10');

      expect(restored.dartsThrown[currentPlayerId], dartsBefore + 1);
    });
  });
}
