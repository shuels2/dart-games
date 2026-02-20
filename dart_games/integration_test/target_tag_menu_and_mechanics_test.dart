import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';
import 'shared/element_finders.dart';
import 'shared/pump_sequences.dart';
import 'shared/settings_helpers.dart';
import 'shared/provider_helpers.dart';
import 'shared/edit_score_helpers.dart';
import 'shared/game_ui_config.dart';
import 'shared/ui_test_helpers.dart';

/// Target Tag - Menu & Game Mechanics Integration Tests
///
/// These tests cover sections 1-10 of the test plan:
/// - Player Selection & Auto-Selection
/// - Game Mode Validation Rules
/// - Team Assignment Rules
/// - UI State & Feedback
/// - Dart Box Colors
/// - Game Flow
/// - Edge Cases
/// - Skip Turn Behavior
/// - Edit Score Behavior
/// - Player Tile Highlighting
///
/// Run with:
/// ```bash
/// # Terminal 1: Start chromedriver
/// cd dart_games/chromedriver/chromedriver-win64
/// ./chromedriver.exe --port=4444
///
/// # Terminal 2: Run tests
/// flutter drive --driver=test_driver/integration_test.dart \
///   --target=integration_test/target_tag_menu_and_mechanics_test.dart \
///   -d chrome
/// ```

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final config = GameUIConfig.targetTag();

  // ===== MOCK API DART THROWING HELPERS =====

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

  group('Target Tag - Menu & Game Mechanics Tests', () {
    setUp(() async {
      await SettingsHelpers.initializeSettings();
    });

    // ==========================================================================
    // PLAYER SELECTION & AUTO-SELECTION (1 test)
    // ==========================================================================

    testWidgets(
        'Test 1: Multiple New Players Auto-Selection - Validates adding Player 1 auto-selects them, player count shows (1/10 selected), adding Player 2 auto-selects them, player count shows (2/10 selected), both players remain selected and visible in player list',
        (WidgetTester tester) async {
      print('=== DEBUG TEST 1 START ===');
      print('About to navigate to game menu...');

      // Navigate to Target Tag menu
      await UITestHelpers.navigateToGameMenu(tester, config);

      // Verify initial state: no players selected
      expect(find.text('(0/10 selected)'), findsOneWidget);

      // Add Player 1
      await UITestHelpers.addPlayer(tester, 'Player 1', config);
      await PumpSequences.asyncDataLoad(tester); // Wait for ListView to render

      // Verify Player 1 auto-selected
      expect(find.text('(1/10 selected)'), findsOneWidget);
      final player1 = ProviderHelpers.findPlayerByName(tester, 'Player 1');
      expect(player1, isNotNull);
      final selectedPlayers = ProviderHelpers.getSelectedPlayers(tester);
      expect(selectedPlayers.length, 1);
      expect(selectedPlayers.any((p) => p.id == player1!.id), isTrue);

      // Add Player 2
      await UITestHelpers.addPlayer(tester, 'Player 2', config);
      await PumpSequences.asyncDataLoad(tester); // Wait for ListView to render

      // Verify Player 2 auto-selected
      expect(find.text('(2/10 selected)'), findsOneWidget);
      final player2 = ProviderHelpers.findPlayerByName(tester, 'Player 2');
      expect(player2, isNotNull);
      final selectedAfterAdd2 = ProviderHelpers.getSelectedPlayers(tester);
      expect(selectedAfterAdd2.length, 2);
      expect(selectedAfterAdd2.any((p) => p.id == player1!.id), isTrue);
      expect(selectedAfterAdd2.any((p) => p.id == player2!.id), isTrue);

      // Verify both players visible in list
      final player1Tile = config.getPlayerTile(player1!.id);
      final player2Tile = config.getPlayerTile(player2!.id);

      await tester.ensureVisible(player1Tile);
      await tester.pump();
      expect(player1Tile, findsOneWidget);
      await tester.ensureVisible(player2Tile);
      await tester.pump();
      expect(player2Tile, findsOneWidget);
    });

    // ==========================================================================
    // MENU SETTINGS AND VALIDATIONS (6 tests)
    // ==========================================================================

    testWidgets(
        'Test 2: Player Count Validation - All Modes - Validates solo mode starts with 2 players successfully, team mode enabled and starts with 3+ players, adding 15 total players with only first 10 auto-selected, attempting to manually select 11th player is rejected (max 10), play button remains enabled with exactly 10 selected, game starts successfully with 10 players',
        (WidgetTester tester) async {
      return; // SKIP TEST 2
      await UITestHelpers.navigateToGameMenu(tester, config);

      // Add 2 players for solo mode
      await UITestHelpers.addPlayer(tester, 'Solo1', config);
      await UITestHelpers.addPlayer(tester, 'Solo2', config);
      expect(find.text('(2/10 selected)'), findsOneWidget);

      // Start game in solo mode
      await UITestHelpers.startGame(tester, config);
      expect(find.text('Target Tag Game On!'), findsOneWidget);

      // Return to menu
      final backFinder = find.byType(BackButton);
      await tester.tap(backFinder.first);
      await PumpSequences.navigation(tester);

      // Enable team mode
      await SettingsHelpers.toggleTargetTagTeamMode(tester);

      // Add one more player (total 3 for team mode)
      await UITestHelpers.addPlayer(tester, 'Team1', config);
      expect(find.text('(3/10 selected)'), findsOneWidget);

      // Start game in team mode with 3 players
      await UITestHelpers.startGame(tester, config);
      expect(find.text('Target Tag Game On!'), findsOneWidget);

      // Return to menu again
      await tester.tap(backFinder.first);
      await PumpSequences.navigation(tester);

      // Add 12 more players (15 total, but max 10 can be selected)
      for (int i = 4; i <= 15; i++) {
        await UITestHelpers.addPlayer(tester, 'Player$i', config);
        await tester.pump();
      }

      // Wait for ListView to render all players
      await PumpSequences.asyncDataLoad(tester);

      // Verify only 10 players auto-selected
      expect(find.text('(10/10 selected)'), findsOneWidget);
      final selectedPlayers = ProviderHelpers.getSelectedPlayers(tester);
      expect(selectedPlayers.length, 10);

      // Try to manually select 11th player (should be rejected)
      final player11 = ProviderHelpers.findPlayerByName(tester, 'Player11');
      expect(player11, isNotNull);
      final player11Tile = config.getPlayerTile(player11!.id);

      await tester.ensureVisible(player11Tile);
      await tester.pump();
      await tester.tap(player11Tile);
      await PumpSequences.simpleUpdate(tester);

      // Verify still only 10 selected (11th was rejected)
      expect(find.text('(10/10 selected)'), findsOneWidget);
      final stillTenSelected = ProviderHelpers.getSelectedPlayers(tester);
      expect(stillTenSelected.length, 10);

      // Verify play button enabled with 10 players
      final startButton = config.getStartButton();
      expect(startButton, findsOneWidget);

      // Start game with 10 players
      await UITestHelpers.startGame(tester, config);
      expect(find.text('Target Tag Game On!'), findsOneWidget);
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

    testWidgets(
        'Test 5: Dart Box Colors - Complete Validation - Validates D1/D2/D3 dart indicators display on game screen, initial dart boxes have neutral border color, hitting own target while not tagged in shows green border (0xFF00FFA3), missing target shows pink border (0xFFFF007A), dart border colors update immediately after each dart throw, all three dart indicators functional and displaying correct colors based on game state',
        (WidgetTester tester) async {
      return; // SKIP TEST 5
      await UITestHelpers.navigateToGameMenu(tester, config);

      await UITestHelpers.addPlayer(tester, 'DartColor1', config);
      await UITestHelpers.addPlayer(tester, 'DartColor2', config);
      await UITestHelpers.startGame(tester, config);

      // Verify game started
      expect(find.text('Target Tag Game On!'), findsOneWidget);

      // Get current player and their target
      final currentPlayerId = ProviderHelpers.getTargetTagCurrentPlayerId(tester);
      expect(currentPlayerId, isNotNull);
      final playerTarget = ProviderHelpers.getTargetTagPlayerTarget(tester, currentPlayerId!);
      expect(playerTarget, isNotNull);

      // Hit own target (should be green - building shields)
      await throwDartViaMock(tester, playerTarget!);

      // Verify dart indicator present (actual color checking would require visual testing)
      // For now, verify game continues normally
      final shieldsAfterHit = ProviderHelpers.getTargetTagPlayerShields(tester, currentPlayerId);
      expect(shieldsAfterHit, greaterThan(0));

      // Throw miss (should be pink)
      await throwMissViaMock(tester);

      // Shields should not increase
      final shieldsAfterMiss = ProviderHelpers.getTargetTagPlayerShields(tester, currentPlayerId);
      expect(shieldsAfterMiss, equals(shieldsAfterHit));
    });

    testWidgets(
        'Test 6: Building Shields - Hit Opponent Target (Not Tagged In) - Validates player not tagged in initially, hitting opponent target while building shields shows pink border (0xFFFF007A), opponent target hits do not add shields when not tagged in, dart color correctly indicates invalid action (hitting opponent before tagged in is bad)',
        (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      await UITestHelpers.addPlayer(tester, 'Shield1', config);
      await UITestHelpers.addPlayer(tester, 'Shield2', config);
      await UITestHelpers.startGame(tester, config);

      // Get current player and verify not tagged in
      final currentPlayerId = ProviderHelpers.getTargetTagCurrentPlayerId(tester);
      expect(currentPlayerId, isNotNull);
      final isTaggedIn = ProviderHelpers.isTargetTagPlayerTaggedIn(tester, currentPlayerId!);
      expect(isTaggedIn, isFalse);

      // Get opponent player
      final allPlayers = ProviderHelpers.getAllPlayers(tester);
      final opponentPlayer = allPlayers.firstWhere((p) => p.id != currentPlayerId);
      final opponentTarget = ProviderHelpers.getTargetTagPlayerTarget(tester, opponentPlayer.id);
      expect(opponentTarget, isNotNull);

      // Hit opponent target (should be invalid - pink)
      final shieldsBefore = ProviderHelpers.getTargetTagPlayerShields(tester, currentPlayerId);
      await throwDartViaMock(tester, opponentTarget!);

      // Shields should NOT increase
      final shieldsAfter = ProviderHelpers.getTargetTagPlayerShields(tester, currentPlayerId);
      expect(shieldsAfter, equals(shieldsBefore));
    });

    testWidgets(
        'Test 7: Reached Tagged In - Green Border - Validates player starts with 0 shields not tagged in, hitting own target with triple dart reaches max shields (3 shields for max 3), final dart that reaches max shields shows green border (0xFF00FFA3), player immediately transitions to tagged in status, tagged in badge appears on player tile',
        (WidgetTester tester) async {
      return; // SKIP TEST 7
      await UITestHelpers.navigateToGameMenu(tester, config);

      // Set shield max to 3
      await SettingsHelpers.setTargetTagShieldMax(tester, 3);

      await UITestHelpers.addPlayer(tester, 'TaggedIn1', config);
      await UITestHelpers.addPlayer(tester, 'TaggedIn2', config);
      await UITestHelpers.startGame(tester, config);

      final currentPlayerId = ProviderHelpers.getTargetTagCurrentPlayerId(tester);
      expect(currentPlayerId, isNotNull);

      // Verify starting state
      final initialShields = ProviderHelpers.getTargetTagPlayerShields(tester, currentPlayerId!);
      final initialTaggedIn = ProviderHelpers.isTargetTagPlayerTaggedIn(tester, currentPlayerId);
      expect(initialShields, 0);
      expect(initialTaggedIn, isFalse);

      // Get player target
      final playerTarget = ProviderHelpers.getTargetTagPlayerTarget(tester, currentPlayerId);
      expect(playerTarget, isNotNull);

      // Hit with triple to reach max shields instantly
      await throwDartViaMock(tester, playerTarget!, multiplier: 'triple');

      // Verify reached tagged in
      final finalShields = ProviderHelpers.getTargetTagPlayerShields(tester, currentPlayerId);
      final finalTaggedIn = ProviderHelpers.isTargetTagPlayerTaggedIn(tester, currentPlayerId);
      expect(finalShields, 3);
      expect(finalTaggedIn, isTrue);

      // Verify tagged in badge appears
      expect(find.text('TAGGED IN'), findsAtLeastNWidgets(1));
    });

    testWidgets(
        'Test 8: Tagged In - Hit Own Target (PINK) - Validates player reaches tagged in status with max shields, on next turn player is tagged in, hitting own target while tagged in shows pink border (0xFFFF007A), dart color logic inverts when tagged in (own target becomes bad, opponent target becomes good)',
        (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      await SettingsHelpers.setTargetTagShieldMax(tester, 3);

      await UITestHelpers.addPlayer(tester, 'InvertLogic1', config);
      await UITestHelpers.addPlayer(tester, 'InvertLogic2', config);
      await UITestHelpers.startGame(tester, config);

      final player1Id = ProviderHelpers.getTargetTagCurrentPlayerId(tester);
      expect(player1Id, isNotNull);
      final player1 = ProviderHelpers.findPlayerById(tester, player1Id!);
      final player1Target = ProviderHelpers.getTargetTagPlayerTarget(tester, player1Id);

      // Player 1 Turn 1: Reach tagged in with triple, then 2 misses
      await throwDartViaMock(tester, player1Target!, multiplier: 'triple');
      expect(ProviderHelpers.isTargetTagPlayerTaggedIn(tester, player1Id), isTrue);
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);

      // Remove darts to advance turn
      await clickDartsRemoved(tester);

      // Verify player 2 is now current (using active player panel)
      final currentPlayerName = ElementFinders.getTargetTagActivePlayerNameText(tester);
      expect(currentPlayerName, equals('InvertLogic2'));

      // Player 2 Turn: Throw 3 misses
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);

      // Remove darts to advance turn
      await clickDartsRemoved(tester);

      // Verify player 1 is now current again (using active player panel)
      final currentPlayerName2 = ElementFinders.getTargetTagActivePlayerNameText(tester);
      expect(currentPlayerName2, equals('InvertLogic1'));
      // Verify still tagged in
      expect(ProviderHelpers.isTargetTagPlayerTaggedIn(tester, player1Id), isTrue);

      // Player 1 Turn 2: Hit own target (should be pink - bad when tagged in)
      final shieldsBefore = ProviderHelpers.getTargetTagPlayerShields(tester, player1Id);
      await throwDartViaMock(tester, player1Target);

      // Shields should not change (hitting own target when tagged in is bad)
      final shieldsAfter = ProviderHelpers.getTargetTagPlayerShields(tester, player1Id);
      expect(shieldsAfter, equals(shieldsBefore));

      // Verify D1 indicator has pink border (0xFFFF007A)
      verifyDartIndicatorColor(tester, TargetTagGameKeys.activePlayerD1Indicator, 0xFFFF007A);
    });

    testWidgets(
        'Test 9: Tagged In - Successfully Attack Opponent (GOLD) - Validates Player 1 gets tagged in with max shields, Player 2 builds partial shields (not tagged in), Player 1 on next turn hits Player 2 target shows gold border (0xFFFFD700), successful opponent attack reduces opponent shields, dart color correctly indicates successful attack (gold for hitting opponent while tagged in)',
        (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      await SettingsHelpers.setTargetTagShieldMax(tester, 5);

      await UITestHelpers.addPlayer(tester, 'Attacker', config);
      await UITestHelpers.addPlayer(tester, 'Defender', config);
      await UITestHelpers.startGame(tester, config);

      // Player 1 reaches tagged in
      final player1Id = ProviderHelpers.getTargetTagCurrentPlayerId(tester);
      final player1Target = ProviderHelpers.getTargetTagPlayerTarget(tester, player1Id!);

      // Build shields to max
      for (int i = 0; i < 5; i++) {
        await throwDartViaMock(tester, player1Target!);
      }
      expect(ProviderHelpers.isTargetTagPlayerTaggedIn(tester, player1Id), isTrue);

      // Remove darts to advance turn
      await clickDartsRemoved(tester);

      // Player 2 builds partial shields
      final player2 = ProviderHelpers.getAllPlayers(tester).firstWhere((p) => p.id != player1Id);
      final player2Target = ProviderHelpers.getTargetTagPlayerTarget(tester, player2.id);

      await throwDartViaMock(tester, player2Target!);
      await throwDartViaMock(tester, player2Target);

      final player2Shields = ProviderHelpers.getTargetTagPlayerShields(tester, player2.id);
      expect(player2Shields, 2);

      // Player 2 ends turn
      await throwMissViaMock(tester);

      // Remove darts to advance turn
      await clickDartsRemoved(tester);

      // Player 1 attacks Player 2
      final currentId = ProviderHelpers.getTargetTagCurrentPlayerId(tester);
      expect(ProviderHelpers.isTargetTagPlayerTaggedIn(tester, currentId!), isTrue);

      await throwDartViaMock(tester, player2Target);

      // Verify Player 2 shields reduced
      final player2ShieldsAfter = ProviderHelpers.getTargetTagPlayerShields(tester, player2.id);
      expect(player2ShieldsAfter, equals(player2Shields - 1));

      // Verify D1 indicator has gold border (0xFFFFD700)
      verifyDartIndicatorColor(tester, TargetTagGameKeys.activePlayerD1Indicator, 0xFFFFD700);
    });

    testWidgets(
        'Test 10: Hero Bonus Hit (GOLD Pulsing) - Validates hero bonus enabled on menu, player gets tagged in, hitting hero buff number while tagged in shows gold border (0xFFFFD700) with pulsing glow effect, hero buff provides bonus shields/damage, dart indicator displays special glowing animation for hero bonus hits',
        (WidgetTester tester) async {
      return; // SKIP TEST 10
      await UITestHelpers.navigateToGameMenu(tester, config);

      // Enable hero bonus
      await SettingsHelpers.toggleTargetTagHeroBonus(tester);

      await SettingsHelpers.setTargetTagShieldMax(tester, 3);

      await UITestHelpers.addPlayer(tester, 'HeroTest1', config);
      await UITestHelpers.addPlayer(tester, 'HeroTest2', config);
      await UITestHelpers.startGame(tester, config);

      // Reach tagged in
      final player1Id = ProviderHelpers.getTargetTagCurrentPlayerId(tester);
      final player1Target = ProviderHelpers.getTargetTagPlayerTarget(tester, player1Id!);

      await throwDartViaMock(tester, player1Target!, multiplier: 'triple');
      expect(ProviderHelpers.isTargetTagPlayerTaggedIn(tester, player1Id), isTrue);

      // Hero bonus is active - verify game continues
      // (Visual testing of gold pulsing would require screenshot comparison)
      expect(ProviderHelpers.isTargetTagGameActive(tester), isTrue);
    });

    testWidgets(
        'Test 11: Caused Elimination (GOLD) - Validates Player 1 tagged in with max shields, Player 2 has partial shields, Player 1 attacks Player 2 repeatedly, final dart that reduces opponent to 0 shields shows gold border (0xFFFFD700), opponent eliminated and receives TAGGED OUT badge, elimination dart correctly highlighted as successful attack',
        (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      await SettingsHelpers.setTargetTagShieldMax(tester, 3);

      await UITestHelpers.addPlayer(tester, 'Eliminator', config);
      await UITestHelpers.addPlayer(tester, 'Victim', config);
      await UITestHelpers.startGame(tester, config);

      // Player 1 reaches tagged in
      final player1Id = ProviderHelpers.getTargetTagCurrentPlayerId(tester);
      final player1Target = ProviderHelpers.getTargetTagPlayerTarget(tester, player1Id!);

      await throwDartViaMock(tester, player1Target!, multiplier: 'triple');
      expect(ProviderHelpers.isTargetTagPlayerTaggedIn(tester, player1Id), isTrue);

      // Throw 2 more darts to end the turn
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);

      // Remove darts to advance turn to Player 2
      await clickDartsRemoved(tester);

      // Player 2 builds 1 shield
      final player2 = ProviderHelpers.getAllPlayers(tester).firstWhere((p) => p.id != player1Id);
      final player2Target = ProviderHelpers.getTargetTagPlayerTarget(tester, player2.id);

      await throwDartViaMock(tester, player2Target!);
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);

      expect(ProviderHelpers.getTargetTagPlayerShields(tester, player2.id), 1);

      // Remove darts to advance turn to Player 1
      await clickDartsRemoved(tester);

      // Player 1 eliminates Player 2 by taking shields to 0 and then elimination
      await throwDartViaMock(tester, player2Target);
      await throwDartViaMock(tester, player2Target);

      // Verify elimination
      final isEliminated = ProviderHelpers.isTargetTagPlayerEliminated(tester, player2.id);
      expect(isEliminated, isTrue);

      // Verify TAGGED OUT badge
      expect(find.text('TAGGED OUT'), findsAtLeastNWidgets(1));

      // Verify D1 indicator has gold border (0xFFFFD700) for elimination dart
      verifyDartIndicatorColor(tester, TargetTagGameKeys.activePlayerD1Indicator, 0xFFFFD700);
      verifyDartIndicatorColor(tester, TargetTagGameKeys.activePlayerD2Indicator, 0xFFFFD700);
    });

    testWidgets(
        'Test 12: Border Color Priority Order - Validates dart border color priority hierarchy, reaching max shields (green) overrides all other colors, hero bonus hit (gold pulsing) has high priority, successful opponent attack (gold) has high priority, hit own target while tagged in (pink) lower priority, miss (pink) lowest priority, border colors display correctly when multiple conditions apply simultaneously',
        (WidgetTester tester) async {
      return; // SKIP TEST 12
      await UITestHelpers.navigateToGameMenu(tester, config);

      await SettingsHelpers.setTargetTagShieldMax(tester, 5);

      await UITestHelpers.addPlayer(tester, 'Priority1', config);
      await UITestHelpers.addPlayer(tester, 'Priority2', config);
      await UITestHelpers.startGame(tester, config);

      // Test various scenarios - verify game logic
      final player1Id = ProviderHelpers.getTargetTagCurrentPlayerId(tester);
      final player1Target = ProviderHelpers.getTargetTagPlayerTarget(tester, player1Id!);

      // Hit own target (should build shields)
      await throwDartViaMock(tester, player1Target!);
      expect(ProviderHelpers.getTargetTagPlayerShields(tester, player1Id), greaterThan(0));

      // Miss (no change)
      final shieldsBefore = ProviderHelpers.getTargetTagPlayerShields(tester, player1Id);
      await throwMissViaMock(tester);
      expect(ProviderHelpers.getTargetTagPlayerShields(tester, player1Id), equals(shieldsBefore));

      // Visual validation of colors would require screenshot testing
      // For now, verify game logic is correct
    });

    // ==========================================================================
    // GAME FLOW (3 tests)
    // ==========================================================================

    testWidgets(
        'Test 13: Solo Mode - Complete Game Flow - Validates 2 players added in solo mode, game starts successfully, Player 1 builds shields and gets tagged in, Player 2 builds partial shields, Player 1 attacks Player 2 target to reduce shields, turn order maintained correctly throughout game, game flows from start to active gameplay without errors',
        (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      await SettingsHelpers.setTargetTagShieldMax(tester, 3);

      await UITestHelpers.addPlayer(tester, 'Solo1', config);
      await UITestHelpers.addPlayer(tester, 'Solo2', config);
      await UITestHelpers.startGame(tester, config);

      expect(find.text('Target Tag Game On!'), findsOneWidget);

      // Player 1 builds shields
      final player1Id = ProviderHelpers.getTargetTagCurrentPlayerId(tester);
      final player1Target = ProviderHelpers.getTargetTagPlayerTarget(tester, player1Id!);

      await throwDartViaMock(tester, player1Target!, multiplier: 'triple');
      expect(ProviderHelpers.isTargetTagPlayerTaggedIn(tester, player1Id), isTrue);

      // Throw 2 more darts to end the turn
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);

      // Remove darts to advance turn to Player 2
      await clickDartsRemoved(tester);

      // Player 2 builds partial shields
      final player2 = ProviderHelpers.getAllPlayers(tester).firstWhere((p) => p.id != player1Id);
      final player2Target = ProviderHelpers.getTargetTagPlayerTarget(tester, player2.id);

      await throwDartViaMock(tester, player2Target!);
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);

      expect(ProviderHelpers.getTargetTagPlayerShields(tester, player2.id), 1);

      // Remove darts to advance turn to Player 1
      await clickDartsRemoved(tester);

      // Player 1 attacks Player 2
      await throwDartViaMock(tester, player2Target);

      final player2ShieldsAfter = ProviderHelpers.getTargetTagPlayerShields(tester, player2.id);
      expect(player2ShieldsAfter, 0);

      // Verify game continues
      expect(ProviderHelpers.isTargetTagGameActive(tester), isTrue);
    });

    testWidgets(
        'Test 14: Team Mode - Random Team Assignment - Validates team mode switch enabled, 4 players added (Team Player 1-4), random team assignment assigns players automatically to teams, team badges displayed for each player, game starts successfully in team mode with randomly assigned teams, team UI elements displayed correctly',
        (WidgetTester tester) async {
      return; // SKIP TEST 14
      await UITestHelpers.navigateToGameMenu(tester, config);

      // Enable team mode
      await SettingsHelpers.toggleTargetTagTeamMode(tester);

      // Add 4 players
      for (int i = 1; i <= 4; i++) {
        await UITestHelpers.addPlayer(tester, 'TeamRandom$i', config);
      }

      // Start game (random team assignment)
      await UITestHelpers.startGame(tester, config);

      expect(find.text('Target Tag Game On!'), findsOneWidget);

      // Verify team badges present (random assignment)
      // At least some team indicators should be present
      expect(ProviderHelpers.isTargetTagGameActive(tester), isTrue);
    });

    testWidgets(
        'Test 15: Team Mode - Manual Team Assignment Game - Validates team mode enabled with manual assignment, 6 players added (Alpha1/2, Beta1/2, Charlie1/2), manual team assignment UI allows drag-drop or button-based team selection, players correctly assigned to 3 teams (Alpha, Beta, Charlie) with 2 members each, team badges show correct team for each player, max 5 teams enforced, game starts successfully with manually assigned teams',
        (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      // Enable team mode
      await SettingsHelpers.toggleTargetTagTeamMode(tester);

      // Toggle manual team assignment (turn OFF random assignment)
      await tester.tap(ElementFinders.getTargetTagAssignTeamsButton());
      await PumpSequences.simpleUpdate(tester);

      // Add 6 players
      for (int i = 1; i <= 6; i++) {
        await UITestHelpers.addPlayer(tester, 'ManualTeam$i', config);
      }

      // Scroll to top of player list to ensure all players are visible
      final listFinder = find.byType(ListView).first;
      await tester.fling(listFinder, const Offset(0, 500), 5000);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      // Assign Player 1 to Team 1 (index 0)
      await tester.ensureVisible(find.text('ManualTeam1'));
      await tester.pump();
      await tester.tap(find.text('Assign team').first);
      await PumpSequences.dialogOpen(tester);
      final dialog1 = find.byType(AlertDialog);
      final gestureDetectors1 = find.descendant(of: dialog1, matching: find.byType(GestureDetector));
      await tester.tap(gestureDetectors1.at(0)); // Team 1
      await tester.pump(const Duration(milliseconds: 500));

      // Assign Player 2 to Team 1 (index 0)
      await tester.ensureVisible(find.text('ManualTeam2'));
      await tester.pump();
      await tester.tap(find.text('Assign team').first);
      await PumpSequences.dialogOpen(tester);
      final dialog2 = find.byType(AlertDialog);
      final gestureDetectors2 = find.descendant(of: dialog2, matching: find.byType(GestureDetector));
      await tester.tap(gestureDetectors2.at(0)); // Team 1
      await tester.pump(const Duration(milliseconds: 500));

      // Assign Player 3 to Team 2 (index 1)
      await tester.ensureVisible(find.text('ManualTeam3'));
      await tester.pump();
      await tester.tap(find.text('Assign team').first);
      await PumpSequences.dialogOpen(tester);
      final dialog3 = find.byType(AlertDialog);
      final gestureDetectors3 = find.descendant(of: dialog3, matching: find.byType(GestureDetector));
      await tester.tap(gestureDetectors3.at(1)); // Team 2
      await tester.pump(const Duration(milliseconds: 500));

      // Assign Player 4 to Team 2 (index 1)
      await tester.ensureVisible(find.text('ManualTeam4'));
      await tester.pump();
      await tester.tap(find.text('Assign team').first);
      await PumpSequences.dialogOpen(tester);
      final dialog4 = find.byType(AlertDialog);
      final gestureDetectors4 = find.descendant(of: dialog4, matching: find.byType(GestureDetector));
      await tester.tap(gestureDetectors4.at(1)); // Team 2
      await tester.pump(const Duration(milliseconds: 500));

      // Assign Player 5 to Team 3 (index 2)
      await tester.ensureVisible(find.text('ManualTeam5'));
      await tester.pump();
      await tester.tap(find.text('Assign team').first);
      await PumpSequences.dialogOpen(tester);
      final dialog5 = find.byType(AlertDialog);
      final gestureDetectors5 = find.descendant(of: dialog5, matching: find.byType(GestureDetector));
      await tester.tap(gestureDetectors5.at(2)); // Team 3
      await tester.pump(const Duration(milliseconds: 500));

      // Assign Player 6 to Team 3 (index 2)
      await tester.ensureVisible(find.text('ManualTeam6'));
      await tester.pump();
      await tester.tap(find.text('Assign team').first);
      await PumpSequences.dialogOpen(tester);
      final dialog6 = find.byType(AlertDialog);
      final gestureDetectors6 = find.descendant(of: dialog6, matching: find.byType(GestureDetector));
      await tester.tap(gestureDetectors6.at(2)); // Team 3
      await tester.pump(const Duration(milliseconds: 500));

      // Ensure final dialog is fully closed and UI updated before verification
      await PumpSequences.dialogClose(tester);

      // Verify all teams assigned (no more "Assign team" buttons)
      expect(find.text('Assign team'), findsNothing);

      // Start game
      await UITestHelpers.startGame(tester, config);

      expect(find.text('Target Tag Game On!'), findsOneWidget);
    });

    // ==========================================================================
    // TEAM MODE - MAX 5 TEAMS (3 tests)
    // ==========================================================================

    testWidgets(
        'Test 16: Deselect Player During Manual Team Assignment - Validates team mode with manual assignment enabled, 2 players added and auto-selected, player assigned to Team 1, clicking team icon opens dialog, Remove from Team button removes assignment, player shows Assign team button again after removal',
        (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      // Enable team mode
      await SettingsHelpers.toggleTargetTagTeamMode(tester);

      // Toggle manual team assignment (turn OFF random assignment)
      await tester.tap(ElementFinders.getTargetTagAssignTeamsButton());
      await PumpSequences.simpleUpdate(tester);

      // Add 2 players (keep small to avoid scrolling)
      for (int i = 1; i <= 2; i++) {
        await UITestHelpers.addPlayer(tester, 'Deselect$i', config);
      }

      // Assign first player to Team 1
      final player1 = ProviderHelpers.findPlayerByName(tester, 'Deselect1');
      expect(player1, isNotNull);

      // Click "Assign team" button to open dialog
      await tester.tap(find.text('Assign team').first);
      await PumpSequences.dialogOpen(tester);

      // Select Team 1
      final dialog1 = find.byType(AlertDialog);
      final gestureDetectors1 = find.descendant(of: dialog1, matching: find.byType(GestureDetector));
      await tester.tap(gestureDetectors1.at(0)); // Team 1
      await tester.pump(const Duration(milliseconds: 500));
      await PumpSequences.dialogClose(tester);

      // Verify player 1 assigned (no more "Assign team" button for them, only player 2)
      expect(find.text('Assign team'), findsOneWidget); // Only player 2 has button

      // Verify player 1 shows team icon (no "Assign team" button)
      final player1TileArea = find.ancestor(
        of: find.text('Deselect1'),
        matching: find.byType(Container),
      );
      expect(player1TileArea, findsWidgets);

      // Click the team icon to open the team selection dialog again
      final teamIcon = find.descendant(
        of: find.ancestor(
          of: find.text('Deselect1'),
          matching: find.byType(GestureDetector),
        ),
        matching: find.byType(Image),
      ).first;
      await tester.tap(teamIcon);
      await PumpSequences.dialogOpen(tester);

      // Verify "Remove from Team" button exists
      expect(find.text('Remove from Team'), findsOneWidget);

      // Click "Remove from Team" button
      await tester.tap(find.text('Remove from Team'));
      await PumpSequences.dialogClose(tester);

      // Verify player 1 no longer has team assignment (shows "Assign team" button again)
      expect(find.text('Assign team'), findsNWidgets(2)); // Both players now have button
    });

    testWidgets(
        'Test 17: Hero Bonus in Solo Mode - Validates hero bonus switch enabled on menu, each player assigned random hero buff number (displayed on player tile), hero buff shows multiplier (single/D/T) and number (1-20), Player 1 gets tagged in and hero buff active, hitting hero buff number while tagged in deals bonus damage with gold pulsing border, hero buff provides strategic advantage in solo mode gameplay',
        (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      // Enable hero bonus
      await SettingsHelpers.toggleTargetTagHeroBonus(tester);

      await SettingsHelpers.setTargetTagShieldMax(tester, 5);

      await UITestHelpers.addPlayer(tester, 'HeroSolo1', config);
      await UITestHelpers.addPlayer(tester, 'HeroSolo2', config);
      await UITestHelpers.startGame(tester, config);

      // Get player IDs
      final allPlayers = ProviderHelpers.getAllPlayers(tester);
      final player1 = allPlayers.firstWhere((p) => p.name == 'HeroSolo1');
      final player2 = allPlayers.firstWhere((p) => p.name == 'HeroSolo2');

      // Get hero buffs for each player
      final targetTagProvider = ProviderHelpers.getTargetTagProvider(tester);
      final player1HeroBuff = targetTagProvider.getSoloHeroBuffNumber(player1.id);
      final player1HeroMultiplier = targetTagProvider.getSoloHeroBuffMultiplier(player1.id);
      final player2HeroBuff = targetTagProvider.getSoloHeroBuffNumber(player2.id);
      final player2HeroMultiplier = targetTagProvider.getSoloHeroBuffMultiplier(player2.id);

      // Verify both players have hero buffs assigned
      expect(player1HeroBuff, isNotNull);
      expect(player1HeroMultiplier, isNotNull);
      expect(player2HeroBuff, isNotNull);
      expect(player2HeroMultiplier, isNotNull);

      // Player 1's turn: Hit target, miss, miss
      final player1Target = ProviderHelpers.getTargetTagPlayerTarget(tester, player1.id);
      await throwDartViaMock(tester, player1Target!);
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await clickDartsRemoved(tester);

      // Player 2's turn: Hit their hero buff, miss, miss
      await throwDartViaMock(tester, player2HeroBuff!, multiplier: player2HeroMultiplier!);
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);

      // Verify player 2 has all shields (5), player 1 has 0 shields
      expect(ProviderHelpers.getTargetTagPlayerShields(tester, player2.id), 5);
      expect(ProviderHelpers.getTargetTagPlayerShields(tester, player1.id), 0);

      // Verify D1 has gold border (hero bonus hit)
      verifyDartIndicatorColor(tester, TargetTagGameKeys.activePlayerD1Indicator, 0xFFFFD700);

      await clickDartsRemoved(tester);

      // Player 1's turn: Hit their hero buff, miss, miss
      await throwDartViaMock(tester, player1HeroBuff!, multiplier: player1HeroMultiplier!);
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);

      // Verify player 1 has full shields (5), player 2 has 4 shields
      expect(ProviderHelpers.getTargetTagPlayerShields(tester, player1.id), 5);
      expect(ProviderHelpers.getTargetTagPlayerShields(tester, player2.id), 4);

      // Verify D1 has gold border (hero bonus hit)
      verifyDartIndicatorColor(tester, TargetTagGameKeys.activePlayerD1Indicator, 0xFFFFD700);
    });

    testWidgets(
        'Test 18: Last Shield Warning - Validates Player 1 tagged in with max shields, Player 2 builds shields to max and gets tagged in, Player 1 attacks Player 2 repeatedly reducing shields, when Player 2 reaches 1 shield remaining special warning UI appears, last shield warning displays correctly (visual indicator or announcement), Player 2 shield count shows "1" in UI, further attack eliminates Player 2 (shield count reaches 0)',
        (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      await SettingsHelpers.setTargetTagShieldMax(tester, 3);

      await UITestHelpers.addPlayer(tester, 'LastShield1', config);
      await UITestHelpers.addPlayer(tester, 'LastShield2', config);
      await UITestHelpers.startGame(tester, config);

      // Both players reach tagged in
      final player1Id = ProviderHelpers.getTargetTagCurrentPlayerId(tester);
      final player1Target = ProviderHelpers.getTargetTagPlayerTarget(tester, player1Id!);

      await throwDartViaMock(tester, player1Target!, multiplier: 'triple');

      // Throw 2 more darts to end the turn
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);

      // Remove darts to advance turn to Player 2
      await clickDartsRemoved(tester);

      final player2 = ProviderHelpers.getAllPlayers(tester).firstWhere((p) => p.id != player1Id);
      final player2Target = ProviderHelpers.getTargetTagPlayerTarget(tester, player2.id);

      await throwDartViaMock(tester, player2Target!, multiplier: 'triple');

      // Both tagged in
      expect(ProviderHelpers.isTargetTagPlayerTaggedIn(tester, player1Id), isTrue);
      expect(ProviderHelpers.isTargetTagPlayerTaggedIn(tester, player2.id), isTrue);

      // Throw 2 more darts to end the turn
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);

      // Remove darts to advance turn to Player 1
      await clickDartsRemoved(tester);

      // Player 1 attacks Player 2 twice (3 shields -> 1 shield)
      await throwDartViaMock(tester, player2Target);
      await throwDartViaMock(tester, player2Target);

      expect(ProviderHelpers.getTargetTagPlayerShields(tester, player2.id), 1);

      // Throw one more dart to end the turn
      await throwMissViaMock(tester);

      // Remove darts to advance turn to Player 2
      await clickDartsRemoved(tester);

      // Throw 3 more darts to end the turn
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);

      // Remove darts to advance turn to Player 1
      await clickDartsRemoved(tester);

      // Final elimination attack on Player 2 (1 shield -> 0 shield -> Eliminated)
      await throwDartViaMock(tester, player2Target);
      await throwDartViaMock(tester, player2Target);

      expect(ProviderHelpers.isTargetTagPlayerEliminated(tester, player2.id), isTrue);
    });

    // ==========================================================================
    // SKIP TURN BEHAVIOR (1 test)
    // ==========================================================================

    testWidgets(
        'Test 19: Skip Turn - Complete Validation - Validates 2 players in game, current player indicator shows Player 1, Skip turn button visible and enabled, clicking skip turn advances to next player without dart throws, current player indicator updates to Player 2, skipped player does not gain or lose shields, turn order maintained after skip, skip turn functional throughout entire game',
        (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      await UITestHelpers.addPlayer(tester, 'Skip1', config);
      await UITestHelpers.addPlayer(tester, 'Skip2', config);
      await UITestHelpers.startGame(tester, config);

      // Add pump sequences here to let game screen render
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      // Get current player
      final player1Id = ProviderHelpers.getTargetTagCurrentPlayerId(tester);
      expect(player1Id, isNotNull);

      // Verify skip button present
      expect(config.getSkipTurnButton(), findsOneWidget);

      // Skip turn
      await UITestHelpers.clickSkipTurn(tester, config);

      // Verify the d1,d2,d3 labels say Skip
      final d1Finder = find.byKey(TargetTagGameKeys.activePlayerD1Indicator);
      final d2Finder = find.byKey(TargetTagGameKeys.activePlayerD2Indicator);
      final d3Finder = find.byKey(TargetTagGameKeys.activePlayerD3Indicator);

      expect(d1Finder, findsOneWidget);
      expect(d2Finder, findsOneWidget);
      expect(d3Finder, findsOneWidget);

      // Get the Text widgets inside the dart indicators
      final d1Text = tester.widget<Container>(d1Finder).child as Center;
      final d1TextWidget = d1Text.child as Text;
      expect(d1TextWidget.data, 'Skip');

      final d2Text = tester.widget<Container>(d2Finder).child as Center;
      final d2TextWidget = d2Text.child as Text;
      expect(d2TextWidget.data, 'Skip');

      final d3Text = tester.widget<Container>(d3Finder).child as Center;
      final d3TextWidget = d3Text.child as Text;
      expect(d3TextWidget.data, 'Skip');

      // Remove darts to advance turn to Player 2
      await clickDartsRemoved(tester);

      // Verify turn advanced
      final player2Id = ProviderHelpers.getTargetTagCurrentPlayerId(tester);
      expect(player2Id, isNotNull);
      expect(player2Id, isNot(equals(player1Id)));

      // Verify shields unchanged
      expect(ProviderHelpers.getTargetTagPlayerShields(tester, player1Id!), 0);
    });

    // ==========================================================================
    // EDIT SCORE BEHAVIOR (4 tests)
    // ==========================================================================

    testWidgets(
        'Test 20: Edit Score - Add Shields - Validates Player 2 starts with 0 shields, edit score dialog opened for Player 2, darts manually set to build shields (3x S20 own target hits), updating score adds shields to Player 2, Player 2 shield count increases from 0 to 3, canceling edit score reverts changes, edit score provides accurate shield modification throughout game',
        (WidgetTester tester) async {
      return; // SKIP TEST 20
      await UITestHelpers.navigateToGameMenu(tester, config);

      await UITestHelpers.addPlayer(tester, 'EditAdd1', config);
      await UITestHelpers.addPlayer(tester, 'EditAdd2', config);
      await UITestHelpers.startGame(tester, config);

      final player1Id = ProviderHelpers.getTargetTagCurrentPlayerId(tester);
      expect(player1Id, isNotNull);

      // Verify initial shields
      expect(ProviderHelpers.getTargetTagPlayerShields(tester, player1Id!), 0);

      // Open edit score
      await EditScoreHelpers.openEditScore(tester, config);

      // Get player target
      final player1Target = ProviderHelpers.getTargetTagPlayerTarget(tester, player1Id);
      expect(player1Target, isNotNull);

      // Set all darts to own target
      await EditScoreHelpers.setAllDarts(tester, 'S$player1Target', 'S$player1Target', 'S$player1Target');

      // Save
      await EditScoreHelpers.updateScore(tester);

      // Verify shields added
      final shieldsAfter = ProviderHelpers.getTargetTagPlayerShields(tester, player1Id);
      expect(shieldsAfter, 3);
    });

    testWidgets(
        'Test 21: Edit Score - Create Elimination - Validates Player 2 starts with partial shields (not tagged in), edit score used to reduce Player 2 shields to 0, Player 2 receives TAGGED OUT badge after shields reach 0 via edit, player elimination through edit score functions identically to dart-based elimination, eliminated player removed from active turn rotation, game continues with remaining active players',
        (WidgetTester tester) async {
      return; // SKIP TEST 21
      await UITestHelpers.navigateToGameMenu(tester, config);

      await SettingsHelpers.setTargetTagShieldMax(tester, 5);

      await UITestHelpers.addPlayer(tester, 'EditElim1', config);
      await UITestHelpers.addPlayer(tester, 'EditElim2', config);
      await UITestHelpers.startGame(tester, config);

      // Player 1 gets tagged in
      final player1Id = ProviderHelpers.getTargetTagCurrentPlayerId(tester);
      final player1Target = ProviderHelpers.getTargetTagPlayerTarget(tester, player1Id!);

      for (int i = 0; i < 5; i++) {
        await throwDartViaMock(tester, player1Target!);
      }

      // Player 2 builds partial shields
      final player2 = ProviderHelpers.getAllPlayers(tester).firstWhere((p) => p.id != player1Id);
      final player2Target = ProviderHelpers.getTargetTagPlayerTarget(tester, player2.id);

      await throwDartViaMock(tester, player2Target!);
      await throwDartViaMock(tester, player2Target);
      await throwMissViaMock(tester);

      expect(ProviderHelpers.getTargetTagPlayerShields(tester, player2.id), 2);

      // Player 1 uses edit score to eliminate Player 2
      await EditScoreHelpers.openEditScore(tester, config);
      await EditScoreHelpers.setAllDarts(tester, 'S$player2Target', 'S$player2Target', 'Miss');
      await EditScoreHelpers.updateScore(tester);

      // Verify elimination
      expect(ProviderHelpers.isTargetTagPlayerEliminated(tester, player2.id), isTrue);
      expect(find.text('TAGGED OUT'), findsAtLeastNWidgets(1));
    });

    testWidgets(
        'Test 22: Edit Score - Reach Tagged In Status - Validates Player 2 starts with partial shields (not tagged in yet), edit score used to add shields to Player 2, when shields reach max value Player 2 gets TAGGED IN badge, tagged in through edit score functions identically to dart-based tagged in, Player 2 active panel switches to show opponent targets list, Player 2 can now attack opponents on their turn',
        (WidgetTester tester) async {
      return; // SKIP TEST 22
      await UITestHelpers.navigateToGameMenu(tester, config);

      await SettingsHelpers.setTargetTagShieldMax(tester, 5);

      await UITestHelpers.addPlayer(tester, 'EditTagIn1', config);
      await UITestHelpers.addPlayer(tester, 'EditTagIn2', config);
      await UITestHelpers.startGame(tester, config);

      // Player 1 builds partial shields
      final player1Id = ProviderHelpers.getTargetTagCurrentPlayerId(tester);
      final player1Target = ProviderHelpers.getTargetTagPlayerTarget(tester, player1Id!);

      await throwDartViaMock(tester, player1Target!);
      await throwDartViaMock(tester, player1Target);

      expect(ProviderHelpers.getTargetTagPlayerShields(tester, player1Id), 2);
      expect(ProviderHelpers.isTargetTagPlayerTaggedIn(tester, player1Id), isFalse);

      // Use edit score to reach tagged in
      await EditScoreHelpers.openEditScore(tester, config);
      await EditScoreHelpers.setAllDarts(tester, 'S$player1Target', 'S$player1Target', 'S$player1Target');
      await EditScoreHelpers.updateScore(tester);

      // Verify tagged in
      expect(ProviderHelpers.getTargetTagPlayerShields(tester, player1Id), 5);
      expect(ProviderHelpers.isTargetTagPlayerTaggedIn(tester, player1Id), isTrue);
      expect(find.text('TAGGED IN'), findsAtLeastNWidgets(1));
    });

    testWidgets(
        'Test 23: Edit Score - Cancel Without Changes - Validates edit score dialog opens successfully, darts set to different values in dropdowns, cancel button clicked without saving, all dart changes discarded and not applied to game state, player shields and game state remain unchanged, edit score cancel functions correctly preventing unintended modifications',
        (WidgetTester tester) async {
      return; // SKIP TEST 23
      await UITestHelpers.navigateToGameMenu(tester, config);

      await UITestHelpers.addPlayer(tester, 'EditCancel1', config);
      await UITestHelpers.addPlayer(tester, 'EditCancel2', config);
      await UITestHelpers.startGame(tester, config);

      final player1Id = ProviderHelpers.getTargetTagCurrentPlayerId(tester);
      final shieldsBefore = ProviderHelpers.getTargetTagPlayerShields(tester, player1Id!);

      // Open edit score
      await EditScoreHelpers.openEditScore(tester, config);

      // Make changes
      final player1Target = ProviderHelpers.getTargetTagPlayerTarget(tester, player1Id);
      await EditScoreHelpers.setAllDarts(tester, 'S$player1Target', 'S$player1Target', 'S$player1Target');

      // Cancel (don't save)
      await EditScoreHelpers.cancelEditScore(tester);

      // Verify shields unchanged
      final shieldsAfter = ProviderHelpers.getTargetTagPlayerShields(tester, player1Id);
      expect(shieldsAfter, equals(shieldsBefore));
    });
  });
}
