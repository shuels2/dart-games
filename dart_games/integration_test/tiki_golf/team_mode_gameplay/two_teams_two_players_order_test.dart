// integration_test/tiki_golf/team_mode_gameplay/two_teams_two_players_order_test.dart
//
// Team [A:2, B:2]: verify shot order A_P1 → A_P2 → B_P1 → B_P2
// for hole 1 (teams play through in team order before handing off).
//
// N=4 players in Team+Random mode → 2 teams of 2.
// We observe the active player ID after each throw to verify the ordering.
//
// Section 12B File 7 — Team mode gameplay test 1 (two_teams_two_players_order)
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Team Mode Gameplay: [A:2, B:2] hole 1 order is A_P1→A_P2→B_P1→B_P2',
      (WidgetTester tester) async {
    await UITestHelpers.runWithFailureScreenshot(
      tester,
      'tiki_golf_team_mode_gameplay_two_teams_order',
      () async {
        await UITestHelpers.resetServerState();
        // N=4 → 2 teams of 2
        await setupAndStartTeamGame(tester,
            playerNames: ['P1', 'P2', 'P3', 'P4']);

        final provider = ProviderHelpers.getTikiGolfProvider(tester);
        final game = provider.currentGame!;

        // Determine the team order from the game's teamPlayers map
        final teamIds = game.teamPlayers.keys.toList();
        expect(teamIds.length, 2,
            reason: 'N=4 should produce exactly 2 teams');

        final team1Id = teamIds[0];
        final team2Id = teamIds[1];
        final team1Players = game.teamPlayers[team1Id]!;
        final team2Players = game.teamPlayers[team2Id]!;
        expect(team1Players.length, 2,
            reason: 'Team 1 should have 2 players');
        expect(team2Players.length, 2,
            reason: 'Team 2 should have 2 players');

        // Record shot order: 4 throws (one per player on hole 1)
        final shotOrder = <String>[];

        for (int i = 0; i < 4; i++) {
          // Active player before this throw
          final activeId = provider.currentPlayerId;
          expect(activeId, isNotNull,
              reason: 'Should have an active player for turn $i');
          shotOrder.add(activeId!);

          // Complete this player's turn (miss = splash, no takeout modal issue)
          await throwMissViaMock(tester);
          await throwMissViaMock(tester);
          await throwMissViaMock(tester);
          await clickDartsRemoved(tester);
          await tester.pump(const Duration(milliseconds: 300));
          await tester.pump();
        }

        // Verify order: team 1 fully before team 2
        expect(shotOrder.length, 4,
            reason: 'Should have recorded 4 shots (one per player)');
        expect(shotOrder[0], team1Players[0],
            reason: 'First shot should be team 1, player 1');
        expect(shotOrder[1], team1Players[1],
            reason: 'Second shot should be team 1, player 2');
        expect(shotOrder[2], team2Players[0],
            reason: 'Third shot should be team 2, player 1');
        expect(shotOrder[3], team2Players[1],
            reason: 'Fourth shot should be team 2, player 2');
      },
    );
  });
}
