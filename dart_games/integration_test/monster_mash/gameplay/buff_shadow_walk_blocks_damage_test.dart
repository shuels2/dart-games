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

  testWidgets('Test 19: Buff - Shadow Walk blocks all damage - Set activeBuff = shadowWalk, attack opponent -> damage = 0', (WidgetTester tester) async {
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

    // Set Shadow Walk buff
    await setActiveBuff(tester, BonusBuff.shadowWalk);

    // Verify UI shows buff indicator via keys
    expect(find.byKey(MonsterMashGameKeys.buffDamageShield), findsOneWidget);
    expect(find.byKey(MonsterMashGameKeys.buffLabel), findsOneWidget);
    expect(find.textContaining('You cannot attack opponents this turn!'), findsOneWidget);

    // Throw single at opponent
    await throwDartViaMock(tester, opponentTarget, multiplier: 'single');

    // Verify damage is 0
    final damageDealt = ProviderHelpers.getMonsterMashDartThrowDamageDealt(tester, currentPlayerId);
    expect(damageDealt.last, 0);

    // Verify opponent health unchanged
    final opponentHealth = ProviderHelpers.getMonsterMashPlayerHealth(tester, opponentId);
    expect(opponentHealth, 20);
  });
}
