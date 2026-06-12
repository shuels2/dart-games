import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dart_games/models/monster_mash_game.dart';
import 'package:dart_games/models/reef_royale_game.dart';

class DartboardSectionConfig {
  final Color backgroundColor;
  final BorderRadius? borderRadius;
  final BoxBorder? border;
  final EdgeInsets padding;
  final Color disabledOverlayBackgroundColor;
  final Color disabledOverlayBorderColor;
  final double disabledOverlayBorderWidth;
  final Color removeButtonBackgroundColor;
  final Color removeButtonBorderColor;
  final TextStyle removeButtonTextStyle;
  final String removeButtonText;
  final String promptText;
  final IconData promptIcon;

  const DartboardSectionConfig({
    required this.backgroundColor,
    this.borderRadius,
    this.border,
    this.padding = const EdgeInsets.all(16.0),
    required this.disabledOverlayBackgroundColor,
    required this.disabledOverlayBorderColor,
    this.disabledOverlayBorderWidth = 3.0,
    required this.removeButtonBackgroundColor,
    required this.removeButtonBorderColor,
    required this.removeButtonTextStyle,
    this.removeButtonText = 'DARTS REMOVED',
    this.promptText = 'Remove Your Darts',
    this.promptIcon = Icons.pan_tool,
  });

  // Factory for Carnival Derby
  factory DartboardSectionConfig.carnivalDerby() {
    return DartboardSectionConfig(
      backgroundColor: Colors.grey[200]!,
      border: const Border(top: BorderSide(color: Colors.grey, width: 1)),
      disabledOverlayBackgroundColor: const Color(0xFF1D3557).withOpacity(0.9), // Midnight Navy
      disabledOverlayBorderColor: const Color(0xFFFFD700), // Canary Yellow
      removeButtonBackgroundColor: const Color(0xFFE63946), // Lava Red
      removeButtonBorderColor: const Color(0xFFFFD700), // Canary Yellow
      removeButtonTextStyle: GoogleFonts.bangers(
        fontSize: 16,
        letterSpacing: 1.0,
        color: const Color(0xFFF1FAEE), // Cloud Dancer
      ),
    );
  }

  // Factory for Target Tag
  factory DartboardSectionConfig.targetTag() {
    return DartboardSectionConfig(
      backgroundColor: const Color(0xFF2A2A3E), // Dark blue-gray
      borderRadius: BorderRadius.circular(12),
      disabledOverlayBackgroundColor: const Color(0xFF1A1A2E).withOpacity(0.9), // Dark navy
      disabledOverlayBorderColor: const Color(0xFFFF007A), // Hot pink
      removeButtonBackgroundColor: const Color(0xFFFF007A), // Hot pink
      removeButtonBorderColor: const Color(0xFF00FFA3), // Neon green
      removeButtonTextStyle: GoogleFonts.fredoka(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.0,
        color: Colors.white,
      ),
    );
  }

  // Factory for Monster Mash
  factory DartboardSectionConfig.monsterMash() {
    return DartboardSectionConfig(
      backgroundColor: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      disabledOverlayBackgroundColor: const Color(0xFF2F4F4F).withOpacity(0.9),
      disabledOverlayBorderColor: const Color(0xFF7FFF00), // Ecto-Green
      removeButtonBackgroundColor: const Color(0xFF4B0082), // Haunted Purple
      removeButtonBorderColor: const Color(0xFF7FFF00), // Ecto-Green
      removeButtonTextStyle: GoogleFonts.pirataOne(
        fontSize: 16,
        letterSpacing: 1.0,
        color: const Color(0xFFF5F5DC), // Aged Parchment
      ),
    );
  }

  // Factory for Reef Royale
  factory DartboardSectionConfig.reefRoyale() {
    return DartboardSectionConfig(
      backgroundColor: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      disabledOverlayBackgroundColor: const Color(0xFF0B3D91).withOpacity(0.9),
      disabledOverlayBorderColor: const Color(0xFF48D1CC), // Seafoam Green
      removeButtonBackgroundColor: const Color(0xFF48D1CC), // Seafoam Green
      removeButtonBorderColor: const Color(0xFF00CED1), // Sunlit Aqua
      removeButtonTextStyle: GoogleFonts.fredoka(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.0,
        color: const Color(0xFFFFF8F0), // Pearl White
      ),
    );
  }

  factory DartboardSectionConfig.clockworkQuest() {
    return DartboardSectionConfig(
      backgroundColor: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      disabledOverlayBackgroundColor: const Color(0xFF2C2C34).withOpacity(0.95), // Dark Iron
      disabledOverlayBorderColor: const Color(0xFFC5A54E), // Brass Gold
      removeButtonBackgroundColor: const Color(0xFFC5A54E), // Brass Gold
      removeButtonBorderColor: const Color(0xFFB87333), // Copper Rose
      removeButtonTextStyle: GoogleFonts.cinzelDecorative(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
        color: const Color(0xFF2C2C34), // Dark Iron
      ),
    );
  }

  // Factory for Lunar Lander
  factory DartboardSectionConfig.lunarLander() {
    return DartboardSectionConfig(
      backgroundColor: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      disabledOverlayBackgroundColor: const Color(0xFF1B4965).withOpacity(0.95), // Earth Blue
      disabledOverlayBorderColor: const Color(0xFFF26430), // Rocket Flame
      removeButtonBackgroundColor: const Color(0xFFF26430), // Rocket Flame
      removeButtonBorderColor: const Color(0xFF52B788), // Mission Green
      removeButtonTextStyle: GoogleFonts.orbitron(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
        color: const Color(0xFFFAFDF6), // Star White
      ),
    );
  }

  // Factory for Pirate's Grid
  factory DartboardSectionConfig.piratesGrid() {
    return DartboardSectionConfig(
      backgroundColor: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      disabledOverlayBackgroundColor: const Color(0xFF1B2838).withOpacity(0.95), // Ocean Navy
      disabledOverlayBorderColor: const Color(0xFFCD7F32), // Compass Bronze
      removeButtonBackgroundColor: const Color(0xFFCD7F32), // Compass Bronze
      removeButtonBorderColor: const Color(0xFFDAA520), // Treasure Gold
      removeButtonTextStyle: GoogleFonts.pirataOne(
        fontSize: 16,
        letterSpacing: 1.2,
        color: const Color(0xFFF5E6C8), // Parchment Tan
      ),
    );
  }

  // Factory for Gladiator Arena
  factory DartboardSectionConfig.gladiatorArena() {
    return DartboardSectionConfig(
      backgroundColor: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      disabledOverlayBackgroundColor: const Color(0xFF3A2010).withOpacity(0.95), // Dark Arena
      disabledOverlayBorderColor: const Color(0xFFDAA520), // Gladiator Gold
      removeButtonBackgroundColor: const Color(0xFFCD7F32), // Bronze
      removeButtonBorderColor: const Color(0xFFDAA520), // Gladiator Gold
      removeButtonTextStyle: GoogleFonts.cinzel(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
        color: const Color(0xFFF5F0E8), // Marble White
      ),
    );
  }

  // Factory for Tiki Golf — Palm Green, Lagoon Blue border, Boogaloo font
  factory DartboardSectionConfig.tikiGolf() {
    return DartboardSectionConfig(
      backgroundColor: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      disabledOverlayBackgroundColor: const Color(0xFF2D6A4F).withOpacity(0.95), // Palm Green
      disabledOverlayBorderColor: const Color(0xFF00B4D8), // Lagoon Blue
      removeButtonBackgroundColor: const Color(0xFF00B4D8), // Lagoon Blue
      removeButtonBorderColor: const Color(0xFFFF8C42), // Tropical Orange
      removeButtonTextStyle: GoogleFonts.boogaloo(
        fontSize: 18,
        color: const Color(0xFFFFF5E1), // Sand White
      ),
    );
  }

  // Factory for Treasure Divide — Ocean Teal, Treasure Gold border, Merriweather/PirataOne font
  factory DartboardSectionConfig.treasureDivide() {
    return DartboardSectionConfig(
      backgroundColor: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFFFD700), width: 2), // Treasure Gold
      disabledOverlayBackgroundColor: const Color(0xFF008B8B).withOpacity(0.95), // Ocean Teal
      disabledOverlayBorderColor: const Color(0xFF8B6914), // Plank Brown
      removeButtonBackgroundColor: const Color(0xFFFFD700), // Treasure Gold
      removeButtonBorderColor: const Color(0xFF8B6914), // Plank Brown
      removeButtonTextStyle: GoogleFonts.merriweather(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF008B8B), // Ocean Teal
      ),
    );
  }
}

class DartboardFABConfig {
  final Color backgroundColor;
  final Color iconColor;
  final Color textColor;
  final TextStyle textStyle;
  final String showText;
  final String hideText;

  const DartboardFABConfig({
    required this.backgroundColor,
    this.iconColor = Colors.white,
    this.textColor = Colors.white,
    required this.textStyle,
    this.showText = 'Show Dartboard',
    this.hideText = 'Hide Dartboard',
  });

  // Factory for Carnival Derby
  factory DartboardFABConfig.carnivalDerby() {
    return DartboardFABConfig(
      backgroundColor: const Color(0xFFFFD700), // Canary Yellow
      iconColor: const Color(0xFF8B5E3C), // Warm Cedar
      textColor: const Color(0xFF8B5E3C), // Warm Cedar
      textStyle: GoogleFonts.rye(fontWeight: FontWeight.bold),
    );
  }

  // Factory for Target Tag
  factory DartboardFABConfig.targetTag() {
    return DartboardFABConfig(
      backgroundColor: const Color(0xFFFF007A), // Hot pink
      iconColor: Colors.white,
      textColor: Colors.white,
      textStyle: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
    );
  }

  // Factory for Monster Mash
  factory DartboardFABConfig.monsterMash() {
    return DartboardFABConfig(
      backgroundColor: const Color(0xFF4B0082), // Haunted Purple
      iconColor: const Color(0xFF7FFF00), // Ecto-Green
      textColor: const Color(0xFFF5F5DC), // Aged Parchment
      textStyle: GoogleFonts.pirataOne(fontWeight: FontWeight.bold),
    );
  }

  // Factory for Reef Royale
  factory DartboardFABConfig.reefRoyale() {
    return DartboardFABConfig(
      backgroundColor: const Color(0xFF48D1CC), // Seafoam Green
      iconColor: const Color(0xFFFFF8F0), // Pearl White
      textColor: const Color(0xFFFFF8F0), // Pearl White
      textStyle: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
    );
  }

  factory DartboardFABConfig.clockworkQuest() {
    return DartboardFABConfig(
      backgroundColor: const Color(0xFFB87333), // Copper Rose
      iconColor: const Color(0xFFF5F0E8), // Steam White
      textColor: const Color(0xFFF5F0E8), // Steam White
      textStyle: GoogleFonts.cinzelDecorative(
        fontWeight: FontWeight.bold,
        letterSpacing: 1.0,
      ),
    );
  }

  // Factory for Lunar Lander
  factory DartboardFABConfig.lunarLander() {
    return DartboardFABConfig(
      backgroundColor: const Color(0xFFF26430), // Rocket Flame
      iconColor: const Color(0xFFFAFDF6), // Star White
      textColor: const Color(0xFFFAFDF6), // Star White
      textStyle: GoogleFonts.orbitron(
        fontWeight: FontWeight.bold,
        letterSpacing: 1.0,
      ),
    );
  }

  // Factory for Pirate's Grid
  factory DartboardFABConfig.piratesGrid() {
    return DartboardFABConfig(
      backgroundColor: const Color(0xFFCD7F32), // Compass Bronze
      iconColor: const Color(0xFFF5E6C8), // Parchment Tan
      textColor: const Color(0xFFF5E6C8), // Parchment Tan
      textStyle: GoogleFonts.pirataOne(
        letterSpacing: 1.0,
      ),
    );
  }

  // Factory for Gladiator Arena
  factory DartboardFABConfig.gladiatorArena() {
    return DartboardFABConfig(
      backgroundColor: const Color(0xFFDAA520), // Gladiator Gold
      iconColor: const Color(0xFF1A0A00), // Near Black
      textColor: const Color(0xFF1A0A00), // Near Black
      textStyle: GoogleFonts.cinzel(
        fontWeight: FontWeight.bold,
        letterSpacing: 1.0,
      ),
    );
  }

  // Factory for Tiki Golf — Lagoon Blue bg, Sand White text, Boogaloo font
  factory DartboardFABConfig.tikiGolf() {
    return DartboardFABConfig(
      backgroundColor: const Color(0xFF00B4D8), // Lagoon Blue
      iconColor: const Color(0xFFFFF5E1), // Sand White
      textColor: const Color(0xFFFFF5E1), // Sand White
      textStyle: GoogleFonts.boogaloo(
        fontSize: 16,
      ),
    );
  }

  // Factory for Treasure Divide — Treasure Gold bg, Ocean Teal icon/text, PirataOne font
  factory DartboardFABConfig.treasureDivide() {
    return DartboardFABConfig(
      backgroundColor: const Color(0xFFFFD700), // Treasure Gold
      iconColor: const Color(0xFF008B8B), // Ocean Teal
      textColor: const Color(0xFF008B8B), // Ocean Teal
      textStyle: GoogleFonts.merriweather(
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
      showText: 'Show Dartboard',
      hideText: 'Hide Dartboard',
    );
  }
}

class PlayToCompleteButtonConfig {
  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;
  final TextStyle textStyle;
  final String buttonText;
  final IconData icon;
  final String runningText;

  const PlayToCompleteButtonConfig({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
    required this.textStyle,
    this.buttonText = 'Play to Complete',
    this.icon = Icons.fast_forward,
    this.runningText = 'Auto-Playing...',
  });

  factory PlayToCompleteButtonConfig.carnivalDerby() {
    return PlayToCompleteButtonConfig(
      backgroundColor: const Color(0xFFE63946), // Lava Red
      foregroundColor: const Color(0xFFF1FAEE), // Cloud Dancer
      borderColor: const Color(0xFFFFD700), // Canary Yellow
      textStyle: GoogleFonts.bangers(
        fontSize: 16,
        letterSpacing: 1.0,
        color: const Color(0xFFF1FAEE),
      ),
    );
  }

  factory PlayToCompleteButtonConfig.targetTag() {
    return PlayToCompleteButtonConfig(
      backgroundColor: const Color(0xFFFF007A), // Hot pink
      foregroundColor: Colors.white,
      borderColor: const Color(0xFF00FFA3), // Neon green
      textStyle: GoogleFonts.fredoka(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.0,
        color: Colors.white,
      ),
    );
  }

  factory PlayToCompleteButtonConfig.monsterMash() {
    return PlayToCompleteButtonConfig(
      backgroundColor: const Color(0xFF4B0082), // Haunted Purple
      foregroundColor: const Color(0xFFF5F5DC), // Aged Parchment
      borderColor: const Color(0xFF7FFF00), // Ecto-Green
      textStyle: GoogleFonts.pirataOne(
        fontSize: 16,
        letterSpacing: 1.0,
        color: const Color(0xFFF5F5DC),
      ),
    );
  }

  factory PlayToCompleteButtonConfig.reefRoyale() {
    return PlayToCompleteButtonConfig(
      backgroundColor: const Color(0xFF48D1CC), // Seafoam Green
      foregroundColor: const Color(0xFFFFF8F0), // Pearl White
      borderColor: const Color(0xFF00CED1), // Sunlit Aqua
      textStyle: GoogleFonts.fredoka(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.0,
        color: const Color(0xFFFFF8F0),
      ),
    );
  }

  factory PlayToCompleteButtonConfig.clockworkQuest() {
    return PlayToCompleteButtonConfig(
      backgroundColor: const Color(0xFFC5A54E), // Brass Gold
      foregroundColor: const Color(0xFF2C2C34), // Dark Iron
      borderColor: const Color(0xFFB87333), // Copper Rose
      textStyle: GoogleFonts.cinzelDecorative(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
        color: const Color(0xFF2C2C34),
      ),
    );
  }

  // Factory for Lunar Lander
  factory PlayToCompleteButtonConfig.lunarLander() {
    return PlayToCompleteButtonConfig(
      backgroundColor: const Color(0xFF52B788), // Mission Green
      foregroundColor: const Color(0xFFFAFDF6), // Star White
      borderColor: const Color(0xFFF26430), // Rocket Flame
      textStyle: GoogleFonts.orbitron(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.0,
        color: const Color(0xFFFAFDF6),
      ),
    );
  }

  // Factory for Pirate's Grid
  factory PlayToCompleteButtonConfig.piratesGrid() {
    return PlayToCompleteButtonConfig(
      backgroundColor: const Color(0xFF2E8B8B), // Sea Foam Teal
      foregroundColor: const Color(0xFFF5E6C8), // Parchment Tan
      borderColor: const Color(0xFFDAA520), // Treasure Gold
      textStyle: GoogleFonts.pirataOne(
        fontSize: 16,
        letterSpacing: 1.0,
        color: const Color(0xFFF5E6C8),
      ),
    );
  }

  // Factory for Gladiator Arena
  factory PlayToCompleteButtonConfig.gladiatorArena() {
    return PlayToCompleteButtonConfig(
      backgroundColor: const Color(0xFF4A7C59), // Laurel Green
      foregroundColor: const Color(0xFFF5F0E8), // Marble White
      borderColor: const Color(0xFFDAA520), // Gladiator Gold
      textStyle: GoogleFonts.cinzel(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.0,
        color: const Color(0xFFF5F0E8),
      ),
    );
  }

  // Factory for Tiki Golf — Palm Green bg, Sand White text, Lagoon Blue border, Boogaloo font
  factory PlayToCompleteButtonConfig.tikiGolf() {
    return PlayToCompleteButtonConfig(
      backgroundColor: const Color(0xFF2D6A4F), // Palm Green
      foregroundColor: const Color(0xFFFFF5E1), // Sand White
      borderColor: const Color(0xFF00B4D8), // Lagoon Blue
      textStyle: GoogleFonts.boogaloo(
        fontSize: 16,
        color: const Color(0xFFFFF5E1),
      ),
    );
  }

  // Factory for Treasure Divide — Treasure Gold bg, Ocean Teal text, Plank Brown border
  factory PlayToCompleteButtonConfig.treasureDivide() {
    return PlayToCompleteButtonConfig(
      backgroundColor: const Color(0xFFFFD700), // Treasure Gold
      foregroundColor: const Color(0xFF008B8B), // Ocean Teal
      borderColor: const Color(0xFF8B6914), // Plank Brown
      textStyle: GoogleFonts.pirataOne(
        fontSize: 16,
        letterSpacing: 1.0,
        color: const Color(0xFF008B8B), // Ocean Teal
      ),
      buttonText: 'Sail to Victory',
    );
  }
}

/// Visual config for the Play to Tie / Draw button. Sits side-by-side
/// with the Play to Complete button in the dartboard emulator section.
/// Only provided for tie-capable games (Tiki Golf, Pirate's Grid,
/// Monster Mash, Reef Royale).
class PlayToTieButtonConfig {
  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;
  final TextStyle textStyle;
  final String buttonText;
  final IconData icon;
  final String runningText;

  const PlayToTieButtonConfig({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
    required this.textStyle,
    required this.buttonText,
    this.icon = Icons.handshake,
    this.runningText = 'Auto-Playing...',
  });

  // Factory for Tiki Golf — Lagoon Blue bg (swapped with the Complete
  // button's Palm Green so the two buttons are visually distinct).
  factory PlayToTieButtonConfig.tikiGolf() {
    return PlayToTieButtonConfig(
      backgroundColor: const Color(0xFF00B4D8), // Lagoon Blue
      foregroundColor: const Color(0xFFFFF5E1), // Sand White
      borderColor: const Color(0xFF2D6A4F), // Palm Green
      textStyle: GoogleFonts.boogaloo(
        fontSize: 16,
        color: const Color(0xFFFFF5E1),
      ),
      buttonText: 'Play to Draw',
    );
  }

  // Factory for Treasure Divide — Treasure Gold bg on Ocean Teal,
  // PirataOne, "Divide the Treasure" label (matches the in-game tie
  // copy "Divided treasure!" used on the results screen).
  factory PlayToTieButtonConfig.treasureDivide() {
    return PlayToTieButtonConfig(
      backgroundColor: const Color(0xFFFFD700), // Treasure Gold
      foregroundColor: const Color(0xFF008B8B), // Ocean Teal
      borderColor: const Color(0xFF8B6914), // Plank Brown
      textStyle: GoogleFonts.pirataOne(
        fontSize: 16,
        letterSpacing: 1.0,
        color: const Color(0xFF008B8B),
      ),
      buttonText: 'Divide the Treasure',
    );
  }

  // Factory for Pirate's Grid — Treasure Gold bg, "Stalemate" label.
  factory PlayToTieButtonConfig.piratesGrid() {
    return PlayToTieButtonConfig(
      backgroundColor: const Color(0xFFDAA520), // Treasure Gold
      foregroundColor: const Color(0xFF1B1B1B),
      borderColor: const Color(0xFF2E8B8B), // Sea Foam Teal
      textStyle: GoogleFonts.pirataOne(
        fontSize: 16,
        letterSpacing: 1.0,
        color: const Color(0xFF1B1B1B),
      ),
      buttonText: 'Play to Stalemate',
    );
  }

  // Factory for Monster Mash — Ecto Green bg (Speed Play only).
  factory PlayToTieButtonConfig.monsterMash() {
    return PlayToTieButtonConfig(
      backgroundColor: const Color(0xFF7FFF00), // Ecto Green
      foregroundColor: const Color(0xFF1B1B1B),
      borderColor: const Color(0xFF4B0082), // Haunted Purple
      textStyle: GoogleFonts.pirataOne(
        fontSize: 16,
        letterSpacing: 1.0,
        color: const Color(0xFF1B1B1B),
      ),
      buttonText: 'Play to Tie',
    );
  }

  // Factory for Reef Royale — Pearl Cream bg (Speed Play recommended).
  factory PlayToTieButtonConfig.reefRoyale() {
    return PlayToTieButtonConfig(
      backgroundColor: const Color(0xFFF5E6C8), // Parchment Tan
      foregroundColor: const Color(0xFF003049), // Deep Sea Navy
      borderColor: const Color(0xFF48CAE4), // Electric Teal
      textStyle: GoogleFonts.fredoka(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.0,
        color: const Color(0xFF003049),
      ),
      buttonText: 'Play to Tie',
    );
  }
}

/// Visual config for a single buff-toggle button (emulator-only debug
/// control that flanks the dartboard in games with bonus buffs).
///
/// Active state: filled with [activeBackgroundColor] + [borderColor] border.
/// Inactive state: filled with [inactiveBackgroundColor] + [borderColor] border.
/// Disabled state (bonus buffs not enabled): rendered at half opacity by
/// the surrounding column.
class BuffToggleButtonConfig {
  final Color activeBackgroundColor;
  final Color inactiveBackgroundColor;
  final Color borderColor;
  final TextStyle activeTextStyle;
  final TextStyle inactiveTextStyle;

  const BuffToggleButtonConfig({
    required this.activeBackgroundColor,
    required this.inactiveBackgroundColor,
    required this.borderColor,
    required this.activeTextStyle,
    required this.inactiveTextStyle,
  });

  /// Monster Mash buff-toggle styling — one factory per buff so each
  /// button carries the visual flavor of its in-game effect.
  factory BuffToggleButtonConfig.monsterMash(BonusBuff buff) {
    // Shared chrome: PirataOne font, Aged Parchment label, Ecto-Green
    // border — matches the rest of the Monster Mash emulator chrome.
    const aged = Color(0xFFF5F5DC); // Aged Parchment
    const ecto = Color(0xFF7FFF00); // Ecto-Green
    const haunted = Color(0xFF4B0082); // Haunted Purple
    final inactiveStyle = GoogleFonts.pirataOne(
      fontSize: 11,
      letterSpacing: 0.5,
      height: 1.1,
      color: aged.withOpacity(0.55),
    );
    final activeStyle = GoogleFonts.pirataOne(
      fontSize: 11,
      letterSpacing: 0.5,
      height: 1.1,
      color: aged,
    );

    // Each buff's active color carries its in-game effect's vibe.
    Color active;
    switch (buff) {
      case BonusBuff.bloodMoon:
        active = const Color(0xFFFF4444); // Blood Red — damage doubling
      case BonusBuff.ancientBandages:
        active = ecto; // Ecto-Green — healing
      case BonusBuff.shadowWalk:
        active = const Color(0xFF2F4F4F); // Iron Gate — null damage
      case BonusBuff.laboratorySpark:
        active = const Color(0xFFFF8C00); // Pumpkin Orange — electric zap
    }

    // For Ancient Bandages the active bg matches the border color, so
    // swap the border to Haunted Purple so the active state still has
    // a visible outline.
    final border = buff == BonusBuff.ancientBandages ? haunted : ecto;

    return BuffToggleButtonConfig(
      activeBackgroundColor: active,
      inactiveBackgroundColor: haunted.withOpacity(0.35),
      borderColor: border,
      activeTextStyle: activeStyle,
      inactiveTextStyle: inactiveStyle,
    );
  }

  /// Reef Royale buff-toggle styling — one factory per buff.
  factory BuffToggleButtonConfig.reefRoyale(ReefBuff buff) {
    const pearl = Color(0xFFFFF8F0); // Pearl White
    const deepReef = Color(0xFF0B3D91); // Deep Reef Blue
    const sandyGold = Color(0xFFF4D03F);
    final inactiveStyle = GoogleFonts.fredoka(
      fontSize: 11,
      fontWeight: FontWeight.bold,
      height: 1.1,
      color: pearl.withOpacity(0.55),
    );
    final activeStyle = GoogleFonts.fredoka(
      fontSize: 11,
      fontWeight: FontWeight.bold,
      height: 1.1,
      color: pearl,
    );

    Color active;
    switch (buff) {
      case ReefBuff.riptideRush:
        active = const Color(0xFF48D1CC); // Seafoam Green — double marks
      case ReefBuff.pearlFever:
        active = sandyGold; // Sandy Gold — double pearls
      case ReefBuff.inkCloud:
        active = const Color(0xFF9B59B6); // Biolum Purple — hides info
    }

    // Pearl Fever's gold active bg clashes with light text — swap the
    // active text color to deep reef for legibility on that one.
    final activeText = buff == ReefBuff.pearlFever
        ? GoogleFonts.fredoka(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            height: 1.1,
            color: deepReef,
          )
        : activeStyle;

    return BuffToggleButtonConfig(
      activeBackgroundColor: active,
      inactiveBackgroundColor: deepReef.withOpacity(0.5),
      borderColor: sandyGold,
      activeTextStyle: activeText,
      inactiveTextStyle: inactiveStyle,
    );
  }

  /// Gladiator Arena shield-round toggle styling.
  factory BuffToggleButtonConfig.gladiatorArena() {
    const gold = Color(0xFFD4AF37);
    const imperial = Color(0xFF4A0E4E);
    const marble = Color(0xFFF5F0E8);
    return BuffToggleButtonConfig(
      activeBackgroundColor: const Color(0xFF2E7D32),
      inactiveBackgroundColor: imperial.withOpacity(0.35),
      borderColor: gold,
      activeTextStyle: GoogleFonts.cinzel(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        height: 1.1,
        color: marble,
      ),
      inactiveTextStyle: GoogleFonts.cinzel(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        height: 1.1,
        color: marble.withOpacity(0.55),
      ),
    );
  }

  factory BuffToggleButtonConfig.piratesGrid() {
    const parchment = Color(0xFFF5E6C8);
    const oceanNavy = Color(0xFF1B2838);
    const compassBronze = Color(0xFFCD7F32);
    return BuffToggleButtonConfig(
      activeBackgroundColor: const Color(0xFF2E8B8B),
      inactiveBackgroundColor: oceanNavy.withOpacity(0.5),
      borderColor: compassBronze,
      activeTextStyle: GoogleFonts.pirataOne(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        height: 1.1,
        color: parchment,
      ),
      inactiveTextStyle: GoogleFonts.pirataOne(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        height: 1.1,
        color: parchment.withOpacity(0.55),
      ),
    );
  }

  /// Treasure Divide theme-preview toggle styling. Used by the emulator-only
  /// theme picker that overrides every player's pirate theme for sprite
  /// placement debugging — game logic is unaffected.
  factory BuffToggleButtonConfig.treasureDivide() {
    const treasureGold = Color(0xFFFFD700);
    const oceanTeal = Color(0xFF008B8B);
    const plankBrown = Color(0xFF8B6914);
    const sailWhite = Color(0xFFFFF8E7);
    return BuffToggleButtonConfig(
      activeBackgroundColor: treasureGold,
      inactiveBackgroundColor: oceanTeal.withOpacity(0.35),
      borderColor: plankBrown,
      activeTextStyle: GoogleFonts.pirataOne(
        fontSize: 11,
        letterSpacing: 0.5,
        height: 1.1,
        color: oceanTeal,
      ),
      inactiveTextStyle: GoogleFonts.pirataOne(
        fontSize: 11,
        letterSpacing: 0.5,
        height: 1.1,
        color: sailWhite,
      ),
    );
  }
}
