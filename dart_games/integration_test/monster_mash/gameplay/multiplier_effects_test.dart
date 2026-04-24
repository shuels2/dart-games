import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 3: Multiplier effects (S/D/T) - Three darts at opponent: single(1), double(2), triple(3) -> total 6 damage', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    await UITestHelpers.addPlayer(tester, 'Player A', config);
    await UITestHelpers.addPlayer(tester, 'Player B', config);

    await UITestHelpers.startGame(tester, config);

    final currentPlayerId = ProviderHelpers.getMonsterMashCurrentPlayerId(tester)!;
    final playerA = ProviderHelpers.findPlayerByName(tester, 'Player A')!;
    final playerB = ProviderHelpers.findPlayerByName(tester, 'Player B')!;
    final opponentId = currentPlayerId == playerA.id ? playerB.id : playerA.id;
    final opponentTarget = ProviderHelpers.getMonsterMashPlayerTarget(tester, opponentId)!;

    // Throw single (1 dmg)
    await throwDartViaMock(tester, opponentTarget, multiplier: 'single');
    // Throw double (2 dmg)
    await throwDartViaMock(tester, opponentTarget, multiplier: 'double');
    // Throw triple (3 dmg)
    await throwDartViaMock(tester, opponentTarget, multiplier: 'triple');

    // Verify total damage: 1 + 2 + 3 = 6
    final opponentHealth = ProviderHelpers.getMonsterMashPlayerHealth(tester, opponentId);
    expect(opponentHealth, 14); // 20 - 6 = 14

    // Verify individual dart damage
    final damageDealt = ProviderHelpers.getMonsterMashDartThrowDamageDealt(tester, currentPlayerId);
    expect(damageDealt.length, 3);
    expect(damageDealt[0], 1); // single
    expect(damageDealt[1], 2); // double
    expect(damageDealt[2], 3); // triple
  });
}
