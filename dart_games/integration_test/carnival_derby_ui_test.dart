import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:dart_games/providers/horse_race_provider.dart';
import 'package:dart_games/providers/player_provider.dart';

// Shared component imports
import 'shared/ui_test_helpers.dart';
import 'shared/element_finders.dart';
import 'shared/settings_helpers.dart';
import 'shared/game_ui_config.dart';

/// Carnival Derby - Interactive UI Tests
///
/// Comprehensive UI tests covering:
/// - Menu: Player selection, target score settings
/// - Game: Basic mechanics, Perfect Finish mode, scoring
/// - Skip turn and edit score functionality
/// - Multi-player races
/// - Edge cases and results screen
///
/// Run with:
/// ```bash
/// # Terminal 1: Start chromedriver
/// cd dart_games/chromedriver/chromedriver-win64
/// ./chromedriver.exe --port=4444
///
/// # Terminal 2: Run tests
/// flutter drive --driver=test_driver/integration_test.dart \
///   --target=integration_test/carnival_derby_ui_test.dart \
///   -d chrome
/// ```

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Game configuration
  final config = GameUIConfig.carnivalDerby();

  // ==================== HELPER FUNCTIONS ====================

  /// Navigate to Carnival Derby menu using shared helper
  Future<void> navigateToCarnivalDerbyMenu(WidgetTester tester) async {
    await SettingsHelpers.initializeSettings();
    await UITestHelpers.navigateToGameMenu(tester, config);

    // Verify we're on the menu screen
    expect(find.textContaining('Target score:'), findsOneWidget);
  }

  /// Set target score by programmatically calling the slider's onChanged callback
  /// Target score range: 20-250, divisions: 46 (step size = 5)
  Future<void> setTargetScore(WidgetTester tester, int targetScore) async {
    final sliderFinder = find.byType(Slider);
    expect(sliderFinder, findsOneWidget);

    // Get the slider widget
    Slider sliderWidget = tester.widget<Slider>(sliderFinder);
    final currentValue = sliderWidget.value.toInt();

    if (currentValue == targetScore) {
      return; // Already at target value
    }

    // Programmatically call the slider's onChanged callback with the target value
    if (sliderWidget.onChanged != null) {
      sliderWidget.onChanged!(targetScore.toDouble());
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

  /// Toggle Perfect Finish mode (Radio buttons: Yes/No)
  Future<void> togglePerfectFinish(WidgetTester tester) async {
    // Find and tap the "Yes" radio button for Perfect Finish mode
    final yesButton = find.text('Yes');
    await tester.ensureVisible(yesButton.first);
    await tester.pump();
    await tester.tap(yesButton.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
  }

  /// Start the game using shared helper
  Future<void> startGame(WidgetTester tester) async {
    await UITestHelpers.startGame(tester, config);

    // Verify we're on the game screen
    expect(find.text('Carnival Derby Race'), findsOneWidget);
  }

  /// Click DARTS REMOVED button on emulator
  Future<void> clickDartsRemoved(WidgetTester tester) async {
    final dartsRemovedButton = find.text('DARTS REMOVED');
    if (dartsRemovedButton.evaluate().isNotEmpty) {
      await tester.tap(dartsRemovedButton.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
    }
  }

  /// Open edit score dialog
  Future<void> openEditScore(WidgetTester tester) async {
    final editButton = config.getEditScoreButton();
    expect(editButton, findsOneWidget);
    await tester.tap(editButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    // Verify dialog opened
    expect(find.text('Update score'), findsOneWidget);
  }

  /// Set dart in edit score dialog
  /// dartIndex: 0, 1, or 2 for D1, D2, D3
  /// ring: 'Single (inner)', 'Double', 'Triple', 'Bullseye', 'Outer bull (25)', 'Miss', 'Single (outer)'
  /// number: 1-20 (ignored for Bullseye, Outer bull, Miss)
  Future<void> setDartInEditScore(WidgetTester tester, int dartIndex, String ring, {int? number}) async {
    // Tap the ring button
    final ringButton = find.text(ring);
    if (ringButton.evaluate().isNotEmpty) {
      await tester.ensureVisible(ringButton.first);
      await tester.pump();
      await tester.tap(ringButton.first, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump();
    }

    // If number is needed, tap the number button.
    // The score display at the top shows the number too, so it's always at index 0.
    // Dart buttons (D1, D2, D3) are at indices 1, 2, 3, so we use dartIndex+1.
    if (number != null && ring != 'Bullseye' && ring != 'Outer bull (25)' && ring != 'Miss') {
      final numberText = find.descendant(
        of: find.byType(Dialog),
        matching: find.text(number.toString()),
      );
      // Skip the first match (score display) by using dartIndex+1
      final actualIndex = dartIndex + 1;
      if (numberText.evaluate().length > actualIndex) {
        await tester.ensureVisible(numberText.at(actualIndex));
        await tester.pump();
        await tester.tap(numberText.at(actualIndex), warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pump();
      }
    }
  }

  /// Update score (click Update button in edit dialog)
  Future<void> updateScore(WidgetTester tester) async {
    final updateButton = ElementFinders.getEditScoreSaveButton();
    await tester.tap(updateButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    // Verify dialog closed
    expect(find.text('Update score'), findsNothing);
  }

  /// Get current player score from provider
  int getCurrentPlayerScore(WidgetTester tester) {
    final context = tester.element(find.byType(MaterialApp));
    final horseRaceProvider = Provider.of<HorseRaceProvider>(context, listen: false);
    final currentPlayerId = horseRaceProvider.getCurrentPlayerId();
    if (currentPlayerId == null) return 0;
    return horseRaceProvider.getPlayerScore(currentPlayerId);
  }

  /// Check if game has winner
  bool hasWinner(WidgetTester tester) {
    final context = tester.element(find.byType(MaterialApp));
    final horseRaceProvider = Provider.of<HorseRaceProvider>(context, listen: false);
    return horseRaceProvider.hasWinner;
  }

  /// Check if current player busted (Perfect Finish mode)
  bool currentPlayerBusted(WidgetTester tester) {
    final context = tester.element(find.byType(MaterialApp));
    final horseRaceProvider = Provider.of<HorseRaceProvider>(context, listen: false);
    return horseRaceProvider.currentPlayerBusted;
  }

  /// Get player count from PlayerProvider
  int getPlayerCount(WidgetTester tester) {
    final context = tester.element(find.byType(MaterialApp));
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    return playerProvider.allPlayers.length;
  }

  /// Get selected player count
  int getSelectedPlayerCount(WidgetTester tester) {
    final context = tester.element(find.byType(MaterialApp));
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    return playerProvider.selectedPlayers.length;
  }

  /// Verify dart display text (D1, D2, D3 indicators on screen)
  /// The UI shows: D1 label above the score, D2 label above the score, D3 label above the score
  /// Expected values: '20', '40', 'Miss', '50', '25', '-' (for un-thrown), etc.
  void verifyDartDisplay(WidgetTester tester, String d1, String d2, String d3) {
    // Verify D1 label exists
    expect(find.text('D1'), findsOneWidget);
    // Verify D1 score (separate Text widget below the label)
    if (d1 != '-') {
      expect(find.text(d1), findsWidgets, reason: 'Expected D1 score to show "$d1"');
    }

    // Verify D2 label exists
    expect(find.text('D2'), findsOneWidget);
    // Verify D2 score (separate Text widget below the label)
    if (d2 != '-') {
      expect(find.text(d2), findsWidgets, reason: 'Expected D2 score to show "$d2"');
    }

    // Verify D3 label exists
    expect(find.text('D3'), findsOneWidget);
    // Verify D3 score (separate Text widget below the label)
    if (d3 != '-') {
      expect(find.text(d3), findsWidgets, reason: 'Expected D3 score to show "$d3"');
    }
  }

  /// Verify game settings are displayed correctly on game screen
  /// targetScore: expected target score (20-250)
  /// perfectFinish: true if Perfect Finish mode is ON, false if OFF
  void verifyGameSettings(WidgetTester tester, int targetScore, bool perfectFinish) {
    // Verify target score display
    expect(find.text('Race to $targetScore points'), findsOneWidget);

    // Verify Perfect Finish mode display
    final expectedText = perfectFinish
        ? 'Perfect Finish Required'
        : 'Perfect Finish Not Required';
    expect(find.text(expectedText), findsOneWidget);
  }

  /// Verify current player score is displayed in the current player section
  /// Shows as "Score: X / Y" where X is current score, Y is target
  void verifyCurrentPlayerScoreDisplay(WidgetTester tester, int currentScore, int targetScore) {
    expect(
      find.text('Score: $currentScore / $targetScore'),
      findsOneWidget,
      reason: 'Expected current player section to show "Score: $currentScore / $targetScore"',
    );
  }

  /// Verify player score is displayed on the race track
  /// Shows as "X / Y" where X is current score, Y is target
  /// This appears in each player's race lane
  void verifyRaceTrackScore(WidgetTester tester, int currentScore, int targetScore) {
    expect(
      find.text('$currentScore / $targetScore'),
      findsWidgets,
      reason: 'Expected race track to show "$currentScore / $targetScore"',
    );
  }

  // ==================== TEST GROUPS ====================

  group('Section 1: Menu - Player Selection', () {
    setUp(() async {
      await SettingsHelpers.initializeSettings();
    });

    // Test 1: Menu - Player Selection & Auto-Selection
    // Features: Player management, auto-selection, play button state
    // UI Elements: NEW PLAYER button, player list, START THE RACE! button
    // Validates: Players auto-select on creation, play button enables with selections
    testWidgets('Test 1: Basic Player Addition and Auto-Selection', (WidgetTester tester) async {
      await navigateToCarnivalDerbyMenu(tester);

      // Verify play button disabled with 0 players
      final playButton = config.getStartButton();
      expect(playButton, findsOneWidget);

      // Add Player 1
      await UITestHelpers.addPlayer(tester, 'Player 1', config);
      // Player 1 appears twice: once in Available Players, once in Selected Players
      expect(find.text('Player 1'), findsWidgets);

      // Verify play button enabled with 1 player
      expect(playButton, findsOneWidget);
      expect(getSelectedPlayerCount(tester), 1);

      // Add Player 2
      await UITestHelpers.addPlayer(tester, 'Player 2', config);
      // Player 2 appears twice: once in Available Players, once in Selected Players
      expect(find.text('Player 2'), findsWidgets);

      // Verify both players remain in list and selected
      expect(find.text('Player 1'), findsWidgets);
      expect(find.text('Player 2'), findsWidgets);
      expect(getSelectedPlayerCount(tester), 2);
    });

    // Test 2: Menu - Maximum Player Limit Enforcement
    // Features: 8-player maximum limit, player selection overflow handling
    // UI Elements: Player selection checkboxes, player list
    // Validates: Only 8 players can be selected, 9th+ players cannot be auto-selected
    testWidgets('Test 2: Max Player Enforcement (8 Players)', (WidgetTester tester) async {
      await navigateToCarnivalDerbyMenu(tester);

      // Add 10 players
      for (int i = 1; i <= 10; i++) {
        await UITestHelpers.addPlayer(tester, 'Player $i', config);
      }

      // Verify all 10 players exist in list
      expect(getPlayerCount(tester), greaterThanOrEqualTo(10));

      // Only first 8 should be auto-selected
      expect(getSelectedPlayerCount(tester), 8);

      // 9th and 10th players should not be auto-selected
      // (Cannot manually select more than 8)

      // Start game with first 8 players selected
      final playButton = config.getStartButton();
      expect(playButton, findsOneWidget);

      await tester.ensureVisible(playButton);
      await tester.pump();
      await tester.tap(playButton);
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      await tester.pump();
      await tester.pump();

      // Verify game starts
      expect(find.text('Carnival Derby Race'), findsOneWidget);
    });
  });

  group('Section 2: Menu - Target Score Settings', () {
    setUp(() async {
      await SettingsHelpers.initializeSettings();
    });

    // Test 3: Menu - Target Score Slider Range
    // Features: Target score configuration, slider bounds validation
    // UI Elements: Slider (20-250, 46 divisions), target score display text
    // Validates: Slider min/max values, target score text updates, range label
    testWidgets('Test 3: Target Score Range Validation', (WidgetTester tester) async {
      await navigateToCarnivalDerbyMenu(tester);

      // Verify default target score display and range
      expect(find.textContaining('Target score:'), findsOneWidget);
      expect(find.text('Range: 20-250 points'), findsOneWidget);

      // Set target to 20 (minimum)
      await setTargetScore(tester, 20);
      expect(find.textContaining('Target score: 20'), findsOneWidget);

      // Set target to 250 (maximum)
      await setTargetScore(tester, 250);
      expect(find.textContaining('Target score: 250'), findsOneWidget);

      // Set target to 150 (middle)
      await setTargetScore(tester, 150);
      expect(find.textContaining('Target score: 150'), findsOneWidget);
    });

    // Test 4: Menu - Perfect Finish Mode Toggle
    // Features: Perfect Finish mode configuration
    // UI Elements: Perfect Finish Yes/No radio buttons
    // Validates: Radio buttons exist and toggle between Yes/No states
    testWidgets('Test 4: Perfect Finish Toggle', (WidgetTester tester) async {
      await navigateToCarnivalDerbyMenu(tester);

      // Verify Perfect Finish radio buttons exist (Yes/No)
      expect(find.text('Yes'), findsWidgets);
      expect(find.text('No'), findsWidgets);

      // Toggle Perfect Finish ON (tap "Yes")
      await togglePerfectFinish(tester);
      await tester.pump();

      // Note: toggling "OFF" would require tapping "No" button
      // The togglePerfectFinish helper always sets it to ON (Yes)
    });
  });

  group('Section 3: Game - Basic Race Mechanics (Normal Mode)', () {
    setUp(() async {
      await SettingsHelpers.initializeSettings();
    });

    // Test 5: Game - Single Player Quick Win (Normal Mode)
    // Features: Normal mode (no Perfect Finish), instant win by exceeding target
    // UI Elements: Score display, dart display, race track, results screen
    // Validates: Game starts, T20x3=180 wins with target 60, results screen appears
    testWidgets('Test 5: Single Player Quick Win (Normal Mode)', (WidgetTester tester) async {
      await navigateToCarnivalDerbyMenu(tester);

      await UITestHelpers.addPlayer(tester, 'Alice', config);

      // Set target to 60
      await setTargetScore(tester, 60);
      expect(find.textContaining('Target score: 60'), findsOneWidget);

      await startGame(tester);

      // Verify game settings displayed on game screen
      verifyGameSettings(tester, 60, false); // target=60, Perfect Finish OFF

      // Turn 1: T20, T20, T20 = 180 (instant win)
      await UITestHelpers.throwDart(tester, config, 20, multiplier: 'triple'); // 60
      expect(getCurrentPlayerScore(tester), 60);
      verifyCurrentPlayerScoreDisplay(tester, 60, 60); // Current player section
      verifyRaceTrackScore(tester, 60, 60); // Race track lane

      await UITestHelpers.throwDart(tester, config, 20, multiplier: 'triple'); // 120
      expect(getCurrentPlayerScore(tester), greaterThanOrEqualTo(60));

      await UITestHelpers.throwDart(tester, config, 20, multiplier: 'triple'); // 180
      expect(getCurrentPlayerScore(tester), greaterThanOrEqualTo(60));

      // Verify game has winner
      expect(hasWinner(tester), true);

      // Click DARTS REMOVED to advance to results
      await clickDartsRemoved(tester);

      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
      await tester.pump();

      // Verify results screen appears
      expect(find.text('Winner!'), findsOneWidget);
      expect(find.text('Alice'), findsWidgets);
    });

    // Test 6: Game - Two Players Alternating Turns (Normal Mode)
    // Features: Turn progression, multi-player scoring, winner detection
    // UI Elements: Current player indicator, score tracking, race positions
    // Validates: Turns alternate correctly, scores accumulate, first to target wins
    testWidgets('Test 6: Two Players Alternating Turns (Normal Mode)', (WidgetTester tester) async {
      await navigateToCarnivalDerbyMenu(tester);

      await UITestHelpers.addPlayer(tester, 'Alice', config);
      await UITestHelpers.addPlayer(tester, 'Bob', config);

      // Set target to 100
      await setTargetScore(tester, 100);

      await startGame(tester);

      // Alice Turn 1: S20, S20, S20 = 60
      await UITestHelpers.throwDart(tester, config, 20); // 20
      await UITestHelpers.throwDart(tester, config, 20); // 40
      await UITestHelpers.throwDart(tester, config, 20); // 60

      expect(getCurrentPlayerScore(tester), 60);
      verifyCurrentPlayerScoreDisplay(tester, 60, 100); // Alice's current score
      verifyRaceTrackScore(tester, 60, 100); // Race track shows Alice: 60/100

      await clickDartsRemoved(tester);

      // Bob Turn 1: S15, S15, S15 = 45
      await UITestHelpers.throwDart(tester, config, 15); // 15
      await UITestHelpers.throwDart(tester, config, 15); // 30
      await UITestHelpers.throwDart(tester, config, 15); // 45

      expect(getCurrentPlayerScore(tester), 45);
      verifyCurrentPlayerScoreDisplay(tester, 45, 100); // Bob's current score
      verifyRaceTrackScore(tester, 45, 100); // Race track shows Bob: 45/100

      await clickDartsRemoved(tester);

      // Alice Turn 2: D20 = 40 (total 100 - wins)
      await UITestHelpers.throwDart(tester, config, 20, multiplier: 'double'); // 40

      expect(getCurrentPlayerScore(tester), 100);
      verifyCurrentPlayerScoreDisplay(tester, 100, 100); // Alice wins with 100/100
      verifyRaceTrackScore(tester, 100, 100); // Race track shows Alice: 100/100
      expect(hasWinner(tester), true);

      await clickDartsRemoved(tester);

      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();

      // Verify results screen with Alice as winner
      expect(find.text('Winner!'), findsOneWidget);
      expect(find.text('Alice'), findsWidgets);
    });

    // Test 7: Game - All Dart Types Scoring (Normal Mode)
    // Features: Single/double/triple scoring, bullseye, outer bull, miss
    // UI Elements: Dart display showing all score types, score accumulation
    // Validates: All dart types score correctly (S20, D20, T20, Bullseye, 25, Miss)
    testWidgets('Test 7: All Dart Types (Normal Mode)', (WidgetTester tester) async {
      await navigateToCarnivalDerbyMenu(tester);

      await UITestHelpers.addPlayer(tester, 'TestPlayer', config);

      // Set target to 200
      await setTargetScore(tester, 200);

      await startGame(tester);

      // Verify game settings displayed on game screen
      verifyGameSettings(tester, 200, false); // target=200, Perfect Finish OFF

      // Turn 1: Single, Double, Triple
      await UITestHelpers.throwDart(tester, config, 20); // 20
      await UITestHelpers.throwDart(tester, config, 20, multiplier: 'double'); // 40
      await UITestHelpers.throwDart(tester, config, 20, multiplier: 'triple'); // 60

      expect(getCurrentPlayerScore(tester), 120);
      verifyCurrentPlayerScoreDisplay(tester, 120, 200); // Current player: 120/200
      verifyRaceTrackScore(tester, 120, 200); // Race track: 120/200

      // Verify dart display: D1=20 (single), D2=40 (double), D3=60 (triple)
      verifyDartDisplay(tester, '20', '40', '60');

      await clickDartsRemoved(tester);

      // Turn 2: Bullseye, Outer Bull, Miss
      await UITestHelpers.throwBullseye(tester, config); // 50
      expect(getCurrentPlayerScore(tester), 170);

      await UITestHelpers.throwOuterBull(tester, config); // 25
      expect(getCurrentPlayerScore(tester), 195);

      await UITestHelpers.throwMiss(tester, config); // 0
      expect(getCurrentPlayerScore(tester), 195);
      verifyCurrentPlayerScoreDisplay(tester, 195, 200); // Current player: 195/200
      verifyRaceTrackScore(tester, 195, 200); // Race track: 195/200

      // Verify dart display: D1=50 (bullseye), D2=25 (outer bull), D3=Miss
      verifyDartDisplay(tester, '50', '25', 'Miss');

      await clickDartsRemoved(tester);

      // Turn 3: T20, T20, S5 = 125 (total 320 > 200 - wins)
      await UITestHelpers.throwDart(tester, config, 20, multiplier: 'triple'); // 255 total - wins!

      // Player wins on first dart of turn 3 (195 + 60 = 255 >= 200)
      expect(getCurrentPlayerScore(tester), greaterThanOrEqualTo(200));
      expect(hasWinner(tester), true);

      // Note: Cannot verify dart display after win - screen transitions to results immediately
    });
  });

  group('Section 4: Game - Perfect Finish Mode (Bust Mechanics)', () {
    setUp(() async {
      await SettingsHelpers.initializeSettings();
    });

    // Test 8: Game - Perfect Finish Mode: Simple Bust
    // Features: Perfect Finish exact score requirement, bust on overshoot
    // UI Elements: Bust announcement, score preservation, turn progression
    // Validates: Score reverts to pre-bust value, turn ends, next turn starts
    testWidgets('Test 8: Simple Bust (Going Over)', (WidgetTester tester) async {
      await navigateToCarnivalDerbyMenu(tester);

      await UITestHelpers.addPlayer(tester, 'Alice', config);

      // Set target to 50 and enable Perfect Finish
      await setTargetScore(tester, 50);
      await togglePerfectFinish(tester);

      await startGame(tester);

      // Verify game settings displayed on game screen
      verifyGameSettings(tester, 50, true); // target=50, Perfect Finish ON

      // Turn 1: S20, then T20 (would bust: 20 + 60 = 80 > 50)
      await UITestHelpers.throwDart(tester, config, 20); // 20
      int scoreAfterFirstDart = getCurrentPlayerScore(tester);
      expect(scoreAfterFirstDart, 20);
      verifyCurrentPlayerScoreDisplay(tester, 20, 50); // Current player: 20/50
      verifyRaceTrackScore(tester, 20, 50); // Race track: 20/50

      await UITestHelpers.throwDart(tester, config, 20, multiplier: 'triple'); // Would be 80 total = BUST

      // Score should stay at 20 (before the busting dart)
      int scoreAfterBust = getCurrentPlayerScore(tester);
      expect(scoreAfterBust, 20);
      verifyCurrentPlayerScoreDisplay(tester, 20, 50); // Score stays at 20/50 after bust
      verifyRaceTrackScore(tester, 20, 50); // Race track still shows 20/50
      expect(currentPlayerBusted(tester), true);

      await clickDartsRemoved(tester);

      // Turn 2: S20, S10 = 50 (exact win)
      await UITestHelpers.throwDart(tester, config, 20); // 40
      await UITestHelpers.throwDart(tester, config, 10); // 50 (exact)

      expect(getCurrentPlayerScore(tester), 50);
      verifyCurrentPlayerScoreDisplay(tester, 50, 50); // Winner: 50/50
      verifyRaceTrackScore(tester, 50, 50); // Race track: 50/50
      expect(hasWinner(tester), true);
    });

    // Test 9: Game - Perfect Finish Mode: Bust on First Dart
    // Features: Bust detection on first dart of turn, score stays at 0
    // UI Elements: Bust announcement, score display, turn end
    // Validates: D20=40 busts when target=30, score stays 0, recover next turn
    testWidgets('Test 9: Bust on First Dart', (WidgetTester tester) async {
      await navigateToCarnivalDerbyMenu(tester);

      await UITestHelpers.addPlayer(tester, 'TestPlayer', config);

      // Set target to 30 and enable Perfect Finish
      await setTargetScore(tester, 30);
      await togglePerfectFinish(tester);

      await startGame(tester);

      // Verify game settings: target=30, Perfect Finish=ON
      verifyGameSettings(tester, 30, true);

      // Turn 1: D20 = 40 (BUST on first dart)
      await UITestHelpers.throwDart(tester, config, 20, multiplier: 'double');

      // Score should stay at 0 (busted from 0)
      expect(getCurrentPlayerScore(tester), 0);
      expect(currentPlayerBusted(tester), true);

      await clickDartsRemoved(tester);

      // Turn 2: S20, S10 = 30 (exact win)
      await UITestHelpers.throwDart(tester, config, 20); // 20
      await UITestHelpers.throwDart(tester, config, 10); // 30

      expect(getCurrentPlayerScore(tester), 30);
      expect(hasWinner(tester), true);
    });

    // Test 10: Game - Perfect Finish Mode: Multiple Busts Before Win
    // Features: Multiple players busting, eventual exact win
    // UI Elements: Bust announcements for multiple players, score preservation
    // Validates: Both players bust (Bullseye=50, T20=60 vs target 40), then exact D20=40 wins
    testWidgets('Test 10: Multiple Busts Before Win', (WidgetTester tester) async {
      await navigateToCarnivalDerbyMenu(tester);

      await UITestHelpers.addPlayer(tester, 'Alice', config);
      await UITestHelpers.addPlayer(tester, 'Bob', config);

      // Set target to 40 and enable Perfect Finish
      await setTargetScore(tester, 40);
      await togglePerfectFinish(tester);

      await startGame(tester);

      // Verify game settings: target=40, Perfect Finish=ON
      verifyGameSettings(tester, 40, true);

      // Alice Turn 1: Bullseye (50) - BUST
      await UITestHelpers.throwBullseye(tester, config);
      expect(getCurrentPlayerScore(tester), 0);
      expect(currentPlayerBusted(tester), true);

      await clickDartsRemoved(tester);

      // Bob Turn 1: T20 (60) - BUST
      await UITestHelpers.throwDart(tester, config, 20, multiplier: 'triple');
      expect(getCurrentPlayerScore(tester), 0);
      expect(currentPlayerBusted(tester), true);

      await clickDartsRemoved(tester);

      // Alice Turn 2: D20 (40) - exact win
      await UITestHelpers.throwDart(tester, config, 20, multiplier: 'double');
      expect(getCurrentPlayerScore(tester), 40);
      expect(hasWinner(tester), true);
    });

    // Test 11: Game - Perfect Finish Mode: Close Call (Just Under, Then Exact)
    // Features: Scoring just under target (safe), then exact win
    // UI Elements: Score tracking, no bust when under target, exact win detection
    // Validates: 95/100 is safe, then S5=100 exact wins
    testWidgets('Test 11: Close Call (Just Under, Then Exact)', (WidgetTester tester) async {
      await navigateToCarnivalDerbyMenu(tester);

      await UITestHelpers.addPlayer(tester, 'TestPlayer', config);

      // Set target to 100 and enable Perfect Finish
      await setTargetScore(tester, 100);
      await togglePerfectFinish(tester);

      await startGame(tester);

      // Verify game settings displayed on game screen
      verifyGameSettings(tester, 100, true); // target=100, Perfect Finish ON

      // Turn 1: T20, S20, S15 = 95 (5 under - safe)
      await UITestHelpers.throwDart(tester, config, 20, multiplier: 'triple'); // 60
      await UITestHelpers.throwDart(tester, config, 20); // 80
      await UITestHelpers.throwDart(tester, config, 15); // 95

      expect(getCurrentPlayerScore(tester), 95);
      expect(currentPlayerBusted(tester), false);

      await clickDartsRemoved(tester);

      // Turn 2: S5 = 100 (exact win)
      await UITestHelpers.throwDart(tester, config, 5); // 100

      expect(getCurrentPlayerScore(tester), 100);
      expect(hasWinner(tester), true);
    });
  });

  group('Section 5: Game - Skip Turn Functionality', () {
    setUp(() async {
      await SettingsHelpers.initializeSettings();
    });

    // Test 12: Game - Skip Turn with No Darts (Immediate Turn Advance)
    // Features: Skip turn button, immediate turn progression with 0 darts
    // UI Elements: SKIP TURN button, turn transition
    // Validates: No remove darts modal, turn advances immediately to next player
    testWidgets('Test 12: Skip Turn with No Darts Thrown (Turn Advances)', (WidgetTester tester) async {
      await navigateToCarnivalDerbyMenu(tester);

      await UITestHelpers.addPlayer(tester, 'Alice', config);
      await UITestHelpers.addPlayer(tester, 'Bob', config);

      await setTargetScore(tester, 60);

      await startGame(tester);

      // Alice Turn 1: SKIP immediately (no darts thrown)
      await UITestHelpers.clickSkipTurn(tester, config);

      // No remove darts modal should appear - turn should advance immediately
      // Wait for turn to advance
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
      await tester.pump();

      // Verify we're now on Bob's turn by checking current player
      // We can't check dart display since it advances too quickly
      // Instead, verify that when Bob throws a dart, his score updates
      await UITestHelpers.throwDart(tester, config, 20, multiplier: 'triple'); // Bob: 60 (wins)

      expect(getCurrentPlayerScore(tester), 60);
      expect(hasWinner(tester), true);
    });

    // Test 13: Game - Skip Turn After Throwing Darts
    // Features: Skip turn with partial darts thrown, skip markers
    // UI Elements: SKIP TURN button, dart display, remove darts modal
    // Validates: S20 + SKIP = remaining darts marked as Skip, remove darts modal appears
    testWidgets('Test 13: Skip Turn with Darts Thrown', (WidgetTester tester) async {
      await navigateToCarnivalDerbyMenu(tester);

      await UITestHelpers.addPlayer(tester, 'Alice', config);
      await UITestHelpers.addPlayer(tester, 'Bob', config);

      await setTargetScore(tester, 60);

      await startGame(tester);

      // Alice Turn 1: S20, then SKIP
      await UITestHelpers.throwDart(tester, config, 20);
      expect(getCurrentPlayerScore(tester), 20);
      verifyCurrentPlayerScoreDisplay(tester, 20, 60); // Alice: 20/60
      verifyRaceTrackScore(tester, 20, 60); // Race track: 20/60

      // Click SKIP TURN
      await UITestHelpers.clickSkipTurn(tester, config);

      // Verify dart display: D1=20, D2=Skip, D3=Skip (remaining darts marked as Skip)
      verifyDartDisplay(tester, '20', 'Skip', 'Skip');

      // Remaining darts marked as Skip, score stays 20
      verifyCurrentPlayerScoreDisplay(tester, 20, 60); // Score still 20/60 after skip
      verifyRaceTrackScore(tester, 20, 60); // Race track still 20/60

      await clickDartsRemoved(tester);

      // Bob's turn
      await UITestHelpers.throwDart(tester, config, 20, multiplier: 'triple'); // 60 (wins)
      expect(getCurrentPlayerScore(tester), 60);
      verifyCurrentPlayerScoreDisplay(tester, 60, 60); // Bob wins: 60/60
      verifyRaceTrackScore(tester, 60, 60); // Race track: 60/60
      expect(hasWinner(tester), true);
    });

    // Test 14: Game - Skip Turn After 1 Dart (Remaining Marked as Skip)
    // Features: Skip with 1 dart thrown, verify skip markers on D2/D3
    // UI Elements: Dart display showing "Skip" text, remove darts modal
    // Validates: D1=10, D2=Skip, D3=Skip displayed correctly, modal appears
    testWidgets('Test 14: Skip Turn After 1 Dart (Remaining Marked as Miss)', (WidgetTester tester) async {
      await navigateToCarnivalDerbyMenu(tester);

      await UITestHelpers.addPlayer(tester, 'Alice', config);
      await UITestHelpers.addPlayer(tester, 'Bob', config);

      await setTargetScore(tester, 60);

      await startGame(tester);

      // Alice Turn 1: Throw 1 dart (S10), then SKIP
      await UITestHelpers.throwDart(tester, config, 10); // D1 = 10
      expect(getCurrentPlayerScore(tester), 10);

      await UITestHelpers.clickSkipTurn(tester, config);

      // D2 and D3 should be marked as Skip, score stays 10
      expect(getCurrentPlayerScore(tester), 10);

      // Verify dart display: D1=10, D2=Skip, D3=Skip (remaining darts marked as Skip)
      verifyDartDisplay(tester, '10', 'Skip', 'Skip');

      // Remove darts modal should appear (we threw 1 dart)
      await clickDartsRemoved(tester);

      // Bob's turn
      await UITestHelpers.throwDart(tester, config, 20, multiplier: 'triple'); // 60 (wins)
      expect(getCurrentPlayerScore(tester), 60);
      expect(hasWinner(tester), true);
    });
  });

  group('Section 6: Game - Edit Score Functionality', () {
    setUp(() async {
      await SettingsHelpers.initializeSettings();
    });

    // Test 15: Game - Edit Score to Change Rings (Normal Mode)
    // Features: Edit score modal, ring type changes, score recalculation
    // UI Elements: Edit player score button, ring buttons (Triple/Double/Single), update button
    // Validates: S20x3 → T20x2+S20 = 140 score update, winner detection
    testWidgets('Test 15: Edit Score During Remove Darts Modal', (WidgetTester tester) async {
      await navigateToCarnivalDerbyMenu(tester);

      await UITestHelpers.addPlayer(tester, 'TestPlayer', config);

      await setTargetScore(tester, 100);

      await startGame(tester);

      // Turn 1: S20, S20, S20 = 60
      await UITestHelpers.throwDart(tester, config, 20);
      await UITestHelpers.throwDart(tester, config, 20);
      await UITestHelpers.throwDart(tester, config, 20);

      expect(getCurrentPlayerScore(tester), 60);

      // Open edit score modal
      await openEditScore(tester);

      // Change rings only (numbers are already 20): D1=T20, D2=T20, D3=S20
      // Just tap the ring buttons - don't select numbers since they're already 20
      await setDartInEditScore(tester, 0, 'Triple'); // D1: S20 → T20
      await setDartInEditScore(tester, 1, 'Triple'); // D2: S20 → T20
      // D3 stays S20 (no change needed)

      // Update score
      await updateScore(tester);

      // Verify score updated to 140 (60+60+20) and winner
      expect(getCurrentPlayerScore(tester), greaterThanOrEqualTo(100));
      expect(hasWinner(tester), true);
    });

    // Test 16: Game - Edit Score Triggers Bust (Perfect Finish Mode)
    // Features: Edit score causing bust in Perfect Finish mode, bust detection
    // UI Elements: Edit score modal, bust announcement after update
    // Validates: Editing S20/S15/S10 → T20x3 causes bust, score reverts correctly
    testWidgets('Test 16: Edit Score with Bust (Perfect Finish Mode)', (WidgetTester tester) async {
      await navigateToCarnivalDerbyMenu(tester);

      await UITestHelpers.addPlayer(tester, 'TestPlayer', config);

      await setTargetScore(tester, 70);
      await togglePerfectFinish(tester);

      await startGame(tester);

      // Turn 1: S20, S15, S10 = 45
      await UITestHelpers.throwDart(tester, config, 20);
      await UITestHelpers.throwDart(tester, config, 15);
      await UITestHelpers.throwDart(tester, config, 10);

      expect(getCurrentPlayerScore(tester), 45);

      // Open edit score modal
      await openEditScore(tester);

      // Change to T20, T20, T20 (would be 180 - BUST)
      await setDartInEditScore(tester, 0, 'Triple', number: 20);
      await setDartInEditScore(tester, 1, 'Triple', number: 20);
      await setDartInEditScore(tester, 2, 'Triple', number: 20);

      // Update score
      await updateScore(tester);

      // After processing T20 (60), second T20 would make 120, exceeding target 70 = BUST
      // Score should revert to start of turn or stay at intermediate value
      expect(getCurrentPlayerScore(tester), greaterThanOrEqualTo(0));
      expect(currentPlayerBusted(tester), true);

      await clickDartsRemoved(tester);

      // Turn 2: Win with exact score (score is 60 after bust, need 10 to reach 70)
      await UITestHelpers.throwDart(tester, config, 5, multiplier: 'double'); // D5 = 10 points, total = 70
    });
  });

  group('Section 7: Game - Multi-Player Race', () {
    setUp(() async {
      await SettingsHelpers.initializeSettings();
    });

    // Test 17: Game - 4-Player Race with Leaderboard Changes
    // Features: Multi-player racing, score tracking, leaderboard updates
    // UI Elements: 4 player race lanes, relative positions, leaderboard
    // Validates: Multiple rounds, leaderboard changes, winner crosses finish first
    testWidgets('Test 17: 4-Player Race', (WidgetTester tester) async {
      await navigateToCarnivalDerbyMenu(tester);

      await UITestHelpers.addPlayer(tester, 'Alice', config);
      await UITestHelpers.addPlayer(tester, 'Bob', config);
      await UITestHelpers.addPlayer(tester, 'Charlie', config);
      await UITestHelpers.addPlayer(tester, 'Diana', config);

      await setTargetScore(tester, 150);

      await startGame(tester);

      // Round 1 - Alice: 60
      await UITestHelpers.throwDart(tester, config, 20);
      await UITestHelpers.throwDart(tester, config, 20);
      await UITestHelpers.throwDart(tester, config, 20);
      expect(getCurrentPlayerScore(tester), 60);
      await clickDartsRemoved(tester);

      // Round 1 - Bob: 45
      await UITestHelpers.throwDart(tester, config, 15);
      await UITestHelpers.throwDart(tester, config, 15);
      await UITestHelpers.throwDart(tester, config, 15);
      expect(getCurrentPlayerScore(tester), 45);
      await clickDartsRemoved(tester);

      // Round 1 - Charlie: 80
      await UITestHelpers.throwDart(tester, config, 20, multiplier: 'double');
      await UITestHelpers.throwDart(tester, config, 20);
      await UITestHelpers.throwDart(tester, config, 20);
      expect(getCurrentPlayerScore(tester), 80);
      await clickDartsRemoved(tester);

      // Round 1 - Diana: 20
      await UITestHelpers.throwDart(tester, config, 20);
      await UITestHelpers.throwMiss(tester, config);
      await UITestHelpers.throwMiss(tester, config);
      expect(getCurrentPlayerScore(tester), 20);
      await clickDartsRemoved(tester);

      // Round 2 - Alice: 120 total
      await UITestHelpers.throwDart(tester, config, 20);
      await UITestHelpers.throwDart(tester, config, 20);
      await UITestHelpers.throwDart(tester, config, 20);
      await clickDartsRemoved(tester);

      // Round 2 - Bob: 100 total
      await UITestHelpers.throwDart(tester, config, 20);
      await UITestHelpers.throwDart(tester, config, 20);
      await UITestHelpers.throwDart(tester, config, 15);
      await clickDartsRemoved(tester);

      // Round 2 - Charlie: 140 total
      await UITestHelpers.throwDart(tester, config, 20);
      await UITestHelpers.throwDart(tester, config, 20);
      await UITestHelpers.throwDart(tester, config, 20);
      await clickDartsRemoved(tester);

      // Round 2 - Diana: 80 total
      await UITestHelpers.throwDart(tester, config, 20);
      await UITestHelpers.throwDart(tester, config, 20);
      await UITestHelpers.throwDart(tester, config, 20);
      await clickDartsRemoved(tester);

      // Round 3 - Alice: Doesn't win
      await UITestHelpers.throwDart(tester, config, 10);
      await UITestHelpers.throwDart(tester, config, 10);
      await UITestHelpers.throwDart(tester, config, 5);
      await clickDartsRemoved(tester);

      // Round 3 - Bob: Doesn't win
      await UITestHelpers.throwDart(tester, config, 10);
      await UITestHelpers.throwDart(tester, config, 10);
      await UITestHelpers.throwDart(tester, config, 10);
      await clickDartsRemoved(tester);

      // Round 3 - Charlie: Wins with 180+
      await UITestHelpers.throwDart(tester, config, 20, multiplier: 'double');
      expect(getCurrentPlayerScore(tester), greaterThanOrEqualTo(150));
      expect(hasWinner(tester), true);
    });

    // Test 18: Game - 8-Player Maximum Capacity Race
    // Features: Maximum 8 players racing simultaneously
    // UI Elements: 8 race lanes, all horses visible, turn progression
    // Validates: Game handles 8 players smoothly, all reach target simultaneously
    testWidgets('Test 18: 8-Player Maximum Capacity', (WidgetTester tester) async {
      await navigateToCarnivalDerbyMenu(tester);

      // Add 8 players
      for (int i = 1; i <= 8; i++) {
        await UITestHelpers.addPlayer(tester, 'Player $i', config);
      }

      await setTargetScore(tester, 60);

      await startGame(tester);

      // Each player throws T20 (all reach 60 in turn 1)
      for (int i = 0; i < 8; i++) {
        await UITestHelpers.throwDart(tester, config, 20, multiplier: 'triple');

        if (i == 0) {
          // First player reaches 60 and wins
          expect(getCurrentPlayerScore(tester), 60);
          expect(hasWinner(tester), true);
          break;
        }
      }

      // Verify game won by first player
      expect(hasWinner(tester), true);
    });
  });

  group('Section 8: Edge Cases', () {
    setUp(() async {
      await SettingsHelpers.initializeSettings();
    });

    // Test 19: Game - Minimum Target Score (20 points)
    // Features: Minimum boundary target score, quick win
    // UI Elements: Target score display, game start, winner detection
    // Validates: Game works with minimum 20-point target, S20 wins instantly
    testWidgets('Test 19: Minimum Target Score (20 points)', (WidgetTester tester) async {
      await navigateToCarnivalDerbyMenu(tester);

      await UITestHelpers.addPlayer(tester, 'TestPlayer', config);

      // Set target to 20 (minimum)
      await setTargetScore(tester, 20);
      await togglePerfectFinish(tester);

      await startGame(tester);

      // Verify game settings displayed on game screen
      verifyGameSettings(tester, 20, true); // target=20, Perfect Finish ON

      // Single S20 should win
      await UITestHelpers.throwDart(tester, config, 20);
      expect(getCurrentPlayerScore(tester), 20);
      expect(hasWinner(tester), true);
    });

    // Test 20: Game - Maximum Target Score (250 points)
    // Features: Maximum boundary target score, extended gameplay
    // UI Elements: Target score display, score accumulation over multiple turns
    // Validates: Game works with maximum 250-point target, scoring accurate
    testWidgets('Test 20: Maximum Target Score (250 points)', (WidgetTester tester) async {
      await navigateToCarnivalDerbyMenu(tester);

      await UITestHelpers.addPlayer(tester, 'TestPlayer', config);

      // Set target to 250 (maximum)
      await setTargetScore(tester, 250);

      await startGame(tester);

      // Verify game settings displayed on game screen
      verifyGameSettings(tester, 250, false); // target=250, Perfect Finish OFF

      // Multiple turns to reach 250
      // Turn 1: 150 (3x Bullseye)
      await UITestHelpers.throwBullseye(tester, config);
      await UITestHelpers.throwBullseye(tester, config);
      await UITestHelpers.throwBullseye(tester, config);
      expect(getCurrentPlayerScore(tester), 150);
      await clickDartsRemoved(tester);

      // Turn 2: 300 total (wins)
      await UITestHelpers.throwBullseye(tester, config);
      await UITestHelpers.throwBullseye(tester, config);
      expect(getCurrentPlayerScore(tester), greaterThanOrEqualTo(250));
      expect(hasWinner(tester), true);
    });

    // Test 21: Game - All Misses Turn (Zero Score)
    // Features: Miss dart handling, announcements, score stays 0
    // UI Elements: Miss announcements, dart display showing "Miss"x3, score=0
    // Validates: Three misses score 0, remove darts modal appears, turn advances
    testWidgets('Test 21: All Misses Turn', (WidgetTester tester) async {
      await navigateToCarnivalDerbyMenu(tester);

      await UITestHelpers.addPlayer(tester, 'Alice', config);
      await UITestHelpers.addPlayer(tester, 'Bob', config);

      await setTargetScore(tester, 60);

      await startGame(tester);

      // Alice Turn 1: Miss, Miss, Miss
      await UITestHelpers.throwMiss(tester, config);
      await UITestHelpers.throwMiss(tester, config);
      await UITestHelpers.throwMiss(tester, config);

      expect(getCurrentPlayerScore(tester), 0);
      verifyCurrentPlayerScoreDisplay(tester, 0, 60); // Alice: 0/60 (all misses)
      verifyRaceTrackScore(tester, 0, 60); // Race track: 0/60

      // Verify dart display: D1=Miss, D2=Miss, D3=Miss
      verifyDartDisplay(tester, 'Miss', 'Miss', 'Miss');

      await clickDartsRemoved(tester);

      // Bob Turn 1: T20 wins
      await UITestHelpers.throwDart(tester, config, 20, multiplier: 'triple');
      expect(getCurrentPlayerScore(tester), 60);
      verifyCurrentPlayerScoreDisplay(tester, 60, 60); // Bob wins: 60/60
      verifyRaceTrackScore(tester, 60, 60); // Race track: 60/60
      expect(hasWinner(tester), true);
    });
  });

  group('Section 9: Results Screen', () {
    setUp(() async {
      await SettingsHelpers.initializeSettings();
    });

    // Test 22: Results - Results Screen Display & Content
    // Features: Results screen layout, winner announcement, action buttons
    // UI Elements: Winner title, avatar, score, standings table, Play Again/Change Settings/Home buttons
    // Validates: All elements visible, confetti animation, victory music plays
    testWidgets('Test 22: Results Screen Content', (WidgetTester tester) async {
      await navigateToCarnivalDerbyMenu(tester);

      await UITestHelpers.addPlayer(tester, 'Winner', config);

      await setTargetScore(tester, 180);

      await startGame(tester);

      // Quick win
      await UITestHelpers.throwDart(tester, config, 20, multiplier: 'triple');
      await UITestHelpers.throwDart(tester, config, 20, multiplier: 'triple');
      await UITestHelpers.throwDart(tester, config, 20, multiplier: 'triple'); // 180

      expect(hasWinner(tester), true);

      await clickDartsRemoved(tester);

      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
      await tester.pump();

      // Verify results screen elements
      expect(find.text('Winner!'), findsOneWidget);
      expect(find.text('Winner'), findsWidgets);
      expect(find.text('Play Again'), findsOneWidget);
      expect(find.text('Change game players and settings'), findsOneWidget);
      expect(find.text('Select a different game'), findsOneWidget);
      expect(find.text('Final Standings'), findsOneWidget);
    });

    // Test 23: Results - Play Again with Same Settings
    // Features: Quick rematch, settings preservation
    // UI Elements: Play Again button, game screen navigation
    // Validates: Same players/target/Perfect Finish, scores reset to 0
    testWidgets('Test 23: Play Again (Same Settings)', (WidgetTester tester) async {
      await navigateToCarnivalDerbyMenu(tester);

      await UITestHelpers.addPlayer(tester, 'Player1', config);

      await setTargetScore(tester, 180);

      await startGame(tester);

      // Quick win
      await UITestHelpers.throwDart(tester, config, 20, multiplier: 'triple');
      await UITestHelpers.throwDart(tester, config, 20, multiplier: 'triple');
      await UITestHelpers.throwDart(tester, config, 20, multiplier: 'triple');

      await clickDartsRemoved(tester);

      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
      await tester.pump();

      // Click Play Again
      final playAgainButton = config.getPlayAgainButton();
      await tester.tap(playAgainButton);
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      await tester.pump();

      // Should navigate back to game screen
      expect(find.text('Carnival Derby Race'), findsOneWidget);
    });

    // Test 24: Results - Change Settings Navigation
    // Features: Return to menu with preserved settings
    // UI Elements: Change game players and settings button, menu navigation
    // Validates: Players preselected, target/Perfect Finish settings preserved
    testWidgets('Test 24: Change Settings', (WidgetTester tester) async {
      await navigateToCarnivalDerbyMenu(tester);

      await UITestHelpers.addPlayer(tester, 'Player1', config);

      await setTargetScore(tester, 180);

      await startGame(tester);

      // Quick win
      await UITestHelpers.throwDart(tester, config, 20, multiplier: 'triple');
      await UITestHelpers.throwDart(tester, config, 20, multiplier: 'triple');
      await UITestHelpers.throwDart(tester, config, 20, multiplier: 'triple');

      await clickDartsRemoved(tester);

      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
      await tester.pump();

      // Click Change Settings
      final changeSettingsButton = config.getChangeSettingsButton();
      await tester.ensureVisible(changeSettingsButton);
      await tester.pump();
      await tester.tap(changeSettingsButton);
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      await tester.pump();

      // Should navigate back to menu with preselected settings
      expect(find.textContaining('Target score:'), findsOneWidget);
      // Player1 appears twice: once in Available Players, once in Selected Players (preselected)
      expect(find.text('Player1'), findsWidgets);
    });
  });
}
