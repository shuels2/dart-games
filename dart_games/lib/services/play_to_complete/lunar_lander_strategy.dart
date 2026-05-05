import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import '../../providers/lunar_lander_provider.dart';
import '../../widgets/dartboard_emulator/play_to_complete_strategy.dart';

class LunarLanderStrategy implements PlayToCompleteStrategy {
  @override
  bool isGameComplete(BuildContext context) {
    final provider = context.read<LunarLanderProvider>();
    return provider.hasWinner || !provider.isGameActive;
  }

  @override
  bool shouldAutoTakeout(BuildContext context) {
    return context.read<LunarLanderProvider>().shouldPromptTakeout;
  }

  @override
  SimulatedThrow? getNextThrow(BuildContext context) {
    final provider = context.read<LunarLanderProvider>();
    final game = provider.currentGame;
    if (game == null) return null;

    final playerId = provider.getCurrentPlayerId();
    if (playerId == null) return null;

    final currentAlt = provider.getCurrentAltitude(playerId);

    // Game already won
    if (currentAlt <= 0) return null;

    // Aim for an exact landing if altitude is small enough
    if (currentAlt <= 20) {
      return SimulatedThrow(
          score: currentAlt, multiplier: 'single', baseScore: currentAlt);
    }
    if (currentAlt == 25) {
      return SimulatedThrow(score: 25, multiplier: 'single', baseScore: 25);
    }
    if (currentAlt == 50) {
      return SimulatedThrow(score: 50, multiplier: 'single', baseScore: 50);
    }

    // For high altitudes, use triple 20 (60) only if it won't bust under hard landing
    if (currentAlt >= 60) {
      final afterThrow = currentAlt - 60;
      if (!game.hardLandingEnabled || afterThrow >= 0) {
        return SimulatedThrow(score: 60, multiplier: 'triple', baseScore: 20);
      }
    }

    // For altitude 21-59 (excluding handled cases above), throw a safe single
    // that won't overshoot if hard landing is on
    if (game.hardLandingEnabled) {
      // Find biggest safe single: largest n <= 20 where currentAlt - n >= 0
      final safeScore = currentAlt > 20 ? 20 : currentAlt;
      return SimulatedThrow(
          score: safeScore, multiplier: 'single', baseScore: safeScore);
    } else {
      // Hard landing off: any throw that gets us close to or past 0 is fine
      final safeScore = currentAlt > 20 ? 20 : currentAlt;
      return SimulatedThrow(
          score: safeScore, multiplier: 'single', baseScore: safeScore);
    }
  }
}
