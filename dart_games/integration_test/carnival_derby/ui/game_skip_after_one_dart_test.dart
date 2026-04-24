import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Test 14: Game - Skip Turn After 1 Dart (Remaining Marked as Skip)
  // Features: Skip with 1 dart thrown, verify skip markers on D2/D3
  // UI Elements: Dart display showing "Skip" text, remove darts modal
  // Validates: Skip turn with 1 dart thrown, D1=10 scored, skip button clicked, D1/D2/D3 display shows "D1: 10", "D2: Skip", "D3: Skip", remove darts modal appears, turn advances to next player who wins
  testWidgets('Test 14: Skip Turn After 1 Dart (Remaining Marked as Skip)', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await navigateToCarnivalDerbyMenu(tester);

    await UITestHelpers.addPlayer(tester, 'Alice', config);
    await UITestHelpers.addPlayer(tester, 'Bob', config);

    await setTargetScore(tester, 60);

    await startGame(tester);

    // Alice Turn 1: Throw 1 dart (S10), then SKIP
    await throwDartViaMock(tester, 10); // D1 = 10
    expect(getCurrentPlayerScore(tester), 10);

    await UITestHelpers.clickSkipTurn(tester, config);

    // D2 and D3 should be marked as Skip, score stays 10
    expect(getCurrentPlayerScore(tester), 10);

    // Verify dart display: D1=10, D2=Skip, D3=Skip (remaining darts marked as Skip)
    verifyDartDisplay(tester, '10', 'Skip', 'Skip');

    // Remove darts modal should appear (we threw 1 dart)
    await clickDartsRemoved(tester);

    // Bob's turn
    await throwDartViaMock(tester, 20, multiplier: 'triple'); // 60 (wins)
    expect(getCurrentPlayerScore(tester), 60);
    expect(hasWinner(tester), true);
  });
}
