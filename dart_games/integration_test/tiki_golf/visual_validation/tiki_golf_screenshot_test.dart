// integration_test/tiki_golf/visual_validation/tiki_golf_screenshot_test.dart
//
// Screenshot test for Tiki Golf — captures menu + solo gameplay visual states
// (spec §12C PARTS 1-5). The remaining PARTS (6-10: team mode, modals,
// results) live in `tiki_golf_screenshot_results_test.dart`. The split is
// necessary because the parallel UI runner has a 600s per-file poll timeout
// (run_ui_tests_parallel_worker.bat) and the combined PARTS 1-10 with two
// full 9-hole rapid-completion loops exceeded that budget.
//
// Driver: test_driver/screenshot_test.dart (NEVER integration_test.dart)
// DO NOT use pumpAndSettle() — splash CircularProgressIndicator prevents settling.
//
// Structure: ONE `testWidgets` block per file (the
// integration_test_driver_extended protocol expects one test per file under
// `-d web-server`; multiple blocks cause DWDS/webdriver session disconnects
// that surface as `SocketException` at `WebDriver.quit`).

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

  group('Tiki Golf - Screenshot Capture', () {
    setUp(() async {
      await UITestHelpers.resetServerState();
    });

    // Single continuous flow capturing all spec §12C visual states.
    // See file header for why this is one testWidgets instead of many.
    testWidgets('Full screenshot flow', (WidgetTester tester) async {
      // ======================================================================
      // PART 1: MENU SCREEN STATES
      // ======================================================================
      print('SCREENSHOT: === PART 1: MENU SCREEN STATES ===');

      // --- Solo default (2 players, default settings) ---
      await UITestHelpers.navigateToGameMenu(tester, config);
      print('SCREENSHOT: Navigated to menu');

      await UITestHelpers.addPlayer(tester, 'Moana', config);
      await UITestHelpers.addPlayer(tester, 'Maui', config);

      final selectedPlayers = ProviderHelpers.getSelectedPlayers(tester);
      expect(selectedPlayers.length, greaterThanOrEqualTo(2));
      final p1Id = selectedPlayers[0].id;
      final p2Id = selectedPlayers[1].id;
      print('SCREENSHOT: P1=$p1Id P2=$p2Id');

      await screenshot(binding, tester, '01_menu_solo_default_2players');

      // --- Solo ready (4 players, Max Strokes 4) ---
      await UITestHelpers.addPlayer(tester, 'Lilo', config);
      await UITestHelpers.addPlayer(tester, 'Stitch', config);

      await SettingsHelpers.setTikiGolfMaxStrokes(tester, 4);
      await screenshot(binding, tester, '02_menu_solo_ready_4players_maxstrokes4');

      // Reset max strokes
      await SettingsHelpers.setTikiGolfMaxStrokes(tester, 3);

      // --- Team mode toggled (Random default, no team boxes) ---
      await SettingsHelpers.setTikiGolfGameModeTeam(tester);
      await PumpSequences.fullRebuild(tester);
      await screenshot(binding, tester, '03_menu_team_random_default');

      // --- Team Manual 4 players (4 team boxes + per-player crests + Team Count) ---
      await SettingsHelpers.setTikiGolfAssignmentManual(tester);
      await PumpSequences.fullRebuild(tester);
      await screenshot(binding, tester, '04_menu_team_manual_4players_team_boxes');

      // --- Team Random 4 players (single list, no team boxes) ---
      await SettingsHelpers.setTikiGolfAssignmentRandom(tester);
      await PumpSequences.fullRebuild(tester);
      await screenshot(binding, tester, '05_menu_team_random_4players_no_boxes');

      // --- Toggling Team Assignment Manual → Random (two back-to-back shots) ---
      await SettingsHelpers.setTikiGolfAssignmentManual(tester);
      await PumpSequences.fullRebuild(tester);
      await screenshot(binding, tester, '06_menu_toggle_to_manual');

      await SettingsHelpers.setTikiGolfAssignmentRandom(tester);
      await PumpSequences.fullRebuild(tester);
      await screenshot(binding, tester, '07_menu_toggle_back_to_random');

      // --- Solo mode + Team Assignment greyed out ---
      await SettingsHelpers.setTikiGolfGameModeSolo(tester);
      await PumpSequences.fullRebuild(tester);
      await screenshot(binding, tester, '08_menu_solo_team_assignment_greyed_out');

      // --- Team mode + 3 players + Team Count = 2 (minimum config) ---
      await SettingsHelpers.setTikiGolfGameModeTeam(tester);
      await PumpSequences.fullRebuild(tester);
      await SettingsHelpers.setTikiGolfAssignmentManual(tester);
      await PumpSequences.fullRebuild(tester);
      // Team Count = 2: find the dropdown and select 2
      final teamCntFinder = ElementFinders.getTikiGolfTeamCountDropdown();
      if (teamCntFinder.evaluate().isNotEmpty) {
        await tester.tap(teamCntFinder);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        final opt2 = find.text('2').last;
        if (opt2.evaluate().isNotEmpty) {
          await tester.tap(opt2);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
        }
      }
      await screenshot(binding, tester, '09_menu_team_manual_3players_team_count_2');

      print('SCREENSHOT: === PART 1 COMPLETE ===');


      // ======================================================================
      // PART 2: GAME SCREEN STATES (SOLO)
      // ======================================================================
      print('SCREENSHOT: === PART 2: GAME SCREEN SOLO STATES ===');

      // Fresh server state for the new game scenario (different player set,
      // different settings — avoid "player already exists" from PART 1).
      await UITestHelpers.resetServerState();

      // --- Solo, start of game, hole 1 (default Max Strokes 3) ---
      await setupAndStartGame(
        tester,
        config,
        playerNames: ['Moana', 'Maui'],
      );

      final gameActive = ProviderHelpers.isTikiGolfGameActive(tester);
      expect(gameActive, isTrue, reason: 'Game should be active after starting');

      final hole1Target = ProviderHelpers.getTikiGolfHoleTarget(tester, 1);
      print('SCREENSHOT: Hole 1 target = $hole1Target');

      await screenshot(binding, tester, '10_game_solo_hole1_start');

      // --- Solo, turn advanced to second player (Moana hits; then Maui's turn) ---
      await throwDartViaMock(tester, hole1Target);
      await simulateTakeout(tester);
      await screenshot(binding, tester, '11_game_solo_hole1_second_player');

      // --- Continue to mid-game: advance through holes 1-3 for both players ---
      // P2 (Maui): splash hole 1
      await throwAllMissesToSplash(tester, maxStrokes: 3);
      await simulateTakeout(tester);

      // Holes 2 & 3: both players hit target on dart 1
      for (int hole = 2; hole <= 3; hole++) {
        final target = ProviderHelpers.getTikiGolfHoleTarget(tester, hole);
        await throwDartViaMock(tester, target);
        await simulateTakeout(tester);
        await throwDartViaMock(tester, target);
        await simulateTakeout(tester);
      }

      // Now at hole 4 — capture mid-game scorecard filled
      final hole4Target = ProviderHelpers.getTikiGolfHoleTarget(tester, 4);
      print('SCREENSHOT: Hole 4 target = $hole4Target');
      await screenshot(binding, tester, '12_game_solo_hole4_scorecard_filled');

      // --- Solo, birdie scored (target hit on dart 1 — hole 4 P1) ---
      await throwDartViaMock(tester, hole4Target);
      await screenshot(binding, tester, '13_game_solo_birdie_state');
      await simulateTakeout(tester);

      // P2 also hits for this test
      await throwDartViaMock(tester, hole4Target);
      await simulateTakeout(tester);

      // --- Hole 5: Max Strokes 3 → Splash + takeout modal visible ---
      final hole5Target = ProviderHelpers.getTikiGolfHoleTarget(tester, 5);
      print('SCREENSHOT: Hole 5 target = $hole5Target');
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      await screenshot(binding, tester, '14_game_solo_splash_takeout_modal');
      await simulateTakeout(tester);

      print('SCREENSHOT: === PART 2 COMPLETE ===');

      // ======================================================================
      // PART 3: MULLIGAN STATES (separate game — Mulligan ON)
      // ======================================================================
      print('SCREENSHOT: === PART 3: MULLIGAN STATES ===');

      await UITestHelpers.resetServerState();

      await setupAndStartGame(
        tester,
        config,
        mulliganEnabled: true,
        playerNames: ['Lilo', 'Stitch'],
      );

      expect(ProviderHelpers.isTikiGolfGameActive(tester), isTrue);

      // Hole 1: Lilo splashes (all 3 misses) → Mulligan button should appear in modal
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);

      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      await tester.pump();

      // Splash + Mulligan modal: shows USE MULLIGAN + NEXT PLAYER buttons
      await screenshot(binding, tester, '15_game_splash_mulligan_modal_visible');

      // Tap USE MULLIGAN to re-throw
      final useMulliganBtn = ElementFinders.getTikiGolfUseMulliganButton();
      if (useMulliganBtn.evaluate().isNotEmpty) {
        await tester.tap(useMulliganBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump();
        await screenshot(binding, tester, '16_game_after_mulligan_rethrow');
      } else {
        print('SCREENSHOT: WARNING - USE MULLIGAN button not found');
      }

      print('SCREENSHOT: === PART 3 COMPLETE ===');

      // ======================================================================
      // PART 4: MAX STROKES = 6 STATES
      // ======================================================================
      print('SCREENSHOT: === PART 4: MAX STROKES 6 STATES ===');

      await UITestHelpers.resetServerState();

      await setupAndStartGame(
        tester,
        config,
        maxStrokes: 6,
        playerNames: ['Moana', 'Maui'],
      );

      expect(ProviderHelpers.isTikiGolfGameActive(tester), isTrue);

      // --- 6 dart indicator slots visible ---
      await screenshot(binding, tester, '17_game_maxstrokes6_6slots_visible');

      // --- All 6 darts missed → Splash (score = 7) ---
      for (int i = 0; i < 6; i++) {
        await throwMissViaMock(tester);
      }
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      await screenshot(binding, tester, '18_game_maxstrokes6_all_miss_splash7');
      await simulateTakeout(tester);

      print('SCREENSHOT: === PART 4 COMPLETE ===');

      // ======================================================================
      // PART 5: TWO BACK-TO-BACK GAMES (verify per-game randomization differs)
      // ======================================================================
      print('SCREENSHOT: === PART 5: TWO BACK-TO-BACK GAMES ===');

      await UITestHelpers.resetServerState();

      // Game 1: navigate and start
      await setupAndStartGame(
        tester,
        config,
        playerNames: ['Moana', 'Maui'],
      );
      expect(ProviderHelpers.isTikiGolfGameActive(tester), isTrue);

      final game1Hole1Target =
          ProviderHelpers.getTikiGolfHoleTarget(tester, 1);
      print('SCREENSHOT: Game1 hole1 target = $game1Hole1Target');
      await screenshot(binding, tester, '19_game1_hole1');

      // Rapid-complete game 1: every player hits target on every hole
      var p5Provider = ProviderHelpers.getTikiGolfProvider(tester);
      while (!p5Provider.hasWinner) {
        final hole = ProviderHelpers.getTikiGolfCurrentHole(tester);
        final target = ProviderHelpers.getTikiGolfHoleTarget(tester, hole);
        await throwDartViaMock(tester, target);
        await simulateTakeout(tester);
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump();
      }

      // Wait for results screen
      // Robust wait: poll until the results screen has rendered, instead of a
      // fixed pump that races the event-driven victory navigation under load.
      for (int _i = 0; _i < 100; _i++) {
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump();
        if (ElementFinders.getTikiGolfPlayAgainButton().evaluate().isNotEmpty) {
          break;
        }
      }
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      // Game 2: tap PLAY AGAIN
      final playAgainBtn = ElementFinders.getTikiGolfPlayAgainButton();
      expect(playAgainBtn, findsOneWidget,
          reason: 'Play Again button should be on results screen');
      await tester.tap(playAgainBtn);
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();

      final game2Hole1Target =
          ProviderHelpers.getTikiGolfHoleTarget(tester, 1);
      print('SCREENSHOT: Game2 hole1 target = $game2Hole1Target');
      await screenshot(binding, tester, '20_game2_hole1');

      print('SCREENSHOT: === PART 5 COMPLETE ===');
    });
  });
}
