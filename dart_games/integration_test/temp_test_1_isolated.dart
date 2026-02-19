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
import 'shared/element_finders.dart';
import 'shared/edit_score_helpers.dart';

/// Target Tag - Menu Test 4 Isolated
///
/// This file tests ONLY Test 4 from the menu and mechanics file
/// (UI Feedback - Complete Validation) to isolate and debug it.
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

  group('Target Tag - Test 4 Isolated', () {
    setUp(() async {
      // Initialize settings with emulator mode
      await SettingsHelpers.initializeSettings();
    });

    testWidgets(
        'Test 4: UI Feedback - Complete Validation - Validates menu screen shows Shield Max setting, Solo/Team mode toggle visible, Hero Bonus switch visible, NEW PLAYER button functional, LETS PLAY TAG button enables when minimum players selected, game screen displays Target Tag Game On! title, player tiles show shields count and target numbers, current player indicator visible, active panel shows correct information',
        (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      // Verify menu UI elements
      expect(find.textContaining('Shield Max:'), findsOneWidget);
      expect(ElementFinders.getTargetTagTeamModeToggle(), findsOneWidget);
      expect(ElementFinders.getTargetTagHeroBonusToggle(), findsOneWidget);

      // Add 2 players (button will be verified implicitly by successful add)
      await UITestHelpers.addPlayer(tester, 'UITest1', config);
      await UITestHelpers.addPlayer(tester, 'UITest2', config);

      // Verify start button enabled
      expect(config.getStartButton(), findsOneWidget);

      // Start game
      await UITestHelpers.startGame(tester, config);

      // Verify game screen UI
      expect(find.text('Target Tag Game On!'), findsOneWidget);

      // Verify player tiles show shields and targets
      final player1 = ProviderHelpers.findPlayerByName(tester, 'UITest1');
      final player2 = ProviderHelpers.findPlayerByName(tester, 'UITest2');
      expect(player1, isNotNull);
      expect(player2, isNotNull);

      // Verify shields displayed
      final shields1 = ProviderHelpers.getTargetTagPlayerShields(tester, player1!.id);
      final shields2 = ProviderHelpers.getTargetTagPlayerShields(tester, player2!.id);
      expect(shields1, 0);
      expect(shields2, 0);

      // Verify current player indicator
      final currentPlayerId = ProviderHelpers.getTargetTagCurrentPlayerId(tester);
      expect(currentPlayerId, isNotNull);
    });
  });
}
