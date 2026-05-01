import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/pump_sequences.dart';
import '../results_screen/_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Results change settings then menu back returns to home',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, config);

    await setShieldMax(tester, 3);
    await UITestHelpers.addPlayer(tester, 'Player A', config);
    await UITestHelpers.addPlayer(tester, 'Player B', config);
    await UITestHelpers.startGame(tester, config);

    await completeGameToVictory(tester, 'Player A', 'Player B');

    // Click Change Settings on results screen
    await UITestHelpers.clickChangeSettings(tester, config);

    // Verify we're on the menu
    expect(config.getStartButton(), findsOneWidget);

    // Click menu back button
    final backButton = ElementFinders.getTargetTagBackButton();
    expect(backButton, findsOneWidget);
    await tester.tap(backButton);
    await PumpSequences.navigation(tester);

    // Verify we're on home screen with multiple game cards
    expect(ElementFinders.getCarnivalDerbyCard(), findsOneWidget);
    expect(ElementFinders.getTargetTagCard(), findsOneWidget);
    expect(ElementFinders.getMonsterMashCard(), findsOneWidget);
  });
}
