import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Test 8: Game - Perfect Finish Mode: Simple Bust
  // Features: Perfect Finish exact score requirement, bust on overshoot
  // UI Elements: Bust announcement, score preservation, turn progression
  // Validates: Score reverts to pre-bust value, turn ends, next turn starts
  testWidgets('Test 8: Simple Bust (Going Over)', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await navigateToCarnivalDerbyMenu(tester);

    await UITestHelpers.addPlayer(tester, 'Alice', config);

    // Set target to 50 and enable Perfect Finish
    await setTargetScore(tester, 50);
    await togglePerfectFinish(tester);

    await startGame(tester);

    // Verify game settings displayed on game screen
    verifyGameSettings(tester, 50, true); // target=50, Perfect Finish ON

    // Turn 1: S20, then T20 (would bust: 20 + 60 = 80 > 50)
    await throwDartViaMock(tester, 20); // 20
    int scoreAfterFirstDart = getCurrentPlayerScore(tester);
    expect(scoreAfterFirstDart, 20);
    verifyCurrentPlayerScoreDisplay(tester, 20, 50); // Current player: 20/50
    verifyRaceTrackScore(tester, 20, 50); // Race track: 20/50

    await throwDartViaMock(tester, 20, multiplier: 'triple'); // Would be 80 total = BUST

    // Score should stay at 20 (before the busting dart)
    int scoreAfterBust = getCurrentPlayerScore(tester);
    expect(scoreAfterBust, 20);
    verifyCurrentPlayerScoreDisplay(tester, 20, 50); // Score stays at 20/50 after bust
    verifyRaceTrackScore(tester, 20, 50); // Race track still shows 20/50
    expect(currentPlayerBusted(tester), true);

    await clickDartsRemoved(tester);

    // Turn 2: S20, S10 = 50 (exact win)
    await throwDartViaMock(tester, 20); // 40
    await throwDartViaMock(tester, 10); // 50 (exact)
    await clickDartsRemoved(tester);

    expect(getCurrentPlayerScore(tester), 50);
    verifyCurrentPlayerScoreDisplay(tester, 50, 50); // Winner: 50/50
    verifyRaceTrackScore(tester, 50, 50); // Race track: 50/50
    expect(hasWinner(tester), true);
  });
}
