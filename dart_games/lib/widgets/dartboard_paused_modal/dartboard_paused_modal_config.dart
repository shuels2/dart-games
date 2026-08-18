import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/game_theme.dart';

/// Configuration class for styling the shared Dartboard Paused modal.
///
/// Use factory methods to get pre-configured styling for each game:
/// - [DartboardPausedModalConfig.carnivalDerby]
/// - [DartboardPausedModalConfig.targetTag]
/// - [DartboardPausedModalConfig.monsterMash]
/// - [DartboardPausedModalConfig.reefRoyale]
class DartboardPausedModalConfig {
  final Color backgroundColor;
  final double backgroundOpacity;
  final Color borderColor;
  final double borderWidth;
  final double borderRadius;
  final Color boxShadowColor;
  final double boxShadowOpacity;
  final Color iconColor;
  final double iconSize;
  final TextStyle titleTextStyle;
  final TextStyle messageTextStyle;
  final double maxWidth;
  final EdgeInsets margin;
  final EdgeInsets padding;

  const DartboardPausedModalConfig({
    required this.backgroundColor,
    this.backgroundOpacity = 0.95,
    required this.borderColor,
    this.borderWidth = 4.0,
    this.borderRadius = 12.0,
    required this.boxShadowColor,
    required this.boxShadowOpacity,
    required this.iconColor,
    this.iconSize = 48,
    required this.titleTextStyle,
    required this.messageTextStyle,
    this.maxWidth = 420,
    this.margin = const EdgeInsets.all(16),
    this.padding = const EdgeInsets.all(32),
  });

  /// Carnival Derby — Midnight Navy with Canary Yellow border
  factory DartboardPausedModalConfig.carnivalDerby() {
    return DartboardPausedModalConfig(
      backgroundColor: GameTheme.carnivalDerby.background,
      borderColor: GameTheme.carnivalDerby.accent,
      boxShadowColor: Colors.black,
      boxShadowOpacity: 0.5,
      iconColor: GameTheme.carnivalDerby.accent,
      iconSize: 56,
      titleTextStyle: GoogleFonts.luckiestGuy(
        color: GameTheme.carnivalDerby.accent,
        fontSize: 28,
      ),
      messageTextStyle: GoogleFonts.bangers(
        color: GameTheme.carnivalDerby.onDark,
        fontSize: 20,
        letterSpacing: 1.0,
      ),
    );
  }

  /// Target Tag — Dark navy with Hot Pink border
  factory DartboardPausedModalConfig.targetTag() {
    return DartboardPausedModalConfig(
      backgroundColor: GameTheme.targetTag.background,
      borderColor: GameTheme.targetTag.accent,
      boxShadowColor: Colors.black,
      boxShadowOpacity: 0.5,
      iconColor: GameTheme.targetTag.accent,
      iconSize: 48,
      titleTextStyle: GoogleFonts.luckiestGuy(
        color: GameTheme.targetTag.accent,
        fontSize: 24,
      ),
      messageTextStyle: GoogleFonts.fredoka(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  /// Monster Mash — Iron Gate with Ecto-Green border
  factory DartboardPausedModalConfig.monsterMash() {
    return DartboardPausedModalConfig(
      backgroundColor: GameTheme.monsterMash.background,
      borderColor: GameTheme.monsterMash.accent,
      boxShadowColor: GameTheme.monsterMash.accent,
      boxShadowOpacity: 0.3,
      iconColor: GameTheme.monsterMash.accent,
      iconSize: 48,
      titleTextStyle: GoogleFonts.creepster(
        color: GameTheme.monsterMash.accent,
        fontSize: 28,
      ),
      messageTextStyle: GoogleFonts.pirataOne(
        color: GameTheme.monsterMash.onDark,
        fontSize: 18,
      ),
    );
  }

  /// Reef Royale — Deep Reef Blue with Seafoam Green border
  factory DartboardPausedModalConfig.reefRoyale() {
    return DartboardPausedModalConfig(
      backgroundColor: GameTheme.reefRoyale.background,
      borderColor: GameTheme.reefRoyale.accent,
      boxShadowColor: GameTheme.reefRoyale.accent,
      boxShadowOpacity: 0.3,
      iconColor: GameTheme.reefRoyale.accent,
      iconSize: 48,
      titleTextStyle: GoogleFonts.fredoka(
        color: GameTheme.reefRoyale.accent,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      messageTextStyle: GoogleFonts.fredoka(
        color: GameTheme.reefRoyale.onDark,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  /// Lunar Lander — Earth Blue with Thruster Red icon, Orbitron/Exo2 fonts
  factory DartboardPausedModalConfig.lunarLander() {
    return DartboardPausedModalConfig(
      backgroundColor: GameTheme.lunarLander.background, // Earth Blue
      borderColor: const Color(0xFFE63946), // Thruster Red
      boxShadowColor: const Color(0xFFE63946),
      boxShadowOpacity: 0.3,
      iconColor: const Color(0xFFE63946), // Thruster Red
      iconSize: 48,
      titleTextStyle: GoogleFonts.orbitron(
        color: const Color(0xFFE63946), // Thruster Red
        fontSize: 22,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
      messageTextStyle: GoogleFonts.exo2(
        color: GameTheme.lunarLander.onDark, // Star White
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  factory DartboardPausedModalConfig.homeScreen() {
    return DartboardPausedModalConfig(
      backgroundColor: const Color(0xFF8B0000),
      borderColor: const Color(0xFFFFC107),
      boxShadowColor: Colors.black,
      boxShadowOpacity: 0.5,
      iconColor: const Color(0xFFFFC107),
      iconSize: 56,
      titleTextStyle: GoogleFonts.luckiestGuy(
        color: const Color(0xFFFFC107),
        fontSize: 28,
      ),
      messageTextStyle: GoogleFonts.fredoka(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  /// Pirate's Grid — Ocean Navy bg, Blood Red border, PirataOne/Lora fonts
  factory DartboardPausedModalConfig.piratesGrid() {
    return DartboardPausedModalConfig(
      backgroundColor: GameTheme.piratesGrid.background, // Ocean Navy
      borderColor: const Color(0xFF8B0000), // Blood Red
      boxShadowColor: const Color(0xFF8B0000),
      boxShadowOpacity: 0.3,
      iconColor: const Color(0xFF8B0000), // Blood Red
      iconSize: 48,
      titleTextStyle: GoogleFonts.pirataOne(
        color: const Color(0xFF8B0000), // Blood Red
        fontSize: 24,
        letterSpacing: 1.2,
      ),
      messageTextStyle: GoogleFonts.lora(
        color: GameTheme.piratesGrid.onDark, // Parchment Tan
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  factory DartboardPausedModalConfig.clockworkQuest() {
    return DartboardPausedModalConfig(
      backgroundColor: GameTheme.clockworkQuest.background, // Dark Iron
      borderColor: GameTheme.clockworkQuest.accent, // Brass Gold
      boxShadowColor: const Color(0xFFFFBF00), // Amber Glow
      boxShadowOpacity: 0.4,
      iconColor: GameTheme.clockworkQuest.accent, // Brass Gold
      iconSize: 48,
      titleTextStyle: GoogleFonts.cinzelDecorative(
        color: GameTheme.clockworkQuest.accent,
        fontSize: 24,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
      messageTextStyle: GoogleFonts.lato(
        color: GameTheme.clockworkQuest.onDark, // Steam White
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  /// Gladiator Arena — Dark Arena bg, Blood Red border (signals danger/disconnection)
  factory DartboardPausedModalConfig.gladiatorArena() {
    return DartboardPausedModalConfig(
      backgroundColor: GameTheme.gladiatorArena.background, // Dark Arena
      borderColor: const Color(0xFFC0392B), // Blood Red — signals danger/disconnected
      boxShadowColor: const Color(0xFFC0392B),
      boxShadowOpacity: 0.4,
      iconColor: const Color(0xFFC0392B), // Blood Red
      iconSize: 48,
      titleTextStyle: GoogleFonts.cinzel(
        color: const Color(0xFFC0392B), // Blood Red
        fontSize: 24,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
      messageTextStyle: GoogleFonts.lato(
        color: GameTheme.gladiatorArena.onDark, // Marble White
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  /// Tiki Golf — Palm Green bg, Hibiscus Pink border (signals disconnection)
  factory DartboardPausedModalConfig.tikiGolf() {
    return DartboardPausedModalConfig(
      backgroundColor: GameTheme.tikiGolf.background, // Palm Green
      borderColor: const Color(0xFFFF69B4), // Hibiscus Pink
      boxShadowColor: Colors.black,
      boxShadowOpacity: 0.5,
      iconColor: const Color(0xFFFF69B4), // Hibiscus Pink
      iconSize: 48,
      titleTextStyle: GoogleFonts.boogaloo(
        color: const Color(0xFFFF69B4), // Hibiscus Pink
        fontSize: 28,
        shadows: const [
          Shadow(color: Color(0xFF8B5E3C), offset: Offset(1, 1), blurRadius: 0),
          Shadow(color: Color(0xFF8B5E3C), offset: Offset(-1, -1), blurRadius: 0),
          Shadow(color: Color(0xFF8B5E3C), offset: Offset(1, -1), blurRadius: 0),
          Shadow(color: Color(0xFF8B5E3C), offset: Offset(-1, 1), blurRadius: 0),
        ],
      ),
      messageTextStyle: GoogleFonts.nunito(
        color: GameTheme.tikiGolf.onDark, // Sand White
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  /// Treasure Divide — Ocean Teal bg (0.85), Blood Red headline, Sail White sub-text,
  /// PirataOne title font, Merriweather body font
  factory DartboardPausedModalConfig.treasureDivide() {
    return DartboardPausedModalConfig(
      backgroundColor: GameTheme.treasureDivide.background, // Ocean Teal
      backgroundOpacity: 0.85,
      borderColor: const Color(0xFFC41E3A), // Blood Red
      boxShadowColor: const Color(0xFFC41E3A),
      boxShadowOpacity: 0.3,
      iconColor: const Color(0xFFC41E3A), // Blood Red
      iconSize: 48,
      titleTextStyle: GoogleFonts.pirataOne(
        color: const Color(0xFFC41E3A), // Blood Red
        fontSize: 24,
        letterSpacing: 1.2,
      ),
      messageTextStyle: GoogleFonts.merriweather(
        color: GameTheme.treasureDivide.onDark, // Sail White
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
