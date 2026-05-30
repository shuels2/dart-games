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

Future<void> clickDartsRemovedViaMock(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 1));
  await tester.pump();

  final provider = ProviderHelpers.getPiratesGridProvider(tester);
  if (provider.shouldPromptTakeout) {
    final mockApi = getMockApi(tester);
    mockApi?.simulateTakeoutFinished();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    await tester.pump();
    await tester.pump();
  }
}

/// Take screenshot with extra pumps to ensure rendering is current.
/// CRITICAL: Uses binding.takeScreenshot() â€” must use screenshot_test.dart driver.
/// Do NOT use pumpAndSettle() â€” continuous animations prevent settling.
Future<void> screenshot(IntegrationTestWidgetsFlutterBinding binding,
    WidgetTester tester, String name) async {
  await tester.pump(const Duration(seconds: 2));
  await tester.pump();
  await tester.pump();
  await tester.pump();
  print('SCREENSHOT: Taking screenshot: $name');
  await binding.takeScreenshot(name);
}

// ==========================================================================
// MAIN TEST
// ==========================================================================

void main() {
  // CRITICAL: Must use test_driver/screenshot_test.dart as driver (NOT integration_test.dart)
  // Using integration_test.dart will cause the test to hang on takeScreenshot().
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final config = GameUIConfig.piratesGrid();

  group("Pirate's Grid - Screenshot Capture", () {
    setUp(() async {
      await UITestHelpers.resetServerState();
    });

    testWidgets('Full screenshot flow', (WidgetTester tester) async {
      // ================================================================
      // SCREENSHOT 1: Menu â€” default settings, no players
      // ================================================================
      print('SCREENSHOT: === PART 1: MENU SCREEN STATES ===');

      await UITestHelpers.navigateToGameMenu(tester, config);
      await screenshot(binding, tester, '01_menu_default_no_players');

      // ================================================================
      // SCREENSHOT 2: Menu â€” Hard difficulty selected
      // ================================================================
      await SettingsHelpers.setPiratesGridDifficulty(tester, 'Hard');
      await screenshot(binding, tester, '02_menu_hard_difficulty');
      // No reset here â€” screenshot 03 also needs Hard difficulty.

      // Extra pumps after takeScreenshot() to allow the widget tree to
      // settle before the next dropdown interaction.
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
      await tester.pump();

      // ================================================================
      // SCREENSHOT 3: Menu â€” Best Of 3, Hard Difficulty
      // ================================================================
      // Difficulty is already Hard from screenshot 02.
      // Ensure the BestOf dropdown is visible before interacting with it.
      await tester.ensureVisible(
          find.byKey(PiratesGridMenuKeys.bestOfDropdown));
      await tester.pump();
      await SettingsHelpers.setPiratesGridBestOf(tester, '3');
      await screenshot(binding, tester, '03_menu_hard_bestof3');

      // Navigate back to home and re-enter the menu to reset settings
      // to their defaults (Easy, BestOf 1) for screenshot 04.
      final navStateForReset = Navigator.of(
          tester.element(find.byKey(PiratesGridMenuKeys.backButton)));
      navStateForReset.popUntil((route) => route.isFirst);
      await PumpSequences.navigation(tester);
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      await UITestHelpers.tapGameCard(tester, config);
      await PumpSequences.asyncDataLoad(tester);

      // ================================================================
      // SCREENSHOT 4: Menu â€” 2 players added, ready to start
      // ================================================================
      await UITestHelpers.addPlayer(tester, 'Captain Jack', config);
      await UITestHelpers.addPlayer(tester, 'Captain Redbeard', config);

      final selectedPlayers = ProviderHelpers.getSelectedPlayers(tester);
      expect(selectedPlayers.length, greaterThanOrEqualTo(2));

      await screenshot(binding, tester, '04_menu_2_players_ready');

      // ================================================================
      // PART 2: GAME SCREEN â€” Easy difficulty
      // ================================================================
      print('SCREENSHOT: === PART 2: GAME SCREEN STATES ===');

      await UITestHelpers.startGame(tester, config);

      // ================================================================
      // SCREENSHOT 5: Game â€” start state (all cells empty, Easy)
      // ================================================================
      await screenshot(binding, tester, '05_game_start_easy');

      // ================================================================
      // SCREENSHOT 6: Game â€” after some darts, flags planted
      // ================================================================
      final s1t00 = ProviderHelpers.getPiratesGridCellTargetNumber(tester, 0, 0);
      final s1t01 = ProviderHelpers.getPiratesGridCellTargetNumber(tester, 0, 1);
      final s1t10 = ProviderHelpers.getPiratesGridCellTargetNumber(tester, 1, 0);
      await throwDartViaMock(tester, s1t00); // P1 plants flag [0,0]
      await throwDartViaMock(tester, s1t01); // P1 plants flag [0,1]
      await screenshot(binding, tester, '06_game_easy_flags_planted');

      await throwDartViaMock(tester, 1); // P1 miss (1 is not a grid target)
      await clickDartsRemovedViaMock(tester);

      // P2 throws a flag
      await throwDartViaMock(tester, s1t10); // P2 plants flag [1,0]
      await screenshot(binding, tester, '07_game_mid_both_players');
      await throwDartViaMock(tester, 1);
      await throwDartViaMock(tester, 1);
      await clickDartsRemovedViaMock(tester);

      // ================================================================
      // PART 3: GAME SCREEN â€” Medium difficulty
      // ================================================================
      print('SCREENSHOT: === PART 3: MEDIUM DIFFICULTY ===');

      // Navigate back to menu via clearGame + popUntil
      final navState = Navigator.of(
          tester.element(find.byKey(PiratesGridGameKeys.skipTurnButton).first));
      ProviderHelpers.getPiratesGridProvider(tester).clearGame();
      await tester.pump();
      await tester.pump();
      navState.popUntil((route) => route.isFirst);
      await PumpSequences.navigation(tester);
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      // Re-enter menu
      await UITestHelpers.tapGameCard(tester, config);
      await PumpSequences.asyncDataLoad(tester);

      await SettingsHelpers.setPiratesGridDifficulty(tester, 'Medium');

      final pA = selectedPlayers[0].id;
      final pB = selectedPlayers[1].id;
      await UITestHelpers.selectPlayers(tester, [pA, pB], config);
      await UITestHelpers.startGame(tester, config);

      // ================================================================
      // SCREENSHOT 8: Game â€” Medium difficulty with D badges
      // ================================================================
      await screenshot(binding, tester, '08_game_medium_d_badges');

      // ================================================================
      // PART 4: GAME SCREEN â€” Hard difficulty
      // ================================================================
      print('SCREENSHOT: === PART 4: HARD DIFFICULTY ===');

      final navState2 = Navigator.of(
          tester.element(find.byKey(PiratesGridGameKeys.skipTurnButton).first));
      ProviderHelpers.getPiratesGridProvider(tester).clearGame();
      await tester.pump();
      await tester.pump();
      navState2.popUntil((route) => route.isFirst);
      await PumpSequences.navigation(tester);
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      await UITestHelpers.tapGameCard(tester, config);
      await PumpSequences.asyncDataLoad(tester);

      await SettingsHelpers.setPiratesGridDifficulty(tester, 'Hard');
      await UITestHelpers.selectPlayers(tester, [pA, pB], config);
      await UITestHelpers.startGame(tester, config);

      // ================================================================
      // SCREENSHOT 9: Game â€” Hard difficulty with T/D/Bull badges
      // ================================================================
      await screenshot(binding, tester, '09_game_hard_tdb_badges');

      // ================================================================
      // PART 5: STEAL MODE badge
      // ================================================================
      print('SCREENSHOT: === PART 5: STEAL MODE ===');

      final navState3 = Navigator.of(
          tester.element(find.byKey(PiratesGridGameKeys.skipTurnButton).first));
      ProviderHelpers.getPiratesGridProvider(tester).clearGame();
      await tester.pump();
      await tester.pump();
      navState3.popUntil((route) => route.isFirst);
      await PumpSequences.navigation(tester);
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      await UITestHelpers.tapGameCard(tester, config);
      await PumpSequences.asyncDataLoad(tester);

      // Difficulty is already Easy and BestOf is already 1 after re-entering menu.
      await SettingsHelpers.togglePiratesGridStealMode(tester);
      await UITestHelpers.selectPlayers(tester, [pA, pB], config);
      await UITestHelpers.startGame(tester, config);

      // ================================================================
      // SCREENSHOT 10: Game â€” Steal Mode badge visible
      // ================================================================
      await screenshot(binding, tester, '10_game_steal_mode_badge');

      // ================================================================
      // SCREENSHOT 11: Game â€” RemoveDartsModal visible
      // ================================================================
      final s4t00 = ProviderHelpers.getPiratesGridCellTargetNumber(tester, 0, 0);
      final s4t01 = ProviderHelpers.getPiratesGridCellTargetNumber(tester, 0, 1);
      final s4t02 = ProviderHelpers.getPiratesGridCellTargetNumber(tester, 0, 2);
      await throwDartViaMock(tester, s4t00);
      await throwDartViaMock(tester, s4t01);
      await throwDartViaMock(tester, s4t02); // P1 wins row 0
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      await screenshot(binding, tester, '11_game_remove_darts_modal');
      await clickDartsRemovedViaMock(tester);
      // Wait for the 3-second Future.delayed in _handleGameWon() to fire
      // and the Navigator.pushReplacement to complete.
      // Robust wait: poll until the results screen has rendered, instead of a
      // fixed pump that races the event-driven victory navigation under load.
      for (int _i = 0; _i < 300; _i++) {
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump();
        if (find.byKey(PiratesGridResultsKeys.playAgainButton).evaluate().isNotEmpty) {
          break;
        }
      }
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      // ================================================================
      // PART 6: SPEED PLAY + ROUND TRACKER
      // ================================================================
      print('SCREENSHOT: === PART 6: SPEED PLAY + ROUND TRACKER ===');

      final navState4 = Navigator.of(
          tester.element(find.byKey(PiratesGridResultsKeys.playAgainButton).first));
      ProviderHelpers.getPiratesGridProvider(tester).clearGame();
      await tester.pump();
      await tester.pump();
      navState4.popUntil((route) => route.isFirst);
      await PumpSequences.navigation(tester);
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      await UITestHelpers.tapGameCard(tester, config);
      await PumpSequences.asyncDataLoad(tester);

      // Difficulty is already Easy and BestOf is already 1 after re-entering menu.
      // Set BestOf to 3 and toggle Speed Play for the next screenshots.
      await SettingsHelpers.setPiratesGridBestOf(tester, '3');
      await SettingsHelpers.togglePiratesGridSpeedPlay(tester);
      await UITestHelpers.selectPlayers(tester, [pA, pB], config);
      await UITestHelpers.startGame(tester, config);

      // ================================================================
      // SCREENSHOT 12: Game â€” Speed Play timer visible
      // ================================================================
      await screenshot(binding, tester, '12_game_speed_play_timer');

      // ================================================================
      // SCREENSHOT 13: Game â€” Bo3 round tracker visible
      // ================================================================
      await screenshot(binding, tester, '13_game_bo3_round_tracker');

      // ================================================================
      // SCREENSHOT 14: Game â€” 2 in a row state (near win)
      // ================================================================
      final s5t00 = ProviderHelpers.getPiratesGridCellTargetNumber(tester, 0, 0);
      final s5t01 = ProviderHelpers.getPiratesGridCellTargetNumber(tester, 0, 1);
      await throwDartViaMock(tester, s5t00);
      await throwDartViaMock(tester, s5t01);
      await throwDartViaMock(tester, 1); // miss for 3rd dart (1 is not a grid target)
      await screenshot(binding, tester, '14_game_two_in_a_row');
      await clickDartsRemovedViaMock(tester);

      // ================================================================
      // PART 7: RESULTS SCREEN
      // Navigate back to menu and start a clean BestOf 1 game,
      // then win it quickly to reach the results screen.
      // ================================================================
      print('SCREENSHOT: === PART 7: RESULTS SCREEN ===');

      // Exit this game (P1 has 2-in-a-row, round 1 incomplete)
      final navState5 = Navigator.of(
          tester.element(find.byKey(PiratesGridGameKeys.skipTurnButton).first));
      ProviderHelpers.getPiratesGridProvider(tester).clearGame();
      await tester.pump();
      await tester.pump();
      navState5.popUntil((route) => route.isFirst);
      await PumpSequences.navigation(tester);
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      await UITestHelpers.tapGameCard(tester, config);
      await PumpSequences.asyncDataLoad(tester);

      // Start BestOf 1, Easy (defaults â€” no extra settings needed)
      await UITestHelpers.selectPlayers(tester, [pA, pB], config);
      await UITestHelpers.startGame(tester, config);

      // P1 wins the match by completing row 0
      final s6t00 = ProviderHelpers.getPiratesGridCellTargetNumber(tester, 0, 0);
      final s6t01 = ProviderHelpers.getPiratesGridCellTargetNumber(tester, 0, 1);
      final s6t02 = ProviderHelpers.getPiratesGridCellTargetNumber(tester, 0, 2);
      await throwDartViaMock(tester, s6t00);
      await throwDartViaMock(tester, s6t01);
      await throwDartViaMock(tester, s6t02);
      await clickDartsRemovedViaMock(tester);

      // Wait for the 3-second Future.delayed in _handleGameWon() + navigation
      await tester.pump(const Duration(seconds: 4));
      await tester.pump();
      await tester.pump();

      // ================================================================
      // SCREENSHOT 15: RESULTS SCREEN
      // ================================================================
      await screenshot(binding, tester, '15_results_single_round_win');

      print('SCREENSHOT: All screenshots captured successfully!');
    });
  });
}
