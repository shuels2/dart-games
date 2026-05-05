import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 16: Bullseye ON - hitting bull at target 21 completes lap',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config, includeBullseye: true);

    final provider = ProviderHelpers.getClockworkQuestProvider(tester);
    final playerId = provider.getCurrentPlayerId()!;

    provider.currentGame!.currentTarget[playerId] = 21;
    await throwBullseyeViaMock(tester);
    await clickDartsRemoved(tester);

    // Should have completed 1 lap and won (1 lap game)
    expect(provider.hasWinner, isTrue);
  });
}
