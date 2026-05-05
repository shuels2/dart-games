import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/models/lunar_lander_game.dart';

void main() {
  group('LunarLanderGame serialization', () {
    /// Builds a fully-populated game with in-progress state for round-trip tests.
    LunarLanderGame _createGameWithState() {
      final game = LunarLanderGame.create(
        playerIds: ['p1', 'p2', 'p3'],
        startingAltitude: 200,
        hardLandingEnabled: true,
      );
      // Snapshot initial turn start state
      game.saveTurnStartState();

      // p1 throws two darts — reduces altitude
      game.dartsThrown['p1'] = 2;
      game.totalDartsThrown['p1'] = 2;
      game.totalTurns['p1'] = 1;
      game.currentAltitudes['p1'] = 180; // 200 - 20
      game.currentTurnDartScores['p1'] = [10, 10];
      game.dartThrowWasBust['p1'] = [false, false];

      // Advance to p2
      game.advanceToNextPlayer();

      // p2 throws one dart
      game.dartsThrown['p2'] = 1;
      game.totalDartsThrown['p2'] = 1;
      game.totalTurns['p2'] = 1;
      game.currentAltitudes['p2'] = 185;
      game.currentTurnDartScores['p2'] = [15];
      game.dartThrowWasBust['p2'] = [false];

      // Snapshot current turn start state
      game.saveTurnStartState();

      return game;
    }

    test('round-trip preserves basic fields', () {
      final original = _createGameWithState();
      final json = original.toJson();
      final restored = LunarLanderGame.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.startedAt, original.startedAt);
      expect(restored.maxDartsPerTurn, original.maxDartsPerTurn);
      expect(restored.playerIds, original.playerIds);
    });

    test('round-trip preserves configuration', () {
      final original = _createGameWithState();
      final json = original.toJson();
      final restored = LunarLanderGame.fromJson(json);

      expect(restored.startingAltitude, 200);
      expect(restored.hardLandingEnabled, true);
    });

    test('round-trip preserves character assignments', () {
      final original = _createGameWithState();
      final json = original.toJson();
      final restored = LunarLanderGame.fromJson(json);

      expect(restored.characterAssignments.length,
          original.characterAssignments.length);
      for (final playerId in original.playerIds) {
        expect(restored.characterAssignments[playerId],
            original.characterAssignments[playerId]);
        expect(restored.characterAssignments[playerId],
            isA<LunarLanderCharacter>());
      }
    });

    test('round-trip preserves runtime state', () {
      final original = _createGameWithState();
      final json = original.toJson();
      final restored = LunarLanderGame.fromJson(json);

      expect(restored.currentAltitudes['p1'], 180);
      expect(restored.currentAltitudes['p2'], 185);
      expect(restored.currentAltitudes['p3'], 200);
      expect(restored.currentPlayerIndex, original.currentPlayerIndex);
      expect(restored.state, original.state);
      expect(restored.winnerId, original.winnerId);
    });

    test('round-trip preserves dart history', () {
      final original = _createGameWithState();
      final json = original.toJson();
      final restored = LunarLanderGame.fromJson(json);

      expect(restored.currentTurnDartScores['p1'],
          original.currentTurnDartScores['p1']);
      expect(restored.currentTurnDartScores['p2'],
          original.currentTurnDartScores['p2']);
      expect(restored.dartThrowWasBust['p1'],
          original.dartThrowWasBust['p1']);
      expect(restored.dartThrowWasBust['p2'],
          original.dartThrowWasBust['p2']);
    });

    test('round-trip preserves turn-start state', () {
      final original = _createGameWithState();
      final json = original.toJson();
      final restored = LunarLanderGame.fromJson(json);

      for (final playerId in original.playerIds) {
        expect(restored.turnStartAltitude[playerId],
            original.turnStartAltitude[playerId]);
      }
      expect(restored.turnStartCurrentPlayerIndex,
          original.turnStartCurrentPlayerIndex);
      expect(restored.turnStartState, original.turnStartState);
      expect(restored.turnStartWinnerId, original.turnStartWinnerId);
    });

    test('round-trip preserves cumulative counters', () {
      final original = _createGameWithState();
      final json = original.toJson();
      final restored = LunarLanderGame.fromJson(json);

      expect(restored.totalDartsThrown['p1'], 2);
      expect(restored.totalDartsThrown['p2'], 1);
      expect(restored.totalDartsThrown['p3'], 0);
      // totalTurns is incremented ONCE per turn (on the first dart). p1 has
      // completed one turn, p2 is mid-turn (first dart thrown), p3 hasn't started.
      expect(restored.totalTurns['p1'], 1);
      expect(restored.totalTurns['p2'], 1);
      expect(restored.totalTurns['p3'], 0);
    });

    test('round-trip preserves enum values as strings', () {
      // Verify LunarLanderGameState and LunarLanderCharacter round-trip via .name
      final game = LunarLanderGame(
        id: 'test-id',
        startedAt: DateTime(2026, 1, 1, 12, 0, 0),
        maxDartsPerTurn: 3,
        startingAltitude: 300,
        hardLandingEnabled: false,
        playerIds: ['px'],
        characterAssignments: {
          'px': LunarLanderCharacter.spaceDog,
        },
        state: LunarLanderGameState.finished,
        currentPlayerIndex: 0,
        winnerId: 'px',
        turnStartState: LunarLanderGameState.playing,
      );

      final json = game.toJson();

      // Enum names serialized as plain strings (no dot-prefix)
      expect(json['state'], 'finished');
      expect(json['state'].toString().contains('.'), false);
      expect(json['turnStartState'], 'playing');
      expect((json['characterAssignments'] as Map)['px'], 'spaceDog');

      final restored = LunarLanderGame.fromJson(json);
      expect(restored.state, LunarLanderGameState.finished);
      expect(restored.characterAssignments['px'], LunarLanderCharacter.spaceDog);
      // All 8 character enum values are representable
      for (final character in LunarLanderCharacter.values) {
        expect(
          LunarLanderCharacter.values
              .firstWhere((e) => e.name == character.name),
          character,
        );
      }
    });

    test('round-trip preserves DateTime via ISO 8601', () {
      final fixed = DateTime(2026, 5, 2, 10, 30, 0);
      final game = LunarLanderGame(
        id: 'iso-test',
        startedAt: fixed,
        maxDartsPerTurn: 3,
        startingAltitude: 150,
        hardLandingEnabled: false,
        playerIds: ['pa', 'pb'],
        characterAssignments: {
          'pa': LunarLanderCharacter.moonCat,
          'pb': LunarLanderCharacter.rocketPenguin,
        },
      );

      final json = game.toJson();
      expect(json['startedAt'], fixed.toIso8601String());

      final restored = LunarLanderGame.fromJson(json);
      expect(restored.startedAt, fixed);
    });

    test('round-trip preserves null winnerId', () {
      final game = LunarLanderGame.create(
        playerIds: ['p1', 'p2'],
        startingAltitude: 100,
        hardLandingEnabled: false,
      );
      final json = game.toJson();
      final restored = LunarLanderGame.fromJson(json);

      expect(restored.winnerId, isNull);
      expect(restored.turnStartWinnerId, isNull);
    });

    test('toJson includes all expected keys', () {
      final original = _createGameWithState();
      final json = original.toJson();

      expect(json['id'], original.id);
      expect(json['startedAt'], original.startedAt.toIso8601String());
      expect(json['maxDartsPerTurn'], 3);
      expect(json['startingAltitude'], 200);
      expect(json['hardLandingEnabled'], true);
      expect(json['playerIds'], isA<List>());
      expect(json['characterAssignments'], isA<Map>());
      expect(json['currentAltitudes'], isA<Map>());
      expect(json['state'], isA<String>());
      expect(json['currentPlayerIndex'], isA<int>());
      expect(json['dartsThrown'], isA<Map>());
      expect(json['totalDartsThrown'], isA<Map>());
      expect(json['totalTurns'], isA<Map>());
      expect(json['currentTurnDartScores'], isA<Map>());
      expect(json['dartThrowWasBust'], isA<Map>());
      expect(json['turnStartAltitude'], isA<Map>());
      expect(json['turnStartCurrentPlayerIndex'], isA<int>());
      expect(json['turnStartState'], isA<String>());
    });

    test('round-trip survives a full game scenario', () {
      // Start fresh game
      final game = LunarLanderGame.create(
        playerIds: ['p1', 'p2'],
        startingAltitude: 50,
        hardLandingEnabled: true,
      );
      game.saveTurnStartState();

      // p1 throws darts: scores 20 + 20 = 40, altitude becomes 10
      game.dartsThrown['p1'] = 2;
      game.totalDartsThrown['p1'] = 2;
      game.totalTurns['p1'] = 1;
      game.currentAltitudes['p1'] = 10;
      game.currentTurnDartScores['p1'] = [20, 20];
      game.dartThrowWasBust['p1'] = [false, false];

      // Save and restore
      final json = game.toJson();
      final restored = LunarLanderGame.fromJson(json);

      // Verify restored state matches
      expect(restored.currentAltitudes['p1'], 10);
      expect(restored.currentAltitudes['p2'], 50);
      expect(restored.totalDartsThrown['p1'], 2);
      expect(restored.currentTurnDartScores['p1'], [20, 20]);
      expect(restored.dartThrowWasBust['p1'], [false, false]);
      expect(restored.state, LunarLanderGameState.playing);
      expect(restored.winnerId, isNull);
      expect(restored.startingAltitude, 50);
      expect(restored.hardLandingEnabled, true);

      // Gameplay can continue after restore — simulate a bust on p1's next dart
      // (dart value 15 would take p1 to -5, which triggers bust)
      final altBefore = restored.turnStartAltitude['p1']!;
      // Simulate bust: revert altitude to turn-start
      restored.currentAltitudes['p1'] = altBefore;
      restored.dartThrowWasBust['p1']!.add(true);

      expect(restored.currentAltitudes['p1'], altBefore);
      expect(restored.dartThrowWasBust['p1']!.last, true);
    });
  });
}
