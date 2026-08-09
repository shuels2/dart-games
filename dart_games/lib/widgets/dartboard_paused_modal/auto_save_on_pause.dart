import 'package:flutter/material.dart';

import 'dartboard_pause_observer.dart';

/// Side-effect widget that fires [onPaused] exactly once per pause
/// when the dartboard connection drops while the user is inside a
/// game screen.
///
/// Re-arms on reconnect — i.e., if the connection flaps:
///   connected → error → connected → error
/// the callback fires on each `connected → error` transition, NOT
/// repeatedly while the connection is bouncing within a single pause.
///
/// The wrapping game screen is responsible for the actual save call:
///
///   AutoSaveOnPause(
///     onPaused: () => provider.saveGame(players, isAutoSave: true),
///     child: ...,
///   )
///
/// Skipped entirely in emulator mode — emulator runs never trigger
/// the pause modal, so auto-save is meaningless there.
class AutoSaveOnPause extends StatelessWidget {
  final VoidCallback onPaused;
  final Widget child;

  const AutoSaveOnPause({
    super.key,
    required this.onPaused,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Edge detection lives in DartboardPauseObserver (WS03 §3.7). This used
    // to carry its own copy of the subscription, the paused predicate, the
    // emulator opt-out and the rising-edge check.
    //
    // No requireObservedConnected here, unlike the announcer: at cold boot
    // there is no game in progress to save, so the gate would be inert.
    return DartboardPauseObserver(
      onPauseEdge: onPaused,
      child: child,
    );
  }
}
