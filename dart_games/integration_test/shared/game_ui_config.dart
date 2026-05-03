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
  final Finder Function() _getGameBackButton;

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
    required Finder Function() getGameBackButton,
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
        _getBackToMenuButton = getBackToMenuButton,
        _getGameBackButton = getGameBackButton;

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
      getGameBackButton: ElementFinders.getTargetTagGameBackButton,
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
      getGameBackButton: ElementFinders.getCarnivalDerbyGameBackButton,
    );
  }

  /// Monster Mash game configuration
  factory GameUIConfig.monsterMash() {
    return GameUIConfig._(
      gameName: 'Monster Mash',
      getGameCard: ElementFinders.getMonsterMashCard,
      getAddPlayerButton: ElementFinders.getMonsterMashAddPlayerButton,
      getPlayerTile: ElementFinders.getMonsterMashPlayerTile,
      getStartButton: ElementFinders.getMonsterMashStartButton,
      getSkipTurnButton: ElementFinders.getMonsterMashSkipTurnButton,
      getEditScoreButton: ElementFinders.getMonsterMashEditScoreButton,
      getDartButton: ElementFinders.getMonsterMashDartButton,
      getBullseyeButton: ElementFinders.getMonsterMashBullseyeButton,
      getOuterBullButton: ElementFinders.getMonsterMashOuterBullButton,
      getMissButton: ElementFinders.getMonsterMashMissButton,
      getPlayAgainButton: ElementFinders.getMonsterMashPlayAgainButton,
      getChangeSettingsButton:
          ElementFinders.getMonsterMashChangeSettingsButton,
      getBackToMenuButton: ElementFinders.getMonsterMashBackToMenuButton,
      getGameBackButton: ElementFinders.getMonsterMashGameBackButton,
    );
  }

  /// Reef Royale game configuration
  factory GameUIConfig.reefRoyale() {
    return GameUIConfig._(
      gameName: 'Reef Royale',
      getGameCard: ElementFinders.getReefRoyaleCard,
      getAddPlayerButton: ElementFinders.getReefRoyaleAddPlayerButton,
      getPlayerTile: ElementFinders.getReefRoyalePlayerTile,
      getStartButton: ElementFinders.getReefRoyaleStartButton,
      getSkipTurnButton: ElementFinders.getReefRoyaleSkipTurnButton,
      getEditScoreButton: ElementFinders.getReefRoyaleEditScoreButton,
      getDartButton: ElementFinders.getReefRoyaleDartButton,
      getBullseyeButton: ElementFinders.getReefRoyaleBullseyeButton,
      getOuterBullButton: ElementFinders.getReefRoyaleOuterBullButton,
      getMissButton: ElementFinders.getReefRoyaleMissButton,
      getPlayAgainButton: ElementFinders.getReefRoyalePlayAgainButton,
      getChangeSettingsButton:
          ElementFinders.getReefRoyaleChangeSettingsButton,
      getBackToMenuButton: ElementFinders.getReefRoyaleBackToMenuButton,
      getGameBackButton: ElementFinders.getReefRoyaleGameBackButton,
    );
  }

  /// Lunar Lander game configuration
  factory GameUIConfig.lunarLander() {
    return GameUIConfig._(
      gameName: 'Lunar Lander',
      getGameCard: ElementFinders.getLunarLanderCard,
      getAddPlayerButton: ElementFinders.getLunarLanderAddPlayerButton,
      getPlayerTile: ElementFinders.getLunarLanderPlayerTile,
      getStartButton: ElementFinders.getLunarLanderStartButton,
      getSkipTurnButton: ElementFinders.getLunarLanderSkipTurnButton,
      getEditScoreButton: ElementFinders.getLunarLanderEditScoreButton,
      getDartButton: (multiplier, number) => find.text('Not used in Lunar Lander directly'),
      getBullseyeButton: () => find.text('Not used in Lunar Lander directly'),
      getOuterBullButton: () => find.text('Not used in Lunar Lander directly'),
      getMissButton: () => find.text('Not used in Lunar Lander directly'),
      getPlayAgainButton: ElementFinders.getLunarLanderPlayAgainButton,
      getChangeSettingsButton: ElementFinders.getLunarLanderChangeSettingsButton,
      getBackToMenuButton: ElementFinders.getLunarLanderBackToMenuButton,
      getGameBackButton: ElementFinders.getLunarLanderGameBackButton,
    );
  }

  /// Clockwork Quest game configuration
  factory GameUIConfig.clockworkQuest() {
    return GameUIConfig._(
      gameName: 'Clockwork Quest',
      getGameCard: ElementFinders.getClockworkQuestCard,
      getAddPlayerButton: ElementFinders.getClockworkQuestAddPlayerButton,
      getPlayerTile: ElementFinders.getClockworkQuestPlayerTile,
      getStartButton: ElementFinders.getClockworkQuestStartButton,
      getSkipTurnButton: ElementFinders.getClockworkQuestSkipTurnButton,
      getEditScoreButton: ElementFinders.getClockworkQuestEditScoreButton,
      getDartButton: (multiplier, number) => find.text('Not used in Clockwork Quest'),
      getBullseyeButton: () => find.text('Not used in Clockwork Quest'),
      getOuterBullButton: () => find.text('Not used in Clockwork Quest'),
      getMissButton: () => find.text('Not used in Clockwork Quest'),
      getPlayAgainButton: ElementFinders.getClockworkQuestPlayAgainButton,
      getChangeSettingsButton:
          ElementFinders.getClockworkQuestChangeSettingsButton,
      getBackToMenuButton: ElementFinders.getClockworkQuestBackToMenuButton,
      getGameBackButton: ElementFinders.getClockworkQuestGameBackButton,
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

  /// Get the game screen back button finder
  Finder getGameBackButton() => _getGameBackButton();

  /// Get the skip turn button finder
  Finder getSkipTurnButton() => _getSkipTurnButton();

  /// Get the edit score button finder
  Finder getEditScoreButton() => _getEditScoreButton();

  /// Get a dart button finder by multiplier and number
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
