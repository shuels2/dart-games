import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 1: Healing - hit own number - Throw single at own target -> healAmount=1, health increases', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    await UITestHelpers.addPlayer(tester, 'Player A', config);
    await UITestHelpers.addPlayer(tester, 'Player B', config);

    // Start game with health=20
    await UITestHelpers.startGame(tester, config);

    final currentPlayerId = ProviderHelpers.getMonsterMashCurrentPlayerId(tester)!;
    final playerTarget = ProviderHelpers.getMonsterMashPlayerTarget(tester, currentPlayerId)!;

    // First reduce health via opponent attack
    // Find opponent's target to hit
    final playerA = ProviderHelpers.findPlayerByName(tester, 'Player A')!;
    final playerB = ProviderHelpers.findPlayerByName(tester, 'Player B')!;
    final opponentId = currentPlayerId == playerA.id ? playerB.id : playerA.id;
    final opponentTarget = ProviderHelpers.getMonsterMashPlayerTarget(tester, opponentId)!;

    // Hit opponent's target to deal damage (just to verify attack works, but we're testing heal)
    // Instead, let's reduce health by hitting the opponent target first
    // Actually, let's test healing directly - throw misses to use darts, advance turn
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await clickDartsRemoved(tester);

    // Player B's turn - hit Player A's target to reduce health
    final newCurrentPlayerId = ProviderHelpers.getMonsterMashCurrentPlayerId(tester)!;
    final firstPlayerTarget = currentPlayerId == playerA.id
        ? ProviderHelpers.getMonsterMashPlayerTarget(tester, playerA.id)!
        : ProviderHelpers.getMonsterMashPlayerTarget(tester, playerB.id)!;

    // Attack first player
    await throwDartViaMock(tester, firstPlayerTarget, multiplier: 'single');
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await clickDartsRemoved(tester);

    // Back to first player - health should be 19
    final healthBefore = ProviderHelpers.getMonsterMashPlayerHealth(tester, currentPlayerId);
    expect(healthBefore, 19);

    // Hit own target to heal
    await throwDartViaMock(tester, playerTarget, multiplier: 'single');

    // Verify heal amount
    final healAmounts = ProviderHelpers.getMonsterMashDartThrowHealAmount(tester, currentPlayerId);
    expect(healAmounts.isNotEmpty, isTrue);
    expect(healAmounts.last, 1);

    // Verify health increased
    final healthAfter = ProviderHelpers.getMonsterMashPlayerHealth(tester, currentPlayerId);
    expect(healthAfter, 20); // 19 + 1 = 20
  });
}
