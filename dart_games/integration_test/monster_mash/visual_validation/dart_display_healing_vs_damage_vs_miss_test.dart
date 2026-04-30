import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 3: Dart display - healing vs damage vs miss - Provider tracks heal amount, damage dealt, and target per dart', (WidgetTester tester) async {
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
    final ownTarget = ProviderHelpers.getMonsterMashPlayerTarget(tester, currentPlayerId)!;

    // First reduce health so heal is visible
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await clickDartsRemoved(tester);

    // Opponent attacks to reduce health
    await throwDartViaMock(tester, ownTarget, multiplier: 'triple'); // -3
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await clickDartsRemoved(tester);

    // Now test: Dart 1 = heal (own target), Dart 2 = damage (opponent target), Dart 3 = miss
    await throwDartViaMock(tester, ownTarget, multiplier: 'single'); // heal +1
    await throwDartViaMock(tester, opponentTarget, multiplier: 'single'); // damage 1
    await throwMissViaMock(tester); // miss

    // Verify dart tracking
    final healAmounts = ProviderHelpers.getMonsterMashDartThrowHealAmount(tester, currentPlayerId);
    final damageAmounts = ProviderHelpers.getMonsterMashDartThrowDamageDealt(tester, currentPlayerId);
    final targetIds = ProviderHelpers.getMonsterMashDartThrowTargetPlayerId(tester, currentPlayerId);

    expect(healAmounts.length, 3);
    expect(healAmounts[0], 1); // heal dart
    expect(healAmounts[1], 0); // damage dart (no heal)
    expect(healAmounts[2], 0); // miss (no heal)

    expect(damageAmounts.length, 3);
    expect(damageAmounts[0], 0); // heal dart (no damage)
    expect(damageAmounts[1], 1); // damage dart
    expect(damageAmounts[2], 0); // miss (no damage)

    expect(targetIds.length, 3);
    expect(targetIds[0], isNull); // heal dart (no target)
    expect(targetIds[1], opponentId); // damage dart
    expect(targetIds[2], isNull); // miss (no target)
  });
}
