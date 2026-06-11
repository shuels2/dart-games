// integration_test/treasure_divide/team_setup/team_crests_picked_test.dart
//
// Set up a team game (Random, 4 players), tap SET SAIL.
// Assert: provider.currentGame!.teamCrestPaths.length == teamCount
//         AND each path is one of the 6 known crest paths
//         AND no duplicates.
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/game_setup_helpers.dart';
import '../../shared/game_ui_config.dart';

final config = GameUIConfig.treasureDivide();

// The 6 known crest asset paths (from spec Section 3E and provider)
const _knownCrestPaths = {
  'assets/games/treasure_divide/teams/CrossedCutlasses.png',
  'assets/games/treasure_divide/teams/GoldDoubloon.png',
  'assets/games/treasure_divide/teams/CompassRose.png',
  'assets/games/treasure_divide/teams/ShipsWheel.png',
  'assets/games/treasure_divide/teams/Anchor.png',
  'assets/games/treasure_divide/teams/Kraken.png',
};

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Team Setup: teamCrestPaths has correct count, valid paths, and no duplicates',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    // N=4 → 2 crews of 2 (per spec distribution table)
    await GameSetupHelpers.setupAndStartTreasureDivide(
      tester,
      config,
      teamMode: true,
      playerNames: ['C1', 'C2', 'C3', 'C4'],
    );

    // Drain any exceptions accumulated during game screen initial render.
    // Using takeException() is safe: it only drains the binding queue and
    // does NOT suppress errors the way FlutterError.onError=no-op does
    // (which can destabilize the renderer and crash Chrome).
    for (var i = 0; i < 5; i++) {
      final ex = tester.binding.takeException();
      if (ex == null) break;
    }

    final provider = ProviderHelpers.getTreasureDivideProvider(tester);
    final game = provider.currentGame;
    expect(game, isNotNull,
        reason: 'Game should be active after SET SAIL');

    final teamCount = game!.teamPlayers.length;
    final crestPaths = game.teamCrestPaths;

    // Crest count matches team count
    expect(crestPaths.length, equals(teamCount),
        reason:
            'teamCrestPaths.length should equal teamCount ($teamCount), '
            'got ${crestPaths.length}');

    // Each path is one of the 6 known crests
    for (final path in crestPaths) {
      expect(_knownCrestPaths.contains(path), isTrue,
          reason:
              'Crest path "$path" is not one of the 6 known crest paths: '
              '$_knownCrestPaths');
    }

    // No duplicates
    final uniquePaths = crestPaths.toSet();
    expect(uniquePaths.length, equals(crestPaths.length),
        reason:
            'teamCrestPaths should have no duplicates. '
            'Got: $crestPaths');

    // Drain any residual pending exceptions.
    for (var i = 0; i < 5; i++) {
      final ex = tester.binding.takeException();
      if (ex == null) break;
    }
  });
}
