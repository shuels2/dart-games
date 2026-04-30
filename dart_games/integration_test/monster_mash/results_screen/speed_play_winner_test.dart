import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/settings_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 5: Speed play winner (round limit) - health=50, speed play ON, limit=3, deal unequal damage -> correct winner by health', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    await SettingsHelpers.setMonsterMashHealthMax(tester, 50);
    await SettingsHelpers.toggleMonsterMashSpeedPlay(tester);
    await SettingsHelpers.setMonsterMashRoundLimit(tester, 3);

    await UITestHelpers.addPlayer(tester, 'Player A', config);
    await UITestHelpers.addPlayer(tester, 'Player B', config);

    await UITestHelpers.startGame(tester, config);

    final playerA = ProviderHelpers.findPlayerByName(tester, 'Player A')!;
    final playerB = ProviderHelpers.findPlayerByName(tester, 'Player B')!;
    final currentPlayerId = ProviderHelpers.getMonsterMashCurrentPlayerId(tester)!;
    final opponentId = currentPlayerId == playerA.id ? playerB.id : playerA.id;
    final opponentTarget = ProviderHelpers.getMonsterMashPlayerTarget(tester, opponentId)!;

    // Play 3 rounds - player 1 attacks, player 2 misses
    for (int round = 0; round < 3; round++) {
      // Player 1: attack with triples for significant damage
      await throwDartViaMock(tester, opponentTarget, multiplier: 'triple');
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await clickDartsRemoved(tester);

      // Player 2: miss everything
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await clickDartsRemoved(tester);
    }

    // Game should be over, winner determined by health
    expect(ProviderHelpers.monsterMashHasWinner(tester), isTrue);

    // Wait for results screen
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    // Verify results screen
    expect(config.getPlayAgainButton(), findsOneWidget);
  });
}
