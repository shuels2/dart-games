import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 19: Speed mode - any gear number counts',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config, speedMode: true);

    final provider = ProviderHelpers.getClockworkQuestProvider(tester);
    final playerId = provider.getCurrentPlayerId()!;

    expect(provider.currentGame!.speedMode, isTrue);

    // Hit gear 15 (not target 1)
    await throwDartViaMock(tester, 15);

    // Should count as a hit in speed mode (any uncompleted gear)
    final completed = provider.getPlayerCompletedTargets(playerId);
    expect(completed, contains(15));
  });
}
