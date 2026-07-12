import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import '../../models/treasure_divide_game.dart';
import '../../providers/treasure_divide_provider.dart';
import '../../widgets/dartboard_emulator/play_to_complete_strategy.dart';
import '../../widgets/dartboard_emulator/play_to_tie_strategy.dart';

/// Play-to-Tie strategy for Treasure Divide.
///
/// Drives the game to a guaranteed tie by having EVERY dart from EVERY
/// player hit the round target identically. With all hauls equal across
/// all players (Solo) or all crews (Team), nobody is halved (every
/// player/crew hits ≥ 1 dart per round) and final treasure totals match
/// — `winnerIds` (Solo) or `winnerTeamIds` (Team) ends up with 2+ ids.
///
/// Tie is reachable from any settings combination — `canProduceTie`
/// returns `true` unconditionally. (Unlike Monster Mash and Reef Royale,
/// Treasure Divide doesn't require Speed Play or any other gating
/// option to make ties reachable; the Halve It scoring naturally
/// produces equal totals when every dart hits.)
///
/// Dart payloads per round target:
/// - Number round (1-20):    T<n>  — 3 × n × 3 = 9n per dart
/// - Any Double round (-1):  D20   — 40 per dart
/// - Any Triple round (-2):  T20   — 60 per dart
/// - Bull round (25):        Bull  — 50 per dart
///
/// The Bull round deliberately does NOT alternate inner/outer bull
/// (which `TreasureDivideStrategy` does) because alternation would
/// produce per-player drift on rounds where the dart count per player
/// is odd, and we want IDENTICAL hauls across every player every round.
class TreasureDivideTieStrategy implements PlayToTieStrategy {
  @override
  bool isGameComplete(BuildContext context) {
    final provider = context.read<TreasureDivideProvider>();
    return provider.currentGame?.state == TreasureDivideGameState.finished ||
        provider.currentGame == null;
  }

  @override
  bool shouldAutoTakeout(BuildContext context) {
    return context.read<TreasureDivideProvider>().shouldPromptTakeout;
  }

  @override
  bool canProduceTie(BuildContext context) {
    // Halve It always allows a tie outcome — no settings gate.
    return true;
  }

  @override
  SimulatedThrow? getNextThrow(BuildContext context) {
    final provider = context.read<TreasureDivideProvider>();
    final game = provider.currentGame;
    if (game == null) return null;
    if (game.state == TreasureDivideGameState.finished) return null;

    final roundIndex = game.currentRoundIndex;
    if (roundIndex >= game.targetSequence.length) return null;
    final target = game.targetSequence[roundIndex];

    if (target == kTargetAnyDouble) {
      return const SimulatedThrow(
          score: 40, multiplier: 'double', baseScore: 20);
    } else if (target == kTargetAnyTriple) {
      return const SimulatedThrow(
          score: 60, multiplier: 'triple', baseScore: 20);
    } else if (target == kTargetBull) {
      return const SimulatedThrow(
          score: 50, multiplier: 'bull', baseScore: 25);
    } else {
      return SimulatedThrow(
          score: target * 3, multiplier: 'triple', baseScore: target);
    }
  }
}
