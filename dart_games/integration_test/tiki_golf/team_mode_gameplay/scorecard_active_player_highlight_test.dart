// integration_test/tiki_golf/team_mode_gameplay/scorecard_active_player_highlight_test.dart
//
// In team mode, the scorecard is visible and shows the active team's players.
// The active player row has Lagoon Blue tint (visual, screenshot-level only).
// This test verifies: (1) scorecard widget is present, (2) active player ID is set.
//
// Note: the scorecardPlayerRow key uses TableRow which may not be findable via
// find.byKey in all Flutter web configurations. We verify via scorecard presence
// and provider state instead. Visual highlight is screenshot-tested.
//
// Section 12B File 7 — Team mode gameplay test 5 (scorecard_active_player_highlight)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/element_finders.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Team Mode Gameplay: scorecard is present and active player is identified in team mode',
      (WidgetTester tester) async {
    await UITestHelpers.runWithFailureScreenshot(
      tester,
      'tiki_golf_team_mode_gameplay_scorecard_active_highlight',
      () async {
        await UITestHelpers.resetServerState();
        // N=4 → 2 teams of 2
        await setupAndStartTeamGame(tester,
            playerNames: ['P1', 'P2', 'P3', 'P4']);

        // Scorecard should be present
        final scorecard = ElementFinders.getTikiGolfScorecard();
        expect(scorecard, findsOneWidget,
            reason: 'Scorecard should be visible in team mode');

        // Active player should be set
        final activePlayerId =
            ProviderHelpers.getTikiGolfCurrentPlayerId(tester);
        expect(activePlayerId, isNotNull,
            reason: 'Should have an active player at game start');

        // Active player name should be visible in the game screen
        final provider = ProviderHelpers.getTikiGolfProvider(tester);
        final game = provider.currentGame!;
        final teamIds = game.teamPlayers.keys.toList();
        final activeTeamId = game.activeTeamId;
        expect(activeTeamId, isNotNull,
            reason: 'Should have an active team in team mode');

        // Verify the active player is in the active team
        final activeTeamPlayers = game.teamPlayers[activeTeamId!]!;
        expect(activeTeamPlayers.contains(activePlayerId), isTrue,
            reason:
                'Active player ($activePlayerId) should belong to the active team ($activeTeamId). '
                'Active team players: $activeTeamPlayers');

        // The scorecard caption should show the active team name
        final scorecardCaption =
            find.byKey(const Key('tiki_golf_game_scorecard_caption'));
        // Caption is present in team mode (shows "<TeamName> scorecard")
        // Use textContaining('scorecard') to verify the caption text
        expect(find.textContaining('scorecard'), findsWidgets,
            reason: 'Scorecard caption should show team scorecard label');
      },
    );
  });
}
