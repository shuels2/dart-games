import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Test 23: Results - Play Again with Same Settings
  // Features: Quick rematch, settings preservation
  // UI Elements: Play Again button, game screen navigation
  // Validates: Quick rematch, Play Again button clicked, navigates back to game screen. Note: Does NOT verify same players/target/Perfect Finish preserved or scores reset to 0 - only confirms navigation to game screen
  testWidgets('Test 23: Play Again (Same Settings)', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await navigateToCarnivalDerbyMenu(tester);

    await UITestHelpers.addPlayer(tester, 'Player1', config);

    await setTargetScore(tester, 180);

    await startGame(tester);

    // Quick win
    await throwDartViaMock(tester, 20, multiplier: 'triple');
    await throwDartViaMock(tester, 20, multiplier: 'triple');
    await throwDartViaMock(tester, 20, multiplier: 'triple');

    await clickDartsRemoved(tester);

    await tester.pump();
    await tester.pump(const Duration(seconds: 4));
    await tester.pump();
    await tester.pump();

    // Click Play Again
    final playAgainButton = config.getPlayAgainButton();
    await tester.tap(playAgainButton);
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    await tester.pump();

    // Should navigate back to game screen
    expect(find.text('Carnival Derby Race'), findsOneWidget);
  });
}
