import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/settings_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Test 18: Last Shield Warning - Game Logic Validation - Validates Player 1 tagged in with max shields, Player 2 tagged in with max shields, Player 1 attacks Player 2 repeatedly reducing shields to 1, then eliminates Player 2 (shields reach 0), elimination confirmed. Note: Does NOT validate "special warning UI appears" or "last shield warning displays correctly" or "shield count shows 1 in UI" - only validates game logic (shield reduction and elimination), not visual warnings or UI displays',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    await SettingsHelpers.setTargetTagShieldMax(tester, 3);

    await UITestHelpers.addPlayer(tester, 'LastShield1', config);
    await UITestHelpers.addPlayer(tester, 'LastShield2', config);
    await UITestHelpers.startGame(tester, config);

    // Both players reach tagged in
    final player1Id = ProviderHelpers.getTargetTagCurrentPlayerId(tester);
    final player1Target = ProviderHelpers.getTargetTagPlayerTarget(tester, player1Id!);

    await throwDartViaMock(tester, player1Target!, multiplier: 'triple');

    // Throw 2 more darts to end the turn
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);

    // Remove darts to advance turn to Player 2
    await clickDartsRemoved(tester);

    final player2 = ProviderHelpers.getSelectedPlayers(tester).firstWhere((p) => p.id != player1Id);
    final player2Target = ProviderHelpers.getTargetTagPlayerTarget(tester, player2.id);

    await throwDartViaMock(tester, player2Target!, multiplier: 'triple');

    // Both tagged in
    expect(ProviderHelpers.isTargetTagPlayerTaggedIn(tester, player1Id), isTrue);
    expect(ProviderHelpers.isTargetTagPlayerTaggedIn(tester, player2.id), isTrue);

    // Throw 2 more darts to end the turn
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);

    // Remove darts to advance turn to Player 1
    await clickDartsRemoved(tester);

    // Player 1 attacks Player 2 twice (3 shields -> 1 shield)
    await throwDartViaMock(tester, player2Target);
    await throwDartViaMock(tester, player2Target);

    expect(ProviderHelpers.getTargetTagPlayerShields(tester, player2.id), 1);

    // Throw one more dart to end the turn
    await throwMissViaMock(tester);

    // Remove darts to advance turn to Player 2
    await clickDartsRemoved(tester);

    // Throw 3 more darts to end the turn
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);

    // Remove darts to advance turn to Player 1
    await clickDartsRemoved(tester);

    // Final elimination attack on Player 2 (1 shield -> 0 shield -> Eliminated)
    await throwDartViaMock(tester, player2Target);
    await throwDartViaMock(tester, player2Target);

    expect(ProviderHelpers.isTargetTagPlayerEliminated(tester, player2.id), isTrue);
  });
}
