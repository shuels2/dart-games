import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
      backgroundColor: const Color(0xFF1D3557),
      borderColor: const Color(0xFFFFD700),
      boxShadowColor: Colors.black,
      boxShadowOpacity: 0.5,
      iconColor: const Color(0xFFFFD700),
      iconSize: 56,
      titleTextStyle: GoogleFonts.luckiestGuy(
        color: const Color(0xFFFFD700),
        fontSize: 28,
      ),
      messageTextStyle: GoogleFonts.bangers(
        color: const Color(0xFFF1FAEE),
        fontSize: 20,
        letterSpacing: 1.0,
      ),
    );
  }

  /// Target Tag — Dark navy with Hot Pink border
  factory DartboardPausedModalConfig.targetTag() {
    return DartboardPausedModalConfig(
      backgroundColor: const Color(0xFF1A1A2E),
      borderColor: const Color(0xFFFF007A),
      boxShadowColor: Colors.black,
      boxShadowOpacity: 0.5,
      iconColor: const Color(0xFFFF007A),
      iconSize: 48,
      titleTextStyle: GoogleFonts.luckiestGuy(
        color: const Color(0xFFFF007A),
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
      backgroundColor: const Color(0xFF2F4F4F),
      borderColor: const Color(0xFF7FFF00),
      boxShadowColor: const Color(0xFF7FFF00),
      boxShadowOpacity: 0.3,
      iconColor: const Color(0xFF7FFF00),
      iconSize: 48,
      titleTextStyle: GoogleFonts.creepster(
        color: const Color(0xFF7FFF00),
        fontSize: 28,
      ),
      messageTextStyle: GoogleFonts.pirataOne(
        color: const Color(0xFFF5F5DC),
        fontSize: 18,
      ),
    );
  }

  /// Reef Royale — Deep Reef Blue with Seafoam Green border
  factory DartboardPausedModalConfig.reefRoyale() {
    return DartboardPausedModalConfig(
      backgroundColor: const Color(0xFF0B3D91),
      borderColor: const Color(0xFF48D1CC),
      boxShadowColor: const Color(0xFF48D1CC),
      boxShadowOpacity: 0.3,
      iconColor: const Color(0xFF48D1CC),
      iconSize: 48,
      titleTextStyle: GoogleFonts.fredoka(
        color: const Color(0xFF48D1CC),
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      messageTextStyle: GoogleFonts.fredoka(
        color: const Color(0xFFFFF8F0),
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  /// Lunar Lander — Earth Blue with Thruster Red icon, Orbitron/Exo2 fonts
  factory DartboardPausedModalConfig.lunarLander() {
    return DartboardPausedModalConfig(
      backgroundColor: const Color(0xFF1B4965), // Earth Blue
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
        color: const Color(0xFFFAFDF6), // Star White
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

  factory DartboardPausedModalConfig.clockworkQuest() {
    return DartboardPausedModalConfig(
      backgroundColor: const Color(0xFF2C2C34), // Dark Iron
      borderColor: const Color(0xFFC5A54E), // Brass Gold
      boxShadowColor: const Color(0xFFFFBF00), // Amber Glow
      boxShadowOpacity: 0.4,
      iconColor: const Color(0xFFC5A54E), // Brass Gold
      iconSize: 48,
      titleTextStyle: GoogleFonts.cinzelDecorative(
        color: const Color(0xFFC5A54E),
        fontSize: 24,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
      messageTextStyle: GoogleFonts.lato(
        color: const Color(0xFFF5F0E8), // Steam White
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
