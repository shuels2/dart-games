import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 7: Turn advances after darts removed',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config);

    final provider = ProviderHelpers.getClockworkQuestProvider(tester);
    final firstPlayerId = provider.getCurrentPlayerId()!;

    await throwDartViaMock(tester, 1);
    await throwDartViaMock(tester, 2);
    await throwDartViaMock(tester, 3);
    await clickDartsRemoved(tester);

    final secondPlayerId = provider.getCurrentPlayerId()!;
    expect(secondPlayerId, isNot(equals(firstPlayerId)));
  });
}
