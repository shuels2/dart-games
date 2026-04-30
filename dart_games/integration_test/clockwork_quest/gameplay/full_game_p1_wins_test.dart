import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 31: Full game - P1 wins with sequential hits',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config);

    final provider = ProviderHelpers.getClockworkQuestProvider(tester);
    final player1 = provider.getCurrentPlayerId()!;

    // P1 plays turns, P2 misses, until P1 wins
    for (int target = 1; target <= 20; target++) {
      await throwDartViaMock(tester, target);

      // After every 3rd dart, handle takeout and opponent turn
      if (target % 3 == 0 && target < 20) {
        await clickDartsRemoved(tester);
        // P2 turn: all misses
        await completeTurnWithMisses(tester);
      }
    }

    // Game should be won
    expect(provider.hasWinner, isTrue);
    expect(provider.currentGame!.winnerId, player1);
  });
}
