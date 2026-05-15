import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

/// Splash: maxStrokes=3, miss all 3 darts → strokes = maxStrokes+1 = 4.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Gameplay: maxStrokes=3, miss all 3 darts records strokes=4 (Splash)',
      (WidgetTester tester) async {
    await UITestHelpers.runWithFailureScreenshot(
      tester,
      'tiki_golf_gameplay_splash_max_darts_3',
      () async {
        await UITestHelpers.resetServerState();
        await setupAndStartGame(tester, maxStrokes: 3,
            playerNames: ['Alice', 'Bob']);

        final playerId = ProviderHelpers.getTikiGolfCurrentPlayerId(tester)!;
        final hole = ProviderHelpers.getTikiGolfCurrentHole(tester);

        // Miss all 3 darts → Splash
        await throwAllMissesToSplash(tester, maxStrokes: 3);

        // Strokes = 4 (Splash = maxStrokes + 1)
        final score =
            ProviderHelpers.getTikiGolfPlayerHoleScore(tester, playerId, hole);
        expect(score, 4,
            reason:
                'Missing all maxStrokes=3 darts should record strokes=4 (Splash)');

        // Turn ended flag
        expect(ProviderHelpers.tikiGolfShouldPromptTakeout(tester), isTrue,
            reason: 'shouldPromptTakeout should be true after Splash');
      },
    );
  });
}
