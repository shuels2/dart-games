import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ResumeGameModalConfig {
  final Color backgroundColor;
  final double backgroundOpacity;
  final Color borderColor;
  final double borderWidth;
  final double borderRadius;
  final Color boxShadowColor;
  final double boxShadowOpacity;
  final TextStyle titleTextStyle;

  // Tile styling
  final Color tileBackgroundColor;
  final Color tileSelectedBackgroundColor;
  final Color tileBorderColor;
  final Color tileSelectedBorderColor;
  final double tileBorderWidth;
  final double tileBorderRadius;
  final TextStyle tileDateTextStyle;
  final TextStyle tilePlayersTextStyle;
  final TextStyle tileProgressTextStyle;
  final TextStyle tileModeTextStyle;
  final TextStyle tileLeaderTextStyle;
  final Color deleteButtonColor;

  // Button styling
  final Color resumeButtonColor;
  final Color resumeButtonTextColor;
  final TextStyle resumeButtonTextStyle;
  final EdgeInsets resumeButtonPadding;
  final Color resumeButtonDisabledColor;
  final Color startNewButtonColor;
  final Color startNewButtonTextColor;
  final TextStyle startNewButtonTextStyle;
  final EdgeInsets startNewButtonPadding;
  final Color deleteAllButtonColor;
  final TextStyle deleteAllButtonTextStyle;

  final double maxWidth;
  final double maxHeight;
  final EdgeInsets margin;
  final EdgeInsets padding;

  const ResumeGameModalConfig({
    required this.backgroundColor,
    this.backgroundOpacity = 0.95,
    required this.borderColor,
    this.borderWidth = 4.0,
    this.borderRadius = 12.0,
    required this.boxShadowColor,
    required this.boxShadowOpacity,
    required this.titleTextStyle,
    required this.tileBackgroundColor,
    required this.tileSelectedBackgroundColor,
    required this.tileBorderColor,
    required this.tileSelectedBorderColor,
    this.tileBorderWidth = 2.0,
    this.tileBorderRadius = 8.0,
    required this.tileDateTextStyle,
    required this.tilePlayersTextStyle,
    required this.tileProgressTextStyle,
    required this.tileModeTextStyle,
    required this.tileLeaderTextStyle,
    required this.deleteButtonColor,
    required this.resumeButtonColor,
    required this.resumeButtonTextColor,
    required this.resumeButtonTextStyle,
    this.resumeButtonPadding = const EdgeInsets.symmetric(vertical: 14),
    required this.resumeButtonDisabledColor,
    required this.startNewButtonColor,
    required this.startNewButtonTextColor,
    required this.startNewButtonTextStyle,
    this.startNewButtonPadding = const EdgeInsets.symmetric(vertical: 14),
    required this.deleteAllButtonColor,
    required this.deleteAllButtonTextStyle,
    this.maxWidth = 520,
    this.maxHeight = 600,
    this.margin = const EdgeInsets.all(16),
    this.padding = const EdgeInsets.all(24),
  });

  factory ResumeGameModalConfig.carnivalDerby() {
    return ResumeGameModalConfig(
      backgroundColor: const Color(0xFF1D3557),
      borderColor: const Color(0xFFFFD700),
      boxShadowColor: Colors.black,
      boxShadowOpacity: 0.5,
      titleTextStyle: GoogleFonts.luckiestGuy(
        color: const Color(0xFFFFD700),
        fontSize: 24,
      ),
      tileBackgroundColor: const Color(0xFF1D3557).withOpacity(0.6),
      tileSelectedBackgroundColor: const Color(0xFFFFD700).withOpacity(0.15),
      tileBorderColor: const Color(0xFFF1FAEE).withOpacity(0.3),
      tileSelectedBorderColor: const Color(0xFFFFD700),
      tileDateTextStyle: GoogleFonts.bangers(
        color: const Color(0xFFF1FAEE).withOpacity(0.7),
        fontSize: 13,
        letterSpacing: 0.5,
      ),
      tilePlayersTextStyle: GoogleFonts.bangers(
        color: const Color(0xFFF1FAEE),
        fontSize: 16,
        letterSpacing: 0.5,
      ),
      tileProgressTextStyle: GoogleFonts.luckiestGuy(
        color: const Color(0xFFFFD700),
        fontSize: 14,
      ),
      tileModeTextStyle: GoogleFonts.bangers(
        color: const Color(0xFFF1FAEE).withOpacity(0.7),
        fontSize: 13,
        letterSpacing: 0.5,
      ),
      tileLeaderTextStyle: GoogleFonts.bangers(
        color: const Color(0xFFF1FAEE),
        fontSize: 14,
        letterSpacing: 0.5,
      ),
      deleteButtonColor: const Color(0xFFE63946),
      resumeButtonColor: const Color(0xFFFFD700),
      resumeButtonTextColor: const Color(0xFF1D3557),
      resumeButtonTextStyle: GoogleFonts.luckiestGuy(fontSize: 20),
      resumeButtonPadding: const EdgeInsets.only(top: 17, bottom: 11),
      resumeButtonDisabledColor: Colors.grey,
      startNewButtonColor: const Color(0xFFF1FAEE).withOpacity(0.2),
      startNewButtonTextColor: const Color(0xFFF1FAEE),
      startNewButtonTextStyle: GoogleFonts.bangers(fontSize: 18, letterSpacing: 1.0),
      deleteAllButtonColor: const Color(0xFFE63946),
      deleteAllButtonTextStyle: GoogleFonts.bangers(
        fontSize: 14,
        letterSpacing: 0.5,
        color: const Color(0xFFE63946),
      ),
    );
  }

  factory ResumeGameModalConfig.targetTag() {
    return ResumeGameModalConfig(
      backgroundColor: const Color(0xFF1A1A2E),
      borderColor: const Color(0xFFFF007A),
      boxShadowColor: Colors.black,
      boxShadowOpacity: 0.5,
      titleTextStyle: GoogleFonts.luckiestGuy(
        color: const Color(0xFFFF007A),
        fontSize: 24,
      ),
      tileBackgroundColor: const Color(0xFF1A1A2E).withOpacity(0.6),
      tileSelectedBackgroundColor: const Color(0xFFFF007A).withOpacity(0.15),
      tileBorderColor: Colors.white.withOpacity(0.3),
      tileSelectedBorderColor: const Color(0xFFFF007A),
      tileDateTextStyle: GoogleFonts.fredoka(
        color: Colors.white.withOpacity(0.7),
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      tilePlayersTextStyle: GoogleFonts.fredoka(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      tileProgressTextStyle: GoogleFonts.luckiestGuy(
        color: const Color(0xFFFF007A),
        fontSize: 14,
      ),
      tileModeTextStyle: GoogleFonts.fredoka(
        color: Colors.white.withOpacity(0.7),
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      tileLeaderTextStyle: GoogleFonts.fredoka(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      deleteButtonColor: const Color(0xFFFF007A),
      resumeButtonColor: const Color(0xFFFF007A),
      resumeButtonTextColor: Colors.white,
      resumeButtonTextStyle: GoogleFonts.luckiestGuy(fontSize: 20),
      resumeButtonPadding: const EdgeInsets.only(top: 17, bottom: 11),
      resumeButtonDisabledColor: Colors.grey,
      startNewButtonColor: Colors.white.withOpacity(0.2),
      startNewButtonTextColor: Colors.white,
      startNewButtonTextStyle: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.w600),
      deleteAllButtonColor: const Color(0xFFFF007A),
      deleteAllButtonTextStyle: GoogleFonts.fredoka(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: const Color(0xFFFF007A),
      ),
    );
  }

  factory ResumeGameModalConfig.monsterMash() {
    return ResumeGameModalConfig(
      backgroundColor: const Color(0xFF2F4F4F),
      borderColor: const Color(0xFF7FFF00),
      boxShadowColor: const Color(0xFF7FFF00),
      boxShadowOpacity: 0.3,
      titleTextStyle: GoogleFonts.creepster(
        color: const Color(0xFF7FFF00),
        fontSize: 24,
      ),
      tileBackgroundColor: const Color(0xFF2F4F4F).withOpacity(0.6),
      tileSelectedBackgroundColor: const Color(0xFF7FFF00).withOpacity(0.15),
      tileBorderColor: const Color(0xFFF5F5DC).withOpacity(0.3),
      tileSelectedBorderColor: const Color(0xFF7FFF00),
      tileDateTextStyle: GoogleFonts.pirataOne(
        color: const Color(0xFFF5F5DC).withOpacity(0.7),
        fontSize: 13,
      ),
      tilePlayersTextStyle: GoogleFonts.pirataOne(
        color: const Color(0xFFF5F5DC),
        fontSize: 16,
      ),
      tileProgressTextStyle: GoogleFonts.creepster(
        color: const Color(0xFF7FFF00),
        fontSize: 14,
      ),
      tileModeTextStyle: GoogleFonts.pirataOne(
        color: const Color(0xFFF5F5DC).withOpacity(0.7),
        fontSize: 13,
      ),
      tileLeaderTextStyle: GoogleFonts.pirataOne(
        color: const Color(0xFFF5F5DC),
        fontSize: 14,
      ),
      deleteButtonColor: const Color(0xFFFF4444),
      resumeButtonColor: const Color(0xFF7FFF00),
      resumeButtonTextColor: const Color(0xFF2F4F4F),
      resumeButtonTextStyle: GoogleFonts.creepster(fontSize: 20),
      resumeButtonPadding: const EdgeInsets.only(top: 14, bottom: 14),
      resumeButtonDisabledColor: Colors.grey,
      startNewButtonColor: const Color(0xFFF5F5DC).withOpacity(0.2),
      startNewButtonTextColor: const Color(0xFFF5F5DC),
      startNewButtonTextStyle: GoogleFonts.pirataOne(fontSize: 18),
      deleteAllButtonColor: const Color(0xFFFF4444),
      deleteAllButtonTextStyle: GoogleFonts.pirataOne(
        fontSize: 14,
        color: const Color(0xFFFF4444),
      ),
    );
  }

  factory ResumeGameModalConfig.reefRoyale() {
    return ResumeGameModalConfig(
      backgroundColor: const Color(0xFF0B3D91),
      borderColor: const Color(0xFF48D1CC),
      boxShadowColor: const Color(0xFF48D1CC),
      boxShadowOpacity: 0.3,
      titleTextStyle: GoogleFonts.fredoka(
        color: const Color(0xFF48D1CC),
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      tileBackgroundColor: const Color(0xFF0B3D91).withOpacity(0.6),
      tileSelectedBackgroundColor: const Color(0xFF48D1CC).withOpacity(0.15),
      tileBorderColor: const Color(0xFFFFF8F0).withOpacity(0.3),
      tileSelectedBorderColor: const Color(0xFF48D1CC),
      tileDateTextStyle: GoogleFonts.fredoka(
        color: const Color(0xFFFFF8F0).withOpacity(0.7),
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      tilePlayersTextStyle: GoogleFonts.fredoka(
        color: const Color(0xFFFFF8F0),
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      tileProgressTextStyle: GoogleFonts.fredoka(
        color: const Color(0xFF48D1CC),
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
      tileModeTextStyle: GoogleFonts.fredoka(
        color: const Color(0xFFFFF8F0).withOpacity(0.7),
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      tileLeaderTextStyle: GoogleFonts.fredoka(
        color: const Color(0xFFFFF8F0),
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      deleteButtonColor: const Color(0xFFFF6B6B),
      resumeButtonColor: const Color(0xFF48D1CC),
      resumeButtonTextColor: const Color(0xFF0B3D91),
      resumeButtonTextStyle: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.bold),
      resumeButtonDisabledColor: Colors.grey,
      startNewButtonColor: const Color(0xFFFFF8F0).withOpacity(0.2),
      startNewButtonTextColor: const Color(0xFFFFF8F0),
      startNewButtonTextStyle: GoogleFonts.fredoka(fontSize: 16, fontWeight: FontWeight.w600),
      startNewButtonPadding: const EdgeInsets.only(top: 12, bottom: 16),
      deleteAllButtonColor: const Color(0xFFFF6B6B),
      deleteAllButtonTextStyle: GoogleFonts.fredoka(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: const Color(0xFFFF6B6B),
      ),
    );
  }

  factory ResumeGameModalConfig.clockworkQuest() {
    return ResumeGameModalConfig(
      backgroundColor: const Color(0xFF2C2C34), // Dark Iron
      borderColor: const Color(0xFFC5A54E), // Brass Gold
      boxShadowColor: const Color(0xFFFFBF00), // Amber Glow
      boxShadowOpacity: 0.4,
      titleTextStyle: GoogleFonts.cinzelDecorative(
        color: const Color(0xFFC5A54E),
        fontSize: 24,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
      tileBackgroundColor: const Color(0xFF2C2C34).withOpacity(0.6),
      tileSelectedBackgroundColor: const Color(0xFFC5A54E).withOpacity(0.15),
      tileBorderColor: const Color(0xFFB87333).withOpacity(0.3), // Copper Rose
      tileSelectedBorderColor: const Color(0xFFC5A54E),
      tileDateTextStyle: GoogleFonts.lato(
        color: const Color(0xFFF5F0E8).withOpacity(0.6),
        fontSize: 11,
        fontWeight: FontWeight.w400,
      ),
      tilePlayersTextStyle: GoogleFonts.lato(
        color: const Color(0xFFF5F0E8).withOpacity(0.7),
        fontSize: 13,
      ),
      tileProgressTextStyle: GoogleFonts.lato(
        color: const Color(0xFFF5F0E8),
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
      tileModeTextStyle: GoogleFonts.lato(
        color: const Color(0xFFF5F0E8), // Steam White
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      tileLeaderTextStyle: GoogleFonts.lato(
        color: const Color(0xFFC5A54E),
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      deleteButtonColor: const Color(0xFFFF6B6B),
      resumeButtonColor: const Color(0xFFC5A54E), // Brass Gold
      resumeButtonTextColor: const Color(0xFF2C2C34),
      resumeButtonTextStyle: GoogleFonts.cinzelDecorative(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.0,
      ),
      resumeButtonDisabledColor: Colors.grey,
      startNewButtonColor: const Color(0xFFF5F0E8).withOpacity(0.2),
      startNewButtonTextColor: const Color(0xFFF5F0E8),
      startNewButtonTextStyle: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.w600),
      startNewButtonPadding: const EdgeInsets.only(top: 12, bottom: 16),
      deleteAllButtonColor: const Color(0xFFFF6B6B),
      deleteAllButtonTextStyle: GoogleFonts.lato(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: const Color(0xFFFF6B6B),
      ),
    );
  }
}
