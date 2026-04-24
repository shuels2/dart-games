import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/settings_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 14: Hit eliminated opponent number - no effect - Eliminate p2, throw at p2 target -> damageDealt=0', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    await SettingsHelpers.setMonsterMashHealthMax(tester, 10);

    await UITestHelpers.addPlayer(tester, 'Player A', config);
    await UITestHelpers.addPlayer(tester, 'Player B', config);
    await UITestHelpers.addPlayer(tester, 'Player C', config);

    await UITestHelpers.startGame(tester, config);

    final playerB = ProviderHelpers.findPlayerByName(tester, 'Player B')!;
    final playerBTarget = ProviderHelpers.getMonsterMashPlayerTarget(tester, playerB.id)!;

    // Player 1 attacks Player B to reduce to 1 HP
    await throwDartViaMock(tester, playerBTarget, multiplier: 'triple');
    await throwDartViaMock(tester, playerBTarget, multiplier: 'triple');
    await throwDartViaMock(tester, playerBTarget, multiplier: 'triple');
    await clickDartsRemoved(tester);

    // Player B (1 HP) misses
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await clickDartsRemoved(tester);

    // Player C misses
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await clickDartsRemoved(tester);

    // Player 1 finishes off Player B
    await throwDartViaMock(tester, playerBTarget, multiplier: 'single');
    expect(ProviderHelpers.isMonsterMashPlayerEliminated(tester, playerB.id), isTrue);

    // Now throw at Player B's (eliminated) target
    await throwDartViaMock(tester, playerBTarget, multiplier: 'single');

    // Verify no damage dealt
    final currentPlayerId = ProviderHelpers.getMonsterMashCurrentPlayerId(tester)!;
    final damageAmounts = ProviderHelpers.getMonsterMashDartThrowDamageDealt(tester, currentPlayerId);
    expect(damageAmounts.last, 0);
  });
}
