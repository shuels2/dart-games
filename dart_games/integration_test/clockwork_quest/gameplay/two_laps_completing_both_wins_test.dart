import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 25: 2 laps - completing both laps wins',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config, laps: 2);

    final provider = ProviderHelpers.getClockworkQuestProvider(tester);
    final playerId = provider.getCurrentPlayerId()!;

    // Complete first lap
    provider.currentGame!.currentTarget[playerId] = 20;
    provider.currentGame!.lapsCompleted[playerId] = 0;
    await throwDartViaMock(tester, 20);
    await clickDartsRemoved(tester);
    expect(provider.hasWinner, isFalse);

    // Complete second lap
    provider.currentGame!.currentTarget[playerId] = 20;
    await throwDartViaMock(tester, 20);
    await clickDartsRemoved(tester);

    expect(provider.hasWinner, isTrue);
  });
}
