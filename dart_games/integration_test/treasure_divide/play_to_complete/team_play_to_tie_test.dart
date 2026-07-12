// integration_test/treasure_divide/play_to_complete/team_play_to_tie_test.dart
//
// Team mode + Random distribution, 4 players (= 2 crews of 2). Tap
// PLAY TO TIE button → TreasureDivideTieStrategy makes every player hit
// identically → every crew banks identical totals → results screen shows
// a multi-crew tie.
//
// Asserts:
//   - provider.hasWinner == true (game ended)
//   - winnerTeamIds.length >= 2 (multi-crew tie)
//   - every crew's totalForTeam IS the same value
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:dart_games/constants/test_keys.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/game_setup_helpers.dart';
import '../../shared/provider_helpers.dart';

final config = GameUIConfig.treasureDivide();

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Play to Tie (Team): every crew banks the same treasure → multi-crew tie',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await GameSetupHelpers.setupAndStartTreasureDivide(
      tester,
      config,
      teamMode: true,
      playerNames: ['T_A1', 'T_A2', 'T_B1', 'T_B2'],
    );

    // Drain accumulated layout exceptions.
    for (var i = 0; i < 5; i++) {
      if (tester.binding.takeException() == null) break;
    }

    // Tap "Divide the Treasure" (Play-to-Tie).
    final tieButton = find.byKey(DartboardEmulatorKeys.playToTieButton);
    expect(tieButton, findsOneWidget,
        reason: 'PLAY TO TIE button should be visible in emulator mode');
    await tester.ensureVisible(tieButton);
    await tester.pump();
    await tester.tap(tieButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Poll for game completion. Team mode with 4 players over 9 rounds
    // takes a bit longer than Solo (more darts to simulate) — 90s budget
    // is still ample.
    final provider = ProviderHelpers.getTreasureDivideProvider(tester);
    for (int i = 0; i < 300; i++) {
      if (provider.hasWinner) break;
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
    }
    expect(provider.hasWinner, isTrue,
        reason: 'Game should have a winner after Play To Tie completes');

    final game = provider.currentGame!;
    expect(game.winnerTeamIds.length, greaterThanOrEqualTo(2),
        reason:
            'Play to Tie (Team) should produce a TIE — winnerTeamIds.length '
            'should be ≥ 2; got ${game.winnerTeamIds.length} '
            '(winnerTeamIds = ${game.winnerTeamIds})');

    // Sanity: every crew's totalForTeam returns the SAME value.
    final crewTotals =
        game.teamPlayers.keys.map((tid) => game.totalForTeam(tid)).toSet();
    expect(crewTotals.length, 1,
        reason: 'All crews should have IDENTICAL totals on a Play-to-Tie '
            'run; got distinct totals: $crewTotals');

    // Let the results screen's `_deleteResumedSavedGame` post-frame
    // callback chain finish BEFORE framework teardown — see solo test
    // for full rationale.
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    await tester.pump();

    for (var i = 0; i < 5; i++) {
      if (tester.binding.takeException() == null) break;
    }
  });
}
