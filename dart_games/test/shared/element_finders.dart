import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/constants/test_keys.dart';

/// Shared element finding helpers using widget keys
///
/// ALL finding uses keys (never text/type/index) for reliability.
class ElementFinders {
  // ==========================================================================
  // HOME SCREEN FINDERS
  // ==========================================================================

  static Finder getCarnivalDerbyCard() {
    return find.byKey(HomeKeys.carnivalDerbyCard);
  }

  static Finder getTargetTagCard() {
    return find.byKey(HomeKeys.targetTagCard);
  }

  // ==========================================================================
  // CARNIVAL DERBY MENU FINDERS
  // ==========================================================================

  static Finder getCarnivalDerbyBackButton() {
    return find.byKey(CarnivalDerbyMenuKeys.backButton);
  }

  static Finder getCarnivalDerbyAddPlayerButton() {
    return find.byKey(CarnivalDerbyMenuKeys.addPlayerButton);
  }

  static Finder getCarnivalDerbyAddPlayerButtonEmptyState() {
    return find.byKey(CarnivalDerbyMenuKeys.addPlayerButtonEmptyState);
  }

  static Finder getCarnivalDerbyPlayerTile(String playerId) {
    return find.byKey(CarnivalDerbyMenuKeys.playerTile(playerId));
  }

  static Finder getCarnivalDerbyTargetScoreDropdown() {
    return find.byKey(CarnivalDerbyMenuKeys.targetScoreDropdown);
  }

  static Finder getCarnivalDerbyPerfectFinishToggle() {
    return find.byKey(CarnivalDerbyMenuKeys.perfectFinishSwitch);
  }

  static Finder getCarnivalDerbyStartButton() {
    return find.byKey(CarnivalDerbyMenuKeys.startButton);
  }

  // ==========================================================================
  // CARNIVAL DERBY GAME FINDERS
  // ==========================================================================

  static Finder getCarnivalDerbyGameBackButton() {
    return find.byKey(CarnivalDerbyGameKeys.backButton);
  }

  static Finder getCarnivalDerbySkipTurnButton() {
    return find.byKey(CarnivalDerbyGameKeys.skipTurnButton);
  }

  static Finder getCarnivalDerbyEditScoreButton() {
    return find.byKey(CarnivalDerbyGameKeys.editScoreButton);
  }

  static Finder getCarnivalDerbyDartButton(String multiplier, int number) {
    return find.byKey(CarnivalDerbyGameKeys.getDartKey(multiplier, number));
  }

  static Finder getCarnivalDerbyBullseyeButton() {
    return find.byKey(CarnivalDerbyGameKeys.dartBullseyeButton);
  }

  static Finder getCarnivalDerbyOuterBullButton() {
    return find.byKey(CarnivalDerbyGameKeys.dartOuterBullButton);
  }

  static Finder getCarnivalDerbyMissButton() {
    return find.byKey(CarnivalDerbyGameKeys.dartMissButton);
  }

  // ==========================================================================
  // CARNIVAL DERBY RESULTS FINDERS
  // ==========================================================================

  static Finder getCarnivalDerbyPlayAgainButton() {
    return find.byKey(CarnivalDerbyResultsKeys.playAgainButton);
  }

  static Finder getCarnivalDerbyChangeSettingsButton() {
    return find.byKey(CarnivalDerbyResultsKeys.changeSettingsButton);
  }

  static Finder getCarnivalDerbyBackToMenuButton() {
    return find.byKey(CarnivalDerbyResultsKeys.backToMenuButton);
  }

  // ==========================================================================
  // TARGET TAG MENU FINDERS
  // ==========================================================================

  static Finder getTargetTagBackButton() {
    return find.byKey(TargetTagMenuKeys.backButton);
  }

  static Finder getTargetTagAddPlayerButton() {
    return find.byKey(TargetTagMenuKeys.addPlayerButton);
  }

  static Finder getTargetTagAddPlayerButtonEmptyState() {
    return find.byKey(TargetTagMenuKeys.addPlayerButtonEmptyState);
  }

  static Finder getTargetTagPlayerTile(String playerId) {
    return find.byKey(TargetTagMenuKeys.playerTile(playerId));
  }

  static Finder getTargetTagShieldMaxSlider() {
    return find.byKey(TargetTagMenuKeys.shieldMaxSlider);
  }

  static Finder getTargetTagTeamModeToggle() {
    return find.byKey(TargetTagMenuKeys.teamModeSwitch);
  }

  static Finder getTargetTagHeroBonusToggle() {
    return find.byKey(TargetTagMenuKeys.heroBonusSwitch);
  }

  static Finder getTargetTagAssignTeamsButton() {
    return find.byKey(TargetTagMenuKeys.manualTeamAssignmentSwitch);
  }

  static Finder getTargetTagStartButton() {
    return find.byKey(TargetTagMenuKeys.startButton);
  }

  // ==========================================================================
  // TARGET TAG GAME FINDERS
  // ==========================================================================

  static Finder getTargetTagGameBackButton() {
    return find.byKey(TargetTagGameKeys.backButton);
  }

  static Finder getTargetTagSkipTurnButton() {
    return find.byKey(TargetTagGameKeys.skipTurnButton);
  }

  static Finder getTargetTagEditScoreButton() {
    return find.byKey(TargetTagGameKeys.editScoreButton);
  }

  static Finder getTargetTagDartButton(String multiplier, int number) {
    return find.byKey(TargetTagGameKeys.getDartKey(multiplier, number));
  }

  static Finder getTargetTagBullseyeButton() {
    return find.byKey(TargetTagGameKeys.dartBullseyeButton);
  }

  static Finder getTargetTagOuterBullButton() {
    return find.byKey(TargetTagGameKeys.dartOuterBullButton);
  }

  static Finder getTargetTagMissButton() {
    return find.byKey(TargetTagGameKeys.dartMissButton);
  }

  static Finder getTargetTagD1Indicator() {
    return find.byKey(TargetTagGameKeys.activePlayerD1Indicator);
  }

  static Finder getTargetTagD2Indicator() {
    return find.byKey(TargetTagGameKeys.activePlayerD2Indicator);
  }

  static Finder getTargetTagD3Indicator() {
    return find.byKey(TargetTagGameKeys.activePlayerD3Indicator);
  }

  static Finder getTargetTagActivePlayerName() {
    return find.byKey(TargetTagGameKeys.activePlayerName);
  }

  /// Get the current player's name from the active player panel
  static String? getTargetTagActivePlayerNameText(WidgetTester tester) {
    final nameFinder = getTargetTagActivePlayerName();
    if (nameFinder.evaluate().isEmpty) {
      return null;
    }
    final textWidget = tester.widget<Text>(nameFinder.first);
    return textWidget.data;
  }

  // ==========================================================================
  // TARGET TAG RESULTS FINDERS
  // ==========================================================================

  static Finder getTargetTagPlayAgainButton() {
    return find.byKey(TargetTagResultsKeys.playAgainButton);
  }

  static Finder getTargetTagChangeSettingsButton() {
    return find.byKey(TargetTagResultsKeys.changeSettingsButton);
  }

  static Finder getTargetTagBackToMenuButton() {
    return find.byKey(TargetTagResultsKeys.backToMenuButton);
  }

  // ==========================================================================
  // MONSTER MASH HOME FINDERS
  // ==========================================================================

  static Finder getMonsterMashCard() {
    return find.byKey(HomeKeys.monsterMashCard);
  }

  // ==========================================================================
  // MONSTER MASH MENU FINDERS
  // ==========================================================================

  static Finder getMonsterMashAddPlayerButton() {
    return find.byKey(MonsterMashMenuKeys.addPlayerButton);
  }

  static Finder getMonsterMashAddPlayerButtonEmptyState() {
    return find.byKey(MonsterMashMenuKeys.addPlayerButtonEmptyState);
  }

  static Finder getMonsterMashPlayerTile(String playerId) {
    return find.byKey(MonsterMashMenuKeys.playerTile(playerId));
  }

  static Finder getMonsterMashHealthPointsSlider() {
    return find.byKey(MonsterMashMenuKeys.healthPointsSlider);
  }

  static Finder getMonsterMashBonusBuffsSwitch() {
    return find.byKey(MonsterMashMenuKeys.bonusBuffsSwitch);
  }

  static Finder getMonsterMashSpeedPlaySwitch() {
    return find.byKey(MonsterMashMenuKeys.speedPlaySwitch);
  }

  static Finder getMonsterMashRoundLimitSlider() {
    return find.byKey(MonsterMashMenuKeys.roundLimitSlider);
  }

  static Finder getMonsterMashStartButton() {
    return find.byKey(MonsterMashMenuKeys.startGameButton);
  }

  static Finder getMonsterMashBackButton() {
    return find.byKey(MonsterMashMenuKeys.backButton);
  }

  // ==========================================================================
  // MONSTER MASH GAME FINDERS
  // ==========================================================================

  static Finder getMonsterMashGameBackButton() {
    return find.byKey(MonsterMashGameKeys.backButton);
  }

  static Finder getMonsterMashSkipTurnButton() {
    return find.byKey(MonsterMashGameKeys.skipTurnButton);
  }

  static Finder getMonsterMashEditScoreButton() {
    return find.byKey(MonsterMashGameKeys.editScoreButton);
  }

  static Finder getMonsterMashDartButton(String multiplier, int number) {
    return find.byKey(MonsterMashGameKeys.getDartKey(multiplier, number));
  }

  static Finder getMonsterMashBullseyeButton() {
    return find.byKey(MonsterMashGameKeys.dartBullseyeButton);
  }

  static Finder getMonsterMashOuterBullButton() {
    return find.byKey(MonsterMashGameKeys.dartOuterBullButton);
  }

  static Finder getMonsterMashMissButton() {
    return find.byKey(MonsterMashGameKeys.dartMissButton);
  }

  // ==========================================================================
  // MONSTER MASH RESULTS FINDERS
  // ==========================================================================

  static Finder getMonsterMashPlayAgainButton() {
    return find.byKey(MonsterMashResultsKeys.playAgainButton);
  }

  static Finder getMonsterMashChangeSettingsButton() {
    return find.byKey(MonsterMashResultsKeys.changeSettingsButton);
  }

  static Finder getMonsterMashBackToMenuButton() {
    return find.byKey(MonsterMashResultsKeys.backToMenuButton);
  }

  static Finder getMonsterMashWinnerName() {
    return find.byKey(MonsterMashResultsKeys.winnerName);
  }

  // ==========================================================================
  // REEF ROYALE HOME FINDERS
  // ==========================================================================

  static Finder getReefRoyaleCard() {
    return find.byKey(HomeKeys.reefRoyaleCard);
  }

  // ==========================================================================
  // REEF ROYALE MENU FINDERS
  // ==========================================================================

  static Finder getReefRoyaleAddPlayerButton() {
    return find.byKey(ReefRoyaleMenuKeys.addPlayerButton);
  }

  static Finder getReefRoyaleAddPlayerButtonEmptyState() {
    return find.byKey(ReefRoyaleMenuKeys.addPlayerButtonEmptyState);
  }

  static Finder getReefRoyalePlayerTile(String playerId) {
    return find.byKey(ReefRoyaleMenuKeys.playerTile(playerId));
  }

  static Finder getReefRoyaleGameModeDropdown() {
    return find.byKey(ReefRoyaleMenuKeys.gameModeDropdown);
  }

  static Finder getReefRoyaleEasyClaimSwitch() {
    return find.byKey(ReefRoyaleMenuKeys.easyClaimSwitch);
  }

  static Finder getReefRoyaleNeighborNumbersSwitch() {
    return find.byKey(ReefRoyaleMenuKeys.neighborNumbersSwitch);
  }

  static Finder getReefRoyaleRandomReefsSwitch() {
    return find.byKey(ReefRoyaleMenuKeys.randomReefsSwitch);
  }

  static Finder getReefRoyaleBonusBuffsSwitch() {
    return find.byKey(ReefRoyaleMenuKeys.bonusBuffsSwitch);
  }

  static Finder getReefRoyaleIncludeBullSwitch() {
    return find.byKey(ReefRoyaleMenuKeys.includeBullSwitch);
  }

  static Finder getReefRoyaleSpeedPlaySwitch() {
    return find.byKey(ReefRoyaleMenuKeys.speedPlaySwitch);
  }

  static Finder getReefRoyaleRoundLimitSlider() {
    return find.byKey(ReefRoyaleMenuKeys.roundLimitSlider);
  }

  static Finder getReefRoyaleStartButton() {
    return find.byKey(ReefRoyaleMenuKeys.startGameButton);
  }

  static Finder getReefRoyaleBackButton() {
    return find.byKey(ReefRoyaleMenuKeys.backButton);
  }

  // ==========================================================================
  // REEF ROYALE GAME FINDERS
  // ==========================================================================

  static Finder getReefRoyaleGameBackButton() {
    return find.byKey(ReefRoyaleGameKeys.backButton);
  }

  static Finder getReefRoyaleSkipTurnButton() {
    return find.byKey(ReefRoyaleGameKeys.skipTurnButton);
  }

  static Finder getReefRoyaleEditScoreButton() {
    return find.byKey(ReefRoyaleGameKeys.editScoreButton);
  }

  static Finder getReefRoyaleDartButton(String multiplier, int number) {
    return find.byKey(ReefRoyaleGameKeys.getDartKey(multiplier, number));
  }

  static Finder getReefRoyaleBullseyeButton() {
    return find.byKey(ReefRoyaleGameKeys.dartBullseyeButton);
  }

  static Finder getReefRoyaleOuterBullButton() {
    return find.byKey(ReefRoyaleGameKeys.dartOuterBullButton);
  }

  static Finder getReefRoyaleMissButton() {
    return find.byKey(ReefRoyaleGameKeys.dartMissButton);
  }

  // ==========================================================================
  // REEF ROYALE RESULTS FINDERS
  // ==========================================================================

  static Finder getReefRoyalePlayAgainButton() {
    return find.byKey(ReefRoyaleResultsKeys.playAgainButton);
  }

  static Finder getReefRoyaleChangeSettingsButton() {
    return find.byKey(ReefRoyaleResultsKeys.changeSettingsButton);
  }

  static Finder getReefRoyaleBackToMenuButton() {
    return find.byKey(ReefRoyaleResultsKeys.backToMenuButton);
  }

  static Finder getReefRoyaleWinnerName() {
    return find.byKey(ReefRoyaleResultsKeys.winnerName);
  }

  // ==========================================================================
  // CLOCKWORK QUEST HOME FINDERS
  // ==========================================================================

  static Finder getClockworkQuestCard() {
    return find.byKey(HomeKeys.clockworkQuestCard);
  }

  // ==========================================================================
  // CLOCKWORK QUEST MENU FINDERS
  // ==========================================================================

  static Finder getClockworkQuestAddPlayerButton() {
    return find.byKey(ClockworkQuestMenuKeys.addPlayerButton);
  }

  static Finder getClockworkQuestAddPlayerButtonEmptyState() {
    return find.byKey(ClockworkQuestMenuKeys.addPlayerButtonEmptyState);
  }

  static Finder getClockworkQuestPlayerTile(String playerId) {
    return find.byKey(ClockworkQuestMenuKeys.playerTile(playerId));
  }

  static Finder getClockworkQuestIncludeBullseyeCheckbox() {
    return find.byKey(ClockworkQuestMenuKeys.includeBullseyeCheckbox);
  }

  static Finder getClockworkQuestSpeedModeCheckbox() {
    return find.byKey(ClockworkQuestMenuKeys.speedModeCheckbox);
  }

  static Finder getClockworkQuestNumberOfLapsDropdown() {
    return find.byKey(ClockworkQuestMenuKeys.numberOfLapsDropdown);
  }

  static Finder getClockworkQuestStartButton() {
    return find.byKey(ClockworkQuestMenuKeys.startButton);
  }

  static Finder getClockworkQuestBackButton() {
    return find.byKey(ClockworkQuestMenuKeys.backButton);
  }

  // ==========================================================================
  // CLOCKWORK QUEST GAME FINDERS
  // ==========================================================================

  static Finder getClockworkQuestGameBackButton() {
    return find.byKey(ClockworkQuestGameKeys.backButton);
  }

  static Finder getClockworkQuestSkipTurnButton() {
    return find.byKey(ClockworkQuestGameKeys.skipTurnButton);
  }

  static Finder getClockworkQuestEditScoreButton() {
    return find.byKey(ClockworkQuestGameKeys.editScoreButton);
  }

  // ==========================================================================
  // CLOCKWORK QUEST RESULTS FINDERS
  // ==========================================================================

  static Finder getClockworkQuestPlayAgainButton() {
    return find.byKey(ClockworkQuestResultsKeys.playAgainButton);
  }

  static Finder getClockworkQuestChangeSettingsButton() {
    return find.byKey(ClockworkQuestResultsKeys.changeSettingsButton);
  }

  static Finder getClockworkQuestBackToMenuButton() {
    return find.byKey(ClockworkQuestResultsKeys.backToMenuButton);
  }

  static Finder getClockworkQuestWinnerName() {
    return find.byKey(ClockworkQuestResultsKeys.winnerName);
  }

  // ==========================================================================
  // DIALOG FINDERS
  // ==========================================================================

  static Finder getEditScoreDialog() {
    return find.byKey(EditScoreDialogKeys.dialogContainer);
  }

  static Finder getEditScoreDart1Dropdown() {
    return find.byKey(EditScoreDialogKeys.dart1Dropdown);
  }

  static Finder getEditScoreDart2Dropdown() {
    return find.byKey(EditScoreDialogKeys.dart2Dropdown);
  }

  static Finder getEditScoreDart3Dropdown() {
    return find.byKey(EditScoreDialogKeys.dart3Dropdown);
  }

  static Finder getEditScoreSaveButton() {
    return find.byKey(EditScoreDialogKeys.saveButton);
  }

  static Finder getEditScoreCancelButton() {
    return find.byKey(EditScoreDialogKeys.cancelButton);
  }

  static Finder getAddPlayerDialog() {
    return find.byKey(AddPlayerDialogKeys.dialogContainer);
  }

  static Finder getAddPlayerNameField() {
    return find.byKey(AddPlayerDialogKeys.nameTextField);
  }

  static Finder getAddPlayerAddButton() {
    return find.byKey(AddPlayerDialogKeys.addButton);
  }

  static Finder getAddPlayerCancelButton() {
    return find.byKey(AddPlayerDialogKeys.cancelButton);
  }

  static Finder getAddPlayerCameraButton() {
    return find.byKey(AddPlayerDialogKeys.cameraButton);
  }

  static Finder getAddPlayerGalleryButton() {
    return find.byKey(AddPlayerDialogKeys.galleryButton);
  }

  static Finder getAddPlayerPhotoPreview() {
    return find.byKey(AddPlayerDialogKeys.photoPreview);
  }

  static Finder getAddPlayerRemovePhotoButton() {
    return find.byKey(AddPlayerDialogKeys.removePhotoButton);
  }

  static Finder getTeamAssignmentDialog() {
    return find.byKey(TeamAssignmentDialogKeys.dialogContainer);
  }

  static Finder getTeamAssignmentPlayerDropdown(String playerId) {
    return find.byKey(TeamAssignmentDialogKeys.playerTeamDropdown(playerId));
  }

  static Finder getTeamAssignmentTeamCountDropdown() {
    return find.byKey(TeamAssignmentDialogKeys.teamCountDropdown);
  }

  static Finder getTeamAssignmentSaveButton() {
    return find.byKey(TeamAssignmentDialogKeys.saveButton);
  }

  static Finder getTeamAssignmentCancelButton() {
    return find.byKey(TeamAssignmentDialogKeys.cancelButton);
  }

  // ==========================================================================
  // SAVE GAME MODAL FINDERS
  // ==========================================================================

  static Finder getSaveGameModalOverlay() {
    return find.byKey(SaveGameModalKeys.overlay);
  }

  static Finder getSaveGameModalContainer() {
    return find.byKey(SaveGameModalKeys.container);
  }

  static Finder getSaveGameModalIcon() {
    return find.byKey(SaveGameModalKeys.icon);
  }

  static Finder getSaveGameModalTitle() {
    return find.byKey(SaveGameModalKeys.title);
  }

  static Finder getSaveGameModalMessage() {
    return find.byKey(SaveGameModalKeys.message);
  }

  static Finder getSaveGameModalSaveButton() {
    return find.byKey(SaveGameModalKeys.saveButton);
  }

  static Finder getSaveGameModalDontSaveButton() {
    return find.byKey(SaveGameModalKeys.dontSaveButton);
  }

  // ==========================================================================
  // RESUME GAME MODAL FINDERS
  // ==========================================================================

  static Finder getResumeGameModalOverlay() {
    return find.byKey(ResumeGameModalKeys.overlay);
  }

  static Finder getResumeGameModalContainer() {
    return find.byKey(ResumeGameModalKeys.container);
  }

  static Finder getResumeGameModalTitle() {
    return find.byKey(ResumeGameModalKeys.title);
  }

  static Finder getResumeGameModalSavedGamesList() {
    return find.byKey(ResumeGameModalKeys.savedGamesList);
  }

  static Finder getResumeGameModalSavedGameTile(String id) {
    return find.byKey(ResumeGameModalKeys.savedGameTile(id));
  }

  static Finder getResumeGameModalDeleteButton(String id) {
    return find.byKey(ResumeGameModalKeys.deleteSavedGameButton(id));
  }

  static Finder getResumeGameModalTileDate(String id) {
    return find.byKey(ResumeGameModalKeys.tileDate(id));
  }

  static Finder getResumeGameModalTilePlayers(String id) {
    return find.byKey(ResumeGameModalKeys.tilePlayers(id));
  }

  static Finder getResumeGameModalTileProgress(String id) {
    return find.byKey(ResumeGameModalKeys.tileProgress(id));
  }

  static Finder getResumeGameModalTileMode(String id) {
    return find.byKey(ResumeGameModalKeys.tileMode(id));
  }

  static Finder getResumeGameModalTileLeader(String id) {
    return find.byKey(ResumeGameModalKeys.tileLeader(id));
  }

  static Finder getResumeGameModalResumeButton() {
    return find.byKey(ResumeGameModalKeys.resumeGameButton);
  }

  static Finder getResumeGameModalStartNewButton() {
    return find.byKey(ResumeGameModalKeys.startNewGameButton);
  }

  static Finder getResumeGameModalDeleteAllButton() {
    return find.byKey(ResumeGameModalKeys.deleteAllButton);
  }

  static Finder getResumeGameModalEmptyState() {
    return find.byKey(ResumeGameModalKeys.emptyStateText);
  }

  // ==========================================================================
  // LUNAR LANDER HOME FINDERS
  // ==========================================================================

  static Finder getLunarLanderCard() {
    return find.byKey(HomeKeys.lunarLanderCard);
  }

  // ==========================================================================
  // LUNAR LANDER MENU FINDERS
  // ==========================================================================

  static Finder getLunarLanderBackButton() {
    return find.byKey(LunarLanderMenuKeys.backButton);
  }

  static Finder getLunarLanderAddPlayerButton() {
    return find.byKey(LunarLanderMenuKeys.addPlayerButton);
  }

  static Finder getLunarLanderAddPlayerButtonEmptyState() {
    return find.byKey(LunarLanderMenuKeys.addPlayerButtonEmptyState);
  }

  static Finder getLunarLanderPlayerTile(String playerId) {
    return find.byKey(LunarLanderMenuKeys.playerTile(playerId));
  }

  static Finder getLunarLanderAltitudeSlider() {
    return find.byKey(LunarLanderMenuKeys.altitudeSlider);
  }

  static Finder getLunarLanderHardLandingSwitch() {
    return find.byKey(LunarLanderMenuKeys.hardLandingSwitch);
  }

  static Finder getLunarLanderStartButton() {
    return find.byKey(LunarLanderMenuKeys.startGameButton);
  }

  // ==========================================================================
  // LUNAR LANDER GAME FINDERS
  // ==========================================================================

  static Finder getLunarLanderGameBackButton() {
    return find.byKey(LunarLanderGameKeys.backButton);
  }

  static Finder getLunarLanderSkipTurnButton() {
    return find.byKey(LunarLanderGameKeys.skipTurnButton);
  }

  static Finder getLunarLanderEditScoreButton() {
    return find.byKey(LunarLanderGameKeys.editScoreButton);
  }

  static Finder getLunarLanderHardLandingBadge() {
    return find.byKey(LunarLanderGameKeys.hardLandingBadge);
  }

  static Finder getLunarLanderDescentTrack(String playerId) {
    return find.byKey(LunarLanderGameKeys.descentTrack(playerId));
  }

  // ==========================================================================
  // LUNAR LANDER RESULTS FINDERS
  // ==========================================================================

  static Finder getLunarLanderPlayAgainButton() {
    return find.byKey(LunarLanderResultsKeys.playAgainButton);
  }

  static Finder getLunarLanderChangeSettingsButton() {
    return find.byKey(LunarLanderResultsKeys.changeSettingsButton);
  }

  static Finder getLunarLanderBackToMenuButton() {
    return find.byKey(LunarLanderResultsKeys.backToMenuButton);
  }

  static Finder getLunarLanderWinnerName() {
    return find.byKey(LunarLanderResultsKeys.winnerName);
  }

  // ==========================================================================
  // PIRATE'S GRID HOME FINDERS
  // ==========================================================================

  static Finder getPiratesGridCard() {
    return find.byKey(HomeKeys.piratesGridCard);
  }

  // ==========================================================================
  // PIRATE'S GRID MENU FINDERS
  // ==========================================================================

  static Finder getPiratesGridBackButton() {
    return find.byKey(PiratesGridMenuKeys.backButton);
  }

  static Finder getPiratesGridAddPlayerButton() {
    return find.byKey(PiratesGridMenuKeys.addPlayerButton);
  }

  static Finder getPiratesGridAddPlayerButtonEmptyState() {
    return find.byKey(PiratesGridMenuKeys.addPlayerButtonEmptyState);
  }

  static Finder getPiratesGridPlayerTile(String playerId) {
    return find.byKey(PiratesGridMenuKeys.playerTile(playerId));
  }

  static Finder getPiratesGridDifficultyDropdown() {
    return find.byKey(PiratesGridMenuKeys.difficultyDropdown);
  }

  static Finder getPiratesGridBestOfDropdown() {
    return find.byKey(PiratesGridMenuKeys.bestOfDropdown);
  }

  static Finder getPiratesGridStealModeSwitch() {
    return find.byKey(PiratesGridMenuKeys.stealModeSwitch);
  }

  static Finder getPiratesGridSpeedPlaySwitch() {
    return find.byKey(PiratesGridMenuKeys.speedPlaySwitch);
  }

  static Finder getPiratesGridStartButton() {
    return find.byKey(PiratesGridMenuKeys.startGameButton);
  }

  // ==========================================================================
  // PIRATE'S GRID GAME FINDERS
  // ==========================================================================

  static Finder getPiratesGridGameBackButton() {
    return find.byKey(PiratesGridGameKeys.backButton);
  }

  static Finder getPiratesGridSkipTurnButton() {
    return find.byKey(PiratesGridGameKeys.skipTurnButton);
  }

  static Finder getPiratesGridEditScoreButton() {
    return find.byKey(PiratesGridGameKeys.editScoreButton);
  }

  static Finder getPiratesGridGridCell(int row, int col) {
    return find.byKey(PiratesGridGameKeys.gridCell(row, col));
  }

  static Finder getPiratesGridPlayerAvatarActive() {
    return find.byKey(PiratesGridGameKeys.playerAvatarActive);
  }

  static Finder getPiratesGridPlayerAvatarInactive() {
    return find.byKey(PiratesGridGameKeys.playerAvatarInactive);
  }

  static Finder getPiratesGridFlagsCounter(String playerId) {
    return find.byKey(PiratesGridGameKeys.flagsCounter(playerId));
  }

  static Finder getPiratesGridDartIndicator(int index) {
    return find.byKey(PiratesGridGameKeys.dartIndicator(index));
  }

  static Finder getPiratesGridStealModeBadge() {
    return find.byKey(PiratesGridGameKeys.stealModeBadge);
  }

  static Finder getPiratesGridSpeedPlayTimer() {
    return find.byKey(PiratesGridGameKeys.speedPlayTimer);
  }

  static Finder getPiratesGridRoundTracker() {
    return find.byKey(PiratesGridGameKeys.roundTracker);
  }

  // ==========================================================================
  // PIRATE'S GRID RESULTS FINDERS
  // ==========================================================================

  static Finder getPiratesGridPlayAgainButton() {
    return find.byKey(PiratesGridResultsKeys.playAgainButton);
  }

  static Finder getPiratesGridChangeSettingsButton() {
    return find.byKey(PiratesGridResultsKeys.changeSettingsButton);
  }

  static Finder getPiratesGridBackToMenuButton() {
    return find.byKey(PiratesGridResultsKeys.backToMenuButton);
  }

  static Finder getPiratesGridWinnerName() {
    return find.byKey(PiratesGridResultsKeys.winnerName);
  }

  static Finder getPiratesGridHeadlineText() {
    return find.byKey(PiratesGridResultsKeys.headlineText);
  }

  // ==========================================================================
  // GLADIATOR ARENA HOME FINDERS
  // ==========================================================================

  static Finder getGladiatorArenaCard() {
    return find.byKey(HomeKeys.gladiatorArenaCard);
  }

  // ==========================================================================
  // GLADIATOR ARENA MENU FINDERS
  // ==========================================================================

  static Finder getGladiatorArenaBackButton() {
    return find.byKey(GladiatorArenaMenuKeys.backButton);
  }

  static Finder getGladiatorArenaAddPlayerButton() {
    return find.byKey(GladiatorArenaMenuKeys.addPlayerButton);
  }

  static Finder getGladiatorArenaAddPlayerButtonEmptyState() {
    return find.byKey(GladiatorArenaMenuKeys.addPlayerButtonEmptyState);
  }

  static Finder getGladiatorArenaPlayerTile(String playerId) {
    return find.byKey(GladiatorArenaMenuKeys.playerTile(playerId));
  }

  static Finder getGladiatorArenaTargetScoreSlider() {
    return find.byKey(GladiatorArenaMenuKeys.targetScoreSlider);
  }

  static Finder getGladiatorArenaTargetScoreValue() {
    return find.byKey(GladiatorArenaMenuKeys.targetScoreValue);
  }

  static Finder getGladiatorArenaDoubleFinishSwitch() {
    return find.byKey(GladiatorArenaMenuKeys.doubleFinishSwitch);
  }

  static Finder getGladiatorArenaShieldRoundSwitch() {
    return find.byKey(GladiatorArenaMenuKeys.shieldRoundSwitch);
  }

  static Finder getGladiatorArenaSpeedPlaySwitch() {
    return find.byKey(GladiatorArenaMenuKeys.speedPlaySwitch);
  }

  static Finder getGladiatorArenaStartButton() {
    return find.byKey(GladiatorArenaMenuKeys.startGameButton);
  }

  // ==========================================================================
  // GLADIATOR ARENA GAME FINDERS
  // ==========================================================================

  static Finder getGladiatorArenaGameBackButton() {
    return find.byKey(GladiatorArenaGameKeys.backButton);
  }

  static Finder getGladiatorArenaSkipTurnButton() {
    return find.byKey(GladiatorArenaGameKeys.skipTurnButton);
  }

  static Finder getGladiatorArenaEditScoreButton() {
    return find.byKey(GladiatorArenaGameKeys.editScoreButton);
  }

  static Finder getGladiatorArenaGoalDisplay() {
    return find.byKey(GladiatorArenaGameKeys.goalDisplay);
  }

  static Finder getGladiatorArenaDoubleRangeIndicator() {
    return find.byKey(GladiatorArenaGameKeys.doubleRangeIndicator);
  }

  static Finder getGladiatorArenaTimerDisplay() {
    return find.byKey(GladiatorArenaGameKeys.timerDisplay);
  }

  static Finder getGladiatorArenaShieldBanner() {
    return find.byKey(GladiatorArenaGameKeys.shieldBanner);
  }

  static Finder getGladiatorArenaEliminationZone() {
    return find.byKey(GladiatorArenaGameKeys.eliminationZone);
  }

  static Finder getGladiatorArenaDoubleBadge() {
    return find.byKey(GladiatorArenaGameKeys.doubleBadge);
  }

  static Finder getGladiatorArenaActivePlayerNameLabel() {
    return find.byKey(GladiatorArenaGameKeys.activePlayerNameLabel);
  }

  static Finder getGladiatorArenaDartIndicator(int index) {
    return find.byKey(GladiatorArenaGameKeys.dartIndicator(index));
  }

  static Finder getGladiatorArenaPodium(String playerId) {
    return find.byKey(GladiatorArenaGameKeys.podium(playerId));
  }

  // ==========================================================================
  // GLADIATOR ARENA RESULTS FINDERS
  // ==========================================================================

  static Finder getGladiatorArenaPlayAgainButton() {
    return find.byKey(GladiatorArenaResultsKeys.playAgainButton);
  }

  static Finder getGladiatorArenaChangeSettingsButton() {
    return find.byKey(GladiatorArenaResultsKeys.changeSettingsButton);
  }

  static Finder getGladiatorArenaBackToMenuButton() {
    return find.byKey(GladiatorArenaResultsKeys.backToMenuButton);
  }

  static Finder getGladiatorArenaWinnerName() {
    return find.byKey(GladiatorArenaResultsKeys.winnerName);
  }

  static Finder getGladiatorArenaRankingsList() {
    return find.byKey(GladiatorArenaResultsKeys.rankingsList);
  }

  static Finder getGladiatorArenaRankRow(int index) {
    return find.byKey(GladiatorArenaResultsKeys.rankRow(index));
  }

  static Finder getGladiatorArenaKnockoffStats() {
    return find.byKey(GladiatorArenaResultsKeys.knockoffStats);
  }

  // ==========================================================================
  // TIKI GOLF HOME FINDERS
  // ==========================================================================

  static Finder getTikiGolfCard() {
    return find.byKey(HomeKeys.tikiGolfCard);
  }

  // ==========================================================================
  // TIKI GOLF MENU FINDERS
  // ==========================================================================

  static Finder getTikiGolfBackButton() {
    return find.byKey(TikiGolfMenuKeys.backButton);
  }

  static Finder getTikiGolfAddPlayerButton() {
    return find.byKey(TikiGolfMenuKeys.addPlayerButton);
  }

  static Finder getTikiGolfAddPlayerButtonEmptyState() {
    return find.byKey(TikiGolfMenuKeys.addPlayerButtonEmptyState);
  }

  static Finder getTikiGolfPlayerTile(String playerId) {
    return find.byKey(TikiGolfMenuKeys.playerTile(playerId));
  }

  static Finder getTikiGolfGameModeToggle() {
    return find.byKey(TikiGolfMenuKeys.gameModeToggle);
  }

  static Finder getTikiGolfGameModeSolo() {
    return find.byKey(TikiGolfMenuKeys.gameModeSolo);
  }

  static Finder getTikiGolfGameModeTeam() {
    return find.byKey(TikiGolfMenuKeys.gameModeTeam);
  }

  static Finder getTikiGolfTeamCountDropdown() {
    return find.byKey(TikiGolfMenuKeys.teamCountDropdown);
  }

  static Finder getTikiGolfAssignmentModeToggle() {
    return find.byKey(TikiGolfMenuKeys.assignmentModeToggle);
  }

  static Finder getTikiGolfAssignmentModeManual() {
    return find.byKey(TikiGolfMenuKeys.assignmentModeManual);
  }

  static Finder getTikiGolfAssignmentModeRandom() {
    return find.byKey(TikiGolfMenuKeys.assignmentModeRandom);
  }

  static Finder getTikiGolfMaxStrokesDropdown() {
    return find.byKey(TikiGolfMenuKeys.maxStrokesDropdown);
  }

  static Finder getTikiGolfMulliganSwitch() {
    return find.byKey(TikiGolfMenuKeys.mulliganSwitch);
  }

  static Finder getTikiGolfStartButton() {
    return find.byKey(TikiGolfMenuKeys.startGameButton);
  }

  // ==========================================================================
  // TIKI GOLF GAME FINDERS
  // ==========================================================================

  static Finder getTikiGolfGameBackButton() {
    return find.byKey(TikiGolfGameKeys.backButton);
  }

  static Finder getTikiGolfSkipTurnButton() {
    return find.byKey(TikiGolfGameKeys.skipTurnButton);
  }

  static Finder getTikiGolfEditScoreButton() {
    return find.byKey(TikiGolfGameKeys.editScoreButton);
  }

  static Finder getTikiGolfHoleCounter() {
    return find.byKey(TikiGolfGameKeys.holeCounter);
  }

  static Finder getTikiGolfHoleName() {
    return find.byKey(TikiGolfGameKeys.holeName);
  }

  static Finder getTikiGolfHoleImage() {
    return find.byKey(TikiGolfGameKeys.holeImage);
  }

  static Finder getTikiGolfTargetNumber() {
    return find.byKey(TikiGolfGameKeys.targetNumber);
  }

  static Finder getTikiGolfDartIndicator(int index) {
    return find.byKey(TikiGolfGameKeys.dartIndicator(index));
  }

  static Finder getTikiGolfScorecard() {
    return find.byKey(TikiGolfGameKeys.scorecard);
  }

  static Finder getTikiGolfScorecardCell(String playerId, int hole) {
    return find.byKey(TikiGolfGameKeys.scorecardCell(playerId, hole));
  }

  static Finder getTikiGolfScorecardPlayerRow(String playerId) {
    return find.byKey(TikiGolfGameKeys.scorecardPlayerRow(playerId));
  }

  static Finder getTikiGolfTeamsPanel() {
    return find.byKey(TikiGolfGameKeys.teamsPanel);
  }

  static Finder getTikiGolfTeamBox(String teamId) {
    return find.byKey(TikiGolfGameKeys.teamBox(teamId));
  }

  static Finder getTikiGolfRemoveDartsModal() {
    return find.byKey(TikiGolfGameKeys.removeDartsModal);
  }

  static Finder getTikiGolfUseMulliganButton() {
    return find.byKey(TikiGolfGameKeys.useMulliganButton);
  }

  static Finder getTikiGolfNextPlayerButton() {
    return find.byKey(TikiGolfGameKeys.nextPlayerButton);
  }

  static Finder getTikiGolfMulliganButton() {
    return find.byKey(TikiGolfGameKeys.mulliganButton);
  }

  // ==========================================================================
  // TIKI GOLF RESULTS FINDERS
  // ==========================================================================

  static Finder getTikiGolfPlayAgainButton() {
    return find.byKey(TikiGolfResultsKeys.playAgainButton);
  }

  static Finder getTikiGolfChangeSettingsButton() {
    return find.byKey(TikiGolfResultsKeys.changeSettingsButton);
  }

  static Finder getTikiGolfBackToMenuButton() {
    return find.byKey(TikiGolfResultsKeys.backToMenuButton);
  }

  static Finder getTikiGolfWinnerName() {
    return find.byKey(TikiGolfResultsKeys.winnerName);
  }

  static Finder getTikiGolfWinnerTeamCrest() {
    return find.byKey(TikiGolfResultsKeys.winnerTeamCrest);
  }

  static Finder getTikiGolfWinnerTeamPlayer(String playerId) {
    return find.byKey(TikiGolfResultsKeys.winnerTeamPlayer(playerId));
  }

  static Finder getTikiGolfFinalScorecard() {
    return find.byKey(TikiGolfResultsKeys.finalScorecard);
  }
}
