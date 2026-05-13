import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

/// Per-dart win evaluation regression: a winning total reached on dart 1
/// must end the game IMMEDIATELY — the player must NOT have to keep
/// throwing to dart 3 for the win to register. Pattern shared with Lunar
/// Lander, Carnival Derby, etc.
///
/// Target is 100 (menu minimum). The single-dart maximum score in darts is
/// T20=60, so a win on the very FIRST dart of the game is impossible with a
/// valid target. Instead, the test pre-loads P1 to 60 via turn 1, then
/// verifies the win triggers on dart 1 OF TURN 2 (D20 → 60+40=100).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Gameplay: win on dart 1 of a turn — DF OFF, D20 with score=60 wins immediately',
      (tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(
      tester,
      config,
      targetScore: 100,
      doubleFinishEnabled: false,
      playerNames: ['Player A', 'Player B'],
    );

    // Turn 1: P1 reaches 60 (T20 + 2 misses).
    await throwDartViaMock(tester, 20, multiplier: 'triple'); // T20 = 60
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await clickDartsRemoved(tester);

    // Turn 1: P2 misses everything (advances to P1 again).
    await completeTurnWithMisses(tester);

    // Turn 2 dart 1: D20 (40) → prospective 60+40=100 ≥ 100 → VICTORY on
    // the FIRST dart of P1's second turn. The win must register here, not
    // wait until dart 3 of the turn.
    await throwDartViaMock(tester, 20, multiplier: 'double');

    expect(ProviderHelpers.gladiatorArenaHasWinner(tester), isTrue,
        reason:
            'Winning dart should end the game immediately on dart 1 of '
            'the turn, not wait until dart 3');

    await clickDartsRemoved(tester);
    await tester.pump(const Duration(seconds: 4));
    await tester.pump();
    await tester.pump();

    expect(ElementFinders.getGladiatorArenaPlayAgainButton(), findsOneWidget,
        reason: 'Should navigate to results after dart-1 victory');
  });
}
