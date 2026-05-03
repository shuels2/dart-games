import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SaveGameModalConfig {
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
  final Color saveButtonColor;
  final Color saveButtonTextColor;
  final TextStyle saveButtonTextStyle;
  final Color dontSaveButtonColor;
  final Color dontSaveButtonTextColor;
  final TextStyle dontSaveButtonTextStyle;
  final EdgeInsets saveButtonPadding;
  final EdgeInsets dontSaveButtonPadding;
  final double maxWidth;
  final EdgeInsets margin;
  final EdgeInsets padding;

  const SaveGameModalConfig({
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
    required this.saveButtonColor,
    required this.saveButtonTextColor,
    required this.saveButtonTextStyle,
    required this.dontSaveButtonColor,
    required this.dontSaveButtonTextColor,
    required this.dontSaveButtonTextStyle,
    this.saveButtonPadding = const EdgeInsets.symmetric(vertical: 14),
    this.dontSaveButtonPadding = const EdgeInsets.symmetric(vertical: 14),
    this.maxWidth = 420,
    this.margin = const EdgeInsets.all(16),
    this.padding = const EdgeInsets.all(32),
  });

  factory SaveGameModalConfig.carnivalDerby() {
    return SaveGameModalConfig(
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
      saveButtonColor: const Color(0xFFFFD700),
      saveButtonTextColor: const Color(0xFF1D3557),
      saveButtonTextStyle: GoogleFonts.luckiestGuy(fontSize: 20),
      saveButtonPadding: const EdgeInsets.only(top: 17, bottom: 11),
      dontSaveButtonColor: Colors.transparent,
      dontSaveButtonTextColor: const Color(0xFFF1FAEE),
      dontSaveButtonTextStyle: GoogleFonts.bangers(fontSize: 18, letterSpacing: 1.0),
    );
  }

  factory SaveGameModalConfig.targetTag() {
    return SaveGameModalConfig(
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
      saveButtonColor: const Color(0xFFFF007A),
      saveButtonTextColor: Colors.white,
      saveButtonTextStyle: GoogleFonts.luckiestGuy(fontSize: 20),
      saveButtonPadding: const EdgeInsets.only(top: 17, bottom: 11),
      dontSaveButtonColor: Colors.transparent,
      dontSaveButtonTextColor: Colors.white,
      dontSaveButtonTextStyle: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.w600),
    );
  }

  factory SaveGameModalConfig.monsterMash() {
    return SaveGameModalConfig(
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
      saveButtonColor: const Color(0xFF7FFF00),
      saveButtonTextColor: const Color(0xFF2F4F4F),
      saveButtonTextStyle: GoogleFonts.creepster(fontSize: 20),
      saveButtonPadding: const EdgeInsets.only(top: 14, bottom: 14),
      dontSaveButtonColor: Colors.transparent,
      dontSaveButtonTextColor: const Color(0xFFF5F5DC),
      dontSaveButtonTextStyle: GoogleFonts.pirataOne(fontSize: 18),
    );
  }

  factory SaveGameModalConfig.reefRoyale() {
    return SaveGameModalConfig(
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
      saveButtonColor: const Color(0xFF48D1CC),
      saveButtonTextColor: const Color(0xFF0B3D91),
      saveButtonTextStyle: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.bold),
      dontSaveButtonColor: Colors.transparent,
      dontSaveButtonTextColor: const Color(0xFFFFF8F0),
      dontSaveButtonTextStyle: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.w600),
      dontSaveButtonPadding: const EdgeInsets.only(top: 12, bottom: 16),
    );
  }

  factory SaveGameModalConfig.lunarLander() {
    return SaveGameModalConfig(
      backgroundColor: const Color(0xFF1B4965), // Earth Blue
      borderColor: const Color(0xFFF26430), // Rocket Flame
      boxShadowColor: const Color(0xFFF26430),
      boxShadowOpacity: 0.3,
      iconColor: const Color(0xFFF26430), // Rocket Flame
      iconSize: 48,
      titleTextStyle: GoogleFonts.orbitron(
        color: const Color(0xFFF26430), // Rocket Flame
        fontSize: 22,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
      messageTextStyle: GoogleFonts.exo2(
        color: const Color(0xFFFAFDF6), // Star White
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      saveButtonColor: const Color(0xFFF26430), // Rocket Flame
      saveButtonTextColor: const Color(0xFFFAFDF6),
      saveButtonTextStyle: GoogleFonts.orbitron(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.0),
      dontSaveButtonColor: Colors.transparent,
      dontSaveButtonTextColor: const Color(0xFFFAFDF6),
      dontSaveButtonTextStyle: GoogleFonts.exo2(fontSize: 16, fontWeight: FontWeight.w600),
    );
  }

  factory SaveGameModalConfig.clockworkQuest() {
    return SaveGameModalConfig(
      backgroundColor: const Color(0xFF2C2C34), // Dark Iron
      borderColor: const Color(0xFFC5A54E), // Brass Gold
      boxShadowColor: const Color(0xFFFFBF00), // Amber Glow
      boxShadowOpacity: 0.4,
      iconColor: const Color(0xFFC5A54E),
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
      saveButtonColor: const Color(0xFFC5A54E), // Brass Gold
      saveButtonTextColor: const Color(0xFF2C2C34), // Dark Iron
      saveButtonTextStyle: GoogleFonts.cinzelDecorative(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.0,
      ),
      dontSaveButtonColor: Colors.transparent,
      dontSaveButtonTextColor: const Color(0xFFF5F0E8),
      dontSaveButtonTextStyle: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.w600),
      dontSaveButtonPadding: const EdgeInsets.only(top: 12, bottom: 16),
    );
  }
}
