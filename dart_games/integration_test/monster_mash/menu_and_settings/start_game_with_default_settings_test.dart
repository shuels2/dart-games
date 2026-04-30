import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 7: Start game with default settings - Add 2 players, start -> game screen loads, provider: isGameActive=true, health=20, unique targets/monsters', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    // Add 2 players
    await UITestHelpers.addPlayer(tester, 'Player A', config);
    await UITestHelpers.addPlayer(tester, 'Player B', config);

    // Start game with default settings
    await UITestHelpers.startGame(tester, config);

    // Verify game screen loaded
    expect(ProviderHelpers.isMonsterMashGameActive(tester), isTrue);

    // Verify health is at default (20)
    final currentPlayerId = ProviderHelpers.getMonsterMashCurrentPlayerId(tester);
    expect(currentPlayerId, isNotNull);
    final health = ProviderHelpers.getMonsterMashPlayerHealth(tester, currentPlayerId!);
    expect(health, 20);

    // Verify unique target numbers
    final playerA = ProviderHelpers.findPlayerByName(tester, 'Player A');
    final playerB = ProviderHelpers.findPlayerByName(tester, 'Player B');
    expect(playerA, isNotNull);
    expect(playerB, isNotNull);

    final targetA = ProviderHelpers.getMonsterMashPlayerTarget(tester, playerA!.id);
    final targetB = ProviderHelpers.getMonsterMashPlayerTarget(tester, playerB!.id);
    expect(targetA, isNotNull);
    expect(targetB, isNotNull);
    expect(targetA, isNot(equals(targetB))); // Unique targets

    // Verify unique monster types
    final monsterA = ProviderHelpers.getMonsterMashPlayerMonsterType(tester, playerA.id);
    final monsterB = ProviderHelpers.getMonsterMashPlayerMonsterType(tester, playerB.id);
    expect(monsterA, isNotNull);
    expect(monsterB, isNotNull);
    expect(monsterA, isNot(equals(monsterB))); // Unique monsters
  });
}
