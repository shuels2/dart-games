// integration_test/treasure_divide/team_mode_gameplay/team_mode_bottom_strip_per_crew_test.dart
//
// Team + Random, 4 players. Start game.
// Assert: per-crew tiles exist in the left column opponent list using
//         TreasureDivideGameKeys.crewTile(teamId) for each opponent crew.
//         Also verify each opponent crew tile shows the crew crest
//         (TreasureDivideGameKeys.crewCrest) and gold text.
import 'package:flutter/foundation.dart' show FlutterError, FlutterErrorDetails;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Team Mode Gameplay: per-crew tiles show crest and gold for opponent crews',
      (WidgetTester tester) async {
    // Suppress TD game screen layout overflow exceptions for this test.
    FlutterError.onError = (FlutterErrorDetails details) {};

    await UITestHelpers.resetServerState();
    // N=4 → 2 crews of 2; active crew's tile is NOT in opponent list
    await setupAndStartTeamGame(tester,
        playerNames: ['BS1', 'BS2', 'BS3', 'BS4']);

    final provider = ProviderHelpers.getTreasureDivideProvider(tester);
    final game = provider.currentGame!;
    final teamIds = game.teamPlayers.keys.toList();
    final activeTeamId = game.activeTeamId;

    // Opponent crew tiles should be present (all crews except the active one)
    final opponentTeams =
        teamIds.where((tid) => tid != activeTeamId).toList();
    expect(opponentTeams, isNotEmpty,
        reason:
            'Should have at least one opponent crew in a 4-player game');

    for (final teamId in opponentTeams) {
      // The crew tile for this opponent should be in the widget tree
      final crewTile = find.byKey(TreasureDivideGameKeys.crewTile(teamId));
      expect(crewTile, findsOneWidget,
          reason:
              'Crew tile for opponent $teamId should be visible in the '
              'left column opponent list');

      // The crew crest image should be present inside the tile
      final crewCrest = find.byKey(TreasureDivideGameKeys.crewCrest(teamId));
      expect(crewCrest, findsOneWidget,
          reason:
              'Crew crest for opponent $teamId should be visible inside '
              'the crew tile');

      // The crew treasure score text should be present
      final crewTreasureScore =
          find.byKey(TreasureDivideGameKeys.crewTreasureScore(teamId));
      expect(crewTreasureScore, findsOneWidget,
          reason:
              'Crew treasure score for opponent $teamId should be visible '
              'inside the crew tile (shows "0 gold" at game start)');
    }

    // Drain layout exceptions.
    tester.binding.takeException();
  });
}
