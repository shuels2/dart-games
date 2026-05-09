import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/pump_sequences.dart';
import '../../shared/edit_score_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // MANDATORY: edit removes winner and no stats recorded.
  // Setup: P1 has 2 cells in row 0 (programmatically).
  // P1 throws the [0,2] target (wins row 0). Then edits dart 1 → Miss
  // (guaranteed not to complete any row). P1 loses the win condition.
  // Verify hasWinner false, click DARTS REMOVED, game still active, stats=0.
  testWidgets(
      'Edit Score: editing winning dart to non-winning value removes winner',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config,
        playerNames: ['Player A', 'Player B']);

    // Set up near-win state: P1 has row 0 cols 0 and 1
    await setupNearWinState(tester);

    // Throw row 0, col 2 target → P1 wins row 0
    final t02 = ProviderHelpers.getPiratesGridCellTargetNumber(tester, 0, 2);
    await throwDartViaMock(tester, t02);
    // Fill remaining darts with miss
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);

    // At this point hasWinner should be true (round won after hitting [0,2])
    expect(ProviderHelpers.piratesGridHasWinner(tester), isTrue,
        reason: 'P1 should have won row 0 with [0,2] target');

    // Edit dart 1 from the winning throw → Miss (guaranteed not to complete row 0).
    // Darts 2 and 3 were silently dropped by the provider's `!isGameActive`
    // guard once dart 1 set state=finished, so they have no ring/number in the
    // dialog. Save is disabled until every dart has a valid ring — set them
    // both to Miss explicitly so updateScore can submit.
    await openEditScore(tester);
    await EditScoreHelpers.setDart1(tester, 'Miss');
    await EditScoreHelpers.setDart2(tester, 'Miss');
    await EditScoreHelpers.setDart3(tester, 'Miss');
    await updateScore(tester);

    // After edit, P1 no longer has row 0 complete → no winner
    expect(ProviderHelpers.piratesGridHasWinner(tester), isFalse,
        reason: 'P1 should not have a winner after editing winning dart to Miss');

    // Click DARTS REMOVED — game should continue (not navigate to results)
    await clickDartsRemoved(tester);

    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    await tester.pump();
    await PumpSequences.fullRebuild(tester);

    // Game should still be active (on game screen, not results)
    // Verify skip turn button is visible (game screen indicator)
    expect(config.getSkipTurnButton(), findsOneWidget,
        reason: 'Skip turn button should be visible — game is still active');

    // MANDATORY: No stats recorded — both players gamesPlayed=0
    final playerA = ProviderHelpers.findPlayerByName(tester, 'Player A');
    final playerB = ProviderHelpers.findPlayerByName(tester, 'Player B');

    expect(playerA?.gamesPlayed ?? 0, 0,
        reason: 'Player A gamesPlayed should be 0 — game not completed');
    expect(playerA?.gamesWon ?? 0, 0,
        reason: 'Player A gamesWon should be 0');
    expect(playerA?.gameHistory.length ?? 0, 0,
        reason: 'Player A gameHistory should be empty');

    expect(playerB?.gamesPlayed ?? 0, 0,
        reason: 'Player B gamesPlayed should be 0');
    expect(playerB?.gamesWon ?? 0, 0,
        reason: 'Player B gamesWon should be 0');
    expect(playerB?.gameHistory.length ?? 0, 0,
        reason: 'Player B gameHistory should be empty');
  });
}
