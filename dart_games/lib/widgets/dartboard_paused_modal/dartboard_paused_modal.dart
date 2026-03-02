import 'package:flutter/material.dart';
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
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: _buildModalContent(),
      ),
    );
  }

  Widget _buildModalContent() {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: config.maxWidth),
      child: Container(
        margin: config.margin,
        padding: config.padding,
        decoration: BoxDecoration(
          color: config.backgroundColor.withOpacity(config.backgroundOpacity),
          borderRadius: BorderRadius.circular(config.borderRadius),
          border: Border.all(
            color: config.borderColor,
            width: config.borderWidth,
          ),
          boxShadow: [
            BoxShadow(
              color: config.boxShadowColor.withOpacity(config.boxShadowOpacity),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
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
      ),
    );
  }
}
