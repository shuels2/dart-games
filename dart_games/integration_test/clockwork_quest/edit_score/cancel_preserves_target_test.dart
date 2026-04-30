import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/edit_score_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 5: Cancel edit score preserves target progression',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config);

    final playerId =
        ProviderHelpers.getClockworkQuestCurrentPlayerId(tester)!;

    // Throw 3 hits (advance from target 1 to target 4)
    await throwDartViaMock(tester, 1);
    await throwDartViaMock(tester, 2);
    await throwDartViaMock(tester, 3);

    final targetAfterHits =
        ProviderHelpers.getClockworkQuestPlayerCurrentTarget(tester, playerId);
    expect(targetAfterHits, 4, reason: 'Should have advanced to target 4');

    // Open and cancel edit score
    await EditScoreHelpers.editScoreAndCancel(tester, config);

    // Target should be unchanged
    expect(
      ProviderHelpers.getClockworkQuestPlayerCurrentTarget(tester, playerId),
      targetAfterHits,
    );
  });
}
