import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/models/clockwork_quest_game.dart';
import 'package:dart_games/models/player.dart';
import 'package:dart_games/providers/clockwork_quest_provider.dart';

void main() {
  // ─── Helper to create a standard 2-player game ───
  ClockworkQuestGame createGame({
    List<String>? playerIds,
    bool includeBullseye = false,
    bool speedMode = false,
    int numberOfLaps = 1,
  }) {
    final ids = playerIds ?? ['p1', 'p2'];
    final inventorAssignments = <String, ClockworkInventor>{};
    for (int i = 0; i < ids.length; i++) {
      inventorAssignments[ids[i]] = ClockworkInventor.values[i];
    }

    return ClockworkQuestGame(
      id: 'test-game',
      startedAt: DateTime.now(),
      maxDartsPerTurn: 3,
      includeBullseye: includeBullseye,
      speedMode: speedMode,
      numberOfLaps: numberOfLaps,
      playerIds: ids,
      inventorAssignments: inventorAssignments,
      state: ClockworkQuestGameState.playing,
      currentPlayerIndex: 0,
    );
  }

  List<Player> createPlayers(int count) {
    return List.generate(
      count,
      (i) => Player(
        id: 'p${i + 1}',
        name: 'Player ${i + 1}',
        createdAt: DateTime.now(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // Model Tests
  // ═══════════════════════════════════════════════════
  group('ClockworkQuestGame Model', () {
    test('creates game with correct initial state', () {
      final game = createGame();
      expect(game.state, ClockworkQuestGameState.playing);
      expect(game.playerIds, ['p1', 'p2']);
      expect(game.currentPlayerIndex, 0);
      expect(game.currentPlayerId, 'p1');
      expect(game.maxDartsPerTurn, 3);
      expect(game.includeBullseye, false);
      expect(game.speedMode, false);
      expect(game.numberOfLaps, 1);
    });

    test('initializes all players at target 1', () {
      final game = createGame();
      expect(game.currentTarget['p1'], 1);
      expect(game.currentTarget['p2'], 1);
      expect(game.lapsCompleted['p1'], 0);
      expect(game.lapsCompleted['p2'], 0);
    });

    test('speed mode uses 3 darts per turn like normal mode', () {
      final game = createGame(speedMode: true);
      expect(game.maxDartsPerTurn, 3);
    });

    test('includeBullseye sets maxTarget to 21', () {
      final game = createGame(includeBullseye: true);
      expect(game.maxTarget, 21);
    });

    test('without bullseye, maxTarget is 20', () {
      final game = createGame(includeBullseye: false);
      expect(game.maxTarget, 20);
    });

    test('copyWith creates a new instance with updated fields', () {
      final game = createGame();
      final copy = game.copyWith(state: ClockworkQuestGameState.finished);
      expect(copy.state, ClockworkQuestGameState.finished);
      expect(game.state, ClockworkQuestGameState.playing);
    });

    test('toJson/fromJson serialization roundtrip', () {
      final game = createGame(
        includeBullseye: true,
        speedMode: true,
        numberOfLaps: 3,
      );
      final json = game.toJson();
      final restored = ClockworkQuestGame.fromJson(json);

      expect(restored.id, game.id);
      expect(restored.playerIds, game.playerIds);
      expect(restored.includeBullseye, game.includeBullseye);
      expect(restored.speedMode, game.speedMode);
      expect(restored.numberOfLaps, game.numberOfLaps);
      expect(restored.maxDartsPerTurn, game.maxDartsPerTurn);
      expect(restored.state, game.state);
    });
  });

  // ═══════════════════════════════════════════════════
  // Provider Tests
  // ═══════════════════════════════════════════════════
  group('ClockworkQuestProvider', () {
    test('startGame creates a new game', () {
      final provider = ClockworkQuestProvider();
      final players = createPlayers(2);

      provider.startGame(players, false, false, 1);

      expect(provider.currentGame, isNotNull);
      expect(provider.isGameActive, true);
      expect(provider.currentGame!.playerIds, ['p1', 'p2']);
    });

    test('startGame with speed mode', () {
      final provider = ClockworkQuestProvider();
      final players = createPlayers(2);

      provider.startGame(players, false, true, 1);

      expect(provider.currentGame!.speedMode, true);
      expect(provider.currentGame!.maxDartsPerTurn, 3);
    });

    test('startGame with bullseye option', () {
      final provider = ClockworkQuestProvider();
      final players = createPlayers(2);

      provider.startGame(players, true, false, 1);

      expect(provider.currentGame!.includeBullseye, true);
      expect(provider.currentGame!.maxTarget, 21);
    });

    test('startGame requires at least 2 players', () {
      final provider = ClockworkQuestProvider();
      final players = createPlayers(1);

      provider.startGame(players, false, false, 1);

      expect(provider.currentGame, isNull);
    });

    test('startGame rejects more than 8 players', () {
      final provider = ClockworkQuestProvider();
      final players = createPlayers(9);

      provider.startGame(players, false, false, 1);

      expect(provider.currentGame, isNull);
    });

    test('processDartThrow handles miss', () {
      final provider = ClockworkQuestProvider();
      final players = createPlayers(2);
      provider.startGame(players, false, false, 1);

      provider.processDartThrow('Miss');

      final currentPlayerId = provider.getCurrentPlayerId()!;
      expect(provider.getCurrentPlayerDartsThrown(), 1);
      expect(provider.getDartThrowHitTarget(currentPlayerId), [false]);
      expect(provider.getDartThrowScoreValue(currentPlayerId), [0]);
      expect(provider.getPlayerCurrentTarget(currentPlayerId), 1); // Still on 1
    });

    test('processDartThrow advances target on hit', () {
      final provider = ClockworkQuestProvider();
      final players = createPlayers(2);
      provider.startGame(players, false, false, 1);

      provider.processDartThrow('S1'); // Hit target 1

      final currentPlayerId = provider.getCurrentPlayerId()!;
      expect(provider.getDartThrowHitTarget(currentPlayerId), [true]);
      expect(provider.getDartThrowAdvanced(currentPlayerId), [true]);
      expect(provider.getPlayerCurrentTarget(currentPlayerId), 2); // Advanced to 2
    });

    test('processDartThrow does not advance on wrong target', () {
      final provider = ClockworkQuestProvider();
      final players = createPlayers(2);
      provider.startGame(players, false, false, 1);

      provider.processDartThrow('S5'); // Wrong target

      final currentPlayerId = provider.getCurrentPlayerId()!;
      expect(provider.getDartThrowHitTarget(currentPlayerId), [false]);
      expect(provider.getDartThrowAdvanced(currentPlayerId), [false]);
      expect(provider.getPlayerCurrentTarget(currentPlayerId), 1); // Still on 1
    });

    test('doubles and triples on target number count as a hit', () {
      final provider = ClockworkQuestProvider();
      final players = createPlayers(2);
      provider.startGame(players, false, false, 1);

      provider.processDartThrow('D1'); // Double 1 — counts, advances 1
      provider.processDartThrow('T2'); // Triple 2 — counts, advances 1

      final currentPlayerId = provider.getCurrentPlayerId()!;
      expect(provider.getDartThrowHitTarget(currentPlayerId), [true, true]);
      expect(provider.getDartThrowAdvanced(currentPlayerId), [true, true]);
      expect(provider.getPlayerCurrentTarget(currentPlayerId), 3);
    });

    test('speed mode: any uncompleted gear number registers a hit', () {
      final provider = ClockworkQuestProvider();
      final players = createPlayers(2);
      provider.startGame(players, false, true, 1); // speed mode

      final pid = provider.getCurrentPlayerId()!;
      provider.processDartThrow('S7'); // Hit 7 first (out of order)

      expect(provider.getDartThrowHitTarget(pid), [true]);
      expect(provider.getDartThrowAdvanced(pid), [true]);
      expect(provider.getPlayerCompletedTargets(pid), [7]);
    });

    test('speed mode: hitting an already-activated gear does not count', () {
      final provider = ClockworkQuestProvider();
      final players = createPlayers(2);
      provider.startGame(players, false, true, 1);

      final pid = provider.getCurrentPlayerId()!;
      provider.processDartThrow('S7');
      provider.processDartThrow('S7'); // Hit 7 again

      expect(provider.getDartThrowHitTarget(pid), [true, false]);
      expect(provider.getPlayerCompletedTargets(pid), [7]); // Still only one 7
    });

    test('speed mode: completing all gears in any order completes a lap', () {
      final provider = ClockworkQuestProvider();
      final players = createPlayers(2);
      provider.startGame(players, false, true, 1);

      final pid = provider.getCurrentPlayerId()!;

      // Hit all 20 in reverse order
      for (int i = 20; i >= 1; i--) {
        provider.processDartThrow('S$i');
        if (provider.shouldPromptTakeout) {
          provider.confirmDartsRemoved(); // advance to p2
          provider.skipTurn(); // p2 skips
        }
      }

      expect(provider.getPlayerLapsCompleted(pid), 1);
      expect(provider.hasWinner, true);
    });

    test('speed mode: wrong sector (e.g. out of range) does not count', () {
      final provider = ClockworkQuestProvider();
      final players = createPlayers(2);
      provider.startGame(players, false, true, 1);

      final pid = provider.getCurrentPlayerId()!;
      provider.processDartThrow('Miss'); // Miss

      expect(provider.getDartThrowHitTarget(pid), [false]);
      expect(provider.getPlayerCompletedTargets(pid), isEmpty);
    });

    test('completing a lap resets target to 1', () {
      final provider = ClockworkQuestProvider();
      final players = createPlayers(2);
      provider.startGame(players, false, false, 1); // normal mode

      final currentPlayerId = provider.getCurrentPlayerId()!;

      // Hit all targets 1-20: one hit per turn, skip remaining darts, skip p2
      for (int i = 1; i <= 20; i++) {
        provider.processDartThrow('S$i');
        provider.skipTurn(); // p1 done, advances to p2
        provider.skipTurn(); // p2 skips, back to p1
      }

      expect(provider.getPlayerCurrentTarget(currentPlayerId), 1);
      expect(provider.getPlayerLapsCompleted(currentPlayerId), 1);
    });

    test('completing required laps wins the game', () {
      final provider = ClockworkQuestProvider();
      final players = createPlayers(2);
      provider.startGame(players, false, false, 1); // 1 lap to win

      final currentPlayerId = provider.getCurrentPlayerId()!;

      for (int i = 1; i <= 20; i++) {
        provider.processDartThrow('S$i');
        provider.skipTurn();
        provider.skipTurn();
      }

      expect(provider.hasWinner, true);
      expect(provider.currentGame!.winnerId, currentPlayerId);
      expect(provider.currentGame!.state, ClockworkQuestGameState.finished);
    });

    test('bullseye as 21st target completes lap', () {
      final provider = ClockworkQuestProvider();
      final players = createPlayers(2);
      provider.startGame(players, true, false, 1); // includeBullseye = true

      final currentPlayerId = provider.getCurrentPlayerId()!;

      // Advance to target 21 (bullseye)
      provider.currentGame!.currentTarget[currentPlayerId] = 21;
      provider.processDartThrow('Bull');

      expect(provider.getPlayerCurrentTarget(currentPlayerId), 1);
      expect(provider.getPlayerLapsCompleted(currentPlayerId), 1);
      expect(provider.getDartThrowCompletedLap(currentPlayerId).last, true);
    });

    test('double bullseye counts for target 21', () {
      final provider = ClockworkQuestProvider();
      final players = createPlayers(2);
      provider.startGame(players, true, false, 1);

      final currentPlayerId = provider.getCurrentPlayerId()!;
      provider.currentGame!.currentTarget[currentPlayerId] = 21;
      provider.processDartThrow('DBull');

      expect(provider.getDartThrowHitTarget(currentPlayerId), [true]);
      expect(provider.getDartThrowAdvanced(currentPlayerId), [true]);
    });

    test('advanceTurn moves to next player', () {
      final provider = ClockworkQuestProvider();
      final players = createPlayers(3);
      provider.startGame(players, false, false, 1);

      expect(provider.getCurrentPlayerId(), 'p1');
      provider.advanceTurn();
      expect(provider.getCurrentPlayerId(), 'p2');
      provider.advanceTurn();
      expect(provider.getCurrentPlayerId(), 'p3');
      provider.advanceTurn();
      expect(provider.getCurrentPlayerId(), 'p1'); // Wraps around
    });

    test('advanceTurn resets per-turn tracking', () {
      final provider = ClockworkQuestProvider();
      final players = createPlayers(2);
      provider.startGame(players, false, false, 1);

      provider.processDartThrow('S1');
      final currentPlayerId = provider.getCurrentPlayerId()!;
      expect(provider.getCurrentPlayerDartsThrown(), 1);

      provider.advanceTurn();

      // Previous player's data should be reset
      expect(provider.getCurrentPlayerDartsThrown(), 0);
      expect(provider.getDartThrowHitTarget(currentPlayerId), isEmpty);
    });

    test('skipTurn fills remaining darts with misses', () {
      final provider = ClockworkQuestProvider();
      final players = createPlayers(2);
      provider.startGame(players, false, false, 1);

      provider.processDartThrow('S1');
      expect(provider.getCurrentPlayerDartsThrown(), 1);

      provider.skipTurn();

      // Should have advanced to next player
      expect(provider.getCurrentPlayerId(), 'p2');
    });

    test('editScore restores turn state and applies new throws', () {
      final provider = ClockworkQuestProvider();
      final players = createPlayers(2);
      provider.startGame(players, false, false, 1);

      final currentPlayerId = provider.getCurrentPlayerId()!;

      // Original throws
      provider.processDartThrow('S1');
      provider.processDartThrow('S2');
      expect(provider.getPlayerCurrentTarget(currentPlayerId), 3);

      // Edit score
      provider.editScore([
        {'sector': 'S1'},
        {'sector': 'Miss'},
      ]);

      expect(provider.getPlayerCurrentTarget(currentPlayerId), 2); // Only advanced once
      expect(provider.getCurrentPlayerDartsThrown(), 2);
    });

    test('confirmDartsRemoved clears takeout flag and advances turn', () {
      final provider = ClockworkQuestProvider();
      final players = createPlayers(2);
      provider.startGame(players, false, false, 1);

      // Throw 3 darts to trigger takeout
      provider.processDartThrow('S1');
      provider.processDartThrow('Miss');
      provider.processDartThrow('Miss');

      expect(provider.shouldPromptTakeout, true);

      provider.confirmDartsRemoved();

      expect(provider.shouldPromptTakeout, false);
      expect(provider.getCurrentPlayerId(), 'p2');
    });

    test('endGame sets state to finished', () {
      final provider = ClockworkQuestProvider();
      final players = createPlayers(2);
      provider.startGame(players, false, false, 1);

      expect(provider.currentGame, isNotNull);
      expect(provider.currentGame!.state, ClockworkQuestGameState.playing);

      provider.endGame();

      expect(provider.currentGame, isNotNull);
      expect(provider.currentGame!.state, ClockworkQuestGameState.finished);
      expect(provider.isGameActive, false);
    });

    test('multiple laps required to win', () {
      final provider = ClockworkQuestProvider();
      final players = createPlayers(2);
      provider.startGame(players, false, false, 2); // 2 laps to win

      final currentPlayerId = provider.getCurrentPlayerId()!;

      // Complete first lap
      for (int i = 1; i <= 20; i++) {
        provider.processDartThrow('S$i');
        provider.skipTurn();
        provider.skipTurn();
      }

      expect(provider.getPlayerLapsCompleted(currentPlayerId), 1);
      expect(provider.hasWinner, false);

      // Complete second lap
      for (int i = 1; i <= 20; i++) {
        provider.processDartThrow('S$i');
        provider.skipTurn();
        provider.skipTurn();
      }

      expect(provider.getPlayerLapsCompleted(currentPlayerId), 2);
      expect(provider.hasWinner, true);
      expect(provider.currentGame!.winnerId, currentPlayerId);
    });

    test('getInventorImagePath returns correct path', () {
      final provider = ClockworkQuestProvider();
      final players = createPlayers(2);
      provider.startGame(players, false, false, 1);

      final imagePath = provider.getInventorImagePath('p1');
      expect(imagePath, isNotNull);
      expect(
          imagePath,
          contains(
              'assets/games/clockwork_quest/images/characters/')); // Should contain characters path
    });
  });
}
