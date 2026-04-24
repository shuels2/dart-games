import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/edit_score_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 3: Change all three darts - 3 misses -> edit all darts to opponent S/D/T -> save -> opponent health -6', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    await UITestHelpers.addPlayer(tester, 'Player A', config);
    await UITestHelpers.addPlayer(tester, 'Player B', config);

    await UITestHelpers.startGame(tester, config);

    final playerA = ProviderHelpers.findPlayerByName(tester, 'Player A')!;
    final playerB = ProviderHelpers.findPlayerByName(tester, 'Player B')!;
    final currentPlayerId = ProviderHelpers.getMonsterMashCurrentPlayerId(tester)!;
    final opponentId = currentPlayerId == playerA.id ? playerB.id : playerA.id;
    final opponentTarget = ProviderHelpers.getMonsterMashPlayerTarget(tester, opponentId)!;

    // Throw 3 misses
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);

    // Open edit score dialog
    await EditScoreHelpers.openEditScore(tester, config);

    // Change all 3 darts to opponent's target: S, D, T
    await EditScoreHelpers.setAllDarts(
      tester,
      'S$opponentTarget',
      'D$opponentTarget',
      'T$opponentTarget',
    );

    // Save
    await EditScoreHelpers.updateScore(tester);

    // Verify opponent health decreased by 6 (1+2+3)
    final healthAfter = ProviderHelpers.getMonsterMashPlayerHealth(tester, opponentId);
    expect(healthAfter, 14); // 20 - 6 = 14
  });
}
