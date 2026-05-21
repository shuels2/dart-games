import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import '../../providers/monster_mash_provider.dart';
import '../../widgets/dartboard_emulator/play_to_complete_strategy.dart';
import '../../widgets/dartboard_emulator/play_to_tie_strategy.dart';

/// Play-to-Tie strategy for Monster Mash.
///
/// Only works when Speed Play is enabled. In standard mode the game is
/// last-player-standing, so a tie isn't reachable (the player who
/// survives is the singular winner). In speed play, the round limit
/// triggers `_determineWinnerByRanking`-style logic: every player has
/// equal health (no damage dealt) and equal damage dealt (0) → all
/// tied at the top → `getWinners()` returns every active player.
///
/// Implementation: throw a miss on every dart. After `roundLimit`
/// rounds, all players finish at full health / 0 damage → tied.
class MonsterMashTieStrategy implements PlayToTieStrategy {
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
  bool canProduceTie(BuildContext context) {
    final game = context.read<MonsterMashProvider>().currentGame;
    if (game == null) return false;
    // Standard mode can't produce a tie — last-player-standing is by
    // definition singular. Speed Play uses ranking → reachable tie.
    return game.speedPlayEnabled;
  }

  @override
  SimulatedThrow? getNextThrow(BuildContext context) {
    // Deliberate miss on every dart. After roundLimit rounds in speed
    // play, every player still has full health and 0 damage dealt →
    // tied at the top of the ranking → winnerIds gets multiple ids.
    return const SimulatedThrow(score: 0, multiplier: 'miss', baseScore: 0);
  }
}
