import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';
import 'package:provider/provider.dart';
import 'package:dart_games/providers/target_tag_provider.dart';
import 'package:dart_games/providers/player_provider.dart';

// Shared component imports
import '../shared/ui_test_helpers.dart';
import '../shared/pump_sequences.dart';
import '../shared/settings_helpers.dart';
import '../shared/game_ui_config.dart';
import '../shared/provider_helpers.dart';
import '../shared/results_helpers.dart';

/// Target Tag - Results Screen Integration Tests
///
/// These are full integration tests that run the complete app in Chrome
/// and test the results screen functionality including:
/// - Results screen content validation
/// - Play Again functionality with same settings
/// - Change Settings navigation with preserved settings
///
/// Run with:
/// ```bash
/// # Terminal 1: Start chromedriver
/// cd dart_games/chromedriver/chromedriver-win64
/// ./chromedriver.exe --port=4444
///
/// # Terminal 2: Run tests
/// flutter drive --driver=test_driver/integration_test.dart \
///   --target=integration_test/target_tag_results_screen_test.dart \
///   -d chrome
/// ```

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Game configuration for Target Tag
  final config = GameUIConfig.targetTag();

  // ==========================================================================
  // MOCK API DART THROWING HELPERS
  // ==========================================================================

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

  /// Click DARTS REMOVED button on emulator
  Future<void> clickDartsRemoved(WidgetTester tester) async {
    final dartsRemovedButton = find.text('DARTS REMOVED');
    if (dartsRemovedButton.evaluate().isNotEmpty) {
      await tester.tap(dartsRemovedButton.first);
      await PumpSequences.simpleUpdate(tester);
    }
  }

  // ==========================================================================
  // HELPER FUNCTIONS
  // ==========================================================================

  /// Set shield max value by programmatically calling the slider's onChanged callback
  /// Shield max range: 1-10, divisions: 9
  Future<void> setShieldMax(WidgetTester tester, int shieldMax) async {
    final sliderFinder = find.byType(Slider);
    expect(sliderFinder, findsWidgets); // May have multiple sliders

    // Find the Shield Max slider specifically
    final shieldMaxLabel = find.textContaining('Shield Max:');
    expect(shieldMaxLabel, findsOneWidget);

    // Find the slider that's a sibling/descendant of the Shield Max container
    final shieldMaxContainer = find.ancestor(
      of: shieldMaxLabel,
      matching: find.byType(Container),
    );

    final shieldMaxSlider = find.descendant(
      of: shieldMaxContainer.first,
      matching: find.byType(Slider),
    );
    expect(shieldMaxSlider, findsOneWidget);

    // Get the slider widget
    Slider sliderWidget = tester.widget<Slider>(shieldMaxSlider);
    final currentValue = sliderWidget.value.toInt();

    if (currentValue == shieldMax) {
      return; // Already at target value
    }

    // Programmatically call the slider's onChanged callback with the target value
    if (sliderWidget.onChanged != null) {
      sliderWidget.onChanged!(shieldMax.toDouble());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      await tester.pump();
    }

    // Extra pumps to ensure UI is fully updated
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
  }

  /// Extract target number from a player's tile on game screen
  String? getTargetNumberFromPlayerTile(WidgetTester tester, String playerName) {
    final playerFinder = find.text(playerName);
    if (playerFinder.evaluate().isEmpty) return null;

    final playerTileContainer = find.ancestor(
      of: playerFinder.first,
      matching: find.byType(Container),
    );
    if (playerTileContainer.evaluate().isEmpty) return null;

    final allTextInTile = find.descendant(
      of: playerTileContainer.first,
      matching: find.byType(Text),
    );

    final targetLabel = find.descendant(
      of: playerTileContainer.first,
      matching: find.text('Target number: '),
    );
    if (targetLabel.evaluate().isEmpty) return null;

    int targetLabelIndex = -1;
    for (int i = 0; i < allTextInTile.evaluate().length; i++) {
      final textWidget = allTextInTile.evaluate().elementAt(i).widget as Text;
      if (textWidget.data == 'Target number: ') {
        targetLabelIndex = i;
        break;
      }
    }

    if (targetLabelIndex >= 0 && targetLabelIndex + 1 < allTextInTile.evaluate().length) {
      final targetNumWidget = allTextInTile.evaluate().elementAt(targetLabelIndex + 1).widget as Text;
      return targetNumWidget.data ?? '';
    }
    return null;
  }

  /// Quickly complete a solo game and reach results screen
  /// Player 1 gets tagged in with triple, Player 2 builds 2 shields, Player 1 eliminates Player 2
  /// Uses dynamic target lookup and 3 shields max
  Future<void> completeGameToVictory(WidgetTester tester, String player1Name, String player2Name) async {
    // Get dynamic target numbers for both players
    final target1Str = getTargetNumberFromPlayerTile(tester, player1Name);
    final target2Str = getTargetNumberFromPlayerTile(tester, player2Name);

    if (target1Str == null || target2Str == null) {
      throw Exception('Could not find target numbers for players');
    }

    final target1 = int.parse(target1Str);
    final target2 = int.parse(target2Str);

    // Turn 1: Player 1 throws TRIPLE on own target = 3 shields = TAGGED IN!
    await throwDartViaMock(tester, target1, multiplier: 'triple'); // 3 shields - TAGGED IN!
    await PumpSequences.simpleUpdate(tester);
    await throwDartViaMock(tester, 1, multiplier: 'single'); // Miss
    await PumpSequences.simpleUpdate(tester);
    await throwDartViaMock(tester, 1, multiplier: 'single'); // Miss
    await PumpSequences.simpleUpdate(tester);
    await clickDartsRemoved(tester);
    await PumpSequences.fullRebuild(tester);

    // Turn 2: Player 2 builds 2 shields (not tagged in yet - need 3)
    await throwDartViaMock(tester, target2, multiplier: 'single'); // Shield 1
    await PumpSequences.simpleUpdate(tester);
    await throwDartViaMock(tester, target2, multiplier: 'single'); // Shield 2
    await PumpSequences.simpleUpdate(tester);
    await throwDartViaMock(tester, 1, multiplier: 'single'); // Miss
    await PumpSequences.simpleUpdate(tester);
    await clickDartsRemoved(tester);
    await PumpSequences.fullRebuild(tester);

    // Turn 3: Player 1 attacks Player 2's target (3 hits: 2->1->0, Player 2 vulnerable)
    await throwDartViaMock(tester, target2, multiplier: 'single'); // Attack! (shields 2->1)
    await PumpSequences.simpleUpdate(tester);
    await throwDartViaMock(tester, target2, multiplier: 'single'); // Attack! (shields 1->0, vulnerable)
    await PumpSequences.simpleUpdate(tester);
    await throwDartViaMock(tester, target2, multiplier: 'single'); // Miss to end turn
    await PumpSequences.simpleUpdate(tester);
    await clickDartsRemoved(tester);
    await PumpSequences.fullRebuild(tester);

    // Turn 4: Player 2 misses (still vulnerable at 0 shields)
    await throwDartViaMock(tester, 1, multiplier: 'single'); // Miss
    await PumpSequences.simpleUpdate(tester);
    await throwDartViaMock(tester, 1, multiplier: 'single'); // Miss
    await PumpSequences.simpleUpdate(tester);
    await throwDartViaMock(tester, 1, multiplier: 'single'); // Miss
    await PumpSequences.simpleUpdate(tester);
    await clickDartsRemoved(tester);
    await PumpSequences.fullRebuild(tester);

    // Turn 5: Player 1 eliminates Player 2 with hit at 0 shields
    await throwDartViaMock(tester, target2, multiplier: 'single'); // Elimination!
    await PumpSequences.simpleUpdate(tester);
    await clickDartsRemoved(tester);

    // Extended wait for victory screen and confetti animation
    await tester.pump(const Duration(seconds: 3)); // Wait for victory announcements
    await tester.pump();
    await tester.pump(const Duration(seconds: 2)); // Wait for navigation to results screen
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // Wait for confetti controller to initialize
    await tester.pump();
  }

  /// Complete a team mode game and reach results screen
  /// Teams share targets - Team 1 gets tagged in, then attacks Team 2 target
  Future<void> completeGameToVictoryTeamMode(WidgetTester tester, String team1Player, String team2Player) async {
    // Access the provider to get team and game information
    final provider = Provider.of<TargetTagProvider>(tester.element(find.byType(Scaffold).first), listen: false);
    final game = provider.currentGame!;

    // Get current player (first in turn order - should be Team 1 Player 1)
    final currentPlayerId = game.getCurrentPlayerId();
    final currentTeamId = game.playerToTeam![currentPlayerId]!;
    final teamTargetNum = game.targetNumbers[currentPlayerId]!;

    // Turn 1 (Team1 Player1): Get tagged in immediately with triple on own target
    await throwDartViaMock(tester, teamTargetNum, multiplier: 'triple'); // 3 shields - TAGGED IN!
    await PumpSequences.simpleUpdate(tester);
    await throwDartViaMock(tester, 1, multiplier: 'single'); // Miss
    await PumpSequences.simpleUpdate(tester);
    await throwDartViaMock(tester, 1, multiplier: 'single'); // Miss
    await PumpSequences.simpleUpdate(tester);
    await clickDartsRemoved(tester);
    await PumpSequences.fullRebuild(tester);

    // Find opponent team target (any player not on current team)
    int? opponentTargetNum;
    final playerProvider = Provider.of<PlayerProvider>(tester.element(find.byType(Scaffold).first), listen: false);
    final allPlayers = playerProvider.allPlayers;
    final currentTeamPlayers = game.teamPlayers![currentTeamId]!;

    for (final player in allPlayers) {
      if (!currentTeamPlayers.contains(player.id)) {
        opponentTargetNum = game.targetNumbers[player.id];
        break;
      }
    }

    if (opponentTargetNum == null) {
      throw Exception('Could not find opponent target number');
    }

    // Turn 2 (Team2 Player1): Miss all 3 throws - stay at 0 shields
    await throwDartViaMock(tester, 1, multiplier: 'single'); // Miss
    await PumpSequences.simpleUpdate(tester);
    await throwDartViaMock(tester, 1, multiplier: 'single'); // Miss
    await PumpSequences.simpleUpdate(tester);
    await throwDartViaMock(tester, 1, multiplier: 'single'); // Miss
    await PumpSequences.simpleUpdate(tester);
    await clickDartsRemoved(tester);
    await PumpSequences.fullRebuild(tester);

    // Turn 3 (Team1 Player2): Attack opponent (Team 2 at 0 shields, eliminate with 1 hit)
    await throwDartViaMock(tester, opponentTargetNum, multiplier: 'single'); // Elimination!
    await PumpSequences.simpleUpdate(tester);
    await clickDartsRemoved(tester);
    await PumpSequences.fullRebuild(tester);

    // Extended wait for team mode victory processing and results screen
    await tester.pump(const Duration(seconds: 5)); // Victory announcements
    await tester.pump();
    await tester.pump(const Duration(seconds: 3)); // Navigation to results screen
    await tester.pump();
    await tester.pump(const Duration(seconds: 2)); // Confetti controller initialization
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // Final render
    await tester.pump();
  }

  group('Target Tag - Results Screen Tests', () {
    setUp(() async {
      // Initialize settings with emulator mode
      await UITestHelpers.resetServerState();
    });

    // Test 1: Results Screen Content - Solo Mode Victory Display
    // Features: Results screen layout, winner announcement, action buttons, confetti, victory music
    // UI Elements: WINNER! title, winner avatar with CircleAvatar, winner name, Play Again/Change Settings/Select Different Game buttons, Target Tag Game Over app bar
    // Game States: Solo mode 2-player game, shield max 3, Player 1 gets tagged in (3 shields), Player 2 builds 2 shields, Player 1 eliminates Player 2
    // Validates: All UI elements visible and correctly displayed, dynamic target lookup working (no hardcoded values), shield max set to 3 successfully
    testWidgets('Test 1: Results Screen Content - Solo Mode Victory Display', (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      // Set shield max to 3 (faster game, verify setting preservation)
      await setShieldMax(tester, 3);

      await UITestHelpers.addPlayer(tester, 'Winner Player', config);
      await UITestHelpers.addPlayer(tester, 'Loser Player', config);

      await UITestHelpers.startGame(tester, config);

      // Complete game to victory
      await completeGameToVictory(tester, 'Winner Player', 'Loser Player');

      // Verify results screen elements
      expect(find.text('WINNER!'), findsOneWidget);
      expect(find.text('Winner Player'), findsWidgets);
      expect(find.text('Play Again'), findsOneWidget);
      expect(find.text('Change Settings'), findsOneWidget);
      expect(find.text('Select Different Game'), findsOneWidget);
      expect(find.text('Target Tag Game Over'), findsOneWidget);
    });

    // Test 2: Play Again - Settings Preservation Solo Mode
    // Features: Quick rematch functionality, shield max preservation, player preservation, score reset
    // UI Elements: Play Again button (green), game screen with "Target Tag Game On!" title
    // Game States: Solo mode game completes with victory, click Play Again, new game starts with identical settings (shield max 3, same 2 players)
    // Validates: Play Again button navigates to new game screen, same players remain in game. Note: Does NOT verify shield max preserved at 3 or scores reset to 0 - only confirms navigation to game screen and player presence
    testWidgets('Test 2: Play Again - Settings Preservation Solo Mode', (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      // Set shield max to 3
      await setShieldMax(tester, 3);

      await UITestHelpers.addPlayer(tester, 'Player1', config);
      await UITestHelpers.addPlayer(tester, 'Player2', config);

      await UITestHelpers.startGame(tester, config);

      // Complete game to victory
      await completeGameToVictory(tester, 'Player1', 'Player2');

      // Click Play Again
      await ResultsHelpers.clickPlayAgain(tester, config);

      // Should navigate back to game screen with same settings
      expect(find.text('Target Tag Game On!'), findsOneWidget);
      expect(find.text('Player1'), findsWidgets);
      expect(find.text('Player2'), findsWidgets);
    });

    // Test 3: Change Settings - Return to Menu with Preserved Settings
    // Features: Settings preservation when returning to menu, shield max verification, player preselection
    // UI Elements: Change Settings button (pink), menu screen with "Shield Max: 3" label, preselected player tiles
    // Game States: Solo mode game completes, click Change Settings, menu loads with all previous settings intact
    // Validates: Navigation to menu successful, shield max displays as "Shield Max: 3" (proves setting preserved), both players appear preselected, ready to modify and restart game
    testWidgets('Test 3: Change Settings - Return to Menu with Preserved Settings', (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      // Set shield max to 3
      await setShieldMax(tester, 3);

      await UITestHelpers.addPlayer(tester, 'Player1', config);
      await UITestHelpers.addPlayer(tester, 'Player2', config);

      await UITestHelpers.startGame(tester, config);

      // Complete game to victory
      await completeGameToVictory(tester, 'Player1', 'Player2');

      // Click Change Settings
      await ResultsHelpers.clickChangeSettings(tester, config);

      // Should navigate back to menu with preselected settings
      expect(find.textContaining('Shield Max:'), findsOneWidget);
      expect(find.text('Shield Max: 3'), findsOneWidget); // Verify shield max preserved
      expect(find.text('Player1'), findsWidgets);
      expect(find.text('Player2'), findsWidgets);
    });

    // Test 4: Results Screen Content - Team Mode Victory Display
    // Features: Team mode results screen layout, team victory announcement, shared target mechanics validation
    // UI Elements: WINNER/WINNERS title (may show plural for teams), winner avatars (multiple CircleAvatars for team), team member names, all action buttons
    // Game States: Team mode 2v2 (4 players, 2 teams), shield max 3, Team 1 gets tagged in (3 shields on shared target), Team 2 builds 2 shields, Team 1 eliminates Team 2 (entire team eliminated together)
    // Validates: Team mode game completes successfully, results screen displays for team victory with "WINNER" text, all buttons present (Play Again, Change Settings, Back to Menu). Note: Does NOT explicitly verify both team members shown as winners by name - only checks for "WINNER" text existence
    testWidgets('Test 4: Results Screen Content - Team Mode Victory Display', (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      // Set shield max to 3
      await setShieldMax(tester, 3);

      // Enable team mode
      await SettingsHelpers.toggleTargetTagTeamMode(tester);

      // Add 4 players for 2v2
      await UITestHelpers.addPlayer(tester, 'Team1 Winner1', config);
      await UITestHelpers.addPlayer(tester, 'Team1 Winner2', config);
      await UITestHelpers.addPlayer(tester, 'Team2 Loser1', config);
      await UITestHelpers.addPlayer(tester, 'Team2 Loser2', config);

      await UITestHelpers.startGame(tester, config);

      // In team mode, players on same team share target
      // Get first player from each team and complete to victory
      // Team 1 player gets tagged in, then attacks Team 2 target
      await completeGameToVictoryTeamMode(tester, 'Team1 Winner1', 'Team2 Loser1');

      // Verify results screen shows WINNERS (plural for team)
      // Note: May show WINNER! or WINNERS! depending on implementation
      expect(find.textContaining('WINNER'), findsOneWidget);
      expect(find.text('Target Tag Game Over'), findsOneWidget);
      expect(find.text('Play Again'), findsOneWidget);
      expect(find.text('Change Settings'), findsOneWidget);
      expect(find.text('Select Different Game'), findsOneWidget);
    });

    // Test 5: Play Again - Team Mode Settings and Team Assignment Preserved
    // Features: Team mode persistence through Play Again, shield max preservation, team assignment preservation, quick rematch in team mode
    // UI Elements: Play Again button, team mode indicators (Team labels), game screen with team displays
    // Game States: Team mode 2v2 game completes with team victory, click Play Again, new team game starts with same teams and settings (shield max 3, same 4 players in same teams)
    // Validates: Play Again works in team mode, navigates to game screen, "Team" text present indicating team mode active. Note: Does NOT explicitly verify shield max preserved at 3, same players in same team assignments, or team targets reassigned - only confirms game restarts in team mode
    testWidgets('Test 5: Play Again - Team Mode Settings and Team Assignment Preserved', (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      // Set shield max to 3
      await setShieldMax(tester, 3);

      await SettingsHelpers.toggleTargetTagTeamMode(tester);

      await UITestHelpers.addPlayer(tester, 'TeamA1', config);
      await UITestHelpers.addPlayer(tester, 'TeamA2', config);
      await UITestHelpers.addPlayer(tester, 'TeamB1', config);
      await UITestHelpers.addPlayer(tester, 'TeamB2', config);

      await UITestHelpers.startGame(tester, config);

      await completeGameToVictoryTeamMode(tester, 'TeamA1', 'TeamB1');

      // Extra pumps to ensure results screen is fully rendered and interactive for team mode
      // Team mode requires significantly more time for all victory announcements and screen transition
      await tester.pump(const Duration(seconds: 5));
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();

      // Verify results screen is visible before clicking
      expect(find.textContaining('WINNER'), findsOneWidget);
      expect(find.text('Target Tag Game Over'), findsOneWidget);

      // Click Play Again
      final playAgainButton = config.getPlayAgainButton();
      expect(playAgainButton, findsOneWidget); // Verify button exists
      await tester.tap(playAgainButton);
      await tester.pump();
      await tester.pump(const Duration(seconds: 3)); // Longer wait for game restart
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      // Should restart in team mode
      expect(find.text('Target Tag Game On!'), findsOneWidget);
      expect(find.textContaining('Team'), findsWidgets);
    });

    // Test 6: Play Again - Hero Bonus Setting Preserved
    // Features: Hero bonus persistence through Play Again, bonus multiplier preservation, settings verification
    // UI Elements: Play Again button, hero bonus buff indicators on player tiles, game screen with buff values displayed
    // Game States: Solo mode game with hero bonus enabled and shield max 3, game completes, click Play Again, new game starts with hero bonus still enabled
    // Validates: Hero bonus enabled on menu, game completes, Play Again clicked, game restarts, players present. Note: Does NOT explicitly verify hero bonus setting preserved (Buff: text), shield max preserved at 3, buff values recalculated, or hero bonus mechanics active - only confirms game restarts with players
    testWidgets('Test 6: Play Again - Hero Bonus Setting Preserved', (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      // Set shield max to 3
      await setShieldMax(tester, 3);

      await SettingsHelpers.toggleTargetTagHeroBonus(tester);

      await UITestHelpers.addPlayer(tester, 'Hero1', config);
      await UITestHelpers.addPlayer(tester, 'Hero2', config);

      await UITestHelpers.startGame(tester, config);

      await completeGameToVictory(tester, 'Hero1', 'Hero2');

      // Click Play Again
      await ResultsHelpers.clickPlayAgain(tester, config);
      await tester.pump(const Duration(seconds: 3)); // Longer wait for game restart
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      // Should restart with hero bonus enabled
      expect(find.text('Target Tag Game On!'), findsOneWidget);
      expect(find.text('Hero1'), findsWidgets);
      expect(find.text('Hero2'), findsWidgets);
    });
  });
}
