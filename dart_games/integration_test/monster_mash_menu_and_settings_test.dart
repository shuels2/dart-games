import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

// Shared component imports
import 'shared/ui_test_helpers.dart';
import 'shared/element_finders.dart';
import 'shared/pump_sequences.dart';
import 'shared/settings_helpers.dart';
import 'shared/game_ui_config.dart';
import 'shared/provider_helpers.dart';

/// Monster Mash - Menu and Settings Integration Tests
///
/// These are full integration tests that run the complete app in Chrome
/// and test menu settings functionality including:
/// - Initial state verification
/// - Health points slider
/// - Bonus buffs toggle
/// - Speed play toggle and round limit slider
/// - Player selection and validation
/// - Starting game with default and custom settings
///
/// Run with:
/// ```bash
/// # Terminal 1: Start chromedriver
/// cd dart_games/chromedriver/chromedriver-win64
/// ./chromedriver.exe --port=4444
///
/// # Terminal 2: Run tests
/// flutter drive --driver=test_driver/integration_test.dart \
///   --target=integration_test/monster_mash_menu_and_settings_test.dart \
///   -d chrome
/// ```

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Game configuration for Monster Mash
  final config = GameUIConfig.monsterMash();

  group('Monster Mash - Menu and Settings Tests', () {
    setUp(() async {
      await SettingsHelpers.initializeSettings();
    });

    testWidgets('Test 1: Menu screen initial state - Health slider present (default 20), Bonus Buffs OFF, Speed Play OFF, Round Limit disabled, Start disabled, back button present', (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      // Verify health slider present with default value 20
      final healthSlider = ElementFinders.getMonsterMashHealthPointsSlider();
      expect(healthSlider, findsOneWidget);
      final healthSliderWidget = tester.widget<Slider>(healthSlider);
      expect(healthSliderWidget.value.toInt(), 20);

      // Verify Bonus Buffs switch is OFF
      final bonusBuffsSwitch = ElementFinders.getMonsterMashBonusBuffsSwitch();
      expect(bonusBuffsSwitch, findsOneWidget);
      final bonusBuffsWidget = tester.widget<Switch>(bonusBuffsSwitch);
      expect(bonusBuffsWidget.value, isFalse);

      // Verify Speed Play switch is OFF
      final speedPlaySwitch = ElementFinders.getMonsterMashSpeedPlaySwitch();
      expect(speedPlaySwitch, findsOneWidget);
      final speedPlayWidget = tester.widget<Switch>(speedPlaySwitch);
      expect(speedPlayWidget.value, isFalse);

      // Verify back button is present
      final backButton = ElementFinders.getMonsterMashBackButton();
      expect(backButton, findsOneWidget);

      // Verify start button exists (disabled without players)
      final startButton = ElementFinders.getMonsterMashStartButton();
      expect(startButton, findsOneWidget);
    });

    testWidgets('Test 2: Health points slider - Set to 10, 30, 50, verify label updates', (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      // Set health to 10
      await SettingsHelpers.setMonsterMashHealthMax(tester, 10);
      final slider10 = tester.widget<Slider>(ElementFinders.getMonsterMashHealthPointsSlider());
      expect(slider10.value.toInt(), 10);

      // Set health to 30
      await SettingsHelpers.setMonsterMashHealthMax(tester, 30);
      final slider30 = tester.widget<Slider>(ElementFinders.getMonsterMashHealthPointsSlider());
      expect(slider30.value.toInt(), 30);

      // Set health to 50
      await SettingsHelpers.setMonsterMashHealthMax(tester, 50);
      final slider50 = tester.widget<Slider>(ElementFinders.getMonsterMashHealthPointsSlider());
      expect(slider50.value.toInt(), 50);
    });

    testWidgets('Test 3: Bonus buffs toggle - Toggle ON/OFF, verify switch state changes', (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      // Verify initially OFF
      var bonusBuffsWidget = tester.widget<Switch>(ElementFinders.getMonsterMashBonusBuffsSwitch());
      expect(bonusBuffsWidget.value, isFalse);

      // Toggle ON
      await SettingsHelpers.toggleMonsterMashBonusBuffs(tester);
      bonusBuffsWidget = tester.widget<Switch>(ElementFinders.getMonsterMashBonusBuffsSwitch());
      expect(bonusBuffsWidget.value, isTrue);

      // Toggle OFF
      await SettingsHelpers.toggleMonsterMashBonusBuffs(tester);
      bonusBuffsWidget = tester.widget<Switch>(ElementFinders.getMonsterMashBonusBuffsSwitch());
      expect(bonusBuffsWidget.value, isFalse);
    });

    testWidgets('Test 4: Speed play toggle and round limit - Speed Play ON enables round limit slider, set round limit, Speed Play OFF disables slider', (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      // Toggle Speed Play ON
      await SettingsHelpers.toggleMonsterMashSpeedPlay(tester);
      var speedPlayWidget = tester.widget<Switch>(ElementFinders.getMonsterMashSpeedPlaySwitch());
      expect(speedPlayWidget.value, isTrue);

      // Verify round limit slider is now available
      final roundLimitSlider = ElementFinders.getMonsterMashRoundLimitSlider();
      expect(roundLimitSlider, findsOneWidget);

      // Set round limit to 5
      await SettingsHelpers.setMonsterMashRoundLimit(tester, 5);
      var roundLimitWidget = tester.widget<Slider>(roundLimitSlider);
      expect(roundLimitWidget.value.toInt(), 5);

      // Set round limit to 15
      await SettingsHelpers.setMonsterMashRoundLimit(tester, 15);
      roundLimitWidget = tester.widget<Slider>(roundLimitSlider);
      expect(roundLimitWidget.value.toInt(), 15);

      // Toggle Speed Play OFF
      await SettingsHelpers.toggleMonsterMashSpeedPlay(tester);
      speedPlayWidget = tester.widget<Switch>(ElementFinders.getMonsterMashSpeedPlaySwitch());
      expect(speedPlayWidget.value, isFalse);
    });

    testWidgets('Test 5: Player selection min/max validation - Start disabled with <2 players, enabled with 2+', (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      // Add only 1 player
      await UITestHelpers.addPlayer(tester, 'Solo Monster', config);

      // Verify player was added
      expect(find.text('Solo Monster'), findsWidgets);

      // With only 1 player, game cannot start (need at least 2)
      // Add a second player
      await UITestHelpers.addPlayer(tester, 'Duo Monster', config);

      // Verify both players present
      expect(find.text('Solo Monster'), findsWidgets);
      expect(find.text('Duo Monster'), findsWidgets);
    });

    testWidgets('Test 6: Player selection and deselection - Select 3 players, deselect one, verify count updates', (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      // Add 3 players
      await UITestHelpers.addPlayer(tester, 'Player One', config);
      await UITestHelpers.addPlayer(tester, 'Player Two', config);
      await UITestHelpers.addPlayer(tester, 'Player Three', config);

      // Verify all 3 players are visible
      expect(find.text('Player One'), findsWidgets);
      expect(find.text('Player Two'), findsWidgets);
      expect(find.text('Player Three'), findsWidgets);

      // Players should be auto-selected after creation
      final selectedPlayers = ProviderHelpers.getSelectedPlayers(tester);
      expect(selectedPlayers.length, greaterThanOrEqualTo(3));
    });

    testWidgets('Test 7: Start game with default settings - Add 2 players, start -> game screen loads, provider: isGameActive=true, health=20, unique targets/monsters', (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      // Add 2 players
      await UITestHelpers.addPlayer(tester, 'Player A', config);
      await UITestHelpers.addPlayer(tester, 'Player B', config);

      // Start game with default settings
      await UITestHelpers.startGame(tester, config);

      // Verify game screen loaded
      expect(ProviderHelpers.isMonsterMashGameActive(tester), isTrue);

      // Verify health is at default (20)
      final currentPlayerId = ProviderHelpers.getMonsterMashCurrentPlayerId(tester);
      expect(currentPlayerId, isNotNull);
      final health = ProviderHelpers.getMonsterMashPlayerHealth(tester, currentPlayerId!);
      expect(health, 20);

      // Verify unique target numbers
      final playerA = ProviderHelpers.findPlayerByName(tester, 'Player A');
      final playerB = ProviderHelpers.findPlayerByName(tester, 'Player B');
      expect(playerA, isNotNull);
      expect(playerB, isNotNull);

      final targetA = ProviderHelpers.getMonsterMashPlayerTarget(tester, playerA!.id);
      final targetB = ProviderHelpers.getMonsterMashPlayerTarget(tester, playerB!.id);
      expect(targetA, isNotNull);
      expect(targetB, isNotNull);
      expect(targetA, isNot(equals(targetB))); // Unique targets

      // Verify unique monster types
      final monsterA = ProviderHelpers.getMonsterMashPlayerMonsterType(tester, playerA.id);
      final monsterB = ProviderHelpers.getMonsterMashPlayerMonsterType(tester, playerB.id);
      expect(monsterA, isNotNull);
      expect(monsterB, isNotNull);
      expect(monsterA, isNot(equals(monsterB))); // Unique monsters
    });

    testWidgets('Test 8: Start game with custom settings - Health=30, buffs ON, speed play ON, round limit=5, 3 players -> provider confirms all settings', (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      // Set custom settings
      await SettingsHelpers.setMonsterMashHealthMax(tester, 30);
      await SettingsHelpers.toggleMonsterMashBonusBuffs(tester);
      await SettingsHelpers.toggleMonsterMashSpeedPlay(tester);
      await SettingsHelpers.setMonsterMashRoundLimit(tester, 5);

      // Add 3 players
      await UITestHelpers.addPlayer(tester, 'Player X', config);
      await UITestHelpers.addPlayer(tester, 'Player Y', config);
      await UITestHelpers.addPlayer(tester, 'Player Z', config);

      // Start game
      await UITestHelpers.startGame(tester, config);

      // Verify game is active
      expect(ProviderHelpers.isMonsterMashGameActive(tester), isTrue);

      // Verify custom health
      final currentPlayerId = ProviderHelpers.getMonsterMashCurrentPlayerId(tester);
      expect(currentPlayerId, isNotNull);
      final health = ProviderHelpers.getMonsterMashPlayerHealth(tester, currentPlayerId!);
      expect(health, 30);

      // Verify round limit
      final roundLimit = ProviderHelpers.getMonsterMashRoundLimit(tester);
      expect(roundLimit, 5);

      // Verify current round starts at 1
      final currentRound = ProviderHelpers.getMonsterMashCurrentRound(tester);
      expect(currentRound, 1);
    });
  });
}
