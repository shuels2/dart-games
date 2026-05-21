import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import '../../models/tiki_golf_game.dart';
import '../../providers/tiki_golf_provider.dart';
import '../../widgets/dartboard_emulator/play_to_complete_strategy.dart';
import '../../widgets/dartboard_emulator/play_to_tie_strategy.dart';

/// Play-to-Tie strategy for Tiki Golf.
///
/// Every player hits the current hole's target on dart 1 (single of
/// the target number = score 1 stroke = the best possible "hole-in-one"
/// birdie). After 9 holes every player totals exactly 9 strokes →
/// `winnerIds` includes every player (solo tie) and every team has
/// the same best-ball (team tie).
///
/// `canProduceTie` is always true — solo and team mode both work the
/// same way, and there's no setting that prevents this from producing
/// a tie outcome.
class TikiGolfTieStrategy implements PlayToTieStrategy {
  @override
  bool isGameComplete(BuildContext context) {
    final provider = context.read<TikiGolfProvider>();
    return provider.currentGame?.state == TikiGolfGameState.finished;
  }

  @override
  bool shouldAutoTakeout(BuildContext context) {
    final provider = context.read<TikiGolfProvider>();
    return provider.currentGame?.currentTurnEnded ?? false;
  }

  @override
  bool canProduceTie(BuildContext context) => true;

  @override
  SimulatedThrow? getNextThrow(BuildContext context) {
    final provider = context.read<TikiGolfProvider>();
    final game = provider.currentGame;
    if (game == null) return null;

    final activePlayerId = game.activePlayerId;
    if (activePlayerId == null) return null;

    // Every player hits the current hole's target on dart 1. All
    // players end the hole at 1 stroke → all end the round at 9 strokes
    // → tied at the lowest total → multiple winners in winnerIds.
    final holeIndex = game.currentHole - 1;
    if (holeIndex < 0 || holeIndex >= game.holeTargets.length) return null;
    final target = game.holeTargets[holeIndex];
    return SimulatedThrow(
      score: target,
      multiplier: 'single',
      baseScore: target,
    );
  }
}
