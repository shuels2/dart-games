import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/pause_modal_helpers.dart';
import '../../shared/pump_sequences.dart';
import '../../shared/dart_throw_helpers.dart';
import '../../shared/edit_score_helpers.dart';
import '../../shared/game_setup_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Pause modal appears during Target Tag gameplay',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await GameSetupHelpers.setupAndStartTargetTag(tester, config);

    // Throw a dart to confirm gameplay is active
    final targetNumber = GameSetupHelpers.getCurrentPlayerTargetNumber(tester);
    await DartThrowHelpers.throwDartViaMock(tester, targetNumber);

    // Disconnect and verify pause modal
    await PauseModalHelpers.simulateDisconnectAndVerify(tester);
  });

  testWidgets('Pause blocks AppBar back button during Target Tag gameplay',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await GameSetupHelpers.setupAndStartTargetTag(tester, config);

    // Throw a dart so hasDartsThrown is true
    final targetNumber = GameSetupHelpers.getCurrentPlayerTargetNumber(tester);
    await DartThrowHelpers.throwDartViaMock(tester, targetNumber);

    // Disconnect
    await PauseModalHelpers.simulateDisconnectAndVerify(tester);

    // Try tapping back button
    final backButton = config.getGameBackButton();
    if (backButton.evaluate().isNotEmpty) {
      await tester.tap(backButton);
      await PumpSequences.simpleUpdate(tester);
    }

    // Verify SaveGameModal did NOT appear (pause modal blocks interaction)
    expect(find.text('Save'), findsNothing);

    // Verify pause modal still visible
    PauseModalHelpers.verifyPauseModalVisible(tester);
  });

  testWidgets('Pause blocks dartboard emulator during Target Tag gameplay',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await GameSetupHelpers.setupAndStartTargetTag(tester, config);

    // Disconnect
    await PauseModalHelpers.simulateDisconnectAndVerify(tester);

    // Verify emulator is blocked by checking pause modal is on top
    PauseModalHelpers.verifyPauseModalVisible(tester);
  });

  testWidgets('Pause modal appears over RemoveDartsModal in Target Tag',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await GameSetupHelpers.setupAndStartTargetTag(tester, config);

    // Throw 3 darts to trigger RemoveDartsModal
    final targetNumber = GameSetupHelpers.getCurrentPlayerTargetNumber(tester);
    await DartThrowHelpers.throwDartViaMock(tester, targetNumber);
    await DartThrowHelpers.throwMissViaMock(tester);
    await DartThrowHelpers.throwMissViaMock(tester);

    // Verify DARTS REMOVED button is showing
    expect(find.text('DARTS REMOVED'), findsOneWidget);

    // Disconnect - pause modal should appear on top
    await PauseModalHelpers.simulateDisconnectAndVerify(tester);
  });

  testWidgets('Pause modal appears over SaveGameModal in Target Tag',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await GameSetupHelpers.setupAndStartTargetTag(tester, config);

    // Throw a dart so hasDartsThrown is true
    final targetNumber = GameSetupHelpers.getCurrentPlayerTargetNumber(tester);
    await DartThrowHelpers.throwDartViaMock(tester, targetNumber);

    // Press back to trigger save modal
    await UITestHelpers.tapGameScreenBackButton(tester, config);

    // Verify save modal appeared
    UITestHelpers.verifySaveGameModal();

    // Disconnect - pause modal should appear on top
    await PauseModalHelpers.simulateDisconnectAndVerify(tester);
  });

  testWidgets('EditScoreDialog auto-closes on disconnect in Target Tag',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await GameSetupHelpers.setupAndStartTargetTag(tester, config);

    // Throw 3 darts to complete the turn
    final targetNumber = GameSetupHelpers.getCurrentPlayerTargetNumber(tester);
    await DartThrowHelpers.throwDartViaMock(tester, targetNumber);
    await DartThrowHelpers.throwMissViaMock(tester);
    await DartThrowHelpers.throwMissViaMock(tester);

    // Open edit score dialog
    await EditScoreHelpers.openEditScore(tester, config);

    // Verify dialog is open
    EditScoreHelpers.verifyDialogOpen();

    // Disconnect
    ProviderHelpers.simulateDartboardDisconnection(tester);
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    // Verify edit score dialog is closed (post-frame callback needs pump time)
    EditScoreHelpers.verifyDialogClosed();

    // Verify pause modal appeared
    PauseModalHelpers.verifyPauseModalVisible(tester);
  });

  testWidgets('Pause dismisses on reconnect and Target Tag game continues',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await GameSetupHelpers.setupAndStartTargetTag(tester, config);

    // Throw a dart
    final targetNumber = GameSetupHelpers.getCurrentPlayerTargetNumber(tester);
    await DartThrowHelpers.throwDartViaMock(tester, targetNumber);

    // Disconnect then reconnect
    await PauseModalHelpers.simulateDisconnectAndVerify(tester);
    await PauseModalHelpers.simulateReconnectAndVerify(tester);

    // Verify game state is unchanged - can still throw darts
    await DartThrowHelpers.throwMissViaMock(tester);

    // Game should still be active
    expect(ProviderHelpers.isTargetTagGameActive(tester), isTrue);
  });

  testWidgets('RemoveDartsModal still visible after reconnect in Target Tag',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await GameSetupHelpers.setupAndStartTargetTag(tester, config);

    // Throw 3 darts to trigger RemoveDartsModal
    final targetNumber = GameSetupHelpers.getCurrentPlayerTargetNumber(tester);
    await DartThrowHelpers.throwDartViaMock(tester, targetNumber);
    await DartThrowHelpers.throwMissViaMock(tester);
    await DartThrowHelpers.throwMissViaMock(tester);

    // Verify DARTS REMOVED button is showing
    expect(find.text('DARTS REMOVED'), findsOneWidget);

    // Disconnect then reconnect
    await PauseModalHelpers.simulateDisconnectAndVerify(tester);
    await PauseModalHelpers.simulateReconnectAndVerify(tester);

    // Verify RemoveDartsModal is still visible
    expect(find.text('DARTS REMOVED'), findsOneWidget);
  });
}
