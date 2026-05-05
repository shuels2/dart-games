import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';

import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Pause modal appears on results screen',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config);
    await completeGameToVictory(tester);

    // Verify we are on results screen
    expect(find.byKey(ClockworkQuestResultsKeys.winnerName), findsOneWidget);

    // Disconnect — pause modal should appear
    await PauseModalHelpers.simulateDisconnectAndVerify(tester);
  });

  testWidgets('Pause blocks Play Again button',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config);
    await completeGameToVictory(tester);

    expect(find.byKey(ClockworkQuestResultsKeys.winnerName), findsOneWidget);

    await PauseModalHelpers.simulateDisconnectAndVerify(tester);

    // Try tapping Play Again — should be blocked
    final playAgainButton = config.getPlayAgainButton();
    await tester.tap(playAgainButton, warnIfMissed: false);
    await PumpSequences.simpleUpdate(tester);

    // Verify still on results screen
    expect(find.byKey(ClockworkQuestResultsKeys.winnerName), findsOneWidget);
    PauseModalHelpers.verifyPauseModalVisible(tester);
  });

  testWidgets('Pause blocks Change Settings button',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config);
    await completeGameToVictory(tester);

    expect(find.byKey(ClockworkQuestResultsKeys.winnerName), findsOneWidget);

    await PauseModalHelpers.simulateDisconnectAndVerify(tester);

    // Try tapping Change Settings — should be blocked
    final changeSettingsButton = config.getChangeSettingsButton();
    await tester.tap(changeSettingsButton, warnIfMissed: false);
    await PumpSequences.simpleUpdate(tester);

    // Verify still on results screen
    expect(find.byKey(ClockworkQuestResultsKeys.winnerName), findsOneWidget);
    PauseModalHelpers.verifyPauseModalVisible(tester);
  });

  testWidgets('Pause blocks Back to Menu button',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config);
    await completeGameToVictory(tester);

    expect(find.byKey(ClockworkQuestResultsKeys.winnerName), findsOneWidget);

    await PauseModalHelpers.simulateDisconnectAndVerify(tester);

    // Try tapping Back to Menu — should be blocked
    final backToMenuButton = config.getBackToMenuButton();
    await tester.tap(backToMenuButton, warnIfMissed: false);
    await PumpSequences.simpleUpdate(tester);

    // Verify still on results screen
    expect(find.byKey(ClockworkQuestResultsKeys.winnerName), findsOneWidget);
    PauseModalHelpers.verifyPauseModalVisible(tester);
  });

  testWidgets('Pause dismisses and buttons work',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config);
    await completeGameToVictory(tester);

    expect(find.byKey(ClockworkQuestResultsKeys.winnerName), findsOneWidget);

    // Disconnect then reconnect
    await PauseModalHelpers.simulateDisconnectAndVerify(tester);
    await PauseModalHelpers.simulateReconnectAndVerify(tester);

    // Tap Play Again — should navigate now
    final playAgainButton = config.getPlayAgainButton();
    await tester.tap(playAgainButton);
    await PumpSequences.navigation(tester);

    // Verify we left the results screen
    PauseModalHelpers.verifyPauseModalNotVisible(tester);
  });
}
