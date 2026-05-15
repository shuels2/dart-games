import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

/// Results screen shows the final scorecard with all 9 holes filled
/// for all players.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Results: final scorecard shows all 9 holes for all players',
      (WidgetTester tester) async {
    await UITestHelpers.runWithFailureScreenshot(
      tester,
      'tiki_golf_results_final_scorecard',
      () async {
        await UITestHelpers.resetServerState();
        await setupAndStartGame(tester,
            maxStrokes: 3, playerNames: ['Alice', 'Bob']);

        await driveToCompletion(tester, playerNames: ['Alice', 'Bob']);

        // Results screen visible
        expect(ElementFinders.getTikiGolfPlayAgainButton(), findsOneWidget);

        // Final scorecard widget present
        expect(ElementFinders.getTikiGolfFinalScorecard(), findsOneWidget,
            reason: 'Final scorecard should be present on results screen');

        // All holes scored for both players
        final players = ProviderHelpers.getSelectedPlayers(tester);
        for (final player in players) {
          for (int hole = 1; hole <= 9; hole++) {
            final score = ProviderHelpers.getTikiGolfPlayerHoleScore(
                tester, player.id, hole);
            expect(score, isNotNull,
                reason:
                    '${player.name} should have a score for hole $hole on results screen');
          }
        }
      },
    );
  });
}
