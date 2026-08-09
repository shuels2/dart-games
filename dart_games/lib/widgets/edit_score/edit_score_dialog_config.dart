import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/game_theme.dart';

/// Configuration class for styling the shared Edit Score dialog.
///
/// Use factory methods to get pre-configured styling for each game:
/// - [EditScoreDialogConfig.carnivalDerby] — Midnight Navy bg, Canary Yellow accents
/// - [EditScoreDialogConfig.targetTag] — Dark Navy bg, Hot Pink border, Neon Green selected
class EditScoreDialogConfig {
  final Color backgroundColor;
  final Color borderColor;
  final double borderWidth;

  final TextStyle titleStyle;
  final TextStyle dartLabelStyle;

  final Color scoreBoxBackgroundColor;
  final Color scoreBoxDefaultBorderColor;
  final TextStyle scoreTextStyle;

  final Color buttonUnselectedColor;
  final Color buttonUnselectedForeground;
  final Color buttonSelectedColor;
  final Color buttonSelectedForeground;
  final TextStyle buttonTextStyle;

  final Color cancelButtonColor;
  final Color cancelButtonForeground;
  final TextStyle cancelButtonTextStyle;

  final Color submitButtonColor;
  final Color submitButtonForeground;
  final TextStyle submitButtonTextStyle;

  /// Optional transform applied to a segment string when displaying it in the
  /// score box. If null, the raw segment string is shown (e.g. "S20", "D15").
  /// Carnival Derby uses this to show the calculated point value instead.
  final String Function(String segment)? scoreDisplayTransform;

  EditScoreDialogConfig({
    required this.backgroundColor,
    required this.borderColor,
    this.borderWidth = 4,
    required this.titleStyle,
    required this.dartLabelStyle,
    required this.scoreBoxBackgroundColor,
    required this.scoreBoxDefaultBorderColor,
    required this.scoreTextStyle,
    required this.buttonUnselectedColor,
    required this.buttonUnselectedForeground,
    required this.buttonSelectedColor,
    required this.buttonSelectedForeground,
    required this.buttonTextStyle,
    required this.cancelButtonColor,
    required this.cancelButtonForeground,
    required this.cancelButtonTextStyle,
    required this.submitButtonColor,
    required this.submitButtonForeground,
    required this.submitButtonTextStyle,
    this.scoreDisplayTransform,
  });

  factory EditScoreDialogConfig.carnivalDerby() {
    return EditScoreDialogConfig(
      backgroundColor: GameTheme.carnivalDerby.background.withOpacity(0.95),
      borderColor: GameTheme.carnivalDerby.accent,
      borderWidth: 4,
      titleStyle: GoogleFonts.luckiestGuy(
        fontSize: 24,
        color: GameTheme.carnivalDerby.accent,
      ),
      dartLabelStyle: GoogleFonts.bangers(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: GameTheme.carnivalDerby.onDark,
        letterSpacing: 1.0,
      ),
      scoreBoxBackgroundColor: GameTheme.carnivalDerby.background,
      scoreBoxDefaultBorderColor: GameTheme.carnivalDerby.accent,
      scoreTextStyle: GoogleFonts.luckiestGuy(
        fontSize: 18,
        color: GameTheme.carnivalDerby.onDark,
      ),
      buttonUnselectedColor: const Color(0xFF8B5E3C),
      buttonUnselectedForeground: GameTheme.carnivalDerby.onDark,
      buttonSelectedColor: GameTheme.carnivalDerby.accent,
      buttonSelectedForeground: GameTheme.carnivalDerby.background,
      buttonTextStyle: GoogleFonts.bangers(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
      cancelButtonColor: Colors.grey.withOpacity(0.85),
      cancelButtonForeground: Colors.white,
      cancelButtonTextStyle: GoogleFonts.bangers(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.0,
      ),
      submitButtonColor: GameTheme.carnivalDerby.accent.withOpacity(0.85),
      submitButtonForeground: GameTheme.carnivalDerby.background,
      submitButtonTextStyle: GoogleFonts.bangers(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.0,
      ),
      scoreDisplayTransform: _carnivalDerbyScoreDisplay,
    );
  }

  static String _carnivalDerbyScoreDisplay(String segment) {
    if (segment.isEmpty || segment == '-') return '-';
    if (segment == 'Miss') return 'Miss';
    if (segment == 'Bull') return '50';
    if (segment == '25') return '25';
    final match = RegExp(r'([SDTsdt])(\d+)').firstMatch(segment);
    if (match == null) return segment;
    final prefix = match.group(1)!.toUpperCase();
    final number = int.parse(match.group(2)!);
    if (prefix == 'D') return '${number * 2}';
    if (prefix == 'T') return '${number * 3}';
    return '$number';
  }

  factory EditScoreDialogConfig.monsterMash() {
    return EditScoreDialogConfig(
      backgroundColor: GameTheme.monsterMash.background.withOpacity(0.95), // Iron Gate
      borderColor: const Color(0xFFFF8C00), // Pumpkin Orange
      borderWidth: 4,
      titleStyle: GoogleFonts.creepster(
        fontSize: 24,
        color: GameTheme.monsterMash.onDark, // Aged Parchment
      ),
      dartLabelStyle: GoogleFonts.montserrat(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: GameTheme.monsterMash.onDark.withOpacity(0.7),
      ),
      scoreBoxBackgroundColor: GameTheme.monsterMash.background,
      scoreBoxDefaultBorderColor: GameTheme.monsterMash.onDark.withOpacity(0.3),
      scoreTextStyle: GoogleFonts.pirataOne(
        fontSize: 18,
        color: GameTheme.monsterMash.onDark,
      ),
      buttonUnselectedColor: const Color(0xFF4B0082), // Haunted Purple
      buttonUnselectedForeground: GameTheme.monsterMash.onDark,
      buttonSelectedColor: GameTheme.monsterMash.accent, // Ecto-Green
      buttonSelectedForeground: Colors.black,
      buttonTextStyle: GoogleFonts.montserrat(
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
      cancelButtonColor: Colors.grey.withOpacity(0.85),
      cancelButtonForeground: Colors.white,
      cancelButtonTextStyle: GoogleFonts.pirataOne(
        fontSize: 16,
      ),
      submitButtonColor: const Color(0xFF4B0082).withOpacity(0.85),
      submitButtonForeground: GameTheme.monsterMash.onDark,
      submitButtonTextStyle: GoogleFonts.pirataOne(
        fontSize: 16,
      ),
    );
  }

  factory EditScoreDialogConfig.targetTag() {
    return EditScoreDialogConfig(
      backgroundColor: GameTheme.targetTag.background.withOpacity(0.95),
      borderColor: GameTheme.targetTag.accent,
      borderWidth: 4,
      titleStyle: GoogleFonts.fredoka(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      dartLabelStyle: GoogleFonts.fredoka(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.white70,
      ),
      scoreBoxBackgroundColor: GameTheme.targetTag.background,
      scoreBoxDefaultBorderColor: Colors.white38,
      scoreTextStyle: GoogleFonts.fredoka(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      buttonUnselectedColor: const Color(0xFF2A2A3E),
      buttonUnselectedForeground: Colors.white,
      buttonSelectedColor: const Color(0xFF00FFA3),
      buttonSelectedForeground: Colors.black,
      buttonTextStyle: GoogleFonts.fredoka(
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
      cancelButtonColor: Colors.grey.withOpacity(0.85),
      cancelButtonForeground: Colors.white,
      cancelButtonTextStyle: GoogleFonts.fredoka(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
      submitButtonColor: GameTheme.targetTag.accent.withOpacity(0.85),
      submitButtonForeground: Colors.white,
      submitButtonTextStyle: GoogleFonts.fredoka(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
      // No scoreDisplayTransform — raw segment string shown (S20, D15, etc.)
    );
  }

  factory EditScoreDialogConfig.reefRoyale() {
    return EditScoreDialogConfig(
      backgroundColor: GameTheme.reefRoyale.background.withOpacity(0.95),
      borderColor: GameTheme.reefRoyale.accent, // Seafoam Green
      borderWidth: 4,
      titleStyle: GoogleFonts.fredoka(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: GameTheme.reefRoyale.onDark, // Pearl White
      ),
      dartLabelStyle: GoogleFonts.fredoka(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: GameTheme.reefRoyale.onDark.withOpacity(0.7),
      ),
      scoreBoxBackgroundColor: GameTheme.reefRoyale.background,
      scoreBoxDefaultBorderColor: GameTheme.reefRoyale.onDark.withOpacity(0.3),
      scoreTextStyle: GoogleFonts.fredoka(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: GameTheme.reefRoyale.onDark,
      ),
      buttonUnselectedColor: GameTheme.reefRoyale.background,
      buttonUnselectedForeground: GameTheme.reefRoyale.onDark,
      buttonSelectedColor: GameTheme.reefRoyale.accent, // Seafoam Green
      buttonSelectedForeground: GameTheme.reefRoyale.background,
      buttonTextStyle: GoogleFonts.fredoka(
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
      cancelButtonColor: Colors.grey.withOpacity(0.85),
      cancelButtonForeground: GameTheme.reefRoyale.onDark,
      cancelButtonTextStyle: GoogleFonts.fredoka(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
      submitButtonColor: GameTheme.reefRoyale.accent.withOpacity(0.85),
      submitButtonForeground: GameTheme.reefRoyale.background,
      submitButtonTextStyle: GoogleFonts.fredoka(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  factory EditScoreDialogConfig.lunarLander() {
    return EditScoreDialogConfig(
      backgroundColor: GameTheme.lunarLander.background.withOpacity(0.95), // Earth Blue
      borderColor: GameTheme.lunarLander.accent, // Rocket Flame
      borderWidth: 4,
      titleStyle: GoogleFonts.orbitron(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: GameTheme.lunarLander.onDark, // Star White
        letterSpacing: 1.2,
      ),
      dartLabelStyle: GoogleFonts.exo2(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: GameTheme.lunarLander.onDark.withOpacity(0.7),
      ),
      scoreBoxBackgroundColor: GameTheme.lunarLander.background,
      scoreBoxDefaultBorderColor: GameTheme.lunarLander.accent.withOpacity(0.5),
      scoreTextStyle: GoogleFonts.orbitron(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: GameTheme.lunarLander.onDark,
      ),
      buttonUnselectedColor: const Color(0xFF0D1B2A), // Space Black
      buttonUnselectedForeground: GameTheme.lunarLander.onDark,
      buttonSelectedColor: GameTheme.lunarLander.accent, // Rocket Flame
      buttonSelectedForeground: GameTheme.lunarLander.onDark,
      buttonTextStyle: GoogleFonts.exo2(
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
      cancelButtonColor: const Color(0xFF0D1B2A).withOpacity(0.85),
      cancelButtonForeground: GameTheme.lunarLander.onDark,
      cancelButtonTextStyle: GoogleFonts.exo2(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
      submitButtonColor: GameTheme.lunarLander.accent.withOpacity(0.85), // Rocket Flame
      submitButtonForeground: GameTheme.lunarLander.onDark,
      submitButtonTextStyle: GoogleFonts.orbitron(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.0,
      ),
      scoreDisplayTransform: _lunarLanderScoreDisplay,
    );
  }

  static String _lunarLanderScoreDisplay(String segment) {
    if (segment.isEmpty || segment == '-') return '-';
    if (segment == 'Miss') return 'Miss';
    if (segment == 'Bull') return '50';
    if (segment == '25') return '25';
    final match = RegExp(r'([SDTsdt])(\d+)').firstMatch(segment);
    if (match == null) return segment;
    final prefix = match.group(1)!.toUpperCase();
    final number = int.parse(match.group(2)!);
    if (prefix == 'D') return '${number * 2}';
    if (prefix == 'T') return '${number * 3}';
    return '$number';
  }

  /// Gladiator Arena — Dark Arena bg, Gladiator Gold border, Cinzel/Lato fonts
  /// Pattern A (Calculated Values): scoreDisplayTransform converts segment strings to point values
  factory EditScoreDialogConfig.gladiatorArena() {
    return EditScoreDialogConfig(
      backgroundColor: GameTheme.gladiatorArena.background.withOpacity(0.97), // Dark Arena
      borderColor: const Color(0xFFDAA520), // Gladiator Gold
      borderWidth: 4,
      titleStyle: GoogleFonts.cinzel(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: const Color(0xFFDAA520), // Gladiator Gold
        letterSpacing: 1.2,
      ),
      dartLabelStyle: GoogleFonts.lato(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: GameTheme.gladiatorArena.onDark.withOpacity(0.7), // Marble White
      ),
      scoreBoxBackgroundColor: GameTheme.gladiatorArena.background,
      scoreBoxDefaultBorderColor: const Color(0xFFDAA520).withOpacity(0.5),
      scoreTextStyle: GoogleFonts.cinzel(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: GameTheme.gladiatorArena.onDark, // Marble White
      ),
      buttonUnselectedColor: const Color(0xFF2A1500), // Dark Arena
      buttonUnselectedForeground: GameTheme.gladiatorArena.onDark, // Marble White
      buttonSelectedColor: const Color(0xFFDAA520), // Gladiator Gold
      buttonSelectedForeground: const Color(0xFF1A0A00), // Near Black
      buttonTextStyle: GoogleFonts.lato(
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
      cancelButtonColor: const Color(0xFF8B8682).withOpacity(0.85), // Colosseum Gray
      cancelButtonForeground: GameTheme.gladiatorArena.onDark,
      cancelButtonTextStyle: GoogleFonts.lato(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      submitButtonColor: GameTheme.gladiatorArena.accent.withOpacity(0.9), // Bronze
      submitButtonForeground: GameTheme.gladiatorArena.onDark,
      submitButtonTextStyle: GoogleFonts.cinzel(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.0,
      ),
      scoreDisplayTransform: _gladiatorArenaScoreDisplay,
    );
  }

  static String _gladiatorArenaScoreDisplay(String segment) {
    if (segment.isEmpty || segment == '-') return '-';
    if (segment == 'Miss') return '0';
    if (segment == 'Skip') return '0';
    if (segment == 'Bull') return '50';
    if (segment == '25') return '25';
    final match = RegExp(r'([SDTsdt])(\d+)').firstMatch(segment);
    if (match == null) return segment;
    final prefix = match.group(1)!.toUpperCase();
    final number = int.parse(match.group(2)!);
    if (prefix == 'D') return '${number * 2}';
    if (prefix == 'T') return '${number * 3}';
    return '$number';
  }

  /// Pirate's Grid — Ocean Navy bg, Compass Bronze border, PirataOne/Lora fonts
  /// Pattern B (Dart Throw Display): no scoreDisplayTransform — raw segment strings shown
  factory EditScoreDialogConfig.piratesGrid() {
    return EditScoreDialogConfig(
      backgroundColor: GameTheme.piratesGrid.background.withOpacity(0.95), // Ocean Navy
      borderColor: GameTheme.piratesGrid.accent, // Compass Bronze
      borderWidth: 4,
      titleStyle: GoogleFonts.pirataOne(
        fontSize: 22,
        color: const Color(0xFFDAA520), // Treasure Gold
        letterSpacing: 1.0,
      ),
      dartLabelStyle: GoogleFonts.lora(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: GameTheme.piratesGrid.onDark.withOpacity(0.7),
      ),
      scoreBoxBackgroundColor: GameTheme.piratesGrid.background,
      scoreBoxDefaultBorderColor: GameTheme.piratesGrid.accent.withOpacity(0.5),
      scoreTextStyle: GoogleFonts.pirataOne(
        fontSize: 18,
        color: GameTheme.piratesGrid.onDark,
      ),
      buttonUnselectedColor: const Color(0xFF1A1A1A), // Ink Black
      buttonUnselectedForeground: GameTheme.piratesGrid.onDark,
      buttonSelectedColor: const Color(0xFFDAA520), // Treasure Gold
      buttonSelectedForeground: const Color(0xFF1A1A1A),
      buttonTextStyle: GoogleFonts.lora(
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
      cancelButtonColor: GameTheme.piratesGrid.background.withOpacity(0.85),
      cancelButtonForeground: GameTheme.piratesGrid.onDark,
      cancelButtonTextStyle: GoogleFonts.lora(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      submitButtonColor: GameTheme.piratesGrid.accent.withOpacity(0.85), // Compass Bronze
      submitButtonForeground: GameTheme.piratesGrid.onDark,
      submitButtonTextStyle: GoogleFonts.pirataOne(
        fontSize: 16,
        letterSpacing: 1.0,
      ),
      // No scoreDisplayTransform — raw dart segment strings shown (T20, D18, Bull, etc.)
    );
  }

  factory EditScoreDialogConfig.clockworkQuest() {
    return EditScoreDialogConfig(
      backgroundColor: GameTheme.clockworkQuest.background.withOpacity(0.95), // Dark Iron
      borderColor: GameTheme.clockworkQuest.accent, // Brass Gold
      borderWidth: 4,
      titleStyle: GoogleFonts.cinzelDecorative(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: GameTheme.clockworkQuest.onDark, // Steam White
        letterSpacing: 1.5,
      ),
      dartLabelStyle: GoogleFonts.lato(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: GameTheme.clockworkQuest.onDark.withOpacity(0.7),
      ),
      scoreBoxBackgroundColor: GameTheme.clockworkQuest.background,
      scoreBoxDefaultBorderColor: const Color(0xFFB87333).withOpacity(0.5), // Copper Rose
      scoreTextStyle: GoogleFonts.lato(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: GameTheme.clockworkQuest.onDark,
      ),
      buttonUnselectedColor: GameTheme.clockworkQuest.background,
      buttonUnselectedForeground: GameTheme.clockworkQuest.onDark,
      buttonSelectedColor: GameTheme.clockworkQuest.accent, // Brass Gold
      buttonSelectedForeground: GameTheme.clockworkQuest.background,
      buttonTextStyle: GoogleFonts.lato(
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
      cancelButtonColor: const Color(0xFF4A4A52).withOpacity(0.85),
      cancelButtonForeground: GameTheme.clockworkQuest.onDark,
      cancelButtonTextStyle: GoogleFonts.lato(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
      submitButtonColor: GameTheme.clockworkQuest.accent.withOpacity(0.85), // Brass Gold
      submitButtonForeground: GameTheme.clockworkQuest.background,
      submitButtonTextStyle: GoogleFonts.cinzelDecorative(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.0,
      ),
    );
  }

  /// Tiki Golf theme — Palm Green bg, Lagoon Blue/Tropical Orange accents, Boogaloo/Nunito fonts.
  ///
  /// Note: the Edit Score dialog for Tiki Golf shows up to `maxStrokes` dart
  /// dropdowns (3–6) dynamically — not hardcoded 3. The dialog widget must read
  /// `maxStrokes` from the game state and call this config with the appropriate
  /// count. The config itself is style-only; the dynamic column count is wired
  /// in the game screen (Pass 2).
  factory EditScoreDialogConfig.tikiGolf() {
    return EditScoreDialogConfig(
      backgroundColor: GameTheme.tikiGolf.background.withOpacity(0.97), // Palm Green
      borderColor: GameTheme.tikiGolf.accent, // Lagoon Blue
      borderWidth: 4,
      titleStyle: GoogleFonts.boogaloo(
        fontSize: 24,
        color: GameTheme.tikiGolf.onDark, // Sand White
        shadows: const [
          Shadow(color: Color(0xFF8B5E3C), offset: Offset(1, 1), blurRadius: 0),
          Shadow(color: Color(0xFF8B5E3C), offset: Offset(-1, -1), blurRadius: 0),
          Shadow(color: Color(0xFF8B5E3C), offset: Offset(1, -1), blurRadius: 0),
          Shadow(color: Color(0xFF8B5E3C), offset: Offset(-1, 1), blurRadius: 0),
        ],
      ),
      dartLabelStyle: GoogleFonts.nunito(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: GameTheme.tikiGolf.onDark, // Sand White
        letterSpacing: 0.5,
      ),
      scoreBoxBackgroundColor: GameTheme.tikiGolf.background, // Palm Green
      scoreBoxDefaultBorderColor: GameTheme.tikiGolf.accent.withOpacity(0.5), // Lagoon Blue
      scoreTextStyle: GoogleFonts.nunito(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: GameTheme.tikiGolf.onDark, // Sand White
      ),
      buttonUnselectedColor: const Color(0xFF3A7B5E), // slightly lighter Palm Green
      buttonUnselectedForeground: GameTheme.tikiGolf.onDark,
      buttonSelectedColor: GameTheme.tikiGolf.accent, // Lagoon Blue
      buttonSelectedForeground: GameTheme.tikiGolf.onDark,
      buttonTextStyle: GoogleFonts.nunito(
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
      cancelButtonColor: const Color(0xFF8B5E3C).withOpacity(0.85), // Tiki Brown
      cancelButtonForeground: GameTheme.tikiGolf.onDark,
      cancelButtonTextStyle: GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
      submitButtonColor: const Color(0xFFFF8C42).withOpacity(0.90), // Tropical Orange
      submitButtonForeground: GameTheme.tikiGolf.onDark,
      submitButtonTextStyle: GoogleFonts.boogaloo(
        fontSize: 18,
      ),
    );
  }

  /// Treasure Divide — Ocean Teal bg, Treasure Gold border, PirataOne/Merriweather fonts
  /// Pattern B (Dart Throw Display): no scoreDisplayTransform — raw segment strings shown (S20, D15, T20, Bull).
  factory EditScoreDialogConfig.treasureDivide() {
    return EditScoreDialogConfig(
      backgroundColor: GameTheme.treasureDivide.background.withOpacity(0.97), // Ocean Teal
      borderColor: GameTheme.treasureDivide.accent, // Treasure Gold
      borderWidth: 4,
      // Every fontSize bumped +4 vs. the prior pass for legibility on
      // the larger HUD scale.
      titleStyle: GoogleFonts.pirataOne(
        fontSize: 26,
        color: GameTheme.treasureDivide.accent, // Treasure Gold
        letterSpacing: 1.2,
      ),
      dartLabelStyle: GoogleFonts.merriweather(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: GameTheme.treasureDivide.onDark.withOpacity(0.7), // Sail White
      ),
      scoreBoxBackgroundColor: GameTheme.treasureDivide.background, // Ocean Teal
      // Dart-label container outline switched from plank brown (low
      // contrast on the ocean-teal panel) to sail white.
      scoreBoxDefaultBorderColor:
          GameTheme.treasureDivide.onDark.withOpacity(0.6), // Sail White
      scoreTextStyle: GoogleFonts.pirataOne(
        fontSize: 22,
        color: GameTheme.treasureDivide.onDark, // Sail White
      ),
      buttonUnselectedColor: const Color(0xFF006666), // darker Ocean Teal
      buttonUnselectedForeground: GameTheme.treasureDivide.onDark, // Sail White
      buttonSelectedColor: GameTheme.treasureDivide.accent, // Treasure Gold
      buttonSelectedForeground: GameTheme.treasureDivide.background, // Ocean Teal
      buttonTextStyle: GoogleFonts.merriweather(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
      cancelButtonColor: const Color(0xFF006666).withOpacity(0.85),
      cancelButtonForeground: GameTheme.treasureDivide.onDark,
      cancelButtonTextStyle: GoogleFonts.merriweather(
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      submitButtonColor: GameTheme.treasureDivide.accent.withOpacity(0.9), // Treasure Gold
      submitButtonForeground: GameTheme.treasureDivide.background, // Ocean Teal
      submitButtonTextStyle: GoogleFonts.pirataOne(
        fontSize: 20,
        letterSpacing: 1.0,
      ),
      // No scoreDisplayTransform — raw dart segment strings shown (S20, D15, T20, Bull, etc.)
    );
  }
}
