import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/dartboard_provider.dart';
import 'dartboard_connection_info_config.dart';

/// A combined widget that shows dartboard name, type (emulator/hardware),
/// and connection status in a single compact row.
///
/// Uses [Consumer<DartboardProvider>] to reactively update.
/// Returns [SizedBox.shrink] if no dartboard is configured.
/// Accepts a [DartboardConnectionInfoConfig] for game-specific styling.
class DartboardConnectionInfo extends StatelessWidget {
  final DartboardConnectionInfoConfig config;

  const DartboardConnectionInfo({
    super.key,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<DartboardProvider>(
      builder: (context, dartboardProvider, child) {
        if (dartboardProvider.dartboard == null) {
          return const SizedBox.shrink();
        }

        final isEmulator = dartboardProvider.isEmulator;
        final borderColor = isEmulator
            ? config.emulatorBorderColor
            : config.hardwareBorderColor;

        return Container(
          padding: config.padding,
          decoration: BoxDecoration(
            color: config.backgroundColor.withOpacity(config.backgroundOpacity),
            borderRadius: BorderRadius.circular(config.borderRadius),
            border: Border.all(
              color: borderColor,
              width: config.borderWidth,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Type icon (emulator vs hardware)
              Icon(
                isEmulator ? Icons.computer : Icons.developer_board,
                size: config.iconSize,
                color: isEmulator
                    ? config.emulatorIconColor
                    : config.hardwareIconColor,
              ),
              const SizedBox(width: 8),
              // Dartboard name on top, status/type below
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    dartboardProvider.dartboard!.name,
                    style: config.nameTextStyle.copyWith(
                      color: isEmulator
                          ? config.emulatorIconColor
                          : config.nameTextStyle.color,
                    ),
                  ),
                  const SizedBox(height: 1),
                  if (isEmulator)
                    Text(
                      'Emulator',
                      style: config.emulatorLabelTextStyle,
                    )
                  else
                    _buildStatusLabel(dartboardProvider),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// Compact status label shown below the dartboard name for non-emulator connections.
  Widget _buildStatusLabel(DartboardProvider provider) {
    final status = provider.status;
    final color = _getStatusColor(status);
    final icon = _getStatusIcon(status);
    final statusText = _getStatusText(status);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: config.iconSize - 6, color: color),
        const SizedBox(width: 3),
        Text(
          statusText,
          style: config.emulatorLabelTextStyle.copyWith(color: color),
        ),
      ],
    );
  }

  Color _getStatusColor(DartboardConnectionStatus status) {
    switch (status) {
      case DartboardConnectionStatus.connected:
        return config.connectedColor;
      case DartboardConnectionStatus.connecting:
        return config.connectingColor;
      case DartboardConnectionStatus.disconnected:
        return config.disconnectedColor;
      case DartboardConnectionStatus.error:
        return config.errorColor;
      case DartboardConnectionStatus.emulator:
        return config.connectedColor;
    }
  }

  IconData _getStatusIcon(DartboardConnectionStatus status) {
    switch (status) {
      case DartboardConnectionStatus.connected:
        return Icons.check_circle;
      case DartboardConnectionStatus.connecting:
        return Icons.sync;
      case DartboardConnectionStatus.disconnected:
        return Icons.wifi_off;
      case DartboardConnectionStatus.error:
        return Icons.error;
      case DartboardConnectionStatus.emulator:
        return Icons.check_circle;
    }
  }

  String _getStatusText(DartboardConnectionStatus status) {
    switch (status) {
      case DartboardConnectionStatus.connected:
        return 'Connected';
      case DartboardConnectionStatus.connecting:
        return 'Connecting...';
      case DartboardConnectionStatus.disconnected:
        return 'Disconnected';
      case DartboardConnectionStatus.error:
        return 'Unable to Connect';
      case DartboardConnectionStatus.emulator:
        return 'Emulator';
    }
  }
}
