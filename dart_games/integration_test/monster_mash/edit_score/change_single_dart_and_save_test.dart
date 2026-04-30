import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/edit_score_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 2: Change single dart and save - 3 misses -> edit dart 1 to opponent target -> save -> opponent health -1', (WidgetTester tester) async {
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

    // Opponent health before
    final healthBefore = ProviderHelpers.getMonsterMashPlayerHealth(tester, opponentId);
    expect(healthBefore, 20);

    // Throw 3 misses
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);

    // Open edit score dialog
    await EditScoreHelpers.openEditScore(tester, config);

    // Change dart 1 to opponent's target (single)
    await EditScoreHelpers.setDart1(tester, 'S$opponentTarget');

    // Save
    await EditScoreHelpers.updateScore(tester);

    // Verify opponent health decreased by 1
    final healthAfter = ProviderHelpers.getMonsterMashPlayerHealth(tester, opponentId);
    expect(healthAfter, 19); // 20 - 1 = 19
  });
}
