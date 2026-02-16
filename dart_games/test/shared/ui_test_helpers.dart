import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/main.dart' as app;
import 'game_ui_config.dart';
import 'element_finders.dart';
import 'pump_sequences.dart';
import 'settings_helpers.dart';

/// High-level UI navigation and interaction helpers
///
/// Provides game-agnostic test helpers that work with any game configuration.
/// All operations use widget keys for reliable element finding.
class UITestHelpers {
  // ==========================================================================
  // NAVIGATION HELPERS
  // ==========================================================================

  /// Navigate from home screen to game menu
  ///
  /// Sets up emulator mode, launches app, and navigates to the specified game.
  ///
  /// Example:
  /// ```dart
  /// final config = GameUIConfig.targetTag();
  /// await UITestHelpers.navigateToGameMenu(tester, config);
  /// ```
  static Future<void> navigateToGameMenu(
    WidgetTester tester,
    GameUIConfig config,
  ) async {
    // Set up emulator mode
    await SettingsHelpers.initializeSettings();

    // Launch app
    app.main();
    await tester.pumpAndSettle();
    await tester.pumpAndSettle(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 2)); // Extra wait for home screen to fully render on cold start
    await tester.pump();
    await tester.pump();
    await tester.pump();

    // Tap game card
    final gameCard = config.getGameCard();
    expect(gameCard, findsOneWidget);
    await tester.tap(gameCard);

    // Wait for navigation
    await PumpSequences.navigation(tester);
  }

  /// Start the game from menu screen
  ///
  /// Taps the start game button and waits for navigation to game screen.
  ///
  /// Example:
  /// ```dart
  /// await UITestHelpers.startGame(tester, config);
  /// ```
  static Future<void> startGame(
    WidgetTester tester,
    GameUIConfig config,
  ) async {
    final startButton = config.getStartButton();

    await tester.ensureVisible(startButton);
    await tester.pump();

    await tester.tap(startButton);
    await PumpSequences.navigation(tester);
  }

  // ==========================================================================
  // PLAYER MANAGEMENT HELPERS
  // ==========================================================================

  /// Add a player via the add player dialog
  ///
  /// Opens dialog, enters name, and saves the player.
  /// Waits for async data loading after player is saved.
  ///
  /// Example:
  /// ```dart
  /// await UITestHelpers.addPlayer(tester, 'Alice', config);
  /// ```
  static Future<void> addPlayer(
    WidgetTester tester,
    String name,
    GameUIConfig config,
  ) async {
    final addButton = config.getAddPlayerButton();

    await tester.ensureVisible(addButton.first);
    await tester.pump();

    await tester.tap(addButton.first);
    await PumpSequences.dialogOpen(tester);

    final nameField = ElementFinders.getAddPlayerNameField();
    await tester.enterText(nameField, name);
    await PumpSequences.textEntry(tester);

    final addPlayerButton = ElementFinders.getAddPlayerAddButton();
    await tester.tap(addPlayerButton.first);
    await PumpSequences.dialogClose(tester);
    await PumpSequences.asyncDataLoad(tester);
  }

  /// Select multiple players from the player list
  ///
  /// Taps each player tile in sequence.
  ///
  /// Example:
  /// ```dart
  /// await UITestHelpers.selectPlayers(tester, ['player1', 'player2'], config);
  /// ```
  static Future<void> selectPlayers(
    WidgetTester tester,
    List<String> playerIds,
    GameUIConfig config,
  ) async {
    for (final playerId in playerIds) {
      final playerTile = config.getPlayerTile(playerId);
      await tester.ensureVisible(playerTile.first);
      await tester.pump();

      await tester.tap(playerTile.first);
      await PumpSequences.simpleUpdate(tester);
    }
  }

  // ==========================================================================
  // DART THROWING HELPERS
  // ==========================================================================

  /// Throw a dart (number with multiplier)
  ///
  /// Examples:
  /// ```dart
  /// await UITestHelpers.throwDart(tester, config, 20); // S20
  /// await UITestHelpers.throwDart(tester, config, 20, multiplier: 'double'); // D20
  /// await UITestHelpers.throwDart(tester, config, 20, multiplier: 'triple'); // T20
  /// ```
  static Future<void> throwDart(
    WidgetTester tester,
    GameUIConfig config,
    int number, {
    String multiplier = 'single',
  }) async {
    final dartButton = config.getDartButton(multiplier, number);

    await tester.tap(dartButton);
    await PumpSequences.simpleUpdate(tester);
  }

  /// Throw bullseye (50 points)
  ///
  /// Example:
  /// ```dart
  /// await UITestHelpers.throwBullseye(tester, config);
  /// ```
  static Future<void> throwBullseye(
    WidgetTester tester,
    GameUIConfig config,
  ) async {
    final bullButton = config.getBullseyeButton();

    await tester.tap(bullButton);
    await PumpSequences.simpleUpdate(tester);
  }

  /// Throw outer bull (25 points)
  ///
  /// Example:
  /// ```dart
  /// await UITestHelpers.throwOuterBull(tester, config);
  /// ```
  static Future<void> throwOuterBull(
    WidgetTester tester,
    GameUIConfig config,
  ) async {
    final outerBullButton = config.getOuterBullButton();

    await tester.tap(outerBullButton);
    await PumpSequences.simpleUpdate(tester);
  }

  /// Throw miss (0 points)
  ///
  /// Example:
  /// ```dart
  /// await UITestHelpers.throwMiss(tester, config);
  /// ```
  static Future<void> throwMiss(
    WidgetTester tester,
    GameUIConfig config,
  ) async {
    final missButton = config.getMissButton();

    await tester.tap(missButton);
    await PumpSequences.simpleUpdate(tester);
  }

  // ==========================================================================
  // GAME CONTROL HELPERS
  // ==========================================================================

  /// Click "Skip Turn" button
  ///
  /// Example:
  /// ```dart
  /// await UITestHelpers.clickSkipTurn(tester, config);
  /// ```
  static Future<void> clickSkipTurn(
    WidgetTester tester,
    GameUIConfig config,
  ) async {
    final skipButton = config.getSkipTurnButton();

    await tester.tap(skipButton);
    await PumpSequences.simpleUpdate(tester);
  }

  // NOTE: clickDartsRemoved() not implemented yet
  // Waiting for dartsRemovedButton to be added to CarnivalDerbyGameKeys and TargetTagGameKeys
  // Will be added when Phase 1D game control keys are complete
  //
  // static Future<void> clickDartsRemoved(
  //   WidgetTester tester,
  //   GameUIConfig config,
  // ) async {
  //   final removeButton = config.getDartsRemovedButton();
  //   await tester.tap(removeButton);
  //   await PumpSequences.simpleUpdate(tester);
  // }

  // ==========================================================================
  // COMPLETE GAME FLOW HELPERS
  // ==========================================================================

  /// Play a complete game with specified dart sequence
  ///
  /// Throws darts in sequence until game is complete.
  /// Each dart is specified as a map with 'multiplier' and 'number' keys.
  /// Special darts: 'bullseye', 'outer_bull', 'miss'
  ///
  /// Example:
  /// ```dart
  /// await UITestHelpers.playCompleteGame(tester, config, [
  ///   {'multiplier': 'triple', 'number': 20},  // T20
  ///   {'multiplier': 'triple', 'number': 20},  // T20
  ///   {'multiplier': 'bullseye'},              // Bullseye
  ///   {'multiplier': 'miss'},                  // Miss
  /// ]);
  /// ```
  static Future<void> playCompleteGame(
    WidgetTester tester,
    GameUIConfig config,
    List<Map<String, dynamic>> dartSequence,
  ) async {
    for (final dart in dartSequence) {
      final multiplier = dart['multiplier'] as String;

      if (multiplier == 'bullseye') {
        await throwBullseye(tester, config);
      } else if (multiplier == 'outer_bull') {
        await throwOuterBull(tester, config);
      } else if (multiplier == 'miss') {
        await throwMiss(tester, config);
      } else {
        final number = dart['number'] as int;
        await throwDart(tester, config, number, multiplier: multiplier);
      }
    }
  }

  // ==========================================================================
  // RESULTS SCREEN HELPERS
  // ==========================================================================

  /// Verify results screen is showing and contains winner information
  ///
  /// Checks for play again, change settings, and back to menu buttons.
  ///
  /// Example:
  /// ```dart
  /// await UITestHelpers.verifyResultsScreen(tester, config);
  /// ```
  static Future<void> verifyResultsScreen(
    WidgetTester tester,
    GameUIConfig config,
  ) async {
    // Wait for results screen to render
    await tester.pump();
    await tester.pump();

    // Verify results screen buttons present
    expect(config.getPlayAgainButton(), findsOneWidget);
    expect(config.getChangeSettingsButton(), findsOneWidget);
    expect(config.getBackToMenuButton(), findsOneWidget);
  }

  /// Click "Play Again" button on results screen
  ///
  /// Example:
  /// ```dart
  /// await UITestHelpers.clickPlayAgain(tester, config);
  /// ```
  static Future<void> clickPlayAgain(
    WidgetTester tester,
    GameUIConfig config,
  ) async {
    final playAgainButton = config.getPlayAgainButton();

    await tester.tap(playAgainButton);
    await PumpSequences.navigation(tester);
  }

  /// Click "Change Settings" button on results screen
  ///
  /// Example:
  /// ```dart
  /// await UITestHelpers.clickChangeSettings(tester, config);
  /// ```
  static Future<void> clickChangeSettings(
    WidgetTester tester,
    GameUIConfig config,
  ) async {
    final changeSettingsButton = config.getChangeSettingsButton();

    await tester.tap(changeSettingsButton);
    await PumpSequences.navigation(tester);
  }

  /// Click "Back to Menu" button on results screen
  ///
  /// Example:
  /// ```dart
  /// await UITestHelpers.clickBackToMenu(tester, config);
  /// ```
  static Future<void> clickBackToMenu(
    WidgetTester tester,
    GameUIConfig config,
  ) async {
    final backToMenuButton = config.getBackToMenuButton();

    await tester.tap(backToMenuButton);
    await PumpSequences.navigation(tester);
  }
}
