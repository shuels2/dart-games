import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/models/clockwork_quest_game.dart';

void main() {
  group('ClockworkQuestGame serialization', () {
    ClockworkQuestGame _createGameWithState() {
      final game = ClockworkQuestGame(
        id: 'test-game-123',
        startedAt: DateTime(2026, 4, 14, 10, 30),
        maxDartsPerTurn: 3,
        includeBullseye: true,
        speedMode: false,
        numberOfLaps: 2,
        playerIds: ['p1', 'p2', 'p3'],
        inventorAssignments: {
          'p1': ClockworkInventor.cogsworthOwl,
          'p2': ClockworkInventor.sprocketRabbit,
          'p3': ClockworkInventor.tickerHedgehog,
        },
        state: ClockworkQuestGameState.playing,
        currentPlayerIndex: 1,
      );

      // Simulate gameplay state for p1
      game.currentTarget['p1'] = 5;
      game.lapsCompleted['p1'] = 1;
      game.dartsThrown['p1'] = 2;
      game.currentTurnDarts['p1'] = ['S5', 'Miss'];
      game.dartThrowHitTarget['p1'] = [true, false];
      game.dartThrowScoreValue['p1'] = [5, 0];
      game.dartThrowMultiplier['p1'] = [1, 0];
      game.dartThrowTargetNumber['p1'] = [5, 6];
      game.dartThrowAdvanced['p1'] = [true, false];
      game.dartThrowCompletedLap['p1'] = [false, false];
      game.totalDartsThrown['p1'] = 12;
      game.totalTurns['p1'] = 4;
      game.completedTargets['p1'] = [1, 2, 3, 4];

      // p2 state
      game.currentTarget['p2'] = 3;
      game.lapsCompleted['p2'] = 0;
      game.totalDartsThrown['p2'] = 8;
      game.totalTurns['p2'] = 3;
      game.completedTargets['p2'] = [1, 2];

      // Turn start snapshots
      game.turnStartCurrentTarget = {'p1': 4, 'p2': 3, 'p3': 1};
      game.turnStartLapsCompleted = {'p1': 1, 'p2': 0, 'p3': 0};
      game.turnStartState = ClockworkQuestGameState.playing;
      game.turnStartWinnerId = null;
      game.turnStartCompletedTargets = {
        'p1': [1, 2, 3],
        'p2': [1, 2],
        'p3': [],
      };

      return game;
    }

    test('toJson includes all fields', () {
      final game = _createGameWithState();
      final json = game.toJson();

      expect(json['id'], 'test-game-123');
      expect(json['startedAt'], game.startedAt.toIso8601String());
      expect(json['maxDartsPerTurn'], 3);
      expect(json['includeBullseye'], true);
      expect(json['speedMode'], false);
      expect(json['numberOfLaps'], 2);
      expect(json['playerIds'], ['p1', 'p2', 'p3']);
      expect(json['inventorAssignments'], isA<Map>());
      expect(json['state'], 'playing');
      expect(json['currentPlayerIndex'], 1);
      expect(json['currentTarget'], isA<Map>());
      expect(json['lapsCompleted'], isA<Map>());
      expect(json['dartsThrown'], isA<Map>());
      expect(json['currentTurnDarts'], isA<Map>());
      expect(json['dartThrowHitTarget'], isA<Map>());
      expect(json['dartThrowScoreValue'], isA<Map>());
      expect(json['dartThrowMultiplier'], isA<Map>());
      expect(json['dartThrowTargetNumber'], isA<Map>());
      expect(json['dartThrowAdvanced'], isA<Map>());
      expect(json['dartThrowCompletedLap'], isA<Map>());
      expect(json['totalDartsThrown'], isA<Map>());
      expect(json['totalTurns'], isA<Map>());
      expect(json['winnerId'], isNull);
      expect(json['completedTargets'], isA<Map>());
      expect(json['turnStartCompletedTargets'], isA<Map>());
      expect(json['turnStartCurrentTarget'], isA<Map>());
      expect(json['turnStartLapsCompleted'], isA<Map>());
      expect(json['turnStartState'], 'playing');
      expect(json['turnStartWinnerId'], isNull);
    });

    test('toJson serializes enums as .name strings', () {
      final game = _createGameWithState();
      final json = game.toJson();

      expect(json['state'], 'playing');
      expect(json['turnStartState'], 'playing');
      for (final value in (json['inventorAssignments'] as Map).values) {
        expect(
          ClockworkInventor.values.any((e) => e.toString().split('.').last == value),
          true,
        );
      }
    });

    test('toJson serializes inventor assignments correctly', () {
      final game = _createGameWithState();
      final json = game.toJson();

      final assignments = json['inventorAssignments'] as Map;
      expect(assignments['p1'], 'cogsworthOwl');
      expect(assignments['p2'], 'sprocketRabbit');
      expect(assignments['p3'], 'tickerHedgehog');
    });

    test('fromJson restores all basic fields', () {
      final original = _createGameWithState();
      final json = original.toJson();
      final restored = ClockworkQuestGame.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.startedAt, original.startedAt);
      expect(restored.maxDartsPerTurn, original.maxDartsPerTurn);
      expect(restored.includeBullseye, original.includeBullseye);
      expect(restored.speedMode, original.speedMode);
      expect(restored.numberOfLaps, original.numberOfLaps);
      expect(restored.playerIds, original.playerIds);
      expect(restored.state, original.state);
      expect(restored.currentPlayerIndex, original.currentPlayerIndex);
      expect(restored.winnerId, original.winnerId);
    });

    test('fromJson restores inventor assignments', () {
      final original = _createGameWithState();
      final json = original.toJson();
      final restored = ClockworkQuestGame.fromJson(json);

      expect(restored.inventorAssignments, original.inventorAssignments);
    });

    test('fromJson restores per-player progress maps', () {
      final original = _createGameWithState();
      final json = original.toJson();
      final restored = ClockworkQuestGame.fromJson(json);

      for (final playerId in original.playerIds) {
        expect(restored.currentTarget[playerId], original.currentTarget[playerId]);
        expect(restored.lapsCompleted[playerId], original.lapsCompleted[playerId]);
        expect(restored.dartsThrown[playerId], original.dartsThrown[playerId]);
      }
    });

    test('round-trip preserves totalDartsThrown and totalTurns', () {
      final original = _createGameWithState();
      final json = original.toJson();
      final restored = ClockworkQuestGame.fromJson(json);

      expect(restored.totalDartsThrown['p1'], 12);
      expect(restored.totalDartsThrown['p2'], 8);
      expect(restored.totalTurns['p1'], 4);
      expect(restored.totalTurns['p2'], 3);
    });

    test('round-trip preserves dart throw tracking arrays', () {
      final original = _createGameWithState();
      final json = original.toJson();
      final restored = ClockworkQuestGame.fromJson(json);

      for (final playerId in original.playerIds) {
        expect(restored.dartThrowHitTarget[playerId],
            original.dartThrowHitTarget[playerId]);
        expect(restored.dartThrowScoreValue[playerId],
            original.dartThrowScoreValue[playerId]);
        expect(restored.dartThrowMultiplier[playerId],
            original.dartThrowMultiplier[playerId]);
        expect(restored.dartThrowTargetNumber[playerId],
            original.dartThrowTargetNumber[playerId]);
        expect(restored.dartThrowAdvanced[playerId],
            original.dartThrowAdvanced[playerId]);
        expect(restored.dartThrowCompletedLap[playerId],
            original.dartThrowCompletedLap[playerId]);
      }
    });

    test('round-trip preserves currentTurnDarts', () {
      final original = _createGameWithState();
      final json = original.toJson();
      final restored = ClockworkQuestGame.fromJson(json);

      expect(restored.currentTurnDarts['p1'], ['S5', 'Miss']);
    });

    test('round-trip preserves completedTargets', () {
      final original = _createGameWithState();
      final json = original.toJson();
      final restored = ClockworkQuestGame.fromJson(json);

      expect(restored.completedTargets['p1'], [1, 2, 3, 4]);
      expect(restored.completedTargets['p2'], [1, 2]);
      expect(restored.completedTargets['p3'], isEmpty);
    });

    test('round-trip preserves turn start state', () {
      final original = _createGameWithState();
      final json = original.toJson();
      final restored = ClockworkQuestGame.fromJson(json);

      expect(restored.turnStartCurrentTarget, original.turnStartCurrentTarget);
      expect(restored.turnStartLapsCompleted, original.turnStartLapsCompleted);
      expect(restored.turnStartState, original.turnStartState);
      expect(restored.turnStartWinnerId, original.turnStartWinnerId);
      for (final playerId in original.playerIds) {
        expect(restored.turnStartCompletedTargets[playerId],
            original.turnStartCompletedTargets[playerId]);
      }
    });

    test('round-trip with null winner', () {
      final game = ClockworkQuestGame(
        id: 'no-winner-game',
        startedAt: DateTime(2026, 4, 14),
        maxDartsPerTurn: 3,
        includeBullseye: false,
        speedMode: true,
        numberOfLaps: 1,
        playerIds: ['p1', 'p2'],
        inventorAssignments: {
          'p1': ClockworkInventor.gizmoFox,
          'p2': ClockworkInventor.pistonCat,
        },
      );
      final json = game.toJson();
      final restored = ClockworkQuestGame.fromJson(json);

      expect(restored.winnerId, isNull);
      expect(restored.turnStartWinnerId, isNull);
      expect(restored.speedMode, true);
      expect(restored.includeBullseye, false);
    });

    test('round-trip with winner set', () {
      final game = _createGameWithState();
      game.winnerId = 'p1';
      game.state = ClockworkQuestGameState.finished;
      game.turnStartWinnerId = 'p1';
      game.turnStartState = ClockworkQuestGameState.finished;

      final json = game.toJson();
      final restored = ClockworkQuestGame.fromJson(json);

      expect(restored.winnerId, 'p1');
      expect(restored.state, ClockworkQuestGameState.finished);
      expect(restored.turnStartWinnerId, 'p1');
      expect(restored.turnStartState, ClockworkQuestGameState.finished);
    });

    test('round-trip with speed mode enabled', () {
      final game = ClockworkQuestGame(
        id: 'speed-game',
        startedAt: DateTime(2026, 4, 14),
        maxDartsPerTurn: 3,
        includeBullseye: false,
        speedMode: true,
        numberOfLaps: 3,
        playerIds: ['p1', 'p2'],
        inventorAssignments: {
          'p1': ClockworkInventor.rivetBadger,
          'p2': ClockworkInventor.boilerBear,
        },
        state: ClockworkQuestGameState.playing,
      );
      // In speed mode, completedTargets tracks which gears are done
      game.completedTargets['p1'] = [5, 12, 3];
      game.completedTargets['p2'] = [20, 1];

      final json = game.toJson();
      final restored = ClockworkQuestGame.fromJson(json);

      expect(restored.speedMode, true);
      expect(restored.completedTargets['p1'], [5, 12, 3]);
      expect(restored.completedTargets['p2'], [20, 1]);
    });

    test('round-trip with bullseye mode (maxTarget 21)', () {
      final game = ClockworkQuestGame(
        id: 'bullseye-game',
        startedAt: DateTime(2026, 4, 14),
        maxDartsPerTurn: 3,
        includeBullseye: true,
        speedMode: false,
        numberOfLaps: 1,
        playerIds: ['p1'],
        inventorAssignments: {
          'p1': ClockworkInventor.whistleMouse,
        },
        state: ClockworkQuestGameState.playing,
      );
      game.currentTarget['p1'] = 21; // On bullseye target
      final json = game.toJson();
      final restored = ClockworkQuestGame.fromJson(json);

      expect(restored.includeBullseye, true);
      expect(restored.maxTarget, 21);
      expect(restored.currentTarget['p1'], 21);
    });

    test('round-trip with all inventor types', () {
      final playerIds = List.generate(8, (i) => 'p${i + 1}');
      final assignments = <String, ClockworkInventor>{};
      for (int i = 0; i < 8; i++) {
        assignments['p${i + 1}'] = ClockworkInventor.values[i];
      }

      final game = ClockworkQuestGame(
        id: 'all-inventors',
        startedAt: DateTime(2026, 4, 14),
        maxDartsPerTurn: 3,
        includeBullseye: false,
        speedMode: false,
        numberOfLaps: 1,
        playerIds: playerIds,
        inventorAssignments: assignments,
      );
      final json = game.toJson();
      final restored = ClockworkQuestGame.fromJson(json);

      for (int i = 0; i < 8; i++) {
        expect(restored.inventorAssignments['p${i + 1}'],
            ClockworkInventor.values[i]);
      }
    });

    test('gameplay continues correctly after restore', () {
      final original = _createGameWithState();
      final json = original.toJson();
      final restored = ClockworkQuestGame.fromJson(json);

      // Verify game can be modified after restore
      final currentPlayer = restored.currentPlayerId;
      final dartsBefore = restored.dartsThrown[currentPlayer]!;
      restored.dartsThrown[currentPlayer] = dartsBefore + 1;
      restored.totalDartsThrown[currentPlayer] =
          (restored.totalDartsThrown[currentPlayer] ?? 0) + 1;

      expect(restored.dartsThrown[currentPlayer], dartsBefore + 1);
    });

    test('round-trip with empty tracking arrays', () {
      final game = ClockworkQuestGame(
        id: 'fresh-game',
        startedAt: DateTime(2026, 4, 14),
        maxDartsPerTurn: 3,
        includeBullseye: false,
        speedMode: false,
        numberOfLaps: 1,
        playerIds: ['p1', 'p2'],
        inventorAssignments: {
          'p1': ClockworkInventor.cogsworthOwl,
          'p2': ClockworkInventor.sprocketRabbit,
        },
      );
      final json = game.toJson();
      final restored = ClockworkQuestGame.fromJson(json);

      expect(restored.dartThrowHitTarget['p1'], isEmpty);
      expect(restored.dartThrowScoreValue['p1'], isEmpty);
      expect(restored.currentTurnDarts['p1'], isEmpty);
      expect(restored.completedTargets['p1'], isEmpty);
      expect(restored.dartsThrown['p1'], 0);
      expect(restored.totalDartsThrown['p1'], 0);
      expect(restored.totalTurns['p1'], 0);
    });

    test('all game states serialize correctly', () {
      for (final state in ClockworkQuestGameState.values) {
        final game = ClockworkQuestGame(
          id: 'state-test-${state.name}',
          startedAt: DateTime(2026, 4, 14),
          maxDartsPerTurn: 3,
          includeBullseye: false,
          speedMode: false,
          numberOfLaps: 1,
          playerIds: ['p1'],
          inventorAssignments: {'p1': ClockworkInventor.cogsworthOwl},
          state: state,
        );
        final json = game.toJson();
        final restored = ClockworkQuestGame.fromJson(json);
        expect(restored.state, state);
      }
    });
  });
}
