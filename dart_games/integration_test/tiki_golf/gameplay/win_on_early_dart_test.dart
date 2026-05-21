import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/pump_sequences.dart';
import '_helpers.dart';

/// Per-dart win evaluation (MANDATORY): when the last player completes their
/// final hole (hole 9) by hitting the target on dart 1, the game must end
/// IMMEDIATELY and navigate to the results screen.
///
/// Strategy: 2 players, 9 holes. Drive through holes 1-8 for both players
/// (all birdies). On hole 9, complete Player A first. Then Player B hits
/// the target on dart 1 of hole 9 → game ends, results screen reached.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Gameplay: hitting target on dart 1 of last hole ends game immediately',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, maxStrokes: 3,
        playerNames: ['Alice', 'Bob']);

    final provider = ProviderHelpers.getTikiGolfProvider(tester);

    // Drive through holes 1-8 for both players (all birdies)
    int safety = 0;
    while (!provider.hasWinner &&
        provider.currentGame!.currentHole < 9 &&
        safety < 200) {
      safety++;
      await throwTargetDart(tester);
      await clickDartsRemoved(tester);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump();
    }

    // We should now be on hole 9 with both players having 8 holes scored
    expect(provider.currentGame!.currentHole, 9,
        reason: 'Should be on hole 9 after driving through holes 1-8');
    expect(provider.hasWinner, isFalse,
        reason: 'Should not have winner yet on hole 9');

    // Complete Player 1 (Alice) on hole 9 with a birdie
    await throwTargetDart(tester);
    await clickDartsRemoved(tester);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    // Now it is Player 2 (Bob) on hole 9 — throw target on dart 1 only
    final hole9Target = getCurrentHoleTarget(tester);
    await throwDartViaMock(tester, hole9Target);

    // After dart 1 hits target, turn ends (currentTurnEnded=true).
    // hasWinner is not yet set (Tiki Golf win is determined after all players
    // complete all 9 holes via confirmTurnEnd → _endGame). No more darts
    // needed — dart 2 and 3 are NOT thrown (per-dart turn-end works).
    expect(provider.shouldPromptTakeout, isTrue,
        reason:
            'shouldPromptTakeout should be true after hitting target on dart 1 '
            '— proves the turn ended immediately without throwing darts 2+');

    // Navigate through takeout to results screen
    await clickDartsRemoved(tester);
    await tester.pump(const Duration(seconds: 4));
    await tester.pump();
    await PumpSequences.fullRebuild(tester);

    // Results screen should be showing
    expect(config.getPlayAgainButton(), findsOneWidget,
        reason: 'Results screen should appear after dart-1 win on hole 9');
  });
}
