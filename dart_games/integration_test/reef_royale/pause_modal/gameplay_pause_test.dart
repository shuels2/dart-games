import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/element_finders.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 1: Pause modal appears during gameplay',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config);

    await PauseModalHelpers.simulateDisconnectAndVerify(tester);

    // Verify we are still on the game screen
    expect(config.getGameBackButton(), findsOneWidget);

    await PauseModalHelpers.simulateReconnectAndVerify(tester);
  });

  testWidgets('Test 2: Pause blocks AppBar back button during gameplay',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config);

    await PauseModalHelpers.simulateDisconnectAndVerify(tester);

    // Try tapping back button — overlay should block it
    await tester.tap(config.getGameBackButton(), warnIfMissed: false);
    await PumpSequences.simpleUpdate(tester);

    // Should still be on game screen with pause visible
    PauseModalHelpers.verifyPauseModalVisible(tester);
    expect(config.getGameBackButton(), findsOneWidget);

    await PauseModalHelpers.simulateReconnectAndVerify(tester);
  });

  testWidgets('Test 3: Pause blocks dartboard emulator',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config);

    await PauseModalHelpers.simulateDisconnectAndVerify(tester);

    // Try throwing a dart via mock — should not register while paused
    // Verify pause modal is still visible
    await throwDartViaMock(tester, 20);

    PauseModalHelpers.verifyPauseModalVisible(tester);

    await PauseModalHelpers.simulateReconnectAndVerify(tester);
  });

  testWidgets('Test 4: Pause over RemoveDartsModal',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config);

    // Throw 3 darts to trigger RemoveDartsModal
    await throwDartViaMock(tester, 20);
    await throwDartViaMock(tester, 20);
    await throwDartViaMock(tester, 20);

    // Verify DARTS REMOVED button is visible
    expect(find.text('DARTS REMOVED'), findsOneWidget);

    // Disconnect — pause should overlay the remove darts modal
    await PauseModalHelpers.simulateDisconnectAndVerify(tester);

    // DARTS REMOVED should be blocked
    await tester.tap(find.text('DARTS REMOVED'), warnIfMissed: false);
    await PumpSequences.simpleUpdate(tester);

    PauseModalHelpers.verifyPauseModalVisible(tester);

    await PauseModalHelpers.simulateReconnectAndVerify(tester);
  });

  testWidgets('Test 5: Pause over SaveGameModal',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config);

    // Throw a dart so back button shows save modal
    await throwDartViaMock(tester, 20);

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

  testWidgets('Test 6: EditScoreDialog auto-closes on disconnect',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config);

    // Throw 3 darts so edit score button appears
    await throwDartViaMock(tester, 20);
    await throwDartViaMock(tester, 20);
    await throwDartViaMock(tester, 20);

    // Open edit score dialog
    await openEditScore(tester, config);

    // Verify edit score dialog is open
    expect(ElementFinders.getEditScoreSaveButton(), findsOneWidget);

    // Disconnect — edit score dialog should auto-close
    ProviderHelpers.simulateDartboardDisconnection(tester);
    await PumpSequences.simpleUpdate(tester);

    // Edit score dialog save button should be gone
    expect(ElementFinders.getEditScoreSaveButton(), findsNothing);

    // Pause modal should be visible
    PauseModalHelpers.verifyPauseModalVisible(tester);

    await PauseModalHelpers.simulateReconnectAndVerify(tester);
  });

  testWidgets('Test 7: Pause dismisses on reconnect game continues',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config);

    // Throw a dart before disconnect
    await throwDartViaMock(tester, 20);

    await PauseModalHelpers.simulateDisconnectAndVerify(tester);
    await PauseModalHelpers.simulateReconnectAndVerify(tester);

    // Game should continue — we should be able to throw more darts
    await throwDartViaMock(tester, 19);

    // Verify game is still on the game screen
    expect(config.getGameBackButton(), findsOneWidget);
  });

  testWidgets('Test 8: RemoveDartsModal still visible after reconnect',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config);

    // Throw 3 darts to trigger RemoveDartsModal
    await throwDartViaMock(tester, 20);
    await throwDartViaMock(tester, 20);
    await throwDartViaMock(tester, 20);

    // Verify DARTS REMOVED is visible
    expect(find.text('DARTS REMOVED'), findsOneWidget);

    // Disconnect then reconnect
    await PauseModalHelpers.simulateDisconnectAndVerify(tester);
    await PauseModalHelpers.simulateReconnectAndVerify(tester);

    // RemoveDartsModal should still be visible after reconnect
    expect(find.text('DARTS REMOVED'), findsOneWidget);

    // Click it to continue the game
    await clickDartsRemoved(tester);
  });
}
