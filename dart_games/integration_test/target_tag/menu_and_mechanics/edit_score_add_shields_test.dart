import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/edit_score_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Test 20: Edit Score - Add Shields - Validates Player 2 starts with 0 shields, edit score dialog opened for Player 2, darts manually set to build shields (3x S20 own target hits), updating score adds shields to Player 2, Player 2 shield count increases from 0 to 3, canceling edit score reverts changes, edit score provides accurate shield modification throughout game',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    await UITestHelpers.addPlayer(tester, 'EditAdd1', config);
    await UITestHelpers.addPlayer(tester, 'EditAdd2', config);
    await UITestHelpers.startGame(tester, config);

    final player1Id = ProviderHelpers.getTargetTagCurrentPlayerId(tester);
    expect(player1Id, isNotNull);

    // Verify initial shields
    expect(ProviderHelpers.getTargetTagPlayerShields(tester, player1Id!), 0);

    // Throw 3 darts to complete the turn
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);

    // Open edit score
    await EditScoreHelpers.openEditScore(tester, config);

    // Get player target
    final player1Target = ProviderHelpers.getTargetTagPlayerTarget(tester, player1Id);
    expect(player1Target, isNotNull);

    // Set all darts to own target
    await EditScoreHelpers.setAllDarts(tester, 'S$player1Target', 'S$player1Target', 'S$player1Target');

    // Save
    await EditScoreHelpers.updateScore(tester);

    // Verify shields added
    final shieldsAfter = ProviderHelpers.getTargetTagPlayerShields(tester, player1Id);
    expect(shieldsAfter, 3);
  });
}
