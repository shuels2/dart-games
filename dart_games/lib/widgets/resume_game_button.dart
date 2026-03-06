import 'package:flutter/material.dart';

/// A reusable button for resuming saved games from game menu screens.
///
/// This button appears in the AppBar of each game's menu screen, positioned
/// just to the left of the DartboardConnectionInfo widget. It allows users to
/// access their saved games directly from the menu without navigating back
/// to the home screen.
///
/// The button is enabled when saved games exist and disabled when no saved
/// games are available. When pressed, it triggers a callback (typically to
/// show the ResumeGameModal).
///
/// Example usage:
/// ```dart
/// AppBar(
///   actions: [
///     ResumeGameButton(
///       hasSavedGames: _hasSavedGames,
///       onPressed: () => setState(() => _showResumeModal = true),
///       color: const Color(0xFFFF007A), // Game-specific theme color
///     ),
///     Padding(
///       padding: const EdgeInsets.only(right: 16.0),
///       child: DartboardConnectionInfo(...),
///     ),
///   ],
/// )
/// ```
class ResumeGameButton extends StatelessWidget {
  /// Whether saved games exist for this game.
  /// When false, the button is disabled.
  final bool hasSavedGames;

  /// Callback when the button is pressed.
  /// Typically shows the ResumeGameModal.
  final VoidCallback onPressed;

  /// The color of the button icon when enabled.
  /// Should match the game's theme color.
  final Color color;

  /// The color of the button icon when disabled.
  /// If not provided, defaults to [color] with 30% opacity.
  final Color? disabledColor;

  /// The size of the icon.
  /// Defaults to 28.
  final double iconSize;

  const ResumeGameButton({
    super.key,
    required this.hasSavedGames,
    required this.onPressed,
    required this.color,
    this.disabledColor,
    this.iconSize = 28,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.history),
      iconSize: iconSize,
      tooltip: hasSavedGames ? 'Resume saved game' : 'No saved games',
      onPressed: hasSavedGames ? onPressed : null,
      color: color,
      disabledColor: disabledColor ?? color.withOpacity(0.3),
    );
  }
}
