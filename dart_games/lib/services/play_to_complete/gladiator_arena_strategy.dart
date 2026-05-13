import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import '../../providers/gladiator_arena_provider.dart';
import '../../widgets/dartboard_emulator/play_to_complete_strategy.dart';

/// Play-to-Complete strategy for Gladiator Arena.
///
/// Strategy design (Miss + Miss + winning-dart pattern):
/// - The FIRST player in playerIds is designated as the "auto-play winner".
/// - Non-winner players always MISS so they make no progress.
/// - On darts 1 and 2, the winner throws a MISS.
/// - On dart 3 (the LAST dart of the turn), the winner throws the winning or
///   progress dart. This guarantees the WINNING DART is always dart 3,
///   matching the provider's turn-end win evaluation (§5 spec).
/// - With Double Finish ON: on dart 3, throw the double finish if in range;
///   otherwise throw a small single to make progress toward a double.
/// - With Double Finish OFF: on dart 3, throw T20 (60 pts) always; when
///   remaining ≤ 60, that dart wins on turn end.
class GladiatorArenaStrategy implements PlayToCompleteStrategy {
  @override
  bool isGameComplete(BuildContext context) {
    final provider = context.read<GladiatorArenaProvider>();
    return provider.hasWinner || !provider.isGameActive;
  }

  @override
  bool shouldAutoTakeout(BuildContext context) {
    return context.read<GladiatorArenaProvider>().shouldPromptTakeout;
  }

  @override
  SimulatedThrow? getNextThrow(BuildContext context) {
    final provider = context.read<GladiatorArenaProvider>();
    final game = provider.currentGame;
    if (game == null) return null;

    final playerId = provider.currentPlayerId;
    if (playerId == null) return null;

    // Determine winner — first player in the list is designated winner
    final winnerId = game.playerIds.isNotEmpty ? game.playerIds.first : null;

    // Non-winner players always miss (no progress = winner wins first)
    if (playerId != winnerId) {
      return const SimulatedThrow(score: 0, multiplier: 'miss', baseScore: 0);
    }

    // ── Winner's throw logic ──────────────────────────────────────────────────
    // Count darts already thrown this turn (0, 1, or 2).
    final dartsThisTurn =
        (game.currentTurnDartValues[playerId] ?? const []).length;
    final isDart3 = dartsThisTurn == 2; // next dart is dart 3 (index 2)

    // Darts 1 and 2: always miss — win evaluation fires only at turn end.
    if (!isDart3) {
      return const SimulatedThrow(score: 0, multiplier: 'miss', baseScore: 0);
    }

    // Dart 3: throw the winning or best-progress dart.
    final savedScore = game.scores[playerId] ?? 0;
    final target = game.targetScore;
    final remaining = target - savedScore;

    // Guard: if already at or past target (shouldn't happen), miss.
    if (remaining <= 0) {
      return const SimulatedThrow(score: 0, multiplier: 'miss', baseScore: 0);
    }

    if (game.doubleFinishEnabled) {
      return _getDoubleFinishDart3(remaining);
    } else {
      return _getAnyFinishDart3(remaining);
    }
  }

  /// Double Finish ON: dart 3 must hit exactly target on a double to win.
  /// If remaining is a valid double, throw it. Otherwise make safe progress
  /// using the highest-value dart that doesn't overshoot and leaves a clean
  /// double (even number ≤ 40) for a future dart 3.
  SimulatedThrow _getDoubleFinishDart3(int remaining) {
    // Can finish with a double this turn?
    if (remaining >= 2 && remaining <= 40 && remaining % 2 == 0) {
      final doubleNum = remaining ~/ 2;
      if (doubleNum <= 20) {
        return SimulatedThrow(
          score: remaining,
          multiplier: 'double',
          baseScore: doubleNum,
        );
      }
    }
    // Bull finish (remaining == 50)?
    if (remaining == 50) {
      return const SimulatedThrow(score: 50, multiplier: 'bull', baseScore: 50);
    }

    // Not in double range — make fast progress toward a clean double.
    // Try T20 (60) first: leaves remaining-60. If that's a valid double target, great.
    // If remaining > 40+60 = 100, T20 is always safe (remaining-60 > 40, need more turns).
    if (remaining > 60) {
      // T20 = 60 pts, fastest safe progress when remaining won't go below 1.
      return const SimulatedThrow(score: 60, multiplier: 'triple', baseScore: 20);
    }

    // remaining in [41..60]: use a single to leave an even ≤ 40.
    for (int n = 20; n >= 1; n--) {
      final after = remaining - n;
      if (after > 0 && after <= 40 && after % 2 == 0) {
        return SimulatedThrow(score: n, multiplier: 'single', baseScore: n);
      }
    }

    // remaining in (0, 40] but not a clean double — throw S1 to adjust.
    return const SimulatedThrow(score: 1, multiplier: 'single', baseScore: 1);
  }

  /// Double Finish OFF: any dart reaching or exceeding target on dart 3 wins.
  /// Throw T20 (60 pts) — when remaining ≤ 60, this wins the turn.
  SimulatedThrow _getAnyFinishDart3(int remaining) {
    // T20 = 60 pts: always good progress and wins when remaining ≤ 60.
    return const SimulatedThrow(score: 60, multiplier: 'triple', baseScore: 20);
  }
}
