import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 6: Miss does nothing - 3 misses -> no health changes for any player', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    await UITestHelpers.addPlayer(tester, 'Player A', config);
    await UITestHelpers.addPlayer(tester, 'Player B', config);

    await UITestHelpers.startGame(tester, config);

    final playerA = ProviderHelpers.findPlayerByName(tester, 'Player A')!;
    final playerB = ProviderHelpers.findPlayerByName(tester, 'Player B')!;
    final currentPlayerId = ProviderHelpers.getMonsterMashCurrentPlayerId(tester)!;

    // Record initial health for both
    final healthA = ProviderHelpers.getMonsterMashPlayerHealth(tester, playerA.id);
    final healthB = ProviderHelpers.getMonsterMashPlayerHealth(tester, playerB.id);
    expect(healthA, 20);
    expect(healthB, 20);

    // Throw 3 misses
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);

    // Verify no health changes
    expect(ProviderHelpers.getMonsterMashPlayerHealth(tester, playerA.id), 20);
    expect(ProviderHelpers.getMonsterMashPlayerHealth(tester, playerB.id), 20);

    // Verify heal/damage = 0 for all darts
    final healAmounts = ProviderHelpers.getMonsterMashDartThrowHealAmount(tester, currentPlayerId);
    final damageAmounts = ProviderHelpers.getMonsterMashDartThrowDamageDealt(tester, currentPlayerId);
    for (final heal in healAmounts) {
      expect(heal, 0);
    }
    for (final damage in damageAmounts) {
      expect(damage, 0);
    }
  });
}
