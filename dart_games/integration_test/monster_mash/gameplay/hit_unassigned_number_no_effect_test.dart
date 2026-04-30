import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 13: Hit unassigned number - no effect - Throw at number not assigned to any player -> no heal, no damage', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    await UITestHelpers.addPlayer(tester, 'Player A', config);
    await UITestHelpers.addPlayer(tester, 'Player B', config);

    await UITestHelpers.startGame(tester, config);

    final playerA = ProviderHelpers.findPlayerByName(tester, 'Player A')!;
    final playerB = ProviderHelpers.findPlayerByName(tester, 'Player B')!;
    final currentPlayerId = ProviderHelpers.getMonsterMashCurrentPlayerId(tester)!;

    final targetA = ProviderHelpers.getMonsterMashPlayerTarget(tester, playerA.id)!;
    final targetB = ProviderHelpers.getMonsterMashPlayerTarget(tester, playerB.id)!;

    // Find an unassigned number (not targetA or targetB)
    int unassignedNumber = 1;
    while (unassignedNumber == targetA || unassignedNumber == targetB) {
      unassignedNumber++;
    }

    // Throw at unassigned number
    await throwDartViaMock(tester, unassignedNumber, multiplier: 'single');

    // Verify no effect
    final healAmounts = ProviderHelpers.getMonsterMashDartThrowHealAmount(tester, currentPlayerId);
    final damageAmounts = ProviderHelpers.getMonsterMashDartThrowDamageDealt(tester, currentPlayerId);
    final targetPlayerIds = ProviderHelpers.getMonsterMashDartThrowTargetPlayerId(tester, currentPlayerId);

    expect(healAmounts.last, 0);
    expect(damageAmounts.last, 0);
    expect(targetPlayerIds.last, isNull);
  });
}
