import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';

import '../shared/ui_test_helpers.dart';
import '../shared/pause_modal_helpers.dart';
import '../shared/pump_sequences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Pause modal appears on home screen disconnect',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToHomeScreen(tester);

    // Verify we are on the home screen
    expect(find.byKey(HomeKeys.carnivalDerbyCard), findsOneWidget);

    // Disconnect dartboard and verify pause modal appears
    await PauseModalHelpers.simulateDisconnectAndVerify(tester);
  });

  testWidgets('Pause modal blocks game card taps on home screen',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToHomeScreen(tester);

    // Verify we are on the home screen
    expect(find.byKey(HomeKeys.carnivalDerbyCard), findsOneWidget);

    // Disconnect dartboard
    await PauseModalHelpers.simulateDisconnectAndVerify(tester);

    // Try tapping a game card while paused
    await tester.tap(find.byKey(HomeKeys.carnivalDerbyCard));
    await PumpSequences.navigation(tester);

    // Verify we are still on the home screen (game cards still visible)
    expect(find.byKey(HomeKeys.carnivalDerbyCard), findsOneWidget);
    expect(find.byKey(HomeKeys.targetTagCard), findsOneWidget);
  });

  testWidgets('Pause modal blocks AppBar menu on home screen',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToHomeScreen(tester);

    // Verify we are on the home screen
    expect(find.byKey(HomeKeys.carnivalDerbyCard), findsOneWidget);

    // Disconnect dartboard
    await PauseModalHelpers.simulateDisconnectAndVerify(tester);

    // Try tapping the AppBar popup menu button
    final menuButton = find.byIcon(Icons.more_vert);
    if (menuButton.evaluate().isNotEmpty) {
      await tester.tap(menuButton.first);
      await PumpSequences.simpleUpdate(tester);
    }

    // Verify popup menu items are NOT visible (settings text should not appear)
    expect(find.text('Settings'), findsNothing);
  });

  testWidgets('Pause modal dismisses on reconnect on home screen',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToHomeScreen(tester);

    // Verify we are on the home screen
    expect(find.byKey(HomeKeys.carnivalDerbyCard), findsOneWidget);

    // Disconnect and verify modal appears
    await PauseModalHelpers.simulateDisconnectAndVerify(tester);

    // Reconnect and verify modal disappears
    await PauseModalHelpers.simulateReconnectAndVerify(tester);
  });

  testWidgets('Game cards work after reconnect on home screen',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToHomeScreen(tester);

    // Verify we are on the home screen
    expect(find.byKey(HomeKeys.carnivalDerbyCard), findsOneWidget);

    // Disconnect then reconnect
    await PauseModalHelpers.simulateDisconnectAndVerify(tester);
    await PauseModalHelpers.simulateReconnectAndVerify(tester);

    // Tap a game card and verify navigation occurs
    await tester.tap(find.byKey(HomeKeys.carnivalDerbyCard));
    await PumpSequences.navigation(tester);

    // Verify we navigated to the Carnival Derby menu screen
    expect(find.textContaining('Target score:'), findsOneWidget);
  });
}
