// integration_test/tiki_golf/team_setup/random_post_shuffle_varies_test.dart
//
// N=7 players, multiple fresh games: multiset sizes [2,2,2,1] constant;
// player→team assignments vary across runs (statistical sanity).
//
// This tests that the Random distribution actually shuffles players differently
// each game, even though the team SIZE distribution is deterministic (N=7 → 4 teams
// of [2,2,2,1]).
//
// Note: we run 2 games and verify sizes are consistent + at least one assignment
// differs. Full 7-game verification is skipped for time budget reasons.
//
// Section 12B File 8 — Team setup test 10 (random_post_shuffle_varies)
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/play_to_complete_helpers.dart';
import '../../shared/game_setup_helpers.dart';
import '../../shared/game_ui_config.dart';
import '_helpers.dart';

final config = GameUIConfig.tikiGolf();

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Team Setup: N=7 Random games have constant team sizes [2,2,2,1] but varying player assignments',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    const playerNames = [
      'P1', 'P2', 'P3', 'P4', 'P5', 'P6', 'P7',
    ];
    // Expected sizes for N=7: [2,2,2,1] sorted descending
    const expectedSizes = [2, 2, 2, 1];

    // ── Game 1 ────────────────────────────────────────────────────────────
    await GameSetupHelpers.setupAndStartTikiGolf(
      tester,
      config,
      teamMode: true,
      playerNames: playerNames,
    );

    final provider = ProviderHelpers.getTikiGolfProvider(tester);
    final game1 = provider.currentGame!;

    final sizes1 = game1.teamPlayers.values
        .map((m) => m.length)
        .toList()
      ..sort((a, b) => b.compareTo(a));
    expect(sizes1, equals(expectedSizes),
        reason: 'Game 1 team sizes for N=7 should be [2,2,2,1]');

    // Capture player→team assignments for game 1
    final assignments1 = Map<String, String>.from(game1.playerTeamAssignments);

    // Drive game 1 to completion
    await PlayToCompleteHelpers.tapPlayToComplete(tester);
    await PlayToCompleteHelpers.waitForGameCompletion(
      tester,
      isComplete: () => provider.hasWinner,
      maxIterations: 800,
    );

    // Play Again → game 2 with same settings
    await tester.tap(config.getPlayAgainButton());
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    // ── Game 2 ────────────────────────────────────────────────────────────
    final game2 = provider.currentGame!;

    final sizes2 = game2.teamPlayers.values
        .map((m) => m.length)
        .toList()
      ..sort((a, b) => b.compareTo(a));
    expect(sizes2, equals(expectedSizes),
        reason: 'Game 2 team sizes for N=7 should still be [2,2,2,1]');

    // Assignments should differ in at least one player→team mapping
    // (extremely unlikely to be identical across two shuffles)
    final assignments2 = Map<String, String>.from(game2.playerTeamAssignments);

    // Check if any player is in a different team
    bool anyDiffers = false;
    for (final pid in assignments1.keys) {
      if (assignments1[pid] != assignments2[pid]) {
        anyDiffers = true;
        break;
      }
    }

    expect(anyDiffers, isTrue,
        reason:
            'Player→team assignments should vary across random games. '
            'Game 1: $assignments1, Game 2: $assignments2. '
            'Both identical means the shuffle is not working correctly.');
  });
}
