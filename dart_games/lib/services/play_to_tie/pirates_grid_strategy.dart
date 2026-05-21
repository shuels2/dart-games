import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import '../../models/pirates_grid_game.dart';
import '../../providers/pirates_grid_provider.dart';
import '../../widgets/dartboard_emulator/play_to_complete_strategy.dart';
import '../../widgets/dartboard_emulator/play_to_tie_strategy.dart';

/// Play-to-Tie / Stalemate strategy for Pirate's Grid.
///
/// Drives the 3×3 grid to a cat's-game draw by claiming cells in a
/// fixed order that mathematically cannot produce a 3-in-a-row before
/// the grid fills. Per user direction, never throw a steal — even when
/// Steal Mode is on, we only claim empty cells.
///
/// Move order (flat indices 0..8 in row-major order, 0 = top-left,
/// 4 = center, 8 = bottom-right):
///
///   move 1 (P1): 0   move 2 (P2): 4   move 3 (P1): 2
///   move 4 (P2): 1   move 5 (P1): 7   move 6 (P2): 3
///   move 7 (P1): 5   move 8 (P2): 8   move 9 (P1): 6
///
/// Verified by enumerating P1/P2 lines: no row, column, or diagonal
/// ends up all-P1 or all-P2 with these moves, so the round ends in
/// `isDraw = true`. If `bestOf > 1`, repeating this every round
/// produces `isMatchDraw = true`.
class PiratesGridTieStrategy implements PlayToTieStrategy {
  /// Fixed cat's-game cell sequence — flat 3×3 indices.
  static const List<int> _drawSequence = [0, 4, 2, 1, 7, 3, 5, 8, 6];

  @override
  bool isGameComplete(BuildContext context) {
    final provider = context.read<PiratesGridProvider>();
    final game = provider.currentGame;
    if (game == null) return true;
    // Match has resolved if there's an overall winner OR a match draw.
    return game.winnerId != null || game.isMatchDraw;
  }

  @override
  bool shouldAutoTakeout(BuildContext context) {
    return context.read<PiratesGridProvider>().shouldPromptTakeout;
  }

  @override
  bool canProduceTie(BuildContext context) => true;

  @override
  SimulatedThrow? getNextThrow(BuildContext context) {
    final provider = context.read<PiratesGridProvider>();
    final game = provider.currentGame;
    if (game == null) return null;

    final currentPlayerId = game.getCurrentPlayerId();
    final dartsThisTurn = game.dartsThrown[currentPlayerId] ?? 0;

    // Already claimed (or attempted to claim) this turn's cell on
    // dart 1 → throw a miss for darts 2 and 3 so the next player
    // gets to claim THEIR cell. Otherwise multiple cells could fall
    // in one turn and break the cat's-game ordering.
    if (dartsThisTurn > 0) {
      return const SimulatedThrow(score: 0, multiplier: 'miss', baseScore: 0);
    }

    // Count cells already claimed across the whole grid → tells us
    // which move number we're on (0..8).
    int claimedCount = 0;
    for (int r = 0; r < 3; r++) {
      for (int c = 0; c < 3; c++) {
        if (game.grid[r][c].claimedBy != null) claimedCount++;
      }
    }

    if (claimedCount >= 9) {
      // Grid full — round will end on its own. Throw a miss.
      return const SimulatedThrow(score: 0, multiplier: 'miss', baseScore: 0);
    }

    final nextIdx = _drawSequence[claimedCount];
    final row = nextIdx ~/ 3;
    final col = nextIdx % 3;
    final cell = game.grid[row][col];

    // Defensive: if the cell at the expected slot is already claimed
    // (e.g. round restarted mid-sequence), miss this dart and let the
    // count re-sync on the next call.
    if (cell.claimedBy != null) {
      return const SimulatedThrow(score: 0, multiplier: 'miss', baseScore: 0);
    }

    return _throwForTarget(cell.target);
  }

  /// Pick a [SimulatedThrow] that satisfies the cell's requirement.
  SimulatedThrow _throwForTarget(CellTarget target) {
    switch (target.requirement) {
      case CellRequirement.bull:
        return const SimulatedThrow(
          score: 50,
          multiplier: 'double',
          baseScore: 25,
        );
      case CellRequirement.tripleOnly:
        return SimulatedThrow(
          score: target.number * 3,
          multiplier: 'triple',
          baseScore: target.number,
        );
      case CellRequirement.doubleOnly:
      case CellRequirement.doubleOrTriple:
        return SimulatedThrow(
          score: target.number * 2,
          multiplier: 'double',
          baseScore: target.number,
        );
      case CellRequirement.any:
        return SimulatedThrow(
          score: target.number,
          multiplier: 'single',
          baseScore: target.number,
        );
    }
  }
}
