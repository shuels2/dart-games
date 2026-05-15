import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/element_finders.dart';
import '_helpers.dart';

/// Minimum player count (Solo, 2 players): game starts, both players complete
/// the first turn cycle, scorecard renders both player rows.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Gameplay: 2-player Solo game starts and scorecard renders both players',
      (WidgetTester tester) async {
    await UITestHelpers.runWithFailureScreenshot(
      tester,
      'tiki_golf_gameplay_min_player_count',
      () async {
        await UITestHelpers.resetServerState();
        await setupAndStartGame(tester, maxStrokes: 3,
            playerNames: ['Player A', 'Player B']);

        final players = ProviderHelpers.getSelectedPlayers(tester);
        expect(players.length, 2,
            reason: 'Should have exactly 2 players selected');

        // Scorecard should show both player names
        for (final player in players) {
          expect(find.textContaining(player.name), findsWidgets,
              reason: '${player.name} should be visible in scorecard');
        }

        // Complete hole 1 for both players (birdie)
        await throwTargetDart(tester);
        await clickDartsRemoved(tester);
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump();

        await throwTargetDart(tester);
        await clickDartsRemoved(tester);
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump();

        // Both players have scored hole 1
        for (final player in players) {
          final score =
              ProviderHelpers.getTikiGolfPlayerHoleScore(tester, player.id, 1);
          expect(score, isNotNull,
              reason: '${player.name} should have a score for hole 1');
        }

        // Game is still active after first full hole
        expect(ProviderHelpers.isTikiGolfGameActive(tester), isTrue);
      },
    );
  });
}
