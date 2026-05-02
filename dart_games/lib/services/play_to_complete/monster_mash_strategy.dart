import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import '../../providers/monster_mash_provider.dart';
import '../../models/monster_mash_game.dart';
import '../../widgets/dartboard_emulator/play_to_complete_strategy.dart';

class MonsterMashStrategy implements PlayToCompleteStrategy {
  @override
  bool isGameComplete(BuildContext context) {
    final provider = context.read<MonsterMashProvider>();
    return provider.hasWinner || !provider.isGameActive;
  }

  @override
  bool shouldAutoTakeout(BuildContext context) {
    return context.read<MonsterMashProvider>().shouldPromptTakeout;
  }

  @override
  SimulatedThrow? getNextThrow(BuildContext context) {
    final provider = context.read<MonsterMashProvider>();
    final game = provider.currentGame;
    if (game == null) return null;

    final playerId = provider.getCurrentPlayerId();
    if (playerId == null) return null;

    final activeBuff = provider.getActiveBuff();

    // Shadow Walk: attacks deal 0 damage, heal instead
    if (activeBuff == BonusBuff.shadowWalk) {
      final ownTarget = provider.getTargetNumber(playerId);
      if (ownTarget != null) {
        return SimulatedThrow(
            score: ownTarget, multiplier: 'single', baseScore: ownTarget);
      }
    }

    // Laboratory Spark: bullseye hits ALL opponents for -10 HP each
    if (activeBuff == BonusBuff.laboratorySpark) {
      final aliveOpponents = game.playerIds
          .where((id) => id != playerId && !provider.isEliminated(id))
          .length;
      if (aliveOpponents >= 2) {
        return const SimulatedThrow(
            score: 50, multiplier: 'bullseye', baseScore: 50);
      }
    }

    // Default: attack lowest-HP non-eliminated opponent
    String? weakestId;
    int lowestHp = 999;

    for (final id in game.playerIds) {
      if (id == playerId || provider.isEliminated(id)) continue;
      final hp = provider.getHealth(id);
      if (hp < lowestHp) {
        lowestHp = hp;
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
