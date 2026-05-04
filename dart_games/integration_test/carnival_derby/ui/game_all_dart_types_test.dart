import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Test 7: Game - All Dart Types Scoring (Normal Mode)
  // Features: Single/double/triple scoring, bullseye, outer bull, miss
  // UI Elements: Dart display showing all score types, score accumulation
  // Validates: All dart types score correctly (S20, D20, T20, Bullseye, 25, Miss)
  testWidgets('Test 7: All Dart Types (Normal Mode)', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await navigateToCarnivalDerbyMenu(tester);

    await UITestHelpers.addPlayer(tester, 'TestPlayer', config);

    // Set target to 200
    await setTargetScore(tester, 200);

    await startGame(tester);

    // Verify game settings displayed on game screen
    verifyGameSettings(tester, 200, false); // target=200, Perfect Finish OFF

    // Turn 1: Single, Double, Triple
    await throwDartViaMock(tester, 20); // 20
    await throwDartViaMock(tester, 20, multiplier: 'double'); // 40
    await throwDartViaMock(tester, 20, multiplier: 'triple'); // 60

    expect(getCurrentPlayerScore(tester), 120);
    verifyCurrentPlayerScoreDisplay(tester, 120, 200); // Current player: 120/200
    verifyRaceTrackScore(tester, 120, 200); // Race track: 120/200

    // Verify dart display: D1=20 (single), D2=40 (double), D3=60 (triple)
    verifyDartDisplay(tester, '20', '40', '60');

    await clickDartsRemoved(tester);

    // Turn 2: Bullseye, Outer Bull, Miss
    await throwBullseyeViaMock(tester); // 50
    expect(getCurrentPlayerScore(tester), 170);

    await throwOuterBullViaMock(tester); // 25
    expect(getCurrentPlayerScore(tester), 195);

    await throwMissViaMock(tester); // 0
    expect(getCurrentPlayerScore(tester), 195);
    verifyCurrentPlayerScoreDisplay(tester, 195, 200); // Current player: 195/200
    verifyRaceTrackScore(tester, 195, 200); // Race track: 195/200

    // Verify dart display: D1=50 (bullseye), D2=25 (outer bull), D3=Miss
    verifyDartDisplay(tester, '50', '25', 'Miss');

    await clickDartsRemoved(tester);

    // Turn 3: T20, T20, S5 = 125 (total 320 > 200 - wins)
    await throwDartViaMock(tester, 20, multiplier: 'triple'); // 255 total - wins!

    // Player wins on first dart of turn 3 (195 + 60 = 255 >= 200)
    await clickDartsRemoved(tester);
    expect(getCurrentPlayerScore(tester), greaterThanOrEqualTo(200));
    expect(hasWinner(tester), true);

    // Note: Cannot verify dart display after win - screen transitions to results immediately
  });
}
