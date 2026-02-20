import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
      backgroundColor: const Color(0xFF1D3557).withOpacity(0.95),
      borderColor: const Color(0xFFFFD700),
      borderWidth: 4,
      titleStyle: GoogleFonts.luckiestGuy(
        fontSize: 24,
        color: const Color(0xFFFFD700),
      ),
      dartLabelStyle: GoogleFonts.bangers(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: const Color(0xFFF1FAEE),
        letterSpacing: 1.0,
      ),
      scoreBoxBackgroundColor: const Color(0xFF1D3557),
      scoreBoxDefaultBorderColor: const Color(0xFFFFD700),
      scoreTextStyle: GoogleFonts.luckiestGuy(
        fontSize: 18,
        color: const Color(0xFFF1FAEE),
      ),
      buttonUnselectedColor: const Color(0xFF8B5E3C),
      buttonUnselectedForeground: const Color(0xFFF1FAEE),
      buttonSelectedColor: const Color(0xFFFFD700),
      buttonSelectedForeground: const Color(0xFF1D3557),
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
      submitButtonColor: const Color(0xFFFFD700).withOpacity(0.85),
      submitButtonForeground: const Color(0xFF1D3557),
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
      backgroundColor: const Color(0xFF2F4F4F).withOpacity(0.95), // Iron Gate
      borderColor: const Color(0xFFFF8C00), // Pumpkin Orange
      borderWidth: 4,
      titleStyle: GoogleFonts.creepster(
        fontSize: 24,
        color: const Color(0xFFF5F5DC), // Aged Parchment
      ),
      dartLabelStyle: GoogleFonts.montserrat(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: const Color(0xFFF5F5DC).withOpacity(0.7),
      ),
      scoreBoxBackgroundColor: const Color(0xFF2F4F4F),
      scoreBoxDefaultBorderColor: const Color(0xFFF5F5DC).withOpacity(0.3),
      scoreTextStyle: GoogleFonts.pirataOne(
        fontSize: 18,
        color: const Color(0xFFF5F5DC),
      ),
      buttonUnselectedColor: const Color(0xFF4B0082), // Haunted Purple
      buttonUnselectedForeground: const Color(0xFFF5F5DC),
      buttonSelectedColor: const Color(0xFF7FFF00), // Ecto-Green
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
      submitButtonForeground: const Color(0xFFF5F5DC),
      submitButtonTextStyle: GoogleFonts.pirataOne(
        fontSize: 16,
      ),
    );
  }

  factory EditScoreDialogConfig.targetTag() {
    return EditScoreDialogConfig(
      backgroundColor: const Color(0xFF1A1A2E).withOpacity(0.95),
      borderColor: const Color(0xFFFF007A),
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
      scoreBoxBackgroundColor: const Color(0xFF1A1A2E),
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
      submitButtonColor: const Color(0xFFFF007A).withOpacity(0.85),
      submitButtonForeground: Colors.white,
      submitButtonTextStyle: GoogleFonts.fredoka(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
      // No scoreDisplayTransform — raw segment string shown (S20, D15, etc.)
    );
  }
}
