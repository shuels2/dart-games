import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/models/pirates_grid_game.dart';
import 'package:dart_games/providers/pirates_grid_provider.dart';

// ─── Runtime helpers ──────────────────────────────────────────────────────────

/// Returns the target number at [row],[col].
int _n(PiratesGridProvider p, int row, int col) =>
    p.currentGame!.grid[row][col].target.number;

/// Returns the requirement at [row],[col].
CellRequirement _req(PiratesGridProvider p, int row, int col) =>
    p.currentGame!.grid[row][col].target.requirement;

/// Builds the sector string for a hit on cell [row],[col] given [multiplier].
String _sector(int number, int multiplier) {
  if (multiplier == 2) return 'D$number';
  if (multiplier == 3) return 'T$number';
  return 'S$number';
}

/// Returns the required multiplier for a cell's requirement in Easy/Medium.
/// For Hard, position rules apply: corner=triple, edge=double, center=bull.
int _multiplierFor(CellRequirement req) {
  switch (req) {
    case CellRequirement.tripleOnly:
      return 3;
    case CellRequirement.doubleOnly:
    case CellRequirement.doubleOrTriple:
      return 2;
    case CellRequirement.any:
      return 1;
    case CellRequirement.bull:
      return 1; // handled specially
  }
}

/// Throws a dart that successfully claims cell [row],[col].
/// Handles bull specially for Hard mode center.
///
/// Note: [score] is the BASE number (1–20), not the total. The provider's
/// processDartThrow uses score=dartNumber to match against cell.target.number.
void _hitCell(PiratesGridProvider p, int row, int col) {
  final req = _req(p, row, col);
  if (req == CellRequirement.bull) {
    // Bull: outer bull score=25 multiplier=1 sector='Bull'
    p.processDartThrow(score: 25, multiplier: 1, sector: 'Bull');
  } else {
    final n = _n(p, row, col);
    final mult = _multiplierFor(req);
    // score = base number (not n*mult) — matches() checks dartNumber == number
    p.processDartThrow(score: n, multiplier: mult, sector: _sector(n, mult));
  }
}

/// Throws a miss dart (score 99, never in grid).
void _miss(PiratesGridProvider p) =>
    p.processDartThrow(score: 99, multiplier: 1, sector: 'S99');

/// Fills remaining darts for the current player with misses then calls
/// handleTakeoutFinished.
void _completeTurn(PiratesGridProvider p) {
  while (p.getCurrentPlayerDartsThrown() < 3) {
    _miss(p);
  }
  p.handleTakeoutFinished();
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  group("Pirate's Grid game logic", () {
    late PiratesGridProvider provider;

    setUp(() {
      provider = PiratesGridProvider();
    });

    // ── Grid Setup (3 tests) ────────────────────────────────────────────────────

    group('Grid Setup', () {
      test('Easy difficulty: 3x3 grid generates 9 cells with correct targets', () {
        provider.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);
        final game = provider.currentGame!;
        final grid = game.grid;

        expect(grid.length, equals(3));
        expect(grid[0].length, equals(3));

        // All 9 cells have numbers in range 1–20 (shuffled per game)
        final numbers = <int>{};
        for (final row in grid) {
          for (final cell in row) {
            expect(cell.target.number, inInclusiveRange(1, 20));
            numbers.add(cell.target.number);
          }
        }
        // All 9 numbers must be unique
        expect(numbers.length, equals(9));

        // All cells have 'any' requirement
        for (final row in grid) {
          for (final cell in row) {
            expect(cell.target.requirement, equals(CellRequirement.any),
                reason: 'Easy mode should use "any" requirement for all cells');
          }
        }

        // All cells are unclaimed
        for (final row in grid) {
          for (final cell in row) {
            expect(cell.claimedBy, isNull);
          }
        }
      });

      test('Medium difficulty: same numbers but doubleOrTriple requirement', () {
        provider.startGame(['p1', 'p2'], TargetDifficulty.medium, 1, false, false);
        final game = provider.currentGame!;
        final grid = game.grid;

        // 9 unique numbers in 1–20
        final numbers = <int>{};
        for (final row in grid) {
          for (final cell in row) {
            expect(cell.target.number, inInclusiveRange(1, 20));
            numbers.add(cell.target.number);
          }
        }
        expect(numbers.length, equals(9));

        // All cells require double or triple
        for (final row in grid) {
          for (final cell in row) {
            expect(cell.target.requirement, equals(CellRequirement.doubleOrTriple),
                reason: 'Medium mode should require doubleOrTriple for all cells');
          }
        }
      });

      test(
          'Hard difficulty: corners require triple, edges require double, '
          'center is Bull', () {
        provider.startGame(['p1', 'p2'], TargetDifficulty.hard, 1, false, false);
        final game = provider.currentGame!;
        final grid = game.grid;

        // Corners: (0,0), (0,2), (2,0), (2,2) — tripleOnly, numbers 1–20
        for (final pos in [(0, 0), (0, 2), (2, 0), (2, 2)]) {
          final cell = grid[pos.$1][pos.$2];
          expect(cell.target.number, inInclusiveRange(1, 20),
              reason: 'Corner (${pos.$1},${pos.$2}) number should be 1–20');
          expect(cell.target.requirement, equals(CellRequirement.tripleOnly),
              reason: 'Corner (${pos.$1},${pos.$2}) should be tripleOnly');
        }

        // Edges: (0,1), (1,0), (1,2), (2,1) — doubleOnly, numbers 1–20
        for (final pos in [(0, 1), (1, 0), (1, 2), (2, 1)]) {
          final cell = grid[pos.$1][pos.$2];
          expect(cell.target.number, inInclusiveRange(1, 20),
              reason: 'Edge (${pos.$1},${pos.$2}) number should be 1–20');
          expect(cell.target.requirement, equals(CellRequirement.doubleOnly),
              reason: 'Edge (${pos.$1},${pos.$2}) should be doubleOnly');
        }

        // Center: (1,1) Bull
        expect(grid[1][1].target.requirement, equals(CellRequirement.bull));

        // All non-center numbers are unique and in range
        final numbers = <int>{};
        for (int r = 0; r < 3; r++) {
          for (int c = 0; c < 3; c++) {
            if (r == 1 && c == 1) continue; // center is Bull (number=0)
            expect(grid[r][c].target.number, inInclusiveRange(1, 20));
            numbers.add(grid[r][c].target.number);
          }
        }
        expect(numbers.length, equals(8));
      });
    });

    // ── Flag Placement (7 tests) ────────────────────────────────────────────────

    group('Flag Placement', () {
      test('Single hit on Easy cell plants flag', () {
        provider.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);
        // Use the actual target number at (0,0) — Easy uses CellRequirement.any
        final n = _n(provider, 0, 0);
        provider.processDartThrow(score: n, multiplier: 1, sector: 'S$n');
        final cell = provider.currentGame!.grid[0][0];
        expect(cell.claimedBy, equals('p1'));
      });

      test('Double hit on D cell plants flag (Medium)', () {
        provider.startGame(['p1', 'p2'], TargetDifficulty.medium, 1, false, false);
        // Medium requires doubleOrTriple; use a double on (0,1)
        // score = base number (not n*2) — processDartThrow matches on base number
        final n = _n(provider, 0, 1);
        provider.processDartThrow(score: n, multiplier: 2, sector: 'D$n');
        final cell = provider.currentGame!.grid[0][1];
        expect(cell.claimedBy, equals('p1'));
      });

      test('Triple hit on T cell plants flag (Hard)', () {
        provider.startGame(['p1', 'p2'], TargetDifficulty.hard, 1, false, false);
        // (0,0) is a corner — requires tripleOnly
        // score = base number (not n*3) — processDartThrow matches on base number
        final n = _n(provider, 0, 0);
        provider.processDartThrow(score: n, multiplier: 3, sector: 'T$n');
        final cell = provider.currentGame!.grid[0][0];
        expect(cell.claimedBy, equals('p1'));
      });

      test('Single hit on D cell does NOT plant flag (Medium)', () {
        provider.startGame(['p1', 'p2'], TargetDifficulty.medium, 1, false, false);
        // Medium requires doubleOrTriple; single hit must fail
        final n = _n(provider, 0, 1);
        provider.processDartThrow(score: n, multiplier: 1, sector: 'S$n');
        final cell = provider.currentGame!.grid[0][1];
        expect(cell.claimedBy, isNull);
      });

      test('Hit on already-owned cell has no effect', () {
        provider.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);
        final n = _n(provider, 0, 0);
        // P1 plants flag at (0,0)
        provider.processDartThrow(score: n, multiplier: 1, sector: 'S$n');
        // P1 throws again at same cell (within 3 darts, still p1's turn)
        provider.processDartThrow(score: n, multiplier: 1, sector: 'S$n');
        final cell = provider.currentGame!.grid[0][0];
        // Still p1 — cell ownership unchanged
        expect(cell.claimedBy, equals('p1'));
      });

      test('Hit on opponent cell with Steal Mode OFF has no effect', () {
        provider.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);
        final n = _n(provider, 0, 0);
        // P1 plants flag at (0,0)
        provider.processDartThrow(score: n, multiplier: 1, sector: 'S$n');
        // Advance to P2 (simulate 3 darts total then takeout)
        provider.processDartThrow(score: 99, multiplier: 1, sector: 'S99'); // miss
        provider.processDartThrow(score: 99, multiplier: 1, sector: 'S99'); // miss
        provider.handleTakeoutFinished(); // advance to P2

        // P2 hits same cell with Steal OFF
        provider.processDartThrow(score: n, multiplier: 1, sector: 'S$n');
        final cell = provider.currentGame!.grid[0][0];
        expect(cell.claimedBy, equals('p1'), reason: 'Steal OFF should not replace p1 flag');
      });

      test('Hit on opponent cell with Steal Mode ON replaces opponent flag', () {
        provider.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, true, false);
        final n = _n(provider, 0, 0);
        // P1 plants flag at (0,0)
        provider.processDartThrow(score: n, multiplier: 1, sector: 'S$n');
        // 2 more misses to end p1's turn
        provider.processDartThrow(score: 99, multiplier: 1, sector: 'S99');
        provider.processDartThrow(score: 99, multiplier: 1, sector: 'S99');
        provider.handleTakeoutFinished(); // advance to P2

        // P2 hits same cell with Steal ON → takes (0,0) from P1
        provider.processDartThrow(score: n, multiplier: 1, sector: 'S$n');
        final cell = provider.currentGame!.grid[0][0];
        expect(cell.claimedBy, equals('p2'), reason: 'Steal ON should give p2 the cell');
      });
    });

    // ── Win Detection (5 tests) ─────────────────────────────────────────────────

    group('Win Detection', () {
      /// Helper: plant flags for a player at a specific row/col using Easy mode.
      void plantFlag(PiratesGridProvider p, String playerId, int row, int col) {
        final game = p.currentGame!;
        // Directly set for easier test control
        game.grid[row][col].claimedBy = playerId;
      }

      test('Horizontal 3 in a row wins round', () {
        provider.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);
        final game = provider.currentGame!;

        // Plant 2 flags for p1 manually in top row
        plantFlag(provider, 'p1', 0, 0);
        plantFlag(provider, 'p1', 0, 1);
        // Throw a single to claim (0,2) — read actual number at (0,2)
        _hitCell(provider, 0, 2);

        expect(game.winnerId, equals('p1'));
        expect(game.winningLine, isNotNull);
        expect(game.winningLine!.length, equals(3));
      });

      test('Vertical 3 in a row wins round', () {
        provider.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);
        final game = provider.currentGame!;

        plantFlag(provider, 'p1', 0, 0);
        plantFlag(provider, 'p1', 1, 0);
        // Claim (2,0) using the actual number
        _hitCell(provider, 2, 0);

        expect(game.winnerId, equals('p1'));
        expect(game.winningLine, isNotNull);
        expect(game.winningLine!.length, equals(3));
      });

      test('Diagonal (top-left to bottom-right) wins round', () {
        provider.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);
        final game = provider.currentGame!;

        plantFlag(provider, 'p1', 0, 0);
        plantFlag(provider, 'p1', 1, 1);
        // Claim (2,2) using the actual number
        _hitCell(provider, 2, 2);

        expect(game.winnerId, equals('p1'));
        expect(game.winningLine, isNotNull);
      });

      test('Diagonal (top-right to bottom-left) wins round', () {
        provider.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);
        final game = provider.currentGame!;

        plantFlag(provider, 'p1', 0, 2);
        plantFlag(provider, 'p1', 1, 1);
        // Claim (2,0) using the actual number
        _hitCell(provider, 2, 0);

        expect(game.winnerId, equals('p1'));
        expect(game.winningLine, isNotNull);
      });

      test('Full grid with no 3 in a row = draw', () {
        provider.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);
        final game = provider.currentGame!;

        // Classic tic-tac-toe draw pattern (no 3-in-a-row for either player):
        //  p1  p2  p1
        //  p2  p2  p1
        //  p1  __  p2   <- (2,1) is the last cell, thrown by p1
        //
        // p1 cells: (0,0),(0,2),(1,2),(2,0)  → plus (2,1) after throw
        // p2 cells: (0,1),(1,0),(1,1),(2,2)
        //
        // After throw: p1 has (0,0),(0,2),(1,2),(2,0),(2,1) — no 3-in-a-row
        // Check p1 diagonals: (0,0)-(1,1)-(2,2)? (1,1) is p2. OK.
        //                     (0,2)-(1,1)-(2,0)? (1,1) is p2. OK.
        game.grid[0][0].claimedBy = 'p1';
        game.grid[0][1].claimedBy = 'p2';
        game.grid[0][2].claimedBy = 'p1';
        game.grid[1][0].claimedBy = 'p2';
        game.grid[1][1].claimedBy = 'p2';
        game.grid[1][2].claimedBy = 'p1';
        game.grid[2][0].claimedBy = 'p1';
        game.grid[2][2].claimedBy = 'p2';
        // Leave (2,1) empty — p1 will claim it via processDartThrow
        // Read the actual number at (2,1) — shuffled per game
        _hitCell(provider, 2, 1);

        expect(game.isDraw, isTrue,
            reason: 'Grid full with no 3-in-a-row should be a draw');
        expect(game.winnerId, isNull);
      });
    });

    // ── Game Flow (5 tests) ─────────────────────────────────────────────────────

    group('Game Flow', () {
      test('Turn advances to next player after 3 darts (handleTakeoutFinished called)', () {
        provider.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);
        expect(provider.currentGame!.currentPlayerIndex, equals(0));

        // Throw 3 misses for P1
        provider.processDartThrow(score: 99, multiplier: 1, sector: 'S99');
        provider.processDartThrow(score: 99, multiplier: 1, sector: 'S99');
        provider.processDartThrow(score: 99, multiplier: 1, sector: 'S99');

        expect(provider.shouldPromptTakeout, isTrue);
        provider.handleTakeoutFinished();

        expect(provider.currentGame!.currentPlayerIndex, equals(1));
      });

      test('Skip turn clears remaining darts and ends turn', () {
        provider.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);
        // Throw 1 dart then skip
        provider.processDartThrow(score: 99, multiplier: 1, sector: 'S99');
        provider.skipTurn();

        expect(provider.shouldPromptTakeout, isTrue);
        final segments = provider.getCurrentTurnDartSegments('p1');
        // Should have 1 real dart + 2 Skip markers
        expect(segments.length, equals(3));
        expect(segments[1], equals('Skip'));
        expect(segments[2], equals('Skip'));
      });

      test('Skip turn with 0 darts thrown advances directly', () {
        provider.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);
        provider.skipTurn();

        expect(provider.shouldPromptTakeout, isTrue);
        final segments = provider.getCurrentTurnDartSegments('p1');
        expect(segments.length, equals(3));
        expect(segments.every((s) => s == 'Skip'), isTrue);
      });

      test('Players alternate turns correctly across multiple turn cycles', () {
        provider.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);

        // Turn 1: P1 throws 3 misses
        provider.processDartThrow(score: 99, multiplier: 1, sector: 'S99');
        provider.processDartThrow(score: 99, multiplier: 1, sector: 'S99');
        provider.processDartThrow(score: 99, multiplier: 1, sector: 'S99');
        provider.handleTakeoutFinished();
        expect(provider.currentGame!.currentPlayerIndex, equals(1)); // P2's turn

        // Turn 2: P2 throws 3 misses
        provider.processDartThrow(score: 99, multiplier: 1, sector: 'S99');
        provider.processDartThrow(score: 99, multiplier: 1, sector: 'S99');
        provider.processDartThrow(score: 99, multiplier: 1, sector: 'S99');
        provider.handleTakeoutFinished();
        expect(provider.currentGame!.currentPlayerIndex, equals(0)); // P1's turn again
      });

      test('Win ends round immediately, no more darts processed in same turn', () {
        provider.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);
        final game = provider.currentGame!;

        // P1 pre-claims 2 cells in the top row
        game.grid[0][0].claimedBy = 'p1';
        game.grid[0][1].claimedBy = 'p1';

        // P1 claims (0,2) → round win using actual number
        _hitCell(provider, 0, 2);
        expect(game.winnerId, equals('p1'));

        // Try to process another dart — should be ignored (round won)
        // Use a number that would match (0,1) which is p1's but round is over
        final n01 = _n(provider, 0, 1);
        provider.processDartThrow(score: n01, multiplier: 1, sector: 'S$n01');
        // (0,1) is still p1's (not overwritten or caused issues)
        expect(game.winnerId, equals('p1'));
        expect(game.grid[0][1].claimedBy, equals('p1'));
      });
    });

    // ── Best Of Rounds (5 tests) ────────────────────────────────────────────────

    group('Best Of Rounds', () {
      /// Helper: win a round for [playerId] by planting flags in top row.
      void winRoundForPlayer(PiratesGridProvider p, String playerId) {
        final game = p.currentGame!;
        // Reset current player to playerId
        game.currentPlayerIndex = game.playerIds.indexOf(playerId);
        // Pre-plant 2 flags
        game.grid[0][0].claimedBy = playerId;
        game.grid[0][1].claimedBy = playerId;
        // Throw winning dart at (0,2) using actual target number
        _hitCell(p, 0, 2);
        // Trigger takeout to process round transition
        p.handleTakeoutFinished();
      }

      test('Best Of 1: single round, match ends on round win', () {
        provider.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);
        winRoundForPlayer(provider, 'p1');

        final game = provider.currentGame!;
        expect(game.matchWinnerId, equals('p1'));
        expect(game.state, equals(GameState.finished));
      });

      test('Best Of 3: first to 2 round wins wins match', () {
        provider.startGame(['p1', 'p2'], TargetDifficulty.easy, 3, false, false);

        // P1 wins round 1
        winRoundForPlayer(provider, 'p1');
        expect(provider.currentGame!.matchWinnerId, isNull, reason: 'Match not over after 1 win');
        expect(provider.currentGame!.currentRound, equals(2));

        // P1 wins round 2 → match over
        winRoundForPlayer(provider, 'p1');
        expect(provider.currentGame!.matchWinnerId, equals('p1'));
        expect(provider.currentGame!.state, equals(GameState.finished));
      });

      test('Best Of 5: first to 3 round wins wins match', () {
        provider.startGame(['p1', 'p2'], TargetDifficulty.easy, 5, false, false);

        winRoundForPlayer(provider, 'p1');
        winRoundForPlayer(provider, 'p1');
        expect(provider.currentGame!.matchWinnerId, isNull, reason: 'Match not over after 2 wins in Bo5');

        winRoundForPlayer(provider, 'p1');
        expect(provider.currentGame!.matchWinnerId, equals('p1'));
        expect(provider.currentGame!.state, equals(GameState.finished));
      });

      test('Grid resets between rounds (cells become empty)', () {
        provider.startGame(['p1', 'p2'], TargetDifficulty.easy, 3, false, false);

        // P1 wins round 1
        winRoundForPlayer(provider, 'p1');
        final game = provider.currentGame!;

        // After round transition, all cells should be unclaimed
        for (final row in game.grid) {
          for (final cell in row) {
            expect(cell.claimedBy, isNull,
                reason: 'Grid should be cleared between rounds');
          }
        }
      });

      test('Starting player alternates between rounds', () {
        provider.startGame(['p1', 'p2'], TargetDifficulty.easy, 3, false, false);
        final game = provider.currentGame!;

        expect(game.currentRoundStartingPlayerIndex, equals(0));

        // P1 wins round 1
        winRoundForPlayer(provider, 'p1');

        // Round 2 should start with P2 (index 1)
        expect(game.currentRoundStartingPlayerIndex, equals(1));
        expect(game.currentPlayerIndex, equals(1));

        // P1 wins round 2 (from P2's starting position) → match over
        winRoundForPlayer(provider, 'p1');
        expect(game.matchWinnerId, equals('p1'));
      });
    });

    // ── Turn Increment Rule (1 test, mandatory project rule) ───────────────────

    group('Turn Increment Rule', () {
      test('totalTurns increments exactly once per turn (on first dart only)', () {
        provider.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);
        final game = provider.currentGame!;

        // Initially 0 turns
        expect(game.totalTurns['p1'], equals(0));

        // First dart — totalTurns should become 1
        provider.processDartThrow(score: 99, multiplier: 1, sector: 'S99');
        expect(game.totalTurns['p1'], equals(1));

        // Second dart of same turn — totalTurns should NOT increment
        provider.processDartThrow(score: 99, multiplier: 1, sector: 'S99');
        expect(game.totalTurns['p1'], equals(1));

        // Third dart of same turn — totalTurns should NOT increment
        provider.processDartThrow(score: 99, multiplier: 1, sector: 'S99');
        expect(game.totalTurns['p1'], equals(1));

        // Advance to next player and P1 gets another turn
        provider.handleTakeoutFinished();
        provider.processDartThrow(score: 99, multiplier: 1, sector: 'S99'); // P2
        provider.processDartThrow(score: 99, multiplier: 1, sector: 'S99'); // P2
        provider.processDartThrow(score: 99, multiplier: 1, sector: 'S99'); // P2
        provider.handleTakeoutFinished(); // back to P1

        // P1's second turn — first dart increments totalTurns
        provider.processDartThrow(score: 99, multiplier: 1, sector: 'S99');
        expect(game.totalTurns['p1'], equals(2));

        // Second dart of turn 2 — no increment
        provider.processDartThrow(score: 99, multiplier: 1, sector: 'S99');
        expect(game.totalTurns['p1'], equals(2));
      });
    });

    // ── Edit Score (1 test) ────────────────────────────────────────────────────

    group('Edit Score', () {
      test('editPlayerScore replays turn with new segments correctly', () {
        provider.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);
        final game = provider.currentGame!;

        // P1 throws a dart hitting (0,0) — use actual number
        final n = _n(provider, 0, 0);
        provider.processDartThrow(score: n, multiplier: 1, sector: 'S$n');
        expect(game.grid[0][0].claimedBy, equals('p1'));

        // Edit: replace that dart with S99 (miss)
        provider.editPlayerScore(playerId: 'p1', newSegments: ['S99', 'Miss', 'Miss']);

        // (0,0) should be unclaimed after edit
        expect(game.grid[0][0].claimedBy, isNull,
            reason: 'Editing dart to a miss should un-claim the cell');
      });
    });

    // ── Speed Play (1 test) ────────────────────────────────────────────────────

    group('Speed Play', () {
      test('Speed Play setting persists in game state', () {
        provider.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, true);
        expect(provider.currentGame!.speedPlay, isTrue);
      });

      test('Speed Play OFF setting also persists', () {
        provider.startGame(['p1', 'p2'], TargetDifficulty.easy, 1, false, false);
        expect(provider.currentGame!.speedPlay, isFalse);
      });
    });

    // ── Serialization (2 tests) ───────────────────────────────────────────────

    group('Serialization', () {
      test('toJson / fromJson round-trips the game state', () {
        provider.startGame(['p1', 'p2'], TargetDifficulty.hard, 3, true, true);
        final game = provider.currentGame!;

        // Make some moves — hit corner (0,0) which requires triple, then a miss
        // score = base number (not n*3) — processDartThrow matches on base number
        final n00 = _n(provider, 0, 0);
        provider.processDartThrow(score: n00, multiplier: 3, sector: 'T$n00');
        provider.processDartThrow(score: 99, multiplier: 1, sector: 'S99');

        final json = game.toJson();
        final restored = PiratesGridGame.fromJson(json);

        expect(restored.id, equals(game.id));
        expect(restored.targetDifficulty, equals(TargetDifficulty.hard));
        expect(restored.bestOf, equals(3));
        expect(restored.stealMode, isTrue);
        expect(restored.speedPlay, isTrue);
        expect(restored.playerIds, equals(['p1', 'p2']));
        expect(restored.grid[0][0].claimedBy, equals(game.grid[0][0].claimedBy));
        expect(restored.dartsThrown['p1'], equals(game.dartsThrown['p1']));
        expect(restored.totalTurns['p1'], equals(game.totalTurns['p1']));
        expect(restored.state.name, equals(game.state.name));
      });

      test('All enums serialize as .name strings', () {
        provider.startGame(['p1', 'p2'], TargetDifficulty.medium, 5, false, false);
        final json = provider.currentGame!.toJson();

        expect(json['targetDifficulty'], equals('medium'));
        expect(json['state'], equals('playing'));
        // Cell requirement should also serialize as name
        final gridData = json['grid'] as List;
        final firstCell = (gridData[0] as List)[0] as Map<String, dynamic>;
        expect(firstCell['target']['requirement'], equals('doubleOrTriple'));
      });
    });
  });
}
