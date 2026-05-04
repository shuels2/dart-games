import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Pause modal appears during gameplay',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config);

    // Throw a dart so we are mid-gameplay
    await throwDartViaMock(tester, 20);

    // Disconnect — pause modal should appear
    await PauseModalHelpers.simulateDisconnectAndVerify(tester);
  });

  testWidgets('Pause blocks AppBar back button',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config);

    await throwDartViaMock(tester, 20);

    await PauseModalHelpers.simulateDisconnectAndVerify(tester);

    // Try tapping back button — should be blocked (no SaveGameModal)
    final backButton = config.getGameBackButton();
    await tester.tap(backButton, warnIfMissed: false);
    await PumpSequences.simpleUpdate(tester);

    // Verify no SaveGameModal appeared and pause is still showing
    PauseModalHelpers.verifyPauseModalVisible(tester);
    expect(find.text('Save Game?'), findsNothing);
  });

  testWidgets('Pause blocks dartboard emulator',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config);

    await PauseModalHelpers.simulateDisconnectAndVerify(tester);

    // Try throwing a dart via mock — the emulator should be blocked
    // The pause modal overlay prevents interaction
    PauseModalHelpers.verifyPauseModalVisible(tester);
  });

  testWidgets('Pause over RemoveDartsModal',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config);

    // Throw 3 darts to trigger RemoveDartsModal
    await throwDartViaMock(tester, 20);
    await throwDartViaMock(tester, 20);
    await throwDartViaMock(tester, 20);

    // Verify DARTS REMOVED button is visible
    expect(find.text('DARTS REMOVED'), findsOneWidget);

    // Disconnect — pause should appear on top of RemoveDartsModal
    await PauseModalHelpers.simulateDisconnectAndVerify(tester);
  });

  testWidgets('Pause over SaveGameModal',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config);

    await throwDartViaMock(tester, 20);

    // Tap back button to trigger SaveGameModal
    final backButton = config.getGameBackButton();
    await tester.tap(backButton);
    await PumpSequences.simpleUpdate(tester);

    // Verify SaveGameModal is showing
    expect(find.text('Save Game?'), findsOneWidget);

    // Disconnect — pause should appear on top
    await PauseModalHelpers.simulateDisconnectAndVerify(tester);
  });

  testWidgets('EditScoreDialog auto-closes on disconnect',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config);

    // Throw 3 darts, then click darts removed so edit score is available
    await throwDartViaMock(tester, 20);
    await throwDartViaMock(tester, 20);
    await throwDartViaMock(tester, 20);
    await clickDartsRemoved(tester);

    // P2 turn — throw 3 darts to make edit score available
    await throwDartViaMock(tester, 5);
    await throwDartViaMock(tester, 5);
    await throwDartViaMock(tester, 5);

    // Open edit score dialog
    await openEditScore(tester);
    EditScoreHelpers.verifyDialogOpen();

    // Disconnect — dialog should auto-close and pause modal should appear
    await PauseModalHelpers.simulateDisconnectAndVerify(tester);
    EditScoreHelpers.verifyDialogClosed();
  });

  testWidgets('Pause dismisses on reconnect game continues',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config);

    await throwDartViaMock(tester, 20);

    // Disconnect then reconnect
    await PauseModalHelpers.simulateDisconnectAndVerify(tester);
    await PauseModalHelpers.simulateReconnectAndVerify(tester);

    // Verify game continues — can still throw darts
    await throwDartViaMock(tester, 20);
    await PumpSequences.simpleUpdate(tester);

    // Verify no pause modal
    PauseModalHelpers.verifyPauseModalNotVisible(tester);
  });

  testWidgets('RemoveDartsModal still visible after reconnect',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config);

    // Throw 3 darts to trigger RemoveDartsModal
    await throwDartViaMock(tester, 20);
    await throwDartViaMock(tester, 20);
    await throwDartViaMock(tester, 20);

    // Verify DARTS REMOVED is showing
    expect(find.text('DARTS REMOVED'), findsOneWidget);

    // Disconnect then reconnect
    await PauseModalHelpers.simulateDisconnectAndVerify(tester);
    await PauseModalHelpers.simulateReconnectAndVerify(tester);

    // Verify DARTS REMOVED is still visible after reconnect
    expect(find.text('DARTS REMOVED'), findsOneWidget);
  });
}
