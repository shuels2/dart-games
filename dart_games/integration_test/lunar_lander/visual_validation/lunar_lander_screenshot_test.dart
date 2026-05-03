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
// HELPER METHODS (screenshot test — inline, not shared)
// ==========================================================================

MockScoliaApiService? getMockApi(WidgetTester tester) {
  final dartboardProvider = ProviderHelpers.getDartboardProvider(tester);
  return dartboardProvider.apiService;
}

/// Throw a dart via mock API with full pump sequence
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

/// Simulate darts removed via mock API
Future<void> clickDartsRemovedViaMock(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 1));
  await tester.pump();

  final provider = ProviderHelpers.getLunarLanderProvider(tester);
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
/// CRITICAL: Uses binding.takeScreenshot() — must use screenshot_test.dart driver.
/// Do NOT use pumpAndSettle() — continuous animations prevent settling.
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

  final config = GameUIConfig.lunarLander();

  group('Lunar Lander - Screenshot Capture', () {
    setUp(() async {
      await UITestHelpers.resetServerState();
    });

    // Single continuous E2E flow capturing all spec §12C states
    testWidgets('Full screenshot flow', (WidgetTester tester) async {
      // ================================================================
      // SCREENSHOT 1: Menu — default settings, no players
      // ================================================================
      print('SCREENSHOT: === PART 1: MENU SCREEN STATES ===');

      await UITestHelpers.navigateToGameMenu(tester, config);
      await screenshot(binding, tester, '01_menu_default_no_players');

      // ================================================================
      // SCREENSHOT 2: Menu — Hard Landing toggle ON
      // ================================================================
      await SettingsHelpers.setLunarLanderHardLanding(tester, enabled: true);
      await screenshot(binding, tester, '02_menu_hard_landing_on');
      // Toggle back off for subsequent screenshots
      await SettingsHelpers.setLunarLanderHardLanding(tester, enabled: false);

      // ================================================================
      // SCREENSHOT 3: Menu — altitude changed to 300
      // ================================================================
      await SettingsHelpers.setLunarLanderAltitude(tester, 300);
      await screenshot(binding, tester, '03_menu_altitude_300');
      // Reset to 200 for main game flow
      await SettingsHelpers.setLunarLanderAltitude(tester, 200);

      // ================================================================
      // SCREENSHOT 4: Menu — 4 players added, ready to start
      // ================================================================
      await UITestHelpers.addPlayer(tester, 'Space Dog', config);
      await UITestHelpers.addPlayer(tester, 'Moon Cat', config);
      await UITestHelpers.addPlayer(tester, 'Rocket Penguin', config);
      await UITestHelpers.addPlayer(tester, 'Orbit Owl', config);

      final selectedPlayers = ProviderHelpers.getSelectedPlayers(tester);
      expect(selectedPlayers.length, greaterThanOrEqualTo(2));
      final p1Id = selectedPlayers[0].id;
      final p2Id = selectedPlayers[1].id;

      await screenshot(binding, tester, '04_menu_4_players_ready');

      // ================================================================
      // PART 2: GAME SCREEN STATES
      // ================================================================
      print('SCREENSHOT: === PART 2: GAME SCREEN STATES ===');

      await UITestHelpers.startGame(tester, config);

      // ================================================================
      // SCREENSHOT 5: Game — start state (all rockets at top, alt=200)
      // ================================================================
      expect(ProviderHelpers.isLunarLanderGameActive(tester), isTrue);
      await screenshot(binding, tester, '05_game_start_all_rockets_top');

      // ================================================================
      // SCREENSHOT 6: Game — mid-game (altitudes varied)
      // ================================================================
      // P1: throw 20+20+20 = -60
      await throwDartViaMock(tester, 20);
      await throwDartViaMock(tester, 20);
      await throwDartViaMock(tester, 20);
      await screenshot(binding, tester, '06_game_mid_p1_descending');
      await clickDartsRemovedViaMock(tester);

      // P2: throw 15 only
      await throwDartViaMock(tester, 15);
      await screenshot(binding, tester, '07_game_mid_varied_altitudes');
      await clickDartsRemovedViaMock(tester);

      // P3 and P4: misses — skip extra players back to P1
      {
        final extraMockApi = getMockApi(tester);
        for (int attempt = 0; attempt < 2; attempt++) {
          final provider = ProviderHelpers.getLunarLanderProvider(tester);
          final currentId = provider.getCurrentPlayerId();
          if (currentId == p1Id || currentId == p2Id) break;
          // Throw 3 misses for current player
          for (int i = 0; i < 3; i++) {
            extraMockApi?.simulateDartThrow(
              score: 0, multiplier: 'miss', playerName: 'Player',
              baseScore: 0, widgetX: 125.0, widgetY: 125.0, widgetSize: 250.0,
            );
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 300));
            await tester.pump();
          }
          await clickDartsRemovedViaMock(tester);
        }
      }

      // ================================================================
      // SCREENSHOT 7: Game — Hard Landing badge visible
      // ================================================================
      // Complete current round, navigate back to menu to enable Hard Landing
      // Strategy: navigate back without saving, re-start with Hard Landing ON
      // To keep test linear: we do a second game setup in the same test.

      // ================================================================
      // PART 3: GAME WITH HARD LANDING ON
      // ================================================================
      print('SCREENSHOT: === PART 3: HARD LANDING BADGE ===');

      // To set up the Hard Landing scenario, navigate FULLY back to home and
      // re-enter the menu from scratch. The save-modal back-from-game flow
      // is fragile (multiple overlays + emulator section in the Stack), so
      // bypass it by:
      //   1) Capturing the Navigator context from the still-mounted game
      //      screen (Skip Turn button is a descendant of the Navigator).
      //   2) Clearing the in-memory game state.
      //   3) Popping all routes back to home via Navigator.popUntil.
      //   4) Re-entering the menu fresh via the home-screen card.
      //
      // Order matters: clearGame() triggers a rebuild that removes the Skip
      // Turn button from the tree, so we must capture the NavigatorState BEFORE
      // calling clearGame(). We store the NavigatorState directly (not just the
      // element/context) so it remains usable after the element is deactivated.
      final navState = Navigator.of(
          tester.element(find.byKey(LunarLanderGameKeys.skipTurnButton).first));
      ProviderHelpers.getLunarLanderProvider(tester).clearGame();
      await tester.pump();
      await tester.pump();
      navState.popUntil((route) => route.isFirst);
      await PumpSequences.navigation(tester);
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      // Re-enter the Lunar Lander menu fresh by tapping its home-screen card
      await tester.tap(config.getGameCard());
      await PumpSequences.navigation(tester);
      await PumpSequences.asyncDataLoad(tester);

      // Confirm we're on the menu
      expect(ElementFinders.getLunarLanderStartButton(), findsOneWidget,
          reason: 'Should be on Lunar Lander menu after fresh re-entry');

      // On menu — enable Hard Landing
      await SettingsHelpers.setLunarLanderHardLanding(tester, enabled: true);

      // Re-add players (selection is empty after fresh menu entry)
      await UITestHelpers.selectPlayers(tester, [p1Id, p2Id], config);
      await UITestHelpers.startGame(tester, config);

      await screenshot(binding, tester, '08_game_hard_landing_badge_visible');

      // ================================================================
      // SCREENSHOT 8: Game — Remove Darts modal visible
      // ================================================================
      await throwDartViaMock(tester, 20);
      await throwDartViaMock(tester, 20);
      await throwDartViaMock(tester, 20);
      // After 3 darts, remove darts modal should appear
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      await screenshot(binding, tester, '09_game_remove_darts_modal');
      await clickDartsRemovedViaMock(tester);

      // ================================================================
      // SCREENSHOT 9: Game — near-landing state (alt <= 20)
      // ================================================================
      // P2 misses all
      final mockApiInstance = getMockApi(tester);
      for (int i = 0; i < 3; i++) {
        mockApiInstance?.simulateDartThrow(
          score: 0, multiplier: 'miss', playerName: 'Player',
          baseScore: 0, widgetX: 125.0, widgetY: 125.0, widgetSize: 250.0,
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump();
      }
      await clickDartsRemovedViaMock(tester);

      // P1 at 140 (200 - 60), throw more to reach near-landing (< 20)
      // Throw 20+20+20 = 60 more → 80 remaining
      await throwDartViaMock(tester, 20);
      await throwDartViaMock(tester, 20);
      await throwDartViaMock(tester, 20);
      await clickDartsRemovedViaMock(tester);

      // P2 misses again
      for (int i = 0; i < 3; i++) {
        mockApiInstance?.simulateDartThrow(
          score: 0, multiplier: 'miss', playerName: 'Player',
          baseScore: 0, widgetX: 125.0, widgetY: 125.0, widgetSize: 250.0,
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump();
      }
      await clickDartsRemovedViaMock(tester);

      // P1 now at 80. Throw triple 20 = 60 → 20 remaining
      // Throw single 20 → at exactly 20 (near-landing)
      await throwDartViaMock(tester, 20, multiplier: 'triple');
      await screenshot(binding, tester, '10_game_near_landing_alt_20');

      // ================================================================
      // PART 4: RESULTS SCREEN
      // ================================================================
      print('SCREENSHOT: === PART 4: RESULTS SCREEN ===');

      // Now win: throw single 20 to reach exactly 0
      // Hard Landing ON — we need to be at exactly 20 to land exactly
      // Check if we're at exactly 20, if so throw 20 to win
      final provider = ProviderHelpers.getLunarLanderProvider(tester);
      final currentId = provider.getCurrentPlayerId()!;
      final currentAlt = provider.getCurrentAltitude(currentId);
      if (currentAlt <= 20 && currentAlt > 0) {
        await throwDartViaMock(tester, currentAlt); // exact landing
      } else {
        // If somehow not exactly 20, let play-to-complete finish
        await throwDartViaMock(tester, 20);
      }

      // Wait for game to complete and results to load
      if (!provider.hasWinner) {
        await clickDartsRemovedViaMock(tester);
        // Continue until game ends
        for (int i = 0; i < 20; i++) {
          if (provider.hasWinner) break;
          final altNow = provider.getCurrentAltitude(provider.getCurrentPlayerId()!);
          await throwDartViaMock(tester, altNow <= 20 ? altNow : 20);
          if (provider.shouldPromptTakeout) {
            await clickDartsRemovedViaMock(tester);
          }
        }
      }

      await tester.pump(const Duration(seconds: 4));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      await tester.pump();

      // ================================================================
      // SCREENSHOT 10: Results — winner display + rankings + 3 buttons
      // ================================================================
      await screenshot(binding, tester, '11_results_winner_rankings_buttons');

      print('SCREENSHOT: === ALL SCREENSHOTS COMPLETE ===');
    });
  });
}
