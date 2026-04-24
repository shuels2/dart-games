import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 3: Play Again returns to game screen',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await setupAndStartGame(tester, config);
    await completeGameToVictory(tester);

    await UITestHelpers.clickPlayAgain(tester, config);

    expect(ProviderHelpers.isReefRoyaleGameActive(tester), isTrue);
  });
}
