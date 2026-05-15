import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/edit_score_helpers.dart';
import '_helpers.dart';

/// Edit Score: change dart 1 from miss to a valid target segment and Save →
/// score updates in the provider (turn replayed with new dart values).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Edit Score: change dart 1 to target segment and save updates score',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, maxStrokes: 3,
        playerNames: ['Alice', 'Bob']);

    final playerId = ProviderHelpers.getTikiGolfCurrentPlayerId(tester)!;
    final hole = ProviderHelpers.getTikiGolfCurrentHole(tester);

    // Throw all 3 misses → Splash (strokes = 4)
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    // Verify Splash recorded
    final splashScore =
        ProviderHelpers.getTikiGolfPlayerHoleScore(tester, playerId, hole);
    expect(splashScore, 4,
        reason: 'Splash should record strokes=4 before edit');

    // Get the target number for this hole
    final target = ProviderHelpers.getTikiGolfHoleTarget(tester, hole);

    // Edit dart 1 to the target → this makes it a Birdie (strokes=1)
    await EditScoreHelpers.editScoreAndSave(
      tester,
      config,
      dart1: 'S$target',
    );

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    // Score should now be 1 (Birdie) since dart 1 hits the target
    final newScore =
        ProviderHelpers.getTikiGolfPlayerHoleScore(tester, playerId, hole);
    expect(newScore, 1,
        reason:
            'After editing dart 1 to target, score should update to 1 (Birdie)');
  });
}
