import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import '../../providers/reef_royale_provider.dart';
import '../../widgets/dartboard_emulator/play_to_complete_strategy.dart';
import '../../widgets/dartboard_emulator/play_to_tie_strategy.dart';

/// Play-to-Tie strategy for Reef Royale.
///
/// Requires Speed Play to be enabled so the game ends via the round
/// limit (otherwise the only way to a tie is "all targets locked
/// simultaneously" — much harder to drive deterministically, and in
/// practice players would only get there by hitting targets, which
/// means somebody would claim a pearl first and end the game).
///
/// With Speed Play on, throw a miss on every dart. After
/// `roundLimit` rounds every player has 0 corals claimed and 0 pearls
/// → all tied at the top of the ranking →
/// `_determineWinnerByRanking` writes them all into `winnerIds`.
class ReefRoyaleTieStrategy implements PlayToTieStrategy {
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
  bool canProduceTie(BuildContext context) {
    final game = context.read<ReefRoyaleProvider>().currentGame;
    if (game == null) return false;
    return game.speedPlayEnabled;
  }

  @override
  SimulatedThrow? getNextThrow(BuildContext context) {
    // Deliberate miss on every dart. After roundLimit rounds with
    // Speed Play enabled, all players are at 0 corals / 0 pearls →
    // tied at the top → `winnerIds` gets multiple ids.
    return const SimulatedThrow(score: 0, multiplier: 'miss', baseScore: 0);
  }
}
