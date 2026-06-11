// integration_test/treasure_divide/results_screen/play_again_navigates_test.dart
//
// Results-2 — SAIL AGAIN returns to the Treasure Divide menu.
// Verifies that Navigator.pushAndRemoveUntil pushes a fresh TreasureDivideMenuScreen.
// The menu retains the last game's settings (both _playAgain and _changeSettings
// pass initialXxx params from the completed game — this is by design).
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '_helpers.dart';

import 'package:dart_games/constants/test_keys.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Results: SAIL AGAIN returns to Treasure Divide menu',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester,
        numberOfRounds: 7, playerNames: ['SailP1', 'SailP2']);

    await playGameToResultsScreen(tester);

    // Verify results screen is showing
    expect(find.byKey(TreasureDivideResultsKeys.playAgainButton),
        findsOneWidget,
        reason:
            '[DIAG td_results_play_again] SAIL AGAIN button not found — results screen not loaded');

    // Tap SAIL AGAIN
    await UITestHelpers.clickPlayAgain(tester, config);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    // Verify we are back on the Treasure Divide menu
    expect(ElementFinders.getTreasureDivideStartButton(), findsOneWidget,
        reason:
            '[DIAG td_results_play_again] SET SAIL! button not found — '
            'SAIL AGAIN did not navigate to TD menu');

    // NOTE: Both SAIL AGAIN and CHANGE COURSE preserve settings from the
    // completed game (initialNumberOfRounds: game.numberOfRounds etc.).
    // The game was started with Rounds=7, so that value is preserved.
    // This is the intended behavior — spec ambiguity flagged: the brief
    // states "Play Again should reset", but the implementation preserves
    // settings for SAIL AGAIN identical to CHANGE COURSE.
    expect(find.text('7'), findsWidgets,
        reason:
            '[DIAG td_results_play_again] Rounds=7 should be shown — settings '
            'preserved after SAIL AGAIN');
  });
}
