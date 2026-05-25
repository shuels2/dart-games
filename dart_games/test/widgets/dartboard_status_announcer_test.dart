import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dart_games/providers/dartboard_provider.dart';
import 'package:dart_games/widgets/dartboard_paused_modal/dartboard_status_announcer.dart';
import '../shared/mock_api_helpers.dart';

/// Helper: pumps a [DartboardStatusAnnouncer] under a [Provider] that
/// supplies the given [provider]. Returns the WidgetTester ready for
/// state mutations + further pumps.
Future<void> _pumpAnnouncer(
  WidgetTester tester, {
  required DartboardProvider provider,
  required VoidCallback onPaused,
  required VoidCallback onReconnected,
  int debounceMs = 5000,
}) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<DartboardProvider>.value(
      value: provider,
      child: MaterialApp(
        home: DartboardStatusAnnouncer(
          onPaused: onPaused,
          onReconnected: onReconnected,
          debounceMs: debounceMs,
          child: const SizedBox.shrink(),
        ),
      ),
    ),
  );
  // Drain the first didChangeDependencies cycle.
  await tester.pump();
}

void main() {
  late MockApiServer mockServer;
  late DartboardProvider provider;

  setUp(() {
    mockServer = MockApiServer();
    provider = DartboardProvider();
    provider.initialize(mockServer.apiClient);
  });

  tearDown(() async {
    await Future.delayed(Duration.zero);
    provider.dispose();
  });

  testWidgets('fires onPaused once when widget mounts with status=error',
      (tester) async {
    int paused = 0;
    int reconnected = 0;

    // Start in an explicit `error` state BEFORE the widget mounts.
    // Only `error` triggers the initial-frame fire — `disconnected`
    // is the app's default unloaded state and is deliberately silent.
    provider.setStatusForTesting(DartboardConnectionStatus.error);

    await _pumpAnnouncer(
      tester,
      provider: provider,
      onPaused: () => paused++,
      onReconnected: () => reconnected++,
    );

    expect(paused, 1, reason: 'first-frame error should fire onPaused once');
    expect(reconnected, 0);
  });

  testWidgets('does NOT fire onPaused on first frame when status is the default disconnected',
      (tester) async {
    int paused = 0;
    int reconnected = 0;

    // The provider's default initial status is `disconnected` (no
    // config loaded yet). The global announcer mounted at app root
    // must NOT fire here — otherwise every app start produces a
    // spurious "Game paused" announcement.
    provider.setStatusForTesting(DartboardConnectionStatus.disconnected);

    await _pumpAnnouncer(
      tester,
      provider: provider,
      onPaused: () => paused++,
      onReconnected: () => reconnected++,
    );

    expect(paused, 0,
        reason: 'initial `disconnected` is the unloaded default — silent');
    expect(reconnected, 0);
  });

  testWidgets('connected → error fires onPaused',
      (tester) async {
    int paused = 0;
    int reconnected = 0;

    provider.setStatusForTesting(DartboardConnectionStatus.connected);

    await _pumpAnnouncer(
      tester,
      provider: provider,
      onPaused: () => paused++,
      onReconnected: () => reconnected++,
    );

    expect(paused, 0, reason: 'no transition yet');

    provider.setStatusForTesting(DartboardConnectionStatus.error);
    await tester.pump();

    expect(paused, 1);
    expect(reconnected, 0);
  });

  testWidgets('error → connected fires onReconnected',
      (tester) async {
    int paused = 0;
    int reconnected = 0;

    provider.setStatusForTesting(DartboardConnectionStatus.error);

    await _pumpAnnouncer(
      tester,
      provider: provider,
      onPaused: () => paused++,
      onReconnected: () => reconnected++,
    );

    expect(paused, 1, reason: 'initial `error` fires the paused callback');
    expect(reconnected, 0);

    provider.setStatusForTesting(DartboardConnectionStatus.connected);
    await tester.pump();

    expect(paused, 1);
    expect(reconnected, 1);
  });

  testWidgets('emulator mode fires neither callback on any transition',
      (tester) async {
    int paused = 0;
    int reconnected = 0;

    provider.setStatusForTesting(DartboardConnectionStatus.emulator);

    await _pumpAnnouncer(
      tester,
      provider: provider,
      onPaused: () => paused++,
      onReconnected: () => reconnected++,
    );

    expect(paused, 0);
    expect(reconnected, 0);

    // Even when status flips inside emulator mode, isEmulator stays true
    // and the announcer suppresses callbacks. Note that `emulator` itself
    // is one of the non-paused values, so this also covers the "emulator
    // → emulator" no-op transition the production code performs.
    provider.setStatusForTesting(DartboardConnectionStatus.emulator);
    await tester.pump();

    expect(paused, 0);
    expect(reconnected, 0);
  });

  testWidgets('per-direction debounce suppresses immediate repeats',
      (tester) async {
    int paused = 0;
    int reconnected = 0;

    provider.setStatusForTesting(DartboardConnectionStatus.connected);

    // Long debounce window — the test only verifies the SUPPRESS side
    // of the debounce (immediate repeats are dropped). The "after the
    // window expires it should fire again" side relies on DateTime.now
    // wall-clock advancement, which is awkward to drive from
    // testWidgets without going to tester.runAsync; leaving that to
    // manual / integration verification.
    await _pumpAnnouncer(
      tester,
      provider: provider,
      onPaused: () => paused++,
      onReconnected: () => reconnected++,
      debounceMs: 60000,
    );

    // First pause fires.
    provider.setStatusForTesting(DartboardConnectionStatus.error);
    await tester.pump();
    expect(paused, 1);

    // Immediate flap: connected → paused again within the debounce
    // window. The reconnect fires (different direction, first time so
    // not yet debounced), but the second pause IS suppressed.
    provider.setStatusForTesting(DartboardConnectionStatus.connected);
    await tester.pump();
    provider.setStatusForTesting(DartboardConnectionStatus.disconnected);
    await tester.pump();
    expect(paused, 1,
        reason: 'second pause within debounce window is suppressed');
    expect(reconnected, 1);

    // Another rapid reconnect attempt is also suppressed (debounce
    // applies to both directions independently).
    provider.setStatusForTesting(DartboardConnectionStatus.connected);
    await tester.pump();
    expect(reconnected, 1,
        reason: 'second reconnect within debounce window is suppressed');
  });
}
