import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/pump_sequences.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // MANDATORY: Exit button navigation test.
  // Verifies that clicking MISSION CONTROL (back to home) returns to game selection
  // screen (NOT the dartboard registration screen).
  //
  // A single-card assertion is a false positive: pushNamedAndRemoveUntil('/')
  // routes to dartboard registration in real use, but shows the home screen in
  // tests. Three cards proves Navigator.popUntil(isFirst) is used correctly.
  testWidgets('Results: leave to home shows at least 3 game cards on home screen',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config);
    await completeGameToVictory(tester);
    await PumpSequences.fullRebuild(tester);

    // Verify results screen is visible
    expect(config.getPlayAgainButton(), findsOneWidget);

    // Tap MISSION CONTROL (back to home button)
    await UITestHelpers.clickBackToMenu(tester, config);

    // MANDATORY: At least 3 game cards must be visible on the home screen.
    // This ensures we navigated to the game selection screen (via popUntil),
    // not to the dartboard registration screen (which would happen with '/' route).
    expect(ElementFinders.getCarnivalDerbyCard(), findsOneWidget,
        reason: 'Carnival Derby card must be visible on home screen');
    expect(ElementFinders.getTargetTagCard(), findsOneWidget,
        reason: 'Target Tag card must be visible on home screen');
    expect(ElementFinders.getMonsterMashCard(), findsOneWidget,
        reason: 'Monster Mash card must be visible on home screen');
  });
}
