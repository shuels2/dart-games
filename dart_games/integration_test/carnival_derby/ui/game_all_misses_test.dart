import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Test 21: Game - All Misses Turn (Zero Score)
  // Features: Miss dart handling, announcements, score stays 0
  // UI Elements: Miss announcements, dart display showing "Miss"x3, score=0
  // Validates: Three misses score 0, remove darts modal appears, turn advances
  testWidgets('Test 21: All Misses Turn', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await navigateToCarnivalDerbyMenu(tester);

    await UITestHelpers.addPlayer(tester, 'Alice', config);
    await UITestHelpers.addPlayer(tester, 'Bob', config);

    await setTargetScore(tester, 60);

    await startGame(tester);

    // Alice Turn 1: Miss, Miss, Miss
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);

    expect(getCurrentPlayerScore(tester), 0);
    verifyCurrentPlayerScoreDisplay(tester, 0, 60); // Alice: 0/60 (all misses)
    verifyRaceTrackScore(tester, 0, 60); // Race track: 0/60

    // Verify dart display: D1=Miss, D2=Miss, D3=Miss
    verifyDartDisplay(tester, 'Miss', 'Miss', 'Miss');

    await clickDartsRemoved(tester);

    // Bob Turn 1: T20 wins
    await throwDartViaMock(tester, 20, multiplier: 'triple');
    await clickDartsRemoved(tester);
    expect(getCurrentPlayerScore(tester), 60);
    verifyCurrentPlayerScoreDisplay(tester, 60, 60); // Bob wins: 60/60
    verifyRaceTrackScore(tester, 60, 60); // Race track: 60/60
    expect(hasWinner(tester), true);
  });
}
