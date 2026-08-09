import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../providers/dartboard_provider.dart';

/// Watches [DartboardProvider] and reports pause/reconnect EDGES.
///
/// WS03 §3.7. [DartboardStatusAnnouncer] and [AutoSaveOnPause] each carried
/// their own copy of the same four things: the listen:false subscription
/// (attach in didChangeDependencies, detach in dispose, re-attach if the
/// provider identity changes), the `disconnected || error` pause predicate,
/// the emulator opt-out, and rising-edge detection against a remembered
/// previous status. Two copies of edge detection is two places for the same
/// subtle bug.
///
/// This owns that once. The behaviours that genuinely differ stay opt-in
/// flags rather than being flattened, because each exists for a reason
/// documented at its declaration.
class DartboardPauseObserver extends StatefulWidget {
  const DartboardPauseObserver({
    super.key,
    required this.child,
    this.onPauseEdge,
    this.onReconnectEdge,
    this.requireObservedConnected = false,
    this.fireOnFirstFrameIfPaused = false,
    this.reconnectAfterAnyPause = false,
  });

  final Widget child;

  /// Fired once when the board transitions into a paused state.
  final VoidCallback? onPauseEdge;

  /// Fired once when it comes back.
  final VoidCallback? onReconnectEdge;

  /// Gate [onPauseEdge] until a successful `connected` has been seen this
  /// session.
  ///
  /// Without this, a cold boot with the dartboard switched off walks
  /// `disconnected → connecting → error` and looks exactly like a mid-session
  /// drop — so the app announces "Game paused" while the user is still being
  /// routed to the dartboard-setup screen. The announcer needs this; the
  /// autosave does not, because there is no game to save at boot.
  final bool requireObservedConnected;

  /// Evaluate once on mount, so a widget that appears while the board is
  /// already down still reports the pause.
  final bool fireOnFirstFrameIfPaused;

  /// Fire [onReconnectEdge] on reaching `connected` after ANY pause, rather
  /// than only on a direct paused→connected transition.
  ///
  /// A real reconnect passes through `connecting`, so by the time `connected`
  /// arrives the remembered previous status is `connecting`, not paused, and
  /// a naive edge check never fires. The announcer needs this; consumers that
  /// only care about the pause edge do not.
  final bool reconnectAfterAnyPause;

  /// The shared definition of "paused". Exposed so consumers and tests agree
  /// on it rather than each re-deriving it.
  static bool isPaused(DartboardConnectionStatus s) =>
      s == DartboardConnectionStatus.disconnected ||
      s == DartboardConnectionStatus.error;

  @override
  State<DartboardPauseObserver> createState() => _DartboardPauseObserverState();
}

class _DartboardPauseObserverState extends State<DartboardPauseObserver> {
  DartboardProvider? _provider;
  DartboardConnectionStatus? _lastStatus;
  bool _firstObservationDone = false;
  bool _hasObservedConnected = false;
  bool _pendingReconnect = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // listen:false + addListener rather than context.watch: watching would
    // rebuild this subtree on every notification, and this widget renders
    // nothing of its own — it only fires callbacks.
    final provider = Provider.of<DartboardProvider>(context, listen: false);
    if (!identical(provider, _provider)) {
      _provider?.removeListener(_onProviderChange);
      _provider = provider;
      _provider!.addListener(_onProviderChange);
      _lastStatus = provider.status;
    }

    if (!_firstObservationDone) {
      _firstObservationDone = true;
      if (provider.status == DartboardConnectionStatus.connected) {
        _hasObservedConnected = true;
      }
      if (widget.fireOnFirstFrameIfPaused) {
        _evaluate(provider, initialFrame: true);
      }
    }
  }

  @override
  void dispose() {
    _provider?.removeListener(_onProviderChange);
    super.dispose();
  }

  void _onProviderChange() {
    final provider = _provider;
    if (provider == null || !mounted) return;
    _evaluate(provider, initialFrame: false);
  }

  void _evaluate(DartboardProvider provider, {required bool initialFrame}) {
    final status = provider.status;

    // The emulator never "pauses" — it has no hardware to lose. Track the
    // status so a later switch back to real hardware starts from the truth.
    if (provider.isEmulator) {
      _lastStatus = status;
      return;
    }

    if (status == DartboardConnectionStatus.connected) {
      _hasObservedConnected = true;
    }

    final wasPaused =
        _lastStatus == null ? false : DartboardPauseObserver.isPaused(_lastStatus!);
    final nowPaused = DartboardPauseObserver.isPaused(status);

    final risingEdge = initialFrame ? nowPaused : (!wasPaused && nowPaused);
    if (risingEdge &&
        (!widget.requireObservedConnected || _hasObservedConnected)) {
      _pendingReconnect = true;
      _lastStatus = status;
      widget.onPauseEdge?.call();
      return;
    }

    final reconnected = status == DartboardConnectionStatus.connected &&
        (widget.reconnectAfterAnyPause ? _pendingReconnect : wasPaused);
    if (reconnected) {
      _pendingReconnect = false;
      _lastStatus = status;
      widget.onReconnectEdge?.call();
      return;
    }

    _lastStatus = status;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
