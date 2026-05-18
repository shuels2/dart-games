// integration_test/tiki_golf/visual_validation/tiki_golf_screenshot_test.dart
//
// Screenshot test for Tiki Golf — captures all spec Section 12C visual states.
// Driver: test_driver/screenshot_test.dart (NEVER integration_test.dart)
// DO NOT use pumpAndSettle() — splash CircularProgressIndicator prevents settling.
//
// Structure: ONE `testWidgets` block containing all screenshot capture phases.
// Multiple `testWidgets` in a screenshot test break the
// `integration_test_driver_extended` request/response protocol under
// `-d web-server` (parallel runner) — the driver protocol expects one test
// per file, and 10+ separate testWidgets cause DWDS/webdriver session
// disconnects that surface as `SocketException` at `WebDriver.quit`.
// Match the structure of every other game's screenshot test.

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/pump_sequences.dart';
import '../../shared/settings_helpers.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/element_finders.dart';

import '_helpers.dart' as h;

// ==========================================================================
// SCREENSHOT HELPER
// ==========================================================================

Future<void> _screenshot(IntegrationTestWidgetsFlutterBinding binding,
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

      await _screenshot(binding, tester, '01_menu_solo_default_2players');

      // --- Solo ready (4 players, Max Strokes 4) ---
      await UITestHelpers.addPlayer(tester, 'Lilo', config);
      await UITestHelpers.addPlayer(tester, 'Stitch', config);

      await SettingsHelpers.setTikiGolfMaxStrokes(tester, 4);
      await _screenshot(binding, tester, '02_menu_solo_ready_4players_maxstrokes4');

      // Reset max strokes
      await SettingsHelpers.setTikiGolfMaxStrokes(tester, 3);

      // --- Team mode toggled (Random default, no team boxes) ---
      await SettingsHelpers.setTikiGolfGameModeTeam(tester);
      await PumpSequences.fullRebuild(tester);
      await _screenshot(binding, tester, '03_menu_team_random_default');

      // --- Team Manual 4 players (4 team boxes + per-player crests + Team Count) ---
      await SettingsHelpers.setTikiGolfAssignmentManual(tester);
      await PumpSequences.fullRebuild(tester);
      await _screenshot(binding, tester, '04_menu_team_manual_4players_team_boxes');

      // --- Team Random 4 players (single list, no team boxes) ---
      await SettingsHelpers.setTikiGolfAssignmentRandom(tester);
      await PumpSequences.fullRebuild(tester);
      await _screenshot(binding, tester, '05_menu_team_random_4players_no_boxes');

      // --- Toggling Team Assignment Manual → Random (two back-to-back shots) ---
      await SettingsHelpers.setTikiGolfAssignmentManual(tester);
      await PumpSequences.fullRebuild(tester);
      await _screenshot(binding, tester, '06_menu_toggle_to_manual');

      await SettingsHelpers.setTikiGolfAssignmentRandom(tester);
      await PumpSequences.fullRebuild(tester);
      await _screenshot(binding, tester, '07_menu_toggle_back_to_random');

      // --- Solo mode + Team Assignment greyed out ---
      await SettingsHelpers.setTikiGolfGameModeSolo(tester);
      await PumpSequences.fullRebuild(tester);
      await _screenshot(binding, tester, '08_menu_solo_team_assignment_greyed_out');

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
      await _screenshot(binding, tester, '09_menu_team_manual_3players_team_count_2');

      print('SCREENSHOT: === PART 1 COMPLETE ===');

      // ======================================================================
      // PART 2: GAME SCREEN STATES (SOLO)
      // ======================================================================
      print('SCREENSHOT: === PART 2: GAME SCREEN SOLO STATES ===');

      // Fresh server state for the new game scenario (different player set,
      // different settings — avoid "player already exists" from PART 1).
      await UITestHelpers.resetServerState();

      // --- Solo, start of game, hole 1 (default Max Strokes 3) ---
      await h.setupAndStartGame(
        tester,
        playerNames: ['Moana', 'Maui'],
      );

      final gameActive = ProviderHelpers.isTikiGolfGameActive(tester);
      expect(gameActive, isTrue, reason: 'Game should be active after starting');

      final hole1Target = ProviderHelpers.getTikiGolfHoleTarget(tester, 1);
      print('SCREENSHOT: Hole 1 target = $hole1Target');

      await _screenshot(binding, tester, '10_game_solo_hole1_start');

      // --- Solo, turn advanced to second player (Moana hits; then Maui's turn) ---
      await h.throwDartViaMock(tester, hole1Target);
      await h.simulateTakeout(tester);
      await _screenshot(binding, tester, '11_game_solo_hole1_second_player');

      // --- Continue to mid-game: advance through holes 1-3 for both players ---
      // P2 (Maui): splash hole 1
      await h.throwAllMissesToSplash(tester, maxStrokes: 3);
      await h.simulateTakeout(tester);

      // Holes 2 & 3: both players hit target on dart 1
      for (int hole = 2; hole <= 3; hole++) {
        final target = ProviderHelpers.getTikiGolfHoleTarget(tester, hole);
        await h.throwDartViaMock(tester, target);
        await h.simulateTakeout(tester);
        await h.throwDartViaMock(tester, target);
        await h.simulateTakeout(tester);
      }

      // Now at hole 4 — capture mid-game scorecard filled
      final hole4Target = ProviderHelpers.getTikiGolfHoleTarget(tester, 4);
      print('SCREENSHOT: Hole 4 target = $hole4Target');
      await _screenshot(binding, tester, '12_game_solo_hole4_scorecard_filled');

      // --- Solo, birdie scored (target hit on dart 1 — hole 4 P1) ---
      await h.throwDartViaMock(tester, hole4Target);
      await _screenshot(binding, tester, '13_game_solo_birdie_state');
      await h.simulateTakeout(tester);

      // P2 also hits for this test
      await h.throwDartViaMock(tester, hole4Target);
      await h.simulateTakeout(tester);

      // --- Hole 5: Max Strokes 3 → Splash + takeout modal visible ---
      final hole5Target = ProviderHelpers.getTikiGolfHoleTarget(tester, 5);
      print('SCREENSHOT: Hole 5 target = $hole5Target');
      await h.throwMissViaMock(tester);
      await h.throwMissViaMock(tester);
      await h.throwMissViaMock(tester);
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      await _screenshot(binding, tester, '14_game_solo_splash_takeout_modal');
      await h.simulateTakeout(tester);

      print('SCREENSHOT: === PART 2 COMPLETE ===');

      // ======================================================================
      // PART 3: MULLIGAN STATES (separate game — Mulligan ON)
      // ======================================================================
      print('SCREENSHOT: === PART 3: MULLIGAN STATES ===');

      await UITestHelpers.resetServerState();

      await h.setupAndStartGame(
        tester,
        mulliganEnabled: true,
        playerNames: ['Lilo', 'Stitch'],
      );

      expect(ProviderHelpers.isTikiGolfGameActive(tester), isTrue);

      // Hole 1: Lilo splashes (all 3 misses) → Mulligan button should appear in modal
      await h.throwMissViaMock(tester);
      await h.throwMissViaMock(tester);
      await h.throwMissViaMock(tester);

      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      await tester.pump();

      // Splash + Mulligan modal: shows USE MULLIGAN + NEXT PLAYER buttons
      await _screenshot(binding, tester, '15_game_splash_mulligan_modal_visible');

      // Tap USE MULLIGAN to re-throw
      final useMulliganBtn = ElementFinders.getTikiGolfUseMulliganButton();
      if (useMulliganBtn.evaluate().isNotEmpty) {
        await tester.tap(useMulliganBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump();
        await _screenshot(binding, tester, '16_game_after_mulligan_rethrow');
      } else {
        print('SCREENSHOT: WARNING - USE MULLIGAN button not found');
      }

      print('SCREENSHOT: === PART 3 COMPLETE ===');

      // ======================================================================
      // PART 4: MAX STROKES = 6 STATES
      // ======================================================================
      print('SCREENSHOT: === PART 4: MAX STROKES 6 STATES ===');

      await UITestHelpers.resetServerState();

      await h.setupAndStartGame(
        tester,
        maxStrokes: 6,
        playerNames: ['Moana', 'Maui'],
      );

      expect(ProviderHelpers.isTikiGolfGameActive(tester), isTrue);

      // --- 6 dart indicator slots visible ---
      await _screenshot(binding, tester, '17_game_maxstrokes6_6slots_visible');

      // --- All 6 darts missed → Splash (score = 7) ---
      for (int i = 0; i < 6; i++) {
        await h.throwMissViaMock(tester);
      }
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      await _screenshot(binding, tester, '18_game_maxstrokes6_all_miss_splash7');
      await h.simulateTakeout(tester);

      print('SCREENSHOT: === PART 4 COMPLETE ===');

      // ======================================================================
      // PART 5: TWO BACK-TO-BACK GAMES (verify per-game randomization differs)
      // ======================================================================
      print('SCREENSHOT: === PART 5: TWO BACK-TO-BACK GAMES ===');

      await UITestHelpers.resetServerState();

      // Game 1: navigate and start
      await h.setupAndStartGame(
        tester,
        playerNames: ['Moana', 'Maui'],
      );
      expect(ProviderHelpers.isTikiGolfGameActive(tester), isTrue);

      final game1Hole1Target =
          ProviderHelpers.getTikiGolfHoleTarget(tester, 1);
      print('SCREENSHOT: Game1 hole1 target = $game1Hole1Target');
      await _screenshot(binding, tester, '19_game1_hole1');

      // Rapid-complete game 1: every player hits target on every hole
      var p5Provider = ProviderHelpers.getTikiGolfProvider(tester);
      while (!p5Provider.hasWinner) {
        final hole = ProviderHelpers.getTikiGolfCurrentHole(tester);
        final target = ProviderHelpers.getTikiGolfHoleTarget(tester, hole);
        await h.throwDartViaMock(tester, target);
        await h.simulateTakeout(tester);
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump();
      }

      // Wait for results screen
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
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
      await _screenshot(binding, tester, '20_game2_hole1');

      print('SCREENSHOT: === PART 5 COMPLETE ===');

      // ======================================================================
      // PART 6: TEAM MODE GAME SCREEN STATES
      // ======================================================================
      print('SCREENSHOT: === PART 6: TEAM MODE GAME STATES ===');

      await UITestHelpers.resetServerState();

      // Team mode with 4 players, Random assignment
      await h.setupAndStartGame(
        tester,
        teamMode: true,
        playerNames: ['Moana', 'Maui', 'Lilo', 'Stitch'],
      );

      expect(ProviderHelpers.isTikiGolfGameActive(tester), isTrue);

      // --- Team mode 4 players, hole 1 (Teams panel visible with team 1 highlighted) ---
      final p6Hole1Target =
          ProviderHelpers.getTikiGolfHoleTarget(tester, 1);
      print('SCREENSHOT: Team game hole1 target = $p6Hole1Target');
      await _screenshot(binding, tester, '21_team_game_hole1_team1_highlighted');

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
        await h.throwDartViaMock(tester, p6Hole1Target);
        await h.simulateTakeout(tester);
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump();
      }

      // --- Turn advanced to second team (highlight moves) ---
      await _screenshot(binding, tester, '22_team_game_hole1_team2_highlighted');

      // Complete hole 1 for all remaining teams
      while (ProviderHelpers.getTikiGolfCurrentHole(tester) == 1 &&
          !ProviderHelpers.tikiGolfHasWinner(tester)) {
        final target =
            ProviderHelpers.getTikiGolfHoleTarget(tester, 1);
        await h.throwDartViaMock(tester, target);
        await h.simulateTakeout(tester);
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
          await h.throwDartViaMock(tester, hole2Target);
          await h.simulateTakeout(tester);
          await tester.pump(const Duration(milliseconds: 300));
          await tester.pump();
        }
      }

      // --- Team mode mid-game with team scorecard (hole 3) ---
      if (!ProviderHelpers.tikiGolfHasWinner(tester)) {
        await _screenshot(binding, tester, '23_team_game_mid_team_scorecard');
      }

      print('SCREENSHOT: === PART 6 COMPLETE ===');

      // ======================================================================
      // PART 7: TEAM MODE + MULLIGAN MODAL
      // ======================================================================
      print('SCREENSHOT: === PART 7: TEAM MULLIGAN MODAL ===');

      await UITestHelpers.resetServerState();

      await h.setupAndStartGame(
        tester,
        teamMode: true,
        mulliganEnabled: true,
        playerNames: ['Moana', 'Maui', 'Lilo', 'Stitch'],
      );

      expect(ProviderHelpers.isTikiGolfGameActive(tester), isTrue);

      // Splash the first player (all 3 misses) to trigger mulligan modal
      await h.throwMissViaMock(tester);
      await h.throwMissViaMock(tester);
      await h.throwMissViaMock(tester);
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();

      // --- Team mode: mulligan button visible in the Splash+Mulligan modal ---
      await _screenshot(binding, tester, '24_team_game_mulligan_modal');
      // Dismiss via NEXT PLAYER
      final nextPlayerBtn = ElementFinders.getTikiGolfNextPlayerButton();
      if (nextPlayerBtn.evaluate().isNotEmpty) {
        await tester.tap(nextPlayerBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump();
      } else {
        await h.simulateTakeout(tester);
      }

      print('SCREENSHOT: === PART 7 COMPLETE ===');

      // ======================================================================
      // PART 8: DURING TAKEOUT (RemoveDartsModal visible)
      // ======================================================================
      print('SCREENSHOT: === PART 8: TAKEOUT MODAL ===');

      await UITestHelpers.resetServerState();

      await h.setupAndStartGame(
        tester,
        playerNames: ['Moana', 'Maui'],
      );

      expect(ProviderHelpers.isTikiGolfGameActive(tester), isTrue);

      // Hit the target on dart 1 — turn ends immediately, modal appears
      final p8Hole1Target =
          ProviderHelpers.getTikiGolfHoleTarget(tester, 1);
      await h.throwDartViaMock(tester, p8Hole1Target);

      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      await tester.pump();

      // --- RemoveDartsModal visible (standard flow, no mulligan) ---
      await _screenshot(binding, tester, '25_game_remove_darts_modal');
      await h.simulateTakeout(tester);

      print('SCREENSHOT: === PART 8 COMPLETE ===');

      // ======================================================================
      // PART 9: SOLO RESULTS SCREEN
      // ======================================================================
      print('SCREENSHOT: === PART 9: SOLO RESULTS SCREEN ===');

      await UITestHelpers.resetServerState();

      await h.setupAndStartGame(
        tester,
        playerNames: ['Moana', 'Maui'],
      );

      expect(ProviderHelpers.isTikiGolfGameActive(tester), isTrue);

      // Rapid-complete all 9 holes: both players hit target on dart 1
      var p9Provider = ProviderHelpers.getTikiGolfProvider(tester);
      while (!p9Provider.hasWinner) {
        final hole = ProviderHelpers.getTikiGolfCurrentHole(tester);
        final target = ProviderHelpers.getTikiGolfHoleTarget(tester, hole);
        await h.throwDartViaMock(tester, target);
        await h.simulateTakeout(tester);
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump();
      }

      // Wait for results screen navigation
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();

      // --- Solo winner display ---
      await _screenshot(binding, tester, '26_results_solo_winner');

      print('SCREENSHOT: === PART 9 COMPLETE ===');

      // ======================================================================
      // PART 10: TEAM RESULTS SCREEN
      // ======================================================================
      print('SCREENSHOT: === PART 10: TEAM RESULTS SCREEN ===');

      await UITestHelpers.resetServerState();

      // 4 players team mode
      await h.setupAndStartGame(
        tester,
        teamMode: true,
        playerNames: ['Moana', 'Maui', 'Lilo', 'Stitch'],
      );

      expect(ProviderHelpers.isTikiGolfGameActive(tester), isTrue);

      // Rapid-complete all 9 holes
      var p10Provider = ProviderHelpers.getTikiGolfProvider(tester);
      while (!p10Provider.hasWinner) {
        final hole = ProviderHelpers.getTikiGolfCurrentHole(tester);
        final target = ProviderHelpers.getTikiGolfHoleTarget(tester, hole);
        await h.throwDartViaMock(tester, target);
        await h.simulateTakeout(tester);
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump();
      }

      // Wait for results screen navigation
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();

      // --- Team winner display: team crest + all winning-team players visible ---
      await _screenshot(binding, tester, '27_results_team_winner_crest_roster');

      print('SCREENSHOT: === PART 10 COMPLETE ===');
      print('SCREENSHOT: === ALL SCREENSHOTS CAPTURED ===');
    });
  });
}
