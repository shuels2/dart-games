import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 5: Sequential progression 1 through 3',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config);

    final provider = ProviderHelpers.getClockworkQuestProvider(tester);
    final playerId = provider.getCurrentPlayerId()!;

    await throwDartViaMock(tester, 1);
    expect(provider.getPlayerCurrentTarget(playerId), 2);

    await throwDartViaMock(tester, 2);
    expect(provider.getPlayerCurrentTarget(playerId), 3);

    await throwDartViaMock(tester, 3);
    expect(provider.getPlayerCurrentTarget(playerId), 4);
  });
}
