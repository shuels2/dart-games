// integration_test/treasure_divide/results_screen/change_course_preserves_team_assignments_test.dart
//
// Regression test for the "team assignments lost after CHANGE COURSE" bug.
// The results screen passes game.playerTeamAssignments to the menu as
// initialPlayerTeamAssignments; the menu re-hydrates its local
// _playerTeamAssignments field from that; and (after the fix) the
// TeamPlayerListPanel widget seeds its own internal map from the
// menu via the initialTeamAssignments parameter. Without that last
// step the widget mounted with an empty map and the team icons
// disappeared next to each player.
//
// The cleanest end-to-end assertion for "assignments preserved" is:
// SET SAIL! must be ENABLED on the menu after CHANGE COURSE, because
// _canStart's manual-team gate requires every selected player to
// have a team assignment. If any assignment is missing, the button
// stays disabled.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:dart_games/constants/test_keys.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/settings_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/dart_throw_helpers.dart';
import '../../shared/results_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/game_ui_config.dart';

final _config = GameUIConfig.treasureDivide();

Future<void> _assignNextPlayerToTeamByIndex(
    WidgetTester tester, int teamIndex) async {
  final assignBtns = find.text('Assign team');
  expect(assignBtns, findsAtLeastNWidgets(1),
      reason: '[DIAG td_cc_pta] "Assign team" button not found');

  await tester.ensureVisible(assignBtns.first);
  await tester.pump();
  await tester.tap(assignBtns.first);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump();

  expect(find.byType(AlertDialog), findsOneWidget,
      reason: '[DIAG td_cc_pta] Team assignment dialog did not open');

  final dialog = find.byType(AlertDialog);
  final gestureDetectors = find.descendant(
    of: dialog,
    matching: find.byType(GestureDetector),
  );
  expect(gestureDetectors, findsAtLeastNWidgets(teamIndex + 1),
      reason:
          '[DIAG td_cc_pta] Not enough team options in dialog for index $teamIndex');

  await tester.tap(gestureDetectors.at(teamIndex));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump();
}

Future<void> _playTeamGameToResults(WidgetTester tester) async {
  final provider = ProviderHelpers.getTreasureDivideProvider(tester);

  int iterations = 0;
  while (!provider.hasWinner) {
    if (iterations++ > 100) {
      throw Exception(
          'change_course_preserves_team_assignments_test: safety bound hit '
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
  }

  await ResultsHelpers.pumpUntilResults(tester, _config);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Results: CHANGE COURSE preserves manual team assignments — '
      'SET SAIL! stays enabled after menu re-entry',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, _config);

    // ── Set Team + Manual, 7 rounds ──────────────────────────────────
    await SettingsHelpers.setTreasureDivideGameModeTeam(tester);
    await SettingsHelpers.setTreasureDivideAssignmentManual(tester);
    await SettingsHelpers.selectTreasureDivideRounds(tester, 7);

    // ── Add 4 players ────────────────────────────────────────────────
    await UITestHelpers.addPlayer(tester, 'CcP1', _config);
    await UITestHelpers.addPlayer(tester, 'CcP2', _config);
    await UITestHelpers.addPlayer(tester, 'CcP3', _config);
    await UITestHelpers.addPlayer(tester, 'CcP4', _config);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    // ── Assign 2v2: CcP1+CcP2 to team1, CcP3+CcP4 to team2 ───────────
    await _assignNextPlayerToTeamByIndex(tester, 0);
    await _assignNextPlayerToTeamByIndex(tester, 0);
    await _assignNextPlayerToTeamByIndex(tester, 1);
    await _assignNextPlayerToTeamByIndex(tester, 1);

    // ── Capture original assignments before starting the game ────────
    await UITestHelpers.startGame(tester, _config);
    final providerBefore =
        ProviderHelpers.getTreasureDivideProvider(tester);
    final originalAssignments = Map<String, String>.from(
        providerBefore.currentGame!.playerTeamAssignments);
    expect(originalAssignments.length, 4,
        reason:
            '[DIAG td_cc_pta] Setup: all 4 players must have team assignments');

    // ── Play to results ──────────────────────────────────────────────
    await _playTeamGameToResults(tester);
    expect(find.byKey(TreasureDivideResultsKeys.changeSettingsButton),
        findsOneWidget,
        reason:
            '[DIAG td_cc_pta] CHANGE COURSE button not found — results screen not loaded');

    // ── Click CHANGE COURSE ──────────────────────────────────────────
    await UITestHelpers.clickChangeSettings(tester, _config);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    // ── We should be on the menu ─────────────────────────────────────
    final startButton = ElementFinders.getTreasureDivideStartButton();
    expect(startButton, findsOneWidget,
        reason:
            '[DIAG td_cc_pta] SET SAIL! button not found — menu did not '
            'load after CHANGE COURSE');

    // ── The critical assertion: SET SAIL! is ENABLED.
    //    _canStart's team-manual gate blocks the button whenever any
    //    selected player is missing a team assignment. If any of the
    //    4 assignments were lost on the round-trip, this expect fails.
    final btn = tester.widget<ElevatedButton>(startButton);
    expect(btn.onPressed, isNotNull,
        reason:
            '[DIAG td_cc_pta] SET SAIL! is DISABLED — a team assignment '
            'must have been dropped in the CHANGE COURSE round-trip. '
            'Original: $originalAssignments');

  });
}
