import 'package:flutter/material.dart';
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

    return Card(
      color: isSelected ? Colors.amber[50] : null,
      elevation: isSelected ? 4 : 1,
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
        leading: PlayerAvatarWidget(
          player: player,
          size: 22.0,
        ),
        title: Text(
          player.name,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          'Games: ${player.gamesPlayed} | Wins: ${player.gamesWon}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: isSelected && onRemove != null
            ? IconButton(
                icon: const Icon(Icons.remove_circle, color: Colors.red),
                onPressed: onRemove,
              )
            : isSelected
                ? const Icon(Icons.check_circle, color: Colors.green)
                : null,
        onTap: onTap,
      ),
    );
  }

  Widget _buildCompactCard() {
    return Card(
      color: Colors.amber[50],
      elevation: 4,
      margin: const EdgeInsets.all(0),
      child: InkWell(
        onTap: onTap,
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
                        color: Colors.red,
                        size: 20,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                player.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                'G: ${player.gamesPlayed}',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
              Text(
                'W: ${player.gamesWon}',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
