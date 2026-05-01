import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import '../../providers/reef_royale_provider.dart';
import '../../models/reef_royale_game.dart';
import '../../widgets/dartboard_emulator/play_to_complete_strategy.dart';

class ReefRoyaleStrategy implements PlayToCompleteStrategy {
  @override
  bool isGameComplete(BuildContext context) {
    final provider = context.read<ReefRoyaleProvider>();
    return provider.hasWinner || !provider.isGameActive;
  }

  @override
  bool shouldAutoTakeout(BuildContext context) {
    return context.read<ReefRoyaleProvider>().shouldPromptTakeout;
  }

  @override
  SimulatedThrow? getNextThrow(BuildContext context) {
    final provider = context.read<ReefRoyaleProvider>();
    final game = provider.currentGame;
    if (game == null) return null;

    final playerId = provider.getCurrentPlayerId();
    if (playerId == null) return null;

    final activeTargets = game.activeTargets;

    // Find first unclaimed target
    for (final target in activeTargets) {
      if (!provider.hasPlayerClaimed(playerId, target)) {
        if (target == 25) {
          return const SimulatedThrow(
              score: 50, multiplier: 'bullseye', baseScore: 50);
        }
        return SimulatedThrow(
            score: target * 3, multiplier: 'triple', baseScore: target);
      }
    }

    // All targets claimed
    if (game.gameMode == ReefRoyaleGameMode.cursedTide) {
      return const SimulatedThrow(score: 0, multiplier: 'miss', baseScore: 0);
    }

    // Standard mode: score pearls on claimed targets
    for (final target in activeTargets) {
      if (target == 25) {
        return const SimulatedThrow(
            score: 50, multiplier: 'bullseye', baseScore: 50);
      }
      return SimulatedThrow(
          score: target * 3, multiplier: 'triple', baseScore: target);
    }

    return null;
  }
}
