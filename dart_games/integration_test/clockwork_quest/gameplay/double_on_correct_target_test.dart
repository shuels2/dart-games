import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 13: Double on correct target still advances 1 gear',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config);

    final provider = ProviderHelpers.getClockworkQuestProvider(tester);
    final playerId = provider.getCurrentPlayerId()!;

    // Hit double 1
    await throwDartViaMock(tester, 1, multiplier: 'double');

    // Should advance to target 2 (doubles count as single hit in normal mode)
    expect(provider.getPlayerCurrentTarget(playerId), 2);
  });
}
