import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 36: 3-player game completes and shows results',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config,
        playerNames: ['Alice', 'Bob', 'Carol']);

    await completeGameToVictory(tester, numOpponents: 2);

    // Should be on results screen
    await UITestHelpers.verifyResultsScreen(tester, config);
  });
}
