import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';

import '../shared/ui_test_helpers.dart';
import '../shared/element_finders.dart';
import '../shared/pump_sequences.dart';
import '../shared/settings_helpers.dart';
import '../shared/game_ui_config.dart';
import '../shared/provider_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final config = GameUIConfig.clockworkQuest();

  group('Clockwork Quest - Menu and Settings Tests', () {
    setUp(() async {
      await SettingsHelpers.initializeSettings();
    });

    // ================================================================
    // INITIAL STATE
    // ================================================================

    testWidgets('Test 1: Menu screen shows all settings controls',
        (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      // Verify all 3 settings controls are visible
      expect(ElementFinders.getClockworkQuestIncludeBullseyeCheckbox(),
          findsOneWidget);
      expect(
          ElementFinders.getClockworkQuestSpeedModeCheckbox(), findsOneWidget);
      expect(ElementFinders.getClockworkQuestNumberOfLapsDropdown(),
          findsOneWidget);

      // Start button should be visible
      expect(config.getStartButton(), findsOneWidget);

      // Player list should be visible
      expect(find.byKey(ClockworkQuestMenuKeys.playerListView), findsOneWidget);
    });

    testWidgets('Test 2: Default settings are correct',
        (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      // Include Bullseye should default to OFF
      final bullseyeSwitch = tester.widget<Switch>(
        ElementFinders.getClockworkQuestIncludeBullseyeCheckbox(),
      );
      expect(bullseyeSwitch.value, isFalse);

      // Speed Mode should default to OFF
      final speedSwitch = tester.widget<Switch>(
        ElementFinders.getClockworkQuestSpeedModeCheckbox(),
      );
      expect(speedSwitch.value, isFalse);

      // Number of Laps should default to 1
      final lapsDropdown = tester.widget<DropdownButton<int>>(
        ElementFinders.getClockworkQuestNumberOfLapsDropdown(),
      );
      expect(lapsDropdown.value, 1);
    });

    // ================================================================
    // INCLUDE BULLSEYE TOGGLE
    // ================================================================

    testWidgets('Test 3: Toggle Include Bullseye ON',
        (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      await SettingsHelpers.toggleClockworkQuestIncludeBullseye(tester);

      final bullseyeSwitch = tester.widget<Switch>(
        ElementFinders.getClockworkQuestIncludeBullseyeCheckbox(),
      );
      expect(bullseyeSwitch.value, isTrue);
    });

    testWidgets('Test 4: Toggle Include Bullseye ON then OFF',
        (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      // Toggle ON
      await SettingsHelpers.toggleClockworkQuestIncludeBullseye(tester);
      var bullseyeSwitch = tester.widget<Switch>(
        ElementFinders.getClockworkQuestIncludeBullseyeCheckbox(),
      );
      expect(bullseyeSwitch.value, isTrue);

      // Toggle OFF
      await SettingsHelpers.toggleClockworkQuestIncludeBullseye(tester);
      bullseyeSwitch = tester.widget<Switch>(
        ElementFinders.getClockworkQuestIncludeBullseyeCheckbox(),
      );
      expect(bullseyeSwitch.value, isFalse);
    });

    // ================================================================
    // SPEED MODE TOGGLE
    // ================================================================

    testWidgets('Test 5: Toggle Speed Mode ON',
        (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      await SettingsHelpers.toggleClockworkQuestSpeedMode(tester);

      final speedSwitch = tester.widget<Switch>(
        ElementFinders.getClockworkQuestSpeedModeCheckbox(),
      );
      expect(speedSwitch.value, isTrue);
    });

    testWidgets('Test 6: Toggle Speed Mode ON then OFF',
        (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      await SettingsHelpers.toggleClockworkQuestSpeedMode(tester);
      var speedSwitch = tester.widget<Switch>(
        ElementFinders.getClockworkQuestSpeedModeCheckbox(),
      );
      expect(speedSwitch.value, isTrue);

      await SettingsHelpers.toggleClockworkQuestSpeedMode(tester);
      speedSwitch = tester.widget<Switch>(
        ElementFinders.getClockworkQuestSpeedModeCheckbox(),
      );
      expect(speedSwitch.value, isFalse);
    });

    // ================================================================
    // LAPS DROPDOWN
    // ================================================================

    testWidgets('Test 7: Change Number of Laps to 3',
        (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      await SettingsHelpers.selectClockworkQuestLaps(tester, 3);

      final lapsDropdown = tester.widget<DropdownButton<int>>(
        ElementFinders.getClockworkQuestNumberOfLapsDropdown(),
      );
      expect(lapsDropdown.value, 3);
    });

    testWidgets('Test 8: Cycle through all lap values',
        (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      for (final laps in [2, 3, 4, 5]) {
        await SettingsHelpers.selectClockworkQuestLaps(tester, laps);
        final lapsDropdown = tester.widget<DropdownButton<int>>(
          ElementFinders.getClockworkQuestNumberOfLapsDropdown(),
        );
        expect(lapsDropdown.value, laps, reason: 'Laps should be $laps');
      }
    });

    // ================================================================
    // ALL SETTINGS COMBINATIONS
    // ================================================================

    testWidgets('Test 9: Enable Bullseye + Speed Mode together',
        (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      await SettingsHelpers.toggleClockworkQuestIncludeBullseye(tester);
      await SettingsHelpers.toggleClockworkQuestSpeedMode(tester);

      final bullseyeSwitch = tester.widget<Switch>(
        ElementFinders.getClockworkQuestIncludeBullseyeCheckbox(),
      );
      final speedSwitch = tester.widget<Switch>(
        ElementFinders.getClockworkQuestSpeedModeCheckbox(),
      );
      expect(bullseyeSwitch.value, isTrue);
      expect(speedSwitch.value, isTrue);
    });

    testWidgets('Test 10: Enable all options (Bullseye + Speed + 5 Laps)',
        (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      await SettingsHelpers.toggleClockworkQuestIncludeBullseye(tester);
      await SettingsHelpers.toggleClockworkQuestSpeedMode(tester);
      await SettingsHelpers.selectClockworkQuestLaps(tester, 5);

      final bullseyeSwitch = tester.widget<Switch>(
        ElementFinders.getClockworkQuestIncludeBullseyeCheckbox(),
      );
      final speedSwitch = tester.widget<Switch>(
        ElementFinders.getClockworkQuestSpeedModeCheckbox(),
      );
      final lapsDropdown = tester.widget<DropdownButton<int>>(
        ElementFinders.getClockworkQuestNumberOfLapsDropdown(),
      );
      expect(bullseyeSwitch.value, isTrue);
      expect(speedSwitch.value, isTrue);
      expect(lapsDropdown.value, 5);
    });

    // ================================================================
    // START BUTTON VALIDATION
    // ================================================================

    testWidgets('Test 11: Start button disabled with no players',
        (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      final startButton = tester.widget<ElevatedButton>(
        config.getStartButton(),
      );
      expect(startButton.onPressed, isNull,
          reason: 'Start button should be disabled with 0 players');
    });

    testWidgets('Test 12: Start button disabled with 1 player',
        (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      await UITestHelpers.addPlayer(tester, 'Solo', config);

      final players = ProviderHelpers.getAllPlayers(tester);
      final solo = players.firstWhere((p) => p.name == 'Solo');
      await UITestHelpers.selectPlayers(tester, [solo.id], config);

      final startButton = tester.widget<ElevatedButton>(
        config.getStartButton(),
      );
      expect(startButton.onPressed, isNull,
          reason: 'Start button should be disabled with 1 player');
    });

    testWidgets('Test 13: Start button enabled with 2 players',
        (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      await UITestHelpers.addPlayer(tester, 'Gear1', config);
      await UITestHelpers.addPlayer(tester, 'Gear2', config);

      final players = ProviderHelpers.getAllPlayers(tester);
      final p1 = players.firstWhere((p) => p.name == 'Gear1');
      final p2 = players.firstWhere((p) => p.name == 'Gear2');
      await UITestHelpers.selectPlayers(tester, [p1.id, p2.id], config);

      final startButton = tester.widget<ElevatedButton>(
        config.getStartButton(),
      );
      expect(startButton.onPressed, isNotNull,
          reason: 'Start button should be enabled with 2 players');
    });

    // ================================================================
    // START GAME WITH SETTINGS
    // ================================================================

    testWidgets('Test 14: Start game with default settings',
        (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      await UITestHelpers.addPlayer(tester, 'Cog1', config);
      await UITestHelpers.addPlayer(tester, 'Cog2', config);

      final players = ProviderHelpers.getAllPlayers(tester);
      final p1 = players.firstWhere((p) => p.name == 'Cog1');
      final p2 = players.firstWhere((p) => p.name == 'Cog2');
      await UITestHelpers.selectPlayers(tester, [p1.id, p2.id], config);

      await UITestHelpers.startGame(tester, config);

      // Should navigate to game screen with game active
      expect(ProviderHelpers.isClockworkQuestGameActive(tester), isTrue);

      // Verify default settings were applied
      final provider = ProviderHelpers.getClockworkQuestProvider(tester);
      expect(provider.currentGame!.includeBullseye, isFalse);
      expect(provider.currentGame!.speedMode, isFalse);
      expect(provider.currentGame!.numberOfLaps, 1);
    });

    testWidgets('Test 15: Start game with Bullseye enabled',
        (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      await SettingsHelpers.toggleClockworkQuestIncludeBullseye(tester);

      await UITestHelpers.addPlayer(tester, 'Bull1', config);
      await UITestHelpers.addPlayer(tester, 'Bull2', config);

      final players = ProviderHelpers.getAllPlayers(tester);
      final p1 = players.firstWhere((p) => p.name == 'Bull1');
      final p2 = players.firstWhere((p) => p.name == 'Bull2');
      await UITestHelpers.selectPlayers(tester, [p1.id, p2.id], config);

      await UITestHelpers.startGame(tester, config);

      final provider = ProviderHelpers.getClockworkQuestProvider(tester);
      expect(provider.currentGame!.includeBullseye, isTrue);
      expect(provider.currentGame!.maxTarget, 21);
    });

    testWidgets('Test 16: Start game with Speed Mode enabled',
        (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      await SettingsHelpers.toggleClockworkQuestSpeedMode(tester);

      await UITestHelpers.addPlayer(tester, 'Speed1', config);
      await UITestHelpers.addPlayer(tester, 'Speed2', config);

      final players = ProviderHelpers.getAllPlayers(tester);
      final p1 = players.firstWhere((p) => p.name == 'Speed1');
      final p2 = players.firstWhere((p) => p.name == 'Speed2');
      await UITestHelpers.selectPlayers(tester, [p1.id, p2.id], config);

      await UITestHelpers.startGame(tester, config);

      final provider = ProviderHelpers.getClockworkQuestProvider(tester);
      expect(provider.currentGame!.speedMode, isTrue);
    });

    testWidgets('Test 17: Start game with 3 Laps',
        (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      await SettingsHelpers.selectClockworkQuestLaps(tester, 3);

      await UITestHelpers.addPlayer(tester, 'Lap1', config);
      await UITestHelpers.addPlayer(tester, 'Lap2', config);

      final players = ProviderHelpers.getAllPlayers(tester);
      final p1 = players.firstWhere((p) => p.name == 'Lap1');
      final p2 = players.firstWhere((p) => p.name == 'Lap2');
      await UITestHelpers.selectPlayers(tester, [p1.id, p2.id], config);

      await UITestHelpers.startGame(tester, config);

      final provider = ProviderHelpers.getClockworkQuestProvider(tester);
      expect(provider.currentGame!.numberOfLaps, 3);
    });

    testWidgets('Test 18: Start game with all options enabled',
        (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      await SettingsHelpers.toggleClockworkQuestIncludeBullseye(tester);
      await SettingsHelpers.toggleClockworkQuestSpeedMode(tester);
      await SettingsHelpers.selectClockworkQuestLaps(tester, 5);

      await UITestHelpers.addPlayer(tester, 'All1', config);
      await UITestHelpers.addPlayer(tester, 'All2', config);

      final players = ProviderHelpers.getAllPlayers(tester);
      final p1 = players.firstWhere((p) => p.name == 'All1');
      final p2 = players.firstWhere((p) => p.name == 'All2');
      await UITestHelpers.selectPlayers(tester, [p1.id, p2.id], config);

      await UITestHelpers.startGame(tester, config);

      final provider = ProviderHelpers.getClockworkQuestProvider(tester);
      expect(provider.currentGame!.includeBullseye, isTrue);
      expect(provider.currentGame!.speedMode, isTrue);
      expect(provider.currentGame!.numberOfLaps, 5);
      expect(provider.currentGame!.maxTarget, 21);
    });

    // ================================================================
    // BACK BUTTON
    // ================================================================

    testWidgets('Test 19: Back button returns to home screen',
        (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      final backButton = ElementFinders.getClockworkQuestBackButton();
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await PumpSequences.navigation(tester);

      // Should be back on home screen with game card visible
      expect(ElementFinders.getClockworkQuestCard(), findsOneWidget);
    });

    // ================================================================
    // RESUME GAME BUTTON
    // ================================================================

    testWidgets('Test 20: Resume game button is present',
        (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      expect(find.byKey(ClockworkQuestMenuKeys.resumeGameButton),
          findsOneWidget);
    });
  });
}
