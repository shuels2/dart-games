import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Select Different Game returns to game selection screen',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, config);

    await UITestHelpers.addPlayer(tester, 'Player A', config);
    await UITestHelpers.addPlayer(tester, 'Player B', config);
    await UITestHelpers.startGame(tester, config);

    await completeGameToVictory(tester, 'Player A', 'Player B');

    // Click Select Different Game (back to menu)
    final backButton = config.getBackToMenuButton();
    await tester.ensureVisible(backButton);
    await tester.pump();
    await tester.tap(backButton);
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    await tester.pump();

    // Verify we're on the game selection home screen — multiple game cards visible
    expect(ElementFinders.getTargetTagCard(), findsOneWidget);
    expect(ElementFinders.getCarnivalDerbyCard(), findsOneWidget);
    expect(ElementFinders.getMonsterMashCard(), findsOneWidget);
  });
}
