import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/pause_modal_helpers.dart';
import '../../shared/pump_sequences.dart';
import '../../shared/game_setup_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Pause modal appears on Carnival Derby results screen',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await GameSetupHelpers.setupAndStartCarnivalDerby(tester, config);

    // Complete game to reach results screen
    await completeGameToVictory(tester);

    // Verify we are on the results screen
    expect(config.getPlayAgainButton(), findsOneWidget);

    // Disconnect and verify pause modal
    await PauseModalHelpers.simulateDisconnectAndVerify(tester);
  });

  testWidgets('Pause blocks Play Again button on Carnival Derby results',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await GameSetupHelpers.setupAndStartCarnivalDerby(tester, config);

    await completeGameToVictory(tester);

    // Verify results screen
    expect(config.getPlayAgainButton(), findsOneWidget);

    // Disconnect
    await PauseModalHelpers.simulateDisconnectAndVerify(tester);

    // Try tapping Play Again
    await tester.tap(config.getPlayAgainButton());
    await PumpSequences.navigation(tester);

    // Verify still on results screen
    expect(config.getPlayAgainButton(), findsOneWidget);
  });

  testWidgets('Pause blocks Change Settings button on Carnival Derby results',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await GameSetupHelpers.setupAndStartCarnivalDerby(tester, config);

    await completeGameToVictory(tester);

    // Verify results screen
    expect(config.getChangeSettingsButton(), findsOneWidget);

    // Disconnect
    await PauseModalHelpers.simulateDisconnectAndVerify(tester);

    // Try tapping Change Settings
    final changeSettingsButton = config.getChangeSettingsButton();
    await tester.ensureVisible(changeSettingsButton);
    await tester.pump();
    await tester.tap(changeSettingsButton);
    await PumpSequences.navigation(tester);

    // Verify still on results screen
    expect(config.getPlayAgainButton(), findsOneWidget);
  });

  testWidgets('Pause blocks Back to Menu button on Carnival Derby results',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await GameSetupHelpers.setupAndStartCarnivalDerby(tester, config);

    await completeGameToVictory(tester);

    // Verify results screen
    expect(config.getBackToMenuButton(), findsOneWidget);

    // Disconnect
    await PauseModalHelpers.simulateDisconnectAndVerify(tester);

    // Try tapping Back to Menu
    final backToMenuButton = config.getBackToMenuButton();
    await tester.ensureVisible(backToMenuButton);
    await tester.pump();
    await tester.tap(backToMenuButton);
    await PumpSequences.navigation(tester);

    // Verify still on results screen
    expect(config.getPlayAgainButton(), findsOneWidget);
  });

  testWidgets('Pause dismisses and buttons work on Carnival Derby results',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await GameSetupHelpers.setupAndStartCarnivalDerby(tester, config);

    await completeGameToVictory(tester);

    // Verify results screen
    expect(config.getPlayAgainButton(), findsOneWidget);

    // Disconnect then reconnect
    await PauseModalHelpers.simulateDisconnectAndVerify(tester);
    await PauseModalHelpers.simulateReconnectAndVerify(tester);

    // Tap Play Again and verify navigation
    await UITestHelpers.clickPlayAgain(tester, config);

    // Verify we navigated away from results (game screen or menu should appear)
    expect(config.getPlayAgainButton(), findsNothing);
  });
}
