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
    final p1Id = game.playerIds[0]; // Designated winner — always P1.

    // When it's the non-winner's (P2's) turn, return null (miss deliberately).
    // This prevents steal-mode ping-pong: if both players target each other's
    // cells the game never ends. P2 missing every dart guarantees P1 builds
    // their winning line without interference.
    if (currentPlayerId != p1Id) return null;

    // P1's turn: target EMPTY cells only — never steal opponent cells even
    // when steal mode is ON. Stealing creates the same infinite-loop risk
    // because P2 could steal back on the next turn.
    for (int r = 0; r < 3; r++) {
      for (int c = 0; c < 3; c++) {
        final cell = game.grid[r][c];
        if (cell.claimedBy != null) continue; // skip all claimed cells

        final target = cell.target;
        switch (target.requirement) {
          case CellRequirement.bull:
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

    // All cells claimed — draw imminent; returning null triggers a miss.
    return null;
  }
}
