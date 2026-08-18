import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/game_theme.dart';

/// Configuration class for styling the DartboardConnectionInfo widget.
///
/// Allows each game/screen to customize the appearance while maintaining
/// consistent functionality across all implementations.
class DartboardConnectionInfoConfig {
  final Color backgroundColor;
  final double backgroundOpacity;
  final double borderRadius;
  final Color emulatorBorderColor;
  final Color hardwareBorderColor;
  final double borderWidth;
  final TextStyle nameTextStyle;
  final TextStyle statusTextStyle;
  final TextStyle emulatorLabelTextStyle;
  final Color emulatorIconColor;
  final Color hardwareIconColor;
  final Color connectedColor;
  final Color connectingColor;
  final Color disconnectedColor;
  final Color errorColor;
  final double iconSize;
  final EdgeInsets padding;

  const DartboardConnectionInfoConfig({
    required this.backgroundColor,
    this.backgroundOpacity = 0.95,
    this.borderRadius = 8.0,
    required this.emulatorBorderColor,
    required this.hardwareBorderColor,
    this.borderWidth = 1.5,
    required this.nameTextStyle,
    required this.statusTextStyle,
    required this.emulatorLabelTextStyle,
    required this.emulatorIconColor,
    required this.hardwareIconColor,
    this.connectedColor = Colors.green,
    this.connectingColor = Colors.orange,
    this.disconnectedColor = Colors.red,
    this.errorColor = Colors.red,
    this.iconSize = 18.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  });

  /// Home screen — semi-transparent overlay that lets the Red→Amber gradient show through
  factory DartboardConnectionInfoConfig.homeScreen() {
    return DartboardConnectionInfoConfig(
      backgroundColor: Colors.black,
      backgroundOpacity: 0.25,
      emulatorBorderColor: Colors.white70,
      hardwareBorderColor: Colors.white70,
      nameTextStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      statusTextStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
      emulatorLabelTextStyle: const TextStyle(
        fontSize: 10,
        color: Colors.white70,
      ),
      emulatorIconColor: Colors.white,
      hardwareIconColor: Colors.white,
      connectedColor: const Color(0xFF69F0AE), // Bright green accent
      connectingColor: const Color(0xFFFFD54F), // Amber
      disconnectedColor: const Color(0xFFC62828), // Dark red
      errorColor: const Color(0xFFC62828), // Dark red
    );
  }

  /// Carnival Derby — Lava Red/Canary Yellow, Montserrat font
  factory DartboardConnectionInfoConfig.carnivalDerby() {
    return DartboardConnectionInfoConfig(
      backgroundColor: GameTheme.carnivalDerby.background, // Midnight Navy
      backgroundOpacity: 0.95,
      emulatorBorderColor: GameTheme.carnivalDerby.accent, // Canary Yellow
      hardwareBorderColor: const Color(0xFF48CAE4), // Electric Teal
      nameTextStyle: GoogleFonts.montserrat(
        fontSize: 12,
        fontWeight: FontWeight.w900,
        color: GameTheme.carnivalDerby.onDark, // Cloud Dancer
      ),
      statusTextStyle: GoogleFonts.montserrat(
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
      emulatorLabelTextStyle: GoogleFonts.montserrat(
        fontSize: 10,
        color: GameTheme.carnivalDerby.accent, // Canary Yellow
      ),
      emulatorIconColor: GameTheme.carnivalDerby.accent, // Canary Yellow
      hardwareIconColor: const Color(0xFF48CAE4), // Electric Teal
      connectedColor: const Color(0xFF48CAE4), // Electric Teal
      connectingColor: GameTheme.carnivalDerby.accent, // Canary Yellow
      disconnectedColor: const Color(0xFFE63946), // Lava Red
      errorColor: const Color(0xFFE63946), // Lava Red
    );
  }

  /// Target Tag — Dark navy with Hot Pink/Neon Green, Fredoka font
  factory DartboardConnectionInfoConfig.targetTag() {
    return DartboardConnectionInfoConfig(
      backgroundColor: const Color(0xFF2A2A3E), // Dark tech panel
      backgroundOpacity: 0.95,
      emulatorBorderColor: const Color(0xFF00FFA3), // Neon Green
      hardwareBorderColor: GameTheme.targetTag.accent, // Hot Pink
      nameTextStyle: GoogleFonts.fredoka(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      statusTextStyle: GoogleFonts.fredoka(
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
      emulatorLabelTextStyle: GoogleFonts.fredoka(
        fontSize: 10,
        color: const Color(0xFF00FFA3), // Neon Green
      ),
      emulatorIconColor: const Color(0xFF00FFA3), // Neon Green
      hardwareIconColor: GameTheme.targetTag.accent, // Hot Pink
      connectedColor: const Color(0xFF00FFA3), // Neon Green
      connectingColor: const Color(0xFFFFD700), // Gold
      disconnectedColor: GameTheme.targetTag.accent, // Hot Pink
      errorColor: GameTheme.targetTag.accent, // Hot Pink
    );
  }

  /// Monster Mash — Dark with Lime Green/Beige, Montserrat font
  factory DartboardConnectionInfoConfig.monsterMash() {
    return DartboardConnectionInfoConfig(
      backgroundColor: GameTheme.monsterMash.background, // Iron Gate
      backgroundOpacity: 0.95,
      emulatorBorderColor: GameTheme.monsterMash.accent, // Ecto-Green
      hardwareBorderColor: GameTheme.monsterMash.onDark, // Aged Parchment
      nameTextStyle: GoogleFonts.montserrat(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: GameTheme.monsterMash.onDark, // Aged Parchment
      ),
      statusTextStyle: GoogleFonts.montserrat(
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
      emulatorLabelTextStyle: GoogleFonts.montserrat(
        fontSize: 10,
        color: GameTheme.monsterMash.accent, // Ecto-Green
      ),
      emulatorIconColor: GameTheme.monsterMash.accent, // Ecto-Green
      hardwareIconColor: GameTheme.monsterMash.onDark, // Aged Parchment
      connectedColor: GameTheme.monsterMash.accent, // Ecto-Green
      connectingColor: const Color(0xFFFF8C00), // Pumpkin Orange
      disconnectedColor: Colors.red,
      errorColor: Colors.red,
    );
  }

  /// Dartboard Emulator — Deep Forest Green/Crimson, classic dartboard feel
  factory DartboardConnectionInfoConfig.dartboardEmulator() {
    return DartboardConnectionInfoConfig(
      backgroundColor: const Color(0xFF1B2A1B), // Deep Forest
      backgroundOpacity: 0.95,
      emulatorBorderColor: const Color(0xFFFFD700), // Gold
      hardwareBorderColor: const Color(0xFFE8E8E8), // Silver Wire
      nameTextStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Color(0xFFF0E6D3), // Cream
      ),
      statusTextStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
      emulatorLabelTextStyle: const TextStyle(
        fontSize: 10,
        color: Color(0xFFFFD700), // Gold
      ),
      emulatorIconColor: const Color(0xFFFFD700), // Gold
      hardwareIconColor: const Color(0xFFE8E8E8), // Silver Wire
      connectedColor: const Color(0xFF4CAF50), // Dartboard Green
      connectingColor: const Color(0xFFFFD700), // Gold
      disconnectedColor: const Color(0xFFD32F2F), // Dartboard Red
      errorColor: const Color(0xFFD32F2F), // Dartboard Red
    );
  }

  /// API Logger — Dark Teal/Cyan, data terminal feel
  factory DartboardConnectionInfoConfig.apiLogger() {
    return DartboardConnectionInfoConfig(
      backgroundColor: const Color(0xFF0D2B2B), // Deep Teal Dark
      backgroundOpacity: 0.95,
      emulatorBorderColor: const Color(0xFF4DD0E1), // Cyan accent
      hardwareBorderColor: const Color(0xFF80CBC4), // Teal light
      nameTextStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Color(0xFFE0F2F1), // Teal 50
      ),
      statusTextStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
      emulatorLabelTextStyle: const TextStyle(
        fontSize: 10,
        color: Color(0xFF4DD0E1), // Cyan accent
      ),
      emulatorIconColor: const Color(0xFF4DD0E1), // Cyan accent
      hardwareIconColor: const Color(0xFF80CBC4), // Teal light
      connectedColor: const Color(0xFF26A69A), // Teal 400
      connectingColor: const Color(0xFFFFB74D), // Amber light
      disconnectedColor: const Color(0xFFEF5350), // Red 400
      errorColor: const Color(0xFFEF5350), // Red 400
    );
  }

  /// Reef Royale — Deep Reef Blue with Seafoam Green, Fredoka font
  factory DartboardConnectionInfoConfig.reefRoyale() {
    return DartboardConnectionInfoConfig(
      backgroundColor: GameTheme.reefRoyale.background, // Deep Reef Blue
      backgroundOpacity: 0.95,
      emulatorBorderColor: GameTheme.reefRoyale.accent, // Seafoam Green
      hardwareBorderColor: const Color(0xFF00CED1), // Sunlit Aqua
      nameTextStyle: GoogleFonts.fredoka(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: GameTheme.reefRoyale.onDark, // Pearl White
      ),
      statusTextStyle: GoogleFonts.fredoka(
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
      emulatorLabelTextStyle: GoogleFonts.fredoka(
        fontSize: 10,
        color: GameTheme.reefRoyale.accent, // Seafoam Green
      ),
      emulatorIconColor: GameTheme.reefRoyale.accent, // Seafoam Green
      hardwareIconColor: const Color(0xFF00CED1), // Sunlit Aqua
      connectedColor: GameTheme.reefRoyale.accent, // Seafoam Green
      connectingColor: const Color(0xFFF4D03F), // Sandy Gold
      disconnectedColor: const Color(0xFFFF6B6B), // Coral Pink
      errorColor: const Color(0xFFFF6B6B), // Coral Pink
    );
  }

  /// Lunar Lander — Earth Blue with Rocket Flame icon, Orbitron/Exo2 fonts
  factory DartboardConnectionInfoConfig.lunarLander() {
    return DartboardConnectionInfoConfig(
      backgroundColor: GameTheme.lunarLander.background, // Earth Blue
      backgroundOpacity: 0.95,
      emulatorBorderColor: GameTheme.lunarLander.accent, // Rocket Flame
      hardwareBorderColor: const Color(0xFF52B788), // Mission Green
      nameTextStyle: GoogleFonts.exo2(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: GameTheme.lunarLander.onDark, // Star White
      ),
      statusTextStyle: GoogleFonts.exo2(
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
      emulatorLabelTextStyle: GoogleFonts.exo2(
        fontSize: 10,
        color: GameTheme.lunarLander.accent, // Rocket Flame
      ),
      emulatorIconColor: GameTheme.lunarLander.accent, // Rocket Flame
      hardwareIconColor: const Color(0xFF52B788), // Mission Green
      connectedColor: const Color(0xFF52B788), // Mission Green
      connectingColor: const Color(0xFFD4C5A9), // Moon Dust Gray
      disconnectedColor: const Color(0xFFE63946), // Thruster Red
      errorColor: const Color(0xFFE63946), // Thruster Red
    );
  }

  /// Pirate's Grid — Ocean Navy bg, Compass Bronze/Treasure Gold, Lora font
  factory DartboardConnectionInfoConfig.piratesGrid() {
    return DartboardConnectionInfoConfig(
      backgroundColor: GameTheme.piratesGrid.background, // Ocean Navy
      backgroundOpacity: 0.95,
      emulatorBorderColor: GameTheme.piratesGrid.accent, // Compass Bronze
      hardwareBorderColor: const Color(0xFFDAA520), // Treasure Gold
      nameTextStyle: GoogleFonts.lora(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: GameTheme.piratesGrid.onDark, // Parchment Tan
      ),
      statusTextStyle: GoogleFonts.lora(
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
      emulatorLabelTextStyle: GoogleFonts.lora(
        fontSize: 10,
        color: GameTheme.piratesGrid.accent, // Compass Bronze
      ),
      emulatorIconColor: GameTheme.piratesGrid.accent, // Compass Bronze
      hardwareIconColor: const Color(0xFFDAA520), // Treasure Gold
      connectedColor: const Color(0xFF2E8B8B), // Sea Foam Teal
      connectingColor: const Color(0xFFDAA520), // Treasure Gold
      disconnectedColor: const Color(0xFF8B0000), // Blood Red
      errorColor: const Color(0xFF8B0000), // Blood Red
    );
  }

  factory DartboardConnectionInfoConfig.clockworkQuest() {
    return DartboardConnectionInfoConfig(
      backgroundColor: GameTheme.clockworkQuest.background, // Dark Iron
      backgroundOpacity: 0.95,
      emulatorBorderColor: const Color(0xFFB87333), // Copper Rose
      hardwareBorderColor: GameTheme.clockworkQuest.accent, // Brass Gold
      nameTextStyle: GoogleFonts.lato(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        height: 1.0,
        color: GameTheme.clockworkQuest.onDark, // Steam White
      ),
      statusTextStyle: GoogleFonts.lato(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        height: 1.0,
      ),
      emulatorLabelTextStyle: GoogleFonts.lato(
        fontSize: 10,
        height: 1.0,
        color: const Color(0xFFB87333), // Copper Rose
      ),
      emulatorIconColor: const Color(0xFFB87333), // Copper Rose
      hardwareIconColor: GameTheme.clockworkQuest.accent, // Brass Gold
      connectedColor: const Color(0xFF43B3AE), // Verdigris Green
      connectingColor: const Color(0xFFFFBF00), // Amber Glow
      disconnectedColor: const Color(0xFFFF6B6B),
      errorColor: const Color(0xFFFF6B6B),
    );
  }

  factory DartboardConnectionInfoConfig.gladiatorArena() {
    return DartboardConnectionInfoConfig(
      backgroundColor: GameTheme.gladiatorArena.background, // Dark Arena
      backgroundOpacity: 0.95,
      emulatorBorderColor: GameTheme.gladiatorArena.accent, // Bronze
      hardwareBorderColor: const Color(0xFFDAA520), // Gladiator Gold
      // Lato (mixed-case) matches every other game's dartboard-name styling.
      // Cinzel renders lowercase as capital letterforms (Roman-inscription
      // font), which made the dartboard name appear upcased — inconsistent
      // with the other 7 games' connection widgets.
      nameTextStyle: GoogleFonts.lato(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        height: 1.0,
        color: GameTheme.gladiatorArena.onDark, // Marble White
      ),
      statusTextStyle: GoogleFonts.lato(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        height: 1.0,
      ),
      emulatorLabelTextStyle: GoogleFonts.lato(
        fontSize: 10,
        height: 1.0,
        color: GameTheme.gladiatorArena.accent, // Bronze
      ),
      emulatorIconColor: GameTheme.gladiatorArena.accent, // Bronze
      hardwareIconColor: const Color(0xFFDAA520), // Gladiator Gold
      connectedColor: const Color(0xFF4A7C59), // Laurel Green
      connectingColor: const Color(0xFFDAA520), // Gladiator Gold
      disconnectedColor: const Color(0xFFC0392B), // Blood Red
      errorColor: const Color(0xFFC0392B), // Blood Red
    );
  }

  /// Treasure Divide — Ocean Teal panel, Treasure Gold/Island Green indicators, Merriweather font
  factory DartboardConnectionInfoConfig.treasureDivide() {
    return DartboardConnectionInfoConfig(
      backgroundColor: GameTheme.treasureDivide.background, // Ocean Teal
      backgroundOpacity: 0.95,
      emulatorBorderColor: GameTheme.treasureDivide.accent, // Treasure Gold
      hardwareBorderColor: const Color(0xFF228B22), // Island Green
      nameTextStyle: GoogleFonts.merriweather(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        height: 1.0,
        color: GameTheme.treasureDivide.onDark, // Sail White
      ),
      statusTextStyle: GoogleFonts.merriweather(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        height: 1.0,
      ),
      emulatorLabelTextStyle: GoogleFonts.merriweather(
        fontSize: 10,
        height: 1.0,
        color: GameTheme.treasureDivide.accent, // Treasure Gold
      ),
      emulatorIconColor: GameTheme.treasureDivide.accent, // Treasure Gold
      hardwareIconColor: const Color(0xFF228B22), // Island Green
      connectedColor: const Color(0xFF228B22), // Island Green
      connectingColor: GameTheme.treasureDivide.accent, // Treasure Gold
      disconnectedColor: const Color(0xFFC41E3A), // Blood Red
      errorColor: const Color(0xFFC41E3A), // Blood Red
    );
  }

  /// Tiki Golf — Palm Green panel, Lagoon Blue accents for all dartboard
  /// status indicators (border, icon, connected text) per user request so the
  /// status reads the same color across all three Tiki Golf AppBars. Pink
  /// is kept for disconnected/error so the user still gets a clear failure
  /// signal that's visually distinct from the normal blue.
  factory DartboardConnectionInfoConfig.tikiGolf() {
    return DartboardConnectionInfoConfig(
      backgroundColor: GameTheme.tikiGolf.background, // Palm Green
      backgroundOpacity: 0.95,
      emulatorBorderColor: GameTheme.tikiGolf.accent, // Lagoon Blue
      hardwareBorderColor: GameTheme.tikiGolf.accent, // Lagoon Blue (was Tropical Orange)
      nameTextStyle: GoogleFonts.boogaloo(
        fontSize: 12,
        color: GameTheme.tikiGolf.onDark, // Sand White
      ),
      statusTextStyle: GoogleFonts.nunito(
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
      emulatorLabelTextStyle: GoogleFonts.nunito(
        fontSize: 10,
        color: GameTheme.tikiGolf.accent, // Lagoon Blue
      ),
      emulatorIconColor: GameTheme.tikiGolf.accent, // Lagoon Blue
      hardwareIconColor: GameTheme.tikiGolf.accent, // Lagoon Blue (was Tropical Orange)
      connectedColor: GameTheme.tikiGolf.accent, // Lagoon Blue
      connectingColor: GameTheme.tikiGolf.accent, // Lagoon Blue (was Tropical Orange)
      disconnectedColor: const Color(0xFFFF69B4), // Hibiscus Pink
      errorColor: const Color(0xFFFF69B4), // Hibiscus Pink
    );
  }
}
