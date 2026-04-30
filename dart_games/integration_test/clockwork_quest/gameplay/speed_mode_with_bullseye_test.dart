import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 22: Speed mode with bullseye - must also hit bull',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config,
        speedMode: true, includeBullseye: true);

    final provider = ProviderHelpers.getClockworkQuestProvider(tester);
    final playerId = provider.getCurrentPlayerId()!;

    expect(provider.currentGame!.maxTarget, 21);

    // Activate gears 1-20 directly
    for (int i = 1; i <= 20; i++) {
      provider.currentGame!.completedTargets[playerId]!.add(i);
    }
    provider.currentGame!.currentTarget[playerId] = 21;

    // Hit bullseye to complete
    await throwBullseyeViaMock(tester);

    expect(provider.hasWinner, isTrue);
  });
}
