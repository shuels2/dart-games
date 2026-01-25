import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dartboard_provider.dart';

enum DartboardStatus {
  connected,
  connecting,
  disconnected,
  error,
}

class DartboardStatusIndicator extends StatelessWidget {
  const DartboardStatusIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DartboardProvider>(
      builder: (context, dartboardProvider, child) {
        // Don't show anything if using emulator
        if (dartboardProvider.isEmulator) {
          return const SizedBox.shrink();
        }

        // Don't show if no dartboard configured
        if (dartboardProvider.dartboard == null) {
          return const SizedBox.shrink();
        }

        final status = _getStatus(dartboardProvider);
        final color = _getStatusColor(status);
        final icon = _getStatusIcon(status);
        final statusText = _getStatusText(status);

        return Tooltip(
          message: statusText,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color, width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Text(
                  statusText,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  DartboardStatus _getStatus(DartboardProvider provider) {
    switch (provider.status) {
      case DartboardConnectionStatus.connected:
        return DartboardStatus.connected;
      case DartboardConnectionStatus.connecting:
        return DartboardStatus.connecting;
      case DartboardConnectionStatus.disconnected:
        return DartboardStatus.disconnected;
      case DartboardConnectionStatus.error:
        return DartboardStatus.error;
      case DartboardConnectionStatus.emulator:
        return DartboardStatus.disconnected;
    }
  }

  Color _getStatusColor(DartboardStatus status) {
    switch (status) {
      case DartboardStatus.connected:
        return Colors.green;
      case DartboardStatus.connecting:
        return Colors.orange;
      case DartboardStatus.disconnected:
      case DartboardStatus.error:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(DartboardStatus status) {
    switch (status) {
      case DartboardStatus.connected:
        return Icons.check_circle;
      case DartboardStatus.connecting:
        return Icons.sync;
      case DartboardStatus.disconnected:
        return Icons.wifi_off;
      case DartboardStatus.error:
        return Icons.error;
    }
  }

  String _getStatusText(DartboardStatus status) {
    switch (status) {
      case DartboardStatus.connected:
        return 'Connected';
      case DartboardStatus.connecting:
        return 'Connecting...';
      case DartboardStatus.disconnected:
        return 'Disconnected';
      case DartboardStatus.error:
        return 'Unable to Connect';
    }
  }
}
