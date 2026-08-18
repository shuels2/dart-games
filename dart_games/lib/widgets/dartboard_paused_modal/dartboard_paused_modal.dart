import 'package:flutter/material.dart';

import '../themed_modal_shell.dart';
import 'dartboard_paused_modal_config.dart';

export 'dartboard_paused_modal_config.dart';

/// A shared full-screen modal overlay shown when the dartboard connection
/// is lost mid-game.
///
/// Displays a semi-transparent overlay with a centered, game-themed container
/// showing a wifi-off icon, "Game Paused" title, and a reconnection message.
///
/// The modal auto-shows when `dartboardProvider.status` becomes `error` or
/// `disconnected` and auto-dismisses when the dartboard reconnects.
///
/// Each game provides its own visual styling via [DartboardPausedModalConfig]
/// factory methods (e.g. `.carnivalDerby()`, `.targetTag()`, `.monsterMash()`,
/// `.reefRoyale()`).
class DartboardPausedModal extends StatelessWidget {
  final DartboardPausedModalConfig config;

  const DartboardPausedModal({
    super.key,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    // Chrome (barrier, centring, width cap, panel decoration) lives in
    // ThemedModalShell (WS03 §3.7); only the contents below are this modal's.
    return ThemedModalShell(
      backgroundColor: config.backgroundColor,
      backgroundOpacity: config.backgroundOpacity,
      borderColor: config.borderColor,
      borderWidth: config.borderWidth,
      borderRadius: config.borderRadius,
      boxShadowColor: config.boxShadowColor,
      boxShadowOpacity: config.boxShadowOpacity,
      maxWidth: config.maxWidth,
      margin: config.margin,
      padding: config.padding,
      child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off,
              color: config.iconColor,
              size: config.iconSize,
            ),
            const SizedBox(height: 20),
            Text(
              'Game Paused',
              style: config.titleTextStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Connection lost to dartboard.\nGame will resume when reconnected.',
              style: config.messageTextStyle,
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }
}
