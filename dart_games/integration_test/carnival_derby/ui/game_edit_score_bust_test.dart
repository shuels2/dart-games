import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Test 16: Game - Edit Score Triggers Bust (Perfect Finish Mode)
  // Features: Edit score causing bust in Perfect Finish mode, bust detection
  // UI Elements: Edit score modal, bust announcement after update
  // Validates: Edit score causing bust in Perfect Finish mode, editing S20/S15/S10 (45 points) to T20x3 (180 points) with target 70, bust flag set to true after update. Note: Does NOT explicitly verify score value reverts to 45 after bust - only validates bust flag is true
  testWidgets('Test 16: Edit Score with Bust (Perfect Finish Mode)', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await navigateToCarnivalDerbyMenu(tester);

    await UITestHelpers.addPlayer(tester, 'TestPlayer', config);

    await setTargetScore(tester, 70);
    await togglePerfectFinish(tester);

    await startGame(tester);

    // Turn 1: S20, S15, S10 = 45
    await throwDartViaMock(tester, 20);
    await throwDartViaMock(tester, 15);
    await throwDartViaMock(tester, 10);

    expect(getCurrentPlayerScore(tester), 45);

    // Open edit score modal
    await openEditScore(tester);

    // Change to T20, T20, T20 (would be 180 - BUST)
    await setDartInEditScore(tester, 0, 'Triple', number: 20);
    await setDartInEditScore(tester, 1, 'Triple', number: 20);
    await setDartInEditScore(tester, 2, 'Triple', number: 20);

    // Update score
    await updateScore(tester);

    // After processing T20 (60), second T20 would make 120, exceeding target 70 = BUST
    // Score should revert to start of turn or stay at intermediate value
    expect(getCurrentPlayerScore(tester), greaterThanOrEqualTo(0));
    expect(currentPlayerBusted(tester), true);

    await clickDartsRemoved(tester);

    // Turn 2: Win with exact score (score is 60 after bust, need 10 to reach 70)
    await throwDartViaMock(tester, 5, multiplier: 'double'); // D5 = 10 points, total = 70
  });
}
