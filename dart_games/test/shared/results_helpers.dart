import 'package:flutter_test/flutter_test.dart';
import 'pump_sequences.dart';
import 'game_ui_config.dart';

/// Helpers for interacting with results screens
///
/// Provides high-level operations for game results screens using widget keys.
/// All operations are game-agnostic and work with any GameUIConfig.
class ResultsHelpers {
  // ==========================================================================
  // NAVIGATION ACTIONS
  // ==========================================================================

  /// Click Play Again button
  ///
  /// Taps the play again button and waits for navigation to menu screen.
  /// Verifies the button is present before clicking.
  ///
  /// Example:
  /// ```dart
  /// final config = GameUIConfig.targetTag();
  /// await ResultsHelpers.clickPlayAgain(tester, config);
  /// ```
  static Future<void> clickPlayAgain(
    WidgetTester tester,
    GameUIConfig config,
  ) async {
    final playAgainButton = config.getPlayAgainButton();

    expect(playAgainButton, findsOneWidget,
        reason: 'Play Again button should be present on results screen');

    await tester.tap(playAgainButton);
    await PumpSequences.navigation(tester);
  }

  /// Click Change Settings button
  ///
  /// Taps the change settings button and waits for navigation to menu screen.
  /// Ensures button is visible before tapping.
  ///
  /// Example:
  /// ```dart
  /// await ResultsHelpers.clickChangeSettings(tester, config);
  /// ```
  static Future<void> clickChangeSettings(
    WidgetTester tester,
    GameUIConfig config,
  ) async {
    final changeSettingsButton = config.getChangeSettingsButton();

    expect(changeSettingsButton, findsOneWidget,
        reason: 'Change Settings button should be present on results screen');

    await tester.ensureVisible(changeSettingsButton);
    await tester.pump();

    await tester.tap(changeSettingsButton);
    await PumpSequences.navigation(tester);
  }

  /// Click Select Different Game button (return to home)
  ///
  /// Taps the back to menu button and waits for navigation to home screen.
  ///
  /// Example:
  /// ```dart
  /// await ResultsHelpers.clickSelectDifferentGame(tester, config);
  /// ```
  static Future<void> clickSelectDifferentGame(
    WidgetTester tester,
    GameUIConfig config,
  ) async {
    final backToMenuButton = config.getBackToMenuButton();

    expect(backToMenuButton, findsOneWidget,
        reason: 'Back to Menu button should be present on results screen');

    await tester.tap(backToMenuButton);
    await PumpSequences.navigation(tester);
  }

  /// Alias for clickSelectDifferentGame for clarity
  ///
  /// Example:
  /// ```dart
  /// await ResultsHelpers.clickBackToMenu(tester, config);
  /// ```
  static Future<void> clickBackToMenu(
    WidgetTester tester,
    GameUIConfig config,
  ) async {
    await clickSelectDifferentGame(tester, config);
  }

  // ==========================================================================
  // VERIFICATION HELPERS
  // ==========================================================================

  /// Verify results screen displays winner
  ///
  /// Checks that the winner text and winner name are displayed.
  /// Works for both solo and team game results.
  ///
  /// Example:
  /// ```dart
  /// ResultsHelpers.verifyWinnerDisplayed('Alice');
  /// ```
  static void verifyWinnerDisplayed(String winnerName) {
    expect(find.text('WINNER!'), findsOneWidget,
        reason: 'Results screen should show WINNER! text');

    expect(find.textContaining(winnerName), findsWidgets,
        reason: 'Results screen should show winner name: $winnerName');
  }

  /// Verify final score is displayed
  ///
  /// Checks that the final score text is present on the results screen.
  /// This can be used for games that show numeric scores or shield counts.
  ///
  /// Example:
  /// ```dart
  /// ResultsHelpers.verifyFinalScore('501');
  /// ResultsHelpers.verifyFinalScore('10 shields');
  /// ```
  static void verifyFinalScore(String scoreText) {
    expect(find.textContaining(scoreText), findsWidgets,
        reason: 'Results screen should show final score: $scoreText');
  }

  /// Verify all three result screen buttons are present
  ///
  /// Checks for Play Again, Change Settings, and Back to Menu buttons.
  ///
  /// Example:
  /// ```dart
  /// final config = GameUIConfig.targetTag();
  /// ResultsHelpers.verifyResultsButtons(config);
  /// ```
  static void verifyResultsButtons(GameUIConfig config) {
    final playAgainButton = config.getPlayAgainButton();
    expect(playAgainButton, findsOneWidget,
        reason: 'Play Again button should be present on results screen');

    final changeSettingsButton = config.getChangeSettingsButton();
    expect(changeSettingsButton, findsOneWidget,
        reason: 'Change Settings button should be present on results screen');

    final backToMenuButton = config.getBackToMenuButton();
    expect(backToMenuButton, findsOneWidget,
        reason: 'Back to Menu button should be present on results screen');
  }

  /// Verify complete results screen content
  ///
  /// Checks that winner is displayed and all buttons are present.
  /// This is a comprehensive verification for results screen state.
  ///
  /// Example:
  /// ```dart
  /// ResultsHelpers.verifyResultsScreenComplete(config, 'Alice');
  /// ```
  static void verifyResultsScreenComplete(
    GameUIConfig config,
    String winnerName,
  ) {
    verifyWinnerDisplayed(winnerName);
    verifyResultsButtons(config);
  }

  /// Verify results screen is visible
  ///
  /// Checks that at least one of the results screen buttons is present.
  /// This is a minimal check to confirm we're on the results screen.
  ///
  /// Example:
  /// ```dart
  /// ResultsHelpers.verifyResultsScreenVisible(config);
  /// ```
  static void verifyResultsScreenVisible(GameUIConfig config) {
    final playAgainButton = config.getPlayAgainButton();
    expect(playAgainButton, findsOneWidget,
        reason: 'Results screen should be visible (Play Again button present)');
  }

  // ==========================================================================
  // TEAM GAME VERIFICATION
  // ==========================================================================

  /// Verify team victory is displayed
  ///
  /// For team-based games, verifies that the winning team is shown.
  ///
  /// Example:
  /// ```dart
  /// ResultsHelpers.verifyTeamVictory('Red Team');
  /// ```
  static void verifyTeamVictory(String teamName) {
    expect(find.text('WINNER!'), findsOneWidget,
        reason: 'Results screen should show WINNER! text for team victory');

    expect(find.textContaining(teamName), findsWidgets,
        reason: 'Results screen should show winning team name: $teamName');
  }

  /// Verify multiple winners are displayed (team mode)
  ///
  /// For team games, checks that all winning team members are listed.
  ///
  /// Example:
  /// ```dart
  /// ResultsHelpers.verifyMultipleWinners(['Alice', 'Bob']);
  /// ```
  static void verifyMultipleWinners(List<String> winnerNames) {
    expect(find.text('WINNER!'), findsOneWidget,
        reason: 'Results screen should show WINNER! text');

    for (final name in winnerNames) {
      expect(find.textContaining(name), findsWidgets,
          reason: 'Results screen should show winner name: $name');
    }
  }

  // ==========================================================================
  // WAIT FOR RESULTS HELPERS
  // ==========================================================================

  /// Wait for results screen to render
  ///
  /// Pumps frames to allow results screen to fully render after game completion.
  /// Use this after the final dart throw in a game.
  ///
  /// Example:
  /// ```dart
  /// await UITestHelpers.throwDart(tester, config, 20, multiplier: 'double');
  /// await ResultsHelpers.waitForResults(tester);
  /// ```
  static Future<void> waitForResults(WidgetTester tester) async {
    await PumpSequences.fullRebuild(tester);
  }

  /// Wait for results screen and verify it's visible
  ///
  /// Combines waiting for results screen to render with verification.
  ///
  /// Example:
  /// ```dart
  /// await ResultsHelpers.waitAndVerifyResults(tester, config);
  /// ```
  static Future<void> waitAndVerifyResults(
    WidgetTester tester,
    GameUIConfig config,
  ) async {
    await waitForResults(tester);
    verifyResultsScreenVisible(config);
  }

  // ==========================================================================
  // GAME STAT VERIFICATION
  // ==========================================================================

  /// Verify game duration is displayed
  ///
  /// Checks that the game duration text is present on results screen.
  /// Format may vary by game (e.g., "2:34", "2m 34s").
  ///
  /// Example:
  /// ```dart
  /// ResultsHelpers.verifyGameDuration('2:34');
  /// ```
  static void verifyGameDuration(String durationText) {
    expect(find.textContaining(durationText), findsWidgets,
        reason: 'Results screen should show game duration: $durationText');
  }

  /// Verify player stats are displayed
  ///
  /// Checks that player statistics are shown on the results screen.
  /// This can include scores, accuracy, or other game-specific stats.
  ///
  /// Example:
  /// ```dart
  /// ResultsHelpers.verifyPlayerStats('Alice', '180');
  /// ```
  static void verifyPlayerStats(String playerName, String statValue) {
    expect(find.textContaining(playerName), findsWidgets,
        reason: 'Results screen should show player name: $playerName');
    expect(find.textContaining(statValue), findsWidgets,
        reason: 'Results screen should show stat value: $statValue');
  }
}
