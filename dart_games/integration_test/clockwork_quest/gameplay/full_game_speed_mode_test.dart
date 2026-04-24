import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 35: Full game with speed mode - P1 wins hitting gears in any order',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config, speedMode: true);

    final provider = ProviderHelpers.getClockworkQuestProvider(tester);
    final player1 = provider.getCurrentPlayerId()!;

    // Hit gears in non-sequential order: 20, 15, 10, 5, 1, ...
    final order = [20, 15, 10, 5, 1, 19, 14, 9, 4, 2, 18, 13, 8, 3, 17, 12, 7, 6, 16, 11];
    for (final gear in order) {
      await throwDartViaMock(tester, gear);
      if (provider.hasWinner) break;
      if (provider.shouldPromptTakeout) {
        await clickDartsRemoved(tester);
        await completeTurnWithMisses(tester);
      }
    }

    expect(provider.hasWinner, isTrue);
    expect(provider.currentGame!.winnerId, player1);
  });
}
