import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Gameplay: overshoot causes bust (Double Finish ON)',
      (tester) async {
    await UITestHelpers.resetServerState();
    // Target=100, DF ON
    await setupAndStartGame(
      tester,
      config,
      targetScore: 100,
      doubleFinishEnabled: true,
      playerNames: ['Player A', 'Player B'],
    );

    final p1Id =
        ProviderHelpers.getGladiatorArenaCurrentPlayerId(tester)!;

    // Build up to 80 over multiple turns
    // Turn 1: S20 + S20 + S20 = 60
    await throwDartViaMock(tester, 20);
    await throwDartViaMock(tester, 20);
    await throwDartViaMock(tester, 20);
    await clickDartsRemoved(tester);

    // P2 turn (misses)
    await completeTurnWithMisses(tester);

    // P1 at 60. Turn 2: S20 = 80 total
    await throwDartViaMock(tester, 20);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await clickDartsRemoved(tester);

    // P2 turn (misses)
    await completeTurnWithMisses(tester);

    // P1 at 80. Now throw T20 = 60 which would give 140 > 100 = BUST
    final preBustScore =
        ProviderHelpers.getGladiatorArenaPlayerScore(tester, p1Id);
    expect(preBustScore, 80);

    await throwDartViaMock(tester, 20, multiplier: 'triple'); // 60
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await clickDartsRemoved(tester);

    // Score should revert to 80 (bust)
    final postBustScore =
        ProviderHelpers.getGladiatorArenaPlayerScore(tester, p1Id);
    expect(postBustScore, 80,
        reason: 'Score should revert to pre-bust value when overshooting');
  });
}
