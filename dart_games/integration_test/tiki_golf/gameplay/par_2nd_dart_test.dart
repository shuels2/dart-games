import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

/// Par: missing dart 1, hitting target on dart 2 → strokes = 2.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Gameplay: miss dart 1, hit target dart 2 records strokes=2 (Par)',
      (WidgetTester tester) async {
    await UITestHelpers.runWithFailureScreenshot(
      tester,
      'tiki_golf_gameplay_par_2nd_dart',
      () async {
        await UITestHelpers.resetServerState();
        await setupAndStartGame(tester, maxStrokes: 3,
            playerNames: ['Alice', 'Bob']);

        final playerId = ProviderHelpers.getTikiGolfCurrentPlayerId(tester)!;
        final hole = ProviderHelpers.getTikiGolfCurrentHole(tester);

        // Dart 1: miss
        await throwMissViaMock(tester);

        // Dart 2: hit target → turn ends
        await throwTargetDart(tester);

        // Strokes = 2 (Par)
        final score =
            ProviderHelpers.getTikiGolfPlayerHoleScore(tester, playerId, hole);
        expect(score, 2,
            reason: 'Hit on dart 2 should record strokes=2 (Par)');
      },
    );
  });
}
