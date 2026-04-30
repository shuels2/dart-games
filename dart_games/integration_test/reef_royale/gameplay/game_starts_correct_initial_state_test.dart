import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 1: Game starts with correct initial state',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await setupAndStartGame(tester, config);

    expect(ProviderHelpers.isReefRoyaleGameActive(tester), isTrue);
    expect(ProviderHelpers.getReefRoyaleCurrentPlayerId(tester), isNotNull);
    expect(
        ProviderHelpers.getReefRoyaleCurrentPlayerDartsThrown(tester), 0);
  });
}
