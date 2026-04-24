import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/settings_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 10: Player elimination - health=10, attack opponent until health=0 -> isEliminated=true', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    // Set low health for faster elimination
    await SettingsHelpers.setMonsterMashHealthMax(tester, 10);

    await UITestHelpers.addPlayer(tester, 'Player A', config);
    await UITestHelpers.addPlayer(tester, 'Player B', config);

    await UITestHelpers.startGame(tester, config);

    final playerA = ProviderHelpers.findPlayerByName(tester, 'Player A')!;
    final playerB = ProviderHelpers.findPlayerByName(tester, 'Player B')!;
    final currentPlayerId = ProviderHelpers.getMonsterMashCurrentPlayerId(tester)!;
    final opponentId = currentPlayerId == playerA.id ? playerB.id : playerA.id;
    final opponentTarget = ProviderHelpers.getMonsterMashPlayerTarget(tester, opponentId)!;

    // Attack opponent with triples: 3+3+3 = 9 damage
    await throwDartViaMock(tester, opponentTarget, multiplier: 'triple');
    await throwDartViaMock(tester, opponentTarget, multiplier: 'triple');
    await throwDartViaMock(tester, opponentTarget, multiplier: 'triple');
    await clickDartsRemoved(tester);

    // Opponent has 1 HP, their turn now
    expect(ProviderHelpers.getMonsterMashPlayerHealth(tester, opponentId), 1);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await clickDartsRemoved(tester);

    // First player's turn again - finish off with single
    await throwDartViaMock(tester, opponentTarget, multiplier: 'single');

    // Verify opponent is eliminated
    expect(ProviderHelpers.isMonsterMashPlayerEliminated(tester, opponentId), isTrue);
    expect(ProviderHelpers.getMonsterMashPlayerHealth(tester, opponentId), 0);
  });
}
