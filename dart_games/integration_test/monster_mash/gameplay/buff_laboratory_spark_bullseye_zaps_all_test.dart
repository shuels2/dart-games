import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/models/monster_mash_game.dart';
import 'package:dart_games/constants/test_keys.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/settings_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 20: Buff - Laboratory Spark bullseye zaps all opponents - Set activeBuff = laboratorySpark, throw bullseye -> all opponents lose 10 HP', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    await SettingsHelpers.setMonsterMashHealthMax(tester, 30);
    await SettingsHelpers.toggleMonsterMashBonusBuffs(tester);

    await UITestHelpers.addPlayer(tester, 'Player A', config);
    await UITestHelpers.addPlayer(tester, 'Player B', config);
    await UITestHelpers.addPlayer(tester, 'Player C', config);

    await UITestHelpers.startGame(tester, config);

    final playerA = ProviderHelpers.findPlayerByName(tester, 'Player A')!;
    final playerB = ProviderHelpers.findPlayerByName(tester, 'Player B')!;
    final playerC = ProviderHelpers.findPlayerByName(tester, 'Player C')!;
    final currentPlayerId = ProviderHelpers.getMonsterMashCurrentPlayerId(tester)!;

    // Set Laboratory Spark buff
    await setActiveBuff(tester, BonusBuff.laboratorySpark);

    // Verify UI shows buff indicator via keys
    expect(find.byKey(MonsterMashGameKeys.buffDamageShield), findsOneWidget);
    expect(find.byKey(MonsterMashGameKeys.buffLabel), findsOneWidget);
    expect(find.textContaining('Hit the bullseye and ALL opponents lose 10 HP!'), findsOneWidget);

    // Record opponent health before
    final opponents = [playerA, playerB, playerC].where((p) => p.id != currentPlayerId).toList();
    final healthBefore = <String, int>{};
    for (final opponent in opponents) {
      healthBefore[opponent.id] = ProviderHelpers.getMonsterMashPlayerHealth(tester, opponent.id);
      expect(healthBefore[opponent.id], 30);
    }

    // Throw bullseye
    await throwBullseyeViaMock(tester);

    // Verify ALL opponents lost 10 HP
    for (final opponent in opponents) {
      final healthAfter = ProviderHelpers.getMonsterMashPlayerHealth(tester, opponent.id);
      expect(healthAfter, 20, reason: 'Opponent ${opponent.name} should have lost 10 HP');
    }
  });
}
