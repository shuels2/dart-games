import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/edit_score_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 9: Edit score in speed mode changes completed gears',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config, speedMode: true);

    final playerId =
        ProviderHelpers.getClockworkQuestCurrentPlayerId(tester)!;
    final provider = ProviderHelpers.getClockworkQuestProvider(tester);

    // Hit gears 5, 10, 15 (speed mode: any order counts)
    await throwDartViaMock(tester, 5);
    await throwDartViaMock(tester, 10);
    await throwDartViaMock(tester, 15);

    expect(provider.getPlayerCompletedTargets(playerId), containsAll([5, 10, 15]));

    // Edit: change dart 2 from S10 to Miss
    await EditScoreHelpers.editScoreAndSave(
      tester, config,
      dart1: 'S5',
      dart2: 'Miss',
      dart3: 'S15',
    );

    expect(provider.getPlayerCompletedTargets(playerId), containsAll([5, 15]));
    expect(provider.getPlayerCompletedTargets(playerId), isNot(contains(10)));
  });
}
