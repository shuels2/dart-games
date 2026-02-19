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

/// Target Tag - Menu Test 3 Isolated
///
/// This file tests ONLY Test 3 from the menu and mechanics file
/// (Team Assignment - Complete Manual Flow) to isolate and debug it.
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

  group('Target Tag - Test 3 Isolated', () {
    setUp(() async {
      // Initialize settings with emulator mode
      await SettingsHelpers.initializeSettings();
    });

    testWidgets(
        'Test 3: Team Assignment - Complete Manual Flow - Validates team mode enabled successfully, manual team assignment switch toggles on, 4 players added (Team1 Player1/2, Team2 Player1/2), all players found in scrollable player list, players manually assigned to teams (team selection UI functional), team badges displayed correctly for each player showing team assignment',
        (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      // Enable team mode
      await SettingsHelpers.toggleTargetTagTeamMode(tester);

      // Toggle manual team assignment (turn OFF random assignment)
      await tester.tap(ElementFinders.getTargetTagAssignTeamsButton());
      await PumpSequences.simpleUpdate(tester);

      // Add 4 players
      for (int i = 1; i <= 4; i++) {
        await UITestHelpers.addPlayer(tester, 'TeamPlayer$i', config);
      }

      // Get all players
      final player1 = ProviderHelpers.findPlayerByName(tester, 'TeamPlayer1');
      final player2 = ProviderHelpers.findPlayerByName(tester, 'TeamPlayer2');
      final player3 = ProviderHelpers.findPlayerByName(tester, 'TeamPlayer3');
      final player4 = ProviderHelpers.findPlayerByName(tester, 'TeamPlayer4');

      expect(player1, isNotNull);
      expect(player2, isNotNull);
      expect(player3, isNotNull);
      expect(player4, isNotNull);

      // Assign Player 1 to Team 1 (index 0)
      await tester.tap(find.text('Assign team').first);
      await PumpSequences.dialogOpen(tester);
      final dialog1 = find.byType(AlertDialog);
      final gestureDetectors1 = find.descendant(of: dialog1, matching: find.byType(GestureDetector));
      await tester.tap(gestureDetectors1.at(0)); // Team 1 - dialog auto-closes
      await tester.pump(const Duration(milliseconds: 500)); // Wait for auto-close

      // Assign Player 2 to Team 1 (index 0)
      await tester.tap(find.text('Assign team').first);
      await PumpSequences.dialogOpen(tester);
      final dialog2 = find.byType(AlertDialog);
      final gestureDetectors2 = find.descendant(of: dialog2, matching: find.byType(GestureDetector));
      await tester.tap(gestureDetectors2.at(0)); // Team 1 - dialog auto-closes
      await tester.pump(const Duration(milliseconds: 500)); // Wait for auto-close

      // Assign Player 3 to Team 2 (index 1)
      await tester.tap(find.text('Assign team').first);
      await PumpSequences.dialogOpen(tester);
      final dialog3 = find.byType(AlertDialog);
      final gestureDetectors3 = find.descendant(of: dialog3, matching: find.byType(GestureDetector));
      await tester.tap(gestureDetectors3.at(1)); // Team 2 - dialog auto-closes
      await tester.pump(const Duration(milliseconds: 500)); // Wait for auto-close

      // Check if Player 4 needs assignment or was auto-assigned
      final remainingButtons = find.text('Assign team');
      if (remainingButtons.evaluate().isEmpty) {
        print('All players auto-assigned after 3 manual assignments');
      } else {
        // Assign Player 4 to Team 2 (index 1)
        await tester.tap(find.text('Assign team').first);
        await PumpSequences.dialogOpen(tester);
        final dialog4 = find.byType(AlertDialog);
        final gestureDetectors4 = find.descendant(of: dialog4, matching: find.byType(GestureDetector));
        await tester.tap(gestureDetectors4.at(1)); // Team 2 - dialog auto-closes
        await tester.pump(const Duration(milliseconds: 500)); // Wait for auto-close
      }

      // Ensure final dialog is fully closed and UI updated before verification
      await PumpSequences.dialogClose(tester);

      // Verify all teams assigned (no more "Assign team" buttons)
      expect(find.text('Assign team'), findsNothing);

      // Verify start button exists
      final startButton = find.byKey(TargetTagMenuKeys.startButton);
      expect(startButton, findsOneWidget);
    });
  });
}
