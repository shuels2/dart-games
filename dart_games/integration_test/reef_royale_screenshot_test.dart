import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';

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
    await PumpSequences.simpleUpdate(tester);
  }
}

Future<void> throwBullseyeViaMock(WidgetTester tester) async {
  final mockApi = getMockApi(tester);
  if (mockApi != null) {
    mockApi.simulateDartThrow(
      score: 50,
      multiplier: 'bullseye',
      playerName: 'Player',
      baseScore: 50,
      widgetX: 125.0,
      widgetY: 125.0,
      widgetSize: 250.0,
    );
    await PumpSequences.simpleUpdate(tester);
  }
}

Future<void> throwOuterBullViaMock(WidgetTester tester) async {
  final mockApi = getMockApi(tester);
  if (mockApi != null) {
    mockApi.simulateDartThrow(
      score: 25,
      multiplier: 'outer_bull',
      playerName: 'Player',
      baseScore: 25,
      widgetX: 125.0,
      widgetY: 125.0,
      widgetSize: 250.0,
    );
    await PumpSequences.simpleUpdate(tester);
  }
}

Future<void> throwMissViaMock(WidgetTester tester) async {
  final mockApi = getMockApi(tester);
  if (mockApi != null) {
    mockApi.simulateDartThrow(
      score: 0,
      multiplier: 'single',
      playerName: 'Player',
      baseScore: 0,
      widgetX: 125.0,
      widgetY: 125.0,
      widgetSize: 250.0,
    );
    await PumpSequences.simpleUpdate(tester);
  }
}

Future<void> clickDartsRemoved(WidgetTester tester) async {
  final dartsRemovedButton = find.text('DARTS REMOVED');
  if (dartsRemovedButton.evaluate().isNotEmpty) {
    await tester.tap(dartsRemovedButton.first);
    await PumpSequences.simpleUpdate(tester);
  }
}

Future<void> addPlayersAndSelect(
    WidgetTester tester, GameUIConfig config) async {
  await UITestHelpers.addPlayer(tester, 'Nemo', config);
  await UITestHelpers.addPlayer(tester, 'Dory', config);

  final players = ProviderHelpers.getAllPlayers(tester);
  final nemo = players.firstWhere((p) => p.name == 'Nemo');
  final dory = players.firstWhere((p) => p.name == 'Dory');
  await UITestHelpers.selectPlayers(tester, [nemo.id, dory.id], config);
}

/// Take screenshot with extra pumps to ensure browser rendering is current
Future<void> screenshot(IntegrationTestWidgetsFlutterBinding binding,
    WidgetTester tester, String name) async {
  await tester.pump(const Duration(seconds: 2));
  await tester.pump();
  await tester.pump();
  await tester.pump();
  await binding.takeScreenshot(name);
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final config = GameUIConfig.reefRoyale();

  group('Reef Royale - Screenshot Capture', () {
    setUp(() async {
      await SettingsHelpers.initializeSettings();
    });

    testWidgets('Menu screen states', (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);
      await screenshot(binding, tester,'01_menu_default');

      // Toggle each option individually and screenshot
      await SettingsHelpers.toggleReefRoyaleEasyClaim(tester);
      await screenshot(binding, tester,'02_menu_easy_claim_on');
      await SettingsHelpers.toggleReefRoyaleEasyClaim(tester);

      await SettingsHelpers.toggleReefRoyaleNeighborNumbers(tester);
      await screenshot(binding, tester,'03_menu_neighbor_numbers_on');
      await SettingsHelpers.toggleReefRoyaleNeighborNumbers(tester);

      await SettingsHelpers.toggleReefRoyaleRandomReefs(tester);
      await screenshot(binding, tester,'04_menu_random_reefs_on');
      await SettingsHelpers.toggleReefRoyaleRandomReefs(tester);

      await SettingsHelpers.toggleReefRoyaleBonusBuffs(tester);
      await screenshot(binding, tester,'05_menu_bonus_buffs_on');
      await SettingsHelpers.toggleReefRoyaleBonusBuffs(tester);

      await SettingsHelpers.toggleReefRoyaleShowHints(tester);
      await screenshot(binding, tester,'06_menu_show_hints_on');
      await SettingsHelpers.toggleReefRoyaleShowHints(tester);

      await SettingsHelpers.toggleReefRoyaleSpeedPlay(tester);
      await screenshot(binding, tester,'07_menu_speed_play_on');
      await SettingsHelpers.toggleReefRoyaleSpeedPlay(tester);

      // Add players and show ready state
      await addPlayersAndSelect(tester, config);
      await screenshot(binding, tester,'08_menu_players_ready');
    });

    testWidgets('Game flow with default settings',
        (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);
      await addPlayersAndSelect(tester, config);
      await UITestHelpers.startGame(tester, config);

      await screenshot(binding, tester,'09_game_start_default');

      // Throw first dart (triple 20 = claim)
      await throwDartViaMock(tester, 20, multiplier: 'triple');
      await screenshot(binding, tester,'10_game_after_claim');

      // Throw 2 more darts
      await throwDartViaMock(tester, 19, multiplier: 'triple');
      await throwDartViaMock(tester, 18);
      await screenshot(binding, tester,'11_game_three_darts_thrown');

      // Wait for takeout modal
      await tester.pump(const Duration(seconds: 4));
      await tester.pump();
      await tester.pump();
      await screenshot(binding, tester,'12_game_takeout_modal');

      // Advance to player 2
      await clickDartsRemoved(tester);
      await screenshot(binding, tester,'13_game_player2_turn');

      // P2 misses
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await clickDartsRemoved(tester);

      // P1 Turn 2: claim 17, 16, 15
      await throwDartViaMock(tester, 17, multiplier: 'triple');
      await throwDartViaMock(tester, 16, multiplier: 'triple');
      await throwDartViaMock(tester, 15, multiplier: 'triple');
      await screenshot(binding, tester,'14_game_after_round2');

      await clickDartsRemoved(tester);

      // P2 misses
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await clickDartsRemoved(tester);

      // P1 Turn 3: claim Bull
      await throwBullseyeViaMock(tester);
      await throwOuterBullViaMock(tester);

      // Wait for results screen
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      await screenshot(binding, tester,'15_results_screen');
    });

    testWidgets('Game with visual options enabled',
        (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      // Enable visual options
      await SettingsHelpers.toggleReefRoyaleShowHints(tester);
      await SettingsHelpers.toggleReefRoyaleSpeedPlay(tester);
      await SettingsHelpers.toggleReefRoyaleBonusBuffs(tester);

      await addPlayersAndSelect(tester, config);
      await UITestHelpers.startGame(tester, config);

      await screenshot(binding, tester,'16_game_hints_and_speed_play');

      // Throw some darts to show marks accumulating
      await throwDartViaMock(tester, 20, multiplier: 'triple');
      await throwDartViaMock(tester, 19);
      await screenshot(binding, tester,'17_game_options_after_darts');
    });
  });
}
