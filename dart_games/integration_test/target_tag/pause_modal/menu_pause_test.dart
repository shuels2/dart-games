import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/pause_modal_helpers.dart';
import '../../shared/pump_sequences.dart';
import '../../shared/element_finders.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Pause modal appears on Target Tag menu screen',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, config);

    // Verify we are on the Target Tag menu
    expect(find.text('TARGET TAG GAME SETUP'), findsWidgets);

    // Disconnect and verify pause modal
    await PauseModalHelpers.simulateDisconnectAndVerify(tester);
  });

  testWidgets('Pause blocks AppBar back button on Target Tag menu',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, config);

    // Disconnect
    await PauseModalHelpers.simulateDisconnectAndVerify(tester);

    // Try tapping back button
    final backButton = ElementFinders.getTargetTagBackButton();
    if (backButton.evaluate().isNotEmpty) {
      await tester.tap(backButton);
      await PumpSequences.navigation(tester);
    }

    // Verify still on Target Tag menu (game title still visible)
    expect(find.text('TARGET TAG GAME SETUP'), findsWidgets);
  });

  testWidgets('Pause blocks start game button on Target Tag menu',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, config);

    // Add 2 players so start button becomes available
    await UITestHelpers.addPlayer(tester, 'PauseA', config);
    await UITestHelpers.addPlayer(tester, 'PauseB', config);

    // Disconnect
    await PauseModalHelpers.simulateDisconnectAndVerify(tester);

    // Try tapping start button
    final startButton = config.getStartButton();
    if (startButton.evaluate().isNotEmpty) {
      await tester.tap(startButton);
      await PumpSequences.navigation(tester);
    }

    // Verify no game screen appeared (still on menu)
    expect(find.text('TARGET TAG GAME SETUP'), findsWidgets);
  });

  testWidgets('Pause blocks settings controls on Target Tag menu',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, config);

    // Disconnect
    await PauseModalHelpers.simulateDisconnectAndVerify(tester);

    // Try tapping a settings control (shield max slider)
    final shieldSlider = ElementFinders.getTargetTagShieldMaxSlider();
    if (shieldSlider.evaluate().isNotEmpty) {
      await tester.tap(shieldSlider);
      await PumpSequences.simpleUpdate(tester);
    }

    // Verify pause modal still visible (settings didn't respond)
    PauseModalHelpers.verifyPauseModalVisible(tester);
  });

  testWidgets('Pause modal on clean menu disconnect works',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, config);

    // Disconnect on a clean menu (no saved games)
    await PauseModalHelpers.simulateDisconnectAndVerify(tester);

    // Verify the pause modal is showing properly
    PauseModalHelpers.verifyPauseModalVisible(tester);

    // Reconnect and verify modal gone
    await PauseModalHelpers.simulateReconnectAndVerify(tester);
  });

  testWidgets('Pause dismisses and Target Tag menu still works',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, config);

    // Disconnect then reconnect
    await PauseModalHelpers.simulateDisconnectAndVerify(tester);
    await PauseModalHelpers.simulateReconnectAndVerify(tester);

    // Verify menu is still interactive - add a player
    await UITestHelpers.addPlayer(tester, 'PostPause', config);

    // Verify player was added
    expect(find.text('PostPause'), findsWidgets);
  });

  testWidgets('Pause blocks back button then reconnect allows it on Target Tag menu',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, config);

    // Disconnect
    await PauseModalHelpers.simulateDisconnectAndVerify(tester);

    // Try back button while paused - should be blocked
    final backButton = ElementFinders.getTargetTagBackButton();
    if (backButton.evaluate().isNotEmpty) {
      await tester.tap(backButton);
      await PumpSequences.navigation(tester);
    }

    // Verify still on menu
    expect(find.text('TARGET TAG GAME SETUP'), findsWidgets);

    // Reconnect
    await PauseModalHelpers.simulateReconnectAndVerify(tester);

    // Now back button should work
    final backButtonAfter = ElementFinders.getTargetTagBackButton();
    expect(backButtonAfter, findsOneWidget);
    await tester.tap(backButtonAfter);
    await PumpSequences.navigation(tester);

    // Verify navigated to home screen
    expect(find.byKey(HomeKeys.carnivalDerbyCard), findsOneWidget);
    expect(find.byKey(HomeKeys.targetTagCard), findsOneWidget);
  });
}
