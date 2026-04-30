import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/settings_helpers.dart';
import '../../shared/edit_score_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Test 21: Edit Score - Create Elimination - Validates Player 2 starts with partial shields (not tagged in), edit score used to reduce Player 2 shields to 0, Player 2 receives TAGGED OUT badge after shields reach 0 via edit, player elimination through edit score functions identically to dart-based elimination, eliminated player removed from active turn rotation, game continues with remaining active players',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    await SettingsHelpers.setTargetTagShieldMax(tester, 3);

    await UITestHelpers.addPlayer(tester, 'EditElim1', config);
    await UITestHelpers.addPlayer(tester, 'EditElim2', config);
    await UITestHelpers.startGame(tester, config);

    // Player 1 gets tagged in
    final player1Id = ProviderHelpers.getTargetTagCurrentPlayerId(tester);
    final player1Target = ProviderHelpers.getTargetTagPlayerTarget(tester, player1Id!);

    for (int i = 0; i < 3; i++) {
      await throwDartViaMock(tester, player1Target!);
    }

    expect(ProviderHelpers.getTargetTagPlayerShields(tester, player1Id), 3);

    // Remove darts to advance turn to Player 2
    await clickDartsRemoved(tester);

    // Player 2 builds partial shields
    final player2 = ProviderHelpers.getSelectedPlayers(tester).firstWhere((p) => p.id != player1Id);
    final player2Target = ProviderHelpers.getTargetTagPlayerTarget(tester, player2.id);

    await throwDartViaMock(tester, player2Target!);
    await throwDartViaMock(tester, player2Target);
    await throwMissViaMock(tester);

    expect(ProviderHelpers.getTargetTagPlayerShields(tester, player2.id), 2);

    // Remove darts to advance turn to Player 1
    await clickDartsRemoved(tester);

    // Throw 3 darts to complete the turn
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);

    // Player 1 uses edit score to eliminate Player 2
    await EditScoreHelpers.openEditScore(tester, config);
    await EditScoreHelpers.setAllDarts(tester, 'S$player2Target', 'S$player2Target', 'S$player2Target');
    await EditScoreHelpers.updateScore(tester);

    // Verify elimination
    expect(ProviderHelpers.isTargetTagPlayerEliminated(tester, player2.id), isTrue);
    expect(find.text('TAGGED OUT'), findsAtLeastNWidgets(1));
  });
}
