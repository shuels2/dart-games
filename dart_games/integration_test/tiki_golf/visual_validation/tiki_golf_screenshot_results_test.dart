// integration_test/tiki_golf/visual_validation/tiki_golf_screenshot_results_test.dart
//
// Screenshot test for Tiki Golf — team mode, takeout modal, and results
// screens (spec §12C PARTS 6-10). PARTS 1-5 (menu + solo gameplay) live in
// the sibling `tiki_golf_screenshot_test.dart`. The split is necessary
// because the parallel UI runner has a 600s per-file poll timeout
// (run_ui_tests_parallel_worker.bat) and the combined PARTS 1-10 with two
// full 9-hole rapid-completion loops (in PARTS 9 and 10) exceeded that
// budget.
//
// Driver: test_driver/screenshot_test.dart (NEVER integration_test.dart)
// DO NOT use pumpAndSettle() — splash CircularProgressIndicator prevents settling.
//
// Structure: ONE `testWidgets` block per file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';
import 'package:dart_games/constants/test_keys.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/pump_sequences.dart';
import '../../shared/settings_helpers.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/element_finders.dart';

// Helpers are inlined below — both their interface AND their bodies. Past
// failures showed that even importing shared/dart_throw_helpers.dart or
// shared/game_setup_helpers.dart from a screenshot test (under parallel
// `-d web-server` mode) triggers the same `SocketException` at
// `WebDriver.quit` ~14s in that we saw with `_helpers.dart` and with multiple
// `testWidgets`. The screenshot-driver web-compile path has a cache hazard
// with helper imports that the integration_test driver doesn't share. Every
// other game's screenshot test (Gladiator, Pirate's Grid, Lunar Lander,
// Reef Royale, Clockwork Quest) inlines helper BODIES — talking directly to
// `mock_scolia_api_service` — and passes in parallel. Match that pattern.

// ==========================================================================
// HELPER METHODS (inline for screenshot test)
// ==========================================================================

MockScoliaApiService? getMockApi(WidgetTester tester) {
  final dartboardProvider = ProviderHelpers.getDartboardProvider(tester);
  return dartboardProvider.apiService;
}

Future<void> throwDartViaMock(WidgetTester tester, int number,
    {String multiplier = 'single'}) async {
  final mockApi = getMockApi(tester);
  if (mockApi != null) {
    mockApi.simulateDartThrow(
      score: number *
          (multiplier == 'double'
              ? 2
              : multiplier == 'triple'
                  ? 3
                  : 1),
      multiplier: multiplier,
      playerName: 'Player',
      baseScore: number,
      widgetX: 125.0,
      widgetY: 125.0,
      widgetSize: 250.0,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    await tester.pump();
    await tester.pump();
  }
}

Future<void> throwMissViaMock(WidgetTester tester) async {
  final mockApi = getMockApi(tester);
  if (mockApi != null) {
    mockApi.simulateDartThrow(
      score: 0,
      multiplier: 'miss',
      playerName: 'Player',
      baseScore: 0,
      widgetX: 125.0,
      widgetY: 125.0,
      widgetSize: 250.0,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    await tester.pump();
    await tester.pump();
  }
}

/// Simulate takeout (darts removed) via the mock API. Tiki Golf fires the
/// RemoveDartsModal only on turn-end; this helper confirms
/// `shouldPromptTakeout` before triggering so screenshots don't try to
/// dismiss a modal that never appeared.
Future<void> simulateTakeout(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 1));
  await tester.pump();

  final provider = ProviderHelpers.getTikiGolfProvider(tester);
  if (provider.shouldPromptTakeout) {
    // ignore: avoid_print
    print('SCREENSHOT: Simulating takeout via mock API...');
    final mockApi = getMockApi(tester);
    mockApi?.simulateTakeoutFinished();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    await tester.pump();
    await tester.pump();
  } else {
    // ignore: avoid_print
    print('SCREENSHOT: WARNING - shouldPromptTakeout is false, skipping takeout');
  }
}

/// Throw all [maxStrokes] darts as misses, ending the current player's turn
/// with a Splash. Leaves `shouldPromptTakeout = true`.
Future<void> throwAllMissesToSplash(WidgetTester tester,
    {int maxStrokes = 3}) async {
  for (int i = 0; i < maxStrokes; i++) {
    await throwMissViaMock(tester);
  }
}

/// Navigate to the Tiki Golf menu, apply settings, add the given players,
/// and start the game. Inlined from `GameSetupHelpers.setupAndStartTikiGolf`
/// (importing shared/game_setup_helpers.dart from a screenshot test triggers
/// the parallel-mode webdriver crash — see header note).
Future<void> setupAndStartGame(
  WidgetTester tester,
  GameUIConfig config, {
  int maxStrokes = 3,
  bool mulliganEnabled = false,
  bool teamMode = false,
  bool manualAssignment = false,
  List<String>? playerNames,
}) async {
  await UITestHelpers.navigateToGameMenu(tester, config);

  if (teamMode) {
    await SettingsHelpers.setTikiGolfGameModeTeam(tester);
    await PumpSequences.fullRebuild(tester);
    if (manualAssignment) {
      await SettingsHelpers.setTikiGolfAssignmentManual(tester);
      await PumpSequences.fullRebuild(tester);
    }
  }
  if (maxStrokes != 3) {
    await SettingsHelpers.setTikiGolfMaxStrokes(tester, maxStrokes);
  }
  if (mulliganEnabled) {
    await SettingsHelpers.toggleTikiGolfMulligan(tester);
  }

  final names = playerNames ?? ['Player A', 'Player B'];
  for (final name in names) {
    await UITestHelpers.addPlayer(tester, name, config);
  }

  await UITestHelpers.startGame(tester, config);
}

/// Take screenshot with extra pumps to ensure rendering is current.
/// CRITICAL: Uses binding.takeScreenshot() — must use screenshot_test.dart driver.
/// Do NOT use pumpAndSettle() — continuous animations prevent settling.
Future<void> screenshot(IntegrationTestWidgetsFlutterBinding binding,
    WidgetTester tester, String name) async {
  await tester.pump(const Duration(seconds: 2));
  await tester.pump();
  await tester.pump();
  await tester.pump();
  // ignore: avoid_print
  print('SCREENSHOT: Taking screenshot: $name');
  await binding.takeScreenshot(name);
}

// ==========================================================================
// MAIN
// ==========================================================================

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final config = GameUIConfig.tikiGolf();

  group('Tiki Golf - Results Screenshot Capture', () {
    setUp(() async {
      await UITestHelpers.resetServerState();
    });

    testWidgets('Results screenshot flow', (WidgetTester tester) async {
      // ======================================================================
      // PART 6: TEAM MODE GAME SCREEN STATES
      // ======================================================================
      print('SCREENSHOT: === PART 6: TEAM MODE GAME STATES ===');

      await UITestHelpers.resetServerState();

      // Team mode with 4 players, Random assignment
      await setupAndStartGame(
        tester,
        config,
        teamMode: true,
        playerNames: ['Moana', 'Maui', 'Lilo', 'Stitch'],
      );

      expect(ProviderHelpers.isTikiGolfGameActive(tester), isTrue);

      // --- Team mode 4 players, hole 1 (Teams panel visible with team 1 highlighted) ---
      final p6Hole1Target =
          ProviderHelpers.getTikiGolfHoleTarget(tester, 1);
      print('SCREENSHOT: Team game hole1 target = $p6Hole1Target');
      await screenshot(binding, tester, '21_team_game_hole1_team1_highlighted');

      // --- Advance through team 1's players on hole 1 ---
      bool movedToTeam2 = false;
      final team1Id = ProviderHelpers.getTikiGolfCurrentTeamId(tester);
      print('SCREENSHOT: Team 1 id = $team1Id');

      // Throw for all players on team 1
      while (!movedToTeam2 && !ProviderHelpers.tikiGolfHasWinner(tester)) {
        final currentTeam =
            ProviderHelpers.getTikiGolfCurrentTeamId(tester);
        if (currentTeam != team1Id) {
          movedToTeam2 = true;
          break;
        }
        await throwDartViaMock(tester, p6Hole1Target);
        await simulateTakeout(tester);
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump();
      }

      // --- Turn advanced to second team (highlight moves) ---
      await screenshot(binding, tester, '22_team_game_hole1_team2_highlighted');

      // Complete hole 1 for all remaining teams
      while (ProviderHelpers.getTikiGolfCurrentHole(tester) == 1 &&
          !ProviderHelpers.tikiGolfHasWinner(tester)) {
        final target =
            ProviderHelpers.getTikiGolfHoleTarget(tester, 1);
        await throwDartViaMock(tester, target);
        await simulateTakeout(tester);
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump();
      }

      // Advance through hole 2
      if (!ProviderHelpers.tikiGolfHasWinner(tester) &&
          ProviderHelpers.getTikiGolfCurrentHole(tester) == 2) {
        final hole2Target =
            ProviderHelpers.getTikiGolfHoleTarget(tester, 2);
        while (ProviderHelpers.getTikiGolfCurrentHole(tester) == 2 &&
            !ProviderHelpers.tikiGolfHasWinner(tester)) {
          await throwDartViaMock(tester, hole2Target);
          await simulateTakeout(tester);
          await tester.pump(const Duration(milliseconds: 300));
          await tester.pump();
        }
      }

      // --- Team mode mid-game with team scorecard (hole 3) ---
      if (!ProviderHelpers.tikiGolfHasWinner(tester)) {
        await screenshot(binding, tester, '23_team_game_mid_team_scorecard');
      }

      print('SCREENSHOT: === PART 6 COMPLETE ===');

      // ======================================================================
      // PART 7: TEAM MODE + MULLIGAN MODAL
      // ======================================================================
      print('SCREENSHOT: === PART 7: TEAM MULLIGAN MODAL ===');

      await UITestHelpers.resetServerState();

      await setupAndStartGame(
        tester,
        config,
        teamMode: true,
        mulliganEnabled: true,
        playerNames: ['Moana', 'Maui', 'Lilo', 'Stitch'],
      );

      expect(ProviderHelpers.isTikiGolfGameActive(tester), isTrue);

      // Splash the first player (all 3 misses) to trigger mulligan modal
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();

      // --- Team mode: mulligan button visible in the Splash+Mulligan modal ---
      await screenshot(binding, tester, '24_team_game_mulligan_modal');
      // Dismiss via NEXT PLAYER
      final nextPlayerBtn = ElementFinders.getTikiGolfNextPlayerButton();
      if (nextPlayerBtn.evaluate().isNotEmpty) {
        await tester.tap(nextPlayerBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump();
      } else {
        await simulateTakeout(tester);
      }

      print('SCREENSHOT: === PART 7 COMPLETE ===');

      // ======================================================================
      // PART 8: DURING TAKEOUT (RemoveDartsModal visible)
      // ======================================================================
      print('SCREENSHOT: === PART 8: TAKEOUT MODAL ===');

      await UITestHelpers.resetServerState();

      await setupAndStartGame(
        tester,
        config,
        playerNames: ['Moana', 'Maui'],
      );

      expect(ProviderHelpers.isTikiGolfGameActive(tester), isTrue);

      // Hit the target on dart 1 — turn ends immediately, modal appears
      final p8Hole1Target =
          ProviderHelpers.getTikiGolfHoleTarget(tester, 1);
      await throwDartViaMock(tester, p8Hole1Target);

      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      await tester.pump();

      // --- RemoveDartsModal visible (standard flow, no mulligan) ---
      await screenshot(binding, tester, '25_game_remove_darts_modal');
      await simulateTakeout(tester);

      print('SCREENSHOT: === PART 8 COMPLETE ===');

      // ======================================================================
      // PART 9: SOLO RESULTS SCREEN
      // ======================================================================
      print('SCREENSHOT: === PART 9: SOLO RESULTS SCREEN ===');

      await UITestHelpers.resetServerState();

      await setupAndStartGame(
        tester,
        config,
        playerNames: ['Moana', 'Maui'],
      );

      expect(ProviderHelpers.isTikiGolfGameActive(tester), isTrue);

      // Rapid-complete all 9 holes: both players hit target on dart 1
      var p9Provider = ProviderHelpers.getTikiGolfProvider(tester);
      while (!p9Provider.hasWinner) {
        final hole = ProviderHelpers.getTikiGolfCurrentHole(tester);
        final target = ProviderHelpers.getTikiGolfHoleTarget(tester, hole);
        await throwDartViaMock(tester, target);
        await simulateTakeout(tester);
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump();
      }

      // Wait for results screen navigation
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();

      // --- Solo winner display ---
      await screenshot(binding, tester, '26_results_solo_winner');

      print('SCREENSHOT: === PART 9 COMPLETE ===');

      // ======================================================================
      // PART 10: TEAM RESULTS SCREEN
      // ======================================================================
      print('SCREENSHOT: === PART 10: TEAM RESULTS SCREEN ===');

      await UITestHelpers.resetServerState();

      // 4 players team mode
      await setupAndStartGame(
        tester,
        config,
        teamMode: true,
        playerNames: ['Moana', 'Maui', 'Lilo', 'Stitch'],
      );

      expect(ProviderHelpers.isTikiGolfGameActive(tester), isTrue);

      // Rapid-complete all 9 holes
      var p10Provider = ProviderHelpers.getTikiGolfProvider(tester);
      while (!p10Provider.hasWinner) {
        final hole = ProviderHelpers.getTikiGolfCurrentHole(tester);
        final target = ProviderHelpers.getTikiGolfHoleTarget(tester, hole);
        await throwDartViaMock(tester, target);
        await simulateTakeout(tester);
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump();
      }

      // Wait for results screen navigation
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();

      // --- Team winner display: team crest + all winning-team players visible ---
      await screenshot(binding, tester, '27_results_team_winner_crest_roster');

      print('SCREENSHOT: === PART 10 COMPLETE ===');
      print('SCREENSHOT: === ALL SCREENSHOTS CAPTURED ===');
    });
  });
}
