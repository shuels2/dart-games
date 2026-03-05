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

  static Finder getReefRoyaleShowHintsSwitch() {
    return find.byKey(ReefRoyaleMenuKeys.showHintsSwitch);
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
}
