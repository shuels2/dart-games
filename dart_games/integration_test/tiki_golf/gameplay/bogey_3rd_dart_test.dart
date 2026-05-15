import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

/// Bogey: miss darts 1 and 2, hit target on dart 3 → strokes = 3.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Gameplay: miss darts 1-2, hit target dart 3 records strokes=3 (Bogey)',
      (WidgetTester tester) async {
    await UITestHelpers.runWithFailureScreenshot(
      tester,
      'tiki_golf_gameplay_bogey_3rd_dart',
      () async {
        await UITestHelpers.resetServerState();
        await setupAndStartGame(tester, maxStrokes: 3,
            playerNames: ['Alice', 'Bob']);

        final playerId = ProviderHelpers.getTikiGolfCurrentPlayerId(tester)!;
        final hole = ProviderHelpers.getTikiGolfCurrentHole(tester);

        // Darts 1 & 2: miss
        await throwMissViaMock(tester);
        await throwMissViaMock(tester);

        // Dart 3: hit target → turn ends
        await throwTargetDart(tester);

        // Strokes = 3 (Bogey)
        final score =
            ProviderHelpers.getTikiGolfPlayerHoleScore(tester, playerId, hole);
        expect(score, 3,
            reason: 'Hit on dart 3 should record strokes=3 (Bogey)');
      },
    );
  });
}
