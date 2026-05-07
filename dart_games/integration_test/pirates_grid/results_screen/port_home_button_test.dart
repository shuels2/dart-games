import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/pump_sequences.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // MANDATORY exit-button test.
  // Verifies PORT HOME button uses Navigator.popUntil(route.isFirst) pattern
  // to correctly return to home screen showing ≥3 game cards.
  testWidgets('Results: PORT HOME button returns to home screen',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config,
        playerNames: ['Player A', 'Player B']);

    await completeGameToVictory(tester);

    UITestHelpers.dumpRoute(tester, 'after-completeGameToVictory');

    // Verify on results screen
    expect(config.getPlayAgainButton(), findsOneWidget,
        reason: 'Should be on results screen');

    // Tap PORT HOME button
    final portHomeButton = config.getBackToMenuButton();
    expect(portHomeButton, findsOneWidget,
        reason: 'PORT HOME button should be present on results screen');
    await tester.tap(portHomeButton);
    await PumpSequences.navigation(tester);
    // Home screen reloads players/dartboard async; give it extra time so
    // canPlayGames-gated game cards have rebuilt before we look for them.
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    await tester.pump();
    await PumpSequences.fullRebuild(tester);

    UITestHelpers.dumpRoute(tester, 'after-PORT-HOME-tap');

    // Verify we are on the home screen — ≥3 game cards visible
    expect(ElementFinders.getCarnivalDerbyCard(), findsOneWidget,
        reason: 'Carnival Derby card should be visible on home screen');
    expect(ElementFinders.getTargetTagCard(), findsOneWidget,
        reason: 'Target Tag card should be visible on home screen');
    expect(ElementFinders.getMonsterMashCard(), findsOneWidget,
        reason: 'Monster Mash card should be visible on home screen');
  });
}
