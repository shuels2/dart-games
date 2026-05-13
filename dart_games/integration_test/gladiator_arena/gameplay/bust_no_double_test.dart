import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Gameplay: reaching target without double is bust (Double Finish ON)',
      (tester) async {
    await UITestHelpers.resetServerState();
    // Target=100, DF ON. We'll get to 80 then try to finish with S20 (not double)
    await setupAndStartGame(
      tester,
      config,
      targetScore: 100,
      doubleFinishEnabled: true,
      playerNames: ['Player A', 'Player B'],
    );

    final p1Id =
        ProviderHelpers.getGladiatorArenaCurrentPlayerId(tester)!;

    // Get to score 80: 4 x S20 across 2 turns
    // Turn 1: S20 + S20 + S20 = 60
    await throwDartViaMock(tester, 20);
    await throwDartViaMock(tester, 20);
    await throwDartViaMock(tester, 20);
    await clickDartsRemoved(tester);

    await completeTurnWithMisses(tester); // P2 turn

    // Turn 2: S20 = 80
    await throwDartViaMock(tester, 20);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await clickDartsRemoved(tester);

    await completeTurnWithMisses(tester); // P2 turn

    // P1 at 80. Try to finish with S20 (target hit but NOT a double = BUST)
    final preScore =
        ProviderHelpers.getGladiatorArenaPlayerScore(tester, p1Id);
    expect(preScore, 80);

    await throwDartViaMock(tester, 20); // S20 = 100, NOT a double
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await clickDartsRemoved(tester);

    // Score should revert to 80 (bust: hit target but not on a double)
    final postScore =
        ProviderHelpers.getGladiatorArenaPlayerScore(tester, p1Id);
    expect(postScore, 80,
        reason:
            'Score should revert when reaching target without a double (DF ON)');
    expect(ProviderHelpers.gladiatorArenaHasWinner(tester), isFalse);
  });
}
