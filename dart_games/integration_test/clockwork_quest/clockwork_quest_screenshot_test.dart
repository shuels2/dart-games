import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';
import 'package:dart_games/constants/test_keys.dart';

import '../shared/ui_test_helpers.dart';
import '../shared/pump_sequences.dart';
import '../shared/settings_helpers.dart';
import '../shared/game_ui_config.dart';
import '../shared/provider_helpers.dart';

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

/// Simulate darts removed via mock API (more reliable than tapping UI button,
/// since RemoveDartsModal overlay blocks taps to emulator section below it)
Future<void> clickDartsRemoved(WidgetTester tester) async {
  // Brief wait for state to settle after dart throws
  await tester.pump(const Duration(seconds: 1));
  await tester.pump();

  final provider = ProviderHelpers.getClockworkQuestProvider(tester);
  if (provider.shouldPromptTakeout) {
    print('SCREENSHOT: Simulating takeout via mock API...');
    final mockApi = getMockApi(tester);
    mockApi?.simulateTakeoutFinished();
    // Wait for stream event to propagate through provider chain
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    await tester.pump();
    await tester.pump();
  } else {
    print('SCREENSHOT: WARNING - shouldPromptTakeout is false, skipping takeout');
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

  final config = GameUIConfig.clockworkQuest();

  group('Clockwork Quest - Screenshot Capture', () {
    setUp(() async {
      await UITestHelpers.resetServerState();
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
      print('SCREENSHOT: Toggling Include Bullseye...');
      await SettingsHelpers.toggleClockworkQuestIncludeBullseye(tester);
      await screenshot(binding, tester, '02_menu_include_bullseye_on');
      await SettingsHelpers.toggleClockworkQuestIncludeBullseye(tester);
      print('SCREENSHOT: Include Bullseye toggled back off');

      print('SCREENSHOT: Toggling Speed Mode...');
      await SettingsHelpers.toggleClockworkQuestSpeedMode(tester);
      await screenshot(binding, tester, '04_menu_speed_mode_on');
      await SettingsHelpers.toggleClockworkQuestSpeedMode(tester);
      print('SCREENSHOT: Speed Mode toggled back off');

      print('SCREENSHOT: Changing Number of Laps...');
      await SettingsHelpers.selectClockworkQuestLaps(tester, 3);
      await screenshot(binding, tester, '05_menu_3_laps');
      await SettingsHelpers.selectClockworkQuestLaps(tester, 1);
      print('SCREENSHOT: Number of Laps changed back to 1');

      // Add players (DualPlayerListPanel auto-selects them)
      print('SCREENSHOT: Adding players...');
      await UITestHelpers.addPlayer(tester, 'Cogsworth', config);
      print('SCREENSHOT: Added Cogsworth');
      await UITestHelpers.addPlayer(tester, 'Gearsby', config);
      print('SCREENSHOT: Added Gearsby');

      // Players are auto-selected by DualPlayerListPanel, verify
      final selectedPlayers = ProviderHelpers.getSelectedPlayers(tester);
      final selectedCount = selectedPlayers.length;
      print('SCREENSHOT: Selected players count: $selectedCount');
      expect(selectedCount, greaterThanOrEqualTo(2),
          reason: 'Need at least 2 players selected to start game');

      // Capture player IDs in order (P1 = index 0, P2 = index 1)
      final p1Id = selectedPlayers[0].id;
      final p2Id = selectedPlayers[1].id;
      print('SCREENSHOT: P1 id: $p1Id, P2 id: $p2Id');

      await screenshot(binding, tester, '06_menu_players_ready');

      // ================================================================
      // PART 2: GAME FLOW (DEFAULT SETTINGS)
      // ================================================================
      print('SCREENSHOT: === PART 2: GAME FLOW ===');

      print('SCREENSHOT: Starting game...');
      await UITestHelpers.startGame(tester, config);
      print('SCREENSHOT: Game started');

      // Verify we're on the game screen
      final gameActive = ProviderHelpers.isClockworkQuestGameActive(tester);
      print('SCREENSHOT: Game active: $gameActive');
      expect(gameActive, isTrue, reason: 'Game should be active after starting');

      final gearIcon1 = find.byKey(ClockworkQuestGameKeys.gear(1));
      print('SCREENSHOT: Gear icon 1 found: ${gearIcon1.evaluate().length}');
      expect(gearIcon1, findsOneWidget, reason: 'Gear icon for 1 should be visible');

      await screenshot(binding, tester, '07_game_start_default');

      // P1 Turn 1: Throw first dart (S1 = advance to gear 2)
      print('SCREENSHOT: P1 throwing S1...');
      await throwDartViaMock(tester, 1);
      print('SCREENSHOT: S1 thrown, advanced to gear 2');
      await screenshot(binding, tester, '08_game_after_first_dart');

      // Throw 2 more darts (advance to 3 and 4)
      print('SCREENSHOT: P1 throwing S2 and S3...');
      await throwDartViaMock(tester, 2);
      await throwDartViaMock(tester, 3);
      // Capture BEFORE the takeout modal appears (shows 3 dart indicators filled)
      await screenshot(binding, tester, '09_game_three_darts_thrown');

      // Now wait for takeout modal to appear and capture it
      print('SCREENSHOT: Waiting for takeout modal...');
      await tester.pump(const Duration(seconds: 5));
      await tester.pump();
      await tester.pump();
      await tester.pump();
      await screenshot(binding, tester, '10_game_takeout_modal');

      // Advance to player 2
      print('SCREENSHOT: Clicking DARTS REMOVED...');
      await clickDartsRemoved(tester);
      print('SCREENSHOT: Advanced to player 2');
      await screenshot(binding, tester, '11_game_player2_turn');

      // P2: hit targets 1, 2, 3 to advance
      print('SCREENSHOT: P2 hitting 1, 2, 3...');
      await throwDartViaMock(tester, 1);
      await throwDartViaMock(tester, 2);
      await throwDartViaMock(tester, 3);
      await clickDartsRemoved(tester);
      print('SCREENSHOT: P2 turn complete');

      // P1 Turn 2: continue progression (currently at gear 4)
      print('SCREENSHOT: P1 continuing from gear 4...');
      await throwDartViaMock(tester, 4);
      await throwDartViaMock(tester, 5);
      await throwDartViaMock(tester, 6);
      await screenshot(binding, tester, '12_game_mid_progression');
      await clickDartsRemoved(tester);

      // Fast forward P1 to near end (we know P1's ID captured before game start)
      ProviderHelpers.setClockworkQuestPlayerTarget(tester, p1Id, 19);

      // P2: skip turn
      await throwDartViaMock(tester, 10); // won't advance (wrong target)
      await throwDartViaMock(tester, 10);
      await throwDartViaMock(tester, 10);
      await clickDartsRemoved(tester);

      // P1: hit 19 to advance to gear 20, then screenshot the near-win state
      print('SCREENSHOT: P1 hitting gear 19...');
      await throwDartViaMock(tester, 19);
      await screenshot(binding, tester, '13_game_final_gear');

      // P1: hit 20 to complete the circuit and win
      print('SCREENSHOT: P1 hitting gear 20 to win...');
      await throwDartViaMock(tester, 20);

      // Wait for results screen navigation
      await tester.pump(const Duration(seconds: 4));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      await tester.pump();
      await screenshot(binding, tester, '14_results_screen');

      // ================================================================
      // PART 3: GAME WITH OPTIONS (BULLSEYE MODE)
      // ================================================================
      print('SCREENSHOT: === PART 3: GAME WITH BULLSEYE ===');

      // Back to menu
      await UITestHelpers.clickChangeSettings(tester, config);
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();

      // Re-select players (DualPlayerListPanel resets selection when navigating back)
      print('SCREENSHOT: Re-selecting players for bullseye game...');
      await UITestHelpers.selectPlayers(tester, [p1Id, p2Id], config);
      print('SCREENSHOT: Players re-selected');

      // Toggle Include Bullseye
      print('SCREENSHOT: Enabling Include Bullseye...');
      await SettingsHelpers.toggleClockworkQuestIncludeBullseye(tester);
      await screenshot(binding, tester, '15_menu_bullseye_enabled');

      // Start new game
      print('SCREENSHOT: Starting game with bullseye...');
      await UITestHelpers.startGame(tester, config);
      await screenshot(binding, tester, '16_game_bullseye_mode');

      // Fast forward current player (P1) to bullseye target (21)
      final currentPlayerId = ProviderHelpers.getClockworkQuestCurrentPlayerId(tester)!;
      ProviderHelpers.setClockworkQuestPlayerTarget(tester, currentPlayerId, 21);
      await tester.pump(); // Process notifyListeners from target change

      // Screenshot showing "Bull" as current target
      await screenshot(binding, tester, '17_game_bullseye_target');

      // Hit bullseye to win
      print('SCREENSHOT: Hitting bullseye to win...');
      await throwBullseyeViaMock(tester);

      // Wait for results screen navigation
      await tester.pump(const Duration(seconds: 4));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      await tester.pump();
      await screenshot(binding, tester, '18_results_bullseye_win');

      print('SCREENSHOT: === ALL SCREENSHOTS COMPLETE ===');
    });
  });
}
