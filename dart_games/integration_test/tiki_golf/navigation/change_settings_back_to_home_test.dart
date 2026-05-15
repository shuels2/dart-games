// integration_test/tiki_golf/navigation/change_settings_back_to_home_test.dart
//
// Test Nav-3 — Complete a quick Solo game, on results tap CHANGE SETTINGS,
//              assert menu loaded, then tap back arrow, assert home with ≥3 cards.
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/pump_sequences.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Results change settings then menu back returns to home screen',
      (tester) async {
    await UITestHelpers.resetServerState();

    // Set up and start a 2-player solo game (default max strokes = 3)
    await setupAndStartGame(
      tester,
      playerNames: ['GoPlayer1', 'GoPlayer2'],
    );

    // Complete the game to reach results screen
    await playGameToCompletion(tester);

    // Verify results screen is showing
    expect(config.getPlayAgainButton(), findsOneWidget,
        reason: '[DIAG cs_back_home] Play Again button not found — results screen not loaded');

    // Tap Change Settings
    await UITestHelpers.clickChangeSettings(tester, config);

    // Verify menu is loaded
    final startButton = ElementFinders.getTikiGolfStartButton();
    expect(startButton, findsOneWidget,
        reason: '[DIAG cs_back_home] TEE OFF button not found — menu did not load after Change Settings');

    // Tap menu back button
    final backButton = ElementFinders.getTikiGolfBackButton();
    expect(backButton, findsOneWidget,
        reason: '[DIAG cs_back_home] Tiki Golf back button not found on menu');
    await tester.tap(backButton);
    await PumpSequences.navigation(tester);

    // Verify home screen with ≥3 game cards
    expect(ElementFinders.getCarnivalDerbyCard(), findsOneWidget,
        reason: '[DIAG cs_back_home] Carnival Derby card not found — not on home screen after back');
    expect(ElementFinders.getTargetTagCard(), findsOneWidget,
        reason: '[DIAG cs_back_home] Target Tag card not found — not on home screen after back');
    expect(ElementFinders.getMonsterMashCard(), findsOneWidget,
        reason: '[DIAG cs_back_home] Monster Mash card not found — not on home screen after back');
  });
}
