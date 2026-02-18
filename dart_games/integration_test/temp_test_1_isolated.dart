import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';
import 'package:dart_games/constants/test_keys.dart';

// Shared component imports
import 'shared/ui_test_helpers.dart';
import 'shared/pump_sequences.dart';
import 'shared/settings_helpers.dart';
import 'shared/game_ui_config.dart';
import 'shared/provider_helpers.dart';

/// Target Tag - Test 1 Isolated
///
/// This file tests ONLY Test 1 from the menu and mechanics file
/// to isolate the failing test and debug it.
///
/// Run with:
/// ```bash
/// # Terminal 1: Start chromedriver
/// cd dart_games/chromedriver/chromedriver-win64
/// ./chromedriver.exe --port=4444
///
/// # Terminal 2: Run tests
/// flutter drive --driver=test_driver/integration_test.dart \
///   --target=integration_test/temp_test_1_isolated.dart \
///   -d chrome
/// ```

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Game configuration for Target Tag
  final config = GameUIConfig.targetTag();

  // ===== MOCK API DART THROWING HELPERS =====
  // These are specific to gameplay tests that need MockScoliaApiService

  /// Get MockScoliaApiService from the widget tree
  MockScoliaApiService? getMockApi(WidgetTester tester) {
    final dartboardProvider = ProviderHelpers.getDartboardProvider(tester);
    return dartboardProvider.apiService;
  }

  /// Simulate hitting a specific dartboard number using mock API
  Future<void> throwDartViaMock(WidgetTester tester, int number, {String multiplier = 'single'}) async {
    final mockApi = getMockApi(tester);
    if (mockApi != null) {
      mockApi.simulateDartThrow(
        score: number * (multiplier == 'double' ? 2 : multiplier == 'triple' ? 3 : 1),
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

  /// Simulate hitting bullseye (50 points) using mock API
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

  /// Simulate hitting outer bull (25 points) using mock API
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

  /// Simulate missing the dartboard using mock API
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
      await PumpSequences.simpleUpdate(tester);
    }
  }

  /// Click DARTS REMOVED button on emulator
  Future<void> clickDartsRemoved(WidgetTester tester) async {
    final dartsRemovedButton = find.text('DARTS REMOVED');
    if (dartsRemovedButton.evaluate().isNotEmpty) {
      await tester.tap(dartsRemovedButton.first);
      await PumpSequences.simpleUpdate(tester);
    }
  }

  /// Enable Hero Bonus by tapping the hero bonus switch
  Future<void> enableHeroBonus(WidgetTester tester) async {
    await SettingsHelpers.toggleTargetTagHeroBonus(tester);
    await PumpSequences.simpleUpdate(tester);
  }

  /// Enable Team Mode by tapping the team mode switch
  Future<void> enableTeamMode(WidgetTester tester) async {
    await SettingsHelpers.toggleTargetTagTeamMode(tester);
    await PumpSequences.fullRebuild(tester);
  }

  /// Navigate back to menu from game screen
  Future<void> navigateBackToMenu(WidgetTester tester) async {
    final backButton = find.byTooltip('Back');
    if (backButton.evaluate().isNotEmpty) {
      await tester.tap(backButton.first);
      await PumpSequences.navigation(tester);
    }
  }

  /// Extract hero buff value from active panel using key
  /// Returns the buff value found in the buff value widget
  String? getHeroBuffFromActivePanel(WidgetTester tester) {
    final buffValueFinder = find.byKey(TargetTagGameKeys.activePlayerBuffValue);

    if (buffValueFinder.evaluate().isEmpty) {
      return null;
    }

    final textWidget = tester.widget<Text>(buffValueFinder.first);
    final buffValue = textWidget.data ?? '';
    return buffValue.isNotEmpty ? buffValue : null;
  }

  group('Target Tag - Test 1 Isolated', () {
    setUp(() async {
      // Initialize settings with emulator mode
      await SettingsHelpers.initializeSettings();
    });

    testWidgets('Test 1: Hero Bonus Toggle and Display - Validates hero bonus OFF shows no buff label, hero bonus ON displays buff label and value in solo mode, hero bonus displays correctly in team mode with random assignment, buff numbers and multipliers shown correctly', (WidgetTester tester) async {
      // ===== Step 1: Verify hero bonus OFF shows no buff =====
      await UITestHelpers.navigateToGameMenu(tester, config);

      // Add 3 players with hero bonus OFF (default state)
      await UITestHelpers.addPlayer(tester, 'Player A', config);
      await UITestHelpers.addPlayer(tester, 'Player B', config);
      await UITestHelpers.addPlayer(tester, 'Player C', config);

      // Verify players were added
      expect(find.text('Player A'), findsWidgets);
      expect(find.text('Player B'), findsWidgets);
      expect(find.text('Player C'), findsWidgets);

      // ===== Step 2: Start game with hero bonus OFF and verify no buff =====
      await UITestHelpers.startGame(tester, config);

      // Verify we're on the game screen
      expect(find.text('Target Tag Game On!'), findsOneWidget);

      // Verify active player panel shows "Target number:" (not tagged in)
      expect(find.textContaining('Target number:'), findsWidgets);

      // Verify NO "Buff:" text appears when hero bonus is OFF
      expect(find.textContaining('Buff:'), findsNothing);

      // Verify NOT showing "Opponent targets:" yet (not tagged in)
      expect(find.textContaining('Opponent targets:'), findsNothing);

      // ===== Step 3: Return to menu, enable hero bonus, and start game =====
      await navigateBackToMenu(tester);

      // Enable hero bonus
      await enableHeroBonus(tester);

      // Verify hero bonus is now ON (toggle should be enabled)
      final heroBonusSwitch = find.byType(Switch).last;
      final switchWidget = tester.widget<Switch>(heroBonusSwitch);
      expect(switchWidget.value, isTrue);

      // Start the game again
      await UITestHelpers.startGame(tester, config);

      // Verify we're on the game screen
      final titleFinder = find.text('Target Tag Game On!');
      expect(titleFinder, findsOneWidget);

      // ===== Step 4: Verify hero buff displays in solo mode =====
      final targetNumberFinder = find.textContaining('Target number:');
      expect(targetNumberFinder, findsWidgets);

      final buffFinder = find.textContaining('Buff:');
      expect(buffFinder, findsWidgets);

      // Extract and validate the buff value (should be dart notation like D3, T16)
      final buffValue = getHeroBuffFromActivePanel(tester);
      expect(buffValue, isNotNull);
      // Buff should be in dart notation: D1-D20 or T1-T20
      final buffPattern = RegExp(r'^[DT]\d{1,2}$');
      expect(buffPattern.hasMatch(buffValue!), isTrue,
          reason: 'Buff value should be dart notation (D1-D20 or T1-T20), got: $buffValue');

      // ===== Step 5: Return to menu and enable team mode =====
      await navigateBackToMenu(tester);

      // Enable team mode (this will also enable random team assignment)
      await enableTeamMode(tester);

      // Verify team mode is enabled
      final teamModeSwitch = find.byType(Switch).first;
      final teamModeSwitchWidget = tester.widget<Switch>(teamModeSwitch);
      expect(teamModeSwitchWidget.value, isTrue);

      // Start the game in team mode
      await UITestHelpers.startGame(tester, config);

      // Verify we're on the game screen
      final teamTitleFinder = find.text('Target Tag Game On!');
      expect(teamTitleFinder, findsOneWidget);

      // ===== Step 6: Verify hero buff displays correctly in team mode =====
      // In team mode, buff is shared per team
      final teamTargetFinder = find.textContaining('Target number:');
      expect(teamTargetFinder, findsWidgets);

      final teamBuffFinder = find.textContaining('Buff:');
      expect(teamBuffFinder, findsWidgets);

      // Extract and validate the team buff value
      final teamBuffValue = getHeroBuffFromActivePanel(tester);
      expect(teamBuffValue, isNotNull);
      // Buff should be in dart notation: D1-D20 or T1-T20
      expect(buffPattern.hasMatch(teamBuffValue!), isTrue,
          reason: 'Team buff value should be dart notation (D1-D20 or T1-T20), got: $teamBuffValue');
    });
  });
}
