import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/edit_score_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 10: Edit score in speed mode adds new gears',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config, speedMode: true);

    final playerId =
        ProviderHelpers.getClockworkQuestCurrentPlayerId(tester)!;
    final provider = ProviderHelpers.getClockworkQuestProvider(tester);

    // Throw 3 misses
    await throw3DartsAndWaitForTakeout(tester);
    expect(provider.getPlayerCompletedTargets(playerId), isEmpty);

    // Edit: change to 3 hits
    await EditScoreHelpers.editScoreAndSave(
      tester, config,
      dart1: 'S3',
      dart2: 'S7',
      dart3: 'S12',
    );

    expect(provider.getPlayerCompletedTargets(playerId), containsAll([3, 7, 12]));
  });
}
