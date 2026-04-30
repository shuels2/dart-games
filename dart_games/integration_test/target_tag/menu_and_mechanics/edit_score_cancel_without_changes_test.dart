import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/edit_score_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Test 23: Edit Score - Cancel Without Changes - Validates edit score dialog opens successfully, darts set to different values in dropdowns, cancel button clicked without saving, all dart changes discarded and not applied to game state, player shields and game state remain unchanged, edit score cancel functions correctly preventing unintended modifications',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    await UITestHelpers.addPlayer(tester, 'EditCancel1', config);
    await UITestHelpers.addPlayer(tester, 'EditCancel2', config);
    await UITestHelpers.startGame(tester, config);

    final player1Id = ProviderHelpers.getTargetTagCurrentPlayerId(tester);
    final shieldsBefore = ProviderHelpers.getTargetTagPlayerShields(tester, player1Id!);

    // Throw 3 darts to complete the turn
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);

    // Open edit score
    await EditScoreHelpers.openEditScore(tester, config);

    // Make changes
    final player1Target = ProviderHelpers.getTargetTagPlayerTarget(tester, player1Id);
    await EditScoreHelpers.setAllDarts(tester, 'S$player1Target', 'S$player1Target', 'S$player1Target');

    // Cancel (don't save)
    await EditScoreHelpers.cancelEditScore(tester);

    // Verify shields unchanged
    final shieldsAfter = ProviderHelpers.getTargetTagPlayerShields(tester, player1Id);
    expect(shieldsAfter, equals(shieldsBefore));
  });
}
