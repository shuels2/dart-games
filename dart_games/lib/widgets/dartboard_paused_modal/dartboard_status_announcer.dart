import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  DartboardConnectionStatus? _lastStatus;
  DateTime? _lastPausedAt;
  DateTime? _lastReconnectedAt;
  DartboardProvider? _provider;
  bool _firstObservationDone = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to the dartboard provider via listen:false + addListener.
    // Using context.watch here would rebuild this whole subtree on every
    // notification — wasteful since we only react via callbacks. Pattern
    // mirrors how the existing game screens consume DartboardProvider in
    // their long-lived listeners.
    final provider = Provider.of<DartboardProvider>(context, listen: false);
    if (!identical(provider, _provider)) {
      _provider?.removeListener(_onProviderChange);
      _provider = provider;
      _provider!.addListener(_onProviderChange);
    }
    // First-frame check: if the dartboard is already paused when this
    // widget mounts, fire onPaused once. Subsequent changes go through
    // _onProviderChange.
    if (!_firstObservationDone) {
      _firstObservationDone = true;
      _evaluate(provider.status, provider.isEmulator, initialFrame: true);
    }
  }

  @override
  void dispose() {
    _provider?.removeListener(_onProviderChange);
    super.dispose();
  }

  void _onProviderChange() {
    final p = _provider;
    if (p == null || !mounted) return;
    _evaluate(p.status, p.isEmulator, initialFrame: false);
  }

  bool _isPaused(DartboardConnectionStatus s) =>
      s == DartboardConnectionStatus.disconnected ||
      s == DartboardConnectionStatus.error;

  void _evaluate(
    DartboardConnectionStatus status,
    bool isEmulator, {
    required bool initialFrame,
  }) {
    if (isEmulator) {
      _lastStatus = status;
      return;
    }

    final wasPaused = _lastStatus == null ? false : _isPaused(_lastStatus!);
    final nowPaused = _isPaused(status);

    if (initialFrame) {
      // No prior state to transition from; fire onPaused if the screen
      // opened already disconnected so the user knows why the modal is up.
      if (nowPaused && _shouldFire(_lastPausedAt)) {
        _lastPausedAt = DateTime.now();
        widget.onPaused();
      }
    } else {
      if (!wasPaused && nowPaused && _shouldFire(_lastPausedAt)) {
        _lastPausedAt = DateTime.now();
        widget.onPaused();
      } else if (wasPaused &&
          status == DartboardConnectionStatus.connected &&
          _shouldFire(_lastReconnectedAt)) {
        _lastReconnectedAt = DateTime.now();
        widget.onReconnected();
      }
    }

    _lastStatus = status;
  }

  bool _shouldFire(DateTime? lastAt) {
    if (lastAt == null) return true;
    return DateTime.now().difference(lastAt).inMilliseconds >= widget.debounceMs;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
