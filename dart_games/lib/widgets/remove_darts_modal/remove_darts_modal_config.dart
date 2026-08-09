import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/game_theme.dart';

/// Configuration class for styling the shared Remove Darts modal.
///
/// Use factory methods to get pre-configured styling for each game:
/// - [RemoveDartsModalConfig.carnivalDerby] — Canary Yellow border, LuckiestGuy/Bangers fonts
/// - [RemoveDartsModalConfig.targetTag] — Hot Pink border, Fredoka font
/// - [RemoveDartsModalConfig.monsterMash] — Lime Green border, Creepster/PirataOne fonts
class RemoveDartsModalConfig {
  final Color backgroundColor;
  final double backgroundOpacity;
  final Color borderColor;
  final double borderWidth;
  final double borderRadius;
  final Color boxShadowColor;
  final double boxShadowOpacity;
  final Color iconColor;
  final double iconSize;
  final TextStyle playerNameTextStyle;
  final TextStyle instructionTextStyle;
  final Color buttonBackgroundColor;
  final Color buttonForegroundColor;
  final BorderSide? buttonBorderSide;
  final TextStyle buttonTextStyle;
  final double buttonBorderRadius;
  final String editButtonText;
  final double maxWidth;
  final EdgeInsets margin;
  final EdgeInsets padding;

  const RemoveDartsModalConfig({
    required this.backgroundColor,
    this.backgroundOpacity = 0.95,
    required this.borderColor,
    this.borderWidth = 4.0,
    this.borderRadius = 12.0,
    required this.boxShadowColor,
    required this.boxShadowOpacity,
    required this.iconColor,
    this.iconSize = 48,
    required this.playerNameTextStyle,
    required this.instructionTextStyle,
    required this.buttonBackgroundColor,
    required this.buttonForegroundColor,
    this.buttonBorderSide,
    required this.buttonTextStyle,
    this.buttonBorderRadius = 8.0,
    this.editButtonText = 'Edit player score',
    this.maxWidth = double.infinity,
    this.margin = const EdgeInsets.all(16),
    this.padding = const EdgeInsets.all(24),
  });

  /// Carnival Derby — Canary Yellow border, LuckiestGuy/Bangers fonts, larger icon/padding
  factory RemoveDartsModalConfig.carnivalDerby() {
    return RemoveDartsModalConfig(
      backgroundColor: GameTheme.carnivalDerby.background, // Midnight Navy
      backgroundOpacity: 0.95,
      borderColor: GameTheme.carnivalDerby.accent, // Canary Yellow
      borderWidth: 4,
      boxShadowColor: Colors.black,
      boxShadowOpacity: 0.5,
      iconColor: Colors.white,
      iconSize: 64,
      playerNameTextStyle: GoogleFonts.luckiestGuy(
        color: GameTheme.carnivalDerby.accent, // Canary Yellow
        fontSize: 28,
      ),
      instructionTextStyle: GoogleFonts.bangers(
        color: GameTheme.carnivalDerby.onDark, // Cloud Dancer
        fontSize: 24,
        letterSpacing: 1.0,
      ),
      buttonBackgroundColor: GameTheme.carnivalDerby.accent, // Canary Yellow
      buttonForegroundColor: GameTheme.carnivalDerby.background, // Midnight Navy
      buttonBorderSide: const BorderSide(
        color: Color(0xFFF1FAEE), // Cloud Dancer border
        width: 2,
      ),
      buttonTextStyle: GoogleFonts.bangers(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.0,
      ),
      editButtonText: 'Edit player score',
      margin: const EdgeInsets.all(32),
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 48),
    );
  }

  /// Target Tag — Hot Pink border, Fredoka font, 400px max width
  factory RemoveDartsModalConfig.targetTag() {
    return RemoveDartsModalConfig(
      backgroundColor: GameTheme.targetTag.background, // Dark navy
      backgroundOpacity: 0.95,
      borderColor: GameTheme.targetTag.accent, // Hot Pink
      borderWidth: 4,
      boxShadowColor: Colors.black,
      boxShadowOpacity: 0.5,
      iconColor: Colors.white,
      iconSize: 48,
      playerNameTextStyle: GoogleFonts.luckiestGuy(
        color: GameTheme.targetTag.accent, // Hot Pink
        fontSize: 24,
      ),
      instructionTextStyle: GoogleFonts.fredoka(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.0,
      ),
      buttonBackgroundColor: GameTheme.targetTag.accent.withOpacity(0.85),
      buttonForegroundColor: Colors.white,
      buttonTextStyle: GoogleFonts.fredoka(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
      editButtonText: 'Edit player score',
      maxWidth: 400,
    );
  }

  /// Monster Mash — Lime Green border with green glow shadow, Creepster/PirataOne fonts
  factory RemoveDartsModalConfig.monsterMash() {
    return RemoveDartsModalConfig(
      backgroundColor: GameTheme.monsterMash.background, // Iron Gate
      backgroundOpacity: 0.95,
      borderColor: GameTheme.monsterMash.accent, // Ecto-Green
      borderWidth: 4,
      boxShadowColor: GameTheme.monsterMash.accent, // Ecto-Green glow
      boxShadowOpacity: 0.3,
      iconColor: GameTheme.monsterMash.onDark, // Aged Parchment
      iconSize: 48,
      playerNameTextStyle: GoogleFonts.creepster(
        color: GameTheme.monsterMash.accent, // Ecto-Green
        fontSize: 24,
      ),
      instructionTextStyle: GoogleFonts.pirataOne(
        color: GameTheme.monsterMash.onDark, // Aged Parchment
        fontSize: 20,
      ),
      buttonBackgroundColor: const Color(0xFF4B0082).withOpacity(0.85), // Haunted Purple
      buttonForegroundColor: GameTheme.monsterMash.onDark, // Aged Parchment
      buttonBorderSide: const BorderSide(
        color: Color(0xFFFF8C00), // Pumpkin Orange
        width: 2,
      ),
      buttonTextStyle: GoogleFonts.pirataOne(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
      editButtonText: 'Edit Player Score',
      maxWidth: 400,
    );
  }

  /// Reef Royale — Ocean theme, Fredoka font, Seafoam Green accents
  factory RemoveDartsModalConfig.reefRoyale() {
    return RemoveDartsModalConfig(
      backgroundColor: GameTheme.reefRoyale.background, // Deep Reef Blue
      backgroundOpacity: 0.95,
      borderColor: GameTheme.reefRoyale.accent, // Seafoam Green
      borderWidth: 4,
      boxShadowColor: GameTheme.reefRoyale.accent, // Seafoam glow
      boxShadowOpacity: 0.3,
      iconColor: GameTheme.reefRoyale.onDark, // Pearl White
      iconSize: 48,
      playerNameTextStyle: GoogleFonts.fredoka(
        color: GameTheme.reefRoyale.accent, // Seafoam Green
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      instructionTextStyle: GoogleFonts.fredoka(
        color: GameTheme.reefRoyale.onDark, // Pearl White
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.0,
      ),
      buttonBackgroundColor: GameTheme.reefRoyale.accent.withOpacity(0.85),
      buttonForegroundColor: GameTheme.reefRoyale.background, // Deep Reef Blue
      buttonTextStyle: GoogleFonts.fredoka(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
      editButtonText: 'Edit player score',
      maxWidth: 400,
    );
  }

  /// Lunar Lander — Earth Blue background, Rocket Flame border, Orbitron/Exo2 fonts
  factory RemoveDartsModalConfig.lunarLander() {
    return RemoveDartsModalConfig(
      backgroundColor: GameTheme.lunarLander.background, // Earth Blue
      backgroundOpacity: 0.95,
      borderColor: GameTheme.lunarLander.accent, // Rocket Flame
      borderWidth: 4,
      boxShadowColor: GameTheme.lunarLander.accent,
      boxShadowOpacity: 0.3,
      iconColor: GameTheme.lunarLander.onDark, // Star White
      iconSize: 48,
      playerNameTextStyle: GoogleFonts.orbitron(
        color: GameTheme.lunarLander.accent, // Rocket Flame
        fontSize: 20,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.0,
      ),
      instructionTextStyle: GoogleFonts.exo2(
        color: GameTheme.lunarLander.onDark, // Star White
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.0,
      ),
      buttonBackgroundColor: GameTheme.lunarLander.accent.withOpacity(0.85), // Rocket Flame
      buttonForegroundColor: GameTheme.lunarLander.onDark,
      buttonTextStyle: GoogleFonts.orbitron(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
      editButtonText: 'Edit player score',
      maxWidth: 400,
    );
  }

  /// Pirate's Grid — Ocean Navy bg, Compass Bronze border, PirataOne/Lora fonts
  factory RemoveDartsModalConfig.piratesGrid() {
    return RemoveDartsModalConfig(
      backgroundColor: GameTheme.piratesGrid.background, // Ocean Navy
      backgroundOpacity: 0.95,
      borderColor: GameTheme.piratesGrid.accent, // Compass Bronze
      borderWidth: 4,
      boxShadowColor: GameTheme.piratesGrid.accent,
      boxShadowOpacity: 0.3,
      iconColor: GameTheme.piratesGrid.onDark, // Parchment Tan
      iconSize: 48,
      playerNameTextStyle: GoogleFonts.pirataOne(
        color: const Color(0xFFDAA520), // Treasure Gold
        fontSize: 22,
        letterSpacing: 1.0,
      ),
      instructionTextStyle: GoogleFonts.lora(
        color: GameTheme.piratesGrid.onDark, // Parchment Tan
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
      buttonBackgroundColor: GameTheme.piratesGrid.accent.withOpacity(0.85), // Compass Bronze
      buttonForegroundColor: GameTheme.piratesGrid.onDark,
      buttonTextStyle: GoogleFonts.pirataOne(
        fontSize: 16,
        letterSpacing: 0.5,
      ),
      editButtonText: 'Edit player score',
      maxWidth: 400,
    );
  }

  factory RemoveDartsModalConfig.clockworkQuest() {
    return RemoveDartsModalConfig(
      backgroundColor: GameTheme.clockworkQuest.background, // Dark Iron
      backgroundOpacity: 0.95,
      borderColor: GameTheme.clockworkQuest.accent, // Brass Gold
      borderWidth: 4,
      boxShadowColor: const Color(0xFFFFBF00), // Amber Glow
      boxShadowOpacity: 0.4,
      iconColor: GameTheme.clockworkQuest.onDark, // Steam White
      iconSize: 48,
      playerNameTextStyle: GoogleFonts.cinzelDecorative(
        color: GameTheme.clockworkQuest.accent, // Brass Gold
        fontSize: 24,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
      instructionTextStyle: GoogleFonts.lato(
        color: GameTheme.clockworkQuest.onDark, // Steam White
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.0,
      ),
      buttonBackgroundColor: GameTheme.clockworkQuest.accent.withOpacity(0.85), // Brass Gold
      buttonForegroundColor: GameTheme.clockworkQuest.background, // Dark Iron
      buttonTextStyle: GoogleFonts.cinzelDecorative(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.0,
      ),
      editButtonText: 'Edit player score',
      maxWidth: 400,
    );
  }

  /// Gladiator Arena — Dark Arena bg, Gladiator Gold border, Cinzel/Lato fonts
  factory RemoveDartsModalConfig.gladiatorArena() {
    return RemoveDartsModalConfig(
      backgroundColor: GameTheme.gladiatorArena.background, // Dark Arena
      backgroundOpacity: 0.97,
      borderColor: const Color(0xFFDAA520), // Gladiator Gold
      borderWidth: 4,
      boxShadowColor: const Color(0xFFDAA520),
      boxShadowOpacity: 0.3,
      iconColor: const Color(0xFFDAA520), // Gladiator Gold
      iconSize: 48,
      playerNameTextStyle: GoogleFonts.cinzel(
        color: const Color(0xFFDAA520), // Gladiator Gold
        fontSize: 24,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.0,
      ),
      instructionTextStyle: GoogleFonts.lato(
        color: GameTheme.gladiatorArena.onDark, // Marble White
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      buttonBackgroundColor: GameTheme.gladiatorArena.accent, // Bronze
      buttonForegroundColor: GameTheme.gladiatorArena.onDark, // Marble White
      buttonBorderSide: const BorderSide(
        color: Color(0xFFDAA520), // Gladiator Gold
        width: 2,
      ),
      buttonTextStyle: GoogleFonts.cinzel(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.0,
        color: GameTheme.gladiatorArena.onDark,
      ),
      editButtonText: 'Edit player score',
      maxWidth: double.infinity,
    );
  }

  /// Tiki Golf — Palm Green bg, Lagoon Blue border, Boogaloo/Nunito fonts
  factory RemoveDartsModalConfig.tikiGolf() {
    return RemoveDartsModalConfig(
      backgroundColor: GameTheme.tikiGolf.background, // Palm Green
      backgroundOpacity: 0.97,
      borderColor: GameTheme.tikiGolf.accent, // Lagoon Blue
      borderWidth: 4,
      boxShadowColor: Colors.black,
      boxShadowOpacity: 0.5,
      iconColor: GameTheme.tikiGolf.onDark, // Sand White
      iconSize: 48,
      playerNameTextStyle: GoogleFonts.boogaloo(
        color: const Color(0xFFFF8C42), // Tropical Orange
        fontSize: 28,
        shadows: const [
          Shadow(color: Color(0xFF8B5E3C), offset: Offset(1, 1), blurRadius: 0),
          Shadow(color: Color(0xFF8B5E3C), offset: Offset(-1, -1), blurRadius: 0),
          Shadow(color: Color(0xFF8B5E3C), offset: Offset(1, -1), blurRadius: 0),
          Shadow(color: Color(0xFF8B5E3C), offset: Offset(-1, 1), blurRadius: 0),
        ],
      ),
      instructionTextStyle: GoogleFonts.nunito(
        color: GameTheme.tikiGolf.onDark, // Sand White
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      buttonBackgroundColor: GameTheme.tikiGolf.accent, // Lagoon Blue
      buttonForegroundColor: GameTheme.tikiGolf.onDark, // Sand White
      buttonBorderSide: const BorderSide(
        color: Color(0xFFFF8C42), // Tropical Orange
        width: 2,
      ),
      buttonTextStyle: GoogleFonts.boogaloo(
        fontSize: 20,
        color: GameTheme.tikiGolf.onDark,
      ),
      editButtonText: 'Edit player score',
      maxWidth: double.infinity,
    );
  }

  /// Treasure Divide — Ocean Teal bg, Treasure Gold border, PirataOne/Merriweather fonts
  factory RemoveDartsModalConfig.treasureDivide() {
    return RemoveDartsModalConfig(
      backgroundColor: GameTheme.treasureDivide.background, // Ocean Teal
      backgroundOpacity: 0.97,
      borderColor: GameTheme.treasureDivide.accent, // Treasure Gold
      borderWidth: 4,
      boxShadowColor: GameTheme.treasureDivide.accent, // Treasure Gold glow
      boxShadowOpacity: 0.3,
      iconColor: GameTheme.treasureDivide.onDark, // Sail White
      iconSize: 48,
      playerNameTextStyle: GoogleFonts.pirataOne(
        color: GameTheme.treasureDivide.accent, // Treasure Gold
        fontSize: 24,
        letterSpacing: 1.0,
      ),
      instructionTextStyle: GoogleFonts.merriweather(
        color: GameTheme.treasureDivide.onDark, // Sail White
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      buttonBackgroundColor: GameTheme.treasureDivide.accent.withOpacity(0.9), // Treasure Gold
      buttonForegroundColor: GameTheme.treasureDivide.background, // Ocean Teal
      buttonBorderSide: BorderSide(
        color: const Color(0xFF8B6914), // Plank Brown
        width: 2,
      ),
      buttonTextStyle: GoogleFonts.merriweather(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: GameTheme.treasureDivide.background,
      ),
      editButtonText: 'Edit Score',
      maxWidth: double.infinity,
    );
  }
}
