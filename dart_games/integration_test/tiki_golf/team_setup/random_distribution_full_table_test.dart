// integration_test/tiki_golf/team_setup/random_distribution_full_table_test.dart
//
// Verifies the Random distribution algorithm matches spec Section 5 table
// for ALL N=3..16 via the provider's static randomDistribution function,
// AND confirms via actual game start for N=4 (most common case) and N=8
// (special case with [4,4] instead of [2,2,2,2]).
//
// Running 14 full games in one test would exceed time budgets.
// The algorithmic coverage is complete via the static function check;
// two representative UI-level checks confirm game-start wiring is correct.
//
// Spec Section 5 distribution table:
//   3→[2,1], 4→[2,2], 5→[2,2,1], 6→[2,2,2], 7→[2,2,2,1], 8→[4,4],
//   9→[3,3,3], 10→[4,3,3], 11→[4,4,3], 12→[3,3,3,3],
//   13→[4,3,3,3], 14→[4,4,3,3], 15→[4,4,4,3], 16→[4,4,4,4]
//
// Section 12B File 8 — Team setup test 1 (random_distribution_full_table)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/providers/tiki_golf_provider.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/game_setup_helpers.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/play_to_complete_helpers.dart';
import '_helpers.dart';

final config = GameUIConfig.tikiGolf();

// Spec Section 5 distribution table (N → sorted sizes descending)
const _specTable = {
  3: [2, 1],
  4: [2, 2],
  5: [2, 2, 1],
  6: [2, 2, 2],
  7: [2, 2, 2, 1],
  8: [4, 4],
  9: [3, 3, 3],
  10: [4, 3, 3],
  11: [4, 4, 3],
  12: [3, 3, 3, 3],
  13: [4, 3, 3, 3],
  14: [4, 4, 3, 3],
  15: [4, 4, 4, 3],
  16: [4, 4, 4, 4],
};

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Team Setup: Random distribution algorithm matches spec Section 5 table (all N=3..16)',
      (WidgetTester tester) async {
    await UITestHelpers.runWithFailureScreenshot(
      tester,
      'tiki_golf_team_setup_random_distribution_full_table',
      () async {
        await UITestHelpers.resetServerState();

        // ── Part 1: Verify the static randomDistribution function for ALL N ──
        // Algorithmic check — no UI needed, covers the full 3..16 range
        for (final entry in _specTable.entries) {
          final n = entry.key;
          final expectedSizes = List<int>.from(entry.value)..sort((a, b) => b.compareTo(a));
          final expectedTeamCount = expectedSizes.length;

          final result = TikiGolfProvider.randomDistribution(n);
          final actualSizes = List<int>.from(result.sizes)..sort((a, b) => b.compareTo(a));

          expect(result.teamCount, expectedTeamCount,
              reason:
                  'randomDistribution($n): expected $expectedTeamCount teams, '
                  'got ${result.teamCount}');
          expect(actualSizes, equals(expectedSizes),
              reason:
                  'randomDistribution($n): expected sizes $expectedSizes, '
                  'got $actualSizes');
        }

        // ── Part 2: Verify via game start for N=4 (2 teams of 2) ─────────────
        // This confirms the provider wires randomDistribution correctly at TEE OFF
        await GameSetupHelpers.setupAndStartTikiGolf(
          tester,
          config,
          teamMode: true,
          playerNames: ['P1', 'P2', 'P3', 'P4'],
        );

        final provider = ProviderHelpers.getTikiGolfProvider(tester);
        final game = provider.currentGame;
        expect(game, isNotNull, reason: 'N=4: game should be active after TEE OFF');

        final actualTeamCount4 = game!.teamPlayers.length;
        final actualSizes4 = game.teamPlayers.values
            .map((members) => members.length)
            .toList()
          ..sort((a, b) => b.compareTo(a));

        expect(actualTeamCount4, 2,
            reason: 'N=4: should have 2 teams');
        expect(actualSizes4, equals([2, 2]),
            reason: 'N=4: teams should be [2,2]');

        // ── Part 3: N=8 special case check (must be [4,4] not [2,2,2,2]) ─────
        // Complete N=4 game first then navigate back to home
        await PlayToCompleteHelpers.tapPlayToComplete(tester);
        await PlayToCompleteHelpers.waitForGameCompletion(
          tester,
          isComplete: () => provider.hasWinner,
          maxIterations: 500,
        );

        // Navigate from results to home
        await tester.tap(config.getBackToMenuButton());
        await tester.pump(const Duration(milliseconds: 800));
        await tester.pump();
        // From menu → home
        final backBtns = find.byKey(const Key('tiki_golf_menu_back_button'));
        if (backBtns.evaluate().isNotEmpty) {
          await tester.tap(backBtns.first);
          await tester.pump(const Duration(milliseconds: 600));
          await tester.pump();
        }

        // Start N=8 game
        await GameSetupHelpers.setupAndStartTikiGolf(
          tester,
          config,
          teamMode: true,
          playerNames: ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'],
        );

        final provider8 = ProviderHelpers.getTikiGolfProvider(tester);
        final game8 = provider8.currentGame;
        expect(game8, isNotNull, reason: 'N=8: game should be active after TEE OFF');

        final actualSizes8 = game8!.teamPlayers.values
            .map((members) => members.length)
            .toList()
          ..sort((a, b) => b.compareTo(a));

        expect(game8.teamPlayers.length, 2,
            reason: 'N=8: should have 2 teams (not 4) — the N=8 special case');
        expect(actualSizes8, equals([4, 4]),
            reason:
                'N=8: teams should be [4,4] (not [2,2,2,2]) — the N=8 special case '
                'where pair-fill would give [2,2,2,2] but spec requires [4,4]');
      },
    );
  });
}
