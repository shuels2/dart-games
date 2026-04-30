import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 29: Speed mode + 2 laps - all gears reset after first lap',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config, speedMode: true, laps: 2);

    final provider = ProviderHelpers.getClockworkQuestProvider(tester);
    final playerId = provider.getCurrentPlayerId()!;

    // Activate gears 1-19
    for (int i = 1; i <= 19; i++) {
      provider.currentGame!.completedTargets[playerId]!.add(i);
    }
    provider.currentGame!.currentTarget[playerId] = 20;

    await throwDartViaMock(tester, 20);

    // First lap done, targets should reset
    expect(provider.getPlayerLapsCompleted(playerId), 1);
    expect(provider.getPlayerCompletedTargets(playerId), isEmpty);
    expect(provider.hasWinner, isFalse);
  });
}
