// WS03 §3.7. DartboardStatusAnnouncer and AutoSaveOnPause each carried their
// own copy of pause-edge detection. These tests cover the shared observer
// directly, including the two opt-in behaviours that differ between the
// consumers — the ones that would be easy to "simplify" away.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dart_games/providers/dartboard_provider.dart';
import 'package:dart_games/widgets/dartboard_paused_modal/dartboard_pause_observer.dart';

Future<void> _pump(
  WidgetTester tester, {
  required DartboardProvider provider,
  VoidCallback? onPause,
  VoidCallback? onReconnect,
  bool requireObservedConnected = false,
  bool fireOnFirstFrameIfPaused = false,
  bool reconnectAfterAnyPause = false,
}) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<DartboardProvider>.value(
      value: provider,
      child: MaterialApp(
        home: DartboardPauseObserver(
          onPauseEdge: onPause,
          onReconnectEdge: onReconnect,
          requireObservedConnected: requireObservedConnected,
          fireOnFirstFrameIfPaused: fireOnFirstFrameIfPaused,
          reconnectAfterAnyPause: reconnectAfterAnyPause,
          child: const SizedBox.shrink(),
        ),
      ),
    ),
  );
}

void main() {
  group('isPaused', () {
    test('is disconnected or error, and nothing else', () {
      expect(
          DartboardPauseObserver.isPaused(
              DartboardConnectionStatus.disconnected),
          isTrue);
      expect(DartboardPauseObserver.isPaused(DartboardConnectionStatus.error),
          isTrue);
      expect(
          DartboardPauseObserver.isPaused(
              DartboardConnectionStatus.connected),
          isFalse);
      expect(
          DartboardPauseObserver.isPaused(
              DartboardConnectionStatus.connecting),
          isFalse,
          reason: 'connecting is a transient state on the way back, NOT a '
              'pause — treating it as one double-fires every reconnect');
      expect(
          DartboardPauseObserver.isPaused(DartboardConnectionStatus.emulator),
          isFalse);
    });
  });

  group('edge detection', () {
    testWidgets('fires once on connected -> error', (tester) async {
      final provider = DartboardProvider();
      var pauses = 0;
      provider.setStatusForTesting(DartboardConnectionStatus.connected);
      await _pump(tester, provider: provider, onPause: () => pauses++);

      provider.setStatusForTesting(DartboardConnectionStatus.error);
      await tester.pump();
      expect(pauses, 1);

      // Still paused, another notification — must not re-fire.
      provider.setStatusForTesting(DartboardConnectionStatus.disconnected);
      await tester.pump();
      expect(pauses, 1, reason: 'paused -> paused is not an edge');
      provider.dispose();
    });

    testWidgets('emulator never pauses', (tester) async {
      final provider = DartboardProvider();
      var pauses = 0;
      provider.setStatusForTesting(DartboardConnectionStatus.emulator);
      await _pump(tester, provider: provider, onPause: () => pauses++);

      provider.setStatusForTesting(DartboardConnectionStatus.error);
      await tester.pump();
      // isEmulator is what gates this; with the emulator selected there is no
      // hardware to lose.
      expect(pauses, provider.isEmulator ? 0 : 1);
      provider.dispose();
    });
  });

  group('requireObservedConnected (the cold-boot gate)', () {
    testWidgets('suppresses the boot-time disconnected -> error sequence',
        (tester) async {
      // The exact sequence a cold boot with the board switched off produces.
      final provider = DartboardProvider();
      var pauses = 0;
      provider.setStatusForTesting(DartboardConnectionStatus.disconnected);
      await _pump(tester,
          provider: provider,
          onPause: () => pauses++,
          requireObservedConnected: true);

      provider.setStatusForTesting(DartboardConnectionStatus.connecting);
      await tester.pump();
      provider.setStatusForTesting(DartboardConnectionStatus.error);
      await tester.pump();

      expect(pauses, 0,
          reason: 'announcing "Game paused" at boot, while the user is being '
              'routed to dartboard-setup, is the bug this gate prevents');
      provider.dispose();
    });

    testWidgets('still fires once a real connection has been seen',
        (tester) async {
      final provider = DartboardProvider();
      var pauses = 0;
      provider.setStatusForTesting(DartboardConnectionStatus.disconnected);
      await _pump(tester,
          provider: provider,
          onPause: () => pauses++,
          requireObservedConnected: true);

      provider.setStatusForTesting(DartboardConnectionStatus.connected);
      await tester.pump();
      provider.setStatusForTesting(DartboardConnectionStatus.error);
      await tester.pump();

      expect(pauses, 1);
      provider.dispose();
    });

    testWidgets('without the gate, a boot-time drop DOES fire', (tester) async {
      // AutoSaveOnPause deliberately opts out: at boot there is no game to
      // save, so the gate would be inert.
      final provider = DartboardProvider();
      var pauses = 0;
      provider.setStatusForTesting(DartboardConnectionStatus.connecting);
      await _pump(tester, provider: provider, onPause: () => pauses++);

      provider.setStatusForTesting(DartboardConnectionStatus.error);
      await tester.pump();
      expect(pauses, 1);
      provider.dispose();
    });
  });

  group('reconnectAfterAnyPause', () {
    testWidgets('fires through the intermediate connecting state',
        (tester) async {
      // A real reconnect is error -> connecting -> connected. By the time
      // `connected` arrives, the previous status is `connecting`, so a naive
      // paused->connected check never fires.
      final provider = DartboardProvider();
      var reconnects = 0;
      provider.setStatusForTesting(DartboardConnectionStatus.connected);
      await _pump(tester,
          provider: provider,
          onPause: () {},
          onReconnect: () => reconnects++,
          reconnectAfterAnyPause: true);

      provider.setStatusForTesting(DartboardConnectionStatus.error);
      await tester.pump();
      provider.setStatusForTesting(DartboardConnectionStatus.connecting);
      await tester.pump();
      provider.setStatusForTesting(DartboardConnectionStatus.connected);
      await tester.pump();

      expect(reconnects, 1);
      provider.dispose();
    });

    testWidgets('does not fire without a preceding pause', (tester) async {
      final provider = DartboardProvider();
      var reconnects = 0;
      provider.setStatusForTesting(DartboardConnectionStatus.connecting);
      await _pump(tester,
          provider: provider,
          onReconnect: () => reconnects++,
          reconnectAfterAnyPause: true);

      provider.setStatusForTesting(DartboardConnectionStatus.connected);
      await tester.pump();
      expect(reconnects, 0, reason: 'nothing was paused, so nothing recovered');
      provider.dispose();
    });
  });

  group('fireOnFirstFrameIfPaused', () {
    testWidgets('off: mounting while already paused is not a transition',
        (tester) async {
      final provider = DartboardProvider();
      var pauses = 0;
      provider.setStatusForTesting(DartboardConnectionStatus.error);
      await _pump(tester, provider: provider, onPause: () => pauses++);
      expect(pauses, 0);
      provider.dispose();
    });

    testWidgets('on: reports a board that is already down at mount',
        (tester) async {
      final provider = DartboardProvider();
      var pauses = 0;
      provider.setStatusForTesting(DartboardConnectionStatus.error);
      await _pump(tester,
          provider: provider,
          onPause: () => pauses++,
          fireOnFirstFrameIfPaused: true);
      expect(pauses, 1);
      provider.dispose();
    });
  });

  testWidgets('detaches its listener on dispose', (tester) async {
    final provider = DartboardProvider();
    var pauses = 0;
    provider.setStatusForTesting(DartboardConnectionStatus.connected);
    await _pump(tester, provider: provider, onPause: () => pauses++);

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    provider.setStatusForTesting(DartboardConnectionStatus.error);
    await tester.pump();

    expect(pauses, 0, reason: 'a leaked listener fires against a dead State');
    provider.dispose();
  });
}
