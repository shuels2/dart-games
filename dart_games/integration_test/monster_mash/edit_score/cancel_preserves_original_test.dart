import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/edit_score_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 4: Cancel preserves original - 3 darts at opponent -> edit dart 1 to Miss -> cancel -> original scores preserved', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    await UITestHelpers.addPlayer(tester, 'Player A', config);
    await UITestHelpers.addPlayer(tester, 'Player B', config);

    await UITestHelpers.startGame(tester, config);
    // Extra pump to ensure game state is fully propagated
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    final playerA = ProviderHelpers.findPlayerByName(tester, 'Player A')!;
    final playerB = ProviderHelpers.findPlayerByName(tester, 'Player B')!;
    final currentPlayerId = ProviderHelpers.getMonsterMashCurrentPlayerId(tester)!;
    final opponentId = currentPlayerId == playerA.id ? playerB.id : playerA.id;
    final opponentTarget = ProviderHelpers.getMonsterMashPlayerTarget(tester, opponentId)!;

    // Throw 3 singles at opponent's target (3 damage total)
    await throwDartViaMock(tester, opponentTarget, multiplier: 'single');
    await throwDartViaMock(tester, opponentTarget, multiplier: 'single');
    await throwDartViaMock(tester, opponentTarget, multiplier: 'single');

    // Opponent health should be 17
    final healthAfterThrows = ProviderHelpers.getMonsterMashPlayerHealth(tester, opponentId);
    expect(healthAfterThrows, 17);

    // Open edit score dialog
    await EditScoreHelpers.openEditScore(tester, config);

    // Change dart 1 to Miss
    await EditScoreHelpers.setDart1(tester, 'Miss');

    // Cancel instead of saving
    await EditScoreHelpers.cancelEditScore(tester);

    // Verify original scores preserved (opponent still at 17)
    final healthAfterCancel = ProviderHelpers.getMonsterMashPlayerHealth(tester, opponentId);
    expect(healthAfterCancel, 17);
  });
}
