// integration_test/treasure_divide/results_screen/play_again_preserves_team_assignments_test.dart
//
// Regression test for the "team assignments lost after SAIL AGAIN" bug.
// The results screen calls provider.startGame(manualTeamAssignments: ...)
// with the previous game's playerTeamAssignments map when the user
// chose manual team mode. This test asserts that the new game
// launched by SAIL AGAIN has an identical assignment map to the
// just-finished game.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:dart_games/constants/test_keys.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/settings_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/dart_throw_helpers.dart';
import '../../shared/results_helpers.dart';
import '../../shared/game_ui_config.dart';

final _config = GameUIConfig.treasureDivide();

/// Taps the next visible "Assign team" trailing button and picks the
/// team at [teamIndex] (0-based) from the crest-picker dialog. Mirrors
/// the dialog flow used by start_button_disabled_team_manual_empty_crew_test.
Future<void> _assignNextPlayerToTeamByIndex(
    WidgetTester tester, int teamIndex) async {
  final assignBtns = find.text('Assign team');
  expect(assignBtns, findsAtLeastNWidgets(1),
      reason: '[DIAG td_sa_pta] "Assign team" button not found');

  await tester.ensureVisible(assignBtns.first);
  await tester.pump();
  await tester.tap(assignBtns.first);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump();

  expect(find.byType(AlertDialog), findsOneWidget,
      reason: '[DIAG td_sa_pta] Team assignment dialog did not open');

  final dialog = find.byType(AlertDialog);
  final gestureDetectors = find.descendant(
    of: dialog,
    matching: find.byType(GestureDetector),
  );
  expect(gestureDetectors, findsAtLeastNWidgets(teamIndex + 1),
      reason:
          '[DIAG td_sa_pta] Not enough team options in dialog for index $teamIndex');

  await tester.tap(gestureDetectors.at(teamIndex));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump();
}

/// Drives a team-mode game to completion by having every crew hit the
/// target every dart, ensuring the game finishes cleanly within its
/// round budget without any all-miss halving events.
Future<void> _playTeamGameToResults(WidgetTester tester) async {
  final provider = ProviderHelpers.getTreasureDivideProvider(tester);

  int iterations = 0;
  while (!provider.hasWinner) {
    if (iterations++ > 100) {
      throw Exception(
          'play_again_preserves_team_assignments_test: safety bound hit '
          '— game did not finish');
    }

    final roundIndex =
        ProviderHelpers.getTreasureDivideCurrentRoundIndex(tester);
    final target =
        ProviderHelpers.getTreasureDivideRoundTarget(tester, roundIndex);
    final dartsThisTurn = provider.currentGame?.dartsThisTurn ?? 3;

    Future<void> throwHit() async {
      if (target == -1) {
        await DartThrowHelpers.throwDartViaMock(tester, 20,
            multiplier: 'double');
      } else if (target == -2) {
        await DartThrowHelpers.throwDartViaMock(tester, 20,
            multiplier: 'triple');
      } else if (target == 25) {
        await DartThrowHelpers.throwDartViaMock(tester, 25,
            multiplier: 'bullseye');
      } else {
        await DartThrowHelpers.throwDartViaMock(tester, target);
      }
    }

    for (int i = 0; i < dartsThisTurn; i++) {
      await throwHit();
    }

    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    if (provider.shouldPromptTakeout) {
      final mockApi = DartThrowHelpers.getMockApi(tester);
      mockApi?.simulateTakeoutFinished();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    tester.binding.takeException();
  }

  await ResultsHelpers.pumpUntilResults(tester, _config);
  tester.binding.takeException();
  tester.binding.takeException();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Results: SAIL AGAIN preserves manual team assignments '
      '(new game has identical playerTeamAssignments)',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, _config);

    // ── Set Team + Manual, 7 rounds (fastest to complete) ────────────
    await SettingsHelpers.setTreasureDivideGameModeTeam(tester);
    await SettingsHelpers.setTreasureDivideAssignmentManual(tester);
    await SettingsHelpers.selectTreasureDivideRounds(tester, 7);

    // ── Add 4 players ────────────────────────────────────────────────
    await UITestHelpers.addPlayer(tester, 'SaP1', _config);
    await UITestHelpers.addPlayer(tester, 'SaP2', _config);
    await UITestHelpers.addPlayer(tester, 'SaP3', _config);
    await UITestHelpers.addPlayer(tester, 'SaP4', _config);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    // ── Assign 2v2: SaP1+SaP2 to team1, SaP3+SaP4 to team2 ───────────
    await _assignNextPlayerToTeamByIndex(tester, 0); // SaP1 → team1
    await _assignNextPlayerToTeamByIndex(tester, 0); // SaP2 → team1
    await _assignNextPlayerToTeamByIndex(tester, 1); // SaP3 → team2
    await _assignNextPlayerToTeamByIndex(tester, 1); // SaP4 → team2

    // ── Capture pre-game team assignments ────────────────────────────
    await UITestHelpers.startGame(tester, _config);
    final providerBefore =
        ProviderHelpers.getTreasureDivideProvider(tester);
    final originalAssignments = Map<String, String>.from(
        providerBefore.currentGame!.playerTeamAssignments);
    expect(originalAssignments.length, 4,
        reason:
            '[DIAG td_sa_pta] Setup: all 4 players must have team assignments');
    expect(originalAssignments.values.toSet().length, 2,
        reason: '[DIAG td_sa_pta] Setup: exactly 2 distinct crews in play');

    // ── Play the game through to the results screen ─────────────────
    await _playTeamGameToResults(tester);
    expect(find.byKey(TreasureDivideResultsKeys.playAgainButton),
        findsOneWidget,
        reason: '[DIAG td_sa_pta] Results screen not shown');

    // ── Click SAIL AGAIN ─────────────────────────────────────────────
    await UITestHelpers.clickPlayAgain(tester, _config);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    // ── Verify we're on the game screen (not the setup screen) ──────
    expect(find.byKey(TreasureDivideGameKeys.treasureMap), findsOneWidget,
        reason:
            '[DIAG td_sa_pta] Treasure map not visible — SAIL AGAIN must '
            'launch straight into a new game');

    // ── Assert new game's team assignments EXACTLY match the previous
    //    game's assignments ─────────────────────────────────────────
    final providerAfter =
        ProviderHelpers.getTreasureDivideProvider(tester);
    final newAssignments = Map<String, String>.from(
        providerAfter.currentGame!.playerTeamAssignments);

    expect(newAssignments, equals(originalAssignments),
        reason:
            '[DIAG td_sa_pta] SAIL AGAIN dropped the manual team assignments. '
            'Expected: $originalAssignments, got: $newAssignments');

    // Also assert the same crew structure at the model level.
    expect(providerAfter.currentGame!.teamPlayers.length, 2,
        reason:
            '[DIAG td_sa_pta] New game must still have exactly 2 crews');

    tester.binding.takeException();
    tester.binding.takeException();
  });
}
