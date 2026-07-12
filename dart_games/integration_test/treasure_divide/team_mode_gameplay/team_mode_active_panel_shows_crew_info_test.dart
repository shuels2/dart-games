// integration_test/treasure_divide/team_mode_gameplay/team_mode_active_panel_shows_crew_info_test.dart
//
// Team + Random, 4 players. Start game.
// Assert: active player panel shows the crew crest (activeCrewCrest key)
//         AND "Crew Treasure:" text (crew name label)
//         AND "Next:" caption when the active crew has a teammate.
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Team Mode Gameplay: active player panel shows crew crest, crew treasure, and Next caption',
      (WidgetTester tester) async {

    await UITestHelpers.resetServerState();
    // N=4 → 2 crews of 2; first crew has 2 members so "Next:" should appear
    await setupAndStartTeamGame(tester,
        playerNames: ['TP1', 'TP2', 'TP3', 'TP4']);

    // Active crew crest should be visible in the active player panel
    expect(find.byKey(TreasureDivideGameKeys.activeCrewCrest), findsOneWidget,
        reason:
            'Active crew crest widget should be visible in active player panel '
            'when in team mode');

    // "Crew Treasure:" text (from _buildActiveCrewHeader label)
    expect(find.textContaining('Crew Treasure:'), findsOneWidget,
        reason:
            '"Crew Treasure:" text should be visible in active player panel '
            'showing the crew gold total');

    // "Next:" caption should appear since the 2-person first crew has a teammate
    final provider = ProviderHelpers.getTreasureDivideProvider(tester);
    final game = provider.currentGame!;
    final activeTeamId = game.activeTeamId;
    expect(activeTeamId, isNotNull,
        reason: 'Should have an active team at game start');

    final members = game.teamPlayers[activeTeamId!] ?? [];
    if (members.length > 1) {
      // There is a teammate — "Next:" caption should appear
      expect(find.textContaining('Next:'), findsOneWidget,
          reason:
              '"Next: {teammate}" caption should be visible in active player panel '
              'when the active crew has more than 1 member. '
              'Active team: $activeTeamId, members: $members');
    }

  });
}
