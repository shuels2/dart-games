import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Gameplay: knockoff resets opponent to zero when scores match',
      (tester) async {
    await UITestHelpers.resetServerState();
    // Use target=500 so we have room to maneuver
    await setupAndStartGame(
      tester,
      config,
      targetScore: 500,
      playerNames: ['Player A', 'Player B'],
    );

    final p1Id =
        ProviderHelpers.getGladiatorArenaCurrentPlayerId(tester)!;

    // P1 throws S20 x3 = 60
    await throwDartViaMock(tester, 20);
    await throwDartViaMock(tester, 20);
    await throwDartViaMock(tester, 20);
    await clickDartsRemoved(tester);

    final p2Id =
        ProviderHelpers.getGladiatorArenaCurrentPlayerId(tester)!;

    // P2 throws S20 x3 = 60 (matches P1's score)
    await throwDartViaMock(tester, 20);
    await throwDartViaMock(tester, 20);
    await throwDartViaMock(tester, 20);
    await clickDartsRemoved(tester);

    // P1 should have been knocked off to 0 (P2's score matched P1's score at 60)
    final p1Score =
        ProviderHelpers.getGladiatorArenaPlayerScore(tester, p1Id);
    expect(p1Score, 0,
        reason: 'P1 should be knocked off to 0 when P2 matches their score');

    // P2 should still have 60
    final p2Score =
        ProviderHelpers.getGladiatorArenaPlayerScore(tester, p2Id);
    expect(p2Score, 60,
        reason: 'P2 should retain their score of 60');
  });
}
