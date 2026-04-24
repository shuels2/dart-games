import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/settings_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 16: Speed play - winner by health differential - Player 1 attacks, player 2 misses -> winner by health', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    await SettingsHelpers.setMonsterMashHealthMax(tester, 20);
    await SettingsHelpers.toggleMonsterMashSpeedPlay(tester);
    await SettingsHelpers.setMonsterMashRoundLimit(tester, 3);

    await UITestHelpers.addPlayer(tester, 'Attacker', config);
    await UITestHelpers.addPlayer(tester, 'Passive', config);

    await UITestHelpers.startGame(tester, config);

    final attacker = ProviderHelpers.findPlayerByName(tester, 'Attacker')!;
    final passive = ProviderHelpers.findPlayerByName(tester, 'Passive')!;
    final currentPlayerId = ProviderHelpers.getMonsterMashCurrentPlayerId(tester)!;
    final opponentId = currentPlayerId == attacker.id ? passive.id : attacker.id;
    final opponentTarget = ProviderHelpers.getMonsterMashPlayerTarget(tester, opponentId)!;

    // Play 3 rounds - player 1 attacks, player 2 misses
    for (int round = 0; round < 3; round++) {
      // Player 1: attack opponent
      await throwDartViaMock(tester, opponentTarget, multiplier: 'single');
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await clickDartsRemoved(tester);

      // Player 2: miss everything
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await clickDartsRemoved(tester);
    }

    // Game should be over
    expect(ProviderHelpers.monsterMashHasWinner(tester), isTrue);

    // Winner should be the player with higher health (the attacker)
    final selectedPlayers = ProviderHelpers.getSelectedPlayers(tester);
    final winners = ProviderHelpers.getMonsterMashWinners(tester, selectedPlayers);
    expect(winners.length, 1);
    expect(winners.first.id, currentPlayerId); // The attacker who dealt damage
  });
}
