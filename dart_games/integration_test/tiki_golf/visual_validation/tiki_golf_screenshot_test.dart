// integration_test/tiki_golf/visual_validation/tiki_golf_screenshot_test.dart
//
// Screenshot test for Tiki Golf — captures all spec Section 12C visual states.
// Driver: test_driver/screenshot_test.dart (NEVER integration_test.dart)
// DO NOT use pumpAndSettle() — splash CircularProgressIndicator prevents settling.
// Phase 9: failure-screenshot wraps removed per Rule §38.

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

    // ========================================================================
    // PART 1: MENU SCREEN STATES
    // ========================================================================

    testWidgets('Menu screen states', (WidgetTester tester) async {
      print('SCREENSHOT: === MENU SCREEN STATES ===');

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

      print('SCREENSHOT: === MENU SCREEN STATES COMPLETE ===');
    });

    // ========================================================================
    // PART 2: GAME SCREEN STATES (SOLO)
    // ========================================================================

    testWidgets('Game screen solo states', (WidgetTester tester) async {
      print('SCREENSHOT: === GAME SCREEN SOLO STATES ===');

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
      // Throw target on dart 1 (birdie), takeout, now it's player 2's turn
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
        // P1 (Moana)
        await h.throwDartViaMock(tester, target);
        await h.simulateTakeout(tester);
        // P2 (Maui)
        await h.throwDartViaMock(tester, target);
        await h.simulateTakeout(tester);
      }

      // Now at hole 4 — capture mid-game scorecard filled
      final hole4Target = ProviderHelpers.getTikiGolfHoleTarget(tester, 4);
      print('SCREENSHOT: Hole 4 target = $hole4Target');
      await _screenshot(binding, tester, '12_game_solo_hole4_scorecard_filled');

      // --- Solo, birdie scored (target hit on dart 1 — hole 4 P1) ---
      // P1 hits target immediately
      await h.throwDartViaMock(tester, hole4Target);
      // Before takeout: dart indicator shows 1 filled slot — birdie state
      await _screenshot(binding, tester, '13_game_solo_birdie_state');
      await h.simulateTakeout(tester);

      // P2 also hits for this test
      await h.throwDartViaMock(tester, hole4Target);
      await h.simulateTakeout(tester);

      // --- Hole 5: Max Strokes 3 → Splash + takeout modal visible ---
      // P1: throw all misses → Splash, modal shows
      final hole5Target = ProviderHelpers.getTikiGolfHoleTarget(tester, 5);
      print('SCREENSHOT: Hole 5 target = $hole5Target');
      await h.throwMissViaMock(tester);
      await h.throwMissViaMock(tester);
      await h.throwMissViaMock(tester);
      // After all 3 misses, takeout modal should appear
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      await _screenshot(binding, tester, '14_game_solo_splash_takeout_modal');
      await h.simulateTakeout(tester);

      print('SCREENSHOT: === GAME SCREEN SOLO STATES COMPLETE ===');
    });

    // ========================================================================
    // PART 3: MULLIGAN STATES (separate game — Mulligan ON)
    // ========================================================================

    testWidgets('Mulligan states', (WidgetTester tester) async {
      print('SCREENSHOT: === MULLIGAN STATES ===');

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
        // After mulligan: player gets to throw again — mulligan button gone
        await _screenshot(binding, tester, '16_game_after_mulligan_rethrow');
      } else {
        print('SCREENSHOT: WARNING - USE MULLIGAN button not found');
      }

      print('SCREENSHOT: === MULLIGAN STATES COMPLETE ===');
    });

    // ========================================================================
    // PART 4: MAX STROKES = 6 STATES
    // ========================================================================

    testWidgets('Max Strokes 6 states', (WidgetTester tester) async {
      print('SCREENSHOT: === MAX STROKES 6 STATES ===');

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
      // After 6 misses: takeout modal showing stroke count 7
      await _screenshot(binding, tester, '18_game_maxstrokes6_all_miss_splash7');
      await h.simulateTakeout(tester);

      print('SCREENSHOT: === MAX STROKES 6 STATES COMPLETE ===');
    });

    // ========================================================================
    // PART 5: TWO BACK-TO-BACK GAMES (verify per-game randomization differs)
    // ========================================================================

    testWidgets('Two back-to-back games', (WidgetTester tester) async {
      print('SCREENSHOT: === TWO BACK-TO-BACK GAMES ===');

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
      final provider = ProviderHelpers.getTikiGolfProvider(tester);
      while (!provider.hasWinner) {
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
      // Note: targets may or may not differ (random), but images are shuffled separately

      print('SCREENSHOT: === TWO BACK-TO-BACK GAMES COMPLETE ===');
    });

    // ========================================================================
    // PART 6: TEAM MODE GAME SCREEN STATES
    // ========================================================================

    testWidgets('Team mode game screen states', (WidgetTester tester) async {
      print('SCREENSHOT: === TEAM MODE GAME STATES ===');

      // Team mode with 4 players, Random assignment
      await h.setupAndStartGame(
        tester,
        teamMode: true,
        playerNames: ['Moana', 'Maui', 'Lilo', 'Stitch'],
      );

      expect(ProviderHelpers.isTikiGolfGameActive(tester), isTrue);

      // --- Team mode 4 players, hole 1 (Teams panel visible with team 1 highlighted) ---
      final hole1Target =
          ProviderHelpers.getTikiGolfHoleTarget(tester, 1);
      print('SCREENSHOT: Team game hole1 target = $hole1Target');
      await _screenshot(binding, tester, '21_team_game_hole1_team1_highlighted');

      // --- Advance through team 1's players on hole 1 ---
      // Each player hits target on dart 1
      // Team 1 has (at least) 2 players in a 4-player Random game [2,2]
      // We don't know how many players are on each team — use shouldPromptTakeout
      // to detect turn-end after each dart hit.
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
        await h.throwDartViaMock(tester, hole1Target);
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

      // --- Team mode mulligan visible: restart with mulligan on ---
      // (Captured in a separate test below)

      print('SCREENSHOT: === TEAM MODE GAME STATES COMPLETE ===');
    });

    // ========================================================================
    // PART 7: TEAM MODE + MULLIGAN MODAL
    // ========================================================================

    testWidgets('Team mode mulligan modal', (WidgetTester tester) async {
      print('SCREENSHOT: === TEAM MULLIGAN MODAL ===');

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
        // Fallback: standard takeout
        await h.simulateTakeout(tester);
      }

      print('SCREENSHOT: === TEAM MULLIGAN MODAL COMPLETE ===');
    });

    // ========================================================================
    // PART 8: DURING TAKEOUT (RemoveDartsModal visible)
    // ========================================================================

    testWidgets('During takeout modal', (WidgetTester tester) async {
      print('SCREENSHOT: === TAKEOUT MODAL ===');

      await h.setupAndStartGame(
        tester,
        playerNames: ['Moana', 'Maui'],
      );

      expect(ProviderHelpers.isTikiGolfGameActive(tester), isTrue);

      // Hit the target on dart 1 — turn ends immediately, modal appears
      final hole1Target =
          ProviderHelpers.getTikiGolfHoleTarget(tester, 1);
      await h.throwDartViaMock(tester, hole1Target);

      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      await tester.pump();

      // --- RemoveDartsModal visible (standard flow, no mulligan) ---
      await _screenshot(binding, tester, '25_game_remove_darts_modal');
      await h.simulateTakeout(tester);

      print('SCREENSHOT: === TAKEOUT MODAL COMPLETE ===');
    });

    // ========================================================================
    // PART 9: RESULTS SCREEN STATES
    // ========================================================================

    testWidgets('Solo results screen', (WidgetTester tester) async {
      print('SCREENSHOT: === SOLO RESULTS SCREEN ===');

      await h.setupAndStartGame(
        tester,
        playerNames: ['Moana', 'Maui'],
      );

      expect(ProviderHelpers.isTikiGolfGameActive(tester), isTrue);

      // Rapid-complete all 9 holes: both players hit target on dart 1
      final provider = ProviderHelpers.getTikiGolfProvider(tester);
      while (!provider.hasWinner) {
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

      print('SCREENSHOT: === SOLO RESULTS SCREEN COMPLETE ===');
    });

    testWidgets('Team results screen', (WidgetTester tester) async {
      print('SCREENSHOT: === TEAM RESULTS SCREEN ===');

      // 4 players team mode
      await h.setupAndStartGame(
        tester,
        teamMode: true,
        playerNames: ['Moana', 'Maui', 'Lilo', 'Stitch'],
      );

      expect(ProviderHelpers.isTikiGolfGameActive(tester), isTrue);

      // Rapid-complete all 9 holes
      final provider = ProviderHelpers.getTikiGolfProvider(tester);
      while (!provider.hasWinner) {
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

      print('SCREENSHOT: === TEAM RESULTS SCREEN COMPLETE ===');
    });

    print('SCREENSHOT: === ALL SCREENSHOT TESTS REGISTERED ===');
  });
}
