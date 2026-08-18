import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/providers/pirates_grid_provider.dart';
import 'package:dart_games/models/pirates_grid_game.dart';
import 'package:dart_games/models/saved_game_metadata.dart';
import '../shared/mock_api_helpers.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

/// Starts an Easy Bo1 no-steal game with two players and returns the provider.
/// Grid cells are randomized; use [cellAt] or [numAt] to build sector strings.
PiratesGridProvider _makeProvider() {
  final server = MockApiServer();
  return PiratesGridProvider(apiClient: server.apiClient);
}

/// Returns the target number at [row],[col] in the current game.
int numAt(PiratesGridProvider p, int row, int col) =>
    p.currentGame!.grid[row][col].target.number;

/// Throws one dart that hits cell [row],[col] in Easy mode (single, any number).
void hitEasy(PiratesGridProvider p, int row, int col) {
  final n = numAt(p, row, col);
  p.processDartThrow(score: n, multiplier: 1, sector: 'S$n');
}

/// Throws a miss dart.
void miss(PiratesGridProvider p) =>
    p.processDartThrow(score: 99, multiplier: 1, sector: 'S99');

/// Fills the remaining darts in p1's turn with misses, then calls
/// handleTakeoutFinished to advance to the next player.
void completeTurn(PiratesGridProvider p) {
  while (p.getCurrentPlayerDartsThrown() < 3) {
    miss(p);
  }
  p.handleTakeoutFinished();
}

/// Wins a round for [playerId] by claiming the entire top row.
/// Forces the current player index to [playerId], pre-claims (0,0) and (0,1),
/// then throws the winning dart at (0,2) and calls handleTakeoutFinished.
void winRoundForPlayer(PiratesGridProvider p, String playerId) {
  final game = p.currentGame!;
  game.currentPlayerIndex = game.playerIds.indexOf(playerId);
  game.grid[0][0].claimedBy = playerId;
  game.grid[0][1].claimedBy = playerId;
  hitEasy(p, 0, 2);            // claims (0,2) → 3-in-a-row
  p.handleTakeoutFinished();   // triggers round/match transition
}

/// Wins a round for the currently active player by claiming the entire top row.
void winRoundForCurrentPlayer(PiratesGridProvider p) {
  final playerId = p.currentGame!.getCurrentPlayerId();
  winRoundForPlayer(p, playerId);
}

void main() {
  // ─────────────────────────────────────────────────────────────────────────────
  // 1. Initial state
  // ─────────────────────────────────────────────────────────────────────────────

  group('PiratesGridProvider — initial state', () {
    test('isGameActive is false before startGame', () {
      final p = _makeProvider();
      expect(p.isGameActive, isFalse);
      expect(p.currentGame, isNull);
    });

    test('startGame requires exactly 2 players — 1 player is rejected', () {
      final p = _makeProvider();
      p.startGame(['p1'], TargetDifficulty.easy, 1, false, false);
      expect(p.isGameActive, isFalse);
      expect(p.currentGame, isNull);
    });

    test('startGame requires exactly 2 players — 3 players are rejected', () {
      final p = _makeProvider();
      p.startGame(
          ['p1', 'p2', 'p3'], TargetDifficulty.easy, 1, false, false);
      expect(p.isGameActive, isFalse);
      expect(p.currentGame, isNull);
    });

    test('startGame with 2 players sets isGameActive true', () {
      final p = _makeProvider();
      p.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);
      expect(p.isGameActive, isTrue);
      expect(p.currentGame, isNotNull);
    });

    test('startGame initialises player maps with zeros', () {
      final p = _makeProvider();
      p.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);
      final game = p.currentGame!;
      expect(game.dartsThrown['p1'], 0);
      expect(game.dartsThrown['p2'], 0);
      expect(game.totalDartsThrown['p1'], 0);
      expect(game.totalDartsThrown['p2'], 0);
      expect(game.totalTurns['p1'], 0);
      expect(game.totalTurns['p2'], 0);
      expect(game.roundsWon['p1'], 0);
      expect(game.roundsWon['p2'], 0);
    });

    test('startGame sets first player as current player', () {
      final p = _makeProvider();
      p.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);
      expect(p.currentGame!.getCurrentPlayerId(), 'p1');
    });

    test('startGame grid contains exactly 9 cells', () {
      final p = _makeProvider();
      p.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);
      final grid = p.currentGame!.grid;
      int count = 0;
      for (final row in grid) {
        count += row.length;
      }
      expect(count, 9);
    });

    test('startGame grid uses numbers in range 1–20', () {
      final p = _makeProvider();
      p.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);
      final grid = p.currentGame!.grid;
      for (final row in grid) {
        for (final cell in row) {
          expect(cell.target.number, inInclusiveRange(1, 20));
        }
      }
    });

    test('startGame grid has 9 unique numbers (no duplicates)', () {
      final p = _makeProvider();
      p.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);
      final grid = p.currentGame!.grid;
      final numbers = <int>{};
      for (final row in grid) {
        for (final cell in row) {
          numbers.add(cell.target.number);
        }
      }
      expect(numbers.length, 9);
    });

    test('all cells start unclaimed', () {
      final p = _makeProvider();
      p.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);
      final grid = p.currentGame!.grid;
      for (final row in grid) {
        for (final cell in row) {
          expect(cell.claimedBy, isNull);
        }
      }
    });

    test('startGame preserves difficulty, bestOf, stealMode, speedPlay', () {
      final p = _makeProvider();
      p.startGame(['p1', 'p2'], TargetDifficulty.hard, 5, true, true);
      final game = p.currentGame!;
      expect(game.targetDifficulty, TargetDifficulty.hard);
      expect(game.bestOf, 5);
      expect(game.stealMode, isTrue);
      expect(game.speedPlay, isTrue);
    });

    test('startGame sets state to playing and currentRound to 1', () {
      final p = _makeProvider();
      p.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);
      expect(p.currentGame!.state, GameState.playing);
      expect(p.currentGame!.currentRound, 1);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // 2. processDartThrow — dart counter and tracking
  // ─────────────────────────────────────────────────────────────────────────────

  group('PiratesGridProvider — dart counter and tracking', () {
    test('processDartThrow increments dartsThrown for current player', () {
      final p = _makeProvider();
      p.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);
      miss(p);
      expect(p.getCurrentPlayerDartsThrown(), 1);
    });

    test('processDartThrow increments totalDartsThrown', () {
      final p = _makeProvider();
      p.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);
      miss(p);
      miss(p);
      expect(p.currentGame!.totalDartsThrown['p1'], 2);
    });

    test('totalTurns increments on first dart only, not second or third', () {
      final p = _makeProvider();
      p.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);
      expect(p.currentGame!.totalTurns['p1'], 0);
      miss(p);
      expect(p.currentGame!.totalTurns['p1'], 1);
      miss(p);
      expect(p.currentGame!.totalTurns['p1'], 1);
      miss(p);
      expect(p.currentGame!.totalTurns['p1'], 1);
    });

    test('currentTurnDartSegments appends sector string for each dart', () {
      final p = _makeProvider();
      p.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);
      p.processDartThrow(score: 5, multiplier: 1, sector: 'S5');
      p.processDartThrow(score: 10, multiplier: 2, sector: 'D10');
      final segs = p.getCurrentTurnDartSegments('p1');
      expect(segs, ['S5', 'D10']);
    });

    test('shouldPromptTakeout is false after 2 darts', () {
      final p = _makeProvider();
      p.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);
      miss(p);
      miss(p);
      expect(p.shouldPromptTakeout, isFalse);
    });

    test('shouldPromptTakeout is true after 3 darts', () {
      final p = _makeProvider();
      p.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);
      miss(p);
      miss(p);
      miss(p);
      expect(p.shouldPromptTakeout, isTrue);
    });

    test('processDartThrow no-ops when game is not active', () {
      final p = _makeProvider();
      p.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);
      p.endGame();
      miss(p);
      expect(p.getCurrentPlayerDartsThrown(), 0);
    });

    test('processDartThrow no-ops when waitingForTakeout', () {
      final p = _makeProvider();
      p.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);
      miss(p);
      miss(p);
      miss(p);
      // 4th dart should be ignored
      miss(p);
      expect(p.getCurrentPlayerDartsThrown(), 3);
    });

    test('dartsThrown resets to 0 after handleTakeoutFinished', () {
      final p = _makeProvider();
      p.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);
      miss(p);
      miss(p);
      miss(p);
      p.handleTakeoutFinished();
      // Now it's p2's turn; p1 dartsThrown should be 0
      expect(p.currentGame!.dartsThrown['p1'], 0);
    });

    test('currentTurnDartSegments resets after turn advances', () {
      final p = _makeProvider();
      p.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);
      miss(p);
      miss(p);
      miss(p);
      p.handleTakeoutFinished();
      expect(p.currentGame!.currentTurnDartSegments['p1'], isEmpty);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // 3. Easy difficulty — CellRequirement.any
  // ─────────────────────────────────────────────────────────────────────────────

  group('PiratesGridProvider — Easy difficulty flag placement', () {
    test('single (multiplier=1) hit claims cell', () {
      final p = _makeProvider();
      p.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);
      final n = numAt(p, 0, 0);
      p.processDartThrow(score: n, multiplier: 1, sector: 'S$n');
      expect(p.currentGame!.grid[0][0].claimedBy, 'p1');
    });

    test('double (multiplier=2) hit on Easy cell claims cell', () {
      final p = _makeProvider();
      p.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);
      final n = numAt(p, 0, 0);
      p.processDartThrow(score: n, multiplier: 2, sector: 'D$n');
      expect(p.currentGame!.grid[0][0].claimedBy, 'p1');
    });

    test('triple (multiplier=3) hit on Easy cell claims cell', () {
      final p = _makeProvider();
      p.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);
      final n = numAt(p, 0, 0);
      p.processDartThrow(score: n, multiplier: 3, sector: 'T$n');
      expect(p.currentGame!.grid[0][0].claimedBy, 'p1');
    });

    test('miss (number not in grid) does not claim any cell', () {
      final p = _makeProvider();
      p.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);
      // Score 99 is never in the grid
      p.processDartThrow(score: 99, multiplier: 1, sector: 'S99');
      int claimed = 0;
      for (final row in p.currentGame!.grid) {
        for (final cell in row) {
          if (cell.claimedBy != null) claimed++;
        }
      }
      expect(claimed, 0);
    });

    test('hitting own already-claimed cell does not change ownership', () {
      final p = _makeProvider();
      p.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);
      hitEasy(p, 0, 0); // p1 claims (0,0)
      hitEasy(p, 0, 0); // p1 hits again — no change
      expect(p.currentGame!.grid[0][0].claimedBy, 'p1');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // 4. Medium difficulty — CellRequirement.doubleOrTriple
  // ─────────────────────────────────────────────────────────────────────────────

  group('PiratesGridProvider — Medium difficulty flag placement', () {
    test('single hit does NOT claim cell in Medium mode', () {
      final p = _makeProvider();
      p.startGame(['p1', 'p2'], TargetDifficulty.medium, 1, false, false);
      final n = numAt(p, 0, 0);
      p.processDartThrow(score: n, multiplier: 1, sector: 'S$n');
      expect(p.currentGame!.grid[0][0].claimedBy, isNull);
    });

    test('double hit claims cell in Medium mode', () {
      final p = _makeProvider();
      p.startGame(['p1', 'p2'], TargetDifficulty.medium, 1, false, false);
      final n = numAt(p, 0, 0);
      p.processDartThrow(score: n, multiplier: 2, sector: 'D$n');
      expect(p.currentGame!.grid[0][0].claimedBy, 'p1');
    });

    test('triple hit claims cell in Medium mode', () {
      final p = _makeProvider();
      p.startGame(['p1', 'p2'], TargetDifficulty.medium, 1, false, false);
      final n = numAt(p, 0, 0);
      p.processDartThrow(score: n, multiplier: 3, sector: 'T$n');
      expect(p.currentGame!.grid[0][0].claimedBy, 'p1');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // 5. Hard difficulty — position-specific requirements
  // ─────────────────────────────────────────────────────────────────────────────

  group('PiratesGridProvider — Hard difficulty flag placement', () {
    test('corner cell (0,0) requires triple — single fails', () {
      final p = _makeProvider();
      p.startGame(['p1', 'p2'], TargetDifficulty.hard, 1, false, false);
      final n = numAt(p, 0, 0);
      p.processDartThrow(score: n, multiplier: 1, sector: 'S$n');
      expect(p.currentGame!.grid[0][0].claimedBy, isNull);
    });

    test('corner cell (0,0) requires triple — double fails', () {
      final p = _makeProvider();
      p.startGame(['p1', 'p2'], TargetDifficulty.hard, 1, false, false);
      final n = numAt(p, 0, 0);
      p.processDartThrow(score: n, multiplier: 2, sector: 'D$n');
      expect(p.currentGame!.grid[0][0].claimedBy, isNull);
    });

    test('corner cell (0,0) requires triple — triple succeeds', () {
      final p = _makeProvider();
      p.startGame(['p1', 'p2'], TargetDifficulty.hard, 1, false, false);
      final n = numAt(p, 0, 0);
      p.processDartThrow(score: n, multiplier: 3, sector: 'T$n');
      expect(p.currentGame!.grid[0][0].claimedBy, 'p1');
    });

    test('edge cell (0,1) requires double — single fails', () {
      final p = _makeProvider();
      p.startGame(['p1', 'p2'], TargetDifficulty.hard, 1, false, false);
      final n = numAt(p, 0, 1);
      p.processDartThrow(score: n, multiplier: 1, sector: 'S$n');
      expect(p.currentGame!.grid[0][1].claimedBy, isNull);
    });

    test('edge cell (0,1) requires double — double succeeds', () {
      final p = _makeProvider();
      p.startGame(['p1', 'p2'], TargetDifficulty.hard, 1, false, false);
      final n = numAt(p, 0, 1);
      p.processDartThrow(score: n, multiplier: 2, sector: 'D$n');
      expect(p.currentGame!.grid[0][1].claimedBy, 'p1');
    });

    test('center cell (1,1) requires Bull — outer bull (score=25) claims it', () {
      final p = _makeProvider();
      p.startGame(['p1', 'p2'], TargetDifficulty.hard, 1, false, false);
      // Center (1,1) always Bull in Hard mode
      p.processDartThrow(score: 25, multiplier: 1, sector: 'Bull');
      expect(p.currentGame!.grid[1][1].claimedBy, 'p1');
    });

    test('center cell (1,1) requires Bull — inner bull (score=50) claims it', () {
      final p = _makeProvider();
      p.startGame(['p1', 'p2'], TargetDifficulty.hard, 1, false, false);
      p.processDartThrow(score: 50, multiplier: 2, sector: 'Bull');
      expect(p.currentGame!.grid[1][1].claimedBy, 'p1');
    });

    test('center cell (1,1) Bull — number 1-20 single does not claim it', () {
      final p = _makeProvider();
      p.startGame(['p1', 'p2'], TargetDifficulty.hard, 1, false, false);
      // Any random numbered dart should not match the Bull cell
      p.processDartThrow(score: 7, multiplier: 1, sector: 'S7');
      // Center is only claimed if score=25 or score=50
      // (It could happen to be a corner/edge cell that matches 7, but not center)
      expect(p.currentGame!.grid[1][1].claimedBy, isNull);
    });

    test('edge cell (1,0) requires double — triple fails', () {
      final p = _makeProvider();
      p.startGame(['p1', 'p2'], TargetDifficulty.hard, 1, false, false);
      final n = numAt(p, 1, 0);
      p.processDartThrow(score: n, multiplier: 3, sector: 'T$n');
      expect(p.currentGame!.grid[1][0].claimedBy, isNull);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // 6. Steal Mode
  // ─────────────────────────────────────────────────────────────────────────────

  group('PiratesGridProvider — Steal Mode', () {
    test('Steal OFF: hitting opponent-claimed cell leaves it unchanged', () {
      final p = _makeProvider();
      p.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);
      hitEasy(p, 0, 0); // p1 claims (0,0)
      completeTurn(p);   // advance to p2

      // p2 hits the same cell with steal OFF
      hitEasy(p, 0, 0);
      expect(p.currentGame!.grid[0][0].claimedBy, 'p1');
    });

    test('Steal ON: hitting opponent-claimed cell replaces flag', () {
      final p = _makeProvider();
      p.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, true, false);
      hitEasy(p, 0, 0); // p1 claims (0,0)
      completeTurn(p);   // advance to p2

      // p2 hits the same cell with steal ON
      hitEasy(p, 0, 0);
      expect(p.currentGame!.grid[0][0].claimedBy, 'p2');
    });

    test('Steal ON: hitting own already-claimed cell does nothing', () {
      final p = _makeProvider();
      p.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, true, false);
      hitEasy(p, 0, 0);  // p1 claims (0,0)
      hitEasy(p, 0, 0);  // p1 hits own cell again — no effect
      expect(p.currentGame!.grid[0][0].claimedBy, 'p1');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // 7. Turn advancement
  // ─────────────────────────────────────────────────────────────────────────────

  group('PiratesGridProvider — turn advancement', () {
    test('advanceToNextPlayer switches from p1 to p2', () {
      final p = _makeProvider();
      p.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);
      miss(p);
      miss(p);
      miss(p);
      p.handleTakeoutFinished();
      expect(p.currentGame!.getCurrentPlayerId(), 'p2');
    });

    test('advanceToNextPlayer switches from p2 back to p1', () {
      final p = _makeProvider();
      p.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);
      completeTurn(p); // p1 → p2
      completeTurn(p); // p2 → p1
      expect(p.currentGame!.getCurrentPlayerId(), 'p1');
    });

    test('handleTakeoutFinished does nothing if not waitingForTakeout', () {
      final p = _makeProvider();
      p.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);
      p.handleTakeoutFinished();
      // Still p1 — no advance
      expect(p.currentGame!.getCurrentPlayerId(), 'p1');
    });

    test('skipTurn sets shouldPromptTakeout after 0 darts', () {
      final p = _makeProvider();
      p.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);
      p.skipTurn();
      expect(p.shouldPromptTakeout, isTrue);
    });

    test('skipTurn adds Skip markers for remaining darts', () {
      final p = _makeProvider();
      p.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);
      miss(p); // 1 dart thrown
      p.skipTurn();
      final segs = p.getCurrentTurnDartSegments('p1');
      expect(segs.length, 3);
      expect(segs[1], 'Skip');
      expect(segs[2], 'Skip');
    });

    test('skipTurn from 0 darts adds 3 Skip markers', () {
      final p = _makeProvider();
      p.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);
      p.skipTurn();
      final segs = p.getCurrentTurnDartSegments('p1');
      expect(segs, ['Skip', 'Skip', 'Skip']);
    });

    test('skipTurn is a no-op when already waitingForTakeout', () {
      final p = _makeProvider();
      p.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);
      miss(p);
      miss(p);
      miss(p);
      final segsBefore = List<String>.from(p.getCurrentTurnDartSegments('p1'));
      p.skipTurn(); // should be no-op
      expect(p.getCurrentTurnDartSegments('p1'), segsBefore);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // 8. Win detection — round winner
  // ─────────────────────────────────────────────────────────────────────────────

  group('PiratesGridProvider — win detection', () {
    test('top row three-in-a-row wins the round', () {
      final p = _makeProvider();
      p.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);
      final game = p.currentGame!;
      game.grid[0][0].claimedBy = 'p1';
      game.grid[0][1].claimedBy = 'p1';
      hitEasy(p, 0, 2); // completes top row
      expect(game.winnerId, 'p1');
      expect(game.winningLine, isNotNull);
      expect(game.winningLine!.length, 3);
    });

    test('middle row three-in-a-row wins the round', () {
      final p = _makeProvider();
      p.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);
      final game = p.currentGame!;
      game.grid[1][0].claimedBy = 'p1';
      game.grid[1][1].claimedBy = 'p1';
      hitEasy(p, 1, 2);
      expect(game.winnerId, 'p1');
    });

    test('left column three-in-a-row wins the round', () {
      final p = _makeProvider();
      p.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);
      final game = p.currentGame!;
      game.grid[0][0].claimedBy = 'p1';
      game.grid[1][0].claimedBy = 'p1';
      hitEasy(p, 2, 0);
      expect(game.winnerId, 'p1');
    });

    test('top-left to bottom-right diagonal wins the round', () {
      final p = _makeProvider();
      p.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);
      final game = p.currentGame!;
      game.grid[0][0].claimedBy = 'p1';
      game.grid[1][1].claimedBy = 'p1';
      hitEasy(p, 2, 2);
      expect(game.winnerId, 'p1');
    });

    test('top-right to bottom-left diagonal wins the round', () {
      final p = _makeProvider();
      p.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);
      final game = p.currentGame!;
      game.grid[0][2].claimedBy = 'p1';
      game.grid[1][1].claimedBy = 'p1';
      hitEasy(p, 2, 0);
      expect(game.winnerId, 'p1');
    });

    test('grid full with no winner produces round draw', () {
      final p = _makeProvider();
      p.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);
      final game = p.currentGame!;
      // Classic no-win draw pattern (p1 never gets 3 in a row):
      //   p1 p2 p1
      //   p2 p2 p1
      //   p1 __  p2
      // p1 will claim (2,1) → fills grid, no 3-in-a-row for either
      game.grid[0][0].claimedBy = 'p1';
      game.grid[0][1].claimedBy = 'p2';
      game.grid[0][2].claimedBy = 'p1';
      game.grid[1][0].claimedBy = 'p2';
      game.grid[1][1].claimedBy = 'p2';
      game.grid[1][2].claimedBy = 'p1';
      game.grid[2][0].claimedBy = 'p1';
      game.grid[2][2].claimedBy = 'p2';
      // (2,1) is empty — p1 will claim it; no 3-in-a-row results
      hitEasy(p, 2, 1);
      expect(game.isDraw, isTrue);
      expect(game.winnerId, isNull);
    });

    test('round win sets shouldPromptTakeout true', () {
      final p = _makeProvider();
      p.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);
      final game = p.currentGame!;
      game.grid[0][0].claimedBy = 'p1';
      game.grid[0][1].claimedBy = 'p1';
      hitEasy(p, 0, 2);
      expect(p.shouldPromptTakeout, isTrue);
    });

    test('isCurrentRoundFinished is true after round win', () {
      final p = _makeProvider();
      p.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);
      final game = p.currentGame!;
      game.grid[0][0].claimedBy = 'p1';
      game.grid[0][1].claimedBy = 'p1';
      hitEasy(p, 0, 2);
      expect(p.isCurrentRoundFinished, isTrue);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // 9. Best Of round transitions
  // ─────────────────────────────────────────────────────────────────────────────

  group('PiratesGridProvider — Best Of round transitions', () {
    test('Bo1: round win is match win; state becomes finished', () {
      final p = _makeProvider();
      p.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);
      winRoundForCurrentPlayer(p);
      expect(p.currentGame!.matchWinnerId, 'p1');
      expect(p.currentGame!.state, GameState.finished);
      expect(p.isGameActive, isFalse);
    });

    test('Bo3: first round win increments roundsWon and continues match', () {
      final p = _makeProvider();
      p.startGame(['p1', 'p2'], TargetDifficulty.easy, 3, false, false);
      winRoundForCurrentPlayer(p);
      expect(p.currentGame!.roundsWon['p1'], 1);
      expect(p.currentGame!.matchWinnerId, isNull);
      expect(p.currentGame!.currentRound, 2);
    });

    test('Bo3: second round win for same player wins match', () {
      final p = _makeProvider();
      p.startGame(['p1', 'p2'], TargetDifficulty.easy, 3, false, false);
      winRoundForPlayer(p, 'p1'); // round 1 → p1 has 1 win
      winRoundForPlayer(p, 'p1'); // round 2 → p1 has 2 wins → match over
      expect(p.currentGame!.matchWinnerId, 'p1');
      expect(p.currentGame!.state, GameState.finished);
    });

    test('Bo5: first to 3 round wins wins match', () {
      final p = _makeProvider();
      p.startGame(['p1', 'p2'], TargetDifficulty.easy, 5, false, false);
      winRoundForPlayer(p, 'p1');
      winRoundForPlayer(p, 'p1');
      expect(p.currentGame!.matchWinnerId, isNull);
      winRoundForPlayer(p, 'p1');
      expect(p.currentGame!.matchWinnerId, 'p1');
    });

    test('grid resets between rounds (all cells unclaimed)', () {
      final p = _makeProvider();
      p.startGame(['p1', 'p2'], TargetDifficulty.easy, 3, false, false);
      winRoundForCurrentPlayer(p); // round 1 ends, grid resets
      for (final row in p.currentGame!.grid) {
        for (final cell in row) {
          expect(cell.claimedBy, isNull);
        }
      }
    });

    test('starting player alternates between rounds', () {
      final p = _makeProvider();
      p.startGame(['p1', 'p2'], TargetDifficulty.easy, 3, false, false);
      expect(p.currentGame!.currentRoundStartingPlayerIndex, 0);
      winRoundForCurrentPlayer(p); // round 1 ends
      expect(p.currentGame!.currentRoundStartingPlayerIndex, 1);
      expect(p.currentGame!.currentPlayerIndex, 1);
    });

    test('round draw advances to next round without incrementing roundsWon', () {
      final p = _makeProvider();
      p.startGame(['p1', 'p2'], TargetDifficulty.easy, 3, false, false);
      final game = p.currentGame!;

      // Force a draw: fill all cells with no 3-in-a-row, p1's turn
      game.grid[0][0].claimedBy = 'p1';
      game.grid[0][1].claimedBy = 'p2';
      game.grid[0][2].claimedBy = 'p1';
      game.grid[1][0].claimedBy = 'p2';
      game.grid[1][1].claimedBy = 'p2';
      game.grid[1][2].claimedBy = 'p1';
      game.grid[2][0].claimedBy = 'p1';
      game.grid[2][2].claimedBy = 'p2';
      hitEasy(p, 2, 1); // fills grid → draw
      p.handleTakeoutFinished(); // transitions to round 2

      expect(game.roundsWon['p1'], 0);
      expect(game.roundsWon['p2'], 0);
      expect(game.currentRound, 2);
    });

    test('matchWinnerId and gameEndTime are set on match win', () {
      final p = _makeProvider();
      p.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);
      winRoundForCurrentPlayer(p);
      expect(p.currentGame!.matchWinnerId, isNotNull);
      expect(p.currentGame!.gameEndTime, isNotNull);
    });

    test('hasWinner returns true after match win', () {
      final p = _makeProvider();
      p.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);
      winRoundForCurrentPlayer(p);
      expect(p.hasWinner, isTrue);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // 10. _resetTurnForPlayer (via editPlayerScore)
  // ─────────────────────────────────────────────────────────────────────────────

  group('PiratesGridProvider — editPlayerScore turn undo', () {
    test('editing dart segments un-claims cells from this turn', () {
      final p = _makeProvider();
      p.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);
      final n = numAt(p, 0, 0);
      p.processDartThrow(score: n, multiplier: 1, sector: 'S$n');
      expect(p.currentGame!.grid[0][0].claimedBy, 'p1');

      // Edit: replace with 3 misses
      p.editPlayerScore(playerId: 'p1', newSegments: ['S99', 'S99', 'S99']);
      expect(p.currentGame!.grid[0][0].claimedBy, isNull);
    });

    test('editing to hit a different cell claims new cell and un-claims old', () {
      final p = _makeProvider();
      p.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);
      final n00 = numAt(p, 0, 0);
      final n01 = numAt(p, 0, 1);
      p.processDartThrow(score: n00, multiplier: 1, sector: 'S$n00');
      expect(p.currentGame!.grid[0][0].claimedBy, 'p1');

      // Edit: now hit (0,1) instead
      p.editPlayerScore(playerId: 'p1', newSegments: ['S$n01', 'S99', 'S99']);
      expect(p.currentGame!.grid[0][0].claimedBy, isNull);
      expect(p.currentGame!.grid[0][1].claimedBy, 'p1');
    });

    test('editPlayerScore for non-current player is ignored', () {
      final p = _makeProvider();
      p.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);
      final n = numAt(p, 0, 0);
      // p1 is current; try to edit p2's score
      p.editPlayerScore(playerId: 'p2', newSegments: ['S$n', 'S$n', 'S$n']);
      // p2's cells should not be claimed
      expect(p.currentGame!.grid[0][0].claimedBy, isNull);
    });

    test('_resetTurnForPlayer undoes round win caused by this turn', () {
      final p = _makeProvider();
      p.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);
      final game = p.currentGame!;
      game.grid[0][0].claimedBy = 'p1';
      game.grid[0][1].claimedBy = 'p1';
      final n = numAt(p, 0, 2);
      p.processDartThrow(score: n, multiplier: 1, sector: 'S$n'); // wins round
      expect(game.winnerId, 'p1');

      // Edit: replace winning dart with all misses — round win should be undone
      p.editPlayerScore(playerId: 'p1', newSegments: ['S99', 'S99', 'S99']);
      expect(game.winnerId, isNull);
      expect(game.roundsWon['p1'], 0);
    });

    test('_resetTurnForPlayer undoes match win if turn caused it', () {
      final p = _makeProvider();
      p.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);
      final game = p.currentGame!;
      // Pre-claim 2 cells
      game.grid[0][0].claimedBy = 'p1';
      game.grid[0][1].claimedBy = 'p1';
      final n = numAt(p, 0, 2);
      p.processDartThrow(score: n, multiplier: 1, sector: 'S$n');
      // Bo1 → match win
      expect(game.matchWinnerId, 'p1');
      expect(game.state, GameState.finished);

      // Edit: remove the winning dart → match un-won
      p.editPlayerScore(playerId: 'p1', newSegments: ['S99', 'S99', 'S99']);
      expect(game.matchWinnerId, isNull);
      expect(game.state, GameState.playing);
      expect(p.isGameActive, isTrue);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // 11. endGame and clearGame
  // ─────────────────────────────────────────────────────────────────────────────

  group('PiratesGridProvider — endGame and clearGame', () {
    test('endGame sets isGameActive false', () {
      final p = _makeProvider();
      p.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);
      expect(p.isGameActive, isTrue);
      p.endGame();
      expect(p.isGameActive, isFalse);
    });

    test('endGame sets state to finished', () {
      final p = _makeProvider();
      p.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);
      p.endGame();
      expect(p.currentGame!.state, GameState.finished);
    });

    test('endGame sets gameEndTime', () {
      final p = _makeProvider();
      p.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);
      p.endGame();
      expect(p.currentGame!.gameEndTime, isNotNull);
    });

    test('clearGame removes the game entirely', () {
      final p = _makeProvider();
      p.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);
      p.clearGame();
      expect(p.currentGame, isNull);
      expect(p.isGameActive, isFalse);
    });

    test('clearGame resets shouldPromptTakeout', () {
      final p = _makeProvider();
      p.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);
      miss(p);
      miss(p);
      miss(p);
      expect(p.shouldPromptTakeout, isTrue);
      p.clearGame();
      expect(p.shouldPromptTakeout, isFalse);
    });

    test('resumedSavedGameId is null by default', () {
      final p = _makeProvider();
      expect(p.resumedSavedGameId, isNull);
    });

    test('clearResumedSavedGameId resets to null after restore', () {
      final p = _makeProvider();
      p.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);
      final game = p.currentGame!;
      final json = game.toJson();
      final fakeMetadata = SavedGameMetadata(
        id: 'test-id',
        gameType: 'pirates_grid',
        savedAt: DateTime.now(),
        playerNames: ['Alice', 'Bob'],
        progressInfo: '',
        gameModeName: '',
        leadingPlayerName: '',
        leadingPlayerScore: '',
        gameState: json,
        waitingForTakeout: false,
      );
      p.restoreGame(fakeMetadata);
      expect(p.resumedSavedGameId, 'test-id');
      p.clearResumedSavedGameId();
      expect(p.resumedSavedGameId, isNull);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // 12. getFlagsPlanted
  // ─────────────────────────────────────────────────────────────────────────────

  group('PiratesGridProvider — getFlagsPlanted', () {
    test('getFlagsPlanted returns 0 at start', () {
      final p = _makeProvider();
      p.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);
      expect(p.currentGame!.getFlagsPlanted('p1'), 0);
    });

    test('getFlagsPlanted increments on each claimed cell', () {
      final p = _makeProvider();
      p.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);
      hitEasy(p, 0, 0);
      expect(p.currentGame!.getFlagsPlanted('p1'), 1);
      hitEasy(p, 0, 1);
      expect(p.currentGame!.getFlagsPlanted('p1'), 2);
    });
  });
}

