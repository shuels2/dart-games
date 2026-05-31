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

  testWidgets('initial mount is silent regardless of status (no prior connected)',
      (tester) async {
    int paused = 0;
    int reconnected = 0;

    // Even an explicit `error` status on mount is silent — the
    // announcer has never seen a successful `connected` in this
    // session, so it can't tell whether `error` represents a
    // genuine mid-session drop or an app cold-boot with a
    // dartboard that's offline.
    provider.setStatusForTesting(DartboardConnectionStatus.error);

    await _pumpAnnouncer(
      tester,
      provider: provider,
      onPaused: () => paused++,
      onReconnected: () => reconnected++,
    );

    expect(paused, 0, reason: 'no prior connected → cold-boot path → silent');
    expect(reconnected, 0);
  });

  testWidgets('cold-boot disconnected→connecting→error is silent',
      (tester) async {
    int paused = 0;
    int reconnected = 0;

    // Reproduces the user-reported bug: laptop has a saved dartboard
    // but no network. Provider attempts to connect on splash, fails.
    // The app correctly routes to dartboard-setup but historically
    // the announcer fired "Game paused" on the connecting→error
    // transition. After the _hasObservedConnected gate, it stays
    // silent.
    provider.setStatusForTesting(DartboardConnectionStatus.disconnected);

    await _pumpAnnouncer(
      tester,
      provider: provider,
      onPaused: () => paused++,
      onReconnected: () => reconnected++,
    );

    // Splash → loadConfiguration → _attemptConnection sequence.
    provider.setStatusForTesting(DartboardConnectionStatus.connecting);
    await tester.pump();
    provider.setStatusForTesting(DartboardConnectionStatus.error);
    await tester.pump();

    expect(paused, 0,
        reason: 'cold-boot with no reachable dartboard must not fire onPaused');
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

  testWidgets('connected → error → connected fires both callbacks',
      (tester) async {
    int paused = 0;
    int reconnected = 0;

    // Establish a successful connection FIRST — that latches
    // _hasObservedConnected so future drops can fire onPaused.
    provider.setStatusForTesting(DartboardConnectionStatus.connected);

    await _pumpAnnouncer(
      tester,
      provider: provider,
      onPaused: () => paused++,
      onReconnected: () => reconnected++,
    );

    provider.setStatusForTesting(DartboardConnectionStatus.error);
    await tester.pump();
    expect(paused, 1, reason: 'mid-session drop fires onPaused');
    expect(reconnected, 0);

    provider.setStatusForTesting(DartboardConnectionStatus.connected);
    await tester.pump();
    expect(paused, 1);
    expect(reconnected, 1, reason: 'direct paused→connected fires onReconnected');
  });

  testWidgets(
      'connected → error → connecting → connected still fires onReconnected '
      '(regression: real reconnect path passes through `connecting`)',
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

    // Drop the connection.
    provider.setStatusForTesting(DartboardConnectionStatus.error);
    await tester.pump();
    expect(paused, 1);
    expect(reconnected, 0);

    // Auto-reconnect kicks off — provider flips through `connecting`
    // first (which is NEITHER a paused state nor `connected`).
    provider.setStatusForTesting(DartboardConnectionStatus.connecting);
    await tester.pump();
    expect(paused, 1);
    expect(reconnected, 0,
        reason: 'connecting is intermediate — no announcement yet');

    // ...then settles to `connected` once HELLO_CLIENT + sbc status
    // confirms hardware online. THIS is where onReconnected must fire.
    provider.setStatusForTesting(DartboardConnectionStatus.connected);
    await tester.pump();
    expect(paused, 1);
    expect(reconnected, 1,
        reason:
            'reconnect must fire even after passing through `connecting`');
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
