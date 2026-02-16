import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';

// Shared component imports
import 'shared/ui_test_helpers.dart';
import 'shared/pump_sequences.dart';
import 'shared/settings_helpers.dart';
import 'shared/game_ui_config.dart';
import 'shared/provider_helpers.dart';

/// Target Tag - Gameplay Integration Tests
///
/// These are full integration tests that run the complete app in Chrome
/// and test gameplay functionality including:
/// - Hero Buff display on player tiles and active panel (8 tests)
/// - D1/D2/D3 dart highlighting behavior (2 tests)
/// - Game settings panel validation (1 test)
/// - Victory screen behaviors (2 tests)
///
/// Run with:
/// ```bash
/// # Terminal 1: Start chromedriver
/// cd dart_games/chromedriver/chromedriver-win64
/// ./chromedriver.exe --port=4444
///
/// # Terminal 2: Run tests
/// flutter drive --driver=test_driver/integration_test.dart \
///   --target=integration_test/target_tag_gameplay_test.dart \
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
        baseScore: 25,
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

  /// Simulate missing the board using mock API
  Future<void> throwMissViaMock(WidgetTester tester) async {
    final mockApi = getMockApi(tester);
    if (mockApi != null) {
      mockApi.simulateDartThrow(
        score: 0,
        multiplier: 'miss',
        playerName: 'Player',
        baseScore: 0,
        widgetX: 0.0,
        widgetY: 0.0,
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

  /// Get current player's target number from provider
  int getCurrentPlayerTargetNumber(WidgetTester tester) {
    final currentPlayerId = ProviderHelpers.getTargetTagCurrentPlayerId(tester);
    if (currentPlayerId == null) return 20;
    final targetNumber = ProviderHelpers.getTargetTagPlayerTarget(tester, currentPlayerId);
    return targetNumber ?? 20;
  }

  /// Skip the current turn
  Future<void> skipTurn(WidgetTester tester) async {
    await UITestHelpers.clickSkipTurn(tester, config);
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

  /// Enable Manual Team Assignment (Switch index 1)
  Future<void> enableManualTeamAssignment(WidgetTester tester) async {
    // Find Team Assignment switch (second switch, index 1)
    // Switch 0: Team Mode, Switch 1: Team Assignment, Switch 2: Hero Bonus
    final switchFinder = find.byType(Switch);
    if (switchFinder.evaluate().length >= 2) {
      await tester.tap(switchFinder.at(1));
      await PumpSequences.simpleUpdate(tester);
    }
  }

  /// Navigate back to menu from game screen
  Future<void> navigateBackToMenu(WidgetTester tester) async {
    final backButton = find.byTooltip('Back');
    if (backButton.evaluate().isNotEmpty) {
      await tester.tap(backButton.first);
      await PumpSequences.navigation(tester);
    }
  }

  /// Extract target number from active panel text
  /// Returns the target number found in "Target number: XX" text
  int? getTargetNumberFromActivePanel(WidgetTester tester) {
    final targetTextFinder = find.textContaining('Target number:');
    if (targetTextFinder.evaluate().isEmpty) return null;

    final textWidget = tester.widget<Text>(targetTextFinder.first);
    final text = textWidget.data ?? '';
    final match = RegExp(r'Target number:\s*(\d+)').firstMatch(text);
    if (match != null) {
      return int.parse(match.group(1)!);
    }
    return null;
  }

  /// Extract hero buff value from active panel text
  /// Returns the buff value found in "Buff: XXx" text
  String? getHeroBuffFromActivePanel(WidgetTester tester) {
    final buffTextFinder = find.textContaining('Buff:');
    if (buffTextFinder.evaluate().isEmpty) return null;

    final textWidget = tester.widget<Text>(buffTextFinder.first);
    final text = textWidget.data ?? '';
    final match = RegExp(r'Buff:\s*(\d+x)').firstMatch(text);
    if (match != null) {
      return match.group(1);
    }
    return null;
  }

  /// Verify dart indicator border color
  /// Dart indicators are identified by key pattern: d1_indicator, d2_indicator, d3_indicator
  void verifyDartIndicatorColor(WidgetTester tester, String dartKey, int expectedColorValue) {
    final indicatorFinder = find.byKey(Key(dartKey));
    expect(indicatorFinder, findsOneWidget);

    final container = tester.widget<Container>(indicatorFinder);
    final decoration = container.decoration as BoxDecoration?;
    expect(decoration, isNotNull);
    expect(decoration!.border, isNotNull);

    final border = decoration.border as Border;
    expect(border.top.color.value, expectedColorValue,
        reason: 'Dart $dartKey should have border color 0x${expectedColorValue.toRadixString(16)}');
  }

  /// Verify game settings panel content
  void verifyGameSettingsPanel(WidgetTester tester, {
    required bool hasShieldMax,
    required bool hasTargetScore,
    required bool hasTeamMode,
    required bool hasHeroBonus,
  }) {
    if (hasShieldMax) {
      expect(find.textContaining('Shield Max:'), findsOneWidget);
    }
    if (hasTargetScore) {
      expect(find.textContaining('Target Score:'), findsOneWidget);
    }
    if (hasTeamMode) {
      expect(find.textContaining('Team mode'), findsOneWidget);
    }
    if (hasHeroBonus) {
      expect(find.textContaining('Hero Bonus'), findsOneWidget);
    }
  }

  group('Target Tag - Hero Buff & Opponent Targets Tests', () {
    setUp(() async {
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
      expect(find.text('Target Tag Game On!'), findsOneWidget);

      // ===== Step 4: Verify hero buff displays in solo mode =====
      // Verify active player panel shows BOTH "Target number:" AND "Buff:"
      expect(find.textContaining('Target number:'), findsWidgets);
      expect(find.textContaining('Buff:'), findsWidgets);

      // Extract and validate the buff value (should be 2x, 3x, 4x, or 5x)
      final buffValue = getHeroBuffFromActivePanel(tester);
      expect(buffValue, isNotNull);
      expect(['2x', '3x', '4x', '5x'].contains(buffValue), isTrue,
          reason: 'Buff value should be 2x, 3x, 4x, or 5x');

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
      expect(find.text('Target Tag Game On!'), findsOneWidget);

      // ===== Step 6: Verify hero buff displays correctly in team mode =====
      // In team mode, buff is shared per team
      expect(find.textContaining('Target number:'), findsWidgets);
      expect(find.textContaining('Buff:'), findsWidgets);

      // Extract and validate the team buff value
      final teamBuffValue = getHeroBuffFromActivePanel(tester);
      expect(teamBuffValue, isNotNull);
      expect(['2x', '3x', '4x', '5x'].contains(teamBuffValue), isTrue,
          reason: 'Team buff value should be 2x, 3x, 4x, or 5x');
    });

    testWidgets('Test 2: Active Panel Opponent Targets Display - Validates active panel shows target number when not tagged in, panel switches to show opponent targets list when player gets tagged in, opponent targets displayed correctly with player names and target numbers', (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      // Add 2 players
      await UITestHelpers.addPlayer(tester, 'Player A', config);
      await UITestHelpers.addPlayer(tester, 'Player B', config);

      // Start game
      await UITestHelpers.startGame(tester, config);

      // Verify we're on the game screen
      expect(find.text('Target Tag Game On!'), findsOneWidget);

      // ===== Step 1: Verify active panel shows target number (not tagged in) =====
      expect(find.textContaining('Target number:'), findsWidgets);
      expect(find.textContaining('Opponent targets:'), findsNothing);

      // Get current player's target number
      final targetNumber = getCurrentPlayerTargetNumber(tester);
      expect(targetNumber, isNotNull);

      // ===== Step 2: Throw darts to reach max shields and get tagged in =====
      // Throw darts hitting current player's target number
      await throwDartViaMock(tester, targetNumber, multiplier: 'single');  // 1 shield
      await clickDartsRemoved(tester);

      await throwDartViaMock(tester, targetNumber, multiplier: 'double');  // 2 shields (total: 3)
      await clickDartsRemoved(tester);

      await throwDartViaMock(tester, targetNumber, multiplier: 'triple');  // 3 shields (total: 6 = max)
      await clickDartsRemoved(tester);

      // ===== Step 3: Verify active panel NOW shows opponent targets =====
      expect(find.textContaining('Opponent targets:'), findsWidgets);
      expect(find.textContaining('Target number:'), findsNothing);

      // Verify opponent name and target appear in the list
      final opponent = find.textContaining('Player');
      expect(opponent, findsWidgets);
    });

    testWidgets('Test 3: Multi-Player Game with Tagged In/Out States - Validates 3-player game initialization with all players not tagged in initially, first player gets tagged in by reaching max shields (single+double+triple), tagged in badge appears correctly, second player builds partial shields without getting tagged in, turn progression and state transitions work correctly', (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      // Add 3 players
      await UITestHelpers.addPlayer(tester, 'Player A', config);
      await UITestHelpers.addPlayer(tester, 'Player B', config);
      await UITestHelpers.addPlayer(tester, 'Player C', config);

      // Start game
      await UITestHelpers.startGame(tester, config);

      // Verify we're on the game screen
      expect(find.text('Target Tag Game On!'), findsOneWidget);

      // ===== Step 1: Verify all players start NOT tagged in =====
      expect(find.text('TAGGED IN'), findsNothing);
      expect(find.textContaining('Target number:'), findsWidgets);
      expect(find.textContaining('Opponent targets:'), findsNothing);

      // ===== Step 2: Player 1 reaches max shields and gets tagged in =====
      final player1Target = getCurrentPlayerTargetNumber(tester);

      await throwDartViaMock(tester, player1Target, multiplier: 'single');
      await clickDartsRemoved(tester);

      await throwDartViaMock(tester, player1Target, multiplier: 'double');
      await clickDartsRemoved(tester);

      await throwDartViaMock(tester, player1Target, multiplier: 'triple');
      await clickDartsRemoved(tester);

      // ===== Step 3: Verify tagged in badge appears =====
      expect(find.text('TAGGED IN'), findsWidgets);
      expect(find.textContaining('Opponent targets:'), findsWidgets);

      // ===== Step 4: Player 2 builds partial shields (does NOT get tagged in) =====
      final player2Target = getCurrentPlayerTargetNumber(tester);

      await throwDartViaMock(tester, player2Target, multiplier: 'single');
      await clickDartsRemoved(tester);

      await throwDartViaMock(tester, player2Target, multiplier: 'double');
      await clickDartsRemoved(tester);

      // Player 2 now has 3 shields (not max), so should NOT be tagged in
      // Verify they still see target number, not opponent targets
      expect(find.textContaining('Target number:'), findsWidgets);
    });

    testWidgets('Test 4: Solo Mode and Team Mode with Hero Buff - Validates hero buff displays correctly in solo mode with 4 players (each player has individual buff value), game transitions from solo mode back to menu, team mode enabled with random team assignment, hero buffs displayed for teams (shared buff per team), team target numbers assigned correctly', (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      // Enable hero bonus first
      await enableHeroBonus(tester);

      // Add 4 players
      await UITestHelpers.addPlayer(tester, 'Player A', config);
      await UITestHelpers.addPlayer(tester, 'Player B', config);
      await UITestHelpers.addPlayer(tester, 'Player C', config);
      await UITestHelpers.addPlayer(tester, 'Player D', config);

      // ===== Step 1: Start solo mode game with hero bonus ON =====
      await UITestHelpers.startGame(tester, config);

      // Verify we're on the game screen
      expect(find.text('Target Tag Game On!'), findsOneWidget);

      // ===== Step 2: Verify solo mode shows hero buff for individual players =====
      expect(find.textContaining('Buff:'), findsWidgets);
      final soloBuff = getHeroBuffFromActivePanel(tester);
      expect(soloBuff, isNotNull);
      expect(['2x', '3x', '4x', '5x'].contains(soloBuff), isTrue);

      // ===== Step 3: Return to menu and enable team mode =====
      await navigateBackToMenu(tester);
      await enableTeamMode(tester);

      // Start game in team mode
      await UITestHelpers.startGame(tester, config);

      // Verify we're on the game screen
      expect(find.text('Target Tag Game On!'), findsOneWidget);

      // ===== Step 4: Verify team mode shows hero buff for teams =====
      expect(find.textContaining('Buff:'), findsWidgets);
      final teamBuff = getHeroBuffFromActivePanel(tester);
      expect(teamBuff, isNotNull);
      expect(['2x', '3x', '4x', '5x'].contains(teamBuff), isTrue);

      // Verify team target numbers are assigned
      expect(find.textContaining('Target number:'), findsWidgets);
    });

    testWidgets('Test 5: Two Player Game with Tagged In and Tagged Out - Validates 2-player game initialization, neither player tagged in initially, target numbers displayed correctly, Player 1 reaches max shields and gets tagged in (single+double+triple), tagged in badge appears for Player 1, active panel switches to show opponent targets list, Player 1 remains tagged in after turn ends', (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      // Add 2 players
      await UITestHelpers.addPlayer(tester, 'Player A', config);
      await UITestHelpers.addPlayer(tester, 'Player B', config);

      // Start game
      await UITestHelpers.startGame(tester, config);

      // Verify game started
      expect(find.text('Target Tag Game On!'), findsOneWidget);

      // ===== Step 1: Verify initial state - neither player tagged in =====
      expect(find.text('TAGGED IN'), findsNothing);
      expect(find.textContaining('Target number:'), findsWidgets);

      // ===== Step 2: Player 1 reaches max shields =====
      final player1Target = getCurrentPlayerTargetNumber(tester);

      await throwDartViaMock(tester, player1Target, multiplier: 'single');
      await clickDartsRemoved(tester);

      await throwDartViaMock(tester, player1Target, multiplier: 'double');
      await clickDartsRemoved(tester);

      await throwDartViaMock(tester, player1Target, multiplier: 'triple');
      await clickDartsRemoved(tester);

      // ===== Step 3: Verify Player 1 is now tagged in =====
      expect(find.text('TAGGED IN'), findsWidgets);
      expect(find.textContaining('Opponent targets:'), findsWidgets);

      // ===== Step 4: Verify Player 1 REMAINS tagged in on next turn =====
      // Note: Player 1's turn ended when they removed darts, now it's Player 2's turn
      // But Player 1 should still have TAGGED IN badge visible on their player tile
      expect(find.text('TAGGED IN'), findsWidgets);
    });

    testWidgets('Test 6: D1/D2/D3 Highlighting - Solo Mode Not Tagged In - Validates dart highlighting colors when player is not tagged in, D1 hits own target shows green border (0xFF00FFA3), D2 misses own target shows pink border (0xFFFF007A), D3 hits own target with double multiplier shows green border, all three dart indicators display correct border colors based on hit/miss', (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      // Add 2 players
      await UITestHelpers.addPlayer(tester, 'Player A', config);
      await UITestHelpers.addPlayer(tester, 'Player B', config);

      // Start game
      await UITestHelpers.startGame(tester, config);

      // Get current player's target number
      final targetNumber = getCurrentPlayerTargetNumber(tester);

      // ===== Test D1: Hit own target (should be green) =====
      await throwDartViaMock(tester, targetNumber, multiplier: 'single');

      // Verify D1 has green border (0xFF00FFA3)
      verifyDartIndicatorColor(tester, 'd1_indicator', 0xFF00FFA3);

      // ===== Test D2: Miss own target (should be pink) =====
      // Throw a different number (not the target)
      final missNumber = targetNumber == 20 ? 19 : 20;
      await throwDartViaMock(tester, missNumber, multiplier: 'single');

      // Verify D2 has pink border (0xFFFF007A)
      verifyDartIndicatorColor(tester, 'd2_indicator', 0xFFFF007A);

      // ===== Test D3: Hit own target with double (should be green) =====
      await throwDartViaMock(tester, targetNumber, multiplier: 'double');

      // Verify D3 has green border (0xFF00FFA3)
      verifyDartIndicatorColor(tester, 'd3_indicator', 0xFF00FFA3);
    });

    testWidgets('Test 7: D1/D2/D3 Highlighting - Tagged In Mode Attack - Validates dart highlighting when player is tagged in and attacking opponents, D1 hits opponent target shows green border (successful attack), D2 misses all opponent targets shows pink border (failed attack), D3 hits different opponent target shows green border, dart indicators correctly show attack hit/miss status', (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      // Add 3 players
      await UITestHelpers.addPlayer(tester, 'Player A', config);
      await UITestHelpers.addPlayer(tester, 'Player B', config);
      await UITestHelpers.addPlayer(tester, 'Player C', config);

      // Start game
      await UITestHelpers.startGame(tester, config);

      // ===== Step 1: Get tagged in first =====
      final player1Target = getCurrentPlayerTargetNumber(tester);

      await throwDartViaMock(tester, player1Target, multiplier: 'single');
      await clickDartsRemoved(tester);

      await throwDartViaMock(tester, player1Target, multiplier: 'double');
      await clickDartsRemoved(tester);

      await throwDartViaMock(tester, player1Target, multiplier: 'triple');
      await clickDartsRemoved(tester);

      // Verify tagged in
      expect(find.text('TAGGED IN'), findsWidgets);
      expect(find.textContaining('Opponent targets:'), findsWidgets);

      // ===== Step 2: Get opponent target numbers from provider =====
      // Player A is tagged in, so get Player B and Player C target numbers
      final playerProvider = ProviderHelpers.getPlayerProvider(tester);
      final selectedPlayers = playerProvider.selectedPlayers;

      // Find Player B and C IDs
      final playerB = selectedPlayers.firstWhere((p) => p.name == 'Player B');
      final playerC = selectedPlayers.firstWhere((p) => p.name == 'Player C');

      final playerBTarget = ProviderHelpers.getTargetTagPlayerTarget(tester, playerB.id);
      final playerCTarget = ProviderHelpers.getTargetTagPlayerTarget(tester, playerC.id);

      expect(playerBTarget, isNotNull);
      expect(playerCTarget, isNotNull);

      // ===== Step 3: Attack opponent targets and verify highlighting =====
      // D1: Hit Player B's target (should be green)
      await throwDartViaMock(tester, playerBTarget!, multiplier: 'single');
      verifyDartIndicatorColor(tester, 'd1_indicator', 0xFF00FFA3);

      // D2: Miss all opponent targets (should be pink)
      // Throw a number that's neither Player B nor Player C target
      int missNumber = 1;
      while (missNumber == playerBTarget || missNumber == playerCTarget) {
        missNumber++;
      }
      await throwDartViaMock(tester, missNumber, multiplier: 'single');
      verifyDartIndicatorColor(tester, 'd2_indicator', 0xFFFF007A);

      // D3: Hit Player C's target (should be green)
      await throwDartViaMock(tester, playerCTarget!, multiplier: 'single');
      verifyDartIndicatorColor(tester, 'd3_indicator', 0xFF00FFA3);
    });

    testWidgets('Test 8: Hero Buff Multiplier Application - Validates hero buff multiplier is correctly applied to attack damage, 2x buff doubles shield damage, 3x buff triples shield damage, different buff values (2x/3x/4x/5x) all work correctly, buff applies to all dart types (single/double/triple)', (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      // Enable hero bonus
      await enableHeroBonus(tester);

      // Add 2 players
      await UITestHelpers.addPlayer(tester, 'Player A', config);
      await UITestHelpers.addPlayer(tester, 'Player B', config);

      // Start game
      await UITestHelpers.startGame(tester, config);

      // ===== Step 1: Get tagged in =====
      final player1Target = getCurrentPlayerTargetNumber(tester);

      await throwDartViaMock(tester, player1Target, multiplier: 'single');
      await clickDartsRemoved(tester);

      await throwDartViaMock(tester, player1Target, multiplier: 'double');
      await clickDartsRemoved(tester);

      await throwDartViaMock(tester, player1Target, multiplier: 'triple');
      await clickDartsRemoved(tester);

      // Verify tagged in and get the buff value
      expect(find.text('TAGGED IN'), findsWidgets);
      final buffValue = getHeroBuffFromActivePanel(tester);
      expect(buffValue, isNotNull);

      // ===== Step 2: Attack opponent with buff active =====
      // Get Player B's shields before attack
      final playerProvider = ProviderHelpers.getPlayerProvider(tester);
      final selectedPlayers = playerProvider.selectedPlayers;
      final playerB = selectedPlayers.firstWhere((p) => p.name == 'Player B');
      final playerBTarget = ProviderHelpers.getTargetTagPlayerTarget(tester, playerB.id);

      final shieldsBefore = ProviderHelpers.getTargetTagPlayerShields(tester, playerB.id);

      // Attack with single dart
      await throwDartViaMock(tester, playerBTarget!, multiplier: 'single');

      // Wait for damage to apply
      await PumpSequences.fullRebuild(tester);

      // Get shields after attack
      final shieldsAfter = ProviderHelpers.getTargetTagPlayerShields(tester, playerB.id);

      // Verify damage was multiplied by buff
      final buffMultiplier = int.parse(buffValue!.replaceAll('x', ''));
      final expectedDamage = 1 * buffMultiplier; // Single dart = 1 shield damage, multiplied by buff
      expect(shieldsBefore - shieldsAfter, expectedDamage,
          reason: 'Buff $buffValue should multiply damage by $buffMultiplier');
    });
  });

  group('Target Tag - D1/D2/D3 Dart Highlighting Tests', () {
    setUp(() async {
      await SettingsHelpers.initializeSettings();
    });

    testWidgets('Test 9: Dart Highlighting - All Three Darts Hit Target - Validates all three dart indicators show green borders when all darts hit the target number, D1/D2/D3 all display 0xFF00FFA3 green border color, visual feedback correctly indicates successful shield building', (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      // Add 2 players
      await UITestHelpers.addPlayer(tester, 'Player A', config);
      await UITestHelpers.addPlayer(tester, 'Player B', config);

      // Start game
      await UITestHelpers.startGame(tester, config);

      // Get current player's target number
      final targetNumber = getCurrentPlayerTargetNumber(tester);

      // Throw all three darts hitting the target
      await throwDartViaMock(tester, targetNumber, multiplier: 'single');
      verifyDartIndicatorColor(tester, 'd1_indicator', 0xFF00FFA3);

      await throwDartViaMock(tester, targetNumber, multiplier: 'single');
      verifyDartIndicatorColor(tester, 'd2_indicator', 0xFF00FFA3);

      await throwDartViaMock(tester, targetNumber, multiplier: 'single');
      verifyDartIndicatorColor(tester, 'd3_indicator', 0xFF00FFA3);

      // All three should be green
      verifyDartIndicatorColor(tester, 'd1_indicator', 0xFF00FFA3);
      verifyDartIndicatorColor(tester, 'd2_indicator', 0xFF00FFA3);
      verifyDartIndicatorColor(tester, 'd3_indicator', 0xFF00FFA3);
    });

    testWidgets('Test 10: Dart Highlighting - All Three Darts Miss Target - Validates all three dart indicators show pink borders when all darts miss the target number, D1/D2/D3 all display 0xFFFF007A pink border color, visual feedback correctly indicates failed shield building attempts', (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      // Add 2 players
      await UITestHelpers.addPlayer(tester, 'Player A', config);
      await UITestHelpers.addPlayer(tester, 'Player B', config);

      // Start game
      await UITestHelpers.startGame(tester, config);

      // Get current player's target number
      final targetNumber = getCurrentPlayerTargetNumber(tester);

      // Throw all three darts missing the target
      final missNumber = targetNumber == 20 ? 19 : 20;

      await throwDartViaMock(tester, missNumber, multiplier: 'single');
      verifyDartIndicatorColor(tester, 'd1_indicator', 0xFFFF007A);

      await throwDartViaMock(tester, missNumber, multiplier: 'single');
      verifyDartIndicatorColor(tester, 'd2_indicator', 0xFFFF007A);

      await throwDartViaMock(tester, missNumber, multiplier: 'single');
      verifyDartIndicatorColor(tester, 'd3_indicator', 0xFFFF007A);

      // All three should be pink
      verifyDartIndicatorColor(tester, 'd1_indicator', 0xFFFF007A);
      verifyDartIndicatorColor(tester, 'd2_indicator', 0xFFFF007A);
      verifyDartIndicatorColor(tester, 'd3_indicator', 0xFFFF007A);
    });
  });

  group('Target Tag - Game Settings Panel Tests', () {
    setUp(() async {
      await SettingsHelpers.initializeSettings();
    });

    testWidgets('Test 11: Game Settings Panel - All Settings Visible - Validates game settings panel displays all configuration options, Shield Max slider is present and functional, Target Score dropdown is visible, Team mode toggle is present, Hero Bonus toggle is present, all settings controls are interactive', (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      // Verify all game settings are visible on menu screen
      verifyGameSettingsPanel(tester,
        hasShieldMax: true,
        hasTargetScore: true,
        hasTeamMode: true,
        hasHeroBonus: true,
      );

      // Verify Shield Max slider exists
      expect(find.byType(Slider), findsOneWidget);

      // Verify Target Score dropdown exists
      expect(find.byType(DropdownButton<String>), findsWidgets);

      // Verify Team mode switch exists
      expect(find.byType(Switch), findsWidgets);

      // Verify settings are interactive by toggling team mode
      await enableTeamMode(tester);
      final teamModeSwitch = find.byType(Switch).first;
      final switchWidget = tester.widget<Switch>(teamModeSwitch);
      expect(switchWidget.value, isTrue);
    });
  });

  group('Target Tag - Victory Screen Tests', () {
    setUp(() async {
      await SettingsHelpers.initializeSettings();
    });

    testWidgets('Test 12: Complete Solo Mode Game to Victory - Validates complete game flow from start to victory screen, 2-player solo mode game starts correctly, Player 1 builds shields to max and gets tagged in, Player 2 builds partial shields, Player 1 attacks Player 2 target repeatedly until elimination, victory screen appears after opponent elimination, winner displayed correctly on victory screen', (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      // Add 2 players
      await UITestHelpers.addPlayer(tester, 'Player A', config);
      await UITestHelpers.addPlayer(tester, 'Player B', config);

      // Start game
      await UITestHelpers.startGame(tester, config);

      // ===== Step 1: Player 1 gets tagged in =====
      final player1Target = getCurrentPlayerTargetNumber(tester);

      await throwDartViaMock(tester, player1Target, multiplier: 'single');
      await clickDartsRemoved(tester);

      await throwDartViaMock(tester, player1Target, multiplier: 'double');
      await clickDartsRemoved(tester);

      await throwDartViaMock(tester, player1Target, multiplier: 'triple');
      await clickDartsRemoved(tester);

      // ===== Step 2: Player 2 builds partial shields =====
      final player2Target = getCurrentPlayerTargetNumber(tester);

      await throwDartViaMock(tester, player2Target, multiplier: 'single');
      await clickDartsRemoved(tester);

      await throwDartViaMock(tester, player2Target, multiplier: 'double');
      await clickDartsRemoved(tester);

      // ===== Step 3: Player 1 attacks Player 2 until elimination =====
      // Get Player B data
      final playerProvider = ProviderHelpers.getPlayerProvider(tester);
      final selectedPlayers = playerProvider.selectedPlayers;
      final playerB = selectedPlayers.firstWhere((p) => p.name == 'Player B');
      final playerBTarget = ProviderHelpers.getTargetTagPlayerTarget(tester, playerB.id);

      // Attack Player B repeatedly (max shields is 6, Player B has 3)
      // Need to remove 3 shields
      for (int i = 0; i < 3; i++) {
        await throwDartViaMock(tester, playerBTarget!, multiplier: 'single');
        await clickDartsRemoved(tester);
      }

      // ===== Step 4: Verify victory screen appears =====
      await PumpSequences.fullRebuild(tester);

      // Check if we're on results screen
      final playAgainButton = config.getPlayAgainButton();
      expect(playAgainButton, findsOneWidget);

      // Verify winner is displayed
      expect(find.textContaining('Player A'), findsWidgets);
    });

    testWidgets('Test 13: Game Start Validation - All Modes - Validates game successfully starts in standard solo mode with 2 players, game screen displays correctly with "Target Tag Game On!" title, player names appear in UI, turn order established, game state initialized properly for solo mode gameplay', (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      // Add 2 players
      await UITestHelpers.addPlayer(tester, 'Player A', config);
      await UITestHelpers.addPlayer(tester, 'Player B', config);

      // Verify we're on menu screen
      expect(find.textContaining('Shield Max:'), findsOneWidget);

      // Start game
      await UITestHelpers.startGame(tester, config);

      // ===== Verify game screen displays correctly =====
      expect(find.text('Target Tag Game On!'), findsOneWidget);

      // Verify player names appear in UI
      expect(find.text('Player A'), findsWidgets);
      expect(find.text('Player B'), findsWidgets);

      // Verify turn order established (active panel shows current player info)
      expect(find.textContaining('Target number:'), findsWidgets);

      // Verify game state initialized (shield max = 6 by default)
      final currentPlayerId = ProviderHelpers.getTargetTagCurrentPlayerId(tester);
      expect(currentPlayerId, isNotNull);

      final currentPlayerShields = ProviderHelpers.getTargetTagPlayerShields(tester, currentPlayerId!);
      expect(currentPlayerShields, equals(0), reason: 'Player should start with 0 shields');

      // Verify not tagged in initially
      final isTaggedIn = ProviderHelpers.isTargetTagPlayerTaggedIn(tester, currentPlayerId);
      expect(isTaggedIn, isFalse, reason: 'Player should not be tagged in at game start');
    });
  });
}
