import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/edit_score_helpers.dart';
import '_helpers.dart';

/// Edit Score: open dialog, change values, tap Cancel → original score unchanged.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Edit Score: cancel leaves original score unchanged',
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

    // Original score = 4 (Splash)
    final originalScore =
        ProviderHelpers.getTikiGolfPlayerHoleScore(tester, playerId, hole);
    expect(originalScore, 4, reason: 'Original score should be 4 (Splash)');

    // Get a valid target segment to attempt editing
    final target = ProviderHelpers.getTikiGolfHoleTarget(tester, hole);

    // Open, change dart 1 to target, but cancel
    await EditScoreHelpers.editScoreAndCancel(
      tester,
      config,
      dart1: 'S$target',
    );

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    // Score should be unchanged
    final scoreAfterCancel =
        ProviderHelpers.getTikiGolfPlayerHoleScore(tester, playerId, hole);
    expect(scoreAfterCancel, originalScore,
        reason: 'Score should be unchanged after cancel');
  });
}
