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
}
