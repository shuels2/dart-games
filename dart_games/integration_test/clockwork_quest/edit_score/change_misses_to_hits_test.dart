import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/edit_score_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 6: Edit score changes misses to hits',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config);

    final playerId =
        ProviderHelpers.getClockworkQuestCurrentPlayerId(tester)!;

    // Throw 3 misses - no advancement
    await throw3DartsAndWaitForTakeout(tester);

    // Should still be at target 1
    expect(
        ProviderHelpers.getClockworkQuestPlayerCurrentTarget(tester, playerId), 1);

    // Edit: change dart 1 from Miss to S1 (single 1)
    await EditScoreHelpers.editScoreAndSave(
      tester, config,
      dart1: 'S1',
    );

    // Target should now be 2 (advanced by hitting target 1)
    expect(
        ProviderHelpers.getClockworkQuestPlayerCurrentTarget(tester, playerId), 2);
  });
}
