import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import '../../models/tiki_golf_game.dart';
import '../../providers/tiki_golf_provider.dart';
import '../../widgets/dartboard_emulator/play_to_complete_strategy.dart';

/// Play-to-Complete strategy for Tiki Golf.
///
/// Deliberate-winner pattern (per skill Rule §10) to avoid steal-loop edge
/// cases in the 9-hole rotation:
///   • Solo mode  → playerIds[0] is the designated winner.
///   • Team mode  → first player of the first team is the designated winner.
///
/// The winner targets the current hole's `holeTargets[holeIndex]` number and
/// hits on dart 1 every time (single of the target number = strokes = 1,
/// which is the best possible score, a "hole-in-one" birdie).
///
/// All other players return a miss-shaped SimulatedThrow on every dart so
/// they record a Splash (maxStrokes + 1) on every hole, guaranteeing the
/// winner finishes with the lowest total after 9 holes.
class TikiGolfStrategy implements PlayToCompleteStrategy {
  @override
  bool isGameComplete(BuildContext context) {
    final provider = context.read<TikiGolfProvider>();
    return provider.currentGame?.state == TikiGolfGameState.finished;
  }

  /// Tiki Golf's shouldAutoTakeout checks the provider's `currentTurnEnded`
  /// flag (set by the provider on hit / all darts missed / skip-turn).  This
  /// is DIFFERENT from fixed-3-dart games: a turn can end after any dart
  /// 1..maxStrokes, so we must poll the flag rather than counting darts.
  @override
  bool shouldAutoTakeout(BuildContext context) {
    final provider = context.read<TikiGolfProvider>();
    return provider.currentGame?.currentTurnEnded ?? false;
  }

  @override
  SimulatedThrow? getNextThrow(BuildContext context) {
    final provider = context.read<TikiGolfProvider>();
    final game = provider.currentGame;
    if (game == null) return null;

    final activePlayerId = game.activePlayerId;
    if (activePlayerId == null) return null;

    // ── Determine designated winner ──────────────────────────────────────────
    final String winnerId;
    if (game.gameMode == TikiGolfGameMode.solo) {
      winnerId = game.playerIds.isNotEmpty ? game.playerIds[0] : activePlayerId;
    } else {
      // Team mode: first player of first team
      final firstTeamId =
          game.teamPlayers.isNotEmpty ? game.teamPlayers.keys.first : null;
      final firstTeamPlayers =
          firstTeamId != null ? game.teamPlayers[firstTeamId] : null;
      winnerId = (firstTeamPlayers != null && firstTeamPlayers.isNotEmpty)
          ? firstTeamPlayers[0]
          : activePlayerId;
    }

    // ── Return throw based on whether this player is the designated winner ───
    if (activePlayerId == winnerId) {
      // Winner: hit the current hole's target on dart 1.
      final holeIndex = game.currentHole - 1;
      if (holeIndex < 0 || holeIndex >= game.holeTargets.length) return null;
      final target = game.holeTargets[holeIndex];
      // Single of the target number — score == target, multiplier 'single'
      return SimulatedThrow(
        score: target,
        multiplier: 'single',
        baseScore: target,
      );
    } else {
      // All other players: deliberate miss every dart.
      // Per skill Rule §23: return a miss-shaped throw, NOT null (null = stop).
      return SimulatedThrow(
        score: 0,
        multiplier: 'miss',
        baseScore: 0,
      );
    }
  }
}
