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
  /// Optional cap for solo mode (no team assignment). When null, [maxPlayers]
  /// is used for both modes. Used by Tiki Golf where Solo = 4, Team = 16.
  final int? maxPlayersSoloMode;
  final int minPlayers;
  final int minPlayersTeamMode;
  final int maxTeams;
  final int maxPlayersPerTeam;

  /// Optional horizontal/vertical inset applied to the header row only
  /// (the row containing the section label, count chip, and ADD PLAYER
  /// button). Defaults to no padding. Used by Tiki Golf so the header
  /// content aligns with option labels/values that sit inside option-box
  /// padding. Does NOT affect the player list row layout.
  final EdgeInsetsGeometry? headerPadding;

  /// When true (default), shows the [teamAssignmentLabel] text above the
  /// team-assignment boxes in Manual team mode. Tiki Golf sets this false
  /// because the boxes themselves are self-explanatory.
  final bool showTeamAssignmentLabel;

  /// Optional fixed width for the TeamAssignmentDialog content area.
  /// Defaults to 400 when null. Games with larger [dialogTeamButtonSize]
  /// or more teams may need to override this so all team badges fit in a
  /// single row inside the dialog's Wrap.
  final double? dialogContentWidth;

  /// Layout direction for each team-assignment box (badge + player count).
  /// [Axis.vertical] (default) stacks the count below the badge.
  /// [Axis.horizontal] places the count to the right of the badge.
  final Axis teamBoxLayout;

  /// Vertical spacing (px) above the team-assignment boxes row in Manual
  /// team mode. Defaults to 16. Games where the team boxes feel too far
  /// from the player list above can tighten this.
  final double teamBoxesTopSpacing;

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
    this.maxPlayersSoloMode,
    this.minPlayers = 2,
    this.minPlayersTeamMode = 3,
    this.maxTeams = 5,
    this.maxPlayersPerTeam = 2,
    this.headerPadding,
    this.showTeamAssignmentLabel = true,
    this.dialogContentWidth,
    this.teamBoxLayout = Axis.vertical,
    this.teamBoxesTopSpacing = 16.0,
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

  /// Treasure Divide theme — Ocean Teal primary, Treasure Gold accent, PirataOne/Merriweather fonts.
  ///
  /// Solo: 2-8 players. Team: 3-10 players across 2-5 crews of 2 (doubles format).
  /// Crews are identified by crest image only — no crew name labels (Rule §62/§63).
  factory TeamPlayerListPanelConfig.treasureDivide() {
    return TeamPlayerListPanelConfig(
      containerColor: const Color(0xFF008B8B), // Ocean Teal
      containerOpacity: 0.85,
      containerBorderColor: const Color(0xFF8B6914), // Plank Brown
      containerBorderColorWhenReady: const Color(0xFFFFD700), // Treasure Gold
      containerBorderWidth: 2,
      headerTextStyle: GoogleFonts.pirataOne(
        fontSize: 22,
        color: const Color(0xFFFFF8E7), // Sail White
        letterSpacing: 0.5,
        shadows: const [
          // Hard black drop shadow for legibility against any background
          Shadow(color: Color(0xCC000000), offset: Offset(2, 2), blurRadius: 4),
          // Soft Ocean Teal halo to anchor it to the brand
          Shadow(color: Color(0xAA008B8B), offset: Offset(0, 0), blurRadius: 10),
        ],
      ),
      headerCountStyle: GoogleFonts.merriweather(
        fontSize: 16,
        color: const Color(0xFFFFF8E7),
        shadows: const [
          Shadow(color: Color(0xCC000000), offset: Offset(1, 1), blurRadius: 3),
          Shadow(color: Color(0xAA008B8B), offset: Offset(0, 0), blurRadius: 6),
        ],
      ),
      headerCountColorWhenReady: const Color(0xFFFFD700), // Treasure Gold
      emptyStateTextStyle: GoogleFonts.merriweather(
        color: const Color(0xFFFFF8E7).withOpacity(0.7),
        fontSize: 14,
      ),
      addButtonColor: const Color(0xFFFFD700), // Treasure Gold
      addButtonForegroundColor: const Color(0xFF008B8B), // Ocean Teal
      addButtonTextStyle: GoogleFonts.merriweather(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
      emptyStateAddButtonTextStyle: GoogleFonts.merriweather(
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
      selectedColor: const Color(0xFFFFD700), // Treasure Gold
      selectedBorderColor: const Color(0xFFFFD700), // Treasure Gold
      checkIconColor: const Color(0xFF228B22), // Island Green
      teamAccentColor: const Color(0xFFFFD700), // Treasure Gold
      assignTeamButtonColor: const Color(0xFFFFD700), // Treasure Gold
      assignTeamButtonForegroundColor: const Color(0xFF008B8B), // Ocean Teal
      assignTeamButtonTextStyle: GoogleFonts.merriweather(
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
      // Crew identification: crest image only — no container chrome (Rule §63)
      teamIconBorderColor: Colors.transparent,
      teamIconBackgroundColor: Colors.transparent,
      teamIconSize: 40.0,
      // Setup-screen crest boxes doubled from 64 so the shields feel
      // like real ship crests instead of postage-stamps.
      teamBoxSize: 128.0,
      teamBoxBackgroundColor: Colors.transparent, // no box around the crest
      teamBoxBorderColor: Colors.transparent,
      teamBoxActiveBorderColor: Colors.transparent,
      // Player-count text — PirataOne + the SAME hard-black drop +
      // teal-glow stack that headerTextStyle ("Available Players")
      // uses so the number reads with equal weight against the wood
      // BG. Merriweather-with-lighter-shadows didn't pop; the pirate
      // font + full-strength shadows do. Bumped 18→22 (headerText's
      // size) so the count physically matches the header rhythm.
      teamBoxCountStyle: GoogleFonts.pirataOne(
        fontSize: 22,
        color: const Color(0xFFFFF8E7).withOpacity(0.85),
        letterSpacing: 0.5,
        shadows: const [
          Shadow(color: Color(0xCC000000), offset: Offset(2, 2), blurRadius: 4),
          Shadow(color: Color(0xAA008B8B), offset: Offset(0, 0), blurRadius: 10),
        ],
      ),
      teamBoxActiveCountStyle: GoogleFonts.pirataOne(
        fontSize: 22,
        color: const Color(0xFFFFD700), // Treasure Gold
        letterSpacing: 0.5,
        shadows: const [
          Shadow(color: Color(0xCC000000), offset: Offset(2, 2), blurRadius: 4),
          Shadow(color: Color(0xAA008B8B), offset: Offset(0, 0), blurRadius: 10),
        ],
      ),
      dialogBackgroundColor: const Color(0xFF008B8B).withOpacity(0.97), // Ocean Teal
      dialogTitleTextStyle: GoogleFonts.pirataOne(
        fontSize: 20,
        color: const Color(0xFFFFF8E7), // Sail White
        letterSpacing: 0.5,
      ),
      // Manual-team dialog shields doubled from 64. Width tuned so the
      // 5 max crests wrap 3 + 2 (top row 3, bottom row 2) — reads more
      // balanced than 4+1. Math:
      //   3 badges: 3×128 + 2×16 = 416 (fits in 480)
      //   4 badges: 4×128 + 3×16 = 560 (does NOT fit in 480 → wraps)
      dialogTeamButtonSize: 128.0,
      dialogContentWidth: 480.0,
      dialogTeamButtonColor: Colors.transparent,
      dialogTeamButtonBorderColor: Colors.transparent,
      dialogTeamButtonSelectedColor: const Color(0xFFFFD700), // Treasure Gold
      dialogTeamButtonSelectedBorderColor: const Color(0xFFFFD700),
      dialogHighlightGlowColor: const Color(0xFFFFD700), // Treasure Gold
      dialogFullTeamColor: const Color(0xFFC41E3A), // Blood Red
      dialogFullTeamTextStyle: GoogleFonts.merriweather(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: const Color(0xFFFFF8E7),
      ),
      dialogRemoveButtonColor: const Color(0xFFC41E3A), // Blood Red
      dialogCancelButtonColor: const Color(0xFF8B6914), // Plank Brown
      dialogCancelBorderColor: const Color(0xFF8B6914).withOpacity(0.5),
      dialogButtonTextStyle: GoogleFonts.merriweather(
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
      teamAssignmentLabelStyle: GoogleFonts.pirataOne(
        fontSize: 18,
        color: const Color(0xFFFFF8E7), // Sail White
      ),
      // Hide team assignment label per Rule §62 — crests self-identify
      showTeamAssignmentLabel: false,
      maxPlayers: 10, // Team max
      maxPlayersSoloMode: 8, // Solo max
      minPlayers: 2,
      minPlayersTeamMode: 3,
      maxTeams: 5,
      maxPlayersPerTeam: 2,
      addPlayerDialogConfig: AddPlayerDialogConfig.treasureDivide(),
    );
  }

  /// Tiki Golf theme — Palm Green primary, Lagoon Blue accent, Boogaloo/Nunito fonts.
  ///
  /// Solo mode caps at 4 players (maxPlayersSoloMode: 4).
  /// Team mode supports up to 16 players across 2-4 teams of up to 4 players each.
  factory TeamPlayerListPanelConfig.tikiGolf() {
    return TeamPlayerListPanelConfig(
      containerColor: const Color(0xFF2D6A4F), // Palm Green
      containerOpacity: 0.85,
      containerBorderColor: const Color(0xFF8B5E3C), // Tiki Brown
      containerBorderColorWhenReady: const Color(0xFF00B4D8), // Lagoon Blue
      containerBorderWidth: 2,
      headerTextStyle: GoogleFonts.boogaloo(
        fontSize: 20, // +2 from 18 per user feedback
        color: const Color(0xFFFFF5E1), // Sand White
      ),
      headerCountStyle: GoogleFonts.nunito(
        fontSize: 14,
        color: const Color(0xFFFFF5E1).withOpacity(0.7),
      ),
      headerCountColorWhenReady: const Color(0xFFFF8C42), // Tropical Orange
      emptyStateTextStyle: GoogleFonts.nunito(
        color: const Color(0xFFFFF5E1).withOpacity(0.7),
        fontSize: 14,
      ),
      addButtonColor: const Color(0xFF00B4D8), // Lagoon Blue
      addButtonForegroundColor: const Color(0xFFFFF5E1), // Sand White
      addButtonTextStyle: GoogleFonts.boogaloo(
        fontSize: 14,
        letterSpacing: 0.5,
      ),
      emptyStateAddButtonTextStyle: GoogleFonts.boogaloo(
        fontSize: 16,
      ),
      selectedColor: const Color(0xFF00B4D8), // Lagoon Blue
      selectedBorderColor: const Color(0xFF00B4D8), // Lagoon Blue
      checkIconColor: const Color(0xFFFF8C42), // Tropical Orange
      teamAccentColor: const Color(0xFFFF8C42), // Tropical Orange
      assignTeamButtonColor: const Color(0xFF00B4D8), // Lagoon Blue
      assignTeamButtonForegroundColor: const Color(0xFFFFF5E1),
      assignTeamButtonTextStyle: GoogleFonts.nunito(
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
      // Player-tile trailing crest icon — no container chrome per user;
      // the badge image renders directly inside the tile.
      teamIconBorderColor: Colors.transparent,
      teamIconBackgroundColor: Colors.transparent,
      teamIconSize: 44.0, // +10% from 40px per user
      teamBoxSize: 163.0, // +15% from 142px per user; badges only
      teamBoxBackgroundColor: Colors.transparent, // no box around the badge
      teamBoxBorderColor: Colors.transparent,
      teamBoxActiveBorderColor: Colors.transparent,
      teamBoxCountStyle: GoogleFonts.nunito(
        fontSize: 18, // +2pt from 16 per user
        fontWeight: FontWeight.bold,
        color: const Color(0xFFFFF5E1).withOpacity(0.5),
      ),
      teamBoxActiveCountStyle: GoogleFonts.nunito(
        fontSize: 18, // +2pt from 16 per user
        fontWeight: FontWeight.bold,
        color: const Color(0xFFFF8C42), // Tropical Orange
      ),
      dialogBackgroundColor: const Color(0xFF2D6A4F).withOpacity(0.97), // Palm Green
      dialogTitleTextStyle: GoogleFonts.boogaloo(
        fontSize: 20,
        color: const Color(0xFFFFF5E1), // Sand White
      ),
      dialogTeamButtonSize: 163.0, // +25% from 130px per user
      // Dialog team-pick buttons — no container chrome in default state per user;
      // the badge image renders directly. Selected + highlighted states still
      // show via their own border colors below.
      dialogTeamButtonColor: Colors.transparent,
      dialogTeamButtonBorderColor: Colors.transparent,
      // Wider dialog so all 4 team badges fit on a single row at the larger
      // button size: 4 × 163 + 5 × 16 spacing = 732px.
      dialogContentWidth: 760.0,
      dialogTeamButtonSelectedColor: const Color(0xFF00B4D8), // Lagoon Blue
      dialogTeamButtonSelectedBorderColor: const Color(0xFF00B4D8),
      dialogHighlightGlowColor: const Color(0xFF00B4D8),
      dialogFullTeamColor: const Color(0xFFFF69B4), // Hibiscus Pink
      dialogFullTeamTextStyle: GoogleFonts.nunito(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: const Color(0xFFFFF5E1),
      ),
      dialogRemoveButtonColor: const Color(0xFFFF69B4), // Hibiscus Pink
      dialogCancelButtonColor: const Color(0xFF8B5E3C), // Tiki Brown
      dialogCancelBorderColor: const Color(0xFF8B5E3C).withOpacity(0.5),
      dialogButtonTextStyle: GoogleFonts.nunito(
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
      teamAssignmentLabelStyle: GoogleFonts.boogaloo(
        fontSize: 18,
        color: const Color(0xFFFFF5E1), // Sand White
      ),
      maxPlayers: 16,
      maxPlayersSoloMode: 4, // Rule §48: Solo mode caps at 4 players
      minPlayers: 2,
      minPlayersTeamMode: 3,
      maxTeams: 4,
      // 12px horizontal inset on the header row only — aligns "Available
      // Players" label and the ADD PLAYER button with the option labels /
      // values above (which sit inside the option-box 12px padding).
      headerPadding: const EdgeInsets.symmetric(horizontal: 12),
      // Hide the "Team Assignment" label above the team boxes per user —
      // the team badges themselves are self-explanatory.
      showTeamAssignmentLabel: false,
      // Player count appears to the RIGHT of each team badge (not below),
      // which also tightens each team box's vertical footprint.
      teamBoxLayout: Axis.horizontal,
      // Tighter gap above the team boxes — matches the small visual gap
      // below them at the bottom of the player panel.
      teamBoxesTopSpacing: 8.0,
      maxPlayersPerTeam: 4,
      addPlayerDialogConfig: AddPlayerDialogConfig.tikiGolf(),
    );
  }
}
