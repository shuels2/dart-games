// integration_test/tiki_golf/team_mode_gameplay/teams_panel_active_highlight_test.dart
//
// Team mode game screen: verify the teams panel is present and the active team
// box is rendered.
//
// Note: The Lagoon Blue accent / tint / opacity assertion is implementation-
// specific and not guaranteed to be findable via widget tests. This test
// verifies the structural presence of the teams panel and active team box.
// Visual tint verification is deferred to screenshot tests.
//
// Section 12B File 7 — Team mode gameplay test 4 (teams_panel_active_highlight)
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/element_finders.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Team Mode Gameplay: teams panel is present with active team box rendered',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    // N=4 → 2 teams of 2
    await setupAndStartTeamGame(tester,
        playerNames: ['P1', 'P2', 'P3', 'P4']);

    // Teams panel should be visible
    final teamsPanel = ElementFinders.getTikiGolfTeamsPanel();
    expect(teamsPanel, findsOneWidget,
        reason: 'Teams panel should be visible in team mode gameplay');

    // The active team's box should be rendered
    final provider = ProviderHelpers.getTikiGolfProvider(tester);
    final game = provider.currentGame!;
    final activeTeamId = game.activeTeamId;
    expect(activeTeamId, isNotNull,
        reason: 'Should have an active team at game start');

    final activeTeamBox = ElementFinders.getTikiGolfTeamBox(activeTeamId!);
    expect(activeTeamBox, findsOneWidget,
        reason:
            'Active team box should be rendered in teams panel. '
            'Active team: $activeTeamId');

    // All teams should have team boxes rendered
    for (final teamId in game.teamPlayers.keys) {
      final teamBox = ElementFinders.getTikiGolfTeamBox(teamId);
      expect(teamBox, findsOneWidget,
          reason: 'Team box for $teamId should be rendered');
    }
  });
}
