import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/player.dart';
import 'player_avatar_widget.dart';

class PlayerSelectionCard extends StatelessWidget {
  final Player player;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onRemove;
  final bool compact;

  const PlayerSelectionCard({
    super.key,
    required this.player,
    required this.isSelected,
    required this.onTap,
    this.onRemove,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompactCard();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFFFFD700).withOpacity(0.2)  // Canary Yellow tint
            : const Color(0xFF1D3557).withOpacity(0.6), // Navy
        border: Border.all(
          color: isSelected
              ? const Color(0xFFFFD700)  // Canary Yellow
              : const Color(0xFF48CAE4),  // Electric Teal
          width: isSelected ? 3 : 2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Row(
              children: [
                PlayerAvatarWidget(
                  player: player,
                  size: 22.0,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player.name,
                        style: GoogleFonts.montserrat(
                          fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                          fontSize: 14,
                          color: const Color(0xFFF1FAEE), // Cloud Dancer
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Games: ${player.gamesPlayed} | Wins: ${player.gamesWon}',
                        style: GoogleFonts.montserrat(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFFF1FAEE).withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected && onRemove != null)
                  IconButton(
                    icon: const Icon(Icons.remove_circle, color: Color(0xFFE63946)),
                    iconSize: 24,
                    onPressed: onRemove,
                  )
                else if (isSelected)
                  const Icon(Icons.check_circle, color: Color(0xFF48CAE4), size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactCard() {
    return Container(
      margin: const EdgeInsets.all(0),
      decoration: BoxDecoration(
        color: const Color(0xFFFFD700).withOpacity(0.2), // Canary Yellow tint
        border: Border.all(
          color: const Color(0xFFFFD700), // Canary Yellow
          width: 3,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: PlayerAvatarWidget(
                        player: player,
                        size: 16.0,
                      ),
                    ),
                    if (onRemove != null)
                      GestureDetector(
                        onTap: onRemove,
                        child: const Icon(
                          Icons.remove_circle,
                          color: Color(0xFFE63946), // Lava Red
                          size: 20,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  player.name,
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    color: const Color(0xFFF1FAEE), // Cloud Dancer
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                Text(
                  'G: ${player.gamesPlayed}',
                  style: GoogleFonts.montserrat(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFFF1FAEE).withOpacity(0.8),
                  ),
                ),
                Text(
                  'W: ${player.gamesWon}',
                  style: GoogleFonts.montserrat(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFFF1FAEE).withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
