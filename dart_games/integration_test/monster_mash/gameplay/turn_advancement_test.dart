import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 7: Turn advancement - 3 darts then takeout - 3 darts -> shouldPromptTakeout=true, takeout finished -> advances to player 2', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    await UITestHelpers.addPlayer(tester, 'Player A', config);
    await UITestHelpers.addPlayer(tester, 'Player B', config);

    await UITestHelpers.startGame(tester, config);

    final player1Id = ProviderHelpers.getMonsterMashCurrentPlayerId(tester)!;

    // Throw 3 darts
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);

    // Verify shouldPromptTakeout
    final provider = ProviderHelpers.getMonsterMashProvider(tester);
    expect(provider.shouldPromptTakeout, isTrue);

    // Click darts removed
    await clickDartsRemoved(tester);

    // Verify turn advanced to player 2
    final player2Id = ProviderHelpers.getMonsterMashCurrentPlayerId(tester)!;
    expect(player2Id, isNot(equals(player1Id)));

    // Verify darts reset
    final dartsThrown = ProviderHelpers.getMonsterMashCurrentPlayerDartsThrown(tester);
    expect(dartsThrown, 0);
  });
}
