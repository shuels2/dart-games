import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Gameplay: Hard Landing OFF — overshoot wins (altitude goes below 0)',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    // Hard Landing OFF (default) — going below 0 wins
    await setupAndStartGame(tester, config,
        altitude: 100, hardLanding: false, playerNames: ['Player A', 'Player B']);

    final playerId = getCurrentPlayerId(tester)!;

    // Get altitude to 5 by throwing 95
    // Triple 20 = 60 → alt=40; then 20 = 20 → alt=20; then 15 = 5 → alt=5
    await throwDartViaMock(tester, 20, multiplier: 'triple');
    await throwDartViaMock(tester, 20);
    await throwDartViaMock(tester, 15);
    await clickDartsRemoved(tester);
    await completeTurnWithMisses(tester); // Player B misses all

    // Player A at altitude 5 — now throw a dart that overshoots (e.g. single 20)
    // Hard Landing OFF: going below 0 wins
    await throwDartViaMock(tester, 20); // 5 - 20 = -15 → WIN (not bust)

    // Game should now have a winner
    expect(hasWinner(tester), isTrue,
        reason: 'Hard Landing OFF: overshoot (below 0) should win the game');
  });
}
