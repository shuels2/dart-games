import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

/// Per-dart win evaluation: a winning total reached on dart 1 or dart 2
/// must end the game IMMEDIATELY — the player must NOT have to keep throwing
/// to dart 3 for the win to register. Regression guard for the per-dart-eval
/// pattern shared with Lunar Lander, Carnival Derby, etc.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Gameplay: win on dart 1 — DF OFF, T20 with target=60 ends the game',
      (tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(
      tester,
      config,
      targetScore: 60,
      doubleFinishEnabled: false,
      playerNames: ['Player A', 'Player B'],
    );

    // T20 = 60 → prospective 60 ≥ 60 → VICTORY on dart 1.
    await throwDartViaMock(tester, 20, multiplier: 'triple');

    expect(ProviderHelpers.gladiatorArenaHasWinner(tester), isTrue,
        reason: 'Winning dart should end the game on dart 1');

    await clickDartsRemoved(tester);
    await tester.pump(const Duration(seconds: 4));
    await tester.pump();
    await tester.pump();

    expect(ElementFinders.getGladiatorArenaPlayAgainButton(), findsOneWidget,
        reason: 'Should navigate to results after dart-1 victory');
  });

  testWidgets(
      'Gameplay: win on dart 2 — DF ON, S20 + D20 with target=60 ends the game',
      (tester) async {
    await UITestHelpers.resetServerState();
    // Double Finish ON: last dart must be a double. S20 (20) then D20 (40)
    // = 60 exact, last dart a double → VICTORY on dart 2.
    await setupAndStartGame(
      tester,
      config,
      targetScore: 60,
      doubleFinishEnabled: true,
      playerNames: ['Player A', 'Player B'],
    );

    await throwDartViaMock(tester, 20); // S20 → 20/60, no win yet
    expect(ProviderHelpers.gladiatorArenaHasWinner(tester), isFalse);

    await throwDartViaMock(tester, 20, multiplier: 'double'); // D20 → 60 on a double
    expect(ProviderHelpers.gladiatorArenaHasWinner(tester), isTrue,
        reason: 'D20 on dart 2 should finish on a double and win');

    await clickDartsRemoved(tester);
    await tester.pump(const Duration(seconds: 4));
    await tester.pump();
    await tester.pump();

    expect(ElementFinders.getGladiatorArenaPlayAgainButton(), findsOneWidget,
        reason: 'Should navigate to results after dart-2 victory');
  });
}
