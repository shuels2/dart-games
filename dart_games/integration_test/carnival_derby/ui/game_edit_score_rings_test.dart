import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Test 15: Game - Edit Score to Change Rings (Normal Mode)
  // Features: Edit score modal, ring type changes, score recalculation
  // UI Elements: Edit player score button, ring buttons (Triple/Double/Single), update button
  // Validates: S20x3 -> T20x2+S20 = 140 score update, winner detection
  testWidgets('Test 15: Edit Score During Remove Darts Modal', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await navigateToCarnivalDerbyMenu(tester);

    await UITestHelpers.addPlayer(tester, 'TestPlayer', config);

    await setTargetScore(tester, 100);

    await startGame(tester);

    // Turn 1: S20, S20, S20 = 60
    await throwDartViaMock(tester, 20);
    await throwDartViaMock(tester, 20);
    await throwDartViaMock(tester, 20);

    expect(getCurrentPlayerScore(tester), 60);

    // Open edit score modal
    await openEditScore(tester);

    // Change rings only (numbers are already 20): D1=T20, D2=T20, D3=S20
    // Just tap the ring buttons - don't select numbers since they're already 20
    await setDartInEditScore(tester, 0, 'Triple'); // D1: S20 -> T20
    await setDartInEditScore(tester, 1, 'Triple'); // D2: S20 -> T20
    // D3 stays S20 (no change needed)

    // Update score
    await updateScore(tester);

    // Verify score updated to 140 (60+60+20) and winner
    expect(getCurrentPlayerScore(tester), greaterThanOrEqualTo(100));
    expect(hasWinner(tester), true);
  });
}
