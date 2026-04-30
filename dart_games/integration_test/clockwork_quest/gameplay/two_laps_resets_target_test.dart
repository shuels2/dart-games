import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 24: 2 laps - completing 1 lap resets target to 1',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config, laps: 2);

    final provider = ProviderHelpers.getClockworkQuestProvider(tester);
    final playerId = provider.getCurrentPlayerId()!;

    expect(provider.currentGame!.numberOfLaps, 2);

    // Set near end of first lap
    provider.currentGame!.currentTarget[playerId] = 20;
    await throwDartViaMock(tester, 20);

    // Should reset to target 1, lap 1 complete
    expect(provider.getPlayerCurrentTarget(playerId), 1);
    expect(provider.getPlayerLapsCompleted(playerId), 1);
    expect(provider.hasWinner, isFalse);
  });
}
