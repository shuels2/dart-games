import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Edit Score: changing a dart value updates score', (tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config,
        playerNames: ['Player A', 'Player B']);

    final p1Id =
        ProviderHelpers.getGladiatorArenaCurrentPlayerId(tester)!;

    // Throw 3 darts: Miss, Miss, Miss → total 0 initially.
    // All score boxes show "0".  Edit dart1 from Miss to D8 (16 pts).
    // Button "8" is the only "8" within dart1 section (score box shows "0").
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);

    // Open edit score dialog
    await openEditScore(tester, config);

    // Change dart 1 from Miss to D8 (16 points)
    // No collision: score boxes show "0", "0", "0"; button "8" is unique.
    await setDart1(tester, 'D8');

    // Save
    await updateScore(tester);
    await clickDartsRemoved(tester);

    // Score should now be D8 + Miss + Miss = 16 + 0 + 0 = 16
    final score =
        ProviderHelpers.getGladiatorArenaPlayerScore(tester, p1Id);
    expect(score, 16,
        reason: 'Score should be 16 after changing dart 1 from Miss to D8');
  });
}
