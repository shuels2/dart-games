import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
      backgroundColor: const Color(0xFF1D3557), // Midnight Navy
      backgroundOpacity: 0.95,
      borderColor: const Color(0xFFFFD700), // Canary Yellow
      borderWidth: 4,
      boxShadowColor: Colors.black,
      boxShadowOpacity: 0.5,
      iconColor: Colors.white,
      iconSize: 64,
      playerNameTextStyle: GoogleFonts.luckiestGuy(
        color: const Color(0xFFFFD700), // Canary Yellow
        fontSize: 28,
      ),
      instructionTextStyle: GoogleFonts.bangers(
        color: const Color(0xFFF1FAEE), // Cloud Dancer
        fontSize: 24,
        letterSpacing: 1.0,
      ),
      buttonBackgroundColor: const Color(0xFFFFD700), // Canary Yellow
      buttonForegroundColor: const Color(0xFF1D3557), // Midnight Navy
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
      backgroundColor: const Color(0xFF1A1A2E), // Dark navy
      backgroundOpacity: 0.95,
      borderColor: const Color(0xFFFF007A), // Hot Pink
      borderWidth: 4,
      boxShadowColor: Colors.black,
      boxShadowOpacity: 0.5,
      iconColor: Colors.white,
      iconSize: 48,
      playerNameTextStyle: GoogleFonts.luckiestGuy(
        color: const Color(0xFFFF007A), // Hot Pink
        fontSize: 24,
      ),
      instructionTextStyle: GoogleFonts.fredoka(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.0,
      ),
      buttonBackgroundColor: const Color(0xFFFF007A).withOpacity(0.85),
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
      backgroundColor: const Color(0xFF2F4F4F), // Iron Gate
      backgroundOpacity: 0.95,
      borderColor: const Color(0xFF7FFF00), // Ecto-Green
      borderWidth: 4,
      boxShadowColor: const Color(0xFF7FFF00), // Ecto-Green glow
      boxShadowOpacity: 0.3,
      iconColor: const Color(0xFFF5F5DC), // Aged Parchment
      iconSize: 48,
      playerNameTextStyle: GoogleFonts.creepster(
        color: const Color(0xFF7FFF00), // Ecto-Green
        fontSize: 24,
      ),
      instructionTextStyle: GoogleFonts.pirataOne(
        color: const Color(0xFFF5F5DC), // Aged Parchment
        fontSize: 20,
      ),
      buttonBackgroundColor: const Color(0xFF4B0082).withOpacity(0.85), // Haunted Purple
      buttonForegroundColor: const Color(0xFFF5F5DC), // Aged Parchment
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
      backgroundColor: const Color(0xFF0B3D91), // Deep Reef Blue
      backgroundOpacity: 0.95,
      borderColor: const Color(0xFF48D1CC), // Seafoam Green
      borderWidth: 4,
      boxShadowColor: const Color(0xFF48D1CC), // Seafoam glow
      boxShadowOpacity: 0.3,
      iconColor: const Color(0xFFFFF8F0), // Pearl White
      iconSize: 48,
      playerNameTextStyle: GoogleFonts.fredoka(
        color: const Color(0xFF48D1CC), // Seafoam Green
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      instructionTextStyle: GoogleFonts.fredoka(
        color: const Color(0xFFFFF8F0), // Pearl White
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.0,
      ),
      buttonBackgroundColor: const Color(0xFF48D1CC).withOpacity(0.85),
      buttonForegroundColor: const Color(0xFF0B3D91), // Deep Reef Blue
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
      backgroundColor: const Color(0xFF1B4965), // Earth Blue
      backgroundOpacity: 0.95,
      borderColor: const Color(0xFFF26430), // Rocket Flame
      borderWidth: 4,
      boxShadowColor: const Color(0xFFF26430),
      boxShadowOpacity: 0.3,
      iconColor: const Color(0xFFFAFDF6), // Star White
      iconSize: 48,
      playerNameTextStyle: GoogleFonts.orbitron(
        color: const Color(0xFFF26430), // Rocket Flame
        fontSize: 20,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.0,
      ),
      instructionTextStyle: GoogleFonts.exo2(
        color: const Color(0xFFFAFDF6), // Star White
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.0,
      ),
      buttonBackgroundColor: const Color(0xFFF26430).withOpacity(0.85), // Rocket Flame
      buttonForegroundColor: const Color(0xFFFAFDF6),
      buttonTextStyle: GoogleFonts.orbitron(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
      editButtonText: 'Edit player score',
      maxWidth: 400,
    );
  }

  factory RemoveDartsModalConfig.clockworkQuest() {
    return RemoveDartsModalConfig(
      backgroundColor: const Color(0xFF2C2C34), // Dark Iron
      backgroundOpacity: 0.95,
      borderColor: const Color(0xFFC5A54E), // Brass Gold
      borderWidth: 4,
      boxShadowColor: const Color(0xFFFFBF00), // Amber Glow
      boxShadowOpacity: 0.4,
      iconColor: const Color(0xFFF5F0E8), // Steam White
      iconSize: 48,
      playerNameTextStyle: GoogleFonts.cinzelDecorative(
        color: const Color(0xFFC5A54E), // Brass Gold
        fontSize: 24,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
      instructionTextStyle: GoogleFonts.lato(
        color: const Color(0xFFF5F0E8), // Steam White
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.0,
      ),
      buttonBackgroundColor: const Color(0xFFC5A54E).withOpacity(0.85), // Brass Gold
      buttonForegroundColor: const Color(0xFF2C2C34), // Dark Iron
      buttonTextStyle: GoogleFonts.cinzelDecorative(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.0,
      ),
      editButtonText: 'Edit player score',
      maxWidth: 400,
    );
  }
}
