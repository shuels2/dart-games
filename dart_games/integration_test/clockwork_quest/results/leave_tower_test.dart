import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 8: Leave Tower returns to game selection screen',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config);
    await completeGameToVictory(tester);

    await UITestHelpers.clickBackToMenu(tester, config);

    // Verify we're on the game selection home screen — multiple game cards must
    // be visible. This distinguishes game selection from the dartboard
    // registration screen, which would appear if navigation used '/' instead of
    // popUntil(isFirst).
    expect(ElementFinders.getClockworkQuestCard(), findsOneWidget);
    expect(ElementFinders.getCarnivalDerbyCard(), findsOneWidget);
    expect(ElementFinders.getTargetTagCard(), findsOneWidget);
  });
}
