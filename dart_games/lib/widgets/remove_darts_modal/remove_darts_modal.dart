import 'package:flutter/material.dart';

import '../themed_modal_shell.dart';
import 'remove_darts_modal_config.dart';

export 'remove_darts_modal_config.dart';

/// A shared full-screen modal overlay prompting the player to remove their
/// darts from the board.
///
/// Renders a semi-transparent black overlay with a centered, game-themed
/// container showing a hand icon, the player's name, a "Remove Your Darts"
/// instruction, and an optional "Edit player score" button.
///
/// Each game provides its own visual styling via [RemoveDartsModalConfig]
/// factory methods (e.g. `.carnivalDerby()`, `.targetTag()`, `.monsterMash()`).
class RemoveDartsModal extends StatelessWidget {
  final RemoveDartsModalConfig config;
  final String playerName;
  final Key? editScoreButtonKey;
  final VoidCallback? onEditScore;

  const RemoveDartsModal({
    super.key,
    required this.config,
    required this.playerName,
    this.editScoreButtonKey,
    this.onEditScore,
  });

  @override
  Widget build(BuildContext context) {
    // Chrome lives in ThemedModalShell (WS03 §3.7).
    //
    // fill: false is load-bearing. This modal is mounted as a bare child of
    // the game shell's outer Stack in a SPECIFIC layer — below the emulator,
    // so DARTS REMOVED stays reachable — and it returned a plain Material,
    // not a Positioned.fill. Wrapping it would change it from a loose Stack
    // child to a filling one.
    return ThemedModalShell(
      fill: false,
      backgroundColor: config.backgroundColor,
      backgroundOpacity: config.backgroundOpacity,
      borderColor: config.borderColor,
      borderWidth: config.borderWidth,
      borderRadius: config.borderRadius,
      boxShadowColor: config.boxShadowColor,
      boxShadowOpacity: config.boxShadowOpacity,
      // Often double.infinity here — the shell then omits the ConstrainedBox
      // entirely, matching what this file did by hand.
      maxWidth: config.maxWidth,
      margin: config.margin,
      padding: config.padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.pan_tool,
            color: config.iconColor,
            size: config.iconSize,
          ),
          SizedBox(height: config.iconSize == 64 ? 24.0 : 16.0),
          Text(
            playerName,
            style: config.playerNameTextStyle,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: config.iconSize == 64 ? 12.0 : 8.0),
          Text(
            'Remove Your Darts',
            style: config.instructionTextStyle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            key: editScoreButtonKey,
            onPressed: onEditScore,
            style: ElevatedButton.styleFrom(
              backgroundColor: config.buttonBackgroundColor,
              foregroundColor: config.buttonForegroundColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              side: config.buttonBorderSide,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(config.buttonBorderRadius),
              ),
            ),
            child: Text(
              config.editButtonText,
              style: config.buttonTextStyle,
            ),
          ),
        ],
      ),
    );
  }
}
