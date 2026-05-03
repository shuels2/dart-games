import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Results: winner is displayed on results screen',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config);
    await completeGameToVictory(tester);

    // Results screen should show winner
    ResultsHelpers.verifyResultsScreenVisible(config);
    expect(ElementFinders.getLunarLanderWinnerName(), findsOneWidget);
    expect(find.textContaining('Player A'), findsWidgets);
  });
}
