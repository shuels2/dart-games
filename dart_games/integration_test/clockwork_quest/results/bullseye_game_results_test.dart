import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 9: Results screen after bullseye game shows winner',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config, includeBullseye: true);
    await completeGameToVictory(tester, includeBullseye: true);

    // Results screen should have all expected widgets
    await UITestHelpers.verifyResultsScreen(tester, config);

    // Winner info should be displayed
    expect(find.byKey(ClockworkQuestResultsKeys.winnerTitle), findsOneWidget);
    expect(find.byKey(ClockworkQuestResultsKeys.winnerName), findsOneWidget);
  });
}
