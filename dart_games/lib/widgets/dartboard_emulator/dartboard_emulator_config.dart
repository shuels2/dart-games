import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
}
