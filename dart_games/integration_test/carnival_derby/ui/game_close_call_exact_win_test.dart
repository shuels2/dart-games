import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Test 11: Game - Perfect Finish Mode: Close Call (Just Under, Then Exact)
  // Features: Scoring just under target (safe), then exact win
  // UI Elements: Score tracking, no bust when under target, exact win detection
  // Validates: 95/100 is safe, then S5=100 exact wins
  testWidgets('Test 11: Close Call (Just Under, Then Exact)', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await navigateToCarnivalDerbyMenu(tester);

    await UITestHelpers.addPlayer(tester, 'TestPlayer', config);

    // Set target to 100 and enable Perfect Finish
    await setTargetScore(tester, 100);
    await togglePerfectFinish(tester);

    await startGame(tester);

    // Verify game settings displayed on game screen
    verifyGameSettings(tester, 100, true); // target=100, Perfect Finish ON

    // Turn 1: T20, S20, S15 = 95 (5 under - safe)
    await throwDartViaMock(tester, 20, multiplier: 'triple'); // 60
    await throwDartViaMock(tester, 20); // 80
    await throwDartViaMock(tester, 15); // 95

    expect(getCurrentPlayerScore(tester), 95);
    expect(currentPlayerBusted(tester), false);

    await clickDartsRemoved(tester);

    // Turn 2: S5 = 100 (exact win)
    await throwDartViaMock(tester, 5); // 100

    expect(getCurrentPlayerScore(tester), 100);
    expect(hasWinner(tester), true);
  });
}
