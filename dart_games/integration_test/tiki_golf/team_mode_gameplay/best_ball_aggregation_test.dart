// integration_test/tiki_golf/team_mode_gameplay/best_ball_aggregation_test.dart
//
// Team A {1,3,2}: team hole score = 1 (best-ball = MIN of individual scores).
//
// N=4, 2 teams of 2. Team 1: player 1 birdies (1), player 2 bogeys (3).
// Team 2: player 1 pars (2), player 2 splashes (4).
// After hole 1: team 1 best-ball = 1, team 2 best-ball = 2.
//
// Section 12B File 7 — Team mode gameplay test 3 (best_ball_aggregation)
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Team Mode Gameplay: best-ball aggregation — team hole score = MIN of player scores',
      (WidgetTester tester) async {
    await UITestHelpers.runWithFailureScreenshot(
      tester,
      'tiki_golf_team_mode_gameplay_best_ball',
      () async {
        await UITestHelpers.resetServerState();
        // N=4 → 2 teams of 2
        await setupAndStartTeamGame(
            tester,
            playerNames: ['A1', 'A2', 'B1', 'B2'],
            maxStrokes: 3);

        final provider = ProviderHelpers.getTikiGolfProvider(tester);
        final game = provider.currentGame!;

        final teamIds = game.teamPlayers.keys.toList();
        final team1Id = teamIds[0];
        final team2Id = teamIds[1];
        final team1Players = game.teamPlayers[team1Id]!;
        final team2Players = game.teamPlayers[team2Id]!;

        // ── Team 1, Player 1: Birdie (1 stroke) ─────────────────────────────
        // Throw target on dart 1
        final target = getCurrentHoleTarget(tester);
        await throwDartViaMock(tester, target);
        await clickDartsRemoved(tester);
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump();

        // ── Team 1, Player 2: Bogey (3 strokes) ─────────────────────────────
        // Miss dart 1, miss dart 2, hit dart 3
        await throwMissViaMock(tester);
        await throwMissViaMock(tester);
        final target2 = getCurrentHoleTarget(tester);
        await throwDartViaMock(tester, target2);
        await clickDartsRemoved(tester);
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump();

        // ── Team 2, Player 1: Par (2 strokes) ───────────────────────────────
        await throwMissViaMock(tester);
        final target3 = getCurrentHoleTarget(tester);
        await throwDartViaMock(tester, target3);
        await clickDartsRemoved(tester);
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump();

        // ── Team 2, Player 2: Splash (3 misses = 4 strokes) ─────────────────
        await throwMissViaMock(tester);
        await throwMissViaMock(tester);
        await throwMissViaMock(tester);
        await clickDartsRemoved(tester);
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump();

        // ── Verify individual scores ──────────────────────────────────────────
        final t1p1Score = ProviderHelpers.getTikiGolfPlayerHoleScore(
            tester, team1Players[0], 1);
        final t1p2Score = ProviderHelpers.getTikiGolfPlayerHoleScore(
            tester, team1Players[1], 1);
        final t2p1Score = ProviderHelpers.getTikiGolfPlayerHoleScore(
            tester, team2Players[0], 1);
        final t2p2Score = ProviderHelpers.getTikiGolfPlayerHoleScore(
            tester, team2Players[1], 1);

        expect(t1p1Score, 1,
            reason: 'Team 1 P1 should have scored 1 (birdie)');
        expect(t1p2Score, 3,
            reason: 'Team 1 P2 should have scored 3 (bogey)');
        expect(t2p1Score, 2,
            reason: 'Team 2 P1 should have scored 2 (par)');
        expect(t2p2Score, 4,
            reason: 'Team 2 P2 should have scored 4 (splash)');

        // ── Verify best-ball aggregation ──────────────────────────────────────
        final team1BestBall = game.bestBallForTeam(team1Id, 0); // hole index 0
        final team2BestBall = game.bestBallForTeam(team2Id, 0);

        expect(team1BestBall, 1,
            reason:
                'Team 1 best-ball for hole 1 should be 1 (min of 1 and 3) — '
                'proves best-ball aggregation uses MIN of player scores');
        expect(team2BestBall, 2,
            reason:
                'Team 2 best-ball for hole 1 should be 2 (min of 2 and 4)');
      },
    );
  });
}
