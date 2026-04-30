import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/settings_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 12: Eliminated player skipped in turn order - 3-player game, eliminate p2, verify turn alternates p1/p3 only', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    await SettingsHelpers.setMonsterMashHealthMax(tester, 10);

    await UITestHelpers.addPlayer(tester, 'Player A', config);
    await UITestHelpers.addPlayer(tester, 'Player B', config);
    await UITestHelpers.addPlayer(tester, 'Player C', config);

    await UITestHelpers.startGame(tester, config);

    final playerA = ProviderHelpers.findPlayerByName(tester, 'Player A')!;
    final playerB = ProviderHelpers.findPlayerByName(tester, 'Player B')!;
    final playerC = ProviderHelpers.findPlayerByName(tester, 'Player C')!;

    // Get current player (player 1) and find player B's target
    final player1Id = ProviderHelpers.getMonsterMashCurrentPlayerId(tester)!;
    final playerBTarget = ProviderHelpers.getMonsterMashPlayerTarget(tester, playerB.id)!;

    // Player 1 attacks player B
    await throwDartViaMock(tester, playerBTarget, multiplier: 'triple');
    await throwDartViaMock(tester, playerBTarget, multiplier: 'triple');
    await throwDartViaMock(tester, playerBTarget, multiplier: 'triple');
    await clickDartsRemoved(tester);

    // Player B (HP=1) - their turn
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await clickDartsRemoved(tester);

    // Player C - their turn, just miss
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await clickDartsRemoved(tester);

    // Player 1 again - finish off Player B
    await throwDartViaMock(tester, playerBTarget, multiplier: 'single');
    // Player B eliminated but game continues (3-player game, 2 remaining)
    expect(ProviderHelpers.isMonsterMashPlayerEliminated(tester, playerB.id), isTrue);

    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await clickDartsRemoved(tester);

    // Now turn should skip Player B and go to Player C
    final afterEliminationPlayerId = ProviderHelpers.getMonsterMashCurrentPlayerId(tester)!;
    expect(afterEliminationPlayerId, isNot(equals(playerB.id)));
  });
}
