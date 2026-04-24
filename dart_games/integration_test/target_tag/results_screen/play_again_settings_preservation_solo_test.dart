import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/results_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 2: Play Again - Settings Preservation Solo Mode', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    // Set shield max to 3
    await setShieldMax(tester, 3);

    await UITestHelpers.addPlayer(tester, 'Player1', config);
    await UITestHelpers.addPlayer(tester, 'Player2', config);

    await UITestHelpers.startGame(tester, config);

    // Complete game to victory
    await completeGameToVictory(tester, 'Player1', 'Player2');

    // Click Play Again
    await ResultsHelpers.clickPlayAgain(tester, config);

    // Should navigate back to game screen with same settings
    expect(find.text('Target Tag Game On!'), findsOneWidget);
    expect(find.text('Player1'), findsWidgets);
    expect(find.text('Player2'), findsWidgets);
  });
}
