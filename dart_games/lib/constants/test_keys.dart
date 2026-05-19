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
  static const reefRoyaleCard = Key('home_reef_royale_card');
  static const clockworkQuestCard = Key('home_clockwork_quest_card');
  static const lunarLanderCard = Key('home_lunar_lander_card');
  static const piratesGridCard = Key('home_pirates_grid_card');
  static const gladiatorArenaCard = Key('home_card_gladiator_arena');
  static const tikiGolfCard = Key('home_card_tiki_golf');

  // ──── Filter bar (home screen) ────
  static const filterBar = Key('home_filter_bar');
  static const filterMaxPlayersButton = Key('home_filter_max_players_button');
  static const filterGameplayStyleButton =
      Key('home_filter_gameplay_style_button');
  static const filterPlayerInteractionButton =
      Key('home_filter_player_interaction_button');
  static const filterGameLengthButton = Key('home_filter_game_length_button');
  static const filterSoloTeamButton = Key('home_filter_solo_team_button');

  /// Per-option menu item key. Caller passes the enum value's `name` (e.g.
  /// 'twoOnly', 'race', 'parallel') so each menu entry has a stable key
  /// that UI tests can target.
  static Key filterMaxPlayersOption(Object value) =>
      Key('home_filter_max_players_option_${(value as Enum).name}');
  static Key filterGameplayStyleOption(Object value) =>
      Key('home_filter_gameplay_style_option_${(value as Enum).name}');
  static Key filterPlayerInteractionOption(Object value) =>
      Key('home_filter_player_interaction_option_${(value as Enum).name}');
  static Key filterGameLengthOption(Object value) =>
      Key('home_filter_game_length_option_${(value as Enum).name}');
  static Key filterSoloTeamOption(Object value) =>
      Key('home_filter_solo_team_option_${(value as Enum).name}');
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
  static const resumeGameButton = Key('carnival_menu_resume_game_button');
}

class CarnivalDerbyGameKeys {
  static const backButton = Key('carnival_game_back_button');

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
  static const resumeGameButton = Key('target_menu_resume_game_button');
}

class TargetTagGameKeys {
  static const backButton = Key('target_game_back_button');

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
  static const addPlayerButtonEmptyState = Key('monster_menu_add_player_button_empty');
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
  static const resumeGameButton = Key('monster_menu_resume_game_button');
}

class MonsterMashGameKeys {
  static const backButton = Key('monster_game_back_button');

  // Player information
  static Key playerTile(String playerId) =>
      Key('monster_game_player_${playerId}_tile');
  static Key healthBar(String playerId) =>
      Key('monster_game_player_${playerId}_health_bar');

  // Game controls
  static const skipTurnButton = Key('monster_game_skip_turn_button');
  static const editScoreButton = Key('monster_game_edit_score_button');

  // Buff display
  static const buffHealShield = Key('monster_game_buff_heal_shield');
  static const buffDamageShield = Key('monster_game_buff_damage_shield');
  static const buffLabel = Key('monster_game_buff_label');

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

// ============================================================================
// REEF ROYALE KEYS
// ============================================================================

class ReefRoyaleMenuKeys {
  static const backButton = Key('reef_menu_back_button');
  static const gameModeDropdown = Key('reef_menu_game_mode_dropdown');
  static const easyClaimSwitch = Key('reef_menu_easy_claim_switch');
  static const neighborNumbersSwitch = Key('reef_menu_neighbor_numbers_switch');
  static const randomReefsSwitch = Key('reef_menu_random_reefs_switch');
  static const bonusBuffsSwitch = Key('reef_menu_bonus_buffs_switch');
  static const showHintsSwitch = Key('reef_menu_show_hints_switch');
  static const speedPlaySwitch = Key('reef_menu_speed_play_switch');
  static const roundLimitSlider = Key('reef_menu_round_limit_slider');
  static const startGameButton = Key('reef_menu_start_game_button');
  static const resumeGameButton = Key('reef_menu_resume_game_button');
  static const addPlayerButton = Key('reef_menu_add_player_button');
  static const addPlayerButtonEmptyState = Key('reef_menu_add_player_button_empty_state');
  static const playerListView = Key('reef_menu_player_list_view');
  static Key playerTile(String id) => Key('reef_menu_player_tile_$id');
  static Key removePlayerButton(String id) => Key('reef_menu_remove_player_$id');
}

class ReefRoyaleGameKeys {
  static const backButton = Key('reef_game_back_button');
  static const skipTurnButton = Key('reef_game_skip_turn_button');
  static const editScoreButton = Key('reef_game_edit_score_button');
  static Key coralCard(int targetNumber) => Key('reef_game_coral_card_$targetNumber');
  static const playerAvatar = Key('reef_game_player_avatar');
  static const pearlCounter = Key('reef_game_pearl_counter');
  static const coralCounter = Key('reef_game_coral_counter');
  static Key dartIndicator(int index) => Key('reef_game_dart_indicator_$index');
  static const buffBanner = Key('reef_game_buff_banner');
  static const roundCounter = Key('reef_game_round_counter');
  static const hintOverlay = Key('reef_game_hint_overlay');
  static Key playerTile(String playerId) => Key('reef_game_player_tile_$playerId');
  static const cursedBadge = Key('reef_game_cursed_badge');
  static const buffsBadge = Key('reef_game_buffs_badge');
  static const neighborsBadge = Key('reef_game_neighbors_badge');

  static const dartBullseyeButton = Key('reef_game_dart_bullseye_button');
  static const dartOuterBullButton = Key('reef_game_dart_outer_bull_button');
  static const dartMissButton = Key('reef_game_dart_miss_button');

  static Key getDartKey(String multiplier, int? number) {
    if (multiplier == 'bullseye') return dartBullseyeButton;
    if (multiplier == 'outer_bull') return dartOuterBullButton;
    if (multiplier == 'miss') return dartMissButton;
    return Key('reef_game_dart_${multiplier}_${number}_button');
  }
}

class ReefRoyaleResultsKeys {
  static const winnerName = Key('reef_results_winner_name');
  static const winnerPhoto = Key('reef_results_winner_photo');
  static const pearlCount = Key('reef_results_pearl_count');
  static const coralCount = Key('reef_results_coral_count');
  static const playAgainButton = Key('reef_results_play_again_button');
  static const changeSettingsButton = Key('reef_results_change_settings_button');
  static const backToMenuButton = Key('reef_results_back_to_menu_button');
  static Key playerRanking(int index) => Key('reef_results_player_ranking_$index');
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

// ============================================================================
// SAVE GAME MODAL KEYS
// ============================================================================

class SaveGameModalKeys {
  static const overlay = Key('save_game_modal_overlay');
  static const container = Key('save_game_modal_container');
  static const icon = Key('save_game_modal_icon');
  static const title = Key('save_game_modal_title');
  static const message = Key('save_game_modal_message');
  static const saveButton = Key('save_game_modal_save_button');
  static const dontSaveButton = Key('save_game_modal_dont_save_button');
}

// ============================================================================
// RESUME GAME MODAL KEYS
// ============================================================================

class ResumeGameModalKeys {
  static const overlay = Key('resume_game_modal_overlay');
  static const container = Key('resume_game_modal_container');
  static const title = Key('resume_game_modal_title');
  static const savedGamesList = Key('resume_game_modal_saved_games_list');
  static Key savedGameTile(String id) => Key('resume_game_modal_tile_$id');
  static Key deleteSavedGameButton(String id) => Key('resume_game_modal_delete_$id');
  static Key tileDate(String id) => Key('resume_game_modal_tile_date_$id');
  static Key tilePlayers(String id) => Key('resume_game_modal_tile_players_$id');
  static Key tileProgress(String id) => Key('resume_game_modal_tile_progress_$id');
  static Key tileMode(String id) => Key('resume_game_modal_tile_mode_$id');
  static Key tileLeader(String id) => Key('resume_game_modal_tile_leader_$id');
  static const resumeGameButton = Key('resume_game_modal_resume_button');
  static const startNewGameButton = Key('resume_game_modal_start_new_button');
  static const deleteAllButton = Key('resume_game_modal_delete_all_button');
  static const emptyStateText = Key('resume_game_modal_empty_state');
}

// ============================================================================
// DARTBOARD EMULATOR KEYS
// ============================================================================

class DartboardEmulatorKeys {
  static const container = Key('dartboard_emulator_container');
  static const dartboard = Key('dartboard_emulator_dartboard');
  static const removeDartsButton = Key('dartboard_emulator_remove_darts_button');
  static const toggleFAB = Key('dartboard_emulator_toggle_fab');
  static const playToCompleteButton = Key('dartboard_emulator_play_to_complete_button');
}

// ============================================================================
// CLOCKWORK QUEST KEYS
// ============================================================================

class ClockworkQuestMenuKeys {
  // Navigation
  static const backButton = Key('cq_menu_back_button');

  // Player selection
  static const addPlayerButton = Key('cq_menu_add_player_button');
  static const addPlayerButtonEmptyState = Key('cq_menu_add_player_button_empty_state');
  static const playerListView = Key('cq_menu_player_list_view');
  static Key playerTile(String playerId) => Key('cq_menu_player_${playerId}_tile');
  static Key removePlayerButton(String playerId) => Key('cq_menu_remove_player_${playerId}_button');

  // Settings
  static const includeBullseyeCheckbox = Key('cq_menu_include_bullseye_checkbox');
  static const speedModeCheckbox = Key('cq_menu_speed_mode_checkbox');
  static const numberOfLapsDropdown = Key('cq_menu_number_of_laps_dropdown');

  // Start button
  static const startButton = Key('cq_menu_start_button');

  // Resume button
  static const resumeGameButton = Key('cq_menu_resume_game_button');
}

class ClockworkQuestGameKeys {
  // Navigation
  static const backButton = Key('cq_game_back_button');

  // Player panels
  static const activePlayerPanel = Key('cq_game_active_player_panel');
  static const playerAvatar = Key('cq_game_player_avatar');
  static const activePlayerName = Key('cq_game_active_player_name');
  static const skipTurnButton = Key('cq_game_skip_turn_button');

  // Gear tracker
  static const gearTracker = Key('cq_game_gear_tracker');
  static Key gear(int number) => Key('cq_game_gear_$number');
  static Key gearActive(int number) => Key('cq_game_gear_${number}_active');

  // Progress display
  static const currentLapText = Key('cq_game_current_lap_text');
  static const currentTargetText = Key('cq_game_current_target_text');

  // Dartboard emulator
  static const dartboardSection = Key('cq_game_dartboard_section');

  // Dart indicators
  static Key dartIndicator(int index) => Key('cq_game_dart_indicator_$index');

  // Opponent progress bar
  static Key playerTile(String playerId) =>
      Key('cq_game_player_tile_$playerId');

  // Remove darts modal
  static const removeDartsModal = Key('cq_game_remove_darts_modal');
  static const confirmRemovalButton = Key('cq_game_confirm_removal_button');
  static const editScoreButton = Key('cq_game_edit_score_button');
}

class ClockworkQuestResultsKeys {
  static const winnerName = Key('cq_results_winner_name');
  static const winnerTitle = Key('cq_results_winner_title');
  static const rankingsList = Key('cq_results_rankings_list');
  static Key playerRankTile(String playerId) => Key('cq_results_player_${playerId}_rank_tile');
  static const playAgainButton = Key('cq_results_play_again_button');
  static const changeSettingsButton = Key('cq_results_change_settings_button');
  static const leaveTowerButton = Key('cq_results_leave_tower_button');
  // Alias for back-to-menu button (same as leaveTowerButton)
  static const backToMenuButton = Key('cq_results_leave_tower_button');
}

// ============================================================================
// LUNAR LANDER KEYS
// ============================================================================

class LunarLanderMenuKeys {
  static const backButton = Key('menu_ll_back_button');
  static const altitudeSlider = Key('menu_ll_altitude_slider');
  static const hardLandingSwitch = Key('menu_ll_hard_landing_switch');
  static const startGameButton = Key('menu_ll_start_game_button');
  static const addPlayerButton = Key('menu_ll_add_player_button');
  static const addPlayerButtonEmptyState = Key('menu_ll_add_player_button_empty');
  static const playerListView = Key('menu_ll_player_list_view');
  static Key playerTile(String playerId) => Key('menu_ll_player_tile_$playerId');
  static Key removePlayerButton(String playerId) => Key('menu_ll_remove_player_$playerId');
}

class LunarLanderGameKeys {
  static const backButton = Key('game_ll_back_button');
  static const skipTurnButton = Key('game_ll_skip_turn_button');
  static const editScoreButton = Key('game_ll_edit_score_button');
  static const playerAvatar = Key('game_ll_player_avatar');
  static const altitudeReadout = Key('game_ll_altitude_readout');
  static const hardLandingBadge = Key('game_ll_hard_landing_badge');
  static const turnSummary = Key('game_ll_turn_summary');
  static Key descentTrack(String playerId) => Key('game_ll_descent_track_$playerId');
  static Key characterOnTrack(String playerId) => Key('game_ll_char_on_track_$playerId');
  static Key dartIndicator(int index) => Key('game_ll_dart_indicator_$index');
}

class LunarLanderResultsKeys {
  static const winnerName = Key('results_ll_winner_name');
  static const winnerPhoto = Key('results_ll_winner_photo');
  static const turnCount = Key('results_ll_turn_count');
  static const playAgainButton = Key('results_ll_play_again_button');
  static const changeSettingsButton = Key('results_ll_change_settings_button');
  static const backToMenuButton = Key('results_ll_back_to_menu_button');
  static Key playerRanking(int index) => Key('results_ll_player_ranking_$index');
}

// ============================================================================
// PIRATE'S GRID KEYS
// ============================================================================

class PiratesGridMenuKeys {
  static const backButton = Key('pirates_grid_menu_back_button');
  static const difficultyDropdown = Key('pirates_grid_menu_difficulty_dropdown');
  static const bestOfDropdown = Key('pirates_grid_menu_best_of_dropdown');
  static const stealModeSwitch = Key('pirates_grid_menu_steal_mode_switch');
  static const speedPlaySwitch = Key('pirates_grid_menu_speed_play_switch');
  static const startGameButton = Key('pirates_grid_menu_start_button');
  static const addPlayerButton = Key('pirates_grid_menu_add_player_button');
  static const addPlayerButtonEmptyState = Key('pirates_grid_menu_add_player_button_empty');
  static const playerListView = Key('pirates_grid_menu_player_list_view');
  static Key playerTile(String playerId) =>
      Key('pirates_grid_menu_player_${playerId}_tile');
  static Key removePlayerButton(String playerId) =>
      Key('pirates_grid_menu_remove_${playerId}_button');
}

class PiratesGridGameKeys {
  static const backButton = Key('pirates_grid_game_back_button');
  static const skipTurnButton = Key('pirates_grid_game_skip_turn_button');
  static const editScoreButton = Key('pirates_grid_game_edit_score_button');
  static Key gridCell(int row, int col) =>
      Key('pirates_grid_game_cell_${row}_$col');
  static Key gridCellTargetLabel(int row, int col) =>
      Key('pirates_grid_game_cell_target_${row}_$col');
  static const playerAvatarActive = Key('pirates_grid_game_player_avatar_active');
  static const playerAvatarInactive = Key('pirates_grid_game_player_avatar_inactive');
  static Key flagsCounter(String playerId) =>
      Key('pirates_grid_game_flags_counter_$playerId');
  static Key dartIndicator(int index) =>
      Key('pirates_grid_game_dart_indicator_$index');
  static const stealModeBadge = Key('pirates_grid_game_steal_mode_badge');
  static const speedPlayTimer = Key('pirates_grid_game_speed_play_timer');
  static const roundTracker = Key('pirates_grid_game_round_tracker');
}

class PiratesGridResultsKeys {
  static const playAgainButton = Key('pirates_grid_results_play_again_button');
  static const changeSettingsButton = Key('pirates_grid_results_change_settings_button');
  static const backToMenuButton = Key('pirates_grid_results_back_to_menu_button');
  static const winnerName = Key('pirates_grid_results_winner_name');
  static const winnerAvatar = Key('pirates_grid_results_winner_avatar');
  static const rankingsList = Key('pirates_grid_results_rankings_list');
  static const headlineText = Key('pirates_grid_results_headline');
}

// ============================================================================
// GLADIATOR ARENA KEYS
// ============================================================================

class GladiatorArenaMenuKeys {
  static const Key backButton = Key('menu_ga_back_button');
  static const Key targetScoreSlider = Key('menu_ga_target_score_slider');
  static const Key targetScoreValue = Key('menu_ga_target_score_value');
  static const Key doubleFinishSwitch = Key('menu_ga_double_finish_switch');
  static const Key shieldRoundSwitch = Key('menu_ga_shield_round_switch');
  static const Key speedPlaySwitch = Key('menu_ga_speed_play_switch');
  static const Key startGameButton = Key('menu_ga_start_game_button');
  static const Key addPlayerButton = Key('menu_ga_add_player_button');
  static const Key addPlayerButtonEmptyState =
      Key('menu_ga_add_player_button_empty_state');
  static const Key playerListView = Key('menu_ga_player_list_view');
  static Key playerTile(String playerId) =>
      Key('menu_ga_player_tile_$playerId');
  static Key removePlayerButton(String playerId) =>
      Key('menu_ga_remove_player_button_$playerId');
}

class GladiatorArenaGameKeys {
  static const Key backButton = Key('game_ga_back_button');
  static const Key skipTurnButton = Key('game_ga_skip_turn_button');
  static const Key editScoreButton = Key('game_ga_edit_score_button');
  static const Key goalDisplay = Key('game_ga_goal_display');
  static const Key doubleRangeIndicator = Key('game_ga_double_range_indicator');
  static const Key timerDisplay = Key('game_ga_timer_display');
  static const Key shieldBanner = Key('game_ga_shield_banner');
  static const Key eliminationZone = Key('game_ga_elimination_zone');
  static const Key doubleBadge = Key('game_ga_double_badge');
  static const Key activePlayerNameLabel = Key('game_ga_active_player_name_label');
  static Key dartIndicator(int index) => Key('game_ga_dart_indicator_$index');
  static Key podium(String playerId) => Key('game_ga_podium_$playerId');
}

class GladiatorArenaResultsKeys {
  static const Key winnerCharacterImage = Key('results_ga_winner_character_image');
  static const Key winnerPlayerPhoto = Key('results_ga_winner_player_photo');
  static const Key winnerName = Key('results_ga_winner_name');
  static const Key rankingsList = Key('results_ga_rankings_list');
  static Key rankRow(int index) => Key('results_ga_rank_row_$index');
  static const Key knockoffStats = Key('results_ga_knockoff_stats');
  static const Key playAgainButton = Key('results_ga_play_again_button');
  static const Key changeSettingsButton = Key('results_ga_change_settings_button');
  static const Key backToMenuButton = Key('results_ga_back_to_menu_button');
}

// ============================================================================
// TIKI GOLF KEYS
// ============================================================================

class TikiGolfMenuKeys {
  // Navigation
  static const backButton = Key('tiki_golf_menu_back_button');

  // Player selection
  static const addPlayerButton = Key('tiki_golf_menu_add_player_button');
  static const addPlayerButtonEmptyState =
      Key('tiki_golf_menu_add_player_button_empty_state');
  static const playerListView = Key('tiki_golf_menu_player_list_view');
  static Key playerTile(String id) => Key('tiki_golf_menu_player_tile_$id');
  static Key removePlayerButton(String id) =>
      Key('tiki_golf_menu_remove_player_button_$id');

  // Navigation buttons
  static const startGameButton = Key('tiki_golf_menu_start_game_button');
  static const resumeGameButton = Key('tiki_golf_menu_resume_game_button');

  // Game Mode toggle
  static const gameModeToggle = Key('tiki_golf_menu_game_mode_toggle');
  static const gameModeSolo = Key('tiki_golf_menu_game_mode_solo');
  static const gameModeTeam = Key('tiki_golf_menu_game_mode_team');

  // Team Assignment toggle
  static const assignmentModeToggle =
      Key('tiki_golf_menu_assignment_mode_toggle');
  static const assignmentModeManual =
      Key('tiki_golf_menu_assignment_mode_manual');
  static const assignmentModeRandom =
      Key('tiki_golf_menu_assignment_mode_random');

  // Team Count dropdown (shown in Team + Manual mode)
  static const teamCountDropdown = Key('tiki_golf_menu_team_count_dropdown');

  // Max Strokes dropdown
  static const maxStrokesDropdown = Key('tiki_golf_menu_max_strokes_dropdown');

  // Mulligan switch
  static const mulliganSwitch = Key('tiki_golf_menu_mulligan_switch');

  // Team boxes (shown in Team + Manual mode)
  static Key teamBox(int teamIndex) =>
      Key('tiki_golf_menu_team_box_$teamIndex');
  static Key teamPlayerChip(int teamIndex, String playerId) =>
      Key('tiki_golf_menu_team_player_chip_${teamIndex}_$playerId');
  static Key teamAssignDropdown(String playerId) =>
      Key('tiki_golf_menu_team_assign_dropdown_$playerId');

  // Team Assignment dialog (shared TeamAssignmentDialog widget — uses shared keys)
  static const teamDialogContainer =
      Key('tiki_golf_menu_team_dialog_container');
  static Key teamDialogDropdown(String id) =>
      Key('tiki_golf_menu_team_dialog_dropdown_$id');
  static const teamDialogCancel = Key('tiki_golf_menu_team_dialog_cancel');

  // Dartboard connection info
  static const dartboardConnectionInfo =
      Key('tiki_golf_menu_dartboard_connection_info');
}

class TikiGolfGameKeys {
  // Navigation
  static const backButton = Key('tiki_golf_game_back_button');

  // Game controls
  static const skipTurnButton = Key('tiki_golf_game_skip_turn_button');
  static const mulliganButton = Key('tiki_golf_game_mulligan_button');

  // Hole info
  static const holeCounter = Key('tiki_golf_game_hole_counter');
  static const holeName = Key('tiki_golf_game_hole_name');
  static const holeImage = Key('tiki_golf_game_hole_image');
  static const targetNumber = Key('tiki_golf_game_target_number');
  static const parLabel = Key('tiki_golf_game_par_label');

  // Dart row
  static const dartRow = Key('tiki_golf_game_dart_row');
  static Key dartIndicator(int index) =>
      Key('tiki_golf_game_dart_indicator_$index');

  // Scorecard
  static const scorecard = Key('tiki_golf_game_scorecard');
  static Key scorecardCell(String playerId, int hole) =>
      Key('tiki_golf_game_scorecard_cell_${playerId}_$hole');
  static LocalKey scorecardPlayerRow(String playerId) =>
      ValueKey('tiki_golf_game_scorecard_player_row_$playerId');
  static const scorecardCaption = Key('tiki_golf_game_scorecard_caption');

  // Teams panel (Team mode)
  static const teamsPanel = Key('tiki_golf_game_teams_panel');
  static Key teamBox(String teamId) =>
      Key('tiki_golf_game_team_box_$teamId');

  // Takeout / mulligan modal
  static const removeDartsModal = Key('tiki_golf_game_remove_darts_modal');
  static const useMulliganButton = Key('tiki_golf_game_use_mulligan_button');
  static const nextPlayerButton = Key('tiki_golf_game_next_player_button');

  // Edit score / save modal
  static const editScoreButton = Key('tiki_golf_game_edit_score_button');
  static const saveGameModal = Key('tiki_golf_game_save_game_modal');
}

class TikiGolfResultsKeys {
  // Action buttons
  static const backToMenuButton = Key('tiki_golf_results_back_to_menu_button');
  static const playAgainButton = Key('tiki_golf_results_play_again_button');
  static const changeSettingsButton =
      Key('tiki_golf_results_change_settings_button');

  // Winner section
  static const winnerName = Key('tiki_golf_results_winner_name');
  static const winnerPhoto = Key('tiki_golf_results_winner_photo');
  static const winnerTeamCrest = Key('tiki_golf_results_winner_team_crest');
  static Key winnerTeamPlayer(String playerId) =>
      Key('tiki_golf_results_winner_team_player_$playerId');
  static const winnerTotal = Key('tiki_golf_results_winner_total');
  static const winnerStats = Key('tiki_golf_results_winner_stats');
  static const championHeading = Key('tiki_golf_results_champion_heading');

  // Tied-winner section (shown when multiple players/teams tie on total).
  static Key tiedWinnerPhoto(String playerId) =>
      Key('tiki_golf_results_tied_winner_photo_$playerId');
  static Key tiedWinnerName(String playerId) =>
      Key('tiki_golf_results_tied_winner_name_$playerId');
  static Key tiedWinnerTeamCrest(String teamId) =>
      Key('tiki_golf_results_tied_winner_team_crest_$teamId');

  // Scorecard
  static const finalScorecard = Key('tiki_golf_results_final_scorecard');
  static LocalKey playerRanking(int index) =>
      ValueKey('tiki_golf_results_player_ranking_$index');
  static LocalKey teamRanking(int index) =>
      ValueKey('tiki_golf_results_team_ranking_$index');
  static LocalKey teamScorecardBlock(String teamId) =>
      ValueKey('tiki_golf_results_team_scorecard_block_$teamId');
  static LocalKey teamBlockTotal(String teamId) =>
      ValueKey('tiki_golf_results_team_block_total_$teamId');

  // Scroll container
  static const scorecardsScroll = Key('tiki_golf_results_scorecards_scroll');
}
