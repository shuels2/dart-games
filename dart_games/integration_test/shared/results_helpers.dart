import 'package:flutter_test/flutter_test.dart';
import 'pump_sequences.dart';
import 'game_ui_config.dart';

/// Helpers for interacting with results screens
class ResultsHelpers {
  // ==========================================================================
  // NAVIGATION ACTIONS
  // ==========================================================================

  /// Click Play Again button
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

  static Future<void> clickBackToMenu(
    WidgetTester tester,
    GameUIConfig config,
  ) async {
    await clickSelectDifferentGame(tester, config);
  }

  // ==========================================================================
  // VERIFICATION HELPERS
  // ==========================================================================

  static void verifyWinnerDisplayed(String winnerName) {
    expect(find.text('WINNER!'), findsOneWidget,
        reason: 'Results screen should show WINNER! text');
    expect(find.textContaining(winnerName), findsWidgets,
        reason: 'Results screen should show winner name: $winnerName');
  }

  static void verifyFinalScore(String scoreText) {
    expect(find.textContaining(scoreText), findsWidgets,
        reason: 'Results screen should show final score: $scoreText');
  }

  static void verifyResultsButtons(GameUIConfig config) {
    expect(config.getPlayAgainButton(), findsOneWidget,
        reason: 'Play Again button should be present');
    expect(config.getChangeSettingsButton(), findsOneWidget,
        reason: 'Change Settings button should be present');
    expect(config.getBackToMenuButton(), findsOneWidget,
        reason: 'Back to Menu button should be present');
  }

  static void verifyResultsScreenComplete(
    GameUIConfig config,
    String winnerName,
  ) {
    verifyWinnerDisplayed(winnerName);
    verifyResultsButtons(config);
  }

  static void verifyResultsScreenVisible(GameUIConfig config) {
    expect(config.getPlayAgainButton(), findsOneWidget,
        reason: 'Results screen should be visible (Play Again button present)');
  }

  // ==========================================================================
  // TEAM GAME VERIFICATION
  // ==========================================================================

  static void verifyTeamVictory(String teamName) {
    expect(find.text('WINNER!'), findsOneWidget);
    expect(find.textContaining(teamName), findsWidgets,
        reason: 'Results screen should show winning team name: $teamName');
  }

  static void verifyMultipleWinners(List<String> winnerNames) {
    expect(find.text('WINNER!'), findsOneWidget);
    for (final name in winnerNames) {
      expect(find.textContaining(name), findsWidgets,
          reason: 'Results screen should show winner name: $name');
    }
  }

  // ==========================================================================
  // WAIT FOR RESULTS HELPERS
  // ==========================================================================

  static Future<void> waitForResults(WidgetTester tester) async {
    await PumpSequences.fullRebuild(tester);
  }

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

  static void verifyGameDuration(String durationText) {
    expect(find.textContaining(durationText), findsWidgets,
        reason: 'Results screen should show game duration: $durationText');
  }

  static void verifyPlayerStats(String playerName, String statValue) {
    expect(find.textContaining(playerName), findsWidgets,
        reason: 'Results screen should show player name: $playerName');
    expect(find.textContaining(statValue), findsWidgets,
        reason: 'Results screen should show stat value: $statValue');
  }
}
