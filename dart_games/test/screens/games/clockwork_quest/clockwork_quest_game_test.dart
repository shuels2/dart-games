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

  // ═══════════════════════════════════════════════════
  // Multi-Player Tests (3+ players)
  // ═══════════════════════════════════════════════════
  group('ClockworkQuestProvider - Multi-Player', () {
    test('startGame with 3 players initializes all correctly', () {
      final provider = ClockworkQuestProvider();
      final players = createPlayers(3);
      provider.startGame(players, false, false, 1);

      expect(provider.currentGame!.playerIds.length, 3);
      for (final pid in ['p1', 'p2', 'p3']) {
        expect(provider.getPlayerCurrentTarget(pid), 1);
        expect(provider.getPlayerLapsCompleted(pid), 0);
      }
    });

    test('startGame with 8 players initializes all correctly', () {
      final provider = ClockworkQuestProvider();
      final players = createPlayers(8);
      provider.startGame(players, false, false, 1);

      expect(provider.currentGame!.playerIds.length, 8);
      for (int i = 1; i <= 8; i++) {
        expect(provider.getPlayerCurrentTarget('p$i'), 1);
        expect(provider.getPlayerLapsCompleted('p$i'), 0);
      }
    });

    test('4-player turn cycling visits all players in order', () {
      final provider = ClockworkQuestProvider();
      final players = createPlayers(4);
      provider.startGame(players, false, false, 1);

      expect(provider.getCurrentPlayerId(), 'p1');
      provider.advanceTurn();
      expect(provider.getCurrentPlayerId(), 'p2');
      provider.advanceTurn();
      expect(provider.getCurrentPlayerId(), 'p3');
      provider.advanceTurn();
      expect(provider.getCurrentPlayerId(), 'p4');
      provider.advanceTurn();
      expect(provider.getCurrentPlayerId(), 'p1'); // Wraps
    });

    test('4-player game: p3 wins while others are behind', () {
      final provider = ClockworkQuestProvider();
      final players = createPlayers(4);
      provider.startGame(players, false, false, 1);

      // Skip to p3's turn
      provider.skipTurn(); // p1 -> p2
      provider.skipTurn(); // p2 -> p3

      final p3 = provider.getCurrentPlayerId()!;
      expect(p3, 'p3');

      // p3 completes all 20 targets
      for (int i = 1; i <= 20; i++) {
        provider.processDartThrow('S$i');
        if (provider.hasWinner) break;
        if (provider.shouldPromptTakeout) {
          provider.confirmDartsRemoved(); // p3 -> p4
          provider.skipTurn(); // p4 -> p1
          provider.skipTurn(); // p1 -> p2
          provider.skipTurn(); // p2 -> p3
        }
      }

      expect(provider.hasWinner, true);
      expect(provider.currentGame!.winnerId, 'p3');

      // Other players should still be at low targets
      expect(provider.getPlayerCurrentTarget('p1'), 1);
      expect(provider.getPlayerCurrentTarget('p2'), 1);
      expect(provider.getPlayerCurrentTarget('p4'), 1);
    });

    test('8-player game completes when first player finishes', () {
      final provider = ClockworkQuestProvider();
      final players = createPlayers(8);
      provider.startGame(players, false, false, 1);

      // p1 completes all targets, all others skip
      for (int i = 1; i <= 20; i++) {
        provider.processDartThrow('S$i');
        if (provider.hasWinner) break;
        if (provider.shouldPromptTakeout) {
          provider.confirmDartsRemoved();
          // Skip 7 other players
          for (int j = 0; j < 7; j++) {
            provider.skipTurn();
          }
        }
      }

      expect(provider.hasWinner, true);
      expect(provider.currentGame!.winnerId, 'p1');
    });
  });

  // ═══════════════════════════════════════════════════
  // Inventor Assignment Tests
  // ═══════════════════════════════════════════════════
  group('ClockworkQuestProvider - Inventor Assignments', () {
    test('each player gets a unique inventor', () {
      final provider = ClockworkQuestProvider();
      final players = createPlayers(4);
      provider.startGame(players, false, false, 1);

      final assignments = provider.currentGame!.inventorAssignments;
      final inventors = assignments.values.toSet();

      expect(assignments.length, 4);
      expect(inventors.length, 4, reason: 'All inventor assignments must be unique');
    });

    test('8 players get all 8 unique inventors', () {
      final provider = ClockworkQuestProvider();
      final players = createPlayers(8);
      provider.startGame(players, false, false, 1);

      final assignments = provider.currentGame!.inventorAssignments;
      final inventors = assignments.values.toSet();

      expect(assignments.length, 8);
      expect(inventors.length, 8, reason: 'All 8 inventors must be assigned');
      expect(inventors, containsAll(ClockworkInventor.values));
    });

    test('every player has a valid inventor image path', () {
      final provider = ClockworkQuestProvider();
      final players = createPlayers(8);
      provider.startGame(players, false, false, 1);

      for (int i = 1; i <= 8; i++) {
        final path = provider.getInventorImagePath('p$i');
        expect(path, isNotNull, reason: 'Player p$i should have an image path');
        expect(path, startsWith('assets/games/clockwork_quest/images/characters/'));
        expect(path, endsWith('.png'));
      }
    });

    test('getInventorType returns correct type per player', () {
      final provider = ClockworkQuestProvider();
      final players = createPlayers(3);
      provider.startGame(players, false, false, 1);

      for (final pid in ['p1', 'p2', 'p3']) {
        final inventor = provider.getInventorType(pid);
        expect(inventor, isNotNull);
        expect(ClockworkInventor.values, contains(inventor));
      }
    });

    test('getInventorType returns null for unknown player', () {
      final provider = ClockworkQuestProvider();
      final players = createPlayers(2);
      provider.startGame(players, false, false, 1);

      expect(provider.getInventorType('unknown'), isNull);
      expect(provider.getInventorImagePath('unknown'), isNull);
    });
  });

  // ═══════════════════════════════════════════════════
  // Edit Score - Speed Mode Tests
  // ═══════════════════════════════════════════════════
  group('ClockworkQuestProvider - Edit Score in Speed Mode', () {
    test('editScore in speed mode restores completed targets', () {
      final provider = ClockworkQuestProvider();
      final players = createPlayers(2);
      provider.startGame(players, false, true, 1); // speed mode

      final pid = provider.getCurrentPlayerId()!;

      // Hit gears 5, 10, 15 in speed mode
      provider.processDartThrow('S5');
      provider.processDartThrow('S10');
      provider.processDartThrow('S15');

      expect(provider.getPlayerCompletedTargets(pid), containsAll([5, 10, 15]));

      // Edit to change dart 2 from S10 to Miss
      provider.editScore([
        {'sector': 'S5'},
        {'sector': 'Miss'},
        {'sector': 'S15'},
      ]);

      expect(provider.getPlayerCompletedTargets(pid), containsAll([5, 15]));
      expect(provider.getPlayerCompletedTargets(pid), isNot(contains(10)));
    });

    test('editScore in speed mode can add new gears', () {
      final provider = ClockworkQuestProvider();
      final players = createPlayers(2);
      provider.startGame(players, false, true, 1);

      final pid = provider.getCurrentPlayerId()!;

      // Original: 3 misses
      provider.processDartThrow('Miss');
      provider.processDartThrow('Miss');
      provider.processDartThrow('Miss');

      expect(provider.getPlayerCompletedTargets(pid), isEmpty);

      // Edit: change to 3 hits
      provider.editScore([
        {'sector': 'S3'},
        {'sector': 'S7'},
        {'sector': 'S12'},
      ]);

      expect(provider.getPlayerCompletedTargets(pid), containsAll([3, 7, 12]));
    });

    test('editScore in speed mode: editing to all misses clears completed', () {
      final provider = ClockworkQuestProvider();
      final players = createPlayers(2);
      provider.startGame(players, false, true, 1);

      final pid = provider.getCurrentPlayerId()!;

      provider.processDartThrow('S1');
      provider.processDartThrow('S2');
      provider.processDartThrow('S3');

      expect(provider.getPlayerCompletedTargets(pid).length, 3);

      provider.editScore([
        {'sector': 'Miss'},
        {'sector': 'Miss'},
        {'sector': 'Miss'},
      ]);

      expect(provider.getPlayerCompletedTargets(pid), isEmpty);
    });
  });

  // ═══════════════════════════════════════════════════
  // Edit Score - Bullseye Mode Tests
  // ═══════════════════════════════════════════════════
  group('ClockworkQuestProvider - Edit Score with Bullseye', () {
    test('editScore with bullseye target restores correctly', () {
      final provider = ClockworkQuestProvider();
      final players = createPlayers(2);
      provider.startGame(players, true, false, 1); // bullseye ON

      final pid = provider.getCurrentPlayerId()!;

      // Advance to target 20
      provider.currentGame!.currentTarget[pid] = 20;
      // Save turn start so edit can restore
      provider.currentGame!.turnStartCurrentTarget[pid] = 20;
      provider.currentGame!.turnStartLapsCompleted[pid] = 0;
      provider.currentGame!.turnStartState = ClockworkQuestGameState.playing;
      provider.currentGame!.turnStartWinnerId = null;
      provider.currentGame!.turnStartCompletedTargets[pid] = [];

      // Hit 20 (advances to 21 = bullseye), then bull, then miss
      provider.processDartThrow('S20');
      expect(provider.getPlayerCurrentTarget(pid), 21);
      provider.processDartThrow('Bull');
      // Hitting bull at 21 completes the game
      expect(provider.hasWinner, true);

      // Edit: remove the bull hit
      provider.editScore([
        {'sector': 'S20'},
        {'sector': 'Miss'},
        {'sector': 'Miss'},
      ]);

      // Should be at target 21, not won
      expect(provider.getPlayerCurrentTarget(pid), 21);
      expect(provider.hasWinner, false);
    });

    test('editScore can change miss to bullseye and complete game', () {
      final provider = ClockworkQuestProvider();
      final players = createPlayers(2);
      provider.startGame(players, true, false, 1);

      final pid = provider.getCurrentPlayerId()!;

      // Set up at target 21
      provider.currentGame!.currentTarget[pid] = 21;
      provider.currentGame!.turnStartCurrentTarget[pid] = 21;
      provider.currentGame!.turnStartLapsCompleted[pid] = 0;
      provider.currentGame!.turnStartState = ClockworkQuestGameState.playing;
      provider.currentGame!.turnStartWinnerId = null;
      provider.currentGame!.turnStartCompletedTargets[pid] = [];

      // Original: 3 misses
      provider.processDartThrow('Miss');
      provider.processDartThrow('Miss');
      provider.processDartThrow('Miss');
      expect(provider.hasWinner, false);

      // Edit: first dart is bullseye
      provider.editScore([
        {'sector': 'Bull'},
        {'sector': 'Miss'},
        {'sector': 'Miss'},
      ]);

      expect(provider.hasWinner, true);
      expect(provider.currentGame!.winnerId, pid);
    });
  });

  // ═══════════════════════════════════════════════════
  // Full Game Completion Tests
  // ═══════════════════════════════════════════════════
  group('ClockworkQuestProvider - Full Game Completion', () {
    test('full game with bullseye: 1-20 then bull to win', () {
      final provider = ClockworkQuestProvider();
      final players = createPlayers(2);
      provider.startGame(players, true, false, 1); // bullseye ON

      final pid = provider.getCurrentPlayerId()!;

      // Hit all 20 targets sequentially, then bullseye
      for (int i = 1; i <= 20; i++) {
        provider.processDartThrow('S$i');
        if (provider.shouldPromptTakeout) {
          provider.confirmDartsRemoved();
          provider.skipTurn(); // p2 skips
        }
      }

      // Should be at target 21
      expect(provider.getPlayerCurrentTarget(pid), 21);
      expect(provider.hasWinner, false);

      // Hit bullseye to win
      provider.processDartThrow('Bull');

      expect(provider.hasWinner, true);
      expect(provider.currentGame!.winnerId, pid);
      expect(provider.getPlayerLapsCompleted(pid), 1);
    });

    test('full game with speed mode: random order to win', () {
      final provider = ClockworkQuestProvider();
      final players = createPlayers(2);
      provider.startGame(players, false, true, 1); // speed mode ON

      final pid = provider.getCurrentPlayerId()!;

      // Hit gears in non-sequential order
      final order = [20, 15, 10, 5, 1, 19, 14, 9, 4, 2, 18, 13, 8, 3, 17, 12, 7, 6, 16, 11];
      for (final gear in order) {
        provider.processDartThrow('S$gear');
        if (provider.hasWinner) break;
        if (provider.shouldPromptTakeout) {
          provider.confirmDartsRemoved();
          provider.skipTurn();
        }
      }

      expect(provider.hasWinner, true);
      expect(provider.currentGame!.winnerId, pid);
    });

    test('full game with speed mode + bullseye: all 20 + bull', () {
      final provider = ClockworkQuestProvider();
      final players = createPlayers(2);
      provider.startGame(players, true, true, 1); // speed + bullseye

      final pid = provider.getCurrentPlayerId()!;

      // Hit all 20 gears
      for (int i = 1; i <= 20; i++) {
        provider.processDartThrow('S$i');
        if (provider.shouldPromptTakeout) {
          provider.confirmDartsRemoved();
          provider.skipTurn();
        }
      }

      expect(provider.hasWinner, false);

      // Hit bullseye
      provider.processDartThrow('Bull');

      expect(provider.hasWinner, true);
      expect(provider.currentGame!.winnerId, pid);
    });

    test('3-lap game requires completing all 3 laps to win', () {
      final provider = ClockworkQuestProvider();
      final players = createPlayers(2);
      provider.startGame(players, false, false, 3); // 3 laps

      final pid = provider.getCurrentPlayerId()!;

      for (int lap = 0; lap < 3; lap++) {
        for (int i = 1; i <= 20; i++) {
          provider.processDartThrow('S$i');
          if (provider.hasWinner) break;
          if (provider.shouldPromptTakeout) {
            provider.confirmDartsRemoved();
            provider.skipTurn();
          }
        }

        if (lap < 2) {
          expect(provider.getPlayerLapsCompleted(pid), lap + 1);
          expect(provider.hasWinner, false);
          expect(provider.getPlayerCurrentTarget(pid), 1,
              reason: 'Target should reset to 1 after lap ${lap + 1}');
        }
      }

      expect(provider.getPlayerLapsCompleted(pid), 3);
      expect(provider.hasWinner, true);
      expect(provider.currentGame!.winnerId, pid);
    });

    test('3-lap game with bullseye: must hit bull each lap', () {
      final provider = ClockworkQuestProvider();
      final players = createPlayers(2);
      provider.startGame(players, true, false, 3); // bullseye + 3 laps

      final pid = provider.getCurrentPlayerId()!;

      for (int lap = 0; lap < 3; lap++) {
        // Hit 1-20
        for (int i = 1; i <= 20; i++) {
          provider.processDartThrow('S$i');
          if (provider.shouldPromptTakeout) {
            provider.confirmDartsRemoved();
            provider.skipTurn();
          }
        }
        expect(provider.getPlayerCurrentTarget(pid), 21);

        // Hit bullseye to complete the lap
        provider.processDartThrow('Bull');
        if (provider.hasWinner) break;
        if (provider.shouldPromptTakeout) {
          provider.confirmDartsRemoved();
          provider.skipTurn();
        }
      }

      expect(provider.getPlayerLapsCompleted(pid), 3);
      expect(provider.hasWinner, true);
    });

    test('speed mode + 3 laps: completed targets clear each lap', () {
      final provider = ClockworkQuestProvider();
      final players = createPlayers(2);
      provider.startGame(players, false, true, 3); // speed + 3 laps

      final pid = provider.getCurrentPlayerId()!;

      for (int lap = 0; lap < 3; lap++) {
        for (int i = 1; i <= 20; i++) {
          provider.processDartThrow('S$i');
          if (provider.hasWinner) break;
          if (provider.shouldPromptTakeout) {
            provider.confirmDartsRemoved();
            provider.skipTurn();
          }
        }

        if (lap < 2) {
          expect(provider.getPlayerCompletedTargets(pid), isEmpty,
              reason: 'Completed targets should reset after lap ${lap + 1}');
          expect(provider.getPlayerCurrentTarget(pid), 1);
        }
      }

      expect(provider.hasWinner, true);
    });

    test('speed mode + bullseye + 2 laps: all options combined', () {
      final provider = ClockworkQuestProvider();
      final players = createPlayers(2);
      provider.startGame(players, true, true, 2); // all options

      final pid = provider.getCurrentPlayerId()!;

      expect(provider.currentGame!.maxTarget, 21);

      for (int lap = 0; lap < 2; lap++) {
        // Hit all 20 numbered gears
        for (int i = 1; i <= 20; i++) {
          provider.processDartThrow('S$i');
          if (provider.shouldPromptTakeout) {
            provider.confirmDartsRemoved();
            provider.skipTurn();
          }
        }
        // Hit bullseye
        provider.processDartThrow('Bull');
        if (provider.hasWinner) break;
        if (provider.shouldPromptTakeout) {
          provider.confirmDartsRemoved();
          provider.skipTurn();
        }
      }

      expect(provider.hasWinner, true);
      expect(provider.getPlayerLapsCompleted(pid), 2);
    });
  });

  // ═══════════════════════════════════════════════════
  // Edge Cases
  // ═══════════════════════════════════════════════════
  group('ClockworkQuestProvider - Edge Cases', () {
    test('bullseye hit without includeBullseye does not count', () {
      final provider = ClockworkQuestProvider();
      final players = createPlayers(2);
      provider.startGame(players, false, false, 1); // bullseye OFF

      final pid = provider.getCurrentPlayerId()!;
      provider.processDartThrow('Bull');

      expect(provider.getDartThrowHitTarget(pid), [false]);
      expect(provider.getPlayerCurrentTarget(pid), 1);
    });

    test('speed mode: bullseye without includeBullseye does not count', () {
      final provider = ClockworkQuestProvider();
      final players = createPlayers(2);
      provider.startGame(players, false, true, 1); // speed mode, no bullseye

      final pid = provider.getCurrentPlayerId()!;
      provider.processDartThrow('Bull');

      expect(provider.getDartThrowHitTarget(pid), [false]);
      expect(provider.getPlayerCompletedTargets(pid), isEmpty);
    });

    test('speed mode: double bullseye with includeBullseye counts for gear 21', () {
      final provider = ClockworkQuestProvider();
      final players = createPlayers(2);
      provider.startGame(players, true, true, 1); // speed + bullseye

      final pid = provider.getCurrentPlayerId()!;
      provider.processDartThrow('DBull');

      expect(provider.getDartThrowHitTarget(pid), [true]);
      expect(provider.getPlayerCompletedTargets(pid), contains(21));
    });

    test('processDartThrow ignored when waiting for takeout', () {
      final provider = ClockworkQuestProvider();
      final players = createPlayers(2);
      provider.startGame(players, false, false, 1);

      final pid = provider.getCurrentPlayerId()!;

      // Throw 3 darts
      provider.processDartThrow('S1');
      provider.processDartThrow('S2');
      provider.processDartThrow('S3');

      expect(provider.shouldPromptTakeout, true);
      expect(provider.getPlayerCurrentTarget(pid), 4);

      // Additional throw should be ignored
      provider.processDartThrow('S4');
      expect(provider.getPlayerCurrentTarget(pid), 4);
      expect(provider.getCurrentPlayerDartsThrown(), 3);
    });

    test('processDartThrow ignored when game is finished', () {
      final provider = ClockworkQuestProvider();
      final players = createPlayers(2);
      provider.startGame(players, false, false, 1);

      provider.endGame();
      provider.processDartThrow('S1');

      // Nothing should change
      expect(provider.getCurrentPlayerDartsThrown(), 0);
    });

    test('processDartThrow handles empty sector string', () {
      final provider = ClockworkQuestProvider();
      final players = createPlayers(2);
      provider.startGame(players, false, false, 1);

      provider.processDartThrow('');

      final pid = provider.getCurrentPlayerId()!;
      expect(provider.getDartThrowHitTarget(pid), [false]);
      expect(provider.getCurrentPlayerDartsThrown(), 1);
    });

    test('processDartThrow handles None sector', () {
      final provider = ClockworkQuestProvider();
      final players = createPlayers(2);
      provider.startGame(players, false, false, 1);

      provider.processDartThrow('None');

      final pid = provider.getCurrentPlayerId()!;
      expect(provider.getDartThrowHitTarget(pid), [false]);
    });

    test('normal mode: hitting future target number does not advance', () {
      final provider = ClockworkQuestProvider();
      final players = createPlayers(2);
      provider.startGame(players, false, false, 1);

      final pid = provider.getCurrentPlayerId()!;
      // Target is 1, hit 2 instead
      provider.processDartThrow('S2');

      expect(provider.getDartThrowHitTarget(pid), [false]);
      expect(provider.getDartThrowAdvanced(pid), [false]);
      expect(provider.getPlayerCurrentTarget(pid), 1);
    });

    test('normal mode: hitting previous target number does not advance', () {
      final provider = ClockworkQuestProvider();
      final players = createPlayers(2);
      provider.startGame(players, false, false, 1);

      final pid = provider.getCurrentPlayerId()!;
      provider.processDartThrow('S1'); // Advance to 2
      provider.processDartThrow('S1'); // Hit 1 again (already past it)

      expect(provider.getDartThrowHitTarget(pid), [true, false]);
      expect(provider.getPlayerCurrentTarget(pid), 2);
    });

    test('clearGame resets all state', () {
      final provider = ClockworkQuestProvider();
      final players = createPlayers(2);
      provider.startGame(players, false, false, 1);
      provider.processDartThrow('S1');

      provider.clearGame();

      expect(provider.currentGame, isNull);
      expect(provider.isGameActive, false);
      expect(provider.shouldPromptTakeout, false);
      expect(provider.hasWinner, false);
      expect(provider.getCurrentPlayerId(), isNull);
    });

    test('serialization roundtrip preserves mid-game state', () {
      final provider = ClockworkQuestProvider();
      final players = createPlayers(3);
      provider.startGame(players, true, true, 3); // all options

      final pid = provider.getCurrentPlayerId()!;
      provider.processDartThrow('S5');
      provider.processDartThrow('S10');

      final game = provider.currentGame!;
      final json = game.toJson();
      final restored = ClockworkQuestGame.fromJson(json);

      expect(restored.playerIds, game.playerIds);
      expect(restored.includeBullseye, true);
      expect(restored.speedMode, true);
      expect(restored.numberOfLaps, 3);
      expect(restored.currentPlayerIndex, game.currentPlayerIndex);
      expect(restored.currentTarget[pid], game.currentTarget[pid]);
      expect(restored.completedTargets[pid], game.completedTargets[pid]);
      expect(restored.dartsThrown[pid], game.dartsThrown[pid]);
      expect(restored.inventorAssignments.length, 3);
    });

    test('serialization roundtrip preserves inventor assignments', () {
      final provider = ClockworkQuestProvider();
      final players = createPlayers(8);
      provider.startGame(players, false, false, 1);

      final game = provider.currentGame!;
      final json = game.toJson();
      final restored = ClockworkQuestGame.fromJson(json);

      for (final pid in game.playerIds) {
        expect(restored.inventorAssignments[pid], game.inventorAssignments[pid]);
      }
    });
  });
}
