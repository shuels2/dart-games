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

  testWidgets('Pause modal appears during Carnival Derby gameplay',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await GameSetupHelpers.setupAndStartCarnivalDerby(tester, config);

    // Throw a dart to confirm gameplay is active
    await DartThrowHelpers.throwDartViaMock(tester, 20);

    // Disconnect and verify pause modal
    await PauseModalHelpers.simulateDisconnectAndVerify(tester);
  });

  testWidgets('Pause blocks AppBar back button during Carnival Derby gameplay',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await GameSetupHelpers.setupAndStartCarnivalDerby(tester, config);

    // Throw a dart so hasDartsThrown is true
    await DartThrowHelpers.throwDartViaMock(tester, 20);

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

  testWidgets('Pause blocks dartboard emulator during Carnival Derby gameplay',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await GameSetupHelpers.setupAndStartCarnivalDerby(tester, config);

    // Disconnect
    await PauseModalHelpers.simulateDisconnectAndVerify(tester);

    // Verify emulator is blocked by checking pause modal is on top
    PauseModalHelpers.verifyPauseModalVisible(tester);
  });

  testWidgets('Pause modal appears over RemoveDartsModal in Carnival Derby',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await GameSetupHelpers.setupAndStartCarnivalDerby(tester, config);

    // Throw 3 darts to trigger RemoveDartsModal
    await DartThrowHelpers.throwDartViaMock(tester, 20);
    await DartThrowHelpers.throwDartViaMock(tester, 5);
    await DartThrowHelpers.throwDartViaMock(tester, 1);

    // Verify DARTS REMOVED button is showing
    expect(find.text('DARTS REMOVED'), findsOneWidget);

    // Disconnect - pause modal should appear on top
    await PauseModalHelpers.simulateDisconnectAndVerify(tester);
  });

  testWidgets('Pause modal appears over SaveGameModal in Carnival Derby',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await GameSetupHelpers.setupAndStartCarnivalDerby(tester, config);

    // Throw a dart so hasDartsThrown is true
    await DartThrowHelpers.throwDartViaMock(tester, 20);

    // Press back to trigger save modal
    await UITestHelpers.tapGameScreenBackButton(tester, config);

    // Verify save modal appeared
    UITestHelpers.verifySaveGameModal();

    // Disconnect - pause modal should appear on top
    await PauseModalHelpers.simulateDisconnectAndVerify(tester);
  });

  testWidgets('EditScoreDialog auto-closes on disconnect in Carnival Derby',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await GameSetupHelpers.setupAndStartCarnivalDerby(tester, config);

    // Throw 3 darts to complete the turn
    await DartThrowHelpers.throwDartViaMock(tester, 20);
    await DartThrowHelpers.throwDartViaMock(tester, 5);
    await DartThrowHelpers.throwDartViaMock(tester, 1);

    // Open edit score dialog
    await EditScoreHelpers.openEditScore(tester, config);

    // Verify dialog is open
    EditScoreHelpers.verifyDialogOpen();

    // Disconnect
    await PauseModalHelpers.simulateDisconnectAndVerify(tester);

    // Verify edit score dialog is closed
    EditScoreHelpers.verifyDialogClosed();
  });

  testWidgets('Pause dismisses on reconnect and Carnival Derby game continues',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await GameSetupHelpers.setupAndStartCarnivalDerby(tester, config);

    // Throw a dart
    await DartThrowHelpers.throwDartViaMock(tester, 20);

    // Disconnect then reconnect
    await PauseModalHelpers.simulateDisconnectAndVerify(tester);
    await PauseModalHelpers.simulateReconnectAndVerify(tester);

    // Verify game state is unchanged - can still throw darts
    await DartThrowHelpers.throwDartViaMock(tester, 5);

    // Game should still be active
    expect(ProviderHelpers.isCarnivalDerbyGameActive(tester), isTrue);
  });

  testWidgets('RemoveDartsModal still visible after reconnect in Carnival Derby',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await GameSetupHelpers.setupAndStartCarnivalDerby(tester, config);

    // Throw 3 darts to trigger RemoveDartsModal
    await DartThrowHelpers.throwDartViaMock(tester, 20);
    await DartThrowHelpers.throwDartViaMock(tester, 5);
    await DartThrowHelpers.throwDartViaMock(tester, 1);

    // Verify DARTS REMOVED button is showing
    expect(find.text('DARTS REMOVED'), findsOneWidget);

    // Disconnect then reconnect
    await PauseModalHelpers.simulateDisconnectAndVerify(tester);
    await PauseModalHelpers.simulateReconnectAndVerify(tester);

    // Verify RemoveDartsModal is still visible
    expect(find.text('DARTS REMOVED'), findsOneWidget);
  });
}
