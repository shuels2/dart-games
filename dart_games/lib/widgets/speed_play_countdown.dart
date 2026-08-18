import 'dart:async';

import 'package:flutter/widgets.dart';

/// Owns the per-second countdown used by the speed-play option.
///
/// WS04 §4.3. Gladiator Arena and Pirate's Grid each ran a
/// `Timer.periodic` that called `setState` on the WHOLE game screen once a
/// second — 1,448 and 1,528 lines of build respectively — to move a two-digit
/// label. Pirate's Grid has a `RepaintBoundary` around its board, which limits
/// repaint but not rebuild, so the cost was paid regardless.
///
/// The controller holds the tick as a [ValueNotifier] so only the widget
/// listening to it rebuilds. The screens keep imperative control (they start
/// and stop the clock from several places — turn change, takeout, game won,
/// pause) rather than having it tied to widget lifecycle, which is why this is
/// a controller and not a self-starting widget.
class SpeedPlayCountdownController extends ChangeNotifier {
  SpeedPlayCountdownController({this.defaultSeconds = 25})
      : secondsRemaining = ValueNotifier<int>(defaultSeconds);

  /// Starting value when [start] is called without an explicit count.
  final int defaultSeconds;

  /// The live tick. Listen to this, not to the controller, to rebuild only
  /// the label.
  final ValueNotifier<int> secondsRemaining;

  Timer? _timer;
  bool _disposed = false;

  bool get isRunning => _timer != null;

  /// Starts (or restarts) the countdown.
  ///
  /// [onTick] fires after each decrement — used to persist the value so a
  /// mid-turn save/resume keeps the remaining time. [onExpired] fires once,
  /// after the timer has already been cancelled, so a callback that starts a
  /// takeout sequence cannot race another tick.
  ///
  /// [shouldStop] is polled before each decrement; returning true cancels
  /// silently WITHOUT calling [onExpired] — that is how Gladiator bails out
  /// when a takeout prompt appears mid-count.
  void start({
    int? seconds,
    ValueChanged<int>? onTick,
    VoidCallback? onExpired,
    bool Function()? shouldStop,
  }) {
    if (_disposed) return;
    stop();
    secondsRemaining.value = seconds ?? defaultSeconds;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_disposed) {
        timer.cancel();
        return;
      }
      if (shouldStop?.call() ?? false) {
        stop();
        return;
      }

      secondsRemaining.value = secondsRemaining.value - 1;
      onTick?.call(secondsRemaining.value);

      if (secondsRemaining.value <= 0) {
        // Cancel BEFORE the callback: onExpired typically kicks off a takeout
        // sequence, and a pending tick landing during that is the kind of
        // cross-turn stale callback this codebase has been bitten by before.
        stop();
        onExpired?.call();
      }
    });
    notifyListeners();
  }

  /// Cancels the countdown, leaving [secondsRemaining] where it stopped.
  void stop() {
    if (_timer == null) return;
    _timer!.cancel();
    _timer = null;
    if (!_disposed) notifyListeners();
  }

  /// Cancels and resets the display to [defaultSeconds].
  void reset([int? seconds]) {
    stop();
    if (!_disposed) secondsRemaining.value = seconds ?? defaultSeconds;
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    secondsRemaining.dispose();
    super.dispose();
  }
}

/// Rebuilds [builder] once per second with the remaining count, and nothing
/// else on the screen.
class SpeedPlayCountdown extends StatelessWidget {
  const SpeedPlayCountdown({
    super.key,
    required this.controller,
    required this.builder,
  });

  final SpeedPlayCountdownController controller;

  /// Renders the label for [secondsRemaining]. Each game styles its own.
  final Widget Function(BuildContext context, int secondsRemaining) builder;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: controller.secondsRemaining,
      builder: (context, seconds, _) => builder(context, seconds),
    );
  }
}
