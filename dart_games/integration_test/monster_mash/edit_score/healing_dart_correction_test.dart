import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/edit_score_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 5: Healing dart correction - Miss -> edit to own target -> save -> health restored by heal amount', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    await UITestHelpers.addPlayer(tester, 'Player A', config);
    await UITestHelpers.addPlayer(tester, 'Player B', config);

    await UITestHelpers.startGame(tester, config);

    final currentPlayerId = ProviderHelpers.getMonsterMashCurrentPlayerId(tester)!;
    final playerTarget = ProviderHelpers.getMonsterMashPlayerTarget(tester, currentPlayerId)!;

    // First, reduce health: skip turn, let opponent attack
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await clickDartsRemoved(tester);

    // Opponent attacks to reduce health
    await throwDartViaMock(tester, playerTarget, multiplier: 'triple'); // -3 HP
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await clickDartsRemoved(tester);

    // Back to our turn, health should be 17
    final healthBefore = ProviderHelpers.getMonsterMashPlayerHealth(tester, currentPlayerId);
    expect(healthBefore, 17);

    // Throw 3 misses
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);

    // Open edit score and change dart 1 to own target (heal)
    await EditScoreHelpers.openEditScore(tester, config);
    await EditScoreHelpers.setDart1(tester, 'S$playerTarget');
    await EditScoreHelpers.updateScore(tester);

    // Verify health increased by 1
    final healthAfter = ProviderHelpers.getMonsterMashPlayerHealth(tester, currentPlayerId);
    expect(healthAfter, 18); // 17 + 1 = 18
  });
}
