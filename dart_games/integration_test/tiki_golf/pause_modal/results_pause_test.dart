import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 1: Pause modal appears on results screen when board disconnects',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester,
        playerNames: ['Player A', 'Player B']);
    await completeGameToVictory(tester);

    // Verify we are on results screen
    expect(config.getPlayAgainButton(), findsOneWidget);

    await PauseModalHelpers.simulateDisconnectAndVerify(tester);

    // Still on results screen
    expect(config.getPlayAgainButton(), findsOneWidget);

    await PauseModalHelpers.simulateReconnectAndVerify(tester);
  });

  testWidgets('Test 2: Pause blocks PLAY AGAIN button tap',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester,
        playerNames: ['Player A', 'Player B']);
    await completeGameToVictory(tester);

    // Verify we are on results screen
    expect(config.getPlayAgainButton(), findsOneWidget);

    await PauseModalHelpers.simulateDisconnectAndVerify(tester);

    // Try tapping PLAY AGAIN — overlay should block it
    await tester.tap(config.getPlayAgainButton(), warnIfMissed: false);
    await PumpSequences.simpleUpdate(tester);

    // Should still be on results screen
    PauseModalHelpers.verifyPauseModalVisible(tester);
    expect(config.getPlayAgainButton(), findsOneWidget);

    await PauseModalHelpers.simulateReconnectAndVerify(tester);
  });

  testWidgets('Test 3: Pause blocks CHANGE SETTINGS button tap',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester,
        playerNames: ['Player A', 'Player B']);
    await completeGameToVictory(tester);

    // Verify we are on results screen
    expect(config.getPlayAgainButton(), findsOneWidget);

    await PauseModalHelpers.simulateDisconnectAndVerify(tester);

    // Try tapping CHANGE SETTINGS — overlay should block it
    await tester.tap(config.getChangeSettingsButton(), warnIfMissed: false);
    await PumpSequences.simpleUpdate(tester);

    // Should still be on results screen
    PauseModalHelpers.verifyPauseModalVisible(tester);
    expect(config.getPlayAgainButton(), findsOneWidget);

    await PauseModalHelpers.simulateReconnectAndVerify(tester);
  });

  testWidgets('Test 4: Pause blocks BACK TO MENU button tap',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester,
        playerNames: ['Player A', 'Player B']);
    await completeGameToVictory(tester);

    // Verify we are on results screen
    expect(config.getPlayAgainButton(), findsOneWidget);

    await PauseModalHelpers.simulateDisconnectAndVerify(tester);

    // Try tapping BACK TO MENU — overlay should block it
    await tester.tap(config.getBackToMenuButton(), warnIfMissed: false);
    await PumpSequences.simpleUpdate(tester);

    // Should still be on results screen
    PauseModalHelpers.verifyPauseModalVisible(tester);
    expect(config.getPlayAgainButton(), findsOneWidget);

    await PauseModalHelpers.simulateReconnectAndVerify(tester);
  });

  testWidgets('Test 5: Pause dismisses on reconnect; action buttons work again',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester,
        playerNames: ['Player A', 'Player B']);
    await completeGameToVictory(tester);

    // Verify we are on results screen
    expect(config.getPlayAgainButton(), findsOneWidget);

    // Disconnect then reconnect
    await PauseModalHelpers.simulateDisconnectAndVerify(tester);
    await PauseModalHelpers.simulateReconnectAndVerify(tester);

    // Buttons should work now — tap Back to Menu
    await UITestHelpers.clickBackToMenu(tester, config);

    // Should be back on home screen with Tiki Golf card visible
    expect(ElementFinders.getTikiGolfCard(), findsOneWidget);
  });
}
