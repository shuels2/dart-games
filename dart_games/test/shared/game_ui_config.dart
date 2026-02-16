import 'package:flutter_test/flutter_test.dart';
import 'element_finders.dart';

/// Configuration for game-specific UI elements and operations
///
/// Provides game-specific finder methods and operations using widget keys.
/// Use factory constructors to get pre-configured instances for each game.
class GameUIConfig {
  final String gameName;
  final Finder Function() _getGameCard;
  final Finder Function() _getAddPlayerButton;
  final Finder Function(String) _getPlayerTile;
  final Finder Function() _getStartButton;
  final Finder Function() _getSkipTurnButton;
  final Finder Function() _getEditScoreButton;
  final Finder Function(String, int) _getDartButton;
  final Finder Function() _getBullseyeButton;
  final Finder Function() _getOuterBullButton;
  final Finder Function() _getMissButton;
  final Finder Function() _getPlayAgainButton;
  final Finder Function() _getChangeSettingsButton;
  final Finder Function() _getBackToMenuButton;

  const GameUIConfig._({
    required this.gameName,
    required Finder Function() getGameCard,
    required Finder Function() getAddPlayerButton,
    required Finder Function(String) getPlayerTile,
    required Finder Function() getStartButton,
    required Finder Function() getSkipTurnButton,
    required Finder Function() getEditScoreButton,
    required Finder Function(String, int) getDartButton,
    required Finder Function() getBullseyeButton,
    required Finder Function() getOuterBullButton,
    required Finder Function() getMissButton,
    required Finder Function() getPlayAgainButton,
    required Finder Function() getChangeSettingsButton,
    required Finder Function() getBackToMenuButton,
  })  : _getGameCard = getGameCard,
        _getAddPlayerButton = getAddPlayerButton,
        _getPlayerTile = getPlayerTile,
        _getStartButton = getStartButton,
        _getSkipTurnButton = getSkipTurnButton,
        _getEditScoreButton = getEditScoreButton,
        _getDartButton = getDartButton,
        _getBullseyeButton = getBullseyeButton,
        _getOuterBullButton = getOuterBullButton,
        _getMissButton = getMissButton,
        _getPlayAgainButton = getPlayAgainButton,
        _getChangeSettingsButton = getChangeSettingsButton,
        _getBackToMenuButton = getBackToMenuButton;

  /// Target Tag game configuration
  factory GameUIConfig.targetTag() {
    return GameUIConfig._(
      gameName: 'Target Tag',
      getGameCard: ElementFinders.getTargetTagCard,
      getAddPlayerButton: ElementFinders.getTargetTagAddPlayerButton,
      getPlayerTile: ElementFinders.getTargetTagPlayerTile,
      getStartButton: ElementFinders.getTargetTagStartButton,
      getSkipTurnButton: ElementFinders.getTargetTagSkipTurnButton,
      getEditScoreButton: ElementFinders.getTargetTagEditScoreButton,
      getDartButton: ElementFinders.getTargetTagDartButton,
      getBullseyeButton: ElementFinders.getTargetTagBullseyeButton,
      getOuterBullButton: ElementFinders.getTargetTagOuterBullButton,
      getMissButton: ElementFinders.getTargetTagMissButton,
      getPlayAgainButton: ElementFinders.getTargetTagPlayAgainButton,
      getChangeSettingsButton: ElementFinders.getTargetTagChangeSettingsButton,
      getBackToMenuButton: ElementFinders.getTargetTagBackToMenuButton,
    );
  }

  /// Carnival Derby game configuration
  factory GameUIConfig.carnivalDerby() {
    return GameUIConfig._(
      gameName: 'Carnival Derby',
      getGameCard: ElementFinders.getCarnivalDerbyCard,
      getAddPlayerButton: ElementFinders.getCarnivalDerbyAddPlayerButton,
      getPlayerTile: ElementFinders.getCarnivalDerbyPlayerTile,
      getStartButton: ElementFinders.getCarnivalDerbyStartButton,
      getSkipTurnButton: ElementFinders.getCarnivalDerbySkipTurnButton,
      getEditScoreButton: ElementFinders.getCarnivalDerbyEditScoreButton,
      getDartButton: ElementFinders.getCarnivalDerbyDartButton,
      getBullseyeButton: ElementFinders.getCarnivalDerbyBullseyeButton,
      getOuterBullButton: ElementFinders.getCarnivalDerbyOuterBullButton,
      getMissButton: ElementFinders.getCarnivalDerbyMissButton,
      getPlayAgainButton: ElementFinders.getCarnivalDerbyPlayAgainButton,
      getChangeSettingsButton:
          ElementFinders.getCarnivalDerbyChangeSettingsButton,
      getBackToMenuButton: ElementFinders.getCarnivalDerbyBackToMenuButton,
    );
  }

  // ==========================================================================
  // HOME SCREEN OPERATIONS
  // ==========================================================================

  /// Get the game card finder for this game
  Finder getGameCard() => _getGameCard();

  // ==========================================================================
  // MENU SCREEN OPERATIONS
  // ==========================================================================

  /// Get the add player button finder
  Finder getAddPlayerButton() => _getAddPlayerButton();

  /// Get a player tile finder by player ID
  Finder getPlayerTile(String playerId) => _getPlayerTile(playerId);

  /// Get the start game button finder
  Finder getStartButton() => _getStartButton();

  // ==========================================================================
  // GAME SCREEN OPERATIONS
  // ==========================================================================

  /// Get the skip turn button finder
  Finder getSkipTurnButton() => _getSkipTurnButton();

  /// Get the edit score button finder
  Finder getEditScoreButton() => _getEditScoreButton();

  /// Get a dart button finder by multiplier and number
  ///
  /// Examples:
  /// - getDartButton('single', 20) → S20 button
  /// - getDartButton('double', 20) → D20 button
  /// - getDartButton('triple', 20) → T20 button
  Finder getDartButton(String multiplier, int number) =>
      _getDartButton(multiplier, number);

  /// Get the bullseye button finder
  Finder getBullseyeButton() => _getBullseyeButton();

  /// Get the outer bull button finder
  Finder getOuterBullButton() => _getOuterBullButton();

  /// Get the miss button finder
  Finder getMissButton() => _getMissButton();

  // ==========================================================================
  // RESULTS SCREEN OPERATIONS
  // ==========================================================================

  /// Get the play again button finder
  Finder getPlayAgainButton() => _getPlayAgainButton();

  /// Get the change settings button finder
  Finder getChangeSettingsButton() => _getChangeSettingsButton();

  /// Get the back to menu button finder
  Finder getBackToMenuButton() => _getBackToMenuButton();
}
