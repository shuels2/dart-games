import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/edit_score_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 7: Edit score changes hits to misses',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config);

    final playerId =
        ProviderHelpers.getClockworkQuestCurrentPlayerId(tester)!;

    // Throw 3 hits (targets 1, 2, 3 -> advance to target 4)
    await throwDartViaMock(tester, 1);
    await throwDartViaMock(tester, 2);
    await throwDartViaMock(tester, 3);

    expect(
        ProviderHelpers.getClockworkQuestPlayerCurrentTarget(tester, playerId), 4);

    // Edit: change all darts to misses
    await EditScoreHelpers.editScoreAndSave(
      tester, config,
      dart1: 'Miss',
      dart2: 'Miss',
      dart3: 'Miss',
    );

    // Target should be back to 1 (no hits)
    expect(
        ProviderHelpers.getClockworkQuestPlayerCurrentTarget(tester, playerId), 1);
  });
}
