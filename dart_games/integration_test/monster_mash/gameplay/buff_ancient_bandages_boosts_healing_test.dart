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

  testWidgets('Test 18: Buff - Ancient Bandages boosts healing to +5 - Set activeBuff = ancientBandages, hit own target -> heal = 5', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    await SettingsHelpers.setMonsterMashHealthMax(tester, 20);
    await SettingsHelpers.toggleMonsterMashBonusBuffs(tester);

    await UITestHelpers.addPlayer(tester, 'Player A', config);
    await UITestHelpers.addPlayer(tester, 'Player B', config);

    await UITestHelpers.startGame(tester, config);

    final currentPlayerId = ProviderHelpers.getMonsterMashCurrentPlayerId(tester)!;

    // Miss 3 darts, advance turn
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await clickDartsRemoved(tester);

    // Opponent attacks first player to reduce health
    final firstPlayerTarget = ProviderHelpers.getMonsterMashPlayerTarget(tester, currentPlayerId)!;
    await throwDartViaMock(tester, firstPlayerTarget, multiplier: 'triple'); // -3
    await throwDartViaMock(tester, firstPlayerTarget, multiplier: 'triple'); // -3
    await throwDartViaMock(tester, firstPlayerTarget, multiplier: 'triple'); // -3
    await clickDartsRemoved(tester);

    // First player health = 11 (20 - 9)
    final healthBefore = ProviderHelpers.getMonsterMashPlayerHealth(tester, currentPlayerId);
    expect(healthBefore, 11);

    // Set Ancient Bandages buff
    await setActiveBuff(tester, BonusBuff.ancientBandages);

    // Verify UI shows buff indicator via keys
    expect(find.byKey(MonsterMashGameKeys.buffHealShield), findsOneWidget);
    expect(find.byKey(MonsterMashGameKeys.buffLabel), findsOneWidget);
    expect(find.textContaining('Hit your target number for +5 HP!'), findsOneWidget);

    // Hit own target number (single) -> should heal +5
    await throwDartViaMock(tester, firstPlayerTarget, multiplier: 'single');

    // Verify heal amount = 5
    final healAmounts = ProviderHelpers.getMonsterMashDartThrowHealAmount(tester, currentPlayerId);
    expect(healAmounts.last, 5);

    // Verify health
    final healthAfter = ProviderHelpers.getMonsterMashPlayerHealth(tester, currentPlayerId);
    expect(healthAfter, 16); // 11 + 5 = 16
  });
}
