import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/player.dart';
import 'shield_bar_widget.dart';
import 'tagged_in_border_widget.dart';

class PlayerCardWidget extends StatelessWidget {
  final Player player;
  final int currentShields;
  final int shieldMax;
  final int targetNumber;
  final int? soloHeroBuffNumber;
  final String? soloHeroBuffMultiplier; // "double" or "triple"
  final bool isTaggedIn;
  final bool isEliminated;
  final bool isCurrentPlayer;
  final bool isTeamMode;
  final String? teamIconPath;
  final List<Player>? teamMembers;

  const PlayerCardWidget({
    super.key,
    required this.player,
    required this.currentShields,
    required this.shieldMax,
    required this.targetNumber,
    this.soloHeroBuffNumber,
    this.soloHeroBuffMultiplier,
    required this.isTaggedIn,
    required this.isEliminated,
    this.isCurrentPlayer = false,
    this.isTeamMode = false,
    this.teamIconPath,
    this.teamMembers,
  });

  @override
  Widget build(BuildContext context) {
    final cardContent = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isEliminated
            ? const Color(0xFF1A1A2E).withOpacity(0.5)
            : const Color(0xFF2A2A3E).withOpacity(0.85),
        borderRadius: BorderRadius.circular(12),
        border: isCurrentPlayer && !isEliminated
            ? Border.all(
                color: const Color(0xFFFF007A), // Pink border for active player
                width: 4, // Increased width to touch pulse
              )
            : null,
      ),
      child: Opacity(
        opacity: isEliminated ? 0.4 : 1.0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Team icon (larger for team mode) or player avatar
            if (isTeamMode && teamIconPath != null) ...[
              // Team icon - twice as large
              Image.asset(
                teamIconPath!,
                width: 160,
                height: 160,
              ),
              const SizedBox(height: 12),
              // Player photos side by side
              if (teamMembers != null && teamMembers!.isNotEmpty)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: teamMembers!.map((p) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: p.photoPath != null
                          ? CircleAvatar(
                              radius: 32,
                              backgroundImage: p.photoPath!.startsWith('data:')
                                  ? MemoryImage(Uri.parse(p.photoPath!).data!.contentAsBytes())
                                  : NetworkImage(p.photoPath!) as ImageProvider,
                            )
                          : CircleAvatar(
                              radius: 32,
                              backgroundColor: const Color(0xFFFF007A),
                              child: Text(
                                p.name[0].toUpperCase(),
                                style: GoogleFonts.fredoka(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 12),
              // Player names on top of each other
              if (teamMembers != null && teamMembers!.isNotEmpty)
                Column(
                  children: teamMembers!.map((p) => Text(
                    p.name,
                    style: GoogleFonts.fredoka(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )).toList(),
                ),
            ] else if (player.photoPath != null)
              CircleAvatar(
                radius: 40, // Increased from 32
                backgroundImage: player.photoPath!.startsWith('data:')
                    ? MemoryImage(Uri.parse(player.photoPath!).data!.contentAsBytes())
                    : NetworkImage(player.photoPath!) as ImageProvider,
              )
            else
              CircleAvatar(
                radius: 40, // Increased from 32
                backgroundColor: const Color(0xFFFF007A),
                child: Text(
                  player.name[0].toUpperCase(),
                  style: GoogleFonts.fredoka(
                    fontSize: 28, // Increased from 24
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),

            // For solo mode, show player name here
            if (!isTeamMode) ...[
              const SizedBox(height: 12),
              Text(
                player.name,
                style: GoogleFonts.fredoka(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            const SizedBox(height: 12),

            // Target number(s)
            if (soloHeroBuffNumber != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Target number: ',
                    style: GoogleFonts.fredoka(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(width: 6), // Padding between label and number
                  Transform.translate(
                    offset: const Offset(0, 5), // Move down 5px
                    child: Text(
                      '$targetNumber',
                      style: GoogleFonts.luckiestGuy(
                        fontSize: 24,
                        color: const Color(0xFFFF007A),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '|',
                    style: GoogleFonts.fredoka(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Buff: ',
                    style: GoogleFonts.fredoka(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(width: 6), // Padding between label and number
                  Transform.translate(
                    offset: const Offset(0, 5), // Move down 5px
                    child: Text(
                      _formatBuffNumber(soloHeroBuffNumber!, soloHeroBuffMultiplier),
                      style: GoogleFonts.luckiestGuy(
                        fontSize: 24,
                        color: const Color(0xFFFFD700), // Gold color
                      ),
                    ),
                  ),
                ],
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Target number: ',
                    style: GoogleFonts.fredoka(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(width: 6), // Padding between label and number
                  Transform.translate(
                    offset: const Offset(0, 5), // Move down 5px
                    child: Text(
                      '$targetNumber',
                      style: GoogleFonts.luckiestGuy(
                        fontSize: 26,
                        color: const Color(0xFFFF007A),
                      ),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 12),

            // Shield bar
            ShieldBarWidget(
              currentShields: currentShields,
              shieldMax: shieldMax,
            ),

            const SizedBox(height: 6),

            // Shield count text
            Text(
              '$currentShields / $shieldMax',
              style: GoogleFonts.fredoka(
                fontSize: 18, // Increased from 14
                fontWeight: FontWeight.bold,
                color: const Color(0xFFFFD700), // Arcade gold
              ),
            ),

            // Tagged In indicator
            if (isTaggedIn && !isEliminated)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700), // Arcade gold
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'TAGGED IN',
                    style: GoogleFonts.fredoka(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),

            // Eliminated indicator
            if (isEliminated)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Text(
                    'TAGGED OUT',
                    style: GoogleFonts.fredoka(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    // Wrap with pulsing border if tagged in
    // Use green pulse, but only show pulse if NOT current player (current player has pink border)
    if (isTaggedIn && !isEliminated && !isCurrentPlayer) {
      return TaggedInBorderWidget(
        isTaggedIn: true,
        borderColor: const Color(0xFF00FFA3), // Green pulse for tagged in
        child: cardContent,
      );
    }

    // If current player AND tagged in, add green glow behind the pink border
    if (isTaggedIn && !isEliminated && isCurrentPlayer) {
      return TaggedInBorderWidget(
        isTaggedIn: true,
        borderColor: const Color(0xFF00FFA3), // Green glow
        showBorderLine: false, // Only glow, no border line
        child: cardContent,
      );
    }

    return cardContent;
  }

  String _formatBuffNumber(int number, String? multiplier) {
    if (multiplier == null) return '$number';
    final prefix = multiplier == 'double' ? 'D' : 'T';
    return '$prefix$number';
  }
}
