import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

/// maxStrokes=6, miss all 6 darts → strokes = 7 (Splash).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Gameplay: maxStrokes=6, miss all 6 darts records strokes=7 (Splash)',
      (WidgetTester tester) async {
    await UITestHelpers.runWithFailureScreenshot(
      tester,
      'tiki_golf_gameplay_max_strokes_6_splash',
      () async {
        await UITestHelpers.resetServerState();
        await setupAndStartGame(tester, maxStrokes: 6,
            playerNames: ['Alice', 'Bob']);

        final playerId = ProviderHelpers.getTikiGolfCurrentPlayerId(tester)!;
        final hole = ProviderHelpers.getTikiGolfCurrentHole(tester);

        // Miss all 6 darts → Splash
        await throwAllMissesToSplash(tester, maxStrokes: 6);

        // Strokes = 7 (Splash = maxStrokes + 1)
        final score =
            ProviderHelpers.getTikiGolfPlayerHoleScore(tester, playerId, hole);
        expect(score, 7,
            reason:
                'Missing all maxStrokes=6 darts should record strokes=7 (Splash)');

        expect(ProviderHelpers.tikiGolfShouldPromptTakeout(tester), isTrue,
            reason: 'shouldPromptTakeout should be true after Splash');
      },
    );
  });
}
