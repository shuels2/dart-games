import 'package:flutter/material.dart';
import 'dartboard_emulator_controller.dart';
import 'dartboard_emulator_config.dart';

class DartboardEmulatorFAB extends StatelessWidget {
  final DartboardEmulatorController controller;
  final bool isConnected;
  final DartboardFABConfig config;

  const DartboardEmulatorFAB({
    super.key,
    required this.controller,
    required this.isConnected,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    // Don't render if connected
    if (isConnected) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return FloatingActionButton.extended(
          onPressed: controller.toggle,
          backgroundColor: config.backgroundColor,
          icon: Icon(
            controller.isVisible ? Icons.visibility_off : Icons.visibility,
            color: config.iconColor,
          ),
          label: Text(
            controller.isVisible ? config.hideText : config.showText,
            style: config.textStyle.copyWith(color: config.textColor),
          ),
        );
      },
    );
  }
}
