import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import '../../providers/target_tag_provider.dart';
import '../../widgets/dartboard_emulator/play_to_complete_strategy.dart';

class TargetTagStrategy implements PlayToCompleteStrategy {
  @override
  bool isGameComplete(BuildContext context) {
    final provider = context.read<TargetTagProvider>();
    return provider.hasWinner || !provider.isGameActive;
  }

  @override
  bool shouldAutoTakeout(BuildContext context) {
    return context.read<TargetTagProvider>().shouldPromptTakeout;
  }

  @override
  SimulatedThrow? getNextThrow(BuildContext context) {
    final provider = context.read<TargetTagProvider>();
    final game = provider.currentGame;
    if (game == null) return null;

    final playerId = provider.getCurrentPlayerId();
    if (playerId == null) return null;

    final isTaggedIn = provider.isTaggedIn(playerId);

    if (!isTaggedIn) {
      // Build shields: hit own target
      final ownTarget = provider.getTargetNumber(playerId);
      if (ownTarget == null) return null;
      return SimulatedThrow(
          score: ownTarget * 3, multiplier: 'triple', baseScore: ownTarget);
    }

    // Tagged in: attack weakest non-eliminated opponent
    String? weakestId;
    int lowestShields = 999;

    for (final id in game.playerIds) {
      if (id == playerId || provider.isEliminated(id)) continue;

      // In team mode, skip teammates
      if (game.mode.name == 'team' && game.playerToTeam != null) {
        final myTeam = game.playerToTeam![playerId];
        final theirTeam = game.playerToTeam![id];
        if (myTeam == theirTeam) continue;
      }

      final shields = provider.getShields(id);
      if (shields < lowestShields) {
        lowestShields = shields;
        weakestId = id;
      }
    }

    if (weakestId == null) return null;

    final targetNumber = provider.getTargetNumber(weakestId);
    if (targetNumber == null) return null;

    return SimulatedThrow(
        score: targetNumber * 3, multiplier: 'triple', baseScore: targetNumber);
  }
}
