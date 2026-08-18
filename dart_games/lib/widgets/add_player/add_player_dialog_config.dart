import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/game_theme.dart';
import '../stone_dialog_button.dart';

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
  final List<Shadow>? photoIconShadows;
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

  // Dialog layout
  final EdgeInsets? dialogInsetPadding;
  final double? dialogContentWidth;

  // Custom button builders (optional - when provided, override default buttons)
  final Widget Function(Key? key, VoidCallback onPressed)? customCancelButton;
  final Widget Function(Key? key, VoidCallback onPressed)? customAddButton;

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
    this.photoIconShadows,
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
    this.dialogInsetPadding,
    this.dialogContentWidth,
    this.customCancelButton,
    this.customAddButton,
  });

  /// Carnival Derby theme configuration (red/yellow/teal carnival theme)
  factory AddPlayerDialogConfig.carnivalDerby() {
    return AddPlayerDialogConfig(
      backgroundColor: GameTheme.carnivalDerby.background.withOpacity(0.95), // Midnight Navy
      textColor: GameTheme.carnivalDerby.onDark, // Cloud Dancer
      titleStyle: GoogleFonts.montserrat(
        fontSize: 20,
        fontWeight: FontWeight.w900,
        color: GameTheme.carnivalDerby.onDark, // Cloud Dancer
        shadows: const [
          Shadow(
            color: Color(0xFFFFD700), // Canary Yellow glow
            blurRadius: 10,
          ),
        ],
      ),
      inputLabelStyle: const TextStyle(color: Color(0xFFF1FAEE)), // Cloud Dancer
      inputBorderColor: const Color(0xFF48CAE4), // Electric Teal
      inputFocusedBorderColor: GameTheme.carnivalDerby.accent, // Canary Yellow
      inputErrorBorderColor: Colors.red,
      photoLabelStyle: GoogleFonts.montserrat(
        fontSize: 16,
        fontWeight: FontWeight.w900,
        color: GameTheme.carnivalDerby.onDark, // Cloud Dancer
      ),
      photoButtonColor: const Color(0xFF48CAE4), // Electric Teal
      photoButtonForegroundColor: GameTheme.carnivalDerby.onDark, // Cloud Dancer
      photoButtonBorderColor: GameTheme.carnivalDerby.accent, // Canary Yellow
      photoButtonTextStyle: GoogleFonts.bangers(
        fontSize: 14,
        letterSpacing: 1.0,
        color: GameTheme.carnivalDerby.onDark,
      ),
      photoButtonWidth: 130.0,
      addButtonColor: const Color(0xFFE63946), // Lava Red
      addButtonForegroundColor: GameTheme.carnivalDerby.onDark, // Cloud Dancer
      addButtonBorderColor: GameTheme.carnivalDerby.accent, // Canary Yellow
      addButtonTextStyle: GoogleFonts.bangers(
        fontSize: 14,
        letterSpacing: 1.0,
        color: GameTheme.carnivalDerby.onDark,
      ),
      cancelButtonColor: GameTheme.carnivalDerby.background, // Midnight Navy
      cancelButtonForegroundColor: GameTheme.carnivalDerby.onDark, // Cloud Dancer
      cancelButtonBorderColor: const Color(0xFF48CAE4), // Electric Teal
      cancelButtonTextStyle: GoogleFonts.bangers(
        fontSize: 14,
        letterSpacing: 1.0,
        color: GameTheme.carnivalDerby.onDark, // Cloud Dancer
      ),
      errorTextColor: Colors.red,
    );
  }

  /// Target Tag theme configuration (pink/green tech/neon theme)
  factory AddPlayerDialogConfig.targetTag() {
    return AddPlayerDialogConfig(
      backgroundColor: GameTheme.targetTag.background.withOpacity(0.95), // Dark tech navy
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
      inputFocusedBorderColor: GameTheme.targetTag.accent, // Hot Pink
      inputErrorBorderColor: Colors.red,
      photoLabelStyle: GoogleFonts.fredoka(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      photoButtonColor: const Color(0xFF00FFA3), // Neon Green
      photoButtonForegroundColor: Colors.white,
      photoButtonBorderColor: GameTheme.targetTag.accent, // Hot Pink
      photoButtonTextStyle: GoogleFonts.fredoka(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      photoButtonWidth: null, // Expanded
      addButtonColor: GameTheme.targetTag.accent, // Hot Pink
      addButtonForegroundColor: Colors.white,
      addButtonBorderColor: GameTheme.targetTag.accent, // Hot Pink
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
      backgroundColor: GameTheme.monsterMash.background.withOpacity(0.95), // Iron Gate
      textColor: GameTheme.monsterMash.onDark, // Aged Parchment
      titleStyle: GoogleFonts.creepster(
        fontSize: 28,
        color: GameTheme.monsterMash.onDark,
        shadows: [
          Shadow(
            color: GameTheme.monsterMash.onDark.withOpacity(0.4),
            blurRadius: 8,
          ),
          const Shadow(
            color: Colors.black,
            blurRadius: 3,
            offset: Offset(1, 1),
          ),
        ],
      ),
      inputLabelStyle: GoogleFonts.montserrat(
        fontSize: 18,
        color: GameTheme.monsterMash.onDark,
      ),
      inputBorderColor: GameTheme.monsterMash.accent, // Ecto-Green
      inputFocusedBorderColor: const Color(0xFFFF8C00), // Pumpkin Orange
      inputErrorBorderColor: Colors.red,
      photoLabelStyle: GoogleFonts.montserrat(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: GameTheme.monsterMash.onDark,
      ),
      photoButtonColor: const Color(0xFF4B0082), // Haunted Purple
      photoButtonForegroundColor: GameTheme.monsterMash.onDark,
      photoButtonBorderColor: GameTheme.monsterMash.accent, // Ecto-Green
      photoButtonTextStyle: GoogleFonts.pirataOne(
        fontSize: 22,
        color: GameTheme.monsterMash.onDark,
        shadows: [
          Shadow(
            color: GameTheme.monsterMash.accent.withOpacity(0.6),
            blurRadius: 8,
          ),
          const Shadow(
            color: Colors.black,
            blurRadius: 3,
            offset: Offset(1, 1),
          ),
        ],
      ),
      photoIconShadows: [
        Shadow(
          color: GameTheme.monsterMash.accent.withOpacity(0.6),
          blurRadius: 8,
        ),
        const Shadow(
          color: Colors.black,
          blurRadius: 3,
          offset: Offset(1, 1),
        ),
      ],
      photoButtonWidth: null,
      addButtonColor: const Color(0xFF4B0082), // Haunted Purple
      addButtonForegroundColor: GameTheme.monsterMash.onDark,
      addButtonBorderColor: GameTheme.monsterMash.accent, // Ecto-Green
      addButtonTextStyle: GoogleFonts.pirataOne(
        fontSize: 24,
        color: GameTheme.monsterMash.onDark,
      ),
      cancelButtonColor: GameTheme.monsterMash.background, // Iron Gate
      cancelButtonForegroundColor: GameTheme.monsterMash.onDark,
      cancelButtonBorderColor: GameTheme.monsterMash.onDark.withOpacity(0.5),
      cancelButtonTextStyle: GoogleFonts.pirataOne(
        fontSize: 24,
        color: GameTheme.monsterMash.onDark,
      ),
      buttonPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
      errorTextColor: Colors.red,
      dialogInsetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 24),
      dialogContentWidth: 380,
      customCancelButton: (key, onPressed) => StoneDialogButton(
        buttonKey: key,
        onPressed: onPressed,
        label: 'CANCEL',
        textStyle: GoogleFonts.pirataOne(
          fontSize: 24,
          color: GameTheme.monsterMash.onDark,
        ),
        showStoneFill: false,
        showShadow: false,
        borderColor: GameTheme.monsterMash.background,
        height: 52,
        seed: 'CANCEL_DIALOG'.hashCode,
      ),
      customAddButton: (key, onPressed) => StoneDialogButton(
        buttonKey: key,
        onPressed: onPressed,
        label: 'ADD PLAYER',
        showLightning: true,
        lightningColor: GameTheme.monsterMash.onDark,
        height: 52,
        seed: 'ADD_PLAYER_DIALOG'.hashCode,
      ),
    );
  }

  /// Reef Royale theme — Deep Reef Blue bg, Seafoam Green accents, Fredoka font
  factory AddPlayerDialogConfig.reefRoyale() {
    return AddPlayerDialogConfig(
      backgroundColor: GameTheme.reefRoyale.background.withOpacity(0.95),
      textColor: GameTheme.reefRoyale.onDark, // Pearl White
      titleStyle: GoogleFonts.fredoka(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: GameTheme.reefRoyale.onDark,
      ),
      inputLabelStyle: GoogleFonts.nunito(
        fontSize: 18,
        color: GameTheme.reefRoyale.onDark,
      ),
      inputBorderColor: GameTheme.reefRoyale.accent, // Seafoam Green
      inputFocusedBorderColor: const Color(0xFF00CED1), // Sunlit Aqua
      inputErrorBorderColor: const Color(0xFFFF6B6B), // Coral Pink
      photoLabelStyle: GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: GameTheme.reefRoyale.onDark,
      ),
      photoButtonColor: GameTheme.reefRoyale.background,
      photoButtonForegroundColor: GameTheme.reefRoyale.onDark,
      photoButtonBorderColor: GameTheme.reefRoyale.accent,
      photoButtonTextStyle: GoogleFonts.fredoka(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: GameTheme.reefRoyale.onDark,
      ),
      photoButtonWidth: null,
      addButtonColor: GameTheme.reefRoyale.accent,
      addButtonForegroundColor: GameTheme.reefRoyale.background,
      addButtonBorderColor: GameTheme.reefRoyale.accent,
      addButtonTextStyle: GoogleFonts.fredoka(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
      cancelButtonColor: Colors.grey,
      cancelButtonForegroundColor: GameTheme.reefRoyale.onDark,
      cancelButtonBorderColor: Colors.grey,
      cancelButtonTextStyle: GoogleFonts.fredoka(
        fontSize: 16,
      ),
      errorTextColor: const Color(0xFFFF6B6B),
    );
  }

  /// Clockwork Quest theme configuration (steampunk clocktower theme)
  factory AddPlayerDialogConfig.clockworkQuest() {
    return AddPlayerDialogConfig(
      backgroundColor: GameTheme.clockworkQuest.background, // Dark Iron
      textColor: GameTheme.clockworkQuest.onDark, // Steam White
      titleStyle: GoogleFonts.cinzelDecorative(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: GameTheme.clockworkQuest.accent, // Brass Gold
        letterSpacing: 1.2,
      ),
      inputLabelStyle: GoogleFonts.lato(
        fontSize: 16,
        color: GameTheme.clockworkQuest.onDark,
        fontWeight: FontWeight.w600,
      ),
      inputBorderColor: const Color(0xFFB87333), // Copper Rose
      inputFocusedBorderColor: GameTheme.clockworkQuest.accent, // Brass Gold
      inputErrorBorderColor: const Color(0xFFFF6B6B),
      photoLabelStyle: GoogleFonts.lato(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: GameTheme.clockworkQuest.onDark,
      ),
      photoButtonColor: const Color(0xFFB87333), // Copper Rose
      photoButtonForegroundColor: GameTheme.clockworkQuest.onDark,
      photoButtonBorderColor: GameTheme.clockworkQuest.accent,
      photoButtonTextStyle: GoogleFonts.lato(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: GameTheme.clockworkQuest.onDark,
      ),
      photoButtonWidth: null,
      addButtonColor: GameTheme.clockworkQuest.accent, // Brass Gold
      addButtonForegroundColor: GameTheme.clockworkQuest.background, // Dark Iron
      addButtonBorderColor: GameTheme.clockworkQuest.accent,
      addButtonTextStyle: GoogleFonts.cinzelDecorative(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.0,
      ),
      cancelButtonColor: const Color(0xFF4A4A52),
      cancelButtonForegroundColor: GameTheme.clockworkQuest.onDark,
      cancelButtonBorderColor: const Color(0xFFB87333),
      cancelButtonTextStyle: GoogleFonts.lato(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      errorTextColor: const Color(0xFFFF6B6B),
    );
  }

  /// Lunar Lander theme — Earth Blue background, Rocket Flame accents, Orbitron/Exo2 fonts
  factory AddPlayerDialogConfig.lunarLander() {
    return AddPlayerDialogConfig(
      backgroundColor: GameTheme.lunarLander.background.withOpacity(0.95), // Earth Blue
      textColor: GameTheme.lunarLander.onDark, // Star White
      titleStyle: GoogleFonts.orbitron(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: GameTheme.lunarLander.onDark, // Star White
        letterSpacing: 1.2,
      ),
      inputLabelStyle: GoogleFonts.exo2(
        fontSize: 16,
        color: GameTheme.lunarLander.onDark,
      ),
      inputBorderColor: GameTheme.lunarLander.accent, // Rocket Flame
      inputFocusedBorderColor: const Color(0xFF52B788), // Mission Green
      inputErrorBorderColor: const Color(0xFFE63946), // Thruster Red
      photoLabelStyle: GoogleFonts.exo2(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: GameTheme.lunarLander.onDark,
      ),
      photoButtonColor: GameTheme.lunarLander.background, // Earth Blue
      photoButtonForegroundColor: GameTheme.lunarLander.onDark,
      photoButtonBorderColor: GameTheme.lunarLander.accent, // Rocket Flame
      photoButtonTextStyle: GoogleFonts.exo2(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: GameTheme.lunarLander.onDark,
      ),
      photoButtonWidth: null,
      addButtonColor: GameTheme.lunarLander.accent, // Rocket Flame
      addButtonForegroundColor: GameTheme.lunarLander.onDark,
      addButtonBorderColor: GameTheme.lunarLander.accent,
      addButtonTextStyle: GoogleFonts.orbitron(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.0,
        color: GameTheme.lunarLander.onDark,
      ),
      cancelButtonColor: const Color(0xFF0D1B2A).withOpacity(0.85), // Space Black
      cancelButtonForegroundColor: GameTheme.lunarLander.onDark,
      cancelButtonBorderColor: const Color(0xFFC0C0C0), // Rocket Silver
      cancelButtonTextStyle: GoogleFonts.exo2(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: GameTheme.lunarLander.onDark,
      ),
      errorTextColor: const Color(0xFFE63946), // Thruster Red
    );
  }

  /// Pirate's Grid theme — Ocean Navy bg, Compass Rose Bronze/Treasure Gold accents, PirataOne/Lora fonts
  factory AddPlayerDialogConfig.piratesGrid() {
    return AddPlayerDialogConfig(
      backgroundColor: GameTheme.piratesGrid.background.withOpacity(0.95), // Ocean Navy
      textColor: GameTheme.piratesGrid.onDark, // Parchment Tan
      titleStyle: GoogleFonts.pirataOne(
        fontSize: 22,
        color: const Color(0xFFDAA520), // Treasure Gold
        letterSpacing: 1.2,
        shadows: const [
          Shadow(color: Color(0xFF1A1A1A), blurRadius: 4, offset: Offset(1, 1)),
        ],
      ),
      inputLabelStyle: GoogleFonts.lora(
        fontSize: 16,
        color: GameTheme.piratesGrid.onDark,
      ),
      inputBorderColor: GameTheme.piratesGrid.accent, // Compass Bronze
      inputFocusedBorderColor: const Color(0xFFDAA520), // Treasure Gold
      inputErrorBorderColor: const Color(0xFF8B0000), // Blood Red
      photoLabelStyle: GoogleFonts.lora(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: GameTheme.piratesGrid.onDark,
      ),
      photoButtonColor: GameTheme.piratesGrid.background, // Ocean Navy
      photoButtonForegroundColor: GameTheme.piratesGrid.onDark,
      photoButtonBorderColor: GameTheme.piratesGrid.accent, // Compass Bronze
      photoButtonTextStyle: GoogleFonts.lora(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: GameTheme.piratesGrid.onDark,
      ),
      photoButtonWidth: null,
      addButtonColor: GameTheme.piratesGrid.accent, // Compass Bronze
      addButtonForegroundColor: GameTheme.piratesGrid.onDark,
      addButtonBorderColor: const Color(0xFFDAA520), // Treasure Gold
      addButtonTextStyle: GoogleFonts.pirataOne(
        fontSize: 16,
        letterSpacing: 1.0,
        color: GameTheme.piratesGrid.onDark,
      ),
      cancelButtonColor: GameTheme.piratesGrid.background.withOpacity(0.85), // Ocean Navy
      cancelButtonForegroundColor: GameTheme.piratesGrid.onDark,
      cancelButtonBorderColor: GameTheme.piratesGrid.accent.withOpacity(0.6),
      cancelButtonTextStyle: GoogleFonts.lora(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: GameTheme.piratesGrid.onDark,
      ),
      errorTextColor: const Color(0xFF8B0000), // Blood Red
    );
  }

  /// Gladiator Arena theme — Arena Sand/Imperial Purple bg, Gladiator Gold/Bronze accents, Cinzel/Lato fonts
  factory AddPlayerDialogConfig.gladiatorArena() {
    return AddPlayerDialogConfig(
      backgroundColor: const Color(0xFF4A3520).withOpacity(0.97), // Dark Arena Brown
      textColor: GameTheme.gladiatorArena.onDark, // Marble White
      titleStyle: GoogleFonts.cinzel(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: const Color(0xFFDAA520), // Gladiator Gold
        letterSpacing: 1.2,
        shadows: const [
          Shadow(color: Color(0xFF1A0A00), blurRadius: 4, offset: Offset(1, 1)),
        ],
      ),
      inputLabelStyle: GoogleFonts.lato(
        fontSize: 16,
        color: GameTheme.gladiatorArena.onDark, // Marble White
      ),
      inputBorderColor: GameTheme.gladiatorArena.accent, // Bronze
      inputFocusedBorderColor: const Color(0xFFDAA520), // Gladiator Gold
      inputErrorBorderColor: const Color(0xFFC0392B), // Blood Red
      photoLabelStyle: GoogleFonts.lato(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: GameTheme.gladiatorArena.onDark, // Marble White
      ),
      photoButtonColor: const Color(0xFF4A3520),
      photoButtonForegroundColor: GameTheme.gladiatorArena.onDark,
      photoButtonBorderColor: GameTheme.gladiatorArena.accent, // Bronze
      photoButtonTextStyle: GoogleFonts.lato(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: GameTheme.gladiatorArena.onDark,
      ),
      photoButtonWidth: null,
      addButtonColor: GameTheme.gladiatorArena.accent, // Bronze
      addButtonForegroundColor: GameTheme.gladiatorArena.onDark, // Marble White
      addButtonBorderColor: const Color(0xFFDAA520), // Gladiator Gold
      addButtonTextStyle: GoogleFonts.cinzel(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.0,
        color: GameTheme.gladiatorArena.onDark,
      ),
      cancelButtonColor: const Color(0xFF4A3520).withOpacity(0.85),
      cancelButtonForegroundColor: GameTheme.gladiatorArena.onDark,
      cancelButtonBorderColor: GameTheme.gladiatorArena.accent.withOpacity(0.6),
      cancelButtonTextStyle: GoogleFonts.lato(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: GameTheme.gladiatorArena.onDark,
      ),
      errorTextColor: const Color(0xFFC0392B), // Blood Red
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

  /// Treasure Divide theme — Ocean Teal bg, Treasure Gold/Plank Brown accents, PirataOne/Merriweather fonts
  factory AddPlayerDialogConfig.treasureDivide() {
    return AddPlayerDialogConfig(
      backgroundColor: GameTheme.treasureDivide.background.withOpacity(0.97), // Ocean Teal
      textColor: GameTheme.treasureDivide.onDark, // Sail White
      titleStyle: GoogleFonts.pirataOne(
        fontSize: 24,
        color: GameTheme.treasureDivide.accent, // Treasure Gold
        letterSpacing: 1.2,
        shadows: const [
          Shadow(color: Color(0xFF1A1A1A), blurRadius: 4, offset: Offset(1, 1)),
        ],
      ),
      inputLabelStyle: GoogleFonts.merriweather(
        fontSize: 16,
        color: GameTheme.treasureDivide.onDark, // Sail White
      ),
      inputBorderColor: const Color(0xFF8B6914), // Plank Brown
      inputFocusedBorderColor: GameTheme.treasureDivide.accent, // Treasure Gold
      inputErrorBorderColor: const Color(0xFFC41E3A), // Blood Red
      photoLabelStyle: GoogleFonts.merriweather(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: GameTheme.treasureDivide.onDark, // Sail White
      ),
      photoButtonColor: GameTheme.treasureDivide.background, // Ocean Teal
      photoButtonForegroundColor: GameTheme.treasureDivide.onDark,
      photoButtonBorderColor: const Color(0xFF8B6914), // Plank Brown
      photoButtonTextStyle: GoogleFonts.merriweather(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: GameTheme.treasureDivide.onDark,
      ),
      photoButtonWidth: null,
      addButtonColor: GameTheme.treasureDivide.accent, // Treasure Gold
      addButtonForegroundColor: GameTheme.treasureDivide.background, // Ocean Teal
      addButtonBorderColor: const Color(0xFF8B6914), // Plank Brown
      addButtonTextStyle: GoogleFonts.pirataOne(
        fontSize: 18,
        letterSpacing: 1.0,
        color: GameTheme.treasureDivide.background,
      ),
      cancelButtonColor: GameTheme.treasureDivide.background.withOpacity(0.85), // Ocean Teal
      cancelButtonForegroundColor: GameTheme.treasureDivide.onDark,
      cancelButtonBorderColor: const Color(0xFF8B6914).withOpacity(0.6), // Plank Brown
      cancelButtonTextStyle: GoogleFonts.merriweather(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: GameTheme.treasureDivide.onDark,
      ),
      errorTextColor: const Color(0xFFC41E3A), // Blood Red
    );
  }

  /// Tiki Golf theme — Palm Green bg, Lagoon Blue/Tropical Orange accents, Boogaloo/Nunito fonts
  factory AddPlayerDialogConfig.tikiGolf() {
    return AddPlayerDialogConfig(
      backgroundColor: GameTheme.tikiGolf.background.withOpacity(0.97), // Palm Green
      textColor: GameTheme.tikiGolf.onDark, // Sand White
      titleStyle: GoogleFonts.boogaloo(
        fontSize: 26,
        color: GameTheme.tikiGolf.onDark, // Sand White
        shadows: const [
          Shadow(color: Color(0xFF00B4D8), offset: Offset(1, 1), blurRadius: 0),
          Shadow(color: Color(0xFF00B4D8), offset: Offset(-1, -1), blurRadius: 0),
          Shadow(color: Color(0xFF00B4D8), offset: Offset(1, -1), blurRadius: 0),
          Shadow(color: Color(0xFF00B4D8), offset: Offset(-1, 1), blurRadius: 0),
        ],
      ),
      inputLabelStyle: GoogleFonts.nunito(
        fontSize: 16,
        color: GameTheme.tikiGolf.onDark, // Sand White
      ),
      inputBorderColor: GameTheme.tikiGolf.accent, // Lagoon Blue
      inputFocusedBorderColor: const Color(0xFFFF8C42), // Tropical Orange
      inputErrorBorderColor: const Color(0xFFFF69B4), // Hibiscus Pink
      photoLabelStyle: GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: GameTheme.tikiGolf.onDark, // Sand White
      ),
      photoButtonColor: GameTheme.tikiGolf.background, // Palm Green
      photoButtonForegroundColor: GameTheme.tikiGolf.onDark,
      photoButtonBorderColor: GameTheme.tikiGolf.accent, // Lagoon Blue
      photoButtonTextStyle: GoogleFonts.nunito(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: GameTheme.tikiGolf.onDark,
      ),
      photoButtonWidth: null,
      addButtonColor: GameTheme.tikiGolf.accent, // Lagoon Blue
      addButtonForegroundColor: GameTheme.tikiGolf.onDark, // Sand White
      addButtonBorderColor: GameTheme.tikiGolf.accent,
      addButtonTextStyle: GoogleFonts.boogaloo(
        fontSize: 18,
        color: GameTheme.tikiGolf.onDark,
      ),
      cancelButtonColor: const Color(0xFF8B5E3C), // Tiki Brown
      cancelButtonForegroundColor: GameTheme.tikiGolf.onDark,
      cancelButtonBorderColor: const Color(0xFF8B5E3C),
      cancelButtonTextStyle: GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: GameTheme.tikiGolf.onDark,
      ),
      errorTextColor: const Color(0xFFFF69B4), // Hibiscus Pink
    );
  }
}
