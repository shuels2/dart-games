import 'package:flutter/material.dart';
import '../interactive_dartboard.dart';
import 'dartboard_emulator_controller.dart';
import 'dartboard_emulator_config.dart';
import 'package:dart_games/constants/test_keys.dart';

class DartboardEmulatorSection extends StatelessWidget {
  final DartboardEmulatorController controller;
  /// When true, the emulator is hidden (real dartboard handles input).
  /// Pass `!dartboardProvider.isEmulator` so the emulator only shows
  /// when the user explicitly chose emulator mode.
  final bool isConnected;
  final bool shouldPromptTakeout;
  final Function(int score, String multiplier, int baseScore, Offset position) onDartThrow;
  final VoidCallback onRemoveDarts;
  final GlobalKey<InteractiveDartboardState>? dartboardKey;
  final DartboardSectionConfig config;
  final VoidCallback? onPlayToComplete;
  final PlayToCompleteButtonConfig? playToCompleteConfig;

  const DartboardEmulatorSection({
    super.key,
    required this.controller,
    required this.isConnected,
    required this.shouldPromptTakeout,
    required this.onDartThrow,
    required this.onRemoveDarts,
    this.dartboardKey,
    required this.config,
    this.onPlayToComplete,
    this.playToCompleteConfig,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        // Don't render if connected or hidden
        if (isConnected || !controller.isVisible) {
          return const SizedBox.shrink();
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onPlayToComplete != null && playToCompleteConfig != null)
              _buildPlayToCompleteButton(),
            Container(
              padding: config.padding,
              decoration: BoxDecoration(
                color: config.backgroundColor,
                borderRadius: config.borderRadius,
                border: config.border,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AbsorbPointer(
                    absorbing: shouldPromptTakeout || controller.isAutoPlaying,
                    child: Opacity(
                      opacity: shouldPromptTakeout ? 0.5 : 1.0,
                      child: InteractiveDartboard(
                        key: dartboardKey,
                        size: 250,
                        onDartThrow: onDartThrow,
                        onRemoveDarts: onRemoveDarts,
                      ),
                    ),
                  ),
                  if (shouldPromptTakeout)
                    _buildDisabledOverlay(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPlayToCompleteButton() {
    final btnConfig = playToCompleteConfig!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: ElevatedButton.icon(
        key: DartboardEmulatorKeys.playToCompleteButton,
        onPressed: shouldPromptTakeout ? null : onPlayToComplete,
        icon: Icon(btnConfig.icon, color: btnConfig.foregroundColor),
        label: Text(btnConfig.buttonText, style: btnConfig.textStyle),
        style: ElevatedButton.styleFrom(
          backgroundColor: btnConfig.backgroundColor,
          disabledBackgroundColor: btnConfig.backgroundColor.withOpacity(0.5),
          side: BorderSide(color: btnConfig.borderColor, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildDisabledOverlay() {
    return Container(
      width: 250,
      height: 250,
      decoration: BoxDecoration(
        color: config.disabledOverlayBackgroundColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: config.disabledOverlayBorderColor,
          width: config.disabledOverlayBorderWidth,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            config.promptIcon,
            size: 48,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          Text(
            config.promptText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            key: DartboardEmulatorKeys.removeDartsButton,
            onPressed: () => dartboardKey?.currentState?.removeDarts(),
            style: ElevatedButton.styleFrom(
              backgroundColor: config.removeButtonBackgroundColor,
              side: BorderSide(
                color: config.removeButtonBorderColor,
                width: 2,
              ),
            ),
            child: Text(
              config.removeButtonText,
              style: config.removeButtonTextStyle,
            ),
          ),
        ],
      ),
    );
  }
}
