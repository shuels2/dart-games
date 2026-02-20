import 'package:flutter/material.dart';

/// Central repository for all widget test keys in the Dart Games project.
///
/// Naming Convention:
/// - Format: Key('{screen}_{game}_{element}_{descriptor}')
/// - Examples:
///   - home_carnival_derby_card
///   - carnival_menu_target_score_dropdown
///   - target_game_player_2_tile
///
/// Organization:
/// - HomeKeys - Home screen navigation
/// - CarnivalDerbyMenuKeys - Carnival Derby menu screen
/// - CarnivalDerbyGameKeys - Carnival Derby game screen
/// - CarnivalDerbyResultsKeys - Carnival Derby results screen
/// - TargetTagMenuKeys - Target Tag menu screen
/// - TargetTagGameKeys - Target Tag game screen
/// - TargetTagResultsKeys - Target Tag results screen
/// - MonsterMashMenuKeys - Monster Mash menu screen
/// - MonsterMashGameKeys - Monster Mash game screen
/// - MonsterMashResultsKeys - Monster Mash results screen
/// - EditScoreDialogKeys - Edit Score dialog (shared by all games)
/// - AddPlayerDialogKeys - Add Player dialog (shared by all games)
/// - TeamAssignmentDialogKeys - Team Assignment dialog (Target Tag only)
/// - DartboardEmulatorKeys - Dartboard emulator widget keys

// ============================================================================
// HOME SCREEN KEYS
// ============================================================================

class HomeKeys {
  static const carnivalDerbyCard = Key('home_carnival_derby_card');
  static const targetTagCard = Key('home_target_tag_card');
  static const monsterMashCard = Key('home_monster_mash_card');
}

// ============================================================================
// CARNIVAL DERBY KEYS
// ============================================================================

class CarnivalDerbyMenuKeys {
  // Player selection
  static const addPlayerButton = Key('carnival_menu_add_player_button');
  static const addPlayerButtonEmptyState = Key('carnival_menu_add_player_button_empty');
  static const playerListView = Key('carnival_menu_player_list_view');
  static Key playerTile(String playerId) =>
      Key('carnival_menu_player_${playerId}_tile');
  static Key removePlayerButton(String playerId) =>
      Key('carnival_menu_remove_player_${playerId}_button');

  // Game settings
  static const targetScoreDropdown =
      Key('carnival_menu_target_score_dropdown');
  static const targetScoreSlider = Key('carnival_menu_target_score_slider');
  static const perfectFinishToggle =
      Key('carnival_menu_perfect_finish_toggle');
  static const perfectFinishSwitch =
      Key('carnival_menu_perfect_finish_switch');

  // Navigation
  static const startGameButton = Key('carnival_menu_start_game_button');
  static const startButton = Key('carnival_menu_start_button');
  static const backButton = Key('carnival_menu_back_button');
}

class CarnivalDerbyGameKeys {
  // Player information
  static Key playerTile(String playerId) =>
      Key('carnival_game_player_${playerId}_tile');
  static Key playerScore(String playerId) =>
      Key('carnival_game_player_${playerId}_score');
  static Key playerPosition(String playerId) =>
      Key('carnival_game_player_${playerId}_position');

  // Game controls
  static const skipTurnButton = Key('carnival_game_skip_turn_button');
  static const editScoreButton = Key('carnival_game_edit_score_button');
  static const currentPlayerIndicator =
      Key('carnival_game_current_player_indicator');

  // Dartboard emulator - all 63 dart buttons
  static const dartSingle1Button = Key('carnival_game_dart_single_1_button');
  static const dartSingle2Button = Key('carnival_game_dart_single_2_button');
  static const dartSingle3Button = Key('carnival_game_dart_single_3_button');
  static const dartSingle4Button = Key('carnival_game_dart_single_4_button');
  static const dartSingle5Button = Key('carnival_game_dart_single_5_button');
  static const dartSingle6Button = Key('carnival_game_dart_single_6_button');
  static const dartSingle7Button = Key('carnival_game_dart_single_7_button');
  static const dartSingle8Button = Key('carnival_game_dart_single_8_button');
  static const dartSingle9Button = Key('carnival_game_dart_single_9_button');
  static const dartSingle10Button = Key('carnival_game_dart_single_10_button');
  static const dartSingle11Button = Key('carnival_game_dart_single_11_button');
  static const dartSingle12Button = Key('carnival_game_dart_single_12_button');
  static const dartSingle13Button = Key('carnival_game_dart_single_13_button');
  static const dartSingle14Button = Key('carnival_game_dart_single_14_button');
  static const dartSingle15Button = Key('carnival_game_dart_single_15_button');
  static const dartSingle16Button = Key('carnival_game_dart_single_16_button');
  static const dartSingle17Button = Key('carnival_game_dart_single_17_button');
  static const dartSingle18Button = Key('carnival_game_dart_single_18_button');
  static const dartSingle19Button = Key('carnival_game_dart_single_19_button');
  static const dartSingle20Button = Key('carnival_game_dart_single_20_button');

  static const dartDouble1Button = Key('carnival_game_dart_double_1_button');
  static const dartDouble2Button = Key('carnival_game_dart_double_2_button');
  static const dartDouble3Button = Key('carnival_game_dart_double_3_button');
  static const dartDouble4Button = Key('carnival_game_dart_double_4_button');
  static const dartDouble5Button = Key('carnival_game_dart_double_5_button');
  static const dartDouble6Button = Key('carnival_game_dart_double_6_button');
  static const dartDouble7Button = Key('carnival_game_dart_double_7_button');
  static const dartDouble8Button = Key('carnival_game_dart_double_8_button');
  static const dartDouble9Button = Key('carnival_game_dart_double_9_button');
  static const dartDouble10Button = Key('carnival_game_dart_double_10_button');
  static const dartDouble11Button = Key('carnival_game_dart_double_11_button');
  static const dartDouble12Button = Key('carnival_game_dart_double_12_button');
  static const dartDouble13Button = Key('carnival_game_dart_double_13_button');
  static const dartDouble14Button = Key('carnival_game_dart_double_14_button');
  static const dartDouble15Button = Key('carnival_game_dart_double_15_button');
  static const dartDouble16Button = Key('carnival_game_dart_double_16_button');
  static const dartDouble17Button = Key('carnival_game_dart_double_17_button');
  static const dartDouble18Button = Key('carnival_game_dart_double_18_button');
  static const dartDouble19Button = Key('carnival_game_dart_double_19_button');
  static const dartDouble20Button = Key('carnival_game_dart_double_20_button');

  static const dartTriple1Button = Key('carnival_game_dart_triple_1_button');
  static const dartTriple2Button = Key('carnival_game_dart_triple_2_button');
  static const dartTriple3Button = Key('carnival_game_dart_triple_3_button');
  static const dartTriple4Button = Key('carnival_game_dart_triple_4_button');
  static const dartTriple5Button = Key('carnival_game_dart_triple_5_button');
  static const dartTriple6Button = Key('carnival_game_dart_triple_6_button');
  static const dartTriple7Button = Key('carnival_game_dart_triple_7_button');
  static const dartTriple8Button = Key('carnival_game_dart_triple_8_button');
  static const dartTriple9Button = Key('carnival_game_dart_triple_9_button');
  static const dartTriple10Button = Key('carnival_game_dart_triple_10_button');
  static const dartTriple11Button = Key('carnival_game_dart_triple_11_button');
  static const dartTriple12Button = Key('carnival_game_dart_triple_12_button');
  static const dartTriple13Button = Key('carnival_game_dart_triple_13_button');
  static const dartTriple14Button = Key('carnival_game_dart_triple_14_button');
  static const dartTriple15Button = Key('carnival_game_dart_triple_15_button');
  static const dartTriple16Button = Key('carnival_game_dart_triple_16_button');
  static const dartTriple17Button = Key('carnival_game_dart_triple_17_button');
  static const dartTriple18Button = Key('carnival_game_dart_triple_18_button');
  static const dartTriple19Button = Key('carnival_game_dart_triple_19_button');
  static const dartTriple20Button = Key('carnival_game_dart_triple_20_button');

  static const dartBullseyeButton = Key('carnival_game_dart_bullseye_button');
  static const dartOuterBullButton =
      Key('carnival_game_dart_outer_bull_button');
  static const dartMissButton = Key('carnival_game_dart_miss_button');

  /// Helper method to get dart button key by multiplier and number.
  ///
  /// Examples:
  /// - getDartKey('single', 20) → dartSingle20Button
  /// - getDartKey('double', 16) → dartDouble16Button
  /// - getDartKey('triple', 5) → dartTriple5Button
  /// - getDartKey('bullseye', null) → dartBullseyeButton
  /// - getDartKey('outer_bull', null) → dartOuterBullButton
  /// - getDartKey('miss', null) → dartMissButton
  static Key getDartKey(String multiplier, int? number) {
    if (multiplier == 'bullseye') return dartBullseyeButton;
    if (multiplier == 'outer_bull') return dartOuterBullButton;
    if (multiplier == 'miss') return dartMissButton;

    return Key('carnival_game_dart_${multiplier}_${number}_button');
  }
}

class CarnivalDerbyResultsKeys {
  static const winnerName = Key('carnival_results_winner_name');
  static const winnerPhoto = Key('carnival_results_winner_photo');
  static const playAgainButton = Key('carnival_results_play_again_button');
  static const changeSettingsButton =
      Key('carnival_results_change_settings_button');
  static const backToMenuButton = Key('carnival_results_back_to_menu_button');
}

// ============================================================================
// TARGET TAG KEYS
// ============================================================================

class TargetTagMenuKeys {
  // Player selection
  static const addPlayerButton = Key('target_menu_add_player_button');
  static const addPlayerButtonEmptyState = Key('target_menu_add_player_button_empty');
  static const playerListView = Key('target_menu_player_list_view');
  static Key playerTile(String playerId) =>
      Key('target_menu_player_${playerId}_tile');
  static Key removePlayerButton(String playerId) =>
      Key('target_menu_remove_player_${playerId}_button');

  // Game settings
  static const targetScoreDropdown = Key('target_menu_target_score_dropdown');
  static const shieldMaxSlider = Key('target_menu_shield_max_slider');
  static const teamModeToggle = Key('target_menu_team_mode_toggle');
  static const teamModeSwitch = Key('target_menu_team_mode_switch');
  static const manualTeamAssignmentSwitch =
      Key('target_menu_manual_team_assignment_switch');
  static const heroBonusToggle = Key('target_menu_hero_bonus_toggle');
  static const heroBonusSwitch = Key('target_menu_hero_bonus_switch');
  static const assignTeamsButton = Key('target_menu_assign_teams_button');

  // Navigation
  static const startGameButton = Key('target_menu_start_game_button');
  static const startButton = Key('target_menu_start_button');
  static const backButton = Key('target_menu_back_button');
}

class TargetTagGameKeys {
  // Player information
  static Key playerTile(String playerId) =>
      Key('target_game_player_${playerId}_tile');
  static Key playerShields(String playerId) =>
      Key('target_game_player_${playerId}_shields');
  static Key playerTaggedInBadge(String playerId) =>
      Key('target_game_player_${playerId}_tagged_in_badge');
  static Key playerEliminatedOverlay(String playerId) =>
      Key('target_game_player_${playerId}_eliminated_overlay');

  // Active player panel
  static const activePlayerName = Key('target_game_active_player_name');
  static const activePlayerTargetLabel = Key('target_game_active_player_target_label');
  static const activePlayerTargetValue = Key('target_game_active_player_target_value');
  static const activePlayerOpponentTargetsLabel = Key('target_game_active_player_opponent_targets_label');
  static const activePlayerOpponentTargetsValue = Key('target_game_active_player_opponent_targets_value');
  static const activePlayerBuffLabel = Key('target_game_active_player_buff_label');
  static const activePlayerBuffValue = Key('target_game_active_player_buff_value');
  static const activePlayerTaggedInBadge = Key('target_game_active_player_tagged_in_badge');
  static const activePlayerD1Indicator = Key('d1_indicator');
  static const activePlayerD2Indicator = Key('d2_indicator');
  static const activePlayerD3Indicator = Key('d3_indicator');

  // Game controls
  static const skipTurnButton = Key('target_game_skip_turn_button');
  static const editScoreButton = Key('target_game_edit_score_button');
  static const currentPlayerIndicator =
      Key('target_game_current_player_indicator');

  // Dartboard emulator - all 63 dart buttons
  static const dartSingle1Button = Key('target_game_dart_single_1_button');
  static const dartSingle2Button = Key('target_game_dart_single_2_button');
  static const dartSingle3Button = Key('target_game_dart_single_3_button');
  static const dartSingle4Button = Key('target_game_dart_single_4_button');
  static const dartSingle5Button = Key('target_game_dart_single_5_button');
  static const dartSingle6Button = Key('target_game_dart_single_6_button');
  static const dartSingle7Button = Key('target_game_dart_single_7_button');
  static const dartSingle8Button = Key('target_game_dart_single_8_button');
  static const dartSingle9Button = Key('target_game_dart_single_9_button');
  static const dartSingle10Button = Key('target_game_dart_single_10_button');
  static const dartSingle11Button = Key('target_game_dart_single_11_button');
  static const dartSingle12Button = Key('target_game_dart_single_12_button');
  static const dartSingle13Button = Key('target_game_dart_single_13_button');
  static const dartSingle14Button = Key('target_game_dart_single_14_button');
  static const dartSingle15Button = Key('target_game_dart_single_15_button');
  static const dartSingle16Button = Key('target_game_dart_single_16_button');
  static const dartSingle17Button = Key('target_game_dart_single_17_button');
  static const dartSingle18Button = Key('target_game_dart_single_18_button');
  static const dartSingle19Button = Key('target_game_dart_single_19_button');
  static const dartSingle20Button = Key('target_game_dart_single_20_button');

  static const dartDouble1Button = Key('target_game_dart_double_1_button');
  static const dartDouble2Button = Key('target_game_dart_double_2_button');
  static const dartDouble3Button = Key('target_game_dart_double_3_button');
  static const dartDouble4Button = Key('target_game_dart_double_4_button');
  static const dartDouble5Button = Key('target_game_dart_double_5_button');
  static const dartDouble6Button = Key('target_game_dart_double_6_button');
  static const dartDouble7Button = Key('target_game_dart_double_7_button');
  static const dartDouble8Button = Key('target_game_dart_double_8_button');
  static const dartDouble9Button = Key('target_game_dart_double_9_button');
  static const dartDouble10Button = Key('target_game_dart_double_10_button');
  static const dartDouble11Button = Key('target_game_dart_double_11_button');
  static const dartDouble12Button = Key('target_game_dart_double_12_button');
  static const dartDouble13Button = Key('target_game_dart_double_13_button');
  static const dartDouble14Button = Key('target_game_dart_double_14_button');
  static const dartDouble15Button = Key('target_game_dart_double_15_button');
  static const dartDouble16Button = Key('target_game_dart_double_16_button');
  static const dartDouble17Button = Key('target_game_dart_double_17_button');
  static const dartDouble18Button = Key('target_game_dart_double_18_button');
  static const dartDouble19Button = Key('target_game_dart_double_19_button');
  static const dartDouble20Button = Key('target_game_dart_double_20_button');

  static const dartTriple1Button = Key('target_game_dart_triple_1_button');
  static const dartTriple2Button = Key('target_game_dart_triple_2_button');
  static const dartTriple3Button = Key('target_game_dart_triple_3_button');
  static const dartTriple4Button = Key('target_game_dart_triple_4_button');
  static const dartTriple5Button = Key('target_game_dart_triple_5_button');
  static const dartTriple6Button = Key('target_game_dart_triple_6_button');
  static const dartTriple7Button = Key('target_game_dart_triple_7_button');
  static const dartTriple8Button = Key('target_game_dart_triple_8_button');
  static const dartTriple9Button = Key('target_game_dart_triple_9_button');
  static const dartTriple10Button = Key('target_game_dart_triple_10_button');
  static const dartTriple11Button = Key('target_game_dart_triple_11_button');
  static const dartTriple12Button = Key('target_game_dart_triple_12_button');
  static const dartTriple13Button = Key('target_game_dart_triple_13_button');
  static const dartTriple14Button = Key('target_game_dart_triple_14_button');
  static const dartTriple15Button = Key('target_game_dart_triple_15_button');
  static const dartTriple16Button = Key('target_game_dart_triple_16_button');
  static const dartTriple17Button = Key('target_game_dart_triple_17_button');
  static const dartTriple18Button = Key('target_game_dart_triple_18_button');
  static const dartTriple19Button = Key('target_game_dart_triple_19_button');
  static const dartTriple20Button = Key('target_game_dart_triple_20_button');

  static const dartBullseyeButton = Key('target_game_dart_bullseye_button');
  static const dartOuterBullButton = Key('target_game_dart_outer_bull_button');
  static const dartMissButton = Key('target_game_dart_miss_button');

  /// Helper method to get dart button key by multiplier and number.
  ///
  /// Examples:
  /// - getDartKey('single', 20) → dartSingle20Button
  /// - getDartKey('double', 16) → dartDouble16Button
  /// - getDartKey('triple', 5) → dartTriple5Button
  /// - getDartKey('bullseye', null) → dartBullseyeButton
  /// - getDartKey('outer_bull', null) → dartOuterBullButton
  /// - getDartKey('miss', null) → dartMissButton
  static Key getDartKey(String multiplier, int? number) {
    if (multiplier == 'bullseye') return dartBullseyeButton;
    if (multiplier == 'outer_bull') return dartOuterBullButton;
    if (multiplier == 'miss') return dartMissButton;

    return Key('target_game_dart_${multiplier}_${number}_button');
  }
}

class TargetTagResultsKeys {
  static const winnerName = Key('target_results_winner_name');
  static const winnerPhoto = Key('target_results_winner_photo');
  static const playAgainButton = Key('target_results_play_again_button');
  static const changeSettingsButton =
      Key('target_results_change_settings_button');
  static const backToMenuButton = Key('target_results_back_to_menu_button');
}

// ============================================================================
// MONSTER MASH KEYS
// ============================================================================

class MonsterMashMenuKeys {
  // Player selection
  static const addPlayerButton = Key('monster_menu_add_player_button');
  static const playerListView = Key('monster_menu_player_list_view');
  static Key playerTile(String playerId) =>
      Key('monster_menu_player_${playerId}_tile');

  // Game settings
  static const healthPointsSlider = Key('monster_menu_health_points_slider');
  static const bonusBuffsSwitch = Key('monster_menu_bonus_buffs_switch');
  static const speedPlaySwitch = Key('monster_menu_speed_play_switch');
  static const roundLimitSlider = Key('monster_menu_round_limit_slider');

  // Navigation
  static const startGameButton = Key('monster_menu_start_game_button');
  static const backButton = Key('monster_menu_back_button');
}

class MonsterMashGameKeys {
  // Player information
  static Key playerTile(String playerId) =>
      Key('monster_game_player_${playerId}_tile');
  static Key healthBar(String playerId) =>
      Key('monster_game_player_${playerId}_health_bar');

  // Game controls
  static const skipTurnButton = Key('monster_game_skip_turn_button');
  static const editScoreButton = Key('monster_game_edit_score_button');

  // Dartboard emulator - all 63 dart buttons
  static const dartSingle1Button = Key('monster_game_dart_single_1_button');
  static const dartSingle2Button = Key('monster_game_dart_single_2_button');
  static const dartSingle3Button = Key('monster_game_dart_single_3_button');
  static const dartSingle4Button = Key('monster_game_dart_single_4_button');
  static const dartSingle5Button = Key('monster_game_dart_single_5_button');
  static const dartSingle6Button = Key('monster_game_dart_single_6_button');
  static const dartSingle7Button = Key('monster_game_dart_single_7_button');
  static const dartSingle8Button = Key('monster_game_dart_single_8_button');
  static const dartSingle9Button = Key('monster_game_dart_single_9_button');
  static const dartSingle10Button = Key('monster_game_dart_single_10_button');
  static const dartSingle11Button = Key('monster_game_dart_single_11_button');
  static const dartSingle12Button = Key('monster_game_dart_single_12_button');
  static const dartSingle13Button = Key('monster_game_dart_single_13_button');
  static const dartSingle14Button = Key('monster_game_dart_single_14_button');
  static const dartSingle15Button = Key('monster_game_dart_single_15_button');
  static const dartSingle16Button = Key('monster_game_dart_single_16_button');
  static const dartSingle17Button = Key('monster_game_dart_single_17_button');
  static const dartSingle18Button = Key('monster_game_dart_single_18_button');
  static const dartSingle19Button = Key('monster_game_dart_single_19_button');
  static const dartSingle20Button = Key('monster_game_dart_single_20_button');

  static const dartDouble1Button = Key('monster_game_dart_double_1_button');
  static const dartDouble2Button = Key('monster_game_dart_double_2_button');
  static const dartDouble3Button = Key('monster_game_dart_double_3_button');
  static const dartDouble4Button = Key('monster_game_dart_double_4_button');
  static const dartDouble5Button = Key('monster_game_dart_double_5_button');
  static const dartDouble6Button = Key('monster_game_dart_double_6_button');
  static const dartDouble7Button = Key('monster_game_dart_double_7_button');
  static const dartDouble8Button = Key('monster_game_dart_double_8_button');
  static const dartDouble9Button = Key('monster_game_dart_double_9_button');
  static const dartDouble10Button = Key('monster_game_dart_double_10_button');
  static const dartDouble11Button = Key('monster_game_dart_double_11_button');
  static const dartDouble12Button = Key('monster_game_dart_double_12_button');
  static const dartDouble13Button = Key('monster_game_dart_double_13_button');
  static const dartDouble14Button = Key('monster_game_dart_double_14_button');
  static const dartDouble15Button = Key('monster_game_dart_double_15_button');
  static const dartDouble16Button = Key('monster_game_dart_double_16_button');
  static const dartDouble17Button = Key('monster_game_dart_double_17_button');
  static const dartDouble18Button = Key('monster_game_dart_double_18_button');
  static const dartDouble19Button = Key('monster_game_dart_double_19_button');
  static const dartDouble20Button = Key('monster_game_dart_double_20_button');

  static const dartTriple1Button = Key('monster_game_dart_triple_1_button');
  static const dartTriple2Button = Key('monster_game_dart_triple_2_button');
  static const dartTriple3Button = Key('monster_game_dart_triple_3_button');
  static const dartTriple4Button = Key('monster_game_dart_triple_4_button');
  static const dartTriple5Button = Key('monster_game_dart_triple_5_button');
  static const dartTriple6Button = Key('monster_game_dart_triple_6_button');
  static const dartTriple7Button = Key('monster_game_dart_triple_7_button');
  static const dartTriple8Button = Key('monster_game_dart_triple_8_button');
  static const dartTriple9Button = Key('monster_game_dart_triple_9_button');
  static const dartTriple10Button = Key('monster_game_dart_triple_10_button');
  static const dartTriple11Button = Key('monster_game_dart_triple_11_button');
  static const dartTriple12Button = Key('monster_game_dart_triple_12_button');
  static const dartTriple13Button = Key('monster_game_dart_triple_13_button');
  static const dartTriple14Button = Key('monster_game_dart_triple_14_button');
  static const dartTriple15Button = Key('monster_game_dart_triple_15_button');
  static const dartTriple16Button = Key('monster_game_dart_triple_16_button');
  static const dartTriple17Button = Key('monster_game_dart_triple_17_button');
  static const dartTriple18Button = Key('monster_game_dart_triple_18_button');
  static const dartTriple19Button = Key('monster_game_dart_triple_19_button');
  static const dartTriple20Button = Key('monster_game_dart_triple_20_button');

  static const dartBullseyeButton = Key('monster_game_dart_bullseye_button');
  static const dartOuterBullButton = Key('monster_game_dart_outer_bull_button');
  static const dartMissButton = Key('monster_game_dart_miss_button');

  static Key getDartKey(String multiplier, int? number) {
    if (multiplier == 'bullseye') return dartBullseyeButton;
    if (multiplier == 'outer_bull') return dartOuterBullButton;
    if (multiplier == 'miss') return dartMissButton;

    return Key('monster_game_dart_${multiplier}_${number}_button');
  }
}

class MonsterMashResultsKeys {
  static const winnerName = Key('monster_results_winner_name');
  static const playAgainButton = Key('monster_results_play_again_button');
  static const changeSettingsButton =
      Key('monster_results_change_settings_button');
  static const backToMenuButton = Key('monster_results_back_to_menu_button');
}

// ============================================================================
// DIALOG KEYS
// ============================================================================

class EditScoreDialogKeys {
  static const dialogContainer = Key('edit_score_dialog_container');
  static const dart1Dropdown = Key('edit_score_dart1_dropdown');
  static const dart2Dropdown = Key('edit_score_dart2_dropdown');
  static const dart3Dropdown = Key('edit_score_dart3_dropdown');
  static const saveButton = Key('edit_score_save_button');
  static const cancelButton = Key('edit_score_cancel_button');
}

class AddPlayerDialogKeys {
  static const dialogContainer = Key('add_player_dialog_container');
  static const nameTextField = Key('add_player_name_text_field');
  static const cameraButton = Key('add_player_camera_button');
  static const galleryButton = Key('add_player_gallery_button');
  static const photoPreview = Key('add_player_photo_preview');
  static const removePhotoButton = Key('add_player_remove_photo_button');
  static const addButton = Key('add_player_add_button');
  static const cancelButton = Key('add_player_cancel_button');
}

class TeamAssignmentDialogKeys {
  static const dialogContainer = Key('team_assignment_dialog_container');
  static const teamCountDropdown = Key('team_assignment_team_count_dropdown');
  static Key playerTeamDropdown(String playerId) =>
      Key('team_assignment_player_${playerId}_dropdown');
  static const saveButton = Key('team_assignment_save_button');
  static const cancelButton = Key('team_assignment_cancel_button');
}

// ============================================================================
// DARTBOARD EMULATOR KEYS
// ============================================================================

class DartboardEmulatorKeys {
  static const container = Key('dartboard_emulator_container');
  static const dartboard = Key('dartboard_emulator_dartboard');
  static const removeDartsButton = Key('dartboard_emulator_remove_darts_button');
  static const toggleFAB = Key('dartboard_emulator_toggle_fab');
}
