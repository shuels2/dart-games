import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/element_finders.dart';
import '_helpers.dart';

/// Maximum player count (Solo, 4 players): all 4 visible in scorecard,
/// no layout overflow errors.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Gameplay: 4-player Solo game has all 4 players in scorecard, no overflow',
      (WidgetTester tester) async {
    await UITestHelpers.runWithFailureScreenshot(
      tester,
      'tiki_golf_gameplay_max_player_count',
      () async {
        await UITestHelpers.resetServerState();
        await setupAndStartGame(tester,
            maxStrokes: 3,
            playerNames: ['P1', 'P2', 'P3', 'P4']);

        final players = ProviderHelpers.getSelectedPlayers(tester);
        expect(players.length, 4,
            reason: 'Should have exactly 4 players selected');

        // Scorecard should show all 4 player names
        for (final player in players) {
          expect(find.textContaining(player.name), findsWidgets,
              reason: '${player.name} should be visible in scorecard');
        }

        // Scorecard container is visible (no overflow)
        expect(ElementFinders.getTikiGolfScorecard(), findsOneWidget,
            reason: 'Scorecard should render without overflow with 4 players');

        // Game is active
        expect(ProviderHelpers.isTikiGolfGameActive(tester), isTrue);
      },
    );
  });
}
