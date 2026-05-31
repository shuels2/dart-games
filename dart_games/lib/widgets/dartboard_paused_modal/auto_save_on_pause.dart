import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dart_games/providers/dartboard_provider.dart';

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
class AutoSaveOnPause extends StatefulWidget {
  final VoidCallback onPaused;
  final Widget child;

  const AutoSaveOnPause({
    super.key,
    required this.onPaused,
    required this.child,
  });

  @override
  State<AutoSaveOnPause> createState() => _AutoSaveOnPauseState();
}

class _AutoSaveOnPauseState extends State<AutoSaveOnPause> {
  DartboardProvider? _provider;
  bool _savedThisPause = false;
  DartboardConnectionStatus? _lastStatus;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = Provider.of<DartboardProvider>(context, listen: false);
    if (!identical(provider, _provider)) {
      _provider?.removeListener(_onProviderChange);
      _provider = provider;
      _provider!.addListener(_onProviderChange);
      _lastStatus = provider.status;
    }
  }

  @override
  void dispose() {
    _provider?.removeListener(_onProviderChange);
    super.dispose();
  }

  bool _isPaused(DartboardConnectionStatus s) =>
      s == DartboardConnectionStatus.disconnected ||
      s == DartboardConnectionStatus.error;

  void _onProviderChange() {
    final p = _provider;
    if (p == null || !mounted) return;
    if (p.isEmulator) {
      _lastStatus = p.status;
      return;
    }

    final status = p.status;
    final wasPaused = _lastStatus == null ? false : _isPaused(_lastStatus!);
    final nowPaused = _isPaused(status);

    // Reset the "saved this pause" arming once the connection comes
    // back. The next pause-edge can then fire onPaused again.
    if (status == DartboardConnectionStatus.connected) {
      _savedThisPause = false;
    }

    // Fire on the rising edge of paused (connected → error / disconnected).
    if (!wasPaused && nowPaused && !_savedThisPause) {
      _savedThisPause = true;
      widget.onPaused();
    }

    _lastStatus = status;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
