import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/settings_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/results_helpers.dart';
import '_helpers.dart';

/// Per-dart win evaluation: when a dart eliminates the last opponent on
/// dart 1 of the active player's turn, the game must end IMMEDIATELY —
/// no need to throw darts 2 and 3. Regression guard for the per-dart-eval
/// pattern shared across every game.
///
/// Target Tag's elimination rule (model: `shieldsBeforeHit == 0 && shields == 0`)
/// requires the victim to be at 0 shields BEFORE the killing dart. With
/// ShieldMax=1 we get there in two turns:
///   Turn 1 — P1 hits own target (tagged in, 1 shield); P2 misses 3x (0 shields).
///   Turn 2 — P1's dart 1 hits P2's target: shieldsBeforeHit=0 → P2 eliminated.
/// The assertion that matters is that dart 1 of turn 2 ends the game without
/// throwing darts 2 and 3 — that is the per-dart-eval regression guard.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Gameplay: solo mode, ShieldMax=1 — dart 1 of a turn ends the game immediately',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);
    await SettingsHelpers.setTargetTagShieldMax(tester, 1);

    await UITestHelpers.addPlayer(tester, 'Player A', config);
    await UITestHelpers.addPlayer(tester, 'Player B', config);
    await UITestHelpers.startGame(tester, config);

    // Turn 1, Player A: hit OWN target once → tagged in with 1 shield.
    final p1Target = getCurrentPlayerTargetNumber(tester);
    await throwDartViaMock(tester, p1Target);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await clickDartsRemoved(tester);

    // Turn 1, Player B: miss all three darts → stays at 0 shields, never
    // tagged in. This is the prerequisite for a single-dart elimination
    // under the "must be at 0 before the killing dart" rule.
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await clickDartsRemoved(tester);

    // Turn 2, Player A: dart 1 hits Player B's target.
    // Player B is at 0 shields before the hit, so the elimination check
    // (shieldsBeforeHit == 0 && shields == 0) fires immediately →
    // Player A wins on dart 1 of this turn. Do NOT throw any more darts.
    final playerProvider = ProviderHelpers.getPlayerProvider(tester);
    final playerB = playerProvider.selectedPlayers
        .firstWhere((p) => p.name == 'Player B');
    final playerBTarget =
        ProviderHelpers.getTargetTagPlayerTarget(tester, playerB.id)!;

    await throwDartViaMock(tester, playerBTarget);

    expect(ProviderHelpers.targetTagHasWinner(tester), isTrue,
        reason: 'Eliminating opponent on dart 1 should end the game');

    await clickDartsRemoved(tester);
    await ResultsHelpers.pumpUntilResults(tester, config);

    expect(config.getPlayAgainButton(), findsOneWidget,
        reason: 'Should navigate to results after dart-1 elimination win');
  });
}
