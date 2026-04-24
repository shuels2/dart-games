import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 20: Speed mode - already activated gear does not count',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config, speedMode: true);

    final provider = ProviderHelpers.getClockworkQuestProvider(tester);
    final playerId = provider.getCurrentPlayerId()!;

    // Hit gear 5
    await throwDartViaMock(tester, 5);
    expect(provider.getPlayerCompletedTargets(playerId), contains(5));

    // Hit gear 5 again
    await throwDartViaMock(tester, 5);
    // Should still only have 1 completed target
    expect(provider.getPlayerCompletedTargets(playerId).length, 1);
  });
}
