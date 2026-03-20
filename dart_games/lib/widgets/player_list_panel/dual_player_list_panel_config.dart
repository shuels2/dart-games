import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
      containerColor: const Color(0xFF1D3557),
      containerOpacity: 0.85,
      containerBorderColor: const Color(0xFFF1FAEE),
      containerBorderWidth: 1,
      headerTextStyle: GoogleFonts.montserrat(
        fontSize: 16,
        color: const Color(0xFFF1FAEE),
        fontWeight: FontWeight.w900,
      ),
      emptyStateTextStyle: GoogleFonts.montserrat(
        color: const Color(0xFFF1FAEE),
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      selectedEmptyText: 'Select at least 1 player',
      addButtonColor: const Color(0xFFE63946),
      addButtonForegroundColor: const Color(0xFFF1FAEE),
      addButtonBorderSide: const BorderSide(
        color: Color(0xFFFFD700),
        width: 3,
      ),
      addButtonTextStyle: GoogleFonts.bangers(
        fontSize: 12,
        letterSpacing: 1.0,
        color: const Color(0xFFF1FAEE),
      ),
      emptyStateAddButtonTextStyle: GoogleFonts.bangers(
        fontSize: 16,
        letterSpacing: 1.0,
        color: const Color(0xFFF1FAEE),
      ),
      maxPlayers: 8,
      addPlayerDialogConfig: AddPlayerDialogConfig.carnivalDerby(),
    );
  }

  /// Monster Mash theme — Dark slate containers, beige borders, PirataOne
  /// headers, purple selected/lime border cards, Creepster card names.
  factory DualPlayerListPanelConfig.monsterMash() {
    return DualPlayerListPanelConfig(
      containerColor: const Color(0xFF2F4F4F),
      containerOpacity: 0.80,
      containerBorderColor: Color(0xFFF5F5DC).withOpacity(0.3),
      containerBorderWidth: 1,
      headerTextStyle: GoogleFonts.pirataOne(
        fontSize: 22,
        color: const Color(0xFFF5F5DC),
      ),
      selectedBorderColorWhenReady: const Color(0xFF7FFF00),
      selectedBorderWidthWhenReady: 2,
      minPlayersForReady: 2,
      selectedHeaderColorWhenReady: const Color(0xFF7FFF00),
      emptyStateTextStyle: GoogleFonts.montserrat(
        color: Color(0xFFF5F5DC).withOpacity(0.7),
        fontSize: 20,
      ),
      selectedEmptyText: 'Select at least 2 players',
      addButtonColor: const Color(0xFF2F4F4F),
      addButtonForegroundColor: const Color(0xFFF5F5DC),
      addButtonTextStyle: GoogleFonts.pirataOne(
        fontSize: 18,
        color: const Color(0xFFF5F5DC),
      ),
      selectedColor: const Color(0xFF4B0082),
      selectedBorderColor: const Color(0xFF7FFF00),
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
      containerColor: const Color(0xFF0B3D91),
      containerOpacity: 0.85,
      containerBorderColor: const Color(0xFF48D1CC).withOpacity(0.3),
      containerBorderWidth: 1,
      headerTextStyle: GoogleFonts.fredoka(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: const Color(0xFFFFF8F0),
      ),
      selectedBorderColorWhenReady: const Color(0xFF48D1CC),
      selectedBorderWidthWhenReady: 2,
      minPlayersForReady: 2,
      selectedHeaderColorWhenReady: const Color(0xFF48D1CC),
      emptyStateTextStyle: GoogleFonts.nunito(
        color: const Color(0xFFFFF8F0).withOpacity(0.7),
        fontSize: 20,
      ),
      selectedEmptyText: 'Select at least 2 players',
      addButtonColor: const Color(0xFF0B3D91),
      addButtonForegroundColor: const Color(0xFFFFF8F0),
      addButtonTextStyle: GoogleFonts.fredoka(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: const Color(0xFFFFF8F0),
      ),
      selectedColor: const Color(0xFF48D1CC).withOpacity(0.2),
      selectedBorderColor: const Color(0xFF48D1CC),
      unselectedBackgroundColor: const Color(0xFF0B3D91).withOpacity(0.6),
      unselectedBorderColor: const Color(0xFF48D1CC).withOpacity(0.3),
      cardNameStyle: GoogleFonts.fredoka(
        fontSize: 21,
        fontWeight: FontWeight.bold,
        color: const Color(0xFFFFF8F0),
      ),
      nameStatsSpacing: 1.4,
      maxPlayers: 8,
      availableContainerMargin: EdgeInsets.zero,
      selectedContainerMargin: EdgeInsets.zero,
      listGap: 8,
      addPlayerDialogConfig: AddPlayerDialogConfig.reefRoyale(),
    );
  }

  factory DualPlayerListPanelConfig.clockworkQuest() {
    return DualPlayerListPanelConfig(
      containerColor: const Color(0xFF2C2C34), // Dark Iron
      containerOpacity: 0.80,
      containerBorderColor: const Color(0xFFB87333).withOpacity(0.3), // Copper Rose
      containerBorderWidth: 1,
      headerTextStyle: GoogleFonts.cinzelDecorative(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: const Color(0xFFC5A54E), // Brass Gold
        letterSpacing: 1.2,
      ),
      selectedBorderColorWhenReady: const Color(0xFFC5A54E),
      selectedBorderWidthWhenReady: 2,
      minPlayersForReady: 2,
      selectedHeaderColorWhenReady: const Color(0xFFC5A54E),
      emptyStateTextStyle: GoogleFonts.lato(
        color: const Color(0xFFF5F0E8).withOpacity(0.7),
        fontSize: 16,
      ),
      selectedEmptyText: 'Select at least 2 players',
      addButtonColor: const Color(0xFF2C2C34),
      addButtonForegroundColor: const Color(0xFFF5F0E8),
      addButtonTextStyle: GoogleFonts.cinzelDecorative(
        fontSize: 14,
        color: const Color(0xFFF5F0E8),
      ),
      selectedColor: const Color(0xFFC5A54E).withOpacity(0.2),
      selectedBorderColor: const Color(0xFFC5A54E),
      unselectedBackgroundColor: const Color(0xFF2C2C34).withOpacity(0.6),
      unselectedBorderColor: const Color(0xFFB87333).withOpacity(0.3),
      cardNameStyle: GoogleFonts.cinzelDecorative(
        fontSize: 21,
        fontWeight: FontWeight.bold,
        color: const Color(0xFFF5F0E8),
        letterSpacing: 1.0,
      ),
      cardStatsStyle: GoogleFonts.lato(
        fontSize: 13,
        color: const Color(0xFFF5F0E8),
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
