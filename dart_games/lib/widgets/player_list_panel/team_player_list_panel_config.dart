import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../add_player/add_player_dialog_config.dart';

/// Configuration class for the team game pattern player list panel.
///
/// Controls all visual aspects of the single-list player management area
/// with optional team assignment (used by Target Tag).
class TeamPlayerListPanelConfig {
  // Container styling
  final Color containerColor;
  final double containerOpacity;
  final Color containerBorderColor;
  final Color containerBorderColorWhenReady;
  final double containerBorderWidth;
  final double containerBorderRadius;

  // Header styling
  final TextStyle headerTextStyle;
  final String headerText;
  final TextStyle headerCountStyle;
  final Color headerCountColorWhenReady;

  // Empty state
  final TextStyle emptyStateTextStyle;
  final String emptyText;

  // Add player button
  final Color addButtonColor;
  final Color addButtonForegroundColor;
  final TextStyle addButtonTextStyle;
  final IconData addButtonIcon;
  final String addButtonLabel;
  final TextStyle? emptyStateAddButtonTextStyle;

  // Player card theming
  final Color? selectedColor;
  final Color? selectedBorderColor;
  final Color? unselectedBackgroundColor;
  final Color? unselectedBorderColor;
  final TextStyle? cardNameStyle;
  final TextStyle? cardStatsStyle;
  final Color? checkIconColor;

  // Team mode UI
  final Color teamAccentColor;
  final Color assignTeamButtonColor;
  final Color assignTeamButtonForegroundColor;
  final TextStyle assignTeamButtonTextStyle;
  final String assignTeamButtonLabel;

  // Team icon styling
  final Color teamIconBorderColor;
  final Color teamIconBackgroundColor;
  final double teamIconSize;

  // Team assignment boxes
  final double teamBoxSize;
  final Color teamBoxBackgroundColor;
  final Color teamBoxBorderColor;
  final Color teamBoxActiveBorderColor;
  final TextStyle teamBoxCountStyle;
  final TextStyle teamBoxActiveCountStyle;

  // Team selection dialog
  final Color dialogBackgroundColor;
  final TextStyle dialogTitleTextStyle;
  final double dialogTeamButtonSize;
  final Color dialogTeamButtonColor;
  final Color dialogTeamButtonBorderColor;
  final Color dialogTeamButtonSelectedColor;
  final Color dialogTeamButtonSelectedBorderColor;
  final Color dialogHighlightGlowColor;
  final Color dialogFullTeamColor;
  final TextStyle dialogFullTeamTextStyle;
  final Color dialogRemoveButtonColor;
  final Color dialogCancelButtonColor;
  final Color dialogCancelBorderColor;
  final TextStyle dialogButtonTextStyle;

  // Layout
  final double soloListHeight;
  final double teamListHeight;
  final int maxPlayers;
  final int minPlayers;
  final int minPlayersTeamMode;
  final int maxTeams;
  final int maxPlayersPerTeam;

  // Team assignment label
  final String teamAssignmentLabel;
  final TextStyle teamAssignmentLabelStyle;

  // Add player dialog
  final AddPlayerDialogConfig addPlayerDialogConfig;

  const TeamPlayerListPanelConfig({
    required this.containerColor,
    this.containerOpacity = 0.85,
    required this.containerBorderColor,
    required this.containerBorderColorWhenReady,
    this.containerBorderWidth = 2,
    this.containerBorderRadius = 8,
    required this.headerTextStyle,
    this.headerText = 'Available Players',
    required this.headerCountStyle,
    required this.headerCountColorWhenReady,
    required this.emptyStateTextStyle,
    this.emptyText = 'No players yet. Add your first player!',
    required this.addButtonColor,
    required this.addButtonForegroundColor,
    required this.addButtonTextStyle,
    this.addButtonIcon = Icons.add,
    this.addButtonLabel = 'NEW PLAYER',
    this.emptyStateAddButtonTextStyle,
    this.selectedColor,
    this.selectedBorderColor,
    this.unselectedBackgroundColor,
    this.unselectedBorderColor,
    this.cardNameStyle,
    this.cardStatsStyle,
    this.checkIconColor,
    required this.teamAccentColor,
    required this.assignTeamButtonColor,
    required this.assignTeamButtonForegroundColor,
    required this.assignTeamButtonTextStyle,
    this.assignTeamButtonLabel = 'Assign team',
    required this.teamIconBorderColor,
    required this.teamIconBackgroundColor,
    this.teamIconSize = 40.0,
    this.teamBoxSize = 140.0,
    required this.teamBoxBackgroundColor,
    required this.teamBoxBorderColor,
    required this.teamBoxActiveBorderColor,
    required this.teamBoxCountStyle,
    required this.teamBoxActiveCountStyle,
    required this.dialogBackgroundColor,
    required this.dialogTitleTextStyle,
    this.dialogTeamButtonSize = 100.0,
    required this.dialogTeamButtonColor,
    required this.dialogTeamButtonBorderColor,
    required this.dialogTeamButtonSelectedColor,
    required this.dialogTeamButtonSelectedBorderColor,
    required this.dialogHighlightGlowColor,
    required this.dialogFullTeamColor,
    required this.dialogFullTeamTextStyle,
    required this.dialogRemoveButtonColor,
    required this.dialogCancelButtonColor,
    required this.dialogCancelBorderColor,
    required this.dialogButtonTextStyle,
    this.soloListHeight = 485.0,
    this.teamListHeight = 300.0,
    this.maxPlayers = 10,
    this.minPlayers = 2,
    this.minPlayersTeamMode = 3,
    this.maxTeams = 5,
    this.maxPlayersPerTeam = 2,
    this.teamAssignmentLabel = 'Team Assignment',
    required this.teamAssignmentLabelStyle,
    required this.addPlayerDialogConfig,
  });

  /// Target Tag theme — Hot Pink primary, Neon Green team accent, Fredoka font,
  /// dark navy backgrounds.
  factory TeamPlayerListPanelConfig.targetTag() {
    return TeamPlayerListPanelConfig(
      containerColor: const Color(0xFF2A2A3E),
      containerOpacity: 0.85,
      containerBorderColor: Colors.white24,
      containerBorderColorWhenReady: const Color(0xFFFF007A),
      containerBorderWidth: 2,
      headerTextStyle: GoogleFonts.fredoka(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      headerCountStyle: GoogleFonts.fredoka(
        fontSize: 14,
        color: Colors.white60,
      ),
      headerCountColorWhenReady: const Color(0xFF00FFA3),
      emptyStateTextStyle: GoogleFonts.fredoka(
        color: Colors.white70,
        fontSize: 14,
      ),
      addButtonColor: const Color(0xFFFF007A),
      addButtonForegroundColor: Colors.white,
      addButtonTextStyle: GoogleFonts.fredoka(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.0,
      ),
      emptyStateAddButtonTextStyle: GoogleFonts.fredoka(
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
      selectedColor: const Color(0xFFFF007A),
      selectedBorderColor: const Color(0xFFFF007A),
      checkIconColor: const Color(0xFF00FFA3),
      teamAccentColor: const Color(0xFF00FFA3),
      assignTeamButtonColor: const Color(0xFFFF007A),
      assignTeamButtonForegroundColor: Colors.white,
      assignTeamButtonTextStyle: GoogleFonts.fredoka(
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
      teamIconBorderColor: const Color(0xFF00FFA3),
      teamIconBackgroundColor: const Color(0xFF1A1A2E),
      teamIconSize: 40.0,
      teamBoxSize: 140.0,
      teamBoxBackgroundColor: const Color(0xFF1A1A2E),
      teamBoxBorderColor: Colors.white24,
      teamBoxActiveBorderColor: const Color(0xFF00FFA3),
      teamBoxCountStyle: GoogleFonts.fredoka(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.white38,
      ),
      teamBoxActiveCountStyle: GoogleFonts.fredoka(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF00FFA3),
      ),
      dialogBackgroundColor: const Color(0xFF1A1A2E).withOpacity(0.95),
      dialogTitleTextStyle: GoogleFonts.fredoka(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      dialogTeamButtonSize: 100.0,
      dialogTeamButtonColor: const Color(0xFF2A2A3E),
      dialogTeamButtonBorderColor: Colors.white24,
      dialogTeamButtonSelectedColor: const Color(0xFF00FFA3),
      dialogTeamButtonSelectedBorderColor: const Color(0xFF00FFA3),
      dialogHighlightGlowColor: const Color(0xFF00FFA3),
      dialogFullTeamColor: Colors.red,
      dialogFullTeamTextStyle: GoogleFonts.fredoka(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      dialogRemoveButtonColor: Colors.red,
      dialogCancelButtonColor: const Color(0xFF2A2A3E),
      dialogCancelBorderColor: Colors.white38,
      dialogButtonTextStyle: GoogleFonts.fredoka(
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
      teamAssignmentLabelStyle: GoogleFonts.fredoka(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      maxPlayers: 10,
      minPlayers: 2,
      minPlayersTeamMode: 3,
      maxTeams: 5,
      maxPlayersPerTeam: 2,
      addPlayerDialogConfig: AddPlayerDialogConfig.targetTag(),
    );
  }
}
