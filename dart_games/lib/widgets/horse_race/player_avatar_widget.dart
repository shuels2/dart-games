import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../models/player.dart';

class PlayerAvatarWidget extends StatelessWidget {
  final Player player;
  final double size;
  final bool showName;
  final bool isHighlighted;

  const PlayerAvatarWidget({
    super.key,
    required this.player,
    this.size = 30.0,
    this.showName = false,
    this.isHighlighted = false,
  });

  ImageProvider? _getImageProvider() {
    if (player.photoPath == null) return null;

    if (kIsWeb) {
      return NetworkImage(player.photoPath!);
    } else {
      return FileImage(File(player.photoPath!));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: isHighlighted
              ? BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.amber,
                    width: 3.0,
                  ),
                )
              : null,
          child: CircleAvatar(
            radius: size,
            backgroundColor: Colors.grey[300],
            backgroundImage: _getImageProvider(),
            child: player.photoPath == null
                ? Icon(
                    Icons.person,
                    size: size * 1.2,
                    color: Colors.grey[600],
                  )
                : null,
          ),
        ),
        if (showName) ...[
          const SizedBox(height: 4),
          Text(
            player.name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}
