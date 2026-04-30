import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/settings_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 11: Game won - last monster standing - Eliminate opponent -> hasWinner=true, results screen appears', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    await SettingsHelpers.setMonsterMashHealthMax(tester, 10);

    await UITestHelpers.addPlayer(tester, 'Winner', config);
    await UITestHelpers.addPlayer(tester, 'Loser', config);

    await UITestHelpers.startGame(tester, config);

    final winner = ProviderHelpers.findPlayerByName(tester, 'Winner')!;
    final loser = ProviderHelpers.findPlayerByName(tester, 'Loser')!;
    final currentPlayerId = ProviderHelpers.getMonsterMashCurrentPlayerId(tester)!;
    final opponentId = currentPlayerId == winner.id ? loser.id : winner.id;
    final opponentTarget = ProviderHelpers.getMonsterMashPlayerTarget(tester, opponentId)!;

    // Attack with triples: 3+3+3 = 9 damage
    await throwDartViaMock(tester, opponentTarget, multiplier: 'triple');
    await throwDartViaMock(tester, opponentTarget, multiplier: 'triple');
    await throwDartViaMock(tester, opponentTarget, multiplier: 'triple');
    await clickDartsRemoved(tester);

    // Opponent has 1 HP, misses 3 darts
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await clickDartsRemoved(tester);

    // Finish off
    await throwDartViaMock(tester, opponentTarget, multiplier: 'single');

    // Verify winner
    expect(ProviderHelpers.monsterMashHasWinner(tester), isTrue);

    // Click darts removed and wait for results screen
    await clickDartsRemoved(tester);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    // Verify results screen appears
    final playAgainButton = config.getPlayAgainButton();
    expect(playAgainButton, findsOneWidget);
  });
}
