import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/edit_score_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 8: Edit score with partial changes',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config);

    final playerId =
        ProviderHelpers.getClockworkQuestCurrentPlayerId(tester)!;

    // Throw 3 misses
    await throw3DartsAndWaitForTakeout(tester);
    expect(
        ProviderHelpers.getClockworkQuestPlayerCurrentTarget(tester, playerId), 1);

    // Edit: change dart 1 and dart 2 to hits (S1, S2), leave dart 3 as miss
    await EditScoreHelpers.editScoreAndSave(
      tester, config,
      dart1: 'S1',
      dart2: 'S2',
    );

    // Target should be 3 (hit 1 and 2)
    expect(
        ProviderHelpers.getClockworkQuestPlayerCurrentTarget(tester, playerId), 3);
  });
}
