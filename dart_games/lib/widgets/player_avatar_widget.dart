import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../models/player.dart';

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

  // ─── Photo ImageProvider cache ──────────────────────────────────────────────
  //
  // Memoize the ResizeImage(NetworkImage|FileImage(photoPath)) wrapper by
  // photoPath. Without this, every PlayerAvatarWidget.build() — and the
  // gameplay screens rebuild via setState on every dart throw, touching
  // every visible avatar (up to 8 in Treasure Divide) — allocates fresh
  // NetworkImage + ResizeImage instances. While ImageProvider equality is
  // defined for both classes (so the image cache would still hit on key
  // lookup), repeated provider chain allocation + repeated Image-widget
  // stream-listener registration churn under heavy avatar density was
  // contributing to CanvasKit wasm-heap pressure that surfaces as
  // RuntimeError: Aborted() inside PictureRecorder. Memoization keeps one
  // canonical provider per (platform, photoPath) so Image widgets share
  // the same listener registration across rebuilds.
  static final Map<String, ImageProvider> _photoProviderCache = {};

  static ImageProvider _resolvePhotoProvider(String photoPath) {
    return _photoProviderCache.putIfAbsent(photoPath, () {
      final ImageProvider raw = kIsWeb
          ? NetworkImage(photoPath)
          : FileImage(File(photoPath));
      return ResizeImage(raw, width: 512, height: 512);
    });
  }

  ImageProvider? _getImageProvider() {
    if (player.photoPath == null) return null;

    // Cap the decoded bitmap dimensions. Without this, an uploaded 2250x1500
    // headshot decodes to ~13MB of pixel data and can exhaust the CanvasKit
    // wasm heap when several avatars render together — the symptom is a
    // RuntimeError: Aborted() inside PictureRecorder on every frame.
    //
    // 512px is ~2x the largest on-screen avatar (Treasure Divide active
    // player is 300px logical) — enough headroom for hi-DPI rendering while
    // keeping a single decoded headshot bounded to ~1MB of pixel data.
    // The previous cap was 256 (sized for an 80px max display) and became
    // smaller than the new 300px Treasure Divide active avatar, which
    // forced upscaling and lost crispness even though it didn't cause the
    // abort by itself.
    return _resolvePhotoProvider(player.photoPath!);
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
