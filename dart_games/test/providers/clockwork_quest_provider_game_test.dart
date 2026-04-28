import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/providers/clockwork_quest_provider.dart';
import 'package:dart_games/models/clockwork_quest_game.dart';
import 'package:dart_games/models/player.dart';
import '../shared/mock_api_helpers.dart';

void main() {
  late MockApiServer mockServer;
  late ClockworkQuestProvider provider;
  late List<Player> players;

  setUp(() {
    mockServer = MockApiServer();
    provider = ClockworkQuestProvider(apiClient: mockServer.apiClient);
    players = [
      Player(id: 'p1', name: 'Alice', createdAt: DateTime.now()),
      Player(id: 'p2', name: 'Bob', createdAt: DateTime.now()),
    ];
  });

  group('startGame', () {
    test('starts game with valid players and sets playing state', () {
      provider.startGame(players, false, false, 1);

      expect(provider.isGameActive, true);
      expect(provider.currentGame, isNotNull);
      expect(provider.currentGame!.state, ClockworkQuestGameState.playing);
      expect(provider.currentGame!.playerIds, ['p1', 'p2']);
      expect(provider.currentGame!.includeBullseye, false);
      expect(provider.currentGame!.speedMode, false);
      expect(provider.currentGame!.numberOfLaps, 1);
    });

    test('rejects fewer than 2 players', () {
      final solo = [Player(id: 'p1', name: 'Alice', createdAt: DateTime.now())];
      provider.startGame(solo, false, false, 1);

      expect(provider.currentGame, isNull);
      expect(provider.isGameActive, false);
    });

    test('rejects more than 8 players', () {
      final tooMany = List.generate(
        9,
        (i) => Player(id: 'p$i', name: 'Player $i', createdAt: DateTime.now()),
      );
      provider.startGame(tooMany, false, false, 1);

      expect(provider.currentGame, isNull);
      expect(provider.isGameActive, false);
    });

    test('assigns unique inventors to each player', () {
      final fourPlayers = List.generate(
        4,
        (i) => Player(id: 'p$i', name: 'Player $i', createdAt: DateTime.now()),
      );
      provider.startGame(fourPlayers, false, false, 1);

      final game = provider.currentGame!;
      final inventors = game.inventorAssignments.values.toSet();
      expect(inventors.length, 4);
      for (final pid in game.playerIds) {
        expect(game.inventorAssignments[pid], isNotNull);
      }
    });

    test('initializes all players with target 1, 0 laps, and 0 darts', () {
      provider.startGame(players, false, false, 1);
      final game = provider.currentGame!;

      for (final pid in game.playerIds) {
        expect(game.currentTarget[pid], 1);
        expect(game.lapsCompleted[pid], 0);
        expect(game.dartsThrown[pid], 0);
      }
    });

    test('sets maxTarget to 21 when includeBullseye is true', () {
      provider.startGame(players, true, false, 1);
      expect(provider.currentGame!.maxTarget, 21);
    });

    test('sets maxTarget to 20 when includeBullseye is false', () {
      provider.startGame(players, false, false, 1);
      expect(provider.currentGame!.maxTarget, 20);
    });
  });

  group('processDartThrow - normal mode', () {
    setUp(() {
      provider.startGame(players, false, false, 1);
    });

    test('hitting current target advances to next target', () {
      // Player starts at target 1
      expect(provider.getPlayerCurrentTarget('p1'), 1);

      provider.processDartThrow('S1');
      expect(provider.getPlayerCurrentTarget('p1'), 2);
    });

    test('missing does not advance target', () {
      provider.processDartThrow('Miss');
      expect(provider.getPlayerCurrentTarget('p1'), 1);
    });

    test('hitting wrong target does not advance', () {
      // Target is 1, but we hit 5
      provider.processDartThrow('S5');
      expect(provider.getPlayerCurrentTarget('p1'), 1);
    });

    test('None sector counts as a miss', () {
      provider.processDartThrow('None');
      expect(provider.getPlayerCurrentTarget('p1'), 1);
      expect(provider.getDartThrowHitTarget('p1'), [false]);
    });

    test('empty sector counts as a miss', () {
      provider.processDartThrow('');
      expect(provider.getPlayerCurrentTarget('p1'), 1);
      expect(provider.getDartThrowHitTarget('p1'), [false]);
    });

    test('parses single (S) sector correctly', () {
      provider.processDartThrow('S1');
      expect(provider.getDartThrowScoreValue('p1'), [1]);
      expect(provider.getDartThrowMultiplier('p1'), [1]);
    });

    test('parses double (D) sector correctly', () {
      provider.processDartThrow('D1');
      expect(provider.getDartThrowScoreValue('p1'), [1]);
      expect(provider.getDartThrowMultiplier('p1'), [2]);
      // D1 still hits target 1 (number matches)
      expect(provider.getDartThrowAdvanced('p1'), [true]);
    });

    test('parses triple (T) sector correctly', () {
      provider.processDartThrow('T1');
      expect(provider.getDartThrowScoreValue('p1'), [1]);
      expect(provider.getDartThrowMultiplier('p1'), [3]);
      expect(provider.getDartThrowAdvanced('p1'), [true]);
    });

    test('parses Bull sector as number 25', () {
      // Bull won't advance because target is 1, but parsing should work
      provider.processDartThrow('Bull');
      expect(provider.getDartThrowScoreValue('p1'), [25]);
      expect(provider.getDartThrowMultiplier('p1'), [1]);
    });

    test('parses DBull sector as number 25 multiplier 2', () {
      provider.processDartThrow('DBull');
      expect(provider.getDartThrowScoreValue('p1'), [25]);
      expect(provider.getDartThrowMultiplier('p1'), [2]);
    });
  });

  group('processDartThrow - speed mode', () {
    setUp(() {
      provider.startGame(players, false, true, 1);
    });

    test('hitting any uncompleted target counts', () {
      // In speed mode, any number 1-20 should count
      provider.processDartThrow('S10');
      expect(provider.getDartThrowAdvanced('p1'), [true]);
      expect(provider.getPlayerCompletedTargets('p1'), contains(10));
    });

    test('hitting already-completed target does not count', () {
      provider.processDartThrow('S10');
      expect(provider.getDartThrowAdvanced('p1'), [true]);

      // Advance turn so darts reset, then come back to p1
      provider.advanceTurn();
      provider.advanceTurn();

      // Now try hitting 10 again — already completed
      provider.processDartThrow('S10');
      expect(provider.getDartThrowAdvanced('p1'), [false]);
    });

    test('can hit targets in any order', () {
      provider.processDartThrow('S15');
      provider.processDartThrow('S3');
      provider.processDartThrow('S8');

      final completed = provider.getPlayerCompletedTargets('p1');
      expect(completed, containsAll([15, 3, 8]));
    });
  });

  group('target advancement and laps', () {
    test('completing target 20 finishes a lap (no bullseye)', () {
      provider.startGame(players, false, false, 1);

      // Advance player through all 20 targets
      for (int target = 1; target <= 20; target++) {
        provider.processDartThrow('S$target');
        if (provider.getCurrentPlayerDartsThrown() >= 3) {
          provider.advanceTurn(); // Bob's turn
          provider.advanceTurn(); // Back to Alice
        }
      }

      expect(provider.getPlayerLapsCompleted('p1'), 1);
    });

    test('completing target 21 (bullseye) finishes a lap with bullseye', () {
      provider.startGame(players, true, false, 1);

      // Advance player through all 21 targets (1-20 + bullseye=21)
      for (int target = 1; target <= 20; target++) {
        provider.processDartThrow('S$target');
        if (provider.getCurrentPlayerDartsThrown() >= 3) {
          provider.advanceTurn();
          provider.advanceTurn();
        }
      }
      // Target 21 is hit with Bull
      if (provider.getCurrentPlayerDartsThrown() >= 3) {
        provider.advanceTurn();
        provider.advanceTurn();
      }
      provider.processDartThrow('Bull');

      expect(provider.getPlayerLapsCompleted('p1'), 1);
    });

    test('multi-lap game requires completing all laps to win', () {
      provider.startGame(players, false, false, 2);

      // Complete lap 1 — go through all 20 targets
      for (int target = 1; target <= 20; target++) {
        provider.processDartThrow('S$target');
        if (provider.getCurrentPlayerDartsThrown() >= 3) {
          provider.advanceTurn();
          provider.advanceTurn();
        }
      }

      expect(provider.getPlayerLapsCompleted('p1'), 1);
      expect(provider.hasWinner, false);

      // Complete lap 2
      for (int target = 1; target <= 20; target++) {
        if (provider.getCurrentPlayerId() != 'p1') {
          provider.advanceTurn();
        }
        provider.processDartThrow('S$target');
        if (provider.getCurrentPlayerDartsThrown() >= 3) {
          provider.advanceTurn();
          provider.advanceTurn();
        }
      }

      expect(provider.getPlayerLapsCompleted('p1'), 2);
      expect(provider.hasWinner, true);
      expect(provider.currentGame!.winnerId, 'p1');
    });

    test('completing required laps sets finished state', () {
      provider.startGame(players, false, false, 1);

      for (int target = 1; target <= 20; target++) {
        provider.processDartThrow('S$target');
        if (provider.getCurrentPlayerDartsThrown() >= 3) {
          provider.advanceTurn();
          provider.advanceTurn();
        }
      }

      expect(provider.currentGame!.state, ClockworkQuestGameState.finished);
      expect(provider.currentGame!.winnerId, 'p1');
    });
  });

  group('turn management', () {
    setUp(() {
      provider.startGame(players, false, false, 1);
    });

    test('advanceTurn increments totalTurns for current player', () {
      expect(provider.currentGame!.totalTurns['p1'], 0);

      provider.advanceTurn();
      expect(provider.currentGame!.totalTurns['p1'], 1);
    });

    test('advanceTurn moves to next player', () {
      expect(provider.getCurrentPlayerId(), 'p1');

      provider.advanceTurn();
      expect(provider.getCurrentPlayerId(), 'p2');
    });

    test('advanceTurn wraps around to first player', () {
      provider.advanceTurn(); // p1 -> p2
      provider.advanceTurn(); // p2 -> p1

      expect(provider.getCurrentPlayerId(), 'p1');
    });

    test('3-dart limit triggers waitingForTakeout', () {
      provider.processDartThrow('Miss');
      provider.processDartThrow('Miss');
      expect(provider.shouldPromptTakeout, false);

      provider.processDartThrow('Miss');
      expect(provider.shouldPromptTakeout, true);
    });

    test('processDartThrow is ignored when waitingForTakeout', () {
      // Throw 3 darts to trigger takeout
      provider.processDartThrow('Miss');
      provider.processDartThrow('Miss');
      provider.processDartThrow('Miss');
      expect(provider.shouldPromptTakeout, true);

      // This should be ignored
      provider.processDartThrow('S1');
      expect(provider.getPlayerCurrentTarget('p1'), 1);
      expect(provider.getCurrentPlayerDartsThrown(), 3);
    });

    test('confirmDartsRemoved clears takeout and advances turn', () {
      provider.processDartThrow('Miss');
      provider.processDartThrow('Miss');
      provider.processDartThrow('Miss');
      expect(provider.shouldPromptTakeout, true);

      provider.confirmDartsRemoved();
      expect(provider.shouldPromptTakeout, false);
      expect(provider.getCurrentPlayerId(), 'p2');
    });
  });

  group('skipTurn', () {
    setUp(() {
      provider.startGame(players, false, false, 1);
    });

    test('skipping with 0 darts thrown adds 3 skip markers', () {
      provider.skipTurn();

      // Skip now sets waitingForTakeout; confirm to advance
      expect(provider.shouldPromptTakeout, true);
      provider.confirmDartsRemoved();
      expect(provider.getCurrentPlayerId(), 'p2');
    });

    test('skipping after 1 dart adds 2 skip markers and advances', () {
      provider.processDartThrow('Miss');
      provider.skipTurn();

      expect(provider.shouldPromptTakeout, true);
      provider.confirmDartsRemoved();
      expect(provider.getCurrentPlayerId(), 'p2');
    });

    test('cannot skip when waitingForTakeout', () {
      provider.processDartThrow('Miss');
      provider.processDartThrow('Miss');
      provider.processDartThrow('Miss');
      expect(provider.shouldPromptTakeout, true);

      provider.skipTurn(); // Should not skip
      // Still on same player since skip was blocked, takeout still pending
      expect(provider.shouldPromptTakeout, true);
    });
  });

  group('editScore', () {
    setUp(() {
      provider.startGame(players, false, false, 1);
    });

    test('restores to turn start state and replays new throws', () {
      // Throw 2 darts — hit target 1 and 2
      provider.processDartThrow('S1');
      provider.processDartThrow('S2');
      expect(provider.getPlayerCurrentTarget('p1'), 3);

      // Edit: replace with misses
      provider.editScore([
        {'sector': 'Miss'},
        {'sector': 'Miss'},
      ]);

      // After edit, target should be back to 1 (start of turn)
      expect(provider.getPlayerCurrentTarget('p1'), 1);
      expect(provider.getCurrentPlayerDartsThrown(), 2);
    });

    test('editScore clears waitingForTakeout', () {
      provider.processDartThrow('S1');
      provider.processDartThrow('S2');
      provider.processDartThrow('S3');
      expect(provider.shouldPromptTakeout, true);

      // Edit with fewer darts — takeout should clear
      provider.editScore([
        {'sector': 'Miss'},
      ]);
      expect(provider.shouldPromptTakeout, false);
      expect(provider.getCurrentPlayerDartsThrown(), 1);
    });

    test('editScore can change hits to different targets', () {
      provider.processDartThrow('S1');
      expect(provider.getPlayerCurrentTarget('p1'), 2);

      // Edit: change to hitting a wrong target
      provider.editScore([
        {'sector': 'S5'},
      ]);

      // Target should still be 1 since S5 doesn't match target 1
      expect(provider.getPlayerCurrentTarget('p1'), 1);
    });
  });

  group('win conditions', () {
    test('single lap win sets winnerId and finished state', () {
      provider.startGame(players, false, false, 1);

      for (int target = 1; target <= 20; target++) {
        provider.processDartThrow('S$target');
        if (target < 20 && provider.getCurrentPlayerDartsThrown() >= 3) {
          provider.advanceTurn();
          provider.advanceTurn();
        }
      }

      expect(provider.hasWinner, true);
      expect(provider.currentGame!.winnerId, 'p1');
      expect(provider.currentGame!.state, ClockworkQuestGameState.finished);
    });

    test('speed mode win after completing all targets', () {
      provider.startGame(players, false, true, 1);

      // Hit all 20 targets in random order
      for (int target = 20; target >= 1; target--) {
        if (provider.getCurrentPlayerId() != 'p1') {
          // Skip until it's p1's turn
          provider.advanceTurn();
        }
        provider.processDartThrow('S$target');
        if (provider.getCurrentPlayerDartsThrown() >= 3 && target > 1) {
          provider.advanceTurn();
          provider.advanceTurn();
        }
      }

      expect(provider.hasWinner, true);
      expect(provider.currentGame!.winnerId, 'p1');
    });
  });

  group('clearGame and endGame', () {
    setUp(() {
      provider.startGame(players, false, false, 1);
    });

    test('endGame sets state to finished', () {
      provider.endGame();
      expect(provider.currentGame!.state, ClockworkQuestGameState.finished);
      expect(provider.isGameActive, false);
    });

    test('clearGame nullifies all game state', () {
      provider.clearGame();
      expect(provider.currentGame, isNull);
      expect(provider.isGameActive, false);
      expect(provider.shouldPromptTakeout, false);
    });

    test('clearGame resets resumedSavedGameId', () {
      provider.clearGame();
      expect(provider.resumedSavedGameId, isNull);
    });
  });

  group('dart tracking arrays', () {
    setUp(() {
      provider.startGame(players, false, false, 1);
    });

    test('dartThrowHitTarget is true when target is hit', () {
      provider.processDartThrow('S1'); // hit target 1
      expect(provider.getDartThrowHitTarget('p1'), [true]);
    });

    test('dartThrowHitTarget is false on miss', () {
      provider.processDartThrow('Miss');
      expect(provider.getDartThrowHitTarget('p1'), [false]);
    });

    test('dartThrowAdvanced is true when target advances', () {
      provider.processDartThrow('S1');
      expect(provider.getDartThrowAdvanced('p1'), [true]);
    });

    test('dartThrowAdvanced is false when target does not advance', () {
      provider.processDartThrow('S5'); // wrong target
      expect(provider.getDartThrowAdvanced('p1'), [false]);
    });

    test('dartThrowCompletedLap is true when lap completes', () {
      provider.startGame(players, false, false, 1);

      // Go through all 20 targets
      for (int target = 1; target <= 20; target++) {
        provider.processDartThrow('S$target');
        if (target < 20 && provider.getCurrentPlayerDartsThrown() >= 3) {
          provider.advanceTurn();
          provider.advanceTurn();
        }
      }

      // The last dart should have completedLap = true
      final completedLap = provider.getDartThrowCompletedLap('p1');
      expect(completedLap.last, true);
    });

    test('dartThrowCompletedLap is false during normal play', () {
      provider.processDartThrow('S1');
      expect(provider.getDartThrowCompletedLap('p1'), [false]);
    });

    test('multiple darts track correctly in sequence', () {
      provider.processDartThrow('S1'); // hit target 1
      provider.processDartThrow('S5'); // wrong (target is now 2)
      provider.processDartThrow('S2'); // hit target 2

      expect(provider.getDartThrowHitTarget('p1'), [true, false, true]);
      expect(provider.getDartThrowAdvanced('p1'), [true, false, true]);
      expect(provider.getDartThrowScoreValue('p1'), [1, 5, 2]);
      expect(provider.getDartThrowMultiplier('p1'), [1, 1, 1]);
    });

    test('advanceTurn clears dart tracking arrays for current player', () {
      provider.processDartThrow('S1');
      expect(provider.getDartThrowHitTarget('p1').length, 1);

      provider.advanceTurn();

      // After advance, p1's tracking arrays should be cleared
      expect(provider.getDartThrowHitTarget('p1'), isEmpty);
      expect(provider.getDartThrowScoreValue('p1'), isEmpty);
      expect(provider.getDartThrowAdvanced('p1'), isEmpty);
    });
  });
}
