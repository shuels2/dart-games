import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import '../../models/treasure_divide_game.dart';
import '../../providers/treasure_divide_provider.dart';
import '../../widgets/dartboard_emulator/play_to_complete_strategy.dart';

class TreasureDivideStrategy implements PlayToCompleteStrategy {
  // Tracks which Bull-round throw we're on (alternates Bull / outer bull).
  int _bullThrowCount = 0;

  @override
  bool isGameComplete(BuildContext context) {
    final provider = context.read<TreasureDivideProvider>();
    return provider.currentGame?.state == TreasureDivideGameState.finished ||
        provider.currentGame == null;
  }

  @override
  bool shouldAutoTakeout(BuildContext context) {
    // Only fire the takeout when the provider has actually flipped
    // `shouldPromptTakeout` to true (after the last dart of the turn).
    // Returning `true` unconditionally made the runner fire takeout in
    // every iteration before throwing any dart — autoplay never threw.
    return context.read<TreasureDivideProvider>().shouldPromptTakeout;
  }

  @override
  SimulatedThrow? getNextThrow(BuildContext context) {
    final provider = context.read<TreasureDivideProvider>();
    final game = provider.currentGame;
    if (game == null) return null;
    if (game.state == TreasureDivideGameState.finished) return null;

    // Designate the FIRST player in playerIds as the winner.
    final winnerId = game.playerIds.isNotEmpty ? game.playerIds.first : null;
    if (winnerId == null) return null;

    final currentPlayerId = game.currentPlayerId;
    final roundIndex = game.currentRoundIndex;
    if (roundIndex >= game.targetSequence.length) return null;
    final target = game.targetSequence[roundIndex];

    final isWinner = currentPlayerId == winnerId;

    if (!isWinner) {
      // Non-winners always miss deliberately.
      return SimulatedThrow(score: 0, multiplier: 'miss', baseScore: 0);
    }

    // Winner throws the most efficient segment for the current target.
    if (target == kTargetAnyDouble) {
      // AnyDouble round: D20 → score 40
      return SimulatedThrow(score: 40, multiplier: 'double', baseScore: 20);
    } else if (target == kTargetAnyTriple) {
      // AnyTriple round: T20 → score 60
      return SimulatedThrow(score: 60, multiplier: 'triple', baseScore: 20);
    } else if (target == kTargetBull) {
      // Bull round: alternate inner bull (50) and outer bull (25)
      _bullThrowCount++;
      if (_bullThrowCount % 2 == 1) {
        return SimulatedThrow(score: 50, multiplier: 'bull', baseScore: 25);
      } else {
        return SimulatedThrow(score: 25, multiplier: 'single', baseScore: 25);
      }
    } else {
      // Number round: T{target} → score target × 3
      return SimulatedThrow(
          score: target * 3, multiplier: 'triple', baseScore: target);
    }
  }
}
