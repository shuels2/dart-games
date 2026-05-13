import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

/// Per-dart win evaluation regression: a winning total reached on dart 2
/// must end the game IMMEDIATELY — the player must NOT have to keep
/// throwing to dart 3 for the win to register. Pattern shared with Lunar
/// Lander, Carnival Derby, etc.
///
/// Target is 100 (menu minimum). DF ON requires the LAST dart to be a
/// double for the win to count. T20 (60) + D20 (40) = 100 exact with the
/// last dart a double → DF ON WIN on dart 2 of turn 1.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Gameplay: win on dart 2 — DF ON, T20 + D20 with target=100 ends the game',
      (tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(
      tester,
      config,
      targetScore: 100,
      doubleFinishEnabled: true,
      playerNames: ['Player A', 'Player B'],
    );

    // Dart 1: T20 → 60/100, no win yet.
    await throwDartViaMock(tester, 20, multiplier: 'triple');
    expect(ProviderHelpers.gladiatorArenaHasWinner(tester), isFalse);

    // Dart 2: D20 → prospective 100 exact on a double → DF ON VICTORY.
    await throwDartViaMock(tester, 20, multiplier: 'double');
    expect(ProviderHelpers.gladiatorArenaHasWinner(tester), isTrue,
        reason:
            'D20 on dart 2 should finish on a double and win immediately, '
            'not wait until dart 3');

    await clickDartsRemoved(tester);
    await tester.pump(const Duration(seconds: 4));
    await tester.pump();
    await tester.pump();

    expect(ElementFinders.getGladiatorArenaPlayAgainButton(), findsOneWidget,
        reason: 'Should navigate to results after dart-2 victory');
  });
}
