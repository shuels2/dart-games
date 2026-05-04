import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/element_finders.dart';
import '../../shared/settings_helpers.dart';
import '../results_screen/_helpers.dart' as results_helpers;
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 1: Pause modal appears on results screen',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);
    await SettingsHelpers.setMonsterMashHealthMax(tester, 10);
    await UITestHelpers.addPlayer(tester, 'Player A', config);
    await UITestHelpers.addPlayer(tester, 'Player B', config);
    await UITestHelpers.startGame(tester, config);

    await results_helpers.completeGameToVictory(tester);

    // Verify we are on results screen
    expect(config.getPlayAgainButton(), findsOneWidget);

    await PauseModalHelpers.simulateDisconnectAndVerify(tester);

    // Still on results screen
    expect(config.getPlayAgainButton(), findsOneWidget);

    await PauseModalHelpers.simulateReconnectAndVerify(tester);
  });

  testWidgets('Test 2: Pause blocks Play Again button',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);
    await SettingsHelpers.setMonsterMashHealthMax(tester, 10);
    await UITestHelpers.addPlayer(tester, 'Player A', config);
    await UITestHelpers.addPlayer(tester, 'Player B', config);
    await UITestHelpers.startGame(tester, config);

    await results_helpers.completeGameToVictory(tester);

    await PauseModalHelpers.simulateDisconnectAndVerify(tester);

    // Try tapping Play Again — overlay should block it
    await tester.tap(config.getPlayAgainButton(), warnIfMissed: false);
    await PumpSequences.simpleUpdate(tester);

    // Should still be on results screen
    PauseModalHelpers.verifyPauseModalVisible(tester);
    expect(config.getPlayAgainButton(), findsOneWidget);

    await PauseModalHelpers.simulateReconnectAndVerify(tester);
  });

  testWidgets('Test 3: Pause blocks Change Settings button',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);
    await SettingsHelpers.setMonsterMashHealthMax(tester, 10);
    await UITestHelpers.addPlayer(tester, 'Player A', config);
    await UITestHelpers.addPlayer(tester, 'Player B', config);
    await UITestHelpers.startGame(tester, config);

    await results_helpers.completeGameToVictory(tester);

    await PauseModalHelpers.simulateDisconnectAndVerify(tester);

    // Try tapping Change Settings — overlay should block it
    await tester.tap(config.getChangeSettingsButton(), warnIfMissed: false);
    await PumpSequences.simpleUpdate(tester);

    // Should still be on results screen
    PauseModalHelpers.verifyPauseModalVisible(tester);
    expect(config.getPlayAgainButton(), findsOneWidget);

    await PauseModalHelpers.simulateReconnectAndVerify(tester);
  });

  testWidgets('Test 4: Pause blocks Back to Menu button',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);
    await SettingsHelpers.setMonsterMashHealthMax(tester, 10);
    await UITestHelpers.addPlayer(tester, 'Player A', config);
    await UITestHelpers.addPlayer(tester, 'Player B', config);
    await UITestHelpers.startGame(tester, config);

    await results_helpers.completeGameToVictory(tester);

    await PauseModalHelpers.simulateDisconnectAndVerify(tester);

    // Try tapping Back to Menu — overlay should block it
    await tester.tap(config.getBackToMenuButton(), warnIfMissed: false);
    await PumpSequences.simpleUpdate(tester);

    // Should still be on results screen
    PauseModalHelpers.verifyPauseModalVisible(tester);
    expect(config.getPlayAgainButton(), findsOneWidget);

    await PauseModalHelpers.simulateReconnectAndVerify(tester);
  });

  testWidgets('Test 5: Pause dismisses and buttons work',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);
    await SettingsHelpers.setMonsterMashHealthMax(tester, 10);
    await UITestHelpers.addPlayer(tester, 'Player A', config);
    await UITestHelpers.addPlayer(tester, 'Player B', config);
    await UITestHelpers.startGame(tester, config);

    await results_helpers.completeGameToVictory(tester);

    // Disconnect then reconnect
    await PauseModalHelpers.simulateDisconnectAndVerify(tester);
    await PauseModalHelpers.simulateReconnectAndVerify(tester);

    // Buttons should work now — tap Back to Menu
    await UITestHelpers.clickBackToMenu(tester, config);

    // Should be back on home screen
    expect(ElementFinders.getMonsterMashCard(), findsOneWidget);
  });
}
