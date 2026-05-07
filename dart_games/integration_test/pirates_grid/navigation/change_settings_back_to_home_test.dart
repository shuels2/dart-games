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

    // Verify on results screen
    expect(config.getPlayAgainButton(), findsOneWidget,
        reason: 'Should be on results screen');

    // Click NEW VOYAGE → menu screen. Scroll into view first because the
    // results screen wraps its action buttons in a SingleChildScrollView and
    // headless chromedriver requires the target to be in the viewport for
    // the click to register.
    final newVoyageButton = config.getChangeSettingsButton();
    await tester.ensureVisible(newVoyageButton);
    await tester.pump();
    await tester.tap(newVoyageButton);
    await PumpSequences.navigation(tester);

    // Inline diagnostic — prefixed with [DIAG] so it shows up in the
    // assertion's reason when the test fails. Tells us which screen is
    // actually mounted when the start-button lookup misses.
    final diag1 = '[DIAG after-NEW-VOYAGE '
        'menuStart=${ElementFinders.getPiratesGridStartButton().evaluate().length} '
        'menuBack=${ElementFinders.getPiratesGridBackButton().evaluate().length} '
        'gameSkip=${ElementFinders.getPiratesGridSkipTurnButton().evaluate().length} '
        'resultsPlayAgain=${config.getPlayAgainButton().evaluate().length} '
        'homeCarnival=${ElementFinders.getCarnivalDerbyCard().evaluate().length} '
        'resumeModal=${ElementFinders.getResumeGameModalOverlay().evaluate().length}]';
    expect(ElementFinders.getPiratesGridStartButton(), findsOneWidget,
        reason: 'Should be on menu after NEW VOYAGE. $diag1');

    // Tap menu back button → home
    final backButton = ElementFinders.getPiratesGridBackButton();
    expect(backButton, findsOneWidget);
    await tester.tap(backButton);
    await PumpSequences.navigation(tester);

    // Verify home screen
    final diag2 = '[DIAG after-menu-back '
        'menuStart=${ElementFinders.getPiratesGridStartButton().evaluate().length} '
        'gameSkip=${ElementFinders.getPiratesGridSkipTurnButton().evaluate().length} '
        'homeCarnival=${ElementFinders.getCarnivalDerbyCard().evaluate().length} '
        'homeTargetTag=${ElementFinders.getTargetTagCard().evaluate().length}]';
    expect(ElementFinders.getCarnivalDerbyCard(), findsOneWidget,
        reason: 'Should be on home screen. $diag2');
    expect(ElementFinders.getTargetTagCard(), findsOneWidget);
    expect(ElementFinders.getMonsterMashCard(), findsOneWidget);
  });
}
