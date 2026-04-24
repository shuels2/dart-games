import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 21: Speed mode - completing all gears wins',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config, speedMode: true);

    final provider = ProviderHelpers.getClockworkQuestProvider(tester);
    final playerId = provider.getCurrentPlayerId()!;

    // Activate gears 1-19 directly
    for (int i = 1; i <= 19; i++) {
      provider.currentGame!.completedTargets[playerId]!.add(i);
    }
    provider.currentGame!.currentTarget[playerId] = 20;

    // Hit the last gear
    await throwDartViaMock(tester, 20);

    expect(provider.hasWinner, isTrue);
  });
}
