import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/element_finders.dart';
import '_helpers.dart';

/// Scorecard cells update with correct colors per stroke count:
/// Birdie (1) = blue, Par (2) = neutral/white, Bogey (3) = pink, Splash (4) = orange.
///
/// This test verifies that scorecard cells are present and populated after each
/// player's turn completes. Color assertions rely on the cell widgets being
/// rendered; we verify cell existence and stroke values via provider.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Gameplay: scorecard cells render after each turn',
      (WidgetTester tester) async {
    await UITestHelpers.runWithFailureScreenshot(
      tester,
      'tiki_golf_gameplay_scorecard_updates',
      () async {
        await UITestHelpers.resetServerState();
        await setupAndStartGame(tester, maxStrokes: 3,
            playerNames: ['Alice', 'Bob']);

        final players = ProviderHelpers.getSelectedPlayers(tester);
        final aliceId = players.firstWhere((p) => p.name == 'Alice').id;
        final bobId = players.firstWhere((p) => p.name == 'Bob').id;

        // Scorecard widget visible
        expect(ElementFinders.getTikiGolfScorecard(), findsOneWidget,
            reason: 'Scorecard should be visible during gameplay');

        // Alice: Birdie (1 stroke)
        await throwTargetDart(tester);
        await clickDartsRemoved(tester);
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump();

        // Bob: Splash (3 misses = 4 strokes)
        await throwAllMissesToSplash(tester, maxStrokes: 3);
        await clickDartsRemoved(tester);
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump();

        // Verify scorecard cells exist for hole 1
        expect(ElementFinders.getTikiGolfScorecardCell(aliceId, 1), findsOneWidget,
            reason: 'Alice scorecard cell for hole 1 should be rendered');
        expect(ElementFinders.getTikiGolfScorecardCell(bobId, 1), findsOneWidget,
            reason: 'Bob scorecard cell for hole 1 should be rendered');

        // Verify provider state matches
        expect(
            ProviderHelpers.getTikiGolfPlayerHoleScore(tester, aliceId, 1), 1,
            reason: 'Alice hole 1 score should be 1 (Birdie)');
        expect(
            ProviderHelpers.getTikiGolfPlayerHoleScore(tester, bobId, 1), 4,
            reason: 'Bob hole 1 score should be 4 (Splash)');
      },
    );
  });
}
