import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/settings_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/results_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 2: Play Again preserves settings - Complete game (health=15), Play Again -> new game with same players, healthMax=15', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    await SettingsHelpers.setMonsterMashHealthMax(tester, 15);

    await UITestHelpers.addPlayer(tester, 'Player A', config);
    await UITestHelpers.addPlayer(tester, 'Player B', config);

    await UITestHelpers.startGame(tester, config);

    // Need to verify healthMax is 15 in game
    final currentPlayerId = ProviderHelpers.getMonsterMashCurrentPlayerId(tester)!;
    expect(ProviderHelpers.getMonsterMashPlayerHealth(tester, currentPlayerId), 15);

    // Complete game to victory
    // Attack with appropriate damage for health=15
    final playerA = ProviderHelpers.findPlayerByName(tester, 'Player A')!;
    final playerB = ProviderHelpers.findPlayerByName(tester, 'Player B')!;
    final opponentId = currentPlayerId == playerA.id ? playerB.id : playerA.id;
    final opponentTarget = ProviderHelpers.getMonsterMashPlayerTarget(tester, opponentId)!;

    // Attack: 3+3+3=9 damage
    await throwDartViaMock(tester, opponentTarget, multiplier: 'triple');
    await throwDartViaMock(tester, opponentTarget, multiplier: 'triple');
    await throwDartViaMock(tester, opponentTarget, multiplier: 'triple');
    await clickDartsRemoved(tester);

    // Opponent misses
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await clickDartsRemoved(tester);

    // Attack: 3+3 = 6 more damage (total 15 = eliminated)
    await throwDartViaMock(tester, opponentTarget, multiplier: 'triple');
    await throwDartViaMock(tester, opponentTarget, multiplier: 'triple');
    await clickDartsRemoved(tester);

    // Wait for results
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    // Click Play Again
    await ResultsHelpers.clickPlayAgain(tester, config);

    // Verify new game started with same health
    expect(ProviderHelpers.isMonsterMashGameActive(tester), isTrue);
    final newPlayerId = ProviderHelpers.getMonsterMashCurrentPlayerId(tester)!;
    expect(ProviderHelpers.getMonsterMashPlayerHealth(tester, newPlayerId), 15);

    // Verify players are present
    expect(find.text('Player A'), findsWidgets);
    expect(find.text('Player B'), findsWidgets);
  });
}
