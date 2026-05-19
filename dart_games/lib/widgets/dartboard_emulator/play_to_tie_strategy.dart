import 'package:flutter/widgets.dart';
import 'play_to_complete_strategy.dart';

/// Auto-play strategy that drives a game toward a TIE / DRAW outcome.
///
/// Shape mirrors [PlayToCompleteStrategy] so the emulator's runner loop
/// stays generic. Adds [canProduceTie] so the button can disable itself
/// when the current game's settings make a tie unreachable
/// (e.g. Monster Mash and Reef Royale require Speed Play enabled —
/// without it, the game's win condition can't produce a tie).
abstract class PlayToTieStrategy {
  /// Next dart to simulate, or null to stop the runner.
  SimulatedThrow? getNextThrow(BuildContext context);

  /// True when the game has finished (winner OR draw declared). The
  /// runner exits its loop when this returns true.
  bool isGameComplete(BuildContext context);

  /// True when the game is waiting for a takeout; the runner will
  /// simulate `simulateTakeoutFinished` and continue.
  bool shouldAutoTakeout(BuildContext context);

  /// Reports whether a tie is *reachable* given the current game's
  /// settings. The Play to Tie button disables itself when this is
  /// false (e.g. MM / RR without Speed Play).
  bool canProduceTie(BuildContext context);
}
