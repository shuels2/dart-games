import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Select Different Game returns to game selection screen',
      (WidgetTester tester) async {
    await navigateToCarnivalDerbyMenu(tester);

    // Set a low target score for a quick 1-turn win (T20 x3 = 180)
    await setTargetScore(tester, 180);
    await UITestHelpers.addPlayer(tester, 'Player1', config);
    await startGame(tester);

    // Win in one turn
    await throwDartViaMock(tester, 20, multiplier: 'triple');
    await throwDartViaMock(tester, 20, multiplier: 'triple');
    await throwDartViaMock(tester, 20, multiplier: 'triple');
    await clickDartsRemoved(tester);

    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    await tester.pump();

    // Click Select Different Game (back to menu)
    final backButton = config.getBackToMenuButton();
    await tester.ensureVisible(backButton);
    await tester.pump();
    await tester.tap(backButton);
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    await tester.pump();

    // Verify we're on the game selection home screen — multiple game cards visible
    expect(ElementFinders.getCarnivalDerbyCard(), findsOneWidget);
    expect(ElementFinders.getTargetTagCard(), findsOneWidget);
    expect(ElementFinders.getMonsterMashCard(), findsOneWidget);
  });
}
