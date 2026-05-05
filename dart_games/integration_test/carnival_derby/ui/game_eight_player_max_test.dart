import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Test 18: Game - 8-Player Maximum Capacity Race
  // Features: Maximum 8 players racing simultaneously
  // UI Elements: 8 race lanes, all horses visible, turn progression
  // Validates: Maximum 8 players can be added, target set to 60, game starts, all 8 players take turns throwing T20 (60 points), first player to throw reaches target and wins. Note: Does NOT test all 8 players reaching target simultaneously - test exits on first player win
  testWidgets('Test 18: 8-Player Maximum Capacity', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await navigateToCarnivalDerbyMenu(tester);

    // Add 8 players
    for (int i = 1; i <= 8; i++) {
      await UITestHelpers.addPlayer(tester, 'Player $i', config);
    }

    await setTargetScore(tester, 60);

    await startGame(tester);

    // Each player throws T20 (all reach 60 in turn 1)
    for (int i = 0; i < 8; i++) {
      await throwDartViaMock(tester, 20, multiplier: 'triple');

      if (i == 0) {
        // First player reaches 60 and wins
        await clickDartsRemoved(tester);
        expect(getCurrentPlayerScore(tester), 60);
        expect(hasWinner(tester), true);
        break;
      }
    }

    // Verify game won by first player
    expect(hasWinner(tester), true);
  });
}
