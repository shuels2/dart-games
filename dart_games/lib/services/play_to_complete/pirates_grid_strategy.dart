import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import '../../models/pirates_grid_game.dart';
import '../../providers/pirates_grid_provider.dart';
import '../../widgets/dartboard_emulator/play_to_complete_strategy.dart';

class PiratesGridStrategy implements PlayToCompleteStrategy {
  @override
  bool isGameComplete(BuildContext context) {
    final provider = context.read<PiratesGridProvider>();
    return provider.hasWinner || !provider.isGameActive;
  }

  @override
  bool shouldAutoTakeout(BuildContext context) {
    return context.read<PiratesGridProvider>().shouldPromptTakeout;
  }

  @override
  SimulatedThrow? getNextThrow(BuildContext context) {
    final provider = context.read<PiratesGridProvider>();
    final game = provider.currentGame;
    if (game == null) return null;

    final currentPlayerId = game.getCurrentPlayerId();
    final opponentId = game.getOpponentPlayerId(currentPlayerId);

    // Iterate grid row-major to find the first targetable cell
    for (int r = 0; r < 3; r++) {
      for (int c = 0; c < 3; c++) {
        final cell = game.grid[r][c];

        final bool isTargetable;
        if (cell.claimedBy == null) {
          // Empty cell — always targetable
          isTargetable = true;
        } else if (cell.claimedBy == opponentId && game.stealMode) {
          // Opponent cell — targetable if steal mode is ON
          isTargetable = true;
        } else {
          isTargetable = false;
        }

        if (!isTargetable) continue;

        // Build the SimulatedThrow for this cell's requirement
        final target = cell.target;

        switch (target.requirement) {
          case CellRequirement.bull:
            // Inner bull (double bull) — dartNumber=25, multiplier=2 in
            // SimulatedThrow means score=50
            return SimulatedThrow(
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
            return SimulatedThrow(
              score: target.number * 2,
              multiplier: 'double',
              baseScore: target.number,
            );

          case CellRequirement.doubleOrTriple:
            // Prefer double (simpler / more realistic)
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

    // No targetable cell found (all cells filled, draw imminent)
    return null;
  }
}
