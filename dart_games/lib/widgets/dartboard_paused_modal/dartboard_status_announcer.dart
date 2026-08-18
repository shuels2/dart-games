import 'package:flutter/material.dart';

import 'dartboard_pause_observer.dart';
import 'package:dart_games/providers/dartboard_provider.dart';

/// Side-effect widget that fires [onPaused] / [onReconnected] callbacks
/// when the dartboard connection transitions in or out of a paused state
/// during gameplay.
///
/// Paused states: [DartboardConnectionStatus.disconnected] and
/// [DartboardConnectionStatus.error]. The widget's contract is paired with
/// [DartboardPausedModal], which is mounted by the game screen under the
/// same condition; this widget gives each game an audio counterpart to
/// the visual modal.
///
/// Semantics:
///   - When the dartboard is paused on the very first observation (i.e. the
///     game screen opened while already disconnected), [onPaused] fires once
///     immediately so the user understands why the modal is showing.
///   - When status flips from `connected` → paused, [onPaused] fires.
///   - When status flips from paused → `connected`, [onReconnected] fires.
///   - In emulator mode (`dartboardProvider.isEmulator == true`) neither
///     callback fires — the paused modal isn't shown there, and the
///     announcement would be a spurious noise during normal dev.
///   - Per-direction debounce: a callback won't fire twice within 5 s of
///     its previous fire. Protects against rapid connection flapping.
class DartboardStatusAnnouncer extends StatefulWidget {
  final VoidCallback onPaused;
  final VoidCallback onReconnected;
  final Widget child;

  /// Minimum gap (in milliseconds) between two consecutive fires of the
  /// SAME callback. Exposed for tests; production callers should use the
  /// default 5000ms.
  final int debounceMs;

  const DartboardStatusAnnouncer({
    super.key,
    required this.onPaused,
    required this.onReconnected,
    required this.child,
    this.debounceMs = 5000,
  });

  @override
  State<DartboardStatusAnnouncer> createState() =>
      _DartboardStatusAnnouncerState();
}

class _DartboardStatusAnnouncerState extends State<DartboardStatusAnnouncer> {
  DateTime? _lastPausedAt;
  DateTime? _lastReconnectedAt;

  /// Minimum gap between two consecutive fires of the SAME callback.
  ///
  /// This stays here rather than moving into DartboardPauseObserver: it is
  /// about not TALKING over yourself, which only matters for the announcer.
  /// The observer's job is detecting edges; deciding whether an edge is worth
  /// speaking is this widget's.
  bool _shouldFire(DateTime? lastAt) {
    if (lastAt == null) return true;
    return DateTime.now().difference(lastAt).inMilliseconds >= widget.debounceMs;
  }

  @override
  Widget build(BuildContext context) {
    return DartboardPauseObserver(
      // Gate on having seen a real connection first. Without it, a cold boot
      // with the board switched off walks disconnected -> connecting -> error
      // and announces "Game paused" while the user is still being routed to
      // the dartboard-setup screen.
      requireObservedConnected: true,
      // A real reconnect passes through `connecting`, so by the time
      // `connected` arrives the previous status is no longer paused and a
      // naive edge check never fires.
      reconnectAfterAnyPause: true,
      // Deliberately false: mounting while already paused is not a pause
      // TRANSITION, and announcing one would be wrong.
      fireOnFirstFrameIfPaused: false,
      onPauseEdge: () {
        if (!_shouldFire(_lastPausedAt)) return;
        _lastPausedAt = DateTime.now();
        widget.onPaused();
      },
      onReconnectEdge: () {
        if (!_shouldFire(_lastReconnectedAt)) return;
        _lastReconnectedAt = DateTime.now();
        widget.onReconnected();
      },
      child: widget.child,
    );
  }
}
