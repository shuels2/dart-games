import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/settings_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 5: Opponent health thresholds - Health >70% green zone, 30-70% yellow zone, <30% red zone', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    await SettingsHelpers.setMonsterMashHealthMax(tester, 20);

    await UITestHelpers.addPlayer(tester, 'Player A', config);
    await UITestHelpers.addPlayer(tester, 'Player B', config);

    await UITestHelpers.startGame(tester, config);

    final playerA = ProviderHelpers.findPlayerByName(tester, 'Player A')!;
    final playerB = ProviderHelpers.findPlayerByName(tester, 'Player B')!;
    final currentPlayerId = ProviderHelpers.getMonsterMashCurrentPlayerId(tester)!;
    final opponentId = currentPlayerId == playerA.id ? playerB.id : playerA.id;
    final opponentTarget = ProviderHelpers.getMonsterMashPlayerTarget(tester, opponentId)!;

    // At 20/20 = 100% -> green zone (>70%)
    var pct = ProviderHelpers.getMonsterMashHealthPercentage(tester, opponentId);
    expect(pct, greaterThan(0.7));

    // Reduce to 12/20 = 60% -> yellow zone (30-70%)
    await throwDartViaMock(tester, opponentTarget, multiplier: 'triple'); // -3 -> 17
    await throwDartViaMock(tester, opponentTarget, multiplier: 'triple'); // -3 -> 14
    await throwDartViaMock(tester, opponentTarget, multiplier: 'double'); // -2 -> 12
    await clickDartsRemoved(tester);

    pct = ProviderHelpers.getMonsterMashHealthPercentage(tester, opponentId);
    expect(pct, closeTo(0.6, 0.01));
    expect(pct, greaterThanOrEqualTo(0.3));
    expect(pct, lessThanOrEqualTo(0.7));

    // Opponent misses
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await clickDartsRemoved(tester);

    // Reduce to 4/20 = 20% -> red zone (<30%)
    await throwDartViaMock(tester, opponentTarget, multiplier: 'triple'); // -3 -> 9
    await throwDartViaMock(tester, opponentTarget, multiplier: 'triple'); // -3 -> 6
    await throwDartViaMock(tester, opponentTarget, multiplier: 'double'); // -2 -> 4
    await clickDartsRemoved(tester);

    pct = ProviderHelpers.getMonsterMashHealthPercentage(tester, opponentId);
    expect(pct, closeTo(0.2, 0.01));
    expect(pct, lessThan(0.3));
  });
}
