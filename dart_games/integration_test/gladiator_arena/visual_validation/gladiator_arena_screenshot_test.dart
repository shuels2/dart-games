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
    final value = number *
        (multiplier == 'double'
            ? 2
            : multiplier == 'triple'
                ? 3
                : 1);
    mockApi.simulateDartThrow(
      score: value,
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

Future<void> clickDartsRemoved(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 1));
  await tester.pump();
  final provider = ProviderHelpers.getGladiatorArenaProvider(tester);
  if (provider.shouldPromptTakeout) {
    final mockApi = getMockApi(tester);
    mockApi?.simulateTakeoutFinished();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    await tester.pump();
  }
}

/// Throw a miss via mock API with full pump sequence
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

/// Take screenshot — MUST use screenshot_test.dart driver.
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

  final config = GameUIConfig.gladiatorArena();

  group('Gladiator Arena - Screenshot Capture', () {
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
      // SCREENSHOT 2: Menu — Shield Round ON
      // ================================================================
      await SettingsHelpers.toggleGladiatorArenaShieldRound(tester);
      await screenshot(binding, tester, '02_menu_shield_round_on');
      await SettingsHelpers.toggleGladiatorArenaShieldRound(tester);

      // ================================================================
      // SCREENSHOT 3: Menu — target changed to 300
      // ================================================================
      await SettingsHelpers.setGladiatorArenaTargetScore(tester, 300);
      await screenshot(binding, tester, '03_menu_target_300');
      await SettingsHelpers.setGladiatorArenaTargetScore(tester, 200);

      // ================================================================
      // SCREENSHOT 4: Menu — players added, ready to start
      // ================================================================
      await UITestHelpers.addPlayer(tester, 'Leo the Lion', config);
      await UITestHelpers.addPlayer(tester, 'Aquila Eagle', config);
      await UITestHelpers.addPlayer(tester, 'Lupus Wolf', config);
      await UITestHelpers.addPlayer(tester, 'Ursus Bear', config);

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
      // SCREENSHOT 5: Game — start state (all podiums at 0)
      // ================================================================
      expect(ProviderHelpers.isGladiatorArenaGameActive(tester), isTrue);
      await screenshot(binding, tester, '05_game_start_all_podiums_zero');

      // ================================================================
      // SCREENSHOT 6: Game — mid-play (P1 throws S20 x3 = 60 pts)
      // ================================================================
      await throwDartViaMock(tester, 20);
      await throwDartViaMock(tester, 20);
      await throwDartViaMock(tester, 20);
      await screenshot(binding, tester, '06_game_mid_p1_scoring');
      await clickDartsRemoved(tester);

      // P2: throw S20 = 20pts (1 dart)
      await throwDartViaMock(tester, 20);
      await screenshot(binding, tester, '07_game_varied_podium_heights');
      // Let P2 finish their turn
      await throwDartViaMock(tester, 20);
      await throwDartViaMock(tester, 20);
      await clickDartsRemoved(tester);

      // Skip P3, P4 turns quickly
      {
        final provider = ProviderHelpers.getGladiatorArenaProvider(tester);
        final mockApi = getMockApi(tester);
        for (int attempt = 0; attempt < 4; attempt++) {
          final currentId = provider.currentPlayerId;
          if (currentId == p1Id || currentId == p2Id) break;
          // Throw 3 misses for current player
          for (int i = 0; i < 3; i++) {
            mockApi?.simulateDartThrow(
              score: 0, multiplier: 'miss', playerName: 'Player',
              baseScore: 0, widgetX: 125.0, widgetY: 125.0, widgetSize: 250.0,
            );
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 300));
            await tester.pump();
          }
          await clickDartsRemoved(tester);
        }
      }

      // ================================================================
      // SCREENSHOT 8: Game — Double Finish badge visible (DF ON by default)
      // ================================================================
      await screenshot(binding, tester, '08_game_double_badge_visible');

      // ================================================================
      // SCREENSHOT 9: Game — RemoveDartsModal visible after 3 darts
      // ================================================================
      await throwDartViaMock(tester, 20);
      await throwDartViaMock(tester, 20);
      await throwDartViaMock(tester, 20);
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      await screenshot(binding, tester, '09_game_remove_darts_modal');
      await clickDartsRemoved(tester);

      // ================================================================
      // PART 3: RESULTS SCREEN — restart with winning-friendly settings
      // ================================================================
      // The current game (target=200, DF=ON) is mid-state with no clean
      // path to a quick win. Reset with target=100 + DF=OFF so the FIRST
      // player can win deterministically: T20 + Miss + Miss = 60 pts/turn,
      // 2 turns = 120 ≥ 100 → WIN at turn end (DF OFF, any dart wins).
      print('SCREENSHOT: === PART 3: RESULTS SCREEN (restart for clean win) ===');

      final ga = ProviderHelpers.getGladiatorArenaProvider(tester);
      final selectedPlayerIds =
          ga.currentGame?.playerIds ?? [];

      // Reset game state directly via provider (the screen will rebuild
      // when notifyListeners fires from startGame).
      ga.clearGame();
      await tester.pump();
      await tester.pump();

      // Reuse character path mapping from the previous game so visuals stay
      // recognizable. If null, the new startGame will assign defaults.
      final charPaths = <String, String>{
        for (int i = 0; i < selectedPlayerIds.length; i++)
          selectedPlayerIds[i]:
              'assets/games/gladiator_arena/characters/${[
            'LeoLion',
            'AquilaEagle',
            'LupusWolf',
            'UrsusBear',
          ][i % 4]}.png',
      };

      ga.startGame(
        playerIds: selectedPlayerIds,
        targetScore: 100,
        doubleFinishEnabled: false,
        shieldRoundEnabled: false,
        speedPlayEnabled: false,
        playerCharacterPaths: charPaths,
      );
      await tester.pump();
      await PumpSequences.fullRebuild(tester);

      // Drive to victory: designated winner = first player. T20 + Miss + Miss
      // each P1 turn = 60 pts. After P1's 2nd turn → 120 ≥ 100 → WIN.
      // Other players throw 3 misses each turn.
      final designatedWinnerId =
          ga.currentGame!.playerIds.first;

      for (int safety = 0; safety < 30; safety++) {
        if (ga.hasWinner) break;
        final currentId = ga.currentPlayerId;
        if (currentId == null) break;

        if (currentId == designatedWinnerId) {
          await throwDartViaMock(tester, 20, multiplier: 'triple');
          if (!ga.hasWinner && !ga.shouldPromptTakeout) {
            await throwMissViaMock(tester);
          }
          if (!ga.hasWinner && !ga.shouldPromptTakeout) {
            await throwMissViaMock(tester);
          }
        } else {
          for (int d = 0; d < 3; d++) {
            if (ga.hasWinner || ga.shouldPromptTakeout) break;
            await throwMissViaMock(tester);
          }
        }

        if (ga.hasWinner) break;
        if (ga.shouldPromptTakeout) {
          await clickDartsRemoved(tester);
        }
      }

      // FINAL takeout click — fires _handleTakeoutFinished → _handleGameWon →
      // Navigator.pushReplacement(results). Without this, the RemoveDartsModal
      // stays up and the screenshot captures the game-screen state.
      if (ga.hasWinner) {
        await clickDartsRemoved(tester);
      }

      // Wait for results-screen navigation (3000ms victory delay + buffer)
      await tester.pump(const Duration(seconds: 4));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      await PumpSequences.fullRebuild(tester);

      // ================================================================
      // SCREENSHOT 10: Results — winner display + rankings + buttons
      // ================================================================
      await screenshot(binding, tester, '10_results_winner_rankings_buttons');

      print('SCREENSHOT: === ALL SCREENSHOTS COMPLETE ===');
    });
  });
}
