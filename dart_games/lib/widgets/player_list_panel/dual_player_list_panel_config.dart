import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/game_theme.dart';
import '../add_player/add_player_dialog_config.dart';

/// Configuration class controlling all visual aspects of the dual-list
/// player management area (Available Players + Selected Players).
class DualPlayerListPanelConfig {
  // Container styling
  final Color containerColor;
  final double containerOpacity;
  final Color containerBorderColor;
  final double containerBorderWidth;
  final double containerBorderRadius;

  // Header styling
  final TextStyle headerTextStyle;
  final String availableHeaderText;
  final String selectedHeaderText;

  // Selected section dynamic border
  final Color? selectedBorderColorWhenReady;
  final double? selectedBorderWidthWhenReady;
  final int minPlayersForReady;

  // Selected header dynamic color
  final Color? selectedHeaderColorWhenReady;

  // Empty state
  final TextStyle emptyStateTextStyle;
  final String availableEmptyText;
  final String selectedEmptyText;

  // Add player button
  final Color addButtonColor;
  final Color addButtonForegroundColor;
  final BorderSide? addButtonBorderSide;
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
  final Color? removeIconColor;
  final double? nameStatsSpacing;

  // Layout
  final EdgeInsets availableContainerMargin;
  final EdgeInsets selectedContainerMargin;
  final double listGap;
  final int maxPlayers;

  // Add player dialog
  final AddPlayerDialogConfig addPlayerDialogConfig;

  const DualPlayerListPanelConfig({
    required this.containerColor,
    this.containerOpacity = 0.85,
    required this.containerBorderColor,
    this.containerBorderWidth = 1,
    this.containerBorderRadius = 8,
    required this.headerTextStyle,
    this.availableHeaderText = 'Available Players',
    this.selectedHeaderText = 'Selected Players',
    this.selectedBorderColorWhenReady,
    this.selectedBorderWidthWhenReady,
    this.minPlayersForReady = 2,
    this.selectedHeaderColorWhenReady,
    required this.emptyStateTextStyle,
    this.availableEmptyText = 'No players yet. Add your first player!',
    this.selectedEmptyText = 'Select at least 1 player',
    required this.addButtonColor,
    required this.addButtonForegroundColor,
    this.addButtonBorderSide,
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
    this.removeIconColor,
    this.nameStatsSpacing,
    this.availableContainerMargin = const EdgeInsets.only(left: 16.0),
    this.selectedContainerMargin = const EdgeInsets.only(right: 16.0),
    this.listGap = 16,
    this.maxPlayers = 8,
    required this.addPlayerDialogConfig,
  });

  /// Carnival Derby theme — Navy containers, off-white borders, Lava Red add
  /// button with Canary Yellow border, Bangers font, Montserrat headers.
  factory DualPlayerListPanelConfig.carnivalDerby() {
    return DualPlayerListPanelConfig(
      containerColor: GameTheme.carnivalDerby.background,
      containerOpacity: 0.85,
      containerBorderColor: GameTheme.carnivalDerby.onDark,
      containerBorderWidth: 1,
      headerTextStyle: GoogleFonts.montserrat(
        fontSize: 16,
        color: GameTheme.carnivalDerby.onDark,
        fontWeight: FontWeight.w900,
      ),
      emptyStateTextStyle: GoogleFonts.montserrat(
        color: GameTheme.carnivalDerby.onDark,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      selectedEmptyText: 'Select at least 1 player',
      addButtonColor: const Color(0xFFE63946),
      addButtonForegroundColor: GameTheme.carnivalDerby.onDark,
      addButtonBorderSide: const BorderSide(
        color: Color(0xFFFFD700),
        width: 3,
      ),
      addButtonTextStyle: GoogleFonts.bangers(
        fontSize: 12,
        letterSpacing: 1.0,
        color: GameTheme.carnivalDerby.onDark,
      ),
      emptyStateAddButtonTextStyle: GoogleFonts.bangers(
        fontSize: 16,
        letterSpacing: 1.0,
        color: GameTheme.carnivalDerby.onDark,
      ),
      maxPlayers: 8,
      addPlayerDialogConfig: AddPlayerDialogConfig.carnivalDerby(),
    );
  }

  /// Monster Mash theme — Dark slate containers, beige borders, PirataOne
  /// headers, purple selected/lime border cards, Creepster card names.
  factory DualPlayerListPanelConfig.monsterMash() {
    return DualPlayerListPanelConfig(
      containerColor: GameTheme.monsterMash.background,
      containerOpacity: 0.80,
      containerBorderColor: Color(0xFFF5F5DC).withOpacity(0.3),
      containerBorderWidth: 1,
      headerTextStyle: GoogleFonts.pirataOne(
        fontSize: 22,
        color: GameTheme.monsterMash.onDark,
      ),
      selectedBorderColorWhenReady: GameTheme.monsterMash.accent,
      selectedBorderWidthWhenReady: 2,
      minPlayersForReady: 2,
      selectedHeaderColorWhenReady: GameTheme.monsterMash.accent,
      emptyStateTextStyle: GoogleFonts.montserrat(
        color: Color(0xFFF5F5DC).withOpacity(0.7),
        fontSize: 20,
      ),
      selectedEmptyText: 'Select at least 2 players',
      addButtonColor: GameTheme.monsterMash.background,
      addButtonForegroundColor: GameTheme.monsterMash.onDark,
      addButtonTextStyle: GoogleFonts.pirataOne(
        fontSize: 18,
        color: GameTheme.monsterMash.onDark,
      ),
      selectedColor: const Color(0xFF4B0082),
      selectedBorderColor: GameTheme.monsterMash.accent,
      unselectedBackgroundColor: const Color(0xFF1D3557),
      unselectedBorderColor: const Color(0xFF48CAE4),
      cardNameStyle: GoogleFonts.creepster(
        fontSize: 21,
        color: const Color(0xFFF1FAEE),
        shadows: [
          Shadow(
            color: const Color(0xFFF1FAEE).withOpacity(0.4),
            blurRadius: 8,
          ),
          const Shadow(
            color: Colors.black,
            blurRadius: 3,
            offset: Offset(1, 1),
          ),
        ],
      ),
      nameStatsSpacing: 1.4,
      maxPlayers: 8,
      availableContainerMargin: EdgeInsets.zero,
      selectedContainerMargin: EdgeInsets.zero,
      addPlayerDialogConfig: AddPlayerDialogConfig.monsterMash(),
    );
  }

  /// Reef Royale theme — Deep Reef Blue containers, Seafoam Green accents,
  /// Fredoka headers, Pearl White text.
  factory DualPlayerListPanelConfig.reefRoyale() {
    return DualPlayerListPanelConfig(
      containerColor: GameTheme.reefRoyale.background,
      containerOpacity: 0.85,
      containerBorderColor: GameTheme.reefRoyale.accent.withOpacity(0.3),
      containerBorderWidth: 1,
      headerTextStyle: GoogleFonts.fredoka(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: GameTheme.reefRoyale.onDark,
      ),
      selectedBorderColorWhenReady: GameTheme.reefRoyale.accent,
      selectedBorderWidthWhenReady: 2,
      minPlayersForReady: 2,
      selectedHeaderColorWhenReady: GameTheme.reefRoyale.accent,
      emptyStateTextStyle: GoogleFonts.nunito(
        color: GameTheme.reefRoyale.onDark.withOpacity(0.7),
        fontSize: 20,
      ),
      selectedEmptyText: 'Select at least 2 players',
      addButtonColor: GameTheme.reefRoyale.background,
      addButtonForegroundColor: GameTheme.reefRoyale.onDark,
      addButtonTextStyle: GoogleFonts.fredoka(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: GameTheme.reefRoyale.onDark,
      ),
      selectedColor: GameTheme.reefRoyale.accent.withOpacity(0.2),
      selectedBorderColor: GameTheme.reefRoyale.accent,
      unselectedBackgroundColor: GameTheme.reefRoyale.background.withOpacity(0.6),
      unselectedBorderColor: GameTheme.reefRoyale.accent.withOpacity(0.3),
      cardNameStyle: GoogleFonts.fredoka(
        fontSize: 21,
        fontWeight: FontWeight.bold,
        color: GameTheme.reefRoyale.onDark,
      ),
      nameStatsSpacing: 1.4,
      maxPlayers: 8,
      availableContainerMargin: EdgeInsets.zero,
      selectedContainerMargin: EdgeInsets.zero,
      listGap: 8,
      addPlayerDialogConfig: AddPlayerDialogConfig.reefRoyale(),
    );
  }

  /// Lunar Lander theme — Earth Blue containers, Rocket Flame accents, Orbitron/Exo2 fonts
  factory DualPlayerListPanelConfig.lunarLander() {
    return DualPlayerListPanelConfig(
      containerColor: GameTheme.lunarLander.background, // Earth Blue
      containerOpacity: 0.85,
      containerBorderColor: GameTheme.lunarLander.accent.withOpacity(0.5), // Rocket Flame
      containerBorderWidth: 2,
      headerTextStyle: GoogleFonts.orbitron(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: GameTheme.lunarLander.accent, // Rocket Flame
        letterSpacing: 1.0,
      ),
      selectedBorderColorWhenReady: GameTheme.lunarLander.accent,
      selectedBorderWidthWhenReady: 2,
      minPlayersForReady: 2,
      selectedHeaderColorWhenReady: GameTheme.lunarLander.accent,
      emptyStateTextStyle: GoogleFonts.exo2(
        color: GameTheme.lunarLander.onDark.withOpacity(0.7),
        fontSize: 16,
      ),
      selectedEmptyText: 'Select at least 2 players',
      addButtonColor: GameTheme.lunarLander.background,
      addButtonForegroundColor: GameTheme.lunarLander.onDark,
      addButtonBorderSide: const BorderSide(
        color: Color(0xFFF26430), // Rocket Flame
        width: 2,
      ),
      addButtonTextStyle: GoogleFonts.orbitron(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: GameTheme.lunarLander.onDark,
        letterSpacing: 0.5,
      ),
      selectedColor: GameTheme.lunarLander.accent.withOpacity(0.2),
      selectedBorderColor: GameTheme.lunarLander.accent,
      unselectedBackgroundColor: GameTheme.lunarLander.background.withOpacity(0.6),
      unselectedBorderColor: GameTheme.lunarLander.accent.withOpacity(0.3),
      cardNameStyle: GoogleFonts.exo2(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: GameTheme.lunarLander.onDark,
      ),
      nameStatsSpacing: 1.4,
      maxPlayers: 8,
      availableContainerMargin: EdgeInsets.zero,
      selectedContainerMargin: EdgeInsets.zero,
      listGap: 8,
      addPlayerDialogConfig: AddPlayerDialogConfig.lunarLander(),
    );
  }

  /// Pirate's Grid theme — Ocean Navy containers, Compass Bronze accents, PirataOne/Lora fonts
  /// Exactly 2 players (no team mode).
  factory DualPlayerListPanelConfig.piratesGrid() {
    return DualPlayerListPanelConfig(
      containerColor: GameTheme.piratesGrid.background, // Ocean Navy
      containerOpacity: 0.85,
      containerBorderColor: GameTheme.piratesGrid.accent.withOpacity(0.5), // Compass Bronze
      containerBorderWidth: 2,
      headerTextStyle: GoogleFonts.pirataOne(
        fontSize: 22,
        color: const Color(0xFFDAA520), // Treasure Gold
        letterSpacing: 1.0,
      ),
      selectedBorderColorWhenReady: const Color(0xFFDAA520), // Treasure Gold
      selectedBorderWidthWhenReady: 2,
      minPlayersForReady: 2,
      selectedHeaderColorWhenReady: const Color(0xFFDAA520),
      emptyStateTextStyle: GoogleFonts.lora(
        color: GameTheme.piratesGrid.onDark.withOpacity(0.7),
        fontSize: 16,
      ),
      selectedEmptyText: 'Select exactly 2 players',
      addButtonColor: GameTheme.piratesGrid.background,
      addButtonForegroundColor: GameTheme.piratesGrid.onDark,
      addButtonBorderSide: const BorderSide(
        color: Color(0xFFCD7F32), // Compass Bronze
        width: 2,
      ),
      addButtonTextStyle: GoogleFonts.pirataOne(
        fontSize: 16,
        color: GameTheme.piratesGrid.onDark,
        letterSpacing: 0.5,
      ),
      selectedColor: GameTheme.piratesGrid.accent.withOpacity(0.2),
      selectedBorderColor: GameTheme.piratesGrid.accent,
      unselectedBackgroundColor: GameTheme.piratesGrid.background.withOpacity(0.6),
      unselectedBorderColor: GameTheme.piratesGrid.accent.withOpacity(0.3),
      cardNameStyle: GoogleFonts.lora(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: GameTheme.piratesGrid.onDark,
      ),
      nameStatsSpacing: 1.4,
      maxPlayers: 2,
      availableContainerMargin: EdgeInsets.zero,
      selectedContainerMargin: EdgeInsets.zero,
      listGap: 6,
      addPlayerDialogConfig: AddPlayerDialogConfig.piratesGrid(),
    );
  }

  /// Gladiator Arena theme — Arena Sand containers, Bronze/Gold accents, Cinzel/Lato fonts
  factory DualPlayerListPanelConfig.gladiatorArena() {
    return DualPlayerListPanelConfig(
      containerColor: const Color(0xFF4A3520), // Dark Arena Brown
      containerOpacity: 0.85,
      containerBorderColor: GameTheme.gladiatorArena.accent.withOpacity(0.5), // Bronze
      containerBorderWidth: 2,
      headerTextStyle: GoogleFonts.cinzel(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: const Color(0xFFDAA520), // Gladiator Gold
        letterSpacing: 1.0,
      ),
      selectedBorderColorWhenReady: const Color(0xFFDAA520), // Gladiator Gold
      selectedBorderWidthWhenReady: 2,
      minPlayersForReady: 2,
      selectedHeaderColorWhenReady: const Color(0xFFDAA520), // Gladiator Gold
      emptyStateTextStyle: GoogleFonts.lato(
        color: GameTheme.gladiatorArena.onDark.withOpacity(0.7), // Marble White
        fontSize: 16,
      ),
      selectedEmptyText: 'Select at least 2 gladiators',
      addButtonColor: const Color(0xFF4A3520),
      addButtonForegroundColor: GameTheme.gladiatorArena.onDark,
      addButtonBorderSide: const BorderSide(
        color: Color(0xFFCD7F32), // Bronze
        width: 2,
      ),
      addButtonTextStyle: GoogleFonts.cinzel(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: GameTheme.gladiatorArena.onDark,
        letterSpacing: 0.5,
      ),
      selectedColor: const Color(0xFFDAA520).withOpacity(0.2),
      selectedBorderColor: const Color(0xFFDAA520), // Gladiator Gold
      unselectedBackgroundColor: const Color(0xFF4A3520).withOpacity(0.6),
      unselectedBorderColor: GameTheme.gladiatorArena.accent.withOpacity(0.3),
      cardNameStyle: GoogleFonts.cinzel(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: GameTheme.gladiatorArena.onDark, // Marble White
        letterSpacing: 0.5,
      ),
      cardStatsStyle: GoogleFonts.lato(
        fontSize: 13,
        color: GameTheme.gladiatorArena.onDark,
      ),
      checkIconColor: const Color(0xFFDAA520), // Gladiator Gold
      removeIconColor: const Color(0xFFC0392B), // Blood Red
      nameStatsSpacing: 1.4,
      maxPlayers: 8,
      availableContainerMargin: EdgeInsets.zero,
      selectedContainerMargin: EdgeInsets.zero,
      // listGap deliberately set to 4 (not 8) to compensate for the
      // hardcoded EdgeInsets.all(16.0) inside each section in the SHARED
      // widget — that 16px inner padding makes the visible "gap" between
      // the two lists' content (player tiles) appear wider than the
      // 8px gap between the options-row option boxes (which now use
      // EdgeInsets.symmetric(horizontal: 16, vertical: 8)). Keeping
      // listGap at 4 brings the visible BOX-to-BOX gap closer to what
      // the user perceives as matching the options-row gap.
      listGap: 4,
      addPlayerDialogConfig: AddPlayerDialogConfig.gladiatorArena(),
    );
  }

  factory DualPlayerListPanelConfig.clockworkQuest() {
    return DualPlayerListPanelConfig(
      containerColor: GameTheme.clockworkQuest.background, // Dark Iron
      containerOpacity: 0.80,
      containerBorderColor: const Color(0xFFB87333).withOpacity(0.3), // Copper Rose
      containerBorderWidth: 1,
      headerTextStyle: GoogleFonts.cinzelDecorative(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: GameTheme.clockworkQuest.accent, // Brass Gold
        letterSpacing: 1.2,
      ),
      selectedBorderColorWhenReady: GameTheme.clockworkQuest.accent,
      selectedBorderWidthWhenReady: 2,
      minPlayersForReady: 2,
      selectedHeaderColorWhenReady: GameTheme.clockworkQuest.accent,
      emptyStateTextStyle: GoogleFonts.lato(
        color: GameTheme.clockworkQuest.onDark.withOpacity(0.7),
        fontSize: 16,
      ),
      selectedEmptyText: 'Select at least 2 players',
      addButtonColor: GameTheme.clockworkQuest.background,
      addButtonForegroundColor: GameTheme.clockworkQuest.onDark,
      addButtonTextStyle: GoogleFonts.cinzelDecorative(
        fontSize: 14,
        color: GameTheme.clockworkQuest.onDark,
      ),
      selectedColor: GameTheme.clockworkQuest.accent.withOpacity(0.2),
      selectedBorderColor: GameTheme.clockworkQuest.accent,
      unselectedBackgroundColor: GameTheme.clockworkQuest.background.withOpacity(0.6),
      unselectedBorderColor: const Color(0xFFB87333).withOpacity(0.3),
      cardNameStyle: GoogleFonts.cinzelDecorative(
        fontSize: 21,
        fontWeight: FontWeight.bold,
        color: GameTheme.clockworkQuest.onDark,
        letterSpacing: 1.0,
      ),
      cardStatsStyle: GoogleFonts.lato(
        fontSize: 13,
        color: GameTheme.clockworkQuest.onDark,
      ),
      nameStatsSpacing: 1.4,
      maxPlayers: 8,
      availableContainerMargin: EdgeInsets.zero,
      selectedContainerMargin: EdgeInsets.zero,
      listGap: 8,
      addPlayerDialogConfig: AddPlayerDialogConfig.clockworkQuest(),
    );
  }
}
