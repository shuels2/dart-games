import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 2: Attack - hit opponent number - Throw single at opponent target -> opponent health -1, damageDealt=1, targetPlayerId set', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    await UITestHelpers.addPlayer(tester, 'Attacker', config);
    await UITestHelpers.addPlayer(tester, 'Defender', config);

    await UITestHelpers.startGame(tester, config);

    final currentPlayerId = ProviderHelpers.getMonsterMashCurrentPlayerId(tester)!;
    final attacker = ProviderHelpers.findPlayerByName(tester, 'Attacker')!;
    final defender = ProviderHelpers.findPlayerByName(tester, 'Defender')!;
    final opponentId = currentPlayerId == attacker.id ? defender.id : attacker.id;
    final opponentTarget = ProviderHelpers.getMonsterMashPlayerTarget(tester, opponentId)!;

    // Record health before attack
    final healthBefore = ProviderHelpers.getMonsterMashPlayerHealth(tester, opponentId);
    expect(healthBefore, 20);

    // Attack opponent
    await throwDartViaMock(tester, opponentTarget, multiplier: 'single');

    // Verify damage
    final damageDealt = ProviderHelpers.getMonsterMashDartThrowDamageDealt(tester, currentPlayerId);
    expect(damageDealt.isNotEmpty, isTrue);
    expect(damageDealt.last, 1);

    // Verify target player ID
    final targetPlayerIds = ProviderHelpers.getMonsterMashDartThrowTargetPlayerId(tester, currentPlayerId);
    expect(targetPlayerIds.isNotEmpty, isTrue);
    expect(targetPlayerIds.last, opponentId);

    // Verify opponent health decreased
    final healthAfter = ProviderHelpers.getMonsterMashPlayerHealth(tester, opponentId);
    expect(healthAfter, 19);
  });
}
