// integration_test/treasure_divide/pause_modal/results_pause_test.dart
//
// Pause-modal tests for the Treasure Divide results screen.
// 5 testWidgets — canonical 1-for-1 mirror of monster_mash/pause_modal/results_pause_test.dart.
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/element_finders.dart';
import '_helpers.dart';

// ==========================================================================
// INLINE FAST GAME COMPLETION — delegates to the proven helpers in
// pause_modal/_helpers.dart.  setupAndStartGame uses the default 9-round
// config; completeGameToVictory drives every turn via clickDartsRemoved (the
// same pattern used by results_screen tests) with a 100-iteration safety
// bound.  Total wall-clock for a 2-player 9-round game: ~20-40s.
// ==========================================================================

Future<void> _setupAndStartFastGame(WidgetTester tester) async {
  await setupAndStartGame(tester);
}

Future<void> _playToResults(WidgetTester tester) async {
  await completeGameToVictory(tester);
}

// ==========================================================================
// MAIN
// ==========================================================================

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 1: Pause modal appears on TD results screen when dartboard disconnects',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await _setupAndStartFastGame(tester);
    await _playToResults(tester);

    // Verify we are on results screen
    expect(config.getPlayAgainButton(), findsOneWidget);

    await PauseModalHelpers.simulateDisconnectAndVerify(tester);

    // Still on results screen
    expect(config.getPlayAgainButton(), findsOneWidget);

    await PauseModalHelpers.simulateReconnectAndVerify(tester);
  });

  testWidgets('Test 2: Pause modal blocks Play Again button on TD results screen',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await _setupAndStartFastGame(tester);
    await _playToResults(tester);

    await PauseModalHelpers.simulateDisconnectAndVerify(tester);

    // Try tapping SAIL AGAIN — overlay should block it
    await tester.tap(config.getPlayAgainButton(), warnIfMissed: false);
    await PumpSequences.simpleUpdate(tester);

    // Should still be on results screen
    PauseModalHelpers.verifyPauseModalVisible(tester);
    expect(config.getPlayAgainButton(), findsOneWidget);

    await PauseModalHelpers.simulateReconnectAndVerify(tester);
  });

  testWidgets('Test 3: Pause modal blocks Change Settings button on TD results screen',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await _setupAndStartFastGame(tester);
    await _playToResults(tester);

    await PauseModalHelpers.simulateDisconnectAndVerify(tester);

    // Try tapping CHANGE COURSE — overlay should block it
    await tester.tap(config.getChangeSettingsButton(), warnIfMissed: false);
    await PumpSequences.simpleUpdate(tester);

    // Should still be on results screen
    PauseModalHelpers.verifyPauseModalVisible(tester);
    expect(config.getPlayAgainButton(), findsOneWidget);

    await PauseModalHelpers.simulateReconnectAndVerify(tester);
  });

  testWidgets('Test 4: Pause modal blocks Back to Menu button on TD results screen',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await _setupAndStartFastGame(tester);
    await _playToResults(tester);

    await PauseModalHelpers.simulateDisconnectAndVerify(tester);

    // Try tapping DOCK HOME — overlay should block it
    await tester.tap(config.getBackToMenuButton(), warnIfMissed: false);
    await PumpSequences.simpleUpdate(tester);

    // Should still be on results screen
    PauseModalHelpers.verifyPauseModalVisible(tester);
    expect(config.getPlayAgainButton(), findsOneWidget);

    await PauseModalHelpers.simulateReconnectAndVerify(tester);
  });

  testWidgets('Test 5: Action buttons work after pause modal dismisses on TD results screen',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await _setupAndStartFastGame(tester);
    await _playToResults(tester);

    // Disconnect then reconnect
    await PauseModalHelpers.simulateDisconnectAndVerify(tester);
    await PauseModalHelpers.simulateReconnectAndVerify(tester);

    // Buttons should work now — tap DOCK HOME (Back to Menu)
    await UITestHelpers.clickBackToMenu(tester, config);

    // Should be back on home screen
    expect(ElementFinders.getTreasureDivideCard(), findsOneWidget);
  });
}
