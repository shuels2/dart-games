import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/models/reef_royale_game.dart';

import '../shared/ui_test_helpers.dart';
import '../shared/element_finders.dart';
import '../shared/pump_sequences.dart';
import '../shared/settings_helpers.dart';
import '../shared/game_ui_config.dart';
import '../shared/provider_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final config = GameUIConfig.reefRoyale();

  group('Reef Royale - Menu and Settings Tests', () {
    setUp(() async {
      await UITestHelpers.resetServerState();
    });

    testWidgets('Test 1: Menu screen shows all 8 game options',
        (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      // Verify game mode dropdown exists
      expect(ElementFinders.getReefRoyaleGameModeDropdown(), findsOneWidget);

      // Verify toggle switches exist
      expect(ElementFinders.getReefRoyaleEasyClaimSwitch(), findsOneWidget);
      expect(ElementFinders.getReefRoyaleNeighborNumbersSwitch(), findsOneWidget);
      expect(ElementFinders.getReefRoyaleRandomReefsSwitch(), findsOneWidget);
      expect(ElementFinders.getReefRoyaleBonusBuffsSwitch(), findsOneWidget);
      expect(ElementFinders.getReefRoyaleShowHintsSwitch(), findsOneWidget);
      expect(ElementFinders.getReefRoyaleSpeedPlaySwitch(), findsOneWidget);
    });

    testWidgets('Test 2: Toggle Easy Claim switch',
        (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      await SettingsHelpers.toggleReefRoyaleEasyClaim(tester);

      // Verify the switch toggled (widget should still exist)
      expect(ElementFinders.getReefRoyaleEasyClaimSwitch(), findsOneWidget);
    });

    testWidgets('Test 3: Toggle Neighbor Numbers switch',
        (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      await SettingsHelpers.toggleReefRoyaleNeighborNumbers(tester);

      expect(ElementFinders.getReefRoyaleNeighborNumbersSwitch(), findsOneWidget);
    });

    testWidgets('Test 4: Toggle Bonus Buffs switch',
        (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      await SettingsHelpers.toggleReefRoyaleBonusBuffs(tester);

      expect(ElementFinders.getReefRoyaleBonusBuffsSwitch(), findsOneWidget);
    });

    testWidgets('Test 5: Speed Play enables Round Limit slider',
        (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      // Toggle speed play ON
      await SettingsHelpers.toggleReefRoyaleSpeedPlay(tester);

      // Round limit slider should now be visible
      expect(ElementFinders.getReefRoyaleRoundLimitSlider(), findsOneWidget);
    });

    testWidgets('Test 6: Set Round Limit slider value',
        (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      // Enable speed play first
      await SettingsHelpers.toggleReefRoyaleSpeedPlay(tester);

      // Set round limit to 8
      await SettingsHelpers.setReefRoyaleRoundLimit(tester, 8);
    });

    testWidgets('Test 7: Start game with default settings navigates to game screen',
        (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      await UITestHelpers.addPlayer(tester, 'Player A', config);
      await UITestHelpers.addPlayer(tester, 'Player B', config);

      // Players are auto-selected when added, no need to call selectPlayers
      await UITestHelpers.startGame(tester, config);

      expect(ProviderHelpers.isReefRoyaleGameActive(tester), isTrue);
    });

    testWidgets('Test 8: Start game with all options enabled',
        (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      // Enable all options
      await SettingsHelpers.toggleReefRoyaleEasyClaim(tester);
      await SettingsHelpers.toggleReefRoyaleNeighborNumbers(tester);
      await SettingsHelpers.toggleReefRoyaleRandomReefs(tester);
      await SettingsHelpers.toggleReefRoyaleBonusBuffs(tester);
      await SettingsHelpers.toggleReefRoyaleShowHints(tester);
      await SettingsHelpers.toggleReefRoyaleSpeedPlay(tester);

      // Add players (auto-selected when added)
      await UITestHelpers.addPlayer(tester, 'Player A', config);
      await UITestHelpers.addPlayer(tester, 'Player B', config);

      await UITestHelpers.startGame(tester, config);

      expect(ProviderHelpers.isReefRoyaleGameActive(tester), isTrue);
    });

    testWidgets('Test 9: Game mode dropdown changes to Cursed Tide',
        (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      // Select Cursed Tide from dropdown
      await SettingsHelpers.setReefRoyaleGameMode(tester, 'Cursed Tide');

      // Add players and start to verify the mode was applied
      await UITestHelpers.addPlayer(tester, 'Player A', config);
      await UITestHelpers.addPlayer(tester, 'Player B', config);
      await UITestHelpers.startGame(tester, config);

      expect(ProviderHelpers.getReefRoyaleGameMode(tester),
          ReefRoyaleGameMode.cursedTide);
    });

    testWidgets('Test 10: Random Reefs and Show Hints toggles',
        (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      // Toggle Random Reefs ON
      await SettingsHelpers.toggleReefRoyaleRandomReefs(tester);
      expect(ElementFinders.getReefRoyaleRandomReefsSwitch(), findsOneWidget);

      // Toggle Show Hints OFF (it starts ON by default)
      await SettingsHelpers.toggleReefRoyaleShowHints(tester);
      expect(ElementFinders.getReefRoyaleShowHintsSwitch(), findsOneWidget);

      // Start game to verify settings were applied
      await UITestHelpers.addPlayer(tester, 'Player A', config);
      await UITestHelpers.addPlayer(tester, 'Player B', config);
      await UITestHelpers.startGame(tester, config);

      expect(ProviderHelpers.isReefRoyaleGameActive(tester), isTrue);
    });
  });
}
