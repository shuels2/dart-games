import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/settings_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

/// Per-dart win evaluation: when a dart eliminates the last opponent on
/// dart 1 of the active player's turn, the game must end IMMEDIATELY —
/// no need to throw darts 2 and 3. Regression guard for the per-dart-eval
/// pattern shared across every game.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Gameplay: solo mode, ShieldMax=1 — dart 1 elimination wins the game',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);
    // ShieldMax=1 → a single hit at a player's own target tags them in with
    // 1 shield, and a single hit at an opponent's target eliminates them.
    await SettingsHelpers.setTargetTagShieldMax(tester, 1);

    await UITestHelpers.addPlayer(tester, 'Player A', config);
    await UITestHelpers.addPlayer(tester, 'Player B', config);
    await UITestHelpers.startGame(tester, config);

    // Step 1: Player A hits OWN target once → tagged in with 1 shield.
    final p1Target = getCurrentPlayerTargetNumber(tester);
    await throwDartViaMock(tester, p1Target);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await clickDartsRemoved(tester);

    // Step 2: Player B hits OWN target once → tagged in with 1 shield.
    final p2Target = getCurrentPlayerTargetNumber(tester);
    await throwDartViaMock(tester, p2Target);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await clickDartsRemoved(tester);

    // Step 3: Player A attacks Player B's target with ONE dart.
    // ShieldMax=1 means one hit removes the only shield → P2 eliminated →
    // P1 wins. Game must end on dart 1 of this turn — do NOT throw any more.
    final playerProvider = ProviderHelpers.getPlayerProvider(tester);
    final playerB = playerProvider.selectedPlayers
        .firstWhere((p) => p.name == 'Player B');
    final playerBTarget =
        ProviderHelpers.getTargetTagPlayerTarget(tester, playerB.id)!;

    await throwDartViaMock(tester, playerBTarget);

    expect(ProviderHelpers.targetTagHasWinner(tester), isTrue,
        reason: 'Eliminating opponent on dart 1 should end the game');

    await clickDartsRemoved(tester);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    expect(config.getPlayAgainButton(), findsOneWidget,
        reason: 'Should navigate to results after dart-1 elimination win');
  });
}
