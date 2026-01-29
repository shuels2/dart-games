import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/player.dart';
import '../../providers/horse_race_provider.dart';
import 'player_avatar_widget.dart';

class RaceTrackWidget extends StatelessWidget {
  final List<Player> players;
  final int targetScore;

  const RaceTrackWidget({
    super.key,
    required this.players,
    required this.targetScore,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<HorseRaceProvider>(
      builder: (context, provider, child) {
        final currentPlayerId = provider.getCurrentPlayerId();

        return Column(
          children: [
            // Race tracks
            Expanded(
              child: ListView.builder(
                itemCount: players.length,
                itemBuilder: (context, index) {
                  final player = players[index];
                  final isCurrentPlayer = player.id == currentPlayerId;
                  final score = provider.getPlayerScore(player.id);
                  final position = provider.getHorsePosition(player.id);

                  return _buildRaceLane(
                    player: player,
                    score: score,
                    position: position,
                    isCurrentPlayer: isCurrentPlayer,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRaceLane({
    required Player player,
    required int score,
    required double position,
    required bool isCurrentPlayer,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: isCurrentPlayer
            ? const Color(0xFFFFD700).withOpacity(0.3)  // Canary Yellow tint for current player
            : const Color(0xFF1D3557).withOpacity(0.6), // Navy for other players
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: isCurrentPlayer
              ? const Color(0xFFFFD700)  // Canary Yellow border for current player
              : const Color(0xFF48CAE4), // Electric Teal border for other players
          width: isCurrentPlayer ? 4.0 : 2.0,
        ),
        boxShadow: isCurrentPlayer ? [
          BoxShadow(
            color: const Color(0xFFFFD700).withOpacity(0.5),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ] : null,
      ),
      child: Row(
        children: [
          // Player info on the left
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PlayerAvatarWidget(
                player: player,
                size: 40.0,
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: 80,
                child: Text(
                  player.name,
                  style: GoogleFonts.montserrat(
                    fontWeight: isCurrentPlayer ? FontWeight.w900 : FontWeight.w700,
                    fontSize: 12,
                    color: const Color(0xFFF1FAEE), // Cloud Dancer
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$score / $targetScore',
                style: GoogleFonts.luckiestGuy(
                  fontSize: 11,
                  color: isCurrentPlayer
                      ? const Color(0xFF1D3557) // Navy for current player (better contrast on yellow)
                      : const Color(0xFF48CAE4), // Electric Teal for others
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),

          // Race track
          Expanded(
            child: SizedBox(
              height: 100,
              child: LayoutBuilder(
              builder: (context, constraints) {
                final trackWidth = constraints.maxWidth;
                final horsePosition = (position * trackWidth).clamp(0.0, trackWidth - 90);

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Track background - tiled image
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          image: const DecorationImage(
                            image: AssetImage('assets/icon/track.png'),
                            repeat: ImageRepeat.repeatX,
                            fit: BoxFit.fitHeight,
                          ),
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(
                            color: isCurrentPlayer
                                ? const Color(0xFFFFD700) // Canary Yellow for current player
                                : const Color(0xFF457B9D), // Light Blue for others
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Finish line
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: Image.asset(
                        'assets/icon/finish_line.png',
                        fit: BoxFit.contain,
                      ),
                    ),

                    // Horse
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOut,
                      left: horsePosition,
                      top: 5,
                      child: Image.asset(
                        'assets/icon/horse.png',
                        width: 90,
                        height: 90,
                      ),
                    ),
                  ],
                );
              },
            ),
            ),
          ),
        ],
      ),
    );
  }
}

