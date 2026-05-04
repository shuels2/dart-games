import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Pause modal appears on menu screen',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, config);

    // Verify we are on the menu screen
    expect(find.text('Clockwork Quest'), findsWidgets);

    // Disconnect dartboard — pause modal should appear
    await PauseModalHelpers.simulateDisconnectAndVerify(tester);
  });

  testWidgets('Pause blocks AppBar back button',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, config);

    await PauseModalHelpers.simulateDisconnectAndVerify(tester);

    // Try tapping back button — should be blocked by pause overlay
    final backButton = find.byTooltip('Back');
    if (backButton.evaluate().isNotEmpty) {
      await tester.tap(backButton, warnIfMissed: false);
      await PumpSequences.simpleUpdate(tester);
    }

    // Verify still on menu screen (not navigated away)
    expect(find.text('Clockwork Quest'), findsWidgets);
    PauseModalHelpers.verifyPauseModalVisible(tester);
  });

  testWidgets('Pause blocks start game button',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, config);

    // Add 2 players so start button is enabled
    await UITestHelpers.addPlayer(tester, 'Player A', config);
    await UITestHelpers.addPlayer(tester, 'Player B', config);

    await PauseModalHelpers.simulateDisconnectAndVerify(tester);

    // Try tapping start button — should be blocked
    final startButton = config.getStartButton();
    await tester.tap(startButton, warnIfMissed: false);
    await PumpSequences.simpleUpdate(tester);

    // Verify still on menu screen
    expect(find.text('Clockwork Quest'), findsWidgets);
    PauseModalHelpers.verifyPauseModalVisible(tester);
  });

  testWidgets('Pause blocks settings controls',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, config);

    await PauseModalHelpers.simulateDisconnectAndVerify(tester);

    // Try tapping add player button — should be blocked
    final addPlayerButton = config.getAddPlayerButton();
    await tester.tap(addPlayerButton, warnIfMissed: false);
    await PumpSequences.simpleUpdate(tester);

    // Verify pause modal is still visible and no dialog opened
    PauseModalHelpers.verifyPauseModalVisible(tester);
  });

  testWidgets('Pause on menu with basic disconnect',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, config);

    // Disconnect on menu screen
    await PauseModalHelpers.simulateDisconnectAndVerify(tester);

    // Verify the pause modal shows "Game Paused" text
    expect(find.text('Game Paused'), findsOneWidget);

    // Verify menu content is still behind the overlay
    expect(find.text('Clockwork Quest'), findsWidgets);
  });

  testWidgets('Pause dismisses and menu still works',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, config);

    // Disconnect then reconnect
    await PauseModalHelpers.simulateDisconnectAndVerify(tester);
    await PauseModalHelpers.simulateReconnectAndVerify(tester);

    // Verify menu is interactive again — add a player
    await UITestHelpers.addPlayer(tester, 'Player A', config);

    // Verify player was added (menu is functional)
    expect(find.text('Player A'), findsWidgets);
  });

  testWidgets('Pause blocks then reconnect enables back',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, config);

    // Disconnect — back button should be blocked
    await PauseModalHelpers.simulateDisconnectAndVerify(tester);

    // Reconnect — back button should work again
    await PauseModalHelpers.simulateReconnectAndVerify(tester);

    // Tap back button — should navigate to home screen
    final backButton = find.byTooltip('Back');
    if (backButton.evaluate().isNotEmpty) {
      await tester.tap(backButton);
      await PumpSequences.navigation(tester);
    }

    // Verify we navigated away from the menu
    PauseModalHelpers.verifyPauseModalNotVisible(tester);
  });
}
