// integration_test/tiki_golf/team_mode_gameplay/team_mulligan_per_player_test.dart
//
// Team mode: P1 uses mulligan → P2's mulligan still available (per-player resource).
//
// Verifies mulligan is independently tracked per player, not per team.
// P1 splashes and uses their mulligan; P2's mulligan counter is still 0 (unused).
//
// Section 12B File 7 — Team mode gameplay test 9 (team_mulligan_per_player)
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/pump_sequences.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Team Mode Gameplay: mulligan is per-player — P1 uses theirs, P2 still has theirs',
      (WidgetTester tester) async {
    await UITestHelpers.runWithFailureScreenshot(
      tester,
      'tiki_golf_team_mode_gameplay_mulligan_per_player',
      () async {
        await UITestHelpers.resetServerState();
        // N=4, Team+Random, Mulligan ON
        await setupAndStartTeamGame(
          tester,
          playerNames: ['A1', 'A2', 'B1', 'B2'],
          mulliganEnabled: true,
        );

        final provider = ProviderHelpers.getTikiGolfProvider(tester);
        final game = provider.currentGame!;
        final team1Id = game.teamPlayers.keys.first;
        final team1Players = game.teamPlayers[team1Id]!;
        final p1Id = team1Players[0];
        final p2Id = team1Players[1];

        // Verify both players have mulligan available at game start
        expect(ProviderHelpers.isTikiGolfMulliganAvailable(tester, p1Id),
            isTrue, reason: 'P1 should have mulligan at game start');
        expect(ProviderHelpers.isTikiGolfMulliganAvailable(tester, p2Id),
            isTrue, reason: 'P2 should have mulligan at game start');

        // P1's turn: throw 3 misses → Splash → mulligan modal appears
        await throwMissViaMock(tester);
        await throwMissViaMock(tester);
        await throwMissViaMock(tester);
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump();

        // Mulligan modal should appear (USE MULLIGAN button)
        final mulliganBtn = ElementFinders.getTikiGolfUseMulliganButton();
        expect(mulliganBtn, findsOneWidget,
            reason: 'USE MULLIGAN button should appear after P1 splashes');

        // Tap USE MULLIGAN for P1
        await tester.tap(mulliganBtn);
        await tester.pump(const Duration(milliseconds: 1000));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1000));
        await tester.pump();

        // P1's mulligan should now be used (unavailable)
        expect(ProviderHelpers.isTikiGolfMulliganAvailable(tester, p1Id),
            isFalse,
            reason: 'P1\'s mulligan should be used after tapping USE MULLIGAN');

        // P2's mulligan should still be available (per-player resource)
        expect(ProviderHelpers.isTikiGolfMulliganAvailable(tester, p2Id),
            isTrue,
            reason:
                'P2\'s mulligan should still be available — '
                'proves mulligan is tracked per-player, not per-team');
      },
    );
  });
}
