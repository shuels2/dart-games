// integration_test/tiki_golf/team_mode_gameplay/team_win_results_screen_test.dart
//
// Team mode game ends → results screen shows team crest as winner.
//
// Section 12B File 7 — Team mode gameplay test 8 (team_win_results_screen)
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/play_to_complete_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Team Mode Gameplay: game ends → results screen shows winning team crest',
      (WidgetTester tester) async {
    await UITestHelpers.runWithFailureScreenshot(
      tester,
      'tiki_golf_team_mode_gameplay_team_win_results',
      () async {
        await UITestHelpers.resetServerState();
        // N=4 → 2 teams of 2
        await setupAndStartTeamGame(tester,
            playerNames: ['A', 'B', 'C', 'D']);

        final provider = ProviderHelpers.getTikiGolfProvider(tester);

        // Drive to completion via PTC
        await PlayToCompleteHelpers.tapPlayToComplete(tester);
        await PlayToCompleteHelpers.waitForGameCompletion(
          tester,
          isComplete: () => provider.hasWinner,
          maxIterations: 700,
        );

        expect(provider.hasWinner, isTrue,
            reason: 'Team game should have a winner');

        // Results screen: winner team crest should be shown
        final winnerCrest = ElementFinders.getTikiGolfWinnerTeamCrest();
        expect(winnerCrest, findsOneWidget,
            reason:
                'Results screen should display winning team crest — '
                'proves team mode results screen shows team identity');

        // Play Again button present (confirms we're on results screen)
        expect(config.getPlayAgainButton(), findsOneWidget,
            reason: 'Play Again button should be on results screen');

        // Winner team ID should be set
        final winnerTeamId = ProviderHelpers.getTikiGolfWinnerTeamId(tester);
        expect(winnerTeamId, isNotNull,
            reason: 'Winner team ID should be set after team game ends');
      },
    );
  });
}
