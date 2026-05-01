import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/pump_sequences.dart';
import '../results/_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Results change settings then menu back returns to home',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config);

    await completeGameToVictory(tester);
    await PumpSequences.fullRebuild(tester);
    expect(config.getPlayAgainButton(), findsOneWidget);

    // Click Change Settings on results screen
    await UITestHelpers.clickChangeSettings(tester, config);

    // Verify we're on the menu
    expect(config.getStartButton(), findsOneWidget);

    // Click menu back button
    final backButton = ElementFinders.getClockworkQuestBackButton();
    expect(backButton, findsOneWidget);
    await tester.tap(backButton);
    await PumpSequences.navigation(tester);

    // Verify we're on home screen with multiple game cards
    expect(ElementFinders.getCarnivalDerbyCard(), findsOneWidget);
    expect(ElementFinders.getTargetTagCard(), findsOneWidget);
    expect(ElementFinders.getMonsterMashCard(), findsOneWidget);
  });
}
