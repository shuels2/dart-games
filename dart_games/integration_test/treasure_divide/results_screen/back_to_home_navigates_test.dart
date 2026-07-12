// integration_test/treasure_divide/results_screen/back_to_home_navigates_test.dart
//
// Results-1 — DOCK HOME returns to the home screen.
// Confirms Navigator.popUntil(context, (r) => r.isFirst) routes back to the
// game-selection grid, not the dartboard-registration page.
// Assertion: ≥3 game cards visible after tapping DOCK HOME.
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:dart_games/constants/test_keys.dart';
import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Results: DOCK HOME returns to home screen with ≥3 game cards',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester,
        numberOfRounds: 7, playerNames: ['HomeP1', 'HomeP2']);

    await playGameToResultsScreen(tester);

    // Verify results screen is showing
    expect(find.byKey(TreasureDivideResultsKeys.backToMenuButton),
        findsOneWidget,
        reason:
            '[DIAG td_results_back_home] DOCK HOME button not found — results screen not loaded');

    // Tap DOCK HOME
    await UITestHelpers.clickBackToMenu(tester, config);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    // Verify home screen with ≥3 game cards visible
    expect(ElementFinders.getCarnivalDerbyCard(), findsOneWidget,
        reason:
            '[DIAG td_results_back_home] Carnival Derby card not found — not on home screen');
    expect(ElementFinders.getTargetTagCard(), findsOneWidget,
        reason:
            '[DIAG td_results_back_home] Target Tag card not found — not on home screen');
    expect(ElementFinders.getMonsterMashCard(), findsOneWidget,
        reason:
            '[DIAG td_results_back_home] Monster Mash card not found — not on home screen');
    expect(ElementFinders.getTreasureDivideCard(), findsOneWidget,
        reason:
            '[DIAG td_results_back_home] Treasure Divide card not found — not on home screen');
  });
}
