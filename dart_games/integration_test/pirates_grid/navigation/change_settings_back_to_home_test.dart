import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/pump_sequences.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Navigation: after game, click NEW VOYAGE then back returns to home',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config,
        bestOf: '3',
        stealMode: true,
        playerNames: ['Player A', 'Player B']);

    // Complete game to results
    await completeGameToVictory(tester);

    UITestHelpers.dumpRoute(tester, 'after-completeGameToVictory');

    // Verify on results screen
    expect(config.getPlayAgainButton(), findsOneWidget,
        reason: 'Should be on results screen');

    // Click NEW VOYAGE → menu screen
    await tester.tap(config.getChangeSettingsButton());
    await PumpSequences.navigation(tester);

    UITestHelpers.dumpRoute(tester, 'after-NEW-VOYAGE-tap');

    expect(ElementFinders.getPiratesGridStartButton(), findsOneWidget,
        reason: 'Should be on menu after NEW VOYAGE');

    // Tap menu back button → home
    final backButton = ElementFinders.getPiratesGridBackButton();
    expect(backButton, findsOneWidget);
    await tester.tap(backButton);
    await PumpSequences.navigation(tester);

    UITestHelpers.dumpRoute(tester, 'after-menu-back-tap');

    // Verify home screen
    expect(ElementFinders.getCarnivalDerbyCard(), findsOneWidget);
    expect(ElementFinders.getTargetTagCard(), findsOneWidget);
    expect(ElementFinders.getMonsterMashCard(), findsOneWidget);
  });
}
