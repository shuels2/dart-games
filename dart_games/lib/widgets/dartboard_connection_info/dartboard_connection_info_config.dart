import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
      backgroundColor: const Color(0xFF1D3557), // Midnight Navy
      backgroundOpacity: 0.95,
      emulatorBorderColor: const Color(0xFFFFD700), // Canary Yellow
      hardwareBorderColor: const Color(0xFF48CAE4), // Electric Teal
      nameTextStyle: GoogleFonts.montserrat(
        fontSize: 12,
        fontWeight: FontWeight.w900,
        color: const Color(0xFFF1FAEE), // Cloud Dancer
      ),
      statusTextStyle: GoogleFonts.montserrat(
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
      emulatorLabelTextStyle: GoogleFonts.montserrat(
        fontSize: 10,
        color: const Color(0xFFFFD700), // Canary Yellow
      ),
      emulatorIconColor: const Color(0xFFFFD700), // Canary Yellow
      hardwareIconColor: const Color(0xFF48CAE4), // Electric Teal
      connectedColor: const Color(0xFF48CAE4), // Electric Teal
      connectingColor: const Color(0xFFFFD700), // Canary Yellow
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
      hardwareBorderColor: const Color(0xFFFF007A), // Hot Pink
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
      hardwareIconColor: const Color(0xFFFF007A), // Hot Pink
      connectedColor: const Color(0xFF00FFA3), // Neon Green
      connectingColor: const Color(0xFFFFD700), // Gold
      disconnectedColor: const Color(0xFFFF007A), // Hot Pink
      errorColor: const Color(0xFFFF007A), // Hot Pink
    );
  }

  /// Monster Mash — Dark with Lime Green/Beige, Montserrat font
  factory DartboardConnectionInfoConfig.monsterMash() {
    return DartboardConnectionInfoConfig(
      backgroundColor: const Color(0xFF2F4F4F), // Iron Gate
      backgroundOpacity: 0.95,
      emulatorBorderColor: const Color(0xFF7FFF00), // Ecto-Green
      hardwareBorderColor: const Color(0xFFF5F5DC), // Aged Parchment
      nameTextStyle: GoogleFonts.montserrat(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: const Color(0xFFF5F5DC), // Aged Parchment
      ),
      statusTextStyle: GoogleFonts.montserrat(
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
      emulatorLabelTextStyle: GoogleFonts.montserrat(
        fontSize: 10,
        color: const Color(0xFF7FFF00), // Ecto-Green
      ),
      emulatorIconColor: const Color(0xFF7FFF00), // Ecto-Green
      hardwareIconColor: const Color(0xFFF5F5DC), // Aged Parchment
      connectedColor: const Color(0xFF7FFF00), // Ecto-Green
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
      backgroundColor: const Color(0xFF0B3D91), // Deep Reef Blue
      backgroundOpacity: 0.95,
      emulatorBorderColor: const Color(0xFF48D1CC), // Seafoam Green
      hardwareBorderColor: const Color(0xFF00CED1), // Sunlit Aqua
      nameTextStyle: GoogleFonts.fredoka(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: const Color(0xFFFFF8F0), // Pearl White
      ),
      statusTextStyle: GoogleFonts.fredoka(
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
      emulatorLabelTextStyle: GoogleFonts.fredoka(
        fontSize: 10,
        color: const Color(0xFF48D1CC), // Seafoam Green
      ),
      emulatorIconColor: const Color(0xFF48D1CC), // Seafoam Green
      hardwareIconColor: const Color(0xFF00CED1), // Sunlit Aqua
      connectedColor: const Color(0xFF48D1CC), // Seafoam Green
      connectingColor: const Color(0xFFF4D03F), // Sandy Gold
      disconnectedColor: const Color(0xFFFF6B6B), // Coral Pink
      errorColor: const Color(0xFFFF6B6B), // Coral Pink
    );
  }
}
