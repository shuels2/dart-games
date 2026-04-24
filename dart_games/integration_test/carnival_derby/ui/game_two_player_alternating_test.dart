import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Test 6: Game - Two Players Alternating Turns (Normal Mode)
  // Features: Turn progression, multi-player scoring, winner detection
  // UI Elements: Current player indicator, score tracking, race positions
  // Validates: Turns alternate correctly, scores accumulate, first to target wins
  testWidgets('Test 6: Two Players Alternating Turns (Normal Mode)', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await navigateToCarnivalDerbyMenu(tester);

    await UITestHelpers.addPlayer(tester, 'Alice', config);
    await UITestHelpers.addPlayer(tester, 'Bob', config);

    // Set target to 100
    await setTargetScore(tester, 100);

    await startGame(tester);

    // Alice Turn 1: S20, S20, S20 = 60
    await throwDartViaMock(tester, 20); // 20
    await throwDartViaMock(tester, 20); // 40
    await throwDartViaMock(tester, 20); // 60

    expect(getCurrentPlayerScore(tester), 60);
    verifyCurrentPlayerScoreDisplay(tester, 60, 100); // Alice's current score
    verifyRaceTrackScore(tester, 60, 100); // Race track shows Alice: 60/100

    await clickDartsRemoved(tester);

    // Bob Turn 1: S15, S15, S15 = 45
    await throwDartViaMock(tester, 15); // 15
    await throwDartViaMock(tester, 15); // 30
    await throwDartViaMock(tester, 15); // 45

    expect(getCurrentPlayerScore(tester), 45);
    verifyCurrentPlayerScoreDisplay(tester, 45, 100); // Bob's current score
    verifyRaceTrackScore(tester, 45, 100); // Race track shows Bob: 45/100

    await clickDartsRemoved(tester);

    // Alice Turn 2: D20 = 40 (total 100 - wins)
    await throwDartViaMock(tester, 20, multiplier: 'double'); // 40

    expect(getCurrentPlayerScore(tester), 100);
    verifyCurrentPlayerScoreDisplay(tester, 100, 100); // Alice wins with 100/100
    verifyRaceTrackScore(tester, 100, 100); // Race track shows Alice: 100/100
    expect(hasWinner(tester), true);

    await clickDartsRemoved(tester);

    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    // Verify results screen with Alice as winner
    expect(find.text('Winner!'), findsOneWidget);
    expect(find.text('Alice'), findsWidgets);
  });
}
