import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 8: Skip turn with darts thrown - Throw 1 dart, skip -> shouldPromptTakeout=true, after takeout advances to next player', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    await UITestHelpers.addPlayer(tester, 'Player A', config);
    await UITestHelpers.addPlayer(tester, 'Player B', config);

    await UITestHelpers.startGame(tester, config);

    final player1Id = ProviderHelpers.getMonsterMashCurrentPlayerId(tester)!;

    // Throw 1 dart
    await throwMissViaMock(tester);
    expect(ProviderHelpers.getMonsterMashCurrentPlayerDartsThrown(tester), 1);

    // Hide dartboard emulator so skip button is not obscured
    await tester.tap(find.byKey(DartboardEmulatorKeys.toggleFAB));
    await tester.pump();
    await tester.pump();

    // Skip turn
    await UITestHelpers.clickSkipTurn(tester, config);

    // Verify shouldPromptTakeout
    final provider = ProviderHelpers.getMonsterMashProvider(tester);
    expect(provider.shouldPromptTakeout, isTrue);

    // Show dartboard emulator for DARTS REMOVED button
    await tester.tap(find.byKey(DartboardEmulatorKeys.toggleFAB));
    await tester.pump();
    await tester.pump();

    // Click darts removed
    await clickDartsRemoved(tester);

    // Verify advanced to next player
    final player2Id = ProviderHelpers.getMonsterMashCurrentPlayerId(tester)!;
    expect(player2Id, isNot(equals(player1Id)));
  });
}
