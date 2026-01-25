import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
            // Header with target score
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Race to $targetScore points!',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(),

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
        color: isCurrentPlayer ? Colors.amber[50] : Colors.grey[100],
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: isCurrentPlayer ? Colors.amber : Colors.grey[300]!,
          width: isCurrentPlayer ? 3.0 : 1.0,
        ),
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
                  style: TextStyle(
                    fontWeight: isCurrentPlayer ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$score / $targetScore',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
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
                          border: Border.all(color: Colors.grey[400]!, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
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

