import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // MANDATORY: Exit button navigation test.
  // Asserts ≥3 game cards visible — catches Navigator.pushNamedAndRemoveUntil('/')
  // regressions that would route to dartboard registration, not home.
  testWidgets('Results: Leave Arena returns to home screen with ≥3 game cards',
      (tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(
      tester,
      config,
      targetScore: 100,
      doubleFinishEnabled: false,
      playerNames: ['Player A', 'Player B'],
    );

    await completeGameToVictory(tester);

    // Tap Leave Arena
    await UITestHelpers.clickBackToMenu(tester, config);

    // Verify home screen — MUST see ≥3 game cards
    // This distinguishes home from dartboard registration page
    expect(ElementFinders.getCarnivalDerbyCard(), findsOneWidget);
    expect(ElementFinders.getTargetTagCard(), findsOneWidget);
    expect(ElementFinders.getMonsterMashCard(), findsOneWidget);
    expect(ElementFinders.getGladiatorArenaCard(), findsOneWidget);
  });
}
