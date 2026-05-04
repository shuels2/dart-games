import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Test 10: Game - Perfect Finish Mode: Multiple Busts Before Win
  // Features: Multiple players busting, eventual exact win
  // UI Elements: Bust announcements for multiple players, score preservation
  // Validates: Both players bust (Bullseye=50, T20=60 vs target 40), then exact D20=40 wins
  testWidgets('Test 10: Multiple Busts Before Win', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await navigateToCarnivalDerbyMenu(tester);

    await UITestHelpers.addPlayer(tester, 'Alice', config);
    await UITestHelpers.addPlayer(tester, 'Bob', config);

    // Set target to 40 and enable Perfect Finish
    await setTargetScore(tester, 40);
    await togglePerfectFinish(tester);

    await startGame(tester);

    // Verify game settings: target=40, Perfect Finish=ON
    verifyGameSettings(tester, 40, true);

    // Alice Turn 1: Bullseye (50) - BUST
    await throwBullseyeViaMock(tester);
    expect(getCurrentPlayerScore(tester), 0);
    expect(currentPlayerBusted(tester), true);

    await clickDartsRemoved(tester);

    // Bob Turn 1: T20 (60) - BUST
    await throwDartViaMock(tester, 20, multiplier: 'triple');
    expect(getCurrentPlayerScore(tester), 0);
    expect(currentPlayerBusted(tester), true);

    await clickDartsRemoved(tester);

    // Alice Turn 2: D20 (40) - exact win
    await throwDartViaMock(tester, 20, multiplier: 'double');
    await clickDartsRemoved(tester);
    expect(getCurrentPlayerScore(tester), 40);
    expect(hasWinner(tester), true);
  });
}
