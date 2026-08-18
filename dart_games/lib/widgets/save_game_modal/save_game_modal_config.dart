import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/game_theme.dart';

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
      backgroundColor: GameTheme.carnivalDerby.background,
      borderColor: GameTheme.carnivalDerby.accent,
      boxShadowColor: GameTheme.carnivalDerby.shadow,
      boxShadowOpacity: GameTheme.carnivalDerby.shadowOpacity,
      iconColor: GameTheme.carnivalDerby.accent,
      iconSize: 56,
      titleTextStyle: GoogleFonts.luckiestGuy(
        color: GameTheme.carnivalDerby.accent,
        fontSize: 28,
      ),
      messageTextStyle: GoogleFonts.bangers(
        color: GameTheme.carnivalDerby.onDark,
        fontSize: 20,
        letterSpacing: 1.0,
      ),
      saveButtonColor: GameTheme.carnivalDerby.accent,
      saveButtonTextColor: GameTheme.carnivalDerby.background,
      saveButtonTextStyle: GoogleFonts.luckiestGuy(fontSize: 20),
      saveButtonPadding: const EdgeInsets.only(top: 17, bottom: 11),
      dontSaveButtonColor: Colors.transparent,
      dontSaveButtonTextColor: GameTheme.carnivalDerby.onDark,
      dontSaveButtonTextStyle: GoogleFonts.bangers(fontSize: 18, letterSpacing: 1.0),
    );
  }

  factory SaveGameModalConfig.targetTag() {
    return SaveGameModalConfig(
      backgroundColor: GameTheme.targetTag.background,
      borderColor: GameTheme.targetTag.accent,
      boxShadowColor: GameTheme.targetTag.shadow,
      boxShadowOpacity: GameTheme.targetTag.shadowOpacity,
      iconColor: GameTheme.targetTag.accent,
      iconSize: 48,
      titleTextStyle: GoogleFonts.luckiestGuy(
        color: GameTheme.targetTag.accent,
        fontSize: 24,
      ),
      messageTextStyle: GoogleFonts.fredoka(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      saveButtonColor: GameTheme.targetTag.accent,
      saveButtonTextColor: Colors.white,
      saveButtonTextStyle: GoogleFonts.luckiestGuy(fontSize: 20),
      saveButtonPadding: const EdgeInsets.only(top: 17, bottom: 11),
      dontSaveButtonColor: Colors.transparent,
      dontSaveButtonTextColor: GameTheme.targetTag.onDark,
      dontSaveButtonTextStyle: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.w600),
    );
  }

  factory SaveGameModalConfig.monsterMash() {
    return SaveGameModalConfig(
      backgroundColor: GameTheme.monsterMash.background,
      borderColor: GameTheme.monsterMash.accent,
      boxShadowColor: GameTheme.monsterMash.shadow,
      boxShadowOpacity: GameTheme.monsterMash.shadowOpacity,
      iconColor: GameTheme.monsterMash.accent,
      iconSize: 48,
      titleTextStyle: GoogleFonts.creepster(
        color: GameTheme.monsterMash.accent,
        fontSize: 28,
      ),
      messageTextStyle: GoogleFonts.pirataOne(
        color: GameTheme.monsterMash.onDark,
        fontSize: 18,
      ),
      saveButtonColor: GameTheme.monsterMash.accent,
      saveButtonTextColor: GameTheme.monsterMash.background,
      saveButtonTextStyle: GoogleFonts.creepster(fontSize: 20),
      saveButtonPadding: const EdgeInsets.only(top: 14, bottom: 14),
      dontSaveButtonColor: Colors.transparent,
      dontSaveButtonTextColor: GameTheme.monsterMash.onDark,
      dontSaveButtonTextStyle: GoogleFonts.pirataOne(fontSize: 18),
    );
  }

  factory SaveGameModalConfig.reefRoyale() {
    return SaveGameModalConfig(
      backgroundColor: GameTheme.reefRoyale.background,
      borderColor: GameTheme.reefRoyale.accent,
      boxShadowColor: GameTheme.reefRoyale.shadow,
      boxShadowOpacity: GameTheme.reefRoyale.shadowOpacity,
      iconColor: GameTheme.reefRoyale.accent,
      iconSize: 48,
      titleTextStyle: GoogleFonts.fredoka(
        color: GameTheme.reefRoyale.accent,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      messageTextStyle: GoogleFonts.fredoka(
        color: GameTheme.reefRoyale.onDark,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      saveButtonColor: GameTheme.reefRoyale.accent,
      saveButtonTextColor: GameTheme.reefRoyale.background,
      saveButtonTextStyle: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.bold),
      dontSaveButtonColor: Colors.transparent,
      dontSaveButtonTextColor: GameTheme.reefRoyale.onDark,
      dontSaveButtonTextStyle: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.w600),
      dontSaveButtonPadding: const EdgeInsets.only(top: 12, bottom: 16),
    );
  }

  factory SaveGameModalConfig.lunarLander() {
    return SaveGameModalConfig(
      backgroundColor: GameTheme.lunarLander.background, // Earth Blue
      borderColor: GameTheme.lunarLander.accent, // Rocket Flame
      boxShadowColor: GameTheme.lunarLander.shadow,
      boxShadowOpacity: GameTheme.lunarLander.shadowOpacity,
      iconColor: GameTheme.lunarLander.accent, // Rocket Flame
      iconSize: 48,
      titleTextStyle: GoogleFonts.orbitron(
        color: GameTheme.lunarLander.accent, // Rocket Flame
        fontSize: 22,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
      messageTextStyle: GoogleFonts.exo2(
        color: GameTheme.lunarLander.onDark, // Star White
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      saveButtonColor: GameTheme.lunarLander.accent, // Rocket Flame
      saveButtonTextColor: GameTheme.lunarLander.onDark,
      saveButtonTextStyle: GoogleFonts.orbitron(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.0),
      dontSaveButtonColor: Colors.transparent,
      dontSaveButtonTextColor: GameTheme.lunarLander.onDark,
      dontSaveButtonTextStyle: GoogleFonts.exo2(fontSize: 16, fontWeight: FontWeight.w600),
    );
  }

  /// Pirate's Grid — Ocean Navy bg, Compass Bronze border, pirate-themed copy
  factory SaveGameModalConfig.piratesGrid() {
    return SaveGameModalConfig(
      backgroundColor: GameTheme.piratesGrid.background, // Ocean Navy
      borderColor: GameTheme.piratesGrid.accent, // Compass Bronze
      boxShadowColor: GameTheme.piratesGrid.shadow,
      boxShadowOpacity: GameTheme.piratesGrid.shadowOpacity,
      iconColor: GameTheme.piratesGrid.accent, // Compass Bronze
      iconSize: 48,
      titleTextStyle: GoogleFonts.pirataOne(
        color: const Color(0xFFDAA520), // Treasure Gold
        fontSize: 24,
        letterSpacing: 1.2,
      ),
      messageTextStyle: GoogleFonts.lora(
        color: GameTheme.piratesGrid.onDark, // Parchment Tan
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      saveButtonColor: GameTheme.piratesGrid.accent, // Compass Bronze
      saveButtonTextColor: GameTheme.piratesGrid.onDark,
      saveButtonTextStyle: GoogleFonts.pirataOne(fontSize: 18, letterSpacing: 1.0),
      dontSaveButtonColor: Colors.transparent,
      dontSaveButtonTextColor: GameTheme.piratesGrid.onDark,
      dontSaveButtonTextStyle: GoogleFonts.lora(fontSize: 16, fontWeight: FontWeight.w600),
    );
  }

  /// Gladiator Arena — Dark Arena bg, Bronze/Gold border, Cinzel/Lato fonts
  /// "LEAVE THE ARENA?" title, SAVE & EXIT (Bronze), DON'T SAVE (Blood Red), CANCEL (Colosseum Gray)
  factory SaveGameModalConfig.gladiatorArena() {
    return SaveGameModalConfig(
      backgroundColor: GameTheme.gladiatorArena.background, // Dark Arena
      borderColor: GameTheme.gladiatorArena.accent, // Bronze
      boxShadowColor: GameTheme.gladiatorArena.shadow, // Gladiator Gold
      boxShadowOpacity: GameTheme.gladiatorArena.shadowOpacity,
      iconColor: GameTheme.gladiatorArena.accent, // Bronze
      iconSize: 48,
      titleTextStyle: GoogleFonts.cinzel(
        color: const Color(0xFFDAA520), // Gladiator Gold
        fontSize: 22,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
      messageTextStyle: GoogleFonts.lato(
        color: GameTheme.gladiatorArena.onDark, // Marble White
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      saveButtonColor: GameTheme.gladiatorArena.accent, // Bronze — SAVE & EXIT
      saveButtonTextColor: GameTheme.gladiatorArena.onDark, // Marble White
      saveButtonTextStyle: GoogleFonts.cinzel(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.0,
      ),
      dontSaveButtonColor: const Color(0xFFC0392B), // Blood Red — DON'T SAVE
      dontSaveButtonTextColor: GameTheme.gladiatorArena.onDark, // Marble White
      dontSaveButtonTextStyle: GoogleFonts.lato(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  factory SaveGameModalConfig.clockworkQuest() {
    return SaveGameModalConfig(
      backgroundColor: GameTheme.clockworkQuest.background, // Dark Iron
      borderColor: GameTheme.clockworkQuest.accent, // Brass Gold
      boxShadowColor: GameTheme.clockworkQuest.shadow, // Amber Glow
      boxShadowOpacity: GameTheme.clockworkQuest.shadowOpacity,
      iconColor: GameTheme.clockworkQuest.accent,
      iconSize: 48,
      titleTextStyle: GoogleFonts.cinzelDecorative(
        color: GameTheme.clockworkQuest.accent,
        fontSize: 24,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
      messageTextStyle: GoogleFonts.lato(
        color: GameTheme.clockworkQuest.onDark, // Steam White
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      saveButtonColor: GameTheme.clockworkQuest.accent, // Brass Gold
      saveButtonTextColor: GameTheme.clockworkQuest.background, // Dark Iron
      saveButtonTextStyle: GoogleFonts.cinzelDecorative(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.0,
      ),
      dontSaveButtonColor: Colors.transparent,
      dontSaveButtonTextColor: GameTheme.clockworkQuest.onDark,
      dontSaveButtonTextStyle: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.w600),
      dontSaveButtonPadding: const EdgeInsets.only(top: 12, bottom: 16),
    );
  }

  /// Tiki Golf — Palm Green bg, Lagoon Blue border, Boogaloo/Nunito fonts
  factory SaveGameModalConfig.tikiGolf() {
    return SaveGameModalConfig(
      backgroundColor: GameTheme.tikiGolf.background, // Palm Green
      borderColor: GameTheme.tikiGolf.accent, // Lagoon Blue
      boxShadowColor: GameTheme.tikiGolf.shadow,
      boxShadowOpacity: GameTheme.tikiGolf.shadowOpacity,
      iconColor: const Color(0xFFFF8C42), // Tropical Orange
      iconSize: 48,
      titleTextStyle: GoogleFonts.boogaloo(
        color: GameTheme.tikiGolf.onDark, // Sand White
        fontSize: 28,
        shadows: const [
          Shadow(color: Color(0xFF8B5E3C), offset: Offset(1, 1), blurRadius: 0),
          Shadow(color: Color(0xFF8B5E3C), offset: Offset(-1, -1), blurRadius: 0),
          Shadow(color: Color(0xFF8B5E3C), offset: Offset(1, -1), blurRadius: 0),
          Shadow(color: Color(0xFF8B5E3C), offset: Offset(-1, 1), blurRadius: 0),
        ],
      ),
      messageTextStyle: GoogleFonts.nunito(
        color: GameTheme.tikiGolf.onDark, // Sand White
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      saveButtonColor: GameTheme.tikiGolf.accent, // Lagoon Blue
      saveButtonTextColor: GameTheme.tikiGolf.onDark, // Sand White
      saveButtonTextStyle: GoogleFonts.boogaloo(fontSize: 22),
      dontSaveButtonColor: Colors.transparent,
      dontSaveButtonTextColor: GameTheme.tikiGolf.onDark,
      dontSaveButtonTextStyle: GoogleFonts.nunito(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  /// Treasure Divide — Ocean Teal bg, Treasure Gold border, PirataOne/Merriweather fonts
  /// SAVE = Island Green, DON'T SAVE = Blood Red
  factory SaveGameModalConfig.treasureDivide() {
    return SaveGameModalConfig(
      backgroundColor: GameTheme.treasureDivide.background, // Ocean Teal
      borderColor: GameTheme.treasureDivide.accent, // Treasure Gold
      boxShadowColor: GameTheme.treasureDivide.shadow,
      boxShadowOpacity: GameTheme.treasureDivide.shadowOpacity,
      iconColor: GameTheme.treasureDivide.accent, // Treasure Gold
      iconSize: 48,
      titleTextStyle: GoogleFonts.pirataOne(
        color: GameTheme.treasureDivide.accent, // Treasure Gold
        fontSize: 24,
        letterSpacing: 1.2,
      ),
      messageTextStyle: GoogleFonts.merriweather(
        color: GameTheme.treasureDivide.onDark, // Sail White
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      saveButtonColor: const Color(0xFF228B22), // Island Green — SAVE
      saveButtonTextColor: GameTheme.treasureDivide.onDark, // Sail White
      saveButtonTextStyle: GoogleFonts.pirataOne(fontSize: 18, letterSpacing: 1.0),
      dontSaveButtonColor: const Color(0xFFC41E3A), // Blood Red — DON'T SAVE
      dontSaveButtonTextColor: GameTheme.treasureDivide.onDark, // Sail White
      dontSaveButtonTextStyle: GoogleFonts.merriweather(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
