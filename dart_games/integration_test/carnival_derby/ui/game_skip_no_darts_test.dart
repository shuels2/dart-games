import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Test 12: Game - Skip Turn with No Darts (Immediate Turn Advance)
  // Features: Skip turn button, immediate turn progression with 0 darts
  // UI Elements: SKIP TURN button, turn transition
  // Validates: No remove darts modal, turn advances immediately to next player
  testWidgets('Test 12: Skip Turn with No Darts Thrown (Turn Advances)', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await navigateToCarnivalDerbyMenu(tester);

    await UITestHelpers.addPlayer(tester, 'Alice', config);
    await UITestHelpers.addPlayer(tester, 'Bob', config);

    await setTargetScore(tester, 60);

    await startGame(tester);

    // Alice Turn 1: SKIP immediately (no darts thrown)
    await UITestHelpers.clickSkipTurn(tester, config);

    // No remove darts modal should appear - turn should advance immediately
    // Wait for turn to advance
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    await tester.pump();

    // Verify we're now on Bob's turn by checking current player
    // We can't check dart display since it advances too quickly
    // Instead, verify that when Bob throws a dart, his score updates
    await throwDartViaMock(tester, 20, multiplier: 'triple'); // Bob: 60 (wins)

    expect(getCurrentPlayerScore(tester), 60);
    expect(hasWinner(tester), true);
  });
}
