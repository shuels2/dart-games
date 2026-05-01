import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import '../../providers/clockwork_quest_provider.dart';
import '../../widgets/dartboard_emulator/play_to_complete_strategy.dart';

class ClockworkQuestStrategy implements PlayToCompleteStrategy {
  @override
  bool isGameComplete(BuildContext context) {
    final provider = context.read<ClockworkQuestProvider>();
    return provider.hasWinner || !provider.isGameActive;
  }

  @override
  bool shouldAutoTakeout(BuildContext context) {
    return context.read<ClockworkQuestProvider>().shouldPromptTakeout;
  }

  @override
  SimulatedThrow? getNextThrow(BuildContext context) {
    final provider = context.read<ClockworkQuestProvider>();
    final game = provider.currentGame;
    if (game == null) return null;

    final playerId = provider.getCurrentPlayerId();
    if (playerId == null) return null;

    if (game.speedMode) {
      return _getSpeedModeThrow(provider, playerId, game);
    }
    return _getSequentialThrow(provider, playerId, game);
  }

  SimulatedThrow? _getSequentialThrow(
      ClockworkQuestProvider provider, String playerId, dynamic game) {
    final currentTarget = provider.getPlayerCurrentTarget(playerId);

    if (currentTarget > game.maxTarget) return null;

    if (currentTarget == 21 || (currentTarget == game.maxTarget && game.includeBullseye && game.maxTarget == 21)) {
      return const SimulatedThrow(score: 50, multiplier: 'bullseye', baseScore: 50);
    }

    return SimulatedThrow(
        score: currentTarget, multiplier: 'single', baseScore: currentTarget);
  }

  SimulatedThrow? _getSpeedModeThrow(
      ClockworkQuestProvider provider, String playerId, dynamic game) {
    final completed = provider.getPlayerCompletedTargets(playerId);
    final completedSet = completed.toSet();

    for (int target = 1; target <= game.maxTarget; target++) {
      final actualTarget = (target == 21 && game.includeBullseye) ? 21 : target;
      if (!completedSet.contains(actualTarget)) {
        if (actualTarget == 21) {
          return const SimulatedThrow(
              score: 50, multiplier: 'bullseye', baseScore: 50);
        }
        return SimulatedThrow(
            score: actualTarget, multiplier: 'single', baseScore: actualTarget);
      }
    }

    return null;
  }
}
