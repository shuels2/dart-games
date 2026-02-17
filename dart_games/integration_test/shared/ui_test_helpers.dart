import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/main.dart' as app;
import 'game_ui_config.dart';
import 'element_finders.dart';
import 'pump_sequences.dart';
import 'settings_helpers.dart';
import 'provider_helpers.dart';

/// High-level UI navigation and interaction helpers
///
/// Provides game-agnostic test helpers that work with any game configuration.
/// All operations use widget keys for reliable element finding.
class UITestHelpers {
  // ==========================================================================
  // NAVIGATION HELPERS
  // ==========================================================================

  /// Navigate from home screen to game menu
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
    await tester.pump(const Duration(seconds: 2));
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
  static Future<void> addPlayer(
    WidgetTester tester,
    String name,
    GameUIConfig config,
  ) async {
    // Try to find the add player button (handles both empty state and normal state)
    Finder addButton;
    if (config.gameName == 'Target Tag') {
      // For Target Tag, check which button exists (empty state or normal state)
      final emptyStateButton = ElementFinders.getTargetTagAddPlayerButtonEmptyState();
      final normalStateButton = ElementFinders.getTargetTagAddPlayerButton();

      if (emptyStateButton.evaluate().isNotEmpty) {
        addButton = emptyStateButton;
      } else {
        addButton = normalStateButton;
      }
    } else if (config.gameName == 'Carnival Derby') {
      // For Carnival Derby, check which button exists (empty state or normal state)
      final emptyStateButton = ElementFinders.getCarnivalDerbyAddPlayerButtonEmptyState();
      final normalStateButton = ElementFinders.getCarnivalDerbyAddPlayerButton();

      if (emptyStateButton.evaluate().isNotEmpty) {
        addButton = emptyStateButton;
      } else {
        addButton = normalStateButton;
      }
    } else {
      // For other games, use the config method
      addButton = config.getAddPlayerButton();
    }

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
  static Future<void> throwDart(
    WidgetTester tester,
    GameUIConfig config,
    int number, {
    String multiplier = 'single',
  }) async {
    final dartButton = config.getDartButton(multiplier, number);

    // DEBUG: Print dartboard state
    print('[DEBUG] throwDart: Looking for $multiplier $number');
    print('[DEBUG] throwDart: Found ${dartButton.evaluate().length} matching buttons');

    final dartboardProvider = ProviderHelpers.getDartboardProvider(tester);
    print('[DEBUG] throwDart: isConnected = ${dartboardProvider.isConnected}');

    // Wait for dartboard buttons to render (poll up to 10 seconds)
    int attempts = 0;
    while (dartButton.evaluate().isEmpty && attempts < 20) {
      print('[DEBUG] throwDart: Waiting for button (attempt ${attempts + 1}/20)...');
      await tester.pump(const Duration(milliseconds: 500));
      attempts++;
    }

    if (dartButton.evaluate().isEmpty) {
      print('[DEBUG] throwDart: ERROR - Button still not found after 10 seconds!');
      print('[DEBUG] throwDart: Dumping all dart buttons on screen:');
      final allDartButtons = find.byWidgetPredicate((widget) =>
        widget.key?.toString().contains('dart_') ?? false
      );
      print('[DEBUG] throwDart: Found ${allDartButtons.evaluate().length} dart buttons total');
      throw TestFailure(
        'Dartboard button for $multiplier $number not found after 10 seconds. '
        'isConnected=${dartboardProvider.isConnected}, '
        'buttons found=${dartButton.evaluate().length}'
      );
    }

    print('[DEBUG] throwDart: Button found! Tapping...');
    await tester.ensureVisible(dartButton);
    await tester.pump();
    await tester.tap(dartButton);
    await PumpSequences.simpleUpdate(tester);
    print('[DEBUG] throwDart: Tap complete');
  }

  /// Throw bullseye (50 points)
  static Future<void> throwBullseye(
    WidgetTester tester,
    GameUIConfig config,
  ) async {
    final bullButton = config.getBullseyeButton();

    print('[DEBUG] throwBullseye: Looking for bullseye button');
    print('[DEBUG] throwBullseye: Found ${bullButton.evaluate().length} matching buttons');

    // Wait for dartboard buttons to render (poll up to 10 seconds)
    int attempts = 0;
    while (bullButton.evaluate().isEmpty && attempts < 20) {
      await tester.pump(const Duration(milliseconds: 500));
      attempts++;
    }

    if (bullButton.evaluate().isEmpty) {
      print('[DEBUG] throwBullseye: ERROR - Bullseye button not found after 10 seconds!');
      throw TestFailure('Bullseye button not found after 10 seconds');
    }

    await tester.ensureVisible(bullButton);
    await tester.pump();
    await tester.tap(bullButton);
    await PumpSequences.simpleUpdate(tester);
  }

  /// Throw outer bull (25 points)
  static Future<void> throwOuterBull(
    WidgetTester tester,
    GameUIConfig config,
  ) async {
    final outerBullButton = config.getOuterBullButton();

    print('[DEBUG] throwOuterBull: Looking for outer bull button');
    print('[DEBUG] throwOuterBull: Found ${outerBullButton.evaluate().length} matching buttons');

    // Wait for dartboard buttons to render (poll up to 10 seconds)
    int attempts = 0;
    while (outerBullButton.evaluate().isEmpty && attempts < 20) {
      await tester.pump(const Duration(milliseconds: 500));
      attempts++;
    }

    if (outerBullButton.evaluate().isEmpty) {
      print('[DEBUG] throwOuterBull: ERROR - Outer bull button not found after 10 seconds!');
      throw TestFailure('Outer bull button not found after 10 seconds');
    }

    await tester.ensureVisible(outerBullButton);
    await tester.pump();
    await tester.tap(outerBullButton);
    await PumpSequences.simpleUpdate(tester);
  }

  /// Throw miss (0 points)
  static Future<void> throwMiss(
    WidgetTester tester,
    GameUIConfig config,
  ) async {
    final missButton = config.getMissButton();

    print('[DEBUG] throwMiss: Looking for miss button');
    print('[DEBUG] throwMiss: Found ${missButton.evaluate().length} matching buttons');

    // Wait for dartboard buttons to render (poll up to 10 seconds)
    int attempts = 0;
    while (missButton.evaluate().isEmpty && attempts < 20) {
      await tester.pump(const Duration(milliseconds: 500));
      attempts++;
    }

    if (missButton.evaluate().isEmpty) {
      print('[DEBUG] throwMiss: ERROR - Miss button not found after 10 seconds!');
      throw TestFailure('Miss button not found after 10 seconds');
    }

    await tester.ensureVisible(missButton);
    await tester.pump();
    await tester.tap(missButton);
    await PumpSequences.simpleUpdate(tester);
  }

  // ==========================================================================
  // GAME CONTROL HELPERS
  // ==========================================================================

  /// Click "Skip Turn" button
  static Future<void> clickSkipTurn(
    WidgetTester tester,
    GameUIConfig config,
  ) async {
    final skipButton = config.getSkipTurnButton();
    await tester.tap(skipButton);
    await PumpSequences.simpleUpdate(tester);
  }

  // ==========================================================================
  // COMPLETE GAME FLOW HELPERS
  // ==========================================================================

  /// Play a complete game with specified dart sequence
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

  /// Verify results screen is showing
  static Future<void> verifyResultsScreen(
    WidgetTester tester,
    GameUIConfig config,
  ) async {
    await tester.pump();
    await tester.pump();
    expect(config.getPlayAgainButton(), findsOneWidget);
    expect(config.getChangeSettingsButton(), findsOneWidget);
    expect(config.getBackToMenuButton(), findsOneWidget);
  }

  /// Click "Play Again" button on results screen
  static Future<void> clickPlayAgain(
    WidgetTester tester,
    GameUIConfig config,
  ) async {
    final playAgainButton = config.getPlayAgainButton();
    await tester.tap(playAgainButton);
    await PumpSequences.navigation(tester);
  }

  /// Click "Change Settings" button on results screen
  static Future<void> clickChangeSettings(
    WidgetTester tester,
    GameUIConfig config,
  ) async {
    final changeSettingsButton = config.getChangeSettingsButton();
    await tester.tap(changeSettingsButton);
    await PumpSequences.navigation(tester);
  }

  /// Click "Back to Menu" button on results screen
  static Future<void> clickBackToMenu(
    WidgetTester tester,
    GameUIConfig config,
  ) async {
    final backToMenuButton = config.getBackToMenuButton();
    await tester.tap(backToMenuButton);
    await PumpSequences.navigation(tester);
  }
}
