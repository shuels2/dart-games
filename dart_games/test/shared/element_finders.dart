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

  // NOTE: optionsButton not yet keyed in HomeKeys - will be added in Phase 1F
  // static Finder getOptionsButton() {
  //   return find.byKey(HomeKeys.optionsButton);
  // }

  // ==========================================================================
  // CARNIVAL DERBY MENU FINDERS
  // ==========================================================================

  static Finder getCarnivalDerbyAddPlayerButton() {
    return find.byKey(CarnivalDerbyMenuKeys.addPlayerButton);
  }

  static Finder getCarnivalDerbyPlayerTile(String playerId) {
    return find.byKey(CarnivalDerbyMenuKeys.playerTile(playerId));
  }

  // NOTE: removePlayerButton not yet added to CarnivalDerbyMenuKeys
  // Will be added when player tiles are fully keyed
  // static Finder getCarnivalDerbyRemovePlayerButton(String playerId) {
  //   return find.byKey(CarnivalDerbyMenuKeys.removePlayerButton(playerId));
  // }

  static Finder getCarnivalDerbyTargetScoreDropdown() {
    return find.byKey(CarnivalDerbyMenuKeys.targetScoreDropdown);
  }

  static Finder getCarnivalDerbyPerfectFinishToggle() {
    return find.byKey(CarnivalDerbyMenuKeys.perfectFinishSwitch);
  }

  static Finder getCarnivalDerbyStartButton() {
    return find.byKey(CarnivalDerbyMenuKeys.startButton);
  }

  // NOTE: backButton not yet added to CarnivalDerbyMenuKeys
  // Will be added when menu navigation is fully keyed
  // static Finder getCarnivalDerbyBackButton() {
  //   return find.byKey(CarnivalDerbyMenuKeys.backButton);
  // }

  // ==========================================================================
  // CARNIVAL DERBY GAME FINDERS
  // ==========================================================================

  static Finder getCarnivalDerbySkipTurnButton() {
    return find.byKey(CarnivalDerbyGameKeys.skipTurnButton);
  }

  // NOTE: dartsRemovedButton not yet added to CarnivalDerbyGameKeys
  // This is a placeholder for when Phase 1D is complete
  // For now, Phase 2D helpers will skip this functionality
  // static Finder getCarnivalDerbyDartsRemovedButton() {
  //   return find.byKey(CarnivalDerbyGameKeys.dartsRemovedButton);
  // }

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

  static Finder getTargetTagPlayerTile(String playerId) {
    return find.byKey(TargetTagMenuKeys.playerTile(playerId));
  }

  // NOTE: removePlayerButton not yet added to TargetTagMenuKeys
  // Will be added when player tiles are fully keyed
  // static Finder getTargetTagRemovePlayerButton(String playerId) {
  //   return find.byKey(TargetTagMenuKeys.removePlayerButton(playerId));
  // }

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

  // NOTE: backButton not yet added to TargetTagMenuKeys
  // Will be added when menu navigation is fully keyed
  // static Finder getTargetTagBackButton() {
  //   return find.byKey(TargetTagMenuKeys.backButton);
  // }

  // ==========================================================================
  // TARGET TAG GAME FINDERS
  // ==========================================================================

  static Finder getTargetTagSkipTurnButton() {
    return find.byKey(TargetTagGameKeys.skipTurnButton);
  }

  // NOTE: dartsRemovedButton not yet added to TargetTagGameKeys
  // Will be added when game controls are fully keyed
  // static Finder getTargetTagDartsRemovedButton() {
  //   return find.byKey(TargetTagGameKeys.dartsRemovedButton);
  // }

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
}
