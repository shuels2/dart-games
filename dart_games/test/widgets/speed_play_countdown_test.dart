import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/widgets/speed_play_countdown.dart';

void main() {
  group('SpeedPlayCountdownController', () {
    test('starts at the given value and counts down once per second', () {
      fakeAsync((async) {
        final c = SpeedPlayCountdownController();
        c.start(seconds: 3);
        expect(c.secondsRemaining.value, 3);

        async.elapse(const Duration(seconds: 1));
        expect(c.secondsRemaining.value, 2);
        async.elapse(const Duration(seconds: 1));
        expect(c.secondsRemaining.value, 1);
        c.dispose();
      });
    });

    test('onExpired fires once, after the timer is already cancelled', () {
      fakeAsync((async) {
        final c = SpeedPlayCountdownController();
        var expired = 0;
        bool runningInsideCallback = true;

        c.start(
          seconds: 2,
          onExpired: () {
            expired++;
            runningInsideCallback = c.isRunning;
          },
        );

        async.elapse(const Duration(seconds: 5));

        expect(expired, 1, reason: 'onExpired must not repeat');
        expect(runningInsideCallback, isFalse,
            reason: 'the timer must be cancelled BEFORE onExpired runs, so a '
                'takeout sequence it starts cannot race another tick');
        c.dispose();
      });
    });

    test('shouldStop cancels silently without expiring', () {
      fakeAsync((async) {
        final c = SpeedPlayCountdownController();
        var expired = 0;
        var stop = false;

        c.start(seconds: 10, onExpired: () => expired++, shouldStop: () => stop);
        async.elapse(const Duration(seconds: 2));
        expect(c.secondsRemaining.value, 8);

        stop = true;
        async.elapse(const Duration(seconds: 5));

        expect(c.isRunning, isFalse);
        expect(expired, 0,
            reason: 'a takeout prompt mid-count stops the clock, it does not '
                'expire the turn');
        expect(c.secondsRemaining.value, 8, reason: 'value freezes where it stopped');
        c.dispose();
      });
    });

    test('onTick reports each decrement so it can be persisted', () {
      fakeAsync((async) {
        final c = SpeedPlayCountdownController();
        final ticks = <int>[];
        c.start(seconds: 3, onTick: ticks.add);

        async.elapse(const Duration(seconds: 3));

        expect(ticks, [2, 1, 0]);
        c.dispose();
      });
    });

    test('start() restarts a running countdown rather than stacking timers',
        () {
      fakeAsync((async) {
        final c = SpeedPlayCountdownController();
        c.start(seconds: 10);
        async.elapse(const Duration(seconds: 3));
        expect(c.secondsRemaining.value, 7);

        c.start(seconds: 10);
        async.elapse(const Duration(seconds: 1));

        // Two live timers would take this to 8.
        expect(c.secondsRemaining.value, 9);
        c.dispose();
      });
    });

    test('reset stops the clock and restores the default', () {
      fakeAsync((async) {
        final c = SpeedPlayCountdownController(defaultSeconds: 25);
        c.start(seconds: 5);
        async.elapse(const Duration(seconds: 2));
        c.reset();

        expect(c.isRunning, isFalse);
        expect(c.secondsRemaining.value, 25);
        async.elapse(const Duration(seconds: 5));
        expect(c.secondsRemaining.value, 25);
        c.dispose();
      });
    });

    test('dispose cancels a running timer', () {
      fakeAsync((async) {
        final c = SpeedPlayCountdownController();
        var expired = 0;
        c.start(seconds: 2, onExpired: () => expired++);
        c.dispose();

        // A surviving timer would fire here and touch a disposed notifier.
        expect(() => async.elapse(const Duration(seconds: 10)), returnsNormally);
        expect(expired, 0);
      });
    });
  });

  group('SpeedPlayCountdown widget', () {
    testWidgets('rebuilds only its own subtree on each tick', (tester) async {
      final controller = SpeedPlayCountdownController();
      var outerBuilds = 0;
      var labelBuilds = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(builder: (context) {
            outerBuilds++;
            return SpeedPlayCountdown(
              controller: controller,
              builder: (context, secs) {
                labelBuilds++;
                return Text('$secs', textDirection: TextDirection.ltr);
              },
            );
          }),
        ),
      );

      final outerAfterMount = outerBuilds;
      controller.start(seconds: 5);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('3'), findsOneWidget);
      expect(labelBuilds, greaterThan(1));
      expect(outerBuilds, outerAfterMount,
          reason: 'the enclosing screen must NOT rebuild per tick — that is '
              'the entire point of WS04 4.3');

      controller.dispose();
    });
  });
}
