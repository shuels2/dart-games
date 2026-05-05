import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Test 19: Game - Minimum Target Score (20 points)
  // Features: Minimum boundary target score, quick win
  // UI Elements: Target score display, game start, winner detection
  // Validates: Game works with minimum 20-point target, S20 wins instantly
  testWidgets('Test 19: Minimum Target Score (20 points)', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await navigateToCarnivalDerbyMenu(tester);

    await UITestHelpers.addPlayer(tester, 'TestPlayer', config);

    // Set target to 20 (minimum)
    await setTargetScore(tester, 20);
    await togglePerfectFinish(tester);

    await startGame(tester);

    // Verify game settings displayed on game screen
    verifyGameSettings(tester, 20, true); // target=20, Perfect Finish ON

    // Single S20 should win
    await throwDartViaMock(tester, 20);
    await clickDartsRemoved(tester);
    expect(getCurrentPlayerScore(tester), 20);
    expect(hasWinner(tester), true);
  });
}
