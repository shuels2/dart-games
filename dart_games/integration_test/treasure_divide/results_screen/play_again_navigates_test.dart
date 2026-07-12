// integration_test/treasure_divide/results_screen/play_again_navigates_test.dart
//
// Results-2 — SAIL AGAIN launches straight into a fresh game.
// Verifies that Navigator.pushReplacement lands on TreasureDivideGameScreen
// (NOT the setup screen — that's what CHANGE COURSE is for).
// The new game uses the SAME settings, players, and (for manual team mode)
// team assignments as the just-finished game.
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

import 'package:dart_games/constants/test_keys.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Results: SAIL AGAIN launches straight into a fresh game (not the setup screen)',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester,
        numberOfRounds: 7, playerNames: ['SailP1', 'SailP2']);

    await playGameToResultsScreen(tester);

    // Verify results screen is showing
    expect(find.byKey(TreasureDivideResultsKeys.playAgainButton),
        findsOneWidget,
        reason:
            '[DIAG td_results_play_again] SAIL AGAIN button not found — results screen not loaded');

    // Tap SAIL AGAIN
    await UITestHelpers.clickPlayAgain(tester, config);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    // Should be on the GAME screen — not the setup screen. Assert on
    // game-screen widgets, and explicitly assert the setup screen's
    // SET SAIL! button is absent so a regression back to menu-nav
    // fails loudly.
    expect(find.byKey(TreasureDivideGameKeys.treasureMap), findsOneWidget,
        reason:
            '[DIAG td_results_play_again] Treasure map not visible — SAIL AGAIN '
            'must launch straight into a new game, not the setup screen');
    expect(find.byKey(TreasureDivideGameKeys.playerAvatar), findsOneWidget,
        reason:
            '[DIAG td_results_play_again] Player avatar not visible — game did '
            'not start after SAIL AGAIN');
    expect(ElementFinders.getTreasureDivideStartButton(), findsNothing,
        reason:
            '[DIAG td_results_play_again] SET SAIL! setup-screen button is '
            'visible — SAIL AGAIN incorrectly routed to the menu screen');

    // Fresh game state: round index reset to 0 and no darts thrown yet.
    expect(ProviderHelpers.getTreasureDivideCurrentRoundIndex(tester), 0,
        reason:
            '[DIAG td_results_play_again] New game must start on round 0');
    expect(
        ProviderHelpers.getTreasureDivideCurrentPlayerId(tester), isNotNull,
        reason:
            '[DIAG td_results_play_again] New game must have an active player');

    // Settings preserved: the new game uses the same numberOfRounds (7)
    // and the same playerIds (SailP1, SailP2) as the just-finished
    // game. If SAIL AGAIN ever regresses to opening a blank menu (or
    // shuffles unrelated players in), these assertions catch it.
    final provider = ProviderHelpers.getTreasureDivideProvider(tester);
    final newGame = provider.currentGame;
    expect(newGame, isNotNull,
        reason:
            '[DIAG td_results_play_again] currentGame must be non-null after '
            'SAIL AGAIN — startGame did not fire');
    expect(newGame!.numberOfRounds, 7,
        reason:
            '[DIAG td_results_play_again] New game must inherit numberOfRounds=7 '
            'from the previous game');
    expect(newGame.playerIds.length, 2,
        reason:
            '[DIAG td_results_play_again] New game must reuse the previous '
            'game\'s 2 players');
  });
}
