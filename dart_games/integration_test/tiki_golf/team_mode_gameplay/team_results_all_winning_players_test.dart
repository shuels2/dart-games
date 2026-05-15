// integration_test/tiki_golf/team_mode_gameplay/team_results_all_winning_players_test.dart
//
// Team mode results screen: ALL winning-team players' avatars visible.
//
// After a team mode game completes, the results screen should show
// all players on the winning team via TikiGolfResultsKeys.winnerTeamPlayer(playerId).
//
// Section 12B File 7 — Team mode gameplay test 10 (team_results_all_winning_players)
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
      'Team Mode Results: all winning-team players\' avatars shown on results screen',
      (WidgetTester tester) async {
    await UITestHelpers.runWithFailureScreenshot(
      tester,
      'tiki_golf_team_mode_gameplay_results_all_winning_players',
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

        expect(provider.hasWinner, isTrue);

        // Get the winning team's player IDs from the provider
        final winnerTeamId = ProviderHelpers.getTikiGolfWinnerTeamId(tester);
        expect(winnerTeamId, isNotNull,
            reason: 'Winner team ID should be set');

        final game = provider.currentGame!;
        final winningTeamPlayers = game.teamPlayers[winnerTeamId]!;
        expect(winningTeamPlayers, isNotEmpty,
            reason: 'Winning team should have at least one player');

        // All winning-team players should have avatar widgets on results screen
        for (final playerId in winningTeamPlayers) {
          final playerAvatar =
              ElementFinders.getTikiGolfWinnerTeamPlayer(playerId);
          expect(playerAvatar, findsOneWidget,
              reason:
                  'Player $playerId on winning team $winnerTeamId should have an avatar '
                  'displayed on the results screen');
        }

        // Winning team crest should also be present
        expect(ElementFinders.getTikiGolfWinnerTeamCrest(), findsOneWidget,
            reason: 'Winning team crest should be visible on results screen');
      },
    );
  });
}
