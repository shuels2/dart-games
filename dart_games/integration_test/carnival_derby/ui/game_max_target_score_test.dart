import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Test 20: Game - Maximum Target Score (250 points)
  // Features: Maximum boundary target score, extended gameplay
  // UI Elements: Target score display, score accumulation over multiple turns
  // Validates: Game works with maximum 250-point target, scoring accurate
  testWidgets('Test 20: Maximum Target Score (250 points)', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await navigateToCarnivalDerbyMenu(tester);

    await UITestHelpers.addPlayer(tester, 'TestPlayer', config);

    // Set target to 250 (maximum)
    await setTargetScore(tester, 250);

    await startGame(tester);

    // Verify game settings displayed on game screen
    verifyGameSettings(tester, 250, false); // target=250, Perfect Finish OFF

    // Multiple turns to reach 250
    // Turn 1: 150 (3x Bullseye)
    await throwBullseyeViaMock(tester);
    await throwBullseyeViaMock(tester);
    await throwBullseyeViaMock(tester);
    expect(getCurrentPlayerScore(tester), 150);
    await clickDartsRemoved(tester);

    // Turn 2: 300 total (wins)
    await throwBullseyeViaMock(tester);
    await throwBullseyeViaMock(tester);
    await clickDartsRemoved(tester);
    expect(getCurrentPlayerScore(tester), greaterThanOrEqualTo(250));
    expect(hasWinner(tester), true);
  });
}
