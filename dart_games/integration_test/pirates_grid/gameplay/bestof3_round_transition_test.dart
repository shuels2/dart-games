import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/element_finders.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Gameplay: Bo3 — P1 wins round 1, grid resets, round 2 starts',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config,
        difficulty: 'Easy',
        bestOf: '3',
        playerNames: ['Player A', 'Player B']);

    final provider = ProviderHelpers.getPiratesGridProvider(tester);
    final p1Id = provider.currentGame!.playerIds[0];

    // Verify round tracker is visible (Bo3)
    expect(ElementFinders.getPiratesGridRoundTracker(), findsOneWidget,
        reason: 'Round tracker should be visible for Bo3');

    // Round 1: P1 throws row 0 cells → wins row 0
    final t00 = ProviderHelpers.getPiratesGridCellTargetNumber(tester, 0, 0);
    final t01 = ProviderHelpers.getPiratesGridCellTargetNumber(tester, 0, 1);
    final t02 = ProviderHelpers.getPiratesGridCellTargetNumber(tester, 0, 2);
    await throwDartViaMock(tester, t00);
    await throwDartViaMock(tester, t01);
    await throwDartViaMock(tester, t02);

    expect(provider.currentGame!.roundsWon[p1Id], 1,
        reason: 'P1 should have 1 round win');
    expect(provider.currentGame!.matchWinnerId, isNull,
        reason: 'Match should not be over yet (need 2 for Bo3)');

    // Click DARTS REMOVED → round transition
    await clickDartsRemoved(tester);
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    await tester.pump();

    // Round 2 should have started: currentRound = 2
    expect(provider.currentGame!.currentRound, 2,
        reason: 'Should now be in round 2');

    // Grid should be empty (reset)
    for (int r = 0; r < 3; r++) {
      for (int c = 0; c < 3; c++) {
        expect(ProviderHelpers.getPiratesGridCellClaimedBy(tester, r, c), isNull,
            reason: 'Grid cell [$r,$c] should be empty at start of round 2');
      }
    }

    // Game screen should still be active
    expect(config.getSkipTurnButton(), findsOneWidget,
        reason: 'Game screen should be active in round 2');
  });
}
