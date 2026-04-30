import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 15: Bullseye ON - must hit bull after 20',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config, includeBullseye: true);

    final provider = ProviderHelpers.getClockworkQuestProvider(tester);
    final playerId = provider.getCurrentPlayerId()!;

    // Verify maxTarget is 21 with bullseye
    expect(provider.currentGame!.maxTarget, 21);

    // Set player to target 20, hit 20
    provider.currentGame!.currentTarget[playerId] = 20;
    await throwDartViaMock(tester, 20);

    // Should advance to 21 (bullseye), not lap complete
    expect(provider.getPlayerCurrentTarget(playerId), 21);
    expect(provider.getPlayerLapsCompleted(playerId), 0);
  });
}
