import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/pump_sequences.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Navigation: back from menu returns to home screen',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, config);

    // Verify we are on the menu screen
    expect(ElementFinders.getGladiatorArenaStartButton(), findsOneWidget);

    // Tap back button on menu
    final backButton = ElementFinders.getGladiatorArenaBackButton();
    await tester.tap(backButton);
    await PumpSequences.navigation(tester);

    // Verify multiple game cards are visible (confirms home screen, not dartboard screen)
    expect(ElementFinders.getCarnivalDerbyCard(), findsOneWidget);
    expect(ElementFinders.getTargetTagCard(), findsOneWidget);
    expect(ElementFinders.getMonsterMashCard(), findsOneWidget);
    expect(ElementFinders.getGladiatorArenaCard(), findsOneWidget);
  });
}
