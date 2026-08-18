import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/game_theme.dart';

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
      backgroundColor: GameTheme.carnivalDerby.background,
      borderColor: GameTheme.carnivalDerby.accent,
      boxShadowColor: Colors.black,
      boxShadowOpacity: 0.5,
      titleTextStyle: GoogleFonts.luckiestGuy(
        color: GameTheme.carnivalDerby.accent,
        fontSize: 24,
      ),
      tileBackgroundColor: GameTheme.carnivalDerby.background.withOpacity(0.6),
      tileSelectedBackgroundColor: GameTheme.carnivalDerby.accent.withOpacity(0.15),
      tileBorderColor: GameTheme.carnivalDerby.onDark.withOpacity(0.3),
      tileSelectedBorderColor: GameTheme.carnivalDerby.accent,
      tileDateTextStyle: GoogleFonts.bangers(
        color: GameTheme.carnivalDerby.onDark.withOpacity(0.7),
        fontSize: 13,
        letterSpacing: 0.5,
      ),
      tilePlayersTextStyle: GoogleFonts.bangers(
        color: GameTheme.carnivalDerby.onDark,
        fontSize: 16,
        letterSpacing: 0.5,
      ),
      tileProgressTextStyle: GoogleFonts.luckiestGuy(
        color: GameTheme.carnivalDerby.accent,
        fontSize: 14,
      ),
      tileModeTextStyle: GoogleFonts.bangers(
        color: GameTheme.carnivalDerby.onDark.withOpacity(0.7),
        fontSize: 13,
        letterSpacing: 0.5,
      ),
      tileLeaderTextStyle: GoogleFonts.bangers(
        color: GameTheme.carnivalDerby.onDark,
        fontSize: 14,
        letterSpacing: 0.5,
      ),
      deleteButtonColor: const Color(0xFFE63946),
      resumeButtonColor: GameTheme.carnivalDerby.accent,
      resumeButtonTextColor: GameTheme.carnivalDerby.background,
      resumeButtonTextStyle: GoogleFonts.luckiestGuy(fontSize: 20),
      resumeButtonPadding: const EdgeInsets.only(top: 17, bottom: 11),
      resumeButtonDisabledColor: Colors.grey,
      startNewButtonColor: GameTheme.carnivalDerby.onDark.withOpacity(0.2),
      startNewButtonTextColor: GameTheme.carnivalDerby.onDark,
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
      backgroundColor: GameTheme.targetTag.background,
      borderColor: GameTheme.targetTag.accent,
      boxShadowColor: Colors.black,
      boxShadowOpacity: 0.5,
      titleTextStyle: GoogleFonts.luckiestGuy(
        color: GameTheme.targetTag.accent,
        fontSize: 24,
      ),
      tileBackgroundColor: GameTheme.targetTag.background.withOpacity(0.6),
      tileSelectedBackgroundColor: GameTheme.targetTag.accent.withOpacity(0.15),
      tileBorderColor: Colors.white.withOpacity(0.3),
      tileSelectedBorderColor: GameTheme.targetTag.accent,
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
        color: GameTheme.targetTag.accent,
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
      deleteButtonColor: GameTheme.targetTag.accent,
      resumeButtonColor: GameTheme.targetTag.accent,
      resumeButtonTextColor: Colors.white,
      resumeButtonTextStyle: GoogleFonts.luckiestGuy(fontSize: 20),
      resumeButtonPadding: const EdgeInsets.only(top: 17, bottom: 11),
      resumeButtonDisabledColor: Colors.grey,
      startNewButtonColor: Colors.white.withOpacity(0.2),
      startNewButtonTextColor: Colors.white,
      startNewButtonTextStyle: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.w600),
      deleteAllButtonColor: GameTheme.targetTag.accent,
      deleteAllButtonTextStyle: GoogleFonts.fredoka(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: GameTheme.targetTag.accent,
      ),
    );
  }

  factory ResumeGameModalConfig.monsterMash() {
    return ResumeGameModalConfig(
      backgroundColor: GameTheme.monsterMash.background,
      borderColor: GameTheme.monsterMash.accent,
      boxShadowColor: GameTheme.monsterMash.accent,
      boxShadowOpacity: 0.3,
      titleTextStyle: GoogleFonts.creepster(
        color: GameTheme.monsterMash.accent,
        fontSize: 24,
      ),
      tileBackgroundColor: GameTheme.monsterMash.background.withOpacity(0.6),
      tileSelectedBackgroundColor: GameTheme.monsterMash.accent.withOpacity(0.15),
      tileBorderColor: GameTheme.monsterMash.onDark.withOpacity(0.3),
      tileSelectedBorderColor: GameTheme.monsterMash.accent,
      tileDateTextStyle: GoogleFonts.pirataOne(
        color: GameTheme.monsterMash.onDark.withOpacity(0.7),
        fontSize: 13,
      ),
      tilePlayersTextStyle: GoogleFonts.pirataOne(
        color: GameTheme.monsterMash.onDark,
        fontSize: 16,
      ),
      tileProgressTextStyle: GoogleFonts.creepster(
        color: GameTheme.monsterMash.accent,
        fontSize: 14,
      ),
      tileModeTextStyle: GoogleFonts.pirataOne(
        color: GameTheme.monsterMash.onDark.withOpacity(0.7),
        fontSize: 13,
      ),
      tileLeaderTextStyle: GoogleFonts.pirataOne(
        color: GameTheme.monsterMash.onDark,
        fontSize: 14,
      ),
      deleteButtonColor: const Color(0xFFFF4444),
      resumeButtonColor: GameTheme.monsterMash.accent,
      resumeButtonTextColor: GameTheme.monsterMash.background,
      resumeButtonTextStyle: GoogleFonts.creepster(fontSize: 20),
      resumeButtonPadding: const EdgeInsets.only(top: 14, bottom: 14),
      resumeButtonDisabledColor: Colors.grey,
      startNewButtonColor: GameTheme.monsterMash.onDark.withOpacity(0.2),
      startNewButtonTextColor: GameTheme.monsterMash.onDark,
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
      backgroundColor: GameTheme.reefRoyale.background,
      borderColor: GameTheme.reefRoyale.accent,
      boxShadowColor: GameTheme.reefRoyale.accent,
      boxShadowOpacity: 0.3,
      titleTextStyle: GoogleFonts.fredoka(
        color: GameTheme.reefRoyale.accent,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      tileBackgroundColor: GameTheme.reefRoyale.background.withOpacity(0.6),
      tileSelectedBackgroundColor: GameTheme.reefRoyale.accent.withOpacity(0.15),
      tileBorderColor: GameTheme.reefRoyale.onDark.withOpacity(0.3),
      tileSelectedBorderColor: GameTheme.reefRoyale.accent,
      tileDateTextStyle: GoogleFonts.fredoka(
        color: GameTheme.reefRoyale.onDark.withOpacity(0.7),
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      tilePlayersTextStyle: GoogleFonts.fredoka(
        color: GameTheme.reefRoyale.onDark,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      tileProgressTextStyle: GoogleFonts.fredoka(
        color: GameTheme.reefRoyale.accent,
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
      tileModeTextStyle: GoogleFonts.fredoka(
        color: GameTheme.reefRoyale.onDark.withOpacity(0.7),
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      tileLeaderTextStyle: GoogleFonts.fredoka(
        color: GameTheme.reefRoyale.onDark,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      deleteButtonColor: const Color(0xFFFF6B6B),
      resumeButtonColor: GameTheme.reefRoyale.accent,
      resumeButtonTextColor: GameTheme.reefRoyale.background,
      resumeButtonTextStyle: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.bold),
      resumeButtonDisabledColor: Colors.grey,
      startNewButtonColor: GameTheme.reefRoyale.onDark.withOpacity(0.2),
      startNewButtonTextColor: GameTheme.reefRoyale.onDark,
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

  factory ResumeGameModalConfig.lunarLander() {
    return ResumeGameModalConfig(
      backgroundColor: GameTheme.lunarLander.background, // Earth Blue
      borderColor: GameTheme.lunarLander.accent, // Rocket Flame
      boxShadowColor: GameTheme.lunarLander.accent,
      boxShadowOpacity: 0.3,
      titleTextStyle: GoogleFonts.orbitron(
        color: GameTheme.lunarLander.accent, // Rocket Flame
        fontSize: 22,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
      tileBackgroundColor: GameTheme.lunarLander.background.withOpacity(0.6),
      tileSelectedBackgroundColor: GameTheme.lunarLander.accent.withOpacity(0.15),
      tileBorderColor: GameTheme.lunarLander.onDark.withOpacity(0.3),
      tileSelectedBorderColor: GameTheme.lunarLander.accent,
      tileDateTextStyle: GoogleFonts.exo2(
        color: GameTheme.lunarLander.onDark.withOpacity(0.7),
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      tilePlayersTextStyle: GoogleFonts.exo2(
        color: GameTheme.lunarLander.onDark,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      tileProgressTextStyle: GoogleFonts.orbitron(
        color: GameTheme.lunarLander.accent,
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
      tileModeTextStyle: GoogleFonts.exo2(
        color: GameTheme.lunarLander.onDark.withOpacity(0.7),
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      tileLeaderTextStyle: GoogleFonts.exo2(
        color: GameTheme.lunarLander.onDark,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      deleteButtonColor: const Color(0xFFE63946), // Thruster Red
      resumeButtonColor: const Color(0xFF52B788), // Mission Green
      resumeButtonTextColor: GameTheme.lunarLander.onDark,
      resumeButtonTextStyle: GoogleFonts.orbitron(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.0),
      resumeButtonDisabledColor: Colors.grey,
      startNewButtonColor: GameTheme.lunarLander.onDark.withOpacity(0.2),
      startNewButtonTextColor: GameTheme.lunarLander.onDark,
      startNewButtonTextStyle: GoogleFonts.exo2(fontSize: 16, fontWeight: FontWeight.w600),
      deleteAllButtonColor: const Color(0xFFE63946),
      deleteAllButtonTextStyle: GoogleFonts.exo2(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: const Color(0xFFE63946),
      ),
    );
  }

  /// Pirate's Grid — Ocean Navy bg, Compass Bronze border, PirataOne/Lora fonts
  factory ResumeGameModalConfig.piratesGrid() {
    return ResumeGameModalConfig(
      backgroundColor: GameTheme.piratesGrid.background, // Ocean Navy
      borderColor: GameTheme.piratesGrid.accent, // Compass Bronze
      boxShadowColor: GameTheme.piratesGrid.accent,
      boxShadowOpacity: 0.3,
      titleTextStyle: GoogleFonts.pirataOne(
        color: const Color(0xFFDAA520), // Treasure Gold
        fontSize: 22,
        letterSpacing: 1.2,
      ),
      tileBackgroundColor: GameTheme.piratesGrid.background.withOpacity(0.6),
      tileSelectedBackgroundColor: GameTheme.piratesGrid.accent.withOpacity(0.15),
      tileBorderColor: GameTheme.piratesGrid.onDark.withOpacity(0.3),
      tileSelectedBorderColor: GameTheme.piratesGrid.accent,
      tileDateTextStyle: GoogleFonts.lora(
        color: GameTheme.piratesGrid.onDark.withOpacity(0.7),
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      tilePlayersTextStyle: GoogleFonts.lora(
        color: GameTheme.piratesGrid.onDark,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      tileProgressTextStyle: GoogleFonts.pirataOne(
        color: const Color(0xFFDAA520),
        fontSize: 14,
      ),
      tileModeTextStyle: GoogleFonts.lora(
        color: GameTheme.piratesGrid.onDark.withOpacity(0.7),
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      tileLeaderTextStyle: GoogleFonts.lora(
        color: GameTheme.piratesGrid.onDark,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      deleteButtonColor: const Color(0xFF8B0000), // Blood Red
      resumeButtonColor: GameTheme.piratesGrid.accent, // Compass Bronze
      resumeButtonTextColor: GameTheme.piratesGrid.onDark,
      resumeButtonTextStyle: GoogleFonts.pirataOne(fontSize: 18, letterSpacing: 1.0),
      resumeButtonDisabledColor: Colors.grey,
      startNewButtonColor: GameTheme.piratesGrid.onDark.withOpacity(0.2),
      startNewButtonTextColor: GameTheme.piratesGrid.onDark,
      startNewButtonTextStyle: GoogleFonts.lora(fontSize: 16, fontWeight: FontWeight.w600),
      deleteAllButtonColor: const Color(0xFF8B0000), // Blood Red
      deleteAllButtonTextStyle: GoogleFonts.lora(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF8B0000),
      ),
    );
  }

  factory ResumeGameModalConfig.clockworkQuest() {
    return ResumeGameModalConfig(
      backgroundColor: GameTheme.clockworkQuest.background, // Dark Iron
      borderColor: GameTheme.clockworkQuest.accent, // Brass Gold
      boxShadowColor: const Color(0xFFFFBF00), // Amber Glow
      boxShadowOpacity: 0.4,
      titleTextStyle: GoogleFonts.cinzelDecorative(
        color: GameTheme.clockworkQuest.accent,
        fontSize: 24,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
      tileBackgroundColor: GameTheme.clockworkQuest.background.withOpacity(0.6),
      tileSelectedBackgroundColor: GameTheme.clockworkQuest.accent.withOpacity(0.15),
      tileBorderColor: const Color(0xFFB87333).withOpacity(0.3), // Copper Rose
      tileSelectedBorderColor: GameTheme.clockworkQuest.accent,
      tileDateTextStyle: GoogleFonts.lato(
        color: GameTheme.clockworkQuest.onDark.withOpacity(0.6),
        fontSize: 11,
        fontWeight: FontWeight.w400,
      ),
      tilePlayersTextStyle: GoogleFonts.lato(
        color: GameTheme.clockworkQuest.onDark.withOpacity(0.7),
        fontSize: 13,
      ),
      tileProgressTextStyle: GoogleFonts.lato(
        color: GameTheme.clockworkQuest.onDark,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
      tileModeTextStyle: GoogleFonts.lato(
        color: GameTheme.clockworkQuest.onDark, // Steam White
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      tileLeaderTextStyle: GoogleFonts.lato(
        color: GameTheme.clockworkQuest.accent,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      deleteButtonColor: const Color(0xFFFF6B6B),
      resumeButtonColor: GameTheme.clockworkQuest.accent, // Brass Gold
      resumeButtonTextColor: GameTheme.clockworkQuest.background,
      resumeButtonTextStyle: GoogleFonts.cinzelDecorative(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.0,
      ),
      resumeButtonDisabledColor: Colors.grey,
      startNewButtonColor: GameTheme.clockworkQuest.onDark.withOpacity(0.2),
      startNewButtonTextColor: GameTheme.clockworkQuest.onDark,
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

  /// Gladiator Arena — Dark Arena bg, Gladiator Gold border, Cinzel/Lato fonts
  factory ResumeGameModalConfig.gladiatorArena() {
    return ResumeGameModalConfig(
      backgroundColor: GameTheme.gladiatorArena.background, // Dark Arena
      borderColor: const Color(0xFFDAA520), // Gladiator Gold
      boxShadowColor: const Color(0xFFDAA520),
      boxShadowOpacity: 0.3,
      titleTextStyle: GoogleFonts.cinzel(
        color: const Color(0xFFDAA520), // Gladiator Gold
        fontSize: 22,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
      tileBackgroundColor: GameTheme.gladiatorArena.background.withOpacity(0.6),
      tileSelectedBackgroundColor: const Color(0xFFDAA520).withOpacity(0.15),
      tileBorderColor: GameTheme.gladiatorArena.onDark.withOpacity(0.3),
      tileSelectedBorderColor: const Color(0xFFDAA520), // Gladiator Gold
      tileDateTextStyle: GoogleFonts.lato(
        color: GameTheme.gladiatorArena.onDark.withOpacity(0.7),
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      tilePlayersTextStyle: GoogleFonts.lato(
        color: GameTheme.gladiatorArena.onDark,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      tileProgressTextStyle: GoogleFonts.cinzel(
        color: const Color(0xFFDAA520), // Gladiator Gold
        fontSize: 11,
        fontWeight: FontWeight.bold,
      ),
      tileModeTextStyle: GoogleFonts.lato(
        color: GameTheme.gladiatorArena.onDark.withOpacity(0.7),
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
      tileLeaderTextStyle: GoogleFonts.lato(
        color: GameTheme.gladiatorArena.onDark,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      deleteButtonColor: const Color(0xFFC0392B), // Blood Red
      resumeButtonColor: GameTheme.gladiatorArena.accent, // Bronze
      resumeButtonTextColor: GameTheme.gladiatorArena.onDark, // Marble White
      resumeButtonTextStyle: GoogleFonts.cinzel(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.0,
      ),
      resumeButtonPadding: const EdgeInsets.only(top: 14, bottom: 14),
      resumeButtonDisabledColor: const Color(0xFF8B8682), // Colosseum Gray
      startNewButtonColor: GameTheme.gladiatorArena.onDark.withOpacity(0.2),
      startNewButtonTextColor: GameTheme.gladiatorArena.onDark,
      startNewButtonTextStyle: GoogleFonts.lato(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      deleteAllButtonColor: const Color(0xFFC0392B), // Blood Red
      deleteAllButtonTextStyle: GoogleFonts.lato(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: const Color(0xFFC0392B),
      ),
    );
  }

  /// Tiki Golf — Palm Green bg, Lagoon Blue border, Boogaloo/Nunito fonts
  factory ResumeGameModalConfig.tikiGolf() {
    return ResumeGameModalConfig(
      backgroundColor: GameTheme.tikiGolf.background, // Palm Green
      borderColor: GameTheme.tikiGolf.accent, // Lagoon Blue
      boxShadowColor: Colors.black,
      boxShadowOpacity: 0.5,
      titleTextStyle: GoogleFonts.boogaloo(
        color: GameTheme.tikiGolf.onDark, // Sand White
        fontSize: 26,
        shadows: const [
          Shadow(color: Color(0xFF8B5E3C), offset: Offset(1, 1), blurRadius: 0),
          Shadow(color: Color(0xFF8B5E3C), offset: Offset(-1, -1), blurRadius: 0),
          Shadow(color: Color(0xFF8B5E3C), offset: Offset(1, -1), blurRadius: 0),
          Shadow(color: Color(0xFF8B5E3C), offset: Offset(-1, 1), blurRadius: 0),
        ],
      ),
      tileBackgroundColor: GameTheme.tikiGolf.background.withOpacity(0.6),
      tileSelectedBackgroundColor: GameTheme.tikiGolf.accent.withOpacity(0.15),
      tileBorderColor: GameTheme.tikiGolf.onDark.withOpacity(0.3),
      tileSelectedBorderColor: GameTheme.tikiGolf.accent, // Lagoon Blue
      tileDateTextStyle: GoogleFonts.nunito(
        color: GameTheme.tikiGolf.onDark.withOpacity(0.7),
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      tilePlayersTextStyle: GoogleFonts.nunito(
        color: GameTheme.tikiGolf.onDark,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      tileProgressTextStyle: GoogleFonts.boogaloo(
        color: const Color(0xFFFF8C42), // Tropical Orange
        fontSize: 14,
      ),
      tileModeTextStyle: GoogleFonts.nunito(
        color: GameTheme.tikiGolf.onDark.withOpacity(0.7),
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      tileLeaderTextStyle: GoogleFonts.nunito(
        color: GameTheme.tikiGolf.onDark,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      deleteButtonColor: const Color(0xFFFF69B4), // Hibiscus Pink
      resumeButtonColor: GameTheme.tikiGolf.accent, // Lagoon Blue
      resumeButtonTextColor: GameTheme.tikiGolf.onDark,
      resumeButtonTextStyle: GoogleFonts.boogaloo(fontSize: 22),
      resumeButtonDisabledColor: Colors.grey,
      startNewButtonColor: GameTheme.tikiGolf.onDark.withOpacity(0.2),
      startNewButtonTextColor: GameTheme.tikiGolf.onDark,
      startNewButtonTextStyle: GoogleFonts.nunito(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      deleteAllButtonColor: const Color(0xFFFF69B4), // Hibiscus Pink
      deleteAllButtonTextStyle: GoogleFonts.nunito(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: const Color(0xFFFF69B4),
      ),
    );
  }

  /// Treasure Divide — Ocean Teal bg, Treasure Gold border, PirataOne title + Merriweather body
  factory ResumeGameModalConfig.treasureDivide() {
    return ResumeGameModalConfig(
      backgroundColor: GameTheme.treasureDivide.background, // Ocean Teal
      borderColor: GameTheme.treasureDivide.accent, // Treasure Gold
      boxShadowColor: GameTheme.treasureDivide.accent,
      boxShadowOpacity: 0.3,
      titleTextStyle: GoogleFonts.pirataOne(
        color: GameTheme.treasureDivide.accent, // Treasure Gold
        fontSize: 22,
        letterSpacing: 1.2,
      ),
      tileBackgroundColor: GameTheme.treasureDivide.background.withOpacity(0.6),
      tileSelectedBackgroundColor: GameTheme.treasureDivide.accent.withOpacity(0.15),
      tileBorderColor: GameTheme.treasureDivide.onDark.withOpacity(0.3),
      tileSelectedBorderColor: GameTheme.treasureDivide.accent, // Treasure Gold
      tileDateTextStyle: GoogleFonts.merriweather(
        color: GameTheme.treasureDivide.onDark.withOpacity(0.7),
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      tilePlayersTextStyle: GoogleFonts.merriweather(
        color: GameTheme.treasureDivide.onDark,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      tileProgressTextStyle: GoogleFonts.pirataOne(
        color: GameTheme.treasureDivide.accent, // Treasure Gold
        fontSize: 14,
        letterSpacing: 0.5,
      ),
      tileModeTextStyle: GoogleFonts.merriweather(
        color: GameTheme.treasureDivide.onDark.withOpacity(0.7),
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      tileLeaderTextStyle: GoogleFonts.merriweather(
        color: GameTheme.treasureDivide.onDark,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      deleteButtonColor: const Color(0xFFC41E3A), // Blood Red
      resumeButtonColor: GameTheme.treasureDivide.accent, // Treasure Gold
      resumeButtonTextColor: GameTheme.treasureDivide.background, // Ocean Teal
      resumeButtonTextStyle: GoogleFonts.pirataOne(fontSize: 18, letterSpacing: 1.0),
      resumeButtonDisabledColor: Colors.grey,
      startNewButtonColor: GameTheme.treasureDivide.onDark.withOpacity(0.2),
      startNewButtonTextColor: GameTheme.treasureDivide.onDark,
      startNewButtonTextStyle: GoogleFonts.merriweather(fontSize: 16, fontWeight: FontWeight.w600),
      deleteAllButtonColor: const Color(0xFFC41E3A), // Blood Red
      deleteAllButtonTextStyle: GoogleFonts.merriweather(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: const Color(0xFFC41E3A),
      ),
    );
  }
}
