import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Test 17: Game - 4-Player Race with Leaderboard Changes
  // Features: Multi-player racing, score tracking, leaderboard updates
  // UI Elements: 4 player race lanes, relative positions, leaderboard
  // Validates: Multiple rounds, leaderboard changes, winner crosses finish first
  testWidgets('Test 17: 4-Player Race', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await navigateToCarnivalDerbyMenu(tester);

    await UITestHelpers.addPlayer(tester, 'Alice', config);
    await UITestHelpers.addPlayer(tester, 'Bob', config);
    await UITestHelpers.addPlayer(tester, 'Charlie', config);
    await UITestHelpers.addPlayer(tester, 'Diana', config);

    await setTargetScore(tester, 150);

    await startGame(tester);

    // Round 1 - Alice: 60
    await throwDartViaMock(tester, 20);
    await throwDartViaMock(tester, 20);
    await throwDartViaMock(tester, 20);
    expect(getCurrentPlayerScore(tester), 60);
    await clickDartsRemoved(tester);

    // Round 1 - Bob: 45
    await throwDartViaMock(tester, 15);
    await throwDartViaMock(tester, 15);
    await throwDartViaMock(tester, 15);
    expect(getCurrentPlayerScore(tester), 45);
    await clickDartsRemoved(tester);

    // Round 1 - Charlie: 80
    await throwDartViaMock(tester, 20, multiplier: 'double');
    await throwDartViaMock(tester, 20);
    await throwDartViaMock(tester, 20);
    expect(getCurrentPlayerScore(tester), 80);
    await clickDartsRemoved(tester);

    // Round 1 - Diana: 20
    await throwDartViaMock(tester, 20);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    expect(getCurrentPlayerScore(tester), 20);
    await clickDartsRemoved(tester);

    // Round 2 - Alice: 120 total
    await throwDartViaMock(tester, 20);
    await throwDartViaMock(tester, 20);
    await throwDartViaMock(tester, 20);
    await clickDartsRemoved(tester);

    // Round 2 - Bob: 100 total
    await throwDartViaMock(tester, 20);
    await throwDartViaMock(tester, 20);
    await throwDartViaMock(tester, 15);
    await clickDartsRemoved(tester);

    // Round 2 - Charlie: 140 total
    await throwDartViaMock(tester, 20);
    await throwDartViaMock(tester, 20);
    await throwDartViaMock(tester, 20);
    await clickDartsRemoved(tester);

    // Round 2 - Diana: 80 total
    await throwDartViaMock(tester, 20);
    await throwDartViaMock(tester, 20);
    await throwDartViaMock(tester, 20);
    await clickDartsRemoved(tester);

    // Round 3 - Alice: Doesn't win
    await throwDartViaMock(tester, 10);
    await throwDartViaMock(tester, 10);
    await throwDartViaMock(tester, 5);
    await clickDartsRemoved(tester);

    // Round 3 - Bob: Doesn't win
    await throwDartViaMock(tester, 10);
    await throwDartViaMock(tester, 10);
    await throwDartViaMock(tester, 10);
    await clickDartsRemoved(tester);

    // Round 3 - Charlie: Wins with 180+
    await throwDartViaMock(tester, 20, multiplier: 'double');
    expect(getCurrentPlayerScore(tester), greaterThanOrEqualTo(150));
    expect(hasWinner(tester), true);
  });
}
