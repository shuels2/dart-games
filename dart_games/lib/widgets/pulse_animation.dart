import 'package:flutter/widgets.dart';

/// Derives a 0→1→0 pulse from a single forward-repeating parent controller.
///
/// WS04 §4.8. Several screens ran one `AnimationController` per pulsing
/// element — Monster Mash's results screen alone had three glow controllers,
/// and `CarnivalStringLights` had eleven. Every controller registers its own
/// ticker with the scheduler and drives its own rebuilds, which is pure
/// overhead when the elements only differ in rate and phase.
///
/// One parent controller repeating forward can drive all of them:
///
/// * [cycles] is a frequency multiplier — how many full up-down pulses this
///   animation completes per parent revolution. Give the parent a duration
///   equal to the LCM of the periods you need and every [cycles] value stays
///   a whole number, so nothing jumps when the parent wraps.
/// * [phase] offsets by a fraction of this animation's own cycle, which is
///   how a row of identical bulbs stays visually out of step.
///
/// The `v <= 0.5 ? v*2 : (1-v)*2` fold reproduces `repeat(reverse: true)`
/// from a controller that only counts forward. That matters: a reversing
/// controller has no stable phase to offset from, so forward-only is what
/// makes sharing possible at all.
class PulseAnimation extends Animation<double>
    with AnimationWithParentMixin<double> {
  PulseAnimation({
    required this.parent,
    this.cycles = 1,
    this.phase = 0,
  }) : assert(cycles > 0);

  @override
  final Animation<double> parent;

  /// Full pulses per parent revolution. Keep whole to avoid a wrap jump.
  final double cycles;

  /// 0..1 fraction of one pulse to lead by.
  final double phase;

  @override
  double get value {
    final t = (parent.value * cycles + phase) % 1.0;
    return t <= 0.5 ? t * 2 : (1.0 - t) * 2;
  }
}

/// Rebuilds [builder] against a [PulseAnimation] and nothing else.
///
/// Use where a pulsing element sits inside a large build method: without it
/// the whole enclosing subtree rebuilds every frame of the animation.
class PulseBuilder extends StatelessWidget {
  const PulseBuilder({
    super.key,
    required this.animation,
    required this.builder,
    this.child,
  });

  final Animation<double> animation;

  /// Receives the current 0..1 pulse value.
  final Widget Function(BuildContext context, double value, Widget? child)
      builder;

  /// Subtree that does not depend on the pulse; passed through untouched so
  /// it is built once rather than every frame.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) => builder(context, animation.value, child),
    );
  }
}
