import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Test 13: Game - Skip Turn After Throwing Darts
  // Features: Skip turn with partial darts thrown, skip markers
  // UI Elements: SKIP TURN button, dart display, remove darts modal
  // Validates: S20 + SKIP = remaining darts marked as Skip, remove darts modal appears
  testWidgets('Test 13: Skip Turn with Darts Thrown', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await navigateToCarnivalDerbyMenu(tester);

    await UITestHelpers.addPlayer(tester, 'Alice', config);
    await UITestHelpers.addPlayer(tester, 'Bob', config);

    await setTargetScore(tester, 60);

    await startGame(tester);

    // Alice Turn 1: S20, then SKIP
    await throwDartViaMock(tester, 20);
    expect(getCurrentPlayerScore(tester), 20);
    verifyCurrentPlayerScoreDisplay(tester, 20, 60); // Alice: 20/60
    verifyRaceTrackScore(tester, 20, 60); // Race track: 20/60

    // Click SKIP TURN
    await UITestHelpers.clickSkipTurn(tester, config);

    // Verify dart display: D1=20, D2=Skip, D3=Skip (remaining darts marked as Skip)
    verifyDartDisplay(tester, '20', 'Skip', 'Skip');

    // Remaining darts marked as Skip, score stays 20
    verifyCurrentPlayerScoreDisplay(tester, 20, 60); // Score still 20/60 after skip
    verifyRaceTrackScore(tester, 20, 60); // Race track still 20/60

    await clickDartsRemoved(tester);

    // Bob's turn
    await throwDartViaMock(tester, 20, multiplier: 'triple'); // 60 (wins)
    expect(getCurrentPlayerScore(tester), 60);
    verifyCurrentPlayerScoreDisplay(tester, 60, 60); // Bob wins: 60/60
    verifyRaceTrackScore(tester, 60, 60); // Race track: 60/60
    expect(hasWinner(tester), true);
  });
}
