// integration_test/treasure_divide/team_setup/random_distribution_table_test.dart
//
// Verifies the Random distribution algorithm matches spec Section 5 table
// for ALL N=3..10 via the provider's static randomDistribution function,
// AND confirms via actual game start for N=4 (most common case).
//
// Spec Section 5 distribution table (pair-fill, cap=5 crews):
//   3→[2,1], 4→[2,2], 5→[2,2,1], 6→[2,2,2], 7→[2,2,2,1],
//   8→[2,2,2,2], 9→[2,2,2,2,1], 10→[2,2,2,2,2]
//
// Note: TD's rule is simpler than Tiki Golf (always pairs, never [4,4]).
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/providers/treasure_divide_provider.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/game_setup_helpers.dart';
import '../../shared/game_ui_config.dart';
import '_helpers.dart';

final config = GameUIConfig.treasureDivide();

// TD spec Section 5 distribution table (N → sorted sizes descending)
const _specTable = {
  3: [2, 1],
  4: [2, 2],
  5: [2, 2, 1],
  6: [2, 2, 2],
  7: [2, 2, 2, 1],
  8: [2, 2, 2, 2],
  9: [2, 2, 2, 2, 1],
  10: [2, 2, 2, 2, 2],
};

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Team Setup: TD Random distribution algorithm matches spec Section 5 table (all N=3..10)',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    // ── Part 1: Verify the static randomDistribution for ALL N ───────────
    // Pure algorithmic check — no UI needed, covers full 3..10 range.
    for (final entry in _specTable.entries) {
      final n = entry.key;
      final expectedSizes =
          List<int>.from(entry.value)..sort((a, b) => b.compareTo(a));
      final expectedTeamCount = expectedSizes.length;

      final result = TreasureDivideProvider.randomDistribution(n);
      final actualSizes =
          List<int>.from(result.sizes)..sort((a, b) => b.compareTo(a));

      expect(result.teamCount, expectedTeamCount,
          reason:
              'randomDistribution($n): expected $expectedTeamCount teams, '
              'got ${result.teamCount}');
      expect(actualSizes, equals(expectedSizes),
          reason:
              'randomDistribution($n): expected sizes $expectedSizes, '
              'got $actualSizes');
    }

    // ── Part 2: Verify via game start for N=4 (2 crews of 2) ─────────────
    await GameSetupHelpers.setupAndStartTreasureDivide(
      tester,
      config,
      teamMode: true,
      playerNames: ['P1', 'P2', 'P3', 'P4'],
    );

    final provider = ProviderHelpers.getTreasureDivideProvider(tester);
    final game = provider.currentGame;
    expect(game, isNotNull,
        reason: 'N=4: game should be active after SET SAIL');

    final actualTeamCount4 = game!.teamPlayers.length;
    final actualSizes4 = game.teamPlayers.values
        .map((members) => members.length)
        .toList()
      ..sort((a, b) => b.compareTo(a));

    expect(actualTeamCount4, 2,
        reason: 'N=4: should have 2 crews');
    expect(actualSizes4, equals([2, 2]),
        reason: 'N=4: crews should be [2,2] per spec distribution table');

    // Drain any pending layout exceptions from TD game screen.
    tester.binding.takeException();
  });
}
