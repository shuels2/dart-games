import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/target_tag_game.dart';

class GameInfoPanelWidget extends StatelessWidget {
  final GameMode mode;
  final int shieldMax;
  final bool soloHeroBonus;
  final String? teamAssignmentMode; // "Random" or "Manual" for team mode

  const GameInfoPanelWidget({
    super.key,
    required this.mode,
    required this.shieldMax,
    required this.soloHeroBonus,
    this.teamAssignmentMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity, // Match height of sibling
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3E).withOpacity(0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF00FFA3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Title
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: Color(0xFF00FFA3),
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Game Settings',
                style: GoogleFonts.fredoka(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),

          // Game Mode
          _buildInfoRow(
            label: 'Mode',
            value: mode == GameMode.solo ? 'Solo' : 'Team',
          ),

          // Team Assignment Mode (only for team mode)
          if (mode == GameMode.team && teamAssignmentMode != null)
            _buildInfoRow(
              label: 'Teams',
              value: teamAssignmentMode!,
            ),

          // Shield Max
          _buildInfoRow(
            label: 'Shield Max',
            value: shieldMax.toString(),
          ),

          // Hero Bonus
          _buildInfoRow(
            label: 'Hero Bonus',
            value: soloHeroBonus ? 'ON' : 'OFF',
            valueColor: soloHeroBonus ? const Color(0xFFFF007A) : Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.fredoka(
            fontSize: 16,
            color: Colors.white70,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.fredoka(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: valueColor ?? const Color(0xFF00FFA3),
          ),
        ),
      ],
    );
  }
}
