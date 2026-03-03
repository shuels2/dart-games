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
}
