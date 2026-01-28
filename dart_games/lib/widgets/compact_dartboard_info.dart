import 'package:flutter/material.dart';
import '../providers/dartboard_provider.dart';

class CompactDartboardInfo extends StatelessWidget {
  final DartboardProvider provider;

  const CompactDartboardInfo({
    super.key,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    if (provider.dartboard == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: provider.isEmulator
              ? Colors.orange.shade700
              : Colors.blue.shade700,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            provider.isEmulator ? Icons.computer : Icons.developer_board,
            size: 18,
            color: provider.isEmulator
                ? Colors.orange.shade700
                : Colors.blue.shade700,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                provider.dartboard!.name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: provider.isEmulator
                      ? Colors.orange.shade900
                      : Colors.blue.shade900,
                ),
              ),
              if (provider.isEmulator)
                Text(
                  'Emulator',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.orange.shade700,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
