import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';
import 'package:dart_games/constants/test_keys.dart';

import 'shared/ui_test_helpers.dart';
import 'shared/pump_sequences.dart';
import 'shared/settings_helpers.dart';
import 'shared/game_ui_config.dart';
import 'shared/provider_helpers.dart';

// ==========================================================================
// HELPER METHODS
// ==========================================================================

MockScoliaApiService? getMockApi(WidgetTester tester) {
  final dartboardProvider = ProviderHelpers.getDartboardProvider(tester);
  return dartboardProvider.apiService;
}

/// Throw dart via mock API with enough pumps for full UI render
Future<void> throwDartViaMock(WidgetTester tester, int number,
    {String multiplier = 'single'}) async {
  final mockApi = getMockApi(tester);
  if (mockApi != null) {
    print('SCREENSHOT: Throwing $multiplier $number...');
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
    // Extra pumps to ensure stream event propagates through provider chain
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    await tester.pump();
    await tester.pump();
  } else {
    print('SCREENSHOT: ERROR - mockApi is null!');
  }
}

Future<void> throwBullseyeViaMock(WidgetTester tester) async {
  final mockApi = getMockApi(tester);
  if (mockApi != null) {
    print('SCREENSHOT: Throwing bullseye...');
    mockApi.simulateDartThrow(
      score: 50,
      multiplier: 'bullseye',
      playerName: 'Player',
      baseScore: 50,
      widgetX: 125.0,
      widgetY: 125.0,
      widgetSize: 250.0,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    await tester.pump();
    await tester.pump();
  } else {
    print('SCREENSHOT: ERROR - mockApi is null!');
  }
}

Future<void> throwOuterBullViaMock(WidgetTester tester) async {
  final mockApi = getMockApi(tester);
  if (mockApi != null) {
    print('SCREENSHOT: Throwing outer bull...');
    mockApi.simulateDartThrow(
      score: 25,
      multiplier: 'outer_bull',
      playerName: 'Player',
      baseScore: 25,
      widgetX: 125.0,
      widgetY: 125.0,
      widgetSize: 250.0,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    await tester.pump();
    await tester.pump();
  } else {
    print('SCREENSHOT: ERROR - mockApi is null!');
  }
}

Future<void> throwMissViaMock(WidgetTester tester) async {
  final mockApi = getMockApi(tester);
  if (mockApi != null) {
    print('SCREENSHOT: Throwing miss...');
    mockApi.simulateDartThrow(
      score: 0,
      multiplier: 'single',
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
  } else {
    print('SCREENSHOT: ERROR - mockApi is null!');
  }
}

/// Wait for and click DARTS REMOVED button
Future<void> clickDartsRemoved(WidgetTester tester) async {
  // Wait for the remove darts modal to appear
  await tester.pump(const Duration(seconds: 4));
  await tester.pump();
  await tester.pump();

  final dartsRemovedButton = find.text('DARTS REMOVED');
  if (dartsRemovedButton.evaluate().isNotEmpty) {
    print('SCREENSHOT: Found DARTS REMOVED button, tapping...');
    await tester.tap(dartsRemovedButton.first);
    await PumpSequences.simpleUpdate(tester);
  } else {
    print('SCREENSHOT: WARNING - DARTS REMOVED button not found!');
  }
}

/// Take screenshot with extra pumps to ensure rendering is current
Future<void> screenshot(IntegrationTestWidgetsFlutterBinding binding,
    WidgetTester tester, String name) async {
  await tester.pump(const Duration(seconds: 2));
  await tester.pump();
  await tester.pump();
  await tester.pump();
  print('SCREENSHOT: Taking screenshot: $name');
  await binding.takeScreenshot(name);
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final config = GameUIConfig.reefRoyale();

  group('Reef Royale - Screenshot Capture', () {
    setUp(() async {
      await SettingsHelpers.initializeSettings();
    });

    // Single continuous E2E flow: menu → game → results → options game
    testWidgets('Full screenshot flow', (WidgetTester tester) async {
      // ================================================================
      // PART 1: MENU SCREEN STATES
      // ================================================================
      print('SCREENSHOT: === PART 1: MENU SCREEN STATES ===');

      await UITestHelpers.navigateToGameMenu(tester, config);
      print('SCREENSHOT: Navigated to menu');

      await screenshot(binding, tester, '01_menu_default');

      // Toggle each option individually and screenshot
      print('SCREENSHOT: Toggling Easy Claim...');
      await SettingsHelpers.toggleReefRoyaleEasyClaim(tester);
      await screenshot(binding, tester, '02_menu_easy_claim_on');
      await SettingsHelpers.toggleReefRoyaleEasyClaim(tester);
      print('SCREENSHOT: Easy Claim toggled back off');

      print('SCREENSHOT: Toggling Neighbor Numbers...');
      await SettingsHelpers.toggleReefRoyaleNeighborNumbers(tester);
      await screenshot(binding, tester, '03_menu_neighbor_numbers_on');
      await SettingsHelpers.toggleReefRoyaleNeighborNumbers(tester);
      print('SCREENSHOT: Neighbor Numbers toggled back off');

      print('SCREENSHOT: Toggling Random Reefs...');
      await SettingsHelpers.toggleReefRoyaleRandomReefs(tester);
      await screenshot(binding, tester, '04_menu_random_reefs_on');
      await SettingsHelpers.toggleReefRoyaleRandomReefs(tester);
      print('SCREENSHOT: Random Reefs toggled back off');

      print('SCREENSHOT: Toggling Bonus Buffs...');
      await SettingsHelpers.toggleReefRoyaleBonusBuffs(tester);
      await screenshot(binding, tester, '05_menu_bonus_buffs_on');
      await SettingsHelpers.toggleReefRoyaleBonusBuffs(tester);
      print('SCREENSHOT: Bonus Buffs toggled back off');

      print('SCREENSHOT: Toggling Show Hints...');
      await SettingsHelpers.toggleReefRoyaleShowHints(tester);
      await screenshot(binding, tester, '06_menu_show_hints_on');
      await SettingsHelpers.toggleReefRoyaleShowHints(tester);
      print('SCREENSHOT: Show Hints toggled back off');

      print('SCREENSHOT: Toggling Speed Play...');
      await SettingsHelpers.toggleReefRoyaleSpeedPlay(tester);
      await screenshot(binding, tester, '07_menu_speed_play_on');
      await SettingsHelpers.toggleReefRoyaleSpeedPlay(tester);
      print('SCREENSHOT: Speed Play toggled back off');

      // Add players (DualPlayerListPanel auto-selects them)
      print('SCREENSHOT: Adding players...');
      await UITestHelpers.addPlayer(tester, 'Nemo', config);
      print('SCREENSHOT: Added Nemo');
      await UITestHelpers.addPlayer(tester, 'Dory', config);
      print('SCREENSHOT: Added Dory');

      // Players are auto-selected by DualPlayerListPanel, verify
      final selectedCount = ProviderHelpers.getSelectedPlayers(tester).length;
      print('SCREENSHOT: Selected players count: $selectedCount');
      expect(selectedCount, greaterThanOrEqualTo(2),
          reason: 'Need at least 2 players selected to start game');

      await screenshot(binding, tester, '08_menu_players_ready');

      // ================================================================
      // PART 2: GAME FLOW (DEFAULT SETTINGS)
      // ================================================================
      print('SCREENSHOT: === PART 2: GAME FLOW ===');

      print('SCREENSHOT: Starting game...');
      await UITestHelpers.startGame(tester, config);
      print('SCREENSHOT: Game started');

      // Verify we're on the game screen
      final gameActive = ProviderHelpers.isReefRoyaleGameActive(tester);
      print('SCREENSHOT: Game active: $gameActive');
      expect(gameActive, isTrue, reason: 'Game should be active after starting');

      final coralCard20 = find.byKey(ReefRoyaleGameKeys.coralCard(20));
      print('SCREENSHOT: Coral card 20 found: ${coralCard20.evaluate().length}');
      expect(coralCard20, findsOneWidget, reason: 'Coral card for 20 should be visible');

      await screenshot(binding, tester, '09_game_start_default');

      // P1 Turn 1: Throw first dart (triple 20 = claim)
      print('SCREENSHOT: P1 throwing triple 20...');
      await throwDartViaMock(tester, 20, multiplier: 'triple');
      print('SCREENSHOT: Triple 20 thrown');
      await screenshot(binding, tester, '10_game_after_claim');

      // Throw 2 more darts (triple to claim each)
      print('SCREENSHOT: P1 throwing triple 19 and triple 18...');
      await throwDartViaMock(tester, 19, multiplier: 'triple');
      await throwDartViaMock(tester, 18, multiplier: 'triple');
      // Capture BEFORE the takeout modal appears (shows 3 dart indicators filled)
      await screenshot(binding, tester, '11_game_three_darts_thrown');

      // Now wait for takeout modal to appear and capture it
      print('SCREENSHOT: Waiting for takeout modal...');
      await tester.pump(const Duration(seconds: 5));
      await tester.pump();
      await tester.pump();
      await tester.pump();
      await screenshot(binding, tester, '12_game_takeout_modal');

      // Advance to player 2
      print('SCREENSHOT: Clicking DARTS REMOVED...');
      await clickDartsRemoved(tester);
      print('SCREENSHOT: Advanced to player 2');
      await screenshot(binding, tester, '13_game_player2_turn');

      // P2 misses
      print('SCREENSHOT: P2 throwing 3 misses...');
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await clickDartsRemoved(tester);
      print('SCREENSHOT: P2 turn complete');

      // P1 Turn 2: claim 17, 16, 15
      print('SCREENSHOT: P1 claiming 17, 16, 15...');
      await throwDartViaMock(tester, 17, multiplier: 'triple');
      await throwDartViaMock(tester, 16, multiplier: 'triple');
      await throwDartViaMock(tester, 15, multiplier: 'triple');
      // Capture BEFORE the takeout modal appears (shows 6 corals claimed)
      await screenshot(binding, tester, '14_game_after_round2');

      await clickDartsRemoved(tester);

      // P2 misses
      print('SCREENSHOT: P2 throwing 3 misses...');
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await clickDartsRemoved(tester);
      print('SCREENSHOT: P2 turn complete');

      // P1 Turn 3: claim Bull (game ends - all 7 targets claimed)
      print('SCREENSHOT: P1 claiming Bull...');
      await throwBullseyeViaMock(tester);
      await throwOuterBullViaMock(tester);
      await throwMissViaMock(tester); // 3rd dart to trigger takeout

      final hasWinner = ProviderHelpers.reefRoyaleHasWinner(tester);
      print('SCREENSHOT: Has winner: $hasWinner');

      // Click DARTS REMOVED to trigger _handleTakeoutFinished → _handleGameWon
      await clickDartsRemoved(tester);

      // Wait for results screen navigation (3s delay in _handleGameWon)
      print('SCREENSHOT: Waiting for results screen...');
      await tester.pump(const Duration(seconds: 4));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      await tester.pump();
      await screenshot(binding, tester, '15_results_screen');

      // Note: Part 3 (game with options) removed - 15 screenshots covers
      // all key visual states: menu toggles, players, game flow, results.

      print('SCREENSHOT: === ALL SCREENSHOTS COMPLETE ===');
    });
  });
}
