import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

/// Per-dart win evaluation: if the round-winning flag is planted on dart 1
/// of the turn, the round must end IMMEDIATELY without requiring darts 2/3.
/// Regression guard for the per-dart-eval pattern shared across every game.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Gameplay: Bo1 — pre-claim row 0 cells [0,0] and [0,1] for P1, '
      'then dart 1 at cell [0,2] completes 3-in-a-row and ends the match',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config,
        difficulty: 'Easy',
        bestOf: '1',
        playerNames: ['Player A', 'Player B']);

    final provider = ProviderHelpers.getPiratesGridProvider(tester);
    final p1Id = provider.currentGame!.playerIds[0];

    // Seed the grid: P1 already owns row 0 cells [0,0] and [0,1].
    ProviderHelpers.setPiratesGridGameState(tester, claimedBy: [
      [p1Id, p1Id, null],
      [null, null, null],
      [null, null, null],
    ]);

    // P1 throws ONE dart at cell [0,2]'s target → row 0 complete → WIN.
    final t02 = ProviderHelpers.getPiratesGridCellTargetNumber(tester, 0, 2);
    await throwDartViaMock(tester, t02);

    expect(ProviderHelpers.piratesGridHasWinner(tester), isTrue,
        reason: 'Winning flag on dart 1 should end the round immediately');
    expect(ProviderHelpers.getPiratesGridMatchWinnerId(tester), p1Id,
        reason: 'P1 should be match winner on dart 1 of the turn');

    await clickDartsRemoved(tester);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    await tester.pump();

    expect(config.getPlayAgainButton(), findsOneWidget,
        reason: 'Should navigate to results after dart-1 match win');
  });
}
