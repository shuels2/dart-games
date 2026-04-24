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

  testWidgets('Test 17: Buff - Blood Moon doubles attack damage - Set activeBuff = bloodMoon, throw single -> verify damage = 2', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    await SettingsHelpers.setMonsterMashHealthMax(tester, 20);
    await SettingsHelpers.toggleMonsterMashBonusBuffs(tester);

    await UITestHelpers.addPlayer(tester, 'Player A', config);
    await UITestHelpers.addPlayer(tester, 'Player B', config);

    await UITestHelpers.startGame(tester, config);

    final playerA = ProviderHelpers.findPlayerByName(tester, 'Player A')!;
    final playerB = ProviderHelpers.findPlayerByName(tester, 'Player B')!;
    final currentPlayerId = ProviderHelpers.getMonsterMashCurrentPlayerId(tester)!;
    final opponentId = currentPlayerId == playerA.id ? playerB.id : playerA.id;
    final opponentTarget = ProviderHelpers.getMonsterMashPlayerTarget(tester, opponentId)!;

    // Set Blood Moon buff programmatically
    await setActiveBuff(tester, BonusBuff.bloodMoon);

    // Verify UI shows buff indicator via keys
    expect(find.byKey(MonsterMashGameKeys.buffDamageShield), findsOneWidget);
    expect(find.byKey(MonsterMashGameKeys.buffLabel), findsOneWidget);
    expect(find.textContaining('2x'), findsWidgets);
    expect(find.textContaining('Double damage to any opponent!'), findsOneWidget);

    // Throw single at opponent
    await throwDartViaMock(tester, opponentTarget, multiplier: 'single');

    // Verify damage is doubled (1 * 2 = 2)
    final damageDealt = ProviderHelpers.getMonsterMashDartThrowDamageDealt(tester, currentPlayerId);
    expect(damageDealt.last, 2);

    // Throw double at opponent
    await throwDartViaMock(tester, opponentTarget, multiplier: 'double');

    // Verify damage is doubled (2 * 2 = 4)
    final damageDealt2 = ProviderHelpers.getMonsterMashDartThrowDamageDealt(tester, currentPlayerId);
    expect(damageDealt2.last, 4);

    // Verify total health decrease: 2 + 4 = 6
    final opponentHealth = ProviderHelpers.getMonsterMashPlayerHealth(tester, opponentId);
    expect(opponentHealth, 14); // 20 - 6 = 14
  });
}
