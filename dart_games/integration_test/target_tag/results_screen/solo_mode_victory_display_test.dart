import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 1: Results Screen Content - Solo Mode Victory Display', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    // Set shield max to 3 (faster game, verify setting preservation)
    await setShieldMax(tester, 3);

    await UITestHelpers.addPlayer(tester, 'Winner Player', config);
    await UITestHelpers.addPlayer(tester, 'Loser Player', config);

    await UITestHelpers.startGame(tester, config);

    // Complete game to victory
    await completeGameToVictory(tester, 'Winner Player', 'Loser Player');

    // Verify results screen elements
    expect(find.text('WINNER!'), findsOneWidget);
    expect(find.text('Winner Player'), findsWidgets);
    expect(find.text('Play Again'), findsOneWidget);
    expect(find.text('Change Settings'), findsOneWidget);
    expect(find.text('Select Different Game'), findsOneWidget);
    expect(find.text('Target Tag Game Over'), findsOneWidget);
  });
}
