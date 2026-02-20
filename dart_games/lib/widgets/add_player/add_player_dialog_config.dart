import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Configuration class for styling the Add Player dialog.
///
/// Allows each game/screen to customize the appearance while maintaining
/// consistent functionality across all implementations.
class AddPlayerDialogConfig {
  // Dialog styling
  final Color backgroundColor;
  final Color textColor;
  final TextStyle titleStyle;
  final TextStyle inputLabelStyle;
  final Color inputBorderColor;
  final Color inputFocusedBorderColor;
  final Color inputErrorBorderColor;

  // Photo section styling
  final TextStyle photoLabelStyle;

  // Button styling
  final Color photoButtonColor;
  final Color photoButtonForegroundColor;
  final Color photoButtonBorderColor;
  final TextStyle photoButtonTextStyle;
  final double? photoButtonWidth; // null = Expanded

  final Color addButtonColor;
  final Color addButtonForegroundColor;
  final Color addButtonBorderColor;
  final TextStyle addButtonTextStyle;

  final Color cancelButtonColor;
  final Color cancelButtonForegroundColor;
  final Color cancelButtonBorderColor;
  final TextStyle cancelButtonTextStyle;

  // Button padding
  final EdgeInsetsGeometry? buttonPadding;

  // Error styling
  final Color errorTextColor;

  const AddPlayerDialogConfig({
    required this.backgroundColor,
    required this.textColor,
    required this.titleStyle,
    required this.inputLabelStyle,
    required this.inputBorderColor,
    required this.inputFocusedBorderColor,
    required this.inputErrorBorderColor,
    required this.photoLabelStyle,
    required this.photoButtonColor,
    required this.photoButtonForegroundColor,
    required this.photoButtonBorderColor,
    required this.photoButtonTextStyle,
    this.photoButtonWidth,
    required this.addButtonColor,
    required this.addButtonForegroundColor,
    required this.addButtonBorderColor,
    required this.addButtonTextStyle,
    required this.cancelButtonColor,
    required this.cancelButtonForegroundColor,
    required this.cancelButtonBorderColor,
    required this.cancelButtonTextStyle,
    this.buttonPadding,
    required this.errorTextColor,
  });

  /// Carnival Derby theme configuration (red/yellow/teal carnival theme)
  factory AddPlayerDialogConfig.carnivalDerby() {
    return AddPlayerDialogConfig(
      backgroundColor: const Color(0xFF1D3557).withOpacity(0.95), // Midnight Navy
      textColor: const Color(0xFFF1FAEE), // Cloud Dancer
      titleStyle: GoogleFonts.montserrat(
        fontSize: 20,
        fontWeight: FontWeight.w900,
        color: const Color(0xFFF1FAEE), // Cloud Dancer
        shadows: const [
          Shadow(
            color: Color(0xFFFFD700), // Canary Yellow glow
            blurRadius: 10,
          ),
        ],
      ),
      inputLabelStyle: const TextStyle(color: Color(0xFFF1FAEE)), // Cloud Dancer
      inputBorderColor: const Color(0xFF48CAE4), // Electric Teal
      inputFocusedBorderColor: const Color(0xFFFFD700), // Canary Yellow
      inputErrorBorderColor: Colors.red,
      photoLabelStyle: GoogleFonts.montserrat(
        fontSize: 16,
        fontWeight: FontWeight.w900,
        color: const Color(0xFFF1FAEE), // Cloud Dancer
      ),
      photoButtonColor: const Color(0xFF48CAE4), // Electric Teal
      photoButtonForegroundColor: const Color(0xFFF1FAEE), // Cloud Dancer
      photoButtonBorderColor: const Color(0xFFFFD700), // Canary Yellow
      photoButtonTextStyle: GoogleFonts.bangers(
        fontSize: 14,
        letterSpacing: 1.0,
        color: const Color(0xFFF1FAEE),
      ),
      photoButtonWidth: 130.0,
      addButtonColor: const Color(0xFFE63946), // Lava Red
      addButtonForegroundColor: const Color(0xFFF1FAEE), // Cloud Dancer
      addButtonBorderColor: const Color(0xFFFFD700), // Canary Yellow
      addButtonTextStyle: GoogleFonts.bangers(
        fontSize: 14,
        letterSpacing: 1.0,
        color: const Color(0xFFF1FAEE),
      ),
      cancelButtonColor: const Color(0xFF1D3557), // Midnight Navy
      cancelButtonForegroundColor: const Color(0xFFF1FAEE), // Cloud Dancer
      cancelButtonBorderColor: const Color(0xFF48CAE4), // Electric Teal
      cancelButtonTextStyle: GoogleFonts.bangers(
        fontSize: 14,
        letterSpacing: 1.0,
        color: const Color(0xFFF1FAEE), // Cloud Dancer
      ),
      errorTextColor: Colors.red,
    );
  }

  /// Target Tag theme configuration (pink/green tech/neon theme)
  factory AddPlayerDialogConfig.targetTag() {
    return AddPlayerDialogConfig(
      backgroundColor: const Color(0xFF1A1A2E).withOpacity(0.95), // Dark tech navy
      textColor: Colors.white,
      titleStyle: GoogleFonts.fredoka(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      inputLabelStyle: GoogleFonts.fredoka(
        fontSize: 14,
        color: Colors.white,
      ),
      inputBorderColor: const Color(0xFF00FFA3), // Neon Green
      inputFocusedBorderColor: const Color(0xFFFF007A), // Hot Pink
      inputErrorBorderColor: Colors.red,
      photoLabelStyle: GoogleFonts.fredoka(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      photoButtonColor: const Color(0xFF00FFA3), // Neon Green
      photoButtonForegroundColor: Colors.white,
      photoButtonBorderColor: const Color(0xFFFF007A), // Hot Pink
      photoButtonTextStyle: GoogleFonts.fredoka(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      photoButtonWidth: null, // Expanded
      addButtonColor: const Color(0xFFFF007A), // Hot Pink
      addButtonForegroundColor: Colors.white,
      addButtonBorderColor: const Color(0xFFFF007A), // Hot Pink
      addButtonTextStyle: GoogleFonts.fredoka(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      cancelButtonColor: const Color(0xFF2A2A3E), // Darker background
      cancelButtonForegroundColor: Colors.white,
      cancelButtonBorderColor: Colors.white,
      cancelButtonTextStyle: GoogleFonts.fredoka(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      errorTextColor: Colors.red,
    );
  }

  /// Monster Mash theme configuration (purple/green horror theme)
  factory AddPlayerDialogConfig.monsterMash() {
    return AddPlayerDialogConfig(
      backgroundColor: const Color(0xFF2F4F4F).withOpacity(0.95), // Iron Gate
      textColor: const Color(0xFFF5F5DC), // Aged Parchment
      titleStyle: GoogleFonts.creepster(
        fontSize: 28,
        color: const Color(0xFFF5F5DC),
      ),
      inputLabelStyle: GoogleFonts.montserrat(
        fontSize: 18,
        color: const Color(0xFFF5F5DC),
      ),
      inputBorderColor: const Color(0xFF7FFF00), // Ecto-Green
      inputFocusedBorderColor: const Color(0xFFFF8C00), // Pumpkin Orange
      inputErrorBorderColor: Colors.red,
      photoLabelStyle: GoogleFonts.montserrat(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: const Color(0xFFF5F5DC),
      ),
      photoButtonColor: const Color(0xFF4B0082), // Haunted Purple
      photoButtonForegroundColor: const Color(0xFFF5F5DC),
      photoButtonBorderColor: const Color(0xFF7FFF00), // Ecto-Green
      photoButtonTextStyle: GoogleFonts.pirataOne(
        fontSize: 22,
        color: const Color(0xFFF5F5DC),
      ),
      photoButtonWidth: null,
      addButtonColor: const Color(0xFF4B0082), // Haunted Purple
      addButtonForegroundColor: const Color(0xFFF5F5DC),
      addButtonBorderColor: const Color(0xFF7FFF00), // Ecto-Green
      addButtonTextStyle: GoogleFonts.pirataOne(
        fontSize: 24,
        color: const Color(0xFFF5F5DC),
      ),
      cancelButtonColor: const Color(0xFF2F4F4F), // Iron Gate
      cancelButtonForegroundColor: const Color(0xFFF5F5DC),
      cancelButtonBorderColor: const Color(0xFFF5F5DC).withOpacity(0.5),
      cancelButtonTextStyle: GoogleFonts.pirataOne(
        fontSize: 24,
        color: const Color(0xFFF5F5DC),
      ),
      buttonPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
      errorTextColor: Colors.red,
    );
  }

  /// Options Screen theme configuration (Material Design defaults)
  factory AddPlayerDialogConfig.optionsScreen(BuildContext context) {
    final theme = Theme.of(context);
    return AddPlayerDialogConfig(
      backgroundColor: theme.dialogBackgroundColor,
      textColor: theme.textTheme.bodyLarge?.color ?? Colors.black87,
      titleStyle: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      inputLabelStyle: TextStyle(
        color: theme.textTheme.bodyMedium?.color ?? Colors.black54,
      ),
      inputBorderColor: theme.dividerColor,
      inputFocusedBorderColor: theme.primaryColor,
      inputErrorBorderColor: theme.colorScheme.error,
      photoLabelStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      photoButtonColor: theme.primaryColor,
      photoButtonForegroundColor: Colors.white,
      photoButtonBorderColor: theme.primaryColor,
      photoButtonTextStyle: const TextStyle(
        fontSize: 14,
        color: Colors.white,
      ),
      photoButtonWidth: null, // Expanded
      addButtonColor: theme.primaryColor,
      addButtonForegroundColor: Colors.white,
      addButtonBorderColor: theme.primaryColor,
      addButtonTextStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
      cancelButtonColor: Colors.grey,
      cancelButtonForegroundColor: Colors.white,
      cancelButtonBorderColor: Colors.grey,
      cancelButtonTextStyle: const TextStyle(
        fontSize: 16,
      ),
      errorTextColor: theme.colorScheme.error,
    );
  }
}
