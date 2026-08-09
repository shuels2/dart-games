import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/widgets/pulse_animation.dart';

/// A settable stand-in for an AnimationController's 0..1 value.
class _FakeParent extends Animation<double> with AnimationLocalListenersMixin {
  double _v = 0;
  set v(double value) {
    _v = value;
    notifyListeners();
  }

  @override
  double get value => _v;

  @override
  AnimationStatus get status => AnimationStatus.forward;

  @override
  void addStatusListener(AnimationStatusListener listener) {}
  @override
  void removeStatusListener(AnimationStatusListener listener) {}
  @override
  void didRegisterListener() {}
  @override
  void didUnregisterListener() {}
}

void main() {
  group('PulseAnimation', () {
    test('folds a forward-only parent into an up-then-down ramp', () {
      final parent = _FakeParent();
      final pulse = PulseAnimation(parent: parent);

      parent.v = 0.0;
      expect(pulse.value, closeTo(0.0, 1e-9));
      parent.v = 0.25;
      expect(pulse.value, closeTo(0.5, 1e-9));
      parent.v = 0.5;
      expect(pulse.value, closeTo(1.0, 1e-9),
          reason: 'peak at the half-way point, as repeat(reverse: true) does');
      parent.v = 0.75;
      expect(pulse.value, closeTo(0.5, 1e-9));
      parent.v = 1.0;
      expect(pulse.value, closeTo(0.0, 1e-9));
    });

    test('cycles multiplies the rate', () {
      final parent = _FakeParent();
      final fast = PulseAnimation(parent: parent, cycles: 3);

      // Three full pulses per parent revolution: peaks at 1/6, 3/6, 5/6.
      for (final t in [1 / 6, 3 / 6, 5 / 6]) {
        parent.v = t;
        expect(fast.value, closeTo(1.0, 1e-9));
      }
      for (final t in [0.0, 2 / 6, 4 / 6, 1.0]) {
        parent.v = t;
        expect(fast.value, closeTo(0.0, 1e-9));
      }
    });

    test('whole-number cycles leave no discontinuity at the wrap', () {
      final parent = _FakeParent();
      // Monster Mash's three glows: 6, 4 and 3 pulses per 14400ms parent.
      for (final cycles in [6.0, 4.0, 3.0]) {
        final pulse = PulseAnimation(parent: parent, cycles: cycles);
        parent.v = 0.0;
        final atStart = pulse.value;
        parent.v = 1.0;
        final atEnd = pulse.value;
        expect(atEnd, closeTo(atStart, 1e-9),
            reason: 'cycles=$cycles must land back where it started, or the '
                'glow visibly jumps every time the parent repeats');
      }
    });

    test('phase offsets without changing the shape', () {
      final parent = _FakeParent();
      final lead = PulseAnimation(parent: parent, phase: 0.25);

      parent.v = 0.0;
      expect(lead.value, closeTo(0.5, 1e-9));
      parent.v = 0.25;
      expect(lead.value, closeTo(1.0, 1e-9), reason: 'peak arrives early');
    });

    test('a row of phased pulses are genuinely out of step', () {
      final parent = _FakeParent();
      // CarnivalStringLights: 150ms stagger against a 2000ms cycle.
      const step = 150 / 2000;
      final bulbs = [
        for (var i = 0; i < 11; i++)
          PulseAnimation(parent: parent, phase: (i * step) % 1.0)
      ];

      parent.v = 0.3;
      final values = bulbs.map((b) => b.value).toList();
      expect(values.toSet().length, greaterThan(8),
          reason: 'bulbs must not all show the same brightness');
    });
  });

  group('PulseBuilder', () {
    testWidgets('rebuilds only its own subtree', (tester) async {
      final controller = AnimationController(
        vsync: const TestVSync(),
        duration: const Duration(seconds: 4),
      );
      addTearDown(controller.dispose);

      var outerBuilds = 0;
      var innerBuilds = 0;

      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: Builder(builder: (context) {
          outerBuilds++;
          return PulseBuilder(
            animation: PulseAnimation(parent: controller),
            builder: (context, value, child) {
              innerBuilds++;
              return SizedBox(width: 10 + value * 10);
            },
          );
        }),
      ));

      final outerAfterMount = outerBuilds;
      controller.repeat();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(innerBuilds, greaterThan(1));
      expect(outerBuilds, outerAfterMount,
          reason: 'the enclosing subtree must not rebuild per frame');
      controller.stop();
    });
  });
}
