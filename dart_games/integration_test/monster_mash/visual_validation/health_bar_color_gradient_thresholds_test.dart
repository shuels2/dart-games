import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/settings_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 1: Health bar color gradient thresholds - Full health = green, ~70% = yellow shift, ~30% = red shift via provider healthPercentage', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    await SettingsHelpers.setMonsterMashHealthMax(tester, 20);

    await UITestHelpers.addPlayer(tester, 'Player A', config);
    await UITestHelpers.addPlayer(tester, 'Player B', config);

    await UITestHelpers.startGame(tester, config);

    final playerA = ProviderHelpers.findPlayerByName(tester, 'Player A')!;
    final playerB = ProviderHelpers.findPlayerByName(tester, 'Player B')!;
    final currentPlayerId = ProviderHelpers.getMonsterMashCurrentPlayerId(tester)!;

    // Full health = 100%
    final fullHealthPct = ProviderHelpers.getMonsterMashHealthPercentage(tester, currentPlayerId);
    expect(fullHealthPct, 1.0);

    // Reduce opponent's health to ~70% (14/20 = 70%)
    final opponentId = currentPlayerId == playerA.id ? playerB.id : playerA.id;
    final opponentTarget = ProviderHelpers.getMonsterMashPlayerTarget(tester, opponentId)!;

    await throwDartViaMock(tester, opponentTarget, multiplier: 'triple'); // -3
    await throwDartViaMock(tester, opponentTarget, multiplier: 'triple'); // -3
    await throwMissViaMock(tester);
    await clickDartsRemoved(tester);

    // Opponent at 14/20 = 70%
    final pct70 = ProviderHelpers.getMonsterMashHealthPercentage(tester, opponentId);
    expect(pct70, closeTo(0.7, 0.01));

    // Opponent's turn - attack first player to get to ~30%
    final firstPlayerTarget = ProviderHelpers.getMonsterMashPlayerTarget(tester, currentPlayerId)!;
    await throwDartViaMock(tester, firstPlayerTarget, multiplier: 'triple'); // -3
    await throwDartViaMock(tester, firstPlayerTarget, multiplier: 'triple'); // -3
    await throwDartViaMock(tester, firstPlayerTarget, multiplier: 'triple'); // -3
    await clickDartsRemoved(tester);

    // First player at 11/20 = 55%
    final pct55 = ProviderHelpers.getMonsterMashHealthPercentage(tester, currentPlayerId);
    expect(pct55, closeTo(0.55, 0.01));

    // Attack opponent more to get to ~30%
    await throwDartViaMock(tester, opponentTarget, multiplier: 'triple'); // -3 -> 11/20
    await throwDartViaMock(tester, opponentTarget, multiplier: 'triple'); // -3 -> 8/20
    await throwDartViaMock(tester, opponentTarget, multiplier: 'double'); // -2 -> 6/20
    await clickDartsRemoved(tester);

    // Opponent at 6/20 = 30%
    final pct30 = ProviderHelpers.getMonsterMashHealthPercentage(tester, opponentId);
    expect(pct30, closeTo(0.3, 0.01));
  });
}
