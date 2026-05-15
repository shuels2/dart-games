import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 1: Pause modal appears on game screen when board disconnects',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester);

    await PauseModalHelpers.simulateDisconnectAndVerify(tester);

    // Verify we are still on the game screen
    expect(config.getGameBackButton(), findsOneWidget);

    await PauseModalHelpers.simulateReconnectAndVerify(tester);
  });

  testWidgets('Test 2: Pause blocks AppBar back arrow on game screen',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester);

    await PauseModalHelpers.simulateDisconnectAndVerify(tester);

    // Try tapping back button — overlay should block it
    await tester.tap(config.getGameBackButton(), warnIfMissed: false);
    await PumpSequences.simpleUpdate(tester);

    // Should still be on game screen with pause visible
    PauseModalHelpers.verifyPauseModalVisible(tester);
    expect(config.getGameBackButton(), findsOneWidget);

    await PauseModalHelpers.simulateReconnectAndVerify(tester);
  });

  testWidgets(
      'Test 3: Pause blocks dartboard emulator (DARTS REMOVED not tappable)',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester);

    await PauseModalHelpers.simulateDisconnectAndVerify(tester);

    // Verify pause modal is visible — emulator is obscured/blocked
    PauseModalHelpers.verifyPauseModalVisible(tester);

    // DARTS REMOVED button should not be interactable
    expect(find.text('DARTS REMOVED'), findsNothing);

    await PauseModalHelpers.simulateReconnectAndVerify(tester);
  });

  testWidgets(
      'Test 4: Pause modal renders OVER RemoveDartsModal (3 misses → turn ends → pause on top)',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester);

    // Throw maxStrokes (3) misses so the turn ends and RemoveDartsModal appears
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await PumpSequences.simpleUpdate(tester);

    // Disconnect — pause should appear on top of RemoveDartsModal
    await PauseModalHelpers.simulateDisconnectAndVerify(tester);

    // Pause modal blocks interaction; we are still mid-takeout
    PauseModalHelpers.verifyPauseModalVisible(tester);
  });

  testWidgets(
      'Test 5: Pause modal renders OVER SaveGameModal (back triggers save modal → pause blocks Save)',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester);

    // Throw a miss on dart 1 so the game has progress but turn has NOT ended.
    // (Turn ends only after all maxStrokes darts, or on target hit.)
    // With turn NOT ended, RemoveDartsModal is not showing, so back button is tappable.
    await throwMissViaMock(tester);
    await PumpSequences.simpleUpdate(tester);

    // Tap back to show save modal
    await UITestHelpers.tapGameScreenBackButton(tester, config);
    UITestHelpers.verifySaveGameModal();

    // Disconnect — pause should overlay the save modal
    await PauseModalHelpers.simulateDisconnectAndVerify(tester);

    // Save button should be blocked
    await tester.tap(ElementFinders.getSaveGameModalSaveButton(),
        warnIfMissed: false);
    await PumpSequences.simpleUpdate(tester);

    PauseModalHelpers.verifyPauseModalVisible(tester);

    await PauseModalHelpers.simulateReconnectAndVerify(tester);

    // Dismiss save modal to clean up
    await UITestHelpers.tapDontSaveButton(tester);
  });

  testWidgets('Test 6: EditScoreDialog auto-closes on dartboard disconnect',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester);

    // Throw maxStrokes (3) misses so edit score button appears after takeout
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await PumpSequences.simpleUpdate(tester);

    // Open edit score dialog
    await openEditScore(tester, config);

    // Verify edit score dialog is open
    expect(ElementFinders.getEditScoreSaveButton(), findsOneWidget);

    // Disconnect — edit score dialog should auto-close
    ProviderHelpers.simulateDartboardDisconnection(tester);
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    // Edit score dialog save button should be gone
    expect(ElementFinders.getEditScoreSaveButton(), findsNothing);

    // Pause modal should be visible
    PauseModalHelpers.verifyPauseModalVisible(tester);

    await PauseModalHelpers.simulateReconnectAndVerify(tester);
  });

  testWidgets('Test 7: Pause dismisses on reconnect (back to normal gameplay)',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester);

    // Throw a dart before disconnect
    await throwMissViaMock(tester);

    await PauseModalHelpers.simulateDisconnectAndVerify(tester);
    await PauseModalHelpers.simulateReconnectAndVerify(tester);

    // Game should continue — we should be able to throw more darts
    await throwMissViaMock(tester);

    // Verify game is still on the game screen
    expect(config.getGameBackButton(), findsOneWidget);
  });

  testWidgets(
      'Test 8: RemoveDartsModal still visible after pause dismisses',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester);

    // Throw maxStrokes (3) misses to trigger RemoveDartsModal
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await PumpSequences.simpleUpdate(tester);

    // Disconnect then reconnect
    await PauseModalHelpers.simulateDisconnectAndVerify(tester);
    await PauseModalHelpers.simulateReconnectAndVerify(tester);

    // RemoveDartsModal should still be present after reconnect (pause only obscures, not dismisses)
    // The takeout modal is still waiting — perform takeout to continue game
    await clickDartsRemoved(tester);

    // Verify game is still running after takeout
    expect(config.getGameBackButton(), findsOneWidget);
  });
}
