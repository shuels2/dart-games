import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Results: Bo1 single round win shows "TREASURE FOUND!" headline',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config,
        bestOf: '1',
        playerNames: ['Player A', 'Player B']);

    await completeGameToVictory(tester);

    // Verify TREASURE FOUND! headline
    expect(find.text('TREASURE FOUND!'), findsOneWidget,
        reason: 'Single round win should show TREASURE FOUND! headline');

    // Verify winner name is displayed
    expect(ElementFinders.getPiratesGridWinnerName(), findsOneWidget,
        reason: 'Winner name widget should be visible');
  });
}
