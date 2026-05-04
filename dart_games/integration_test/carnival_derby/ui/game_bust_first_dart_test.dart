import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Test 9: Game - Perfect Finish Mode: Bust on First Dart
  // Features: Bust detection on first dart of turn, score stays at 0
  // UI Elements: Bust announcement, score display, turn end
  // Validates: D20=40 busts when target=30, score stays 0, recover next turn
  testWidgets('Test 9: Bust on First Dart', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await navigateToCarnivalDerbyMenu(tester);

    await UITestHelpers.addPlayer(tester, 'TestPlayer', config);

    // Set target to 30 and enable Perfect Finish
    await setTargetScore(tester, 30);
    await togglePerfectFinish(tester);

    await startGame(tester);

    // Verify game settings: target=30, Perfect Finish=ON
    verifyGameSettings(tester, 30, true);

    // Turn 1: D20 = 40 (BUST on first dart)
    await throwDartViaMock(tester, 20, multiplier: 'double');

    // Score should stay at 0 (busted from 0)
    expect(getCurrentPlayerScore(tester), 0);
    expect(currentPlayerBusted(tester), true);

    await clickDartsRemoved(tester);

    // Turn 2: S20, S10 = 30 (exact win)
    await throwDartViaMock(tester, 20); // 20
    await throwDartViaMock(tester, 10); // 30
    await clickDartsRemoved(tester);

    expect(getCurrentPlayerScore(tester), 30);
    expect(hasWinner(tester), true);
  });
}
