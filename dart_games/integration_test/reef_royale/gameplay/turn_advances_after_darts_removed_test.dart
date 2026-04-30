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

    final firstPlayerId =
        ProviderHelpers.getReefRoyaleCurrentPlayerId(tester)!;

    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);

    await clickDartsRemoved(tester);

    final secondPlayerId =
        ProviderHelpers.getReefRoyaleCurrentPlayerId(tester);
    expect(secondPlayerId, isNot(equals(firstPlayerId)));
  });
}
