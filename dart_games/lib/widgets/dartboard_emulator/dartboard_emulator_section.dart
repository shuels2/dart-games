import 'package:flutter/material.dart';
import '../interactive_dartboard.dart';
import 'dartboard_emulator_controller.dart';
import 'dartboard_emulator_config.dart';

class DartboardEmulatorSection extends StatelessWidget {
  final DartboardEmulatorController controller;
  final bool isConnected;
  final bool shouldPromptTakeout;
  final Function(int score, String multiplier, int baseScore, Offset position) onDartThrow;
  final VoidCallback onRemoveDarts;
  final GlobalKey<InteractiveDartboardState>? dartboardKey;
  final DartboardSectionConfig config;

  const DartboardEmulatorSection({
    super.key,
    required this.controller,
    required this.isConnected,
    required this.shouldPromptTakeout,
    required this.onDartThrow,
    required this.onRemoveDarts,
    this.dartboardKey,
    required this.config,
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

        return Container(
          padding: config.padding,
          decoration: BoxDecoration(
            color: config.backgroundColor,
            borderRadius: config.borderRadius,
            border: config.border,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Dartboard with conditional disable
              AbsorbPointer(
                absorbing: shouldPromptTakeout,
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

              // Disabled overlay modal
              if (shouldPromptTakeout)
                _buildDisabledOverlay(),
            ],
          ),
        );
      },
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
            onPressed: onRemoveDarts,
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
