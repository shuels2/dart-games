import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 34: Full game with bullseye - P1 wins after hitting bull',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config, includeBullseye: true);

    final provider = ProviderHelpers.getClockworkQuestProvider(tester);
    final player1 = provider.getCurrentPlayerId()!;

    // P1 hits 1-20 sequentially
    for (int target = 1; target <= 20; target++) {
      await throwDartViaMock(tester, target);
      if (target % 3 == 0 && target < 20) {
        await clickDartsRemoved(tester);
        await completeTurnWithMisses(tester);
      }
    }

    // After hitting 20, should be at target 21 (bullseye)
    expect(provider.getPlayerCurrentTarget(player1), 21);
    expect(provider.hasWinner, isFalse);

    // Handle takeout from the turn that hit 20
    if (provider.shouldPromptTakeout) {
      await clickDartsRemoved(tester);
      await completeTurnWithMisses(tester);
    }

    // Hit bullseye to win
    await throwBullseyeViaMock(tester);

    expect(provider.hasWinner, isTrue);
    expect(provider.currentGame!.winnerId, player1);
  });
}
