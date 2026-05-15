// integration_test/tiki_golf/team_mode_gameplay/scorecard_team_only_rows_test.dart
//
// In team mode, the scorecard shows only the current team's player names
// in the scorecard area. Players from other teams should NOT appear in the
// scorecard while the current team is playing.
//
// Note: TikiGolfGameKeys.scorecardPlayerRow uses TableRow keys which may not
// be findable via byKey in Flutter web. We verify via player name text presence:
// active team players' names appear in scorecard, other team names do not.
//
// Section 12B File 7 — Team mode gameplay test 6 (scorecard_team_only_rows)
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/element_finders.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Team Mode Gameplay: scorecard shows current team players; other team players absent from scorecard area',
      (WidgetTester tester) async {
    await UITestHelpers.runWithFailureScreenshot(
      tester,
      'tiki_golf_team_mode_gameplay_scorecard_team_only_rows',
      () async {
        await UITestHelpers.resetServerState();
        // N=4 → 2 teams of 2; use very distinct names to identify which team
        await setupAndStartTeamGame(tester,
            playerNames: ['AlphaOne', 'AlphaTwo', 'BetaOne', 'BetaTwo']);

        final provider = ProviderHelpers.getTikiGolfProvider(tester);
        final game = provider.currentGame!;

        final teamIds = game.teamPlayers.keys.toList();
        expect(teamIds.length, 2);

        final activeTeamId = game.activeTeamId;
        expect(activeTeamId, isNotNull);

        // Determine which players are in the active team vs. the other team
        final activeTeamPlayers = game.teamPlayers[activeTeamId!]!;
        final otherTeamId = teamIds.firstWhere((id) => id != activeTeamId);
        final otherTeamPlayers = game.teamPlayers[otherTeamId]!;

        // Resolve player names
        final activePlayerNames = activeTeamPlayers
            .map((id) =>
                ProviderHelpers.findPlayerById(tester, id)?.name ?? id)
            .toList();
        final otherPlayerNames = otherTeamPlayers
            .map((id) =>
                ProviderHelpers.findPlayerById(tester, id)?.name ?? id)
            .toList();

        // Scorecard should be visible
        expect(ElementFinders.getTikiGolfScorecard(), findsOneWidget,
            reason: 'Scorecard should be visible in team mode');

        // Active team players: their names should appear in the scorecard
        for (final name in activePlayerNames) {
          expect(find.textContaining(name), findsWidgets,
              reason:
                  'Player "$name" (active team) should be visible in the scorecard area');
        }

        // Other team players: their names should NOT appear in the scorecard
        // (the scorecard shows only the current team)
        for (final name in otherPlayerNames) {
          expect(find.textContaining(name), findsNothing,
              reason:
                  'Player "$name" (other team, $otherTeamId) should NOT appear in the scorecard '
                  'while active team ($activeTeamId) is playing. '
                  'Active team players: $activePlayerNames, Other team players: $otherPlayerNames');
        }
      },
    );
  });
}
