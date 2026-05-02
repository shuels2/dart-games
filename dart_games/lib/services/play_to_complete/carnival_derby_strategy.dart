import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import '../../providers/horse_race_provider.dart';
import '../../widgets/dartboard_emulator/play_to_complete_strategy.dart';

class CarnivalDerbyStrategy implements PlayToCompleteStrategy {
  @override
  bool isGameComplete(BuildContext context) {
    final provider = context.read<HorseRaceProvider>();
    return provider.hasWinner || !provider.isGameActive;
  }

  @override
  bool shouldAutoTakeout(BuildContext context) {
    return context.read<HorseRaceProvider>().shouldPromptTakeout;
  }

  @override
  SimulatedThrow? getNextThrow(BuildContext context) {
    final provider = context.read<HorseRaceProvider>();
    final game = provider.currentGame;
    if (game == null) return null;

    final currentPlayerId = game.getCurrentPlayerId();
    final playerScore = game.getPlayerScore(currentPlayerId);
    final targetScore = game.targetScore;
    final exactMode = game.exactScoreMode;

    if (!exactMode) {
      return const SimulatedThrow(score: 60, multiplier: 'triple', baseScore: 20);
    }

    final remaining = targetScore - playerScore;
    if (remaining <= 0) return null;

    if (remaining > 60) {
      return const SimulatedThrow(score: 60, multiplier: 'triple', baseScore: 20);
    }

    return _findExactDart(remaining);
  }

  SimulatedThrow _findExactDart(int remaining) {
    if (remaining == 50) {
      return const SimulatedThrow(score: 50, multiplier: 'bullseye', baseScore: 50);
    }
    if (remaining == 25) {
      return const SimulatedThrow(score: 25, multiplier: 'outer_bull', baseScore: 25);
    }

    // Triple (3-60, multiples of 3 where base <= 20)
    if (remaining % 3 == 0 && remaining ~/ 3 <= 20) {
      final base = remaining ~/ 3;
      return SimulatedThrow(score: remaining, multiplier: 'triple', baseScore: base);
    }

    // Double (2-40, multiples of 2 where base <= 20)
    if (remaining % 2 == 0 && remaining ~/ 2 <= 20) {
      final base = remaining ~/ 2;
      return SimulatedThrow(score: remaining, multiplier: 'double', baseScore: base);
    }

    // Single (1-20)
    if (remaining <= 20) {
      return SimulatedThrow(score: remaining, multiplier: 'single', baseScore: remaining);
    }

    // Can't hit exact remaining — chip away with Single 1
    return const SimulatedThrow(score: 1, multiplier: 'single', baseScore: 1);
  }
}
