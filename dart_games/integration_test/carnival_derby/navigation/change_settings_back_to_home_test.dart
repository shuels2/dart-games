import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/pump_sequences.dart';
import '../ui/_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Results change settings then menu back returns to home',
      (WidgetTester tester) async {
    await navigateToCarnivalDerbyMenu(tester);

    // Set low target for quick win
    await setTargetScore(tester, 180);
    await UITestHelpers.addPlayer(tester, 'Player A', config);
    await UITestHelpers.addPlayer(tester, 'Player B', config);
    await startGame(tester);

    // Win in one turn: 3x T20 = 180
    await throwDartViaMock(tester, 20, multiplier: 'triple');
    await throwDartViaMock(tester, 20, multiplier: 'triple');
    await throwDartViaMock(tester, 20, multiplier: 'triple');
    await clickDartsRemoved(tester);

    // Wait for results screen
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    await PumpSequences.fullRebuild(tester);

    // Click Change Settings on results screen
    await UITestHelpers.clickChangeSettings(tester, config);

    // Verify we're on the menu
    expect(config.getStartButton(), findsOneWidget);

    // Click menu back button
    final backButton = ElementFinders.getCarnivalDerbyBackButton();
    expect(backButton, findsOneWidget);
    await tester.tap(backButton);
    await PumpSequences.navigation(tester);

    // Verify we're on home screen with multiple game cards
    expect(ElementFinders.getCarnivalDerbyCard(), findsOneWidget);
    expect(ElementFinders.getTargetTagCard(), findsOneWidget);
    expect(ElementFinders.getMonsterMashCard(), findsOneWidget);
  });
}
